# TP Fleet : piloter des Elastic Agents depuis Kibana

**Durée :** 1 h à 1 h 30
**Stack Portainer :** `tp3`

## Objectifs

À la fin de ce TP, vous saurez :

- expliquer le rôle de **Fleet**, du **Fleet Server** et des **Elastic Agents** ;
- créer une **politique d'agent** (agent policy) et lui ajouter des intégrations ;
- **enrôler** un agent avec un jeton d'enrôlement ;
- modifier une politique « à chaud » et voir les agents se mettre à jour tout seuls ;
- **désenrôler** un agent et révoquer un jeton.

## Rappel : comment ça marche

```
                    ┌──────────────┐
  Vous ───────────▶ │    Kibana    │  Fleet (interface) : politiques, intégrations, jetons
                    └──────┬───────┘
                           │ stocke les politiques
                    ┌──────▼───────┐
                    │ es01 / es02  │ ◀───────────────────────────┐
                    └──────▲───────┘                             │
                           │ lit les politiques                  │ envoie les données
                    ┌──────┴───────┐   politique + mises à jour  │ (logs, métriques)
                    │ Fleet Server │ ◀──────────────▶ ┌──────────┴──┐
                    │   :8220      │   (check-in)     │ Elastic Agent│
                    └──────────────┘                  └─────────────┘
```

- **Kibana / Fleet** : l'interface où l'on décrit *ce que* les agents doivent collecter.
- **Fleet Server** : un Elastic Agent particulier qui sert de point de contact aux autres agents. Il leur distribue leur politique et reçoit leur état.
- **Elastic Agent** : un agent unique installé sur chaque machine. Il remplace Filebeat, Metricbeat, etc., et envoie ses données **directement à Elasticsearch**.

Dans la stack `tp3`, le Fleet Server est déjà en place : c'est le conteneur `fleet-server`.

---

## Partie 1 : démarrer la stack et découvrir Fleet

