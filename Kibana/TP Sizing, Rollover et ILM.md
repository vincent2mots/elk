# 📏 Travaux Pratiques : Sizing, rollover & ILM

Cette série d'exercices montre **pourquoi le rollover a changé la manière de dimensionner** un cluster Elasticsearch. Avant, on choisissait un nombre de shards en fonction du volume attendu d'un index (journalier, mensuel). Avec le rollover, on fixe une **taille cible de shard**, et le nombre total de shards devient une **conséquence** du volume journalier et de la rétention.

*(Pour la théorie — shards, réplicas, data streams, phases ILM, data tiers — voir les parties "Sizing" et "Cycle de vie de la donnée" du support de formation. Les templates composables sont traités dans le TP "Templates & ECS".)*

Tous les exercices se font dans **Dev Tools**, sauf le TP 9 (papier ou tableur). Ils s'appuient sur le jeu de démo **Sample web logs** (`kibana_sample_data_logs`), à installer depuis la page d'accueil de Kibana.

> ℹ️ Selon la version de Kibana, la date des documents de ce jeu est stockée dans `@timestamp` ou dans `timestamp`. Les scripts de réindexation gèrent les deux cas. Pour vérifier : `GET kibana_sample_data_logs/_search?size=1&_source=*timestamp*`

---

## 📚 Rappels express

| Règle | Ancienne approche (index datés) | Approche actuelle (rollover / data stream) |
|---|---|---|
| Ce qu'on choisit | le **nombre de shards** d'un index journalier ou mensuel | la **taille cible d'un shard** (`max_primary_shard_size`) |
| Taille d'un shard | fonction du volume du jour : très variable | **10 à 50 Go** et < 200 M documents, bornée par le rollover |
| `number_of_shards` | dimensionné sur le volume total de l'index | dimensionné sur le **parallélisme d'écriture** (souvent 1, au plus ≈ nombre de nœuds hot) |
| Nombre total de shards | choisi | **calculé** : volume/jour × rétention ÷ taille cible × (1 + réplicas) |
| Changer le nombre de shards | réindexer | modifier le template, puis **rollover** (ou `_split` / `_shrink`) |

Les politiques ILM fournies par Elastic (`logs@lifecycle`, `metrics@lifecycle`…) utilisent par défaut `max_primary_shard_size: 50gb` et `max_age: 30d`.

### Préparation : accélérer ILM pour la salle de formation
ILM ne vérifie les conditions que **toutes les 10 minutes** par défaut. Pour les TP :
```json
PUT _cluster/settings
{ "persistent": { "indices.lifecycle.poll_interval": "10s" } }
```
⚠️ À remettre à `null` en fin de session (voir Nettoyage). Ne jamais faire ça en production.

---

## 🧪 Niveau 1 : Mesurer avant de dimensionner

### TP 1 : Le ratio brut → indexé
* **Objectif** : Mesurer ce que coûte réellement un document une fois indexé, et quels champs pèsent le plus.
* **Commandes** :
  ```json
  GET _cat/indices/kibana_sample_data_logs?v&h=index,docs.count,pri.store.size,store.size

  POST kibana_sample_data_logs/_disk_usage?run_expensive_tasks=true
  ```
* **À observer** :
  - `store.size` = `pri.store.size` × (1 + réplicas). Le disque à prévoir inclut **toujours** les réplicas.
  - Dans `_disk_usage`, repérer les champs les plus lourds (`message`, `request`, `_source`…). Diviser `pri.store.size` par `docs.count` pour obtenir un **coût moyen par document**.
* **À retenir** : c'est cette mesure, faite sur un échantillon représentatif (POC), qui alimente le calcul de sizing du TP 9. Une estimation "à l'intuition" peut se tromper d'un facteur 2 à 3.

