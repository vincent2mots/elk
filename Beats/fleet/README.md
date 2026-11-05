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

> **Question :** pourquoi la sortie liste-t-elle **es01 et es02** plutôt qu'un seul nœud ?

---

## Partie 2 : créer une politique d'agent

1. **Fleet** → **Agent policies** → **Create agent policy**.
2. Nom : `Postes formation`.
3. Laissez cochée l'option **Collect system logs and metrics** : l'intégration **System** sera ajoutée automatiquement.
4. Cliquez sur **Create agent policy**.
5. Ouvrez la politique `Postes formation` et regardez l'intégration *system-1* : quels logs et quelles métriques collecte-t-elle ?

---

## Partie 3 : récupérer un jeton d'enrôlement

Chaque politique possède son propre **jeton d'enrôlement** (enrollment token). L'agent l'utilise une seule fois pour s'inscrire auprès de Fleet et rejoindre la bonne politique.

1. **Fleet** → onglet **Enrollment tokens**.
2. Repérez la ligne de la politique `Postes formation`, puis cliquez sur l'icône 👁 pour afficher le **secret**.
3. Copiez-le : vous en avez besoin à la partie suivante.

> **Question :** que se passerait-il si vous utilisiez le jeton de *Fleet Server Policy* ?

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

---

## Partie 7 : un deuxième agent, puis du ménage

1. Lancez un **deuxième agent** `agent-02` avec la même commande que `agent-01`, en changeant `--name` et `--hostname`.
2. Vérifiez dans **Fleet** qu'il reçoit **directement** la politique complète, intégration Docker comprise.
3. **Désenrôlez** `agent-02` : sélectionnez-le, puis **Actions** → **Unenroll agent**. Que devient-il dans la liste ? Que disent ses logs (`docker logs agent-02`) ?
4. **Révoquez** le jeton de `Postes formation` (onglet **Enrollment tokens**), puis essayez de lancer un `agent-03` avec ce jeton. Que se passe-t-il ?
5. Créez un nouveau jeton pour la politique : **Create enrollment token**.

---

## Bonus : tolérance aux pannes

1. Dans Portainer, **arrêtez le conteneur es01** de la stack tp3.
2. Les données d'`agent-01` arrivent-elles toujours dans Discover (rafraîchissez sur les 5 dernières minutes) ? Pourquoi ?
3. Kibana répond-il toujours ? Pourquoi ? (Indice : regardez la variable `ELASTICSEARCH_HOSTS` du service `kibana` dans `tp3.yml`.)
4. Redémarrez es01.

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