1. Dans **Portainer** (http://localhost:9000), arrêtez toute autre stack, puis démarrez la stack **tp3**.
2. Attendez 2 à 3 minutes, puis ouvrez **Kibana** (http://localhost:5601) avec `elastic` / `formation`.
3. Menu ☰ → **Management** → **Fleet**.

**À observer :**

- Onglet **Agents** : un agent est déjà présent. Lequel ? Dans quelle politique ? Quel est son état ?
- Onglet **Agent policies** : ouvrez *Fleet Server Policy*. Quelles intégrations contient-elle ?
- Onglet **Settings** :
  - *Fleet server hosts* : à quelle adresse les agents contactent-ils le Fleet Server ?
  - *Outputs* : vers quels nœuds Elasticsearch les agents envoient-ils leurs données ? Ouvrez la sortie *Elasticsearch TP3* et regardez la *configuration YAML avancée* : à quoi sert la ligne `ssl.certificate_authorities` ?

<details>
<summary>💡 Réponses : ce qu'il fallait observer</summary>

- **Agents** : l'agent présent est le **Fleet Server** lui-même (hôte `fleet-server`). Il fait partie de la politique *Fleet Server Policy* et doit être **Healthy**. Le Fleet Server est donc un Elastic Agent comme un autre, enrôlé dans Fleet.
- **Fleet Server Policy** : elle contient l'intégration **Fleet Server**, qui transforme l'agent en Fleet Server. Il s'y ajoute la supervision de l'agent lui-même (logs et métriques de monitoring).
- **Fleet server hosts** : `https://fleet-server:8220`. C'est l'adresse que les agents utilisent pour récupérer leur politique et envoyer leur état (le *check-in*).
- **Outputs** : `https://es01:9200` et `https://es02:9200`. La ligne `ssl.certificate_authorities` indique aux agents la CA à utiliser pour faire confiance aux certificats auto-signés d'Elasticsearch. Sans elle, la connexion TLS serait refusée.

</details>

> **Question :** pourquoi la sortie liste-t-elle **es01 et es02** plutôt qu'un seul nœud ?

<details>
<summary>💡 Réponse</summary>

Pour la **tolérance aux pannes** et la **répartition de charge**. L'agent répartit ses envois entre les nœuds listés. Si l'un d'eux tombe, il continue d'envoyer ses données à l'autre. Avec un seul nœud, l'arrêt d'es01 bloquerait toute la collecte, même si le cluster restait disponible grâce à es02.

</details>

---

## Partie 2 : créer une politique d'agent

1. **Fleet** → **Agent policies** → **Create agent policy**.
2. Nom : `Postes formation`.
3. Laissez cochée l'option **Collect system logs and metrics** : l'intégration **System** sera ajoutée automatiquement.
4. Cliquez sur **Create agent policy**.
5. Ouvrez la politique `Postes formation` et regardez l'intégration *system-1* : quels logs et quelles métriques collecte-t-elle ?

<details>
<summary>💡 Réponse</summary>

- **Logs** : les journaux système `/var/log/auth.log*` et `/var/log/secure*` (authentifications), ainsi que `/var/log/messages*` et `/var/log/syslog*`. L'intégration propose aussi les journaux d'événements Windows, utiles uniquement sur un hôte Windows.
- **Métriques** : CPU, charge (load), mémoire, réseau, processus (et résumé des processus), uptime, système de fichiers et socket summary, collectées toutes les 10 secondes par défaut (1 minute pour les systèmes de fichiers).

Chaque type de logs ou de métriques peut être activé, désactivé ou paramétré séparément.

</details>

---

## Partie 3 : récupérer un jeton d'enrôlement

Chaque politique possède son propre **jeton d'enrôlement** (enrollment token). L'agent l'utilise une seule fois pour s'inscrire auprès de Fleet et rejoindre la bonne politique.

1. **Fleet** → onglet **Enrollment tokens**.
2. Repérez la ligne de la politique `Postes formation`, puis cliquez sur l'icône 👁 pour afficher le **secret**.
3. Copiez-le : vous en avez besoin à la partie suivante.

> **Question :** que se passerait-il si vous utilisiez le jeton de *Fleet Server Policy* ?

<details>
<summary>💡 Réponse</summary>

L'agent rejoindrait la politique *Fleet Server Policy* : c'est **le jeton qui détermine la politique**. Il recevrait donc l'intégration Fleet Server et tenterait de devenir lui-même un Fleet Server, au lieu de collecter les logs et métriques système. C'est pour ça qu'on crée une politique par type de machine (serveurs web, bases de données, postes…), chacune avec son propre jeton.

</details>

---

## Partie 4 : enrôler un Elastic Agent

On lance un nouvel Elastic Agent dans un conteneur, sur le même réseau que la stack.

1. Ouvrez un terminal et vérifiez le nom du réseau et du volume de certificats de la stack :

   ```bash
   docker network ls | grep tp3     # attendu : tp3_default
   docker volume ls | grep certs    # attendu : tp3_certs
   ```

2. Lancez l'agent en remplaçant `<VOTRE_JETON>` par le jeton copié :

   ```bash
   docker run -d --name agent-01 --hostname agent-01 \
     --network tp3_default \
     --user root \
     -v tp3_certs:/certs:ro \
     -v /var/run/docker.sock:/var/run/docker.sock:ro \
     -e FLEET_ENROLL=1 \
     -e FLEET_URL=https://fleet-server:8220 \
     -e FLEET_CA=/certs/ca/ca.crt \
     -e FLEET_ENROLLMENT_TOKEN=<VOTRE_JETON> \
     docker.elastic.co/beats/elastic-agent:8.18.2
   ```

   | Paramètre | Rôle |
   |---|---|
   | `FLEET_ENROLL=1` | demande à l'agent de s'enrôler au démarrage |
   | `FLEET_URL` | adresse du Fleet Server |
   | `FLEET_CA` | autorité de certification pour faire confiance au certificat du Fleet Server |
   | `FLEET_ENROLLMENT_TOKEN` | jeton qui indique la politique à rejoindre |
   | `-v tp3_certs:/certs` | donne accès à la CA, utilisée aussi pour parler à Elasticsearch |
   | `-v /var/run/docker.sock` | servira à la partie 6 (intégration Docker) |

3. Suivez l'enrôlement :

   ```bash
   docker logs -f agent-01
   ```

   Repérez la ligne *Successfully enrolled the Elastic Agent*, puis faites `Ctrl+C`.

4. Dans **Fleet** → **Agents** : `agent-01` apparaît dans la politique `Postes formation`. Attendez qu'il passe à l'état **Healthy**.

---

## Partie 5 : vérifier les données

1. Cliquez sur `agent-01` dans la liste des agents :
   - onglet **Agent details** : version, politique, dernière activité (*last check-in*) ;
   - onglet **Logs** : les logs de l'agent lui-même, consultables sans se connecter à la machine.
2. **Discover** : créez une vue de données sur `metrics-*`, puis filtrez sur `host.name : "agent-01"`.
3. **Dashboards** : ouvrez **[Metrics System] Host overview** et sélectionnez l'hôte `agent-01`.
4. **Fleet** → **Data streams** : quels data streams ont été créés ? Décomposez un nom, par exemple `metrics-system.cpu-default` :
   - `metrics` : le **type** de données ;
   - `system.cpu` : le **dataset** ;
   - `default` : le **namespace**.

> **Question :** où ces flux auraient-ils été configurés avec Metricbeat ? Combien de fichiers aurait-il fallu modifier, et sur combien de machines ?

<details>
<summary>💡 Réponse</summary>

Avec Metricbeat (et Filebeat pour les logs), la configuration se fait **localement sur chaque machine**, dans `metricbeat.yml` et les fichiers de `modules.d/` (par exemple `system.yml`). Il faut aussi un Filebeat à part pour les logs. Il aurait donc fallu modifier **plusieurs fichiers, sur chacune des machines**, puis redémarrer les beats.

Avec Fleet, on modifie **une seule politique dans Kibana**, et tous les agents qui en font partie se mettent à jour automatiquement. Un seul agent remplace aussi plusieurs beats.

</details>

---

## Partie 6 : modifier la politique à chaud

On va ajouter une intégration **sans toucher à l'agent**.

1. **Fleet** → **Agent policies** → `Postes formation` → **Add integration**.
2. Cherchez **Docker**, puis **Add Docker**.
3. Laissez les métriques par défaut. Vérifiez que *Docker Host* vaut `unix:///var/run/docker.sock`.
4. Choisissez *Existing hosts* → `Postes formation`, puis **Save and continue**.
5. Dans **Fleet** → **Agents**, la colonne *Last activity* et la révision de la politique (*rev.*) de `agent-01` changent en quelques secondes.
6. Ouvrez le dashboard **[Metrics Docker] Overview** : vous voyez les conteneurs de la formation (es01, es02, kibana, fleet-server…).

> **Question :** qu'a-t-il fallu faire sur la machine de l'agent pour qu'il collecte ces nouvelles métriques ?

<details>
<summary>💡 Réponse</summary>

**Rien.** Lors de son *check-in* régulier, l'agent a récupéré la nouvelle révision de sa politique auprès du Fleet Server, puis il a démarré lui-même la collecte Docker. C'est tout l'intérêt de Fleet : une gestion **centralisée** des agents.

La seule condition, c'était que l'agent ait accès à la source de données : ici, le socket Docker monté avec `-v /var/run/docker.sock` à la partie 4. Il faut l'anticiper lors du déploiement des agents.

</details>

---

## Partie 7 : un deuxième agent, puis du ménage

1. Lancez un **deuxième agent** `agent-02` avec la même commande que `agent-01`, en changeant `--name` et `--hostname`.
2. Vérifiez dans **Fleet** qu'il reçoit **directement** la politique complète, intégration Docker comprise.
3. **Désenrôlez** `agent-02` : sélectionnez-le, puis **Actions** → **Unenroll agent**. Que devient-il dans la liste ? Que disent ses logs (`docker logs agent-02`) ?
4. **Révoquez** le jeton de `Postes formation` (onglet **Enrollment tokens**), puis essayez de lancer un `agent-03` avec ce jeton. Que se passe-t-il ?
5. Créez un nouveau jeton pour la politique : **Create enrollment token**.

<details>
<summary>💡 Réponses</summary>

- **Étape 2** : `agent-02` reçoit immédiatement la **dernière révision** de la politique, intégration Docker comprise. Un nouvel agent n'a rien à rattraper : il récupère toujours la politique telle qu'elle est au moment de son enrôlement.
- **Étape 3** : `agent-02` disparaît de la liste des agents actifs. On peut le revoir en cochant le filtre *Inactive* / *Unenrolled*. Dans ses logs, l'agent indique qu'il a été désenrôlé : il arrête ses collectes et ne contacte plus le Fleet Server. Le conteneur, lui, continue de tourner : le désenrôlement ne désinstalle rien.
- **Étape 4** : l'enrôlement d'`agent-03` **échoue**. Les logs affichent une erreur d'authentification (jeton invalide ou inactif). Révoquer un jeton empêche tout **nouvel** enrôlement avec ce jeton, mais **ne touche pas les agents déjà enrôlés** : `agent-01` continue de fonctionner. En production, c'est utile quand un jeton a fuité.

</details>

---

## Bonus : tolérance aux pannes

1. Dans Portainer, **arrêtez le conteneur es01** de la stack tp3.
2. Les données d'`agent-01` arrivent-elles toujours dans Discover (rafraîchissez sur les 5 dernières minutes) ? Pourquoi ?
3. Kibana répond-il toujours ? Pourquoi ? (Indice : regardez la variable `ELASTICSEARCH_HOSTS` du service `kibana` dans `tp3.yml`.)
4. Redémarrez es01.

<details>
<summary>💡 Réponses</summary>

- **Les données arrivent toujours** : la sortie Fleet liste es01 **et** es02. L'agent constate qu'es01 ne répond plus et envoie tout à es02. Le cluster reste disponible parce qu'es02 est toujours là et que les index ont des réplicas, s'ils ont pu être alloués. Une brève coupure de quelques secondes est possible au moment de la bascule.
- **Kibana répond toujours** : dans `tp3.yml`, la variable `ELASTICSEARCH_HOSTS` du service `kibana` liste aussi les deux nœuds (`https://es01:9200` et `https://es02:9200`). Kibana bascule donc sur es02.
- **À retenir** : la haute disponibilité ne vient pas seulement du nombre de nœuds. Il faut aussi que **chaque client** (agents, Kibana, Logstash, applications…) connaisse plusieurs nœuds.

</details>

---

## En cas de problème

| Symptôme | Piste |
|---|---|
| Aucun agent dans Fleet après le démarrage de tp3 | Logs des conteneurs `fleet-setup` puis `fleet-server` dans Portainer. Il faut un accès Internet pour télécharger les intégrations. |
| `agent-01` reste *Offline* ou *Updating* | `docker logs agent-01`. Vérifiez le réseau (`tp3_default`) et le volume (`tp3_certs`). |
| `x509: certificate signed by unknown authority` | Le volume de certificats n'est pas monté ou `FLEET_CA` est faux. |
| `invalid enrollment token` | Jeton mal copié, révoqué, ou appartenant à une autre politique. |
| `Error response from daemon: Conflict` | Un conteneur `agent-01` existe déjà : `docker rm -f agent-01`. |

## Nettoyage

```bash
docker rm -f agent-01 agent-02 agent-03 2>/dev/null
```

Puis, dans Portainer, arrêtez la stack **tp3**.

> Les agents supprimés restent visibles dans Fleet à l'état *Offline*. Vous pouvez les désenrôler depuis l'interface.