### TP 2 : Le mode `logsdb`
* **Objectif** : Constater l'effet du mode d'index `logsdb`, appliqué par défaut aux data streams `logs-*-*` en v9.
* **Commandes** :
  ```json
  PUT tp-standard
  { "settings": { "number_of_shards": 1, "number_of_replicas": 0 } }

  PUT tp-logsdb
  { "settings": { "index.mode": "logsdb", "number_of_shards": 1, "number_of_replicas": 0 } }

  POST _reindex
  { "source": { "index": "kibana_sample_data_logs" }, "dest": { "index": "tp-standard" },
    "script": { "source": "if (ctx._source['@timestamp'] == null) { ctx._source['@timestamp'] = ctx._source.timestamp }" } }

  POST _reindex
  { "source": { "index": "kibana_sample_data_logs" }, "dest": { "index": "tp-logsdb" },
    "script": { "source": "if (ctx._source['@timestamp'] == null) { ctx._source['@timestamp'] = ctx._source.timestamp }" } }

  POST tp-standard,tp-logsdb/_forcemerge?max_num_segments=1
  GET _cat/indices/tp-standard,tp-logsdb?v&h=index,docs.count,pri.store.size
  ```
* **À observer** : l'écart de taille entre les deux index pour les mêmes documents. Le `forcemerge` sert à comparer à état égal.
* **Discussion** : le gain dépend de la licence (la *synthetic source*, qui ne stocke plus `_source` tel quel, n'est pas disponible avec toutes les licences). Moralité : le ratio du TP 1 doit être mesuré **dans le mode d'index réellement utilisé** en production.

---

## 🧱 Niveau 2 : Le nombre de shards n'est plus gravé dans le marbre

### TP 3 : Pourquoi on ne peut pas "ajouter un shard"
* **Objectif** : Comprendre le routage, qui explique la règle "on ne change pas le nombre de shards à chaud".
* **Commandes** :
  ```json
  PUT tp-routage
  { "settings": { "number_of_shards": 3, "number_of_replicas": 0 } }

  PUT tp-routage/_doc/client-42
  { "nom": "Dupont" }

  GET _cat/shards/tp-routage?v&h=index,shard,prirep,docs
  GET tp-routage/_search_shards?routing=client-42
  ```
* **À observer** : le document entier est placé dans **un seul** shard. Elasticsearch calcule `hash(_routing) % nombre_de_shards_primaires`, avec `_routing` = `_id` par défaut. Un document n'est **jamais découpé** entre plusieurs shards. Si le nombre de shards change, la formule change et plus aucun document n'est à sa place.

### TP 4 : `_split` et `_shrink`
* **Objectif** : Voir qu'on peut quand même changer le nombre de shards d'un index existant, à condition de le passer en lecture seule.
* **Commandes** :
  ```json
  # Tentative directe → refusée
  PUT tp-routage/_settings
  { "index.number_of_shards": 6 }

  # Split : multiplier le nombre de shards (facteur entier)
  PUT tp-routage/_settings
  { "index.blocks.write": true }

  POST tp-routage/_split/tp-routage-x2
  { "settings": { "index.number_of_shards": 6 } }

  # Shrink : diviser le nombre de shards (diviseur entier)
  POST tp-routage/_shrink/tp-routage-1
  { "settings": { "index.number_of_shards": 1, "index.blocks.write": null } }

  GET _cat/indices/tp-routage*?v&h=index,pri,docs.count
  ```
* **À observer** : la modification directe échoue. `_split` et `_shrink` créent un **nouvel index**, sans réindexer (ils réutilisent les segments par liens physiques, d'où leur rapidité). C'est exactement ce que fait l'action `shrink` d'ILM en phase warm (TP 6).

---

## 🔄 Niveau 3 : Index datés contre rollover

### TP 5 : Le problème des index journaliers
* **Objectif** : Reproduire le scénario "30 index de 600 Mo" de la slide granularité.
* **Commandes** :
  ```json
  PUT _index_template/tp-daily
  { "index_patterns": ["tp-daily-*"], "priority": 500,
    "template": { "settings": { "number_of_shards": 1, "number_of_replicas": 0 } } }

  POST _reindex
  { "source": { "index": "kibana_sample_data_logs" },
    "dest":   { "index": "tp-daily" },
    "script": { "source": "def ts = ctx._source['@timestamp'] != null ? ctx._source['@timestamp'] : ctx._source.timestamp; ctx._index = 'tp-daily-' + ts.toString().substring(0,10)" } }

  GET _cat/indices/tp-daily-*?v&h=index,docs.count,pri.store.size&s=index
  GET _cat/shards/tp-daily-*?h=index&format=json&filter_path=**.index
  ```
* **À observer** : des dizaines d'index de quelques centaines de Ko chacun, soit **un shard par jour** quel que soit le volume. Le jour où le trafic est multiplié par 10 (campagne marketing, incident), l'index du jour grossit sans aucune limite.
* **Question aux stagiaires** : avec 3 applications, une rétention d'un an et 1 réplica, combien de shards cette stratégie génère-t-elle ? (3 × 365 × 2 = **2 190 shards**, quel que soit le volume.)

### TP 6 : Le même flux avec un data stream et ILM
* **Objectif** : Laisser ILM découper le flux par **taille**, et observer le passage hot → warm → delete.
* **Étape 1 — politique et template** :
  ```json
  PUT _ilm/policy/tp-logs-policy
  {
    "policy": {
      "phases": {
        "hot": {
          "actions": { "rollover": { "max_primary_shard_size": "2mb", "max_age": "30d" } }
        },
        "warm": {
          "min_age": "3m",
          "actions": {
            "shrink":     { "number_of_shards": 1 },
            "forcemerge": { "max_num_segments": 1 }
          }
        },
        "delete": {
          "min_age": "15m",
          "actions": { "delete": {} }
        }
      }
    }
  }

  PUT _index_template/tp-ds
  {
    "index_patterns": ["tp-ds-*"],
    "data_stream": {},
    "priority": 500,
    "template": {
      "settings": {
        "number_of_shards": 2,
        "number_of_replicas": 0,
        "index.lifecycle.name": "tp-logs-policy"
      },
      "mappings": { "properties": { "@timestamp": { "type": "date" } } }
    }
  }
  ```
  *(La taille de 2 Mo remplace les 50 Go de production, pour voir des rollovers en quelques minutes.)*
* **Étape 2 — alimenter par lots** : lancer la commande ci-dessous **5 fois**, en remplaçant la valeur par `win 8`, `win xp`, `win 7`, `ios` puis `osx`, et en attendant ~20 s entre deux lots.
  ```json
  POST _reindex
  { "source": { "index": "kibana_sample_data_logs",
                "query": { "term": { "machine.os.keyword": "win 8" } } },
    "dest":   { "index": "tp-ds-weblogs", "op_type": "create" },
    "script": { "source": "if (ctx._source['@timestamp'] == null) { ctx._source['@timestamp'] = ctx._source.timestamp }" } }
  ```
* **Étape 3 — observer** :
  ```json
  GET _data_stream/tp-ds-weblogs
  GET _cat/indices/.ds-tp-ds-weblogs-*?v&h=index,pri,docs.count,pri.store.size&s=index&expand_wildcards=all
  GET .ds-tp-ds-weblogs-*/_ilm/explain?filter_path=indices.*.phase,indices.*.action,indices.*.age
  ```
* **À observer** :
  - Les backing index ont tous une **taille comparable**, quel que soit le nombre de jours qu'ils couvrent. Comparer avec le TP 5.
  - Après quelques minutes, les index passés en warm n'ont plus **qu'un seul shard** (`shrink`), et un nom préfixé `shrink-`.
  - Le compteur `age` démarre **au rollover**, pas à la création de l'index. Une donnée vit donc au plus *durée avant rollover* + `min_age` de la phase delete. C'est pour ça qu'on combine toujours `max_primary_shard_size` avec un `max_age`, sinon une source à faible volume garde le même index pendant des mois.
  - L'index d'écriture (le plus récent) reste en hot avec ses 2 shards.

### TP 7 : Changer le nombre de shards… sans rien casser
* **Objectif** : Démontrer que, sur un data stream, on change le nombre de shards en modifiant le template.
* **Commandes** :
  ```json
  # Le template se remplace en entier : on renvoie toutes les sections
  PUT _index_template/tp-ds
  {
    "index_patterns": ["tp-ds-*"], "data_stream": {}, "priority": 500,
    "template": {
      "settings": { "number_of_shards": 1, "number_of_replicas": 0,
                    "index.lifecycle.name": "tp-logs-policy" },
      "mappings": { "properties": { "@timestamp": { "type": "date" } } }
    }
  }

  POST tp-ds-weblogs/_rollover?lazy=true

  POST tp-ds-weblogs/_doc
  { "@timestamp": "2026-10-28T09:00:00Z", "message": "premier document après le changement" }

  GET _cat/indices/.ds-tp-ds-weblogs-*?v&h=index,pri,docs.count&s=index&expand_wildcards=all
  ```
* **À observer** : seul le **nouveau** backing index a 1 shard, les anciens sont intacts. Avec `?lazy=true`, le rollover n'a lieu qu'à la prochaine écriture, ce qui évite de créer un index vide.

---

## 🚨 Niveau 4 : ILM en panne et alternative

### TP 8 : Diagnostiquer une politique en erreur
* **Objectif** : Reproduire l'erreur ILM la plus fréquente sur un index "classique" (hors data stream).
* **Étape 1 — provoquer l'erreur** :
  ```json
  PUT _ilm/policy/tp-classique-policy
  { "policy": { "phases": { "hot": { "actions": { "rollover": { "max_docs": 5 } } } } } }

  PUT tp-classique-000001
  { "settings": { "index.lifecycle.name": "tp-classique-policy", "number_of_replicas": 0 } }

  POST tp-classique-000001/_doc
  { "message": "test" }

  # Patienter ~20 s
  GET tp-classique-000001/_ilm/explain
  ```
* **À observer** : `"step": "ERROR"` et un message indiquant que `index.lifecycle.rollover_alias` n'est pas défini. Hors data stream, un rollover a besoin d'un **alias d'écriture**.
* **Étape 2 — corriger et relancer** :
  ```json
  POST _aliases
  { "actions": [ { "add": { "index": "tp-classique-000001", "alias": "tp-classique", "is_write_index": true } } ] }

  PUT tp-classique-000001/_settings
  { "index.lifecycle.rollover_alias": "tp-classique" }

  POST tp-classique-000001/_ilm/retry
  GET tp-classique-000001/_ilm/explain
  ```
* **À retenir** : `_ilm/explain` est le premier réflexe dès qu'un index "ne bascule pas". Dans Kibana : *Stack Management > Index Management*, les index en erreur ILM sont signalés. Les data streams évitent ce piège : le rollover y est natif, sans alias à gérer.

### TP 9 (bonus) : Data stream lifecycle, l'alternative simple
* **Objectif** : Découvrir le *data stream lifecycle*, plus simple qu'ILM quand on n'a besoin que d'une rétention.
* **Commandes** :
  ```json
  PUT _index_template/tp-dsl
  { "index_patterns": ["tp-dsl-*"], "data_stream": {}, "priority": 500,
    "template": {
      "settings": { "number_of_replicas": 0 },
      "lifecycle": { "data_retention": "7d" } } }

  POST tp-dsl-app/_doc
  { "@timestamp": "2026-10-28T09:00:00Z", "message": "hello" }

  GET _data_stream/tp-dsl-app/_lifecycle
  GET .ds-tp-dsl-app-*/_lifecycle/explain?expand_wildcards=all
  ```
* **Discussion** : on déclare **quoi** (une rétention), Elasticsearch gère **comment** (rollover automatique, fusion des segments). Pas de phases, pas de data tiers. ILM reste nécessaire pour hot/warm/cold/frozen, shrink et searchable snapshots. Si les deux sont configurés, ILM l'emporte par défaut.

---

## 🧮 Niveau 5 : Exercice de dimensionnement

### TP 10 : Dimensionner un cluster de logs
* **Énoncé** :
  - 3 sources : pare-feu **120 Go/jour**, Apache **40 Go/jour**, application métier **15 Go/jour** (volumes bruts).
  - Ratio brut → indexé mesuré lors du POC (TP 1) : **1,0**.
  - Rétention : **7 jours en hot** (SSD), puis **warm jusqu'à 30 jours**, puis suppression.
  - **1 réplica** partout. Taille cible des shards : **50 Go** (rollover).
  - Les disques ne doivent pas dépasser **85 %** (seuil `low watermark`).
* **Questions** :
  1. Volume total sur disque en hot ? en warm ?
  2. Combien de nœuds hot de 2 To et de nœuds warm de 8 To ?
  3. Combien de shards au total sur le cluster ? Est-ce la limite des 1 000 shards par nœud qui dimensionne le cluster ?
  4. Quel `number_of_shards` pour chaque source ? Quel `max_age` pour l'application métier ?
* **Correction** :
  1. Volume indexé par jour : 175 Go. Hot : 175 × 7 × 2 = **2,45 To**, soit 2,9 To en tenant compte des 85 %. Warm : 175 × 23 × 2 = **8,05 To**, soit 9,5 To.
  2. **2 nœuds hot** de 2 To (4 To utiles) ; **2 nœuds warm** de 8 To (16 To, marge confortable). Si on veut 3 nœuds pour la tolérance aux pannes, la contrainte de disponibilité l'emporte sur la contrainte de volume.
  3. 175 × 30 = 5 250 Go primaires ÷ ~50 Go ≈ **105 shards primaires**, donc ~210 avec les réplicas, moins de 60 par nœud. Ce n'est **pas** le nombre de shards qui dimensionne le cluster, c'est le **disque**. La limite de 1 000 shards par nœud ne devient un problème qu'avec des index trop petits (cf. TP 5).
  4. Pare-feu : 2 shards (un par nœud hot, pour répartir l'écriture), rollover toutes les ~20 h. Apache : 1 shard, rollover tous les ~1,25 jours. Application : 1 shard, mais 50 Go = ~3,3 jours, ce qui convient. Avec une source à 1 Go/jour, il faudrait `max_age: 7d` pour que la suppression reste fidèle à la rétention.
* **Variante** : refaire le calcul avec `logsdb` et un ratio mesuré de 0,5 (TP 2). Combien de nœuds économise-t-on ?

---

## 🎓 Pour aller plus loin

- **Taille des shards** : la recommandation actuelle est 10 à 50 Go par shard et moins de 200 millions de documents. L'ancienne règle "20 shards par Go de heap" a été retirée de la documentation en 8.3. La vraie contrainte mémoire est le nombre de **champs mappés** par index et par nœud.
- **`cluster.max_shards_per_node`** (1 000 par défaut) est une **limite de sécurité configurable**, pas une limite physique.
- **Data tiers** : les rôles `data_hot`, `data_warm`, `data_cold`, `data_frozen` et le setting `index.routing.allocation.include._tier_preference` déplacent automatiquement les index d'un tier à l'autre au fil des phases ILM.
- **Cold / frozen** : les *searchable snapshots* (index montés depuis un dépôt S3, Azure, GCS…) nécessitent une licence Enterprise. Une phase cold "simple" (sans snapshot) reste gratuite.
- Référence : [Size your shards](https://www.elastic.co/guide/en/elasticsearch/reference/current/size-your-shards.html), [Data stream lifecycle](https://www.elastic.co/search-labs/blog/data-lifecycle-simplified-for-data-streams).

## 🧹 Nettoyage
```json
DELETE _data_stream/tp-ds-weblogs,tp-dsl-app
DELETE tp-standard,tp-logsdb,tp-routage*,tp-daily-*,tp-classique-*
DELETE _index_template/tp-daily,tp-ds,tp-dsl
DELETE _ilm/policy/tp-logs-policy
DELETE _ilm/policy/tp-classique-policy
PUT _cluster/settings
{ "persistent": { "indices.lifecycle.poll_interval": null } }
```

## 🛠 Prérequis
1. Une instance Elasticsearch & Kibana v8.14+ ou v9.x (le `?lazy=true` du TP 7 et le data stream lifecycle du TP 9 en dépendent). Un seul nœud suffit : tous les TP utilisent `number_of_replicas: 0`.
2. Le jeu de données **Sample web logs** installé.
3. Un utilisateur avec les droits `manage`, `manage_ilm`, `manage_index_templates` et les droits sur les index `tp-*` et `kibana_sample_data_logs`.