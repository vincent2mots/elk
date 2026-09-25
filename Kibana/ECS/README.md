# 🧩 Travaux Pratiques : Templates d'index & ECS

Cette série d'exercices montre **pourquoi le typage des champs est décisif** dans Elasticsearch, comment les **templates composables** le garantissent, et comment un simple template mal placé peut casser des dashboards en production. Le fil rouge est un cas réel : des logs Filebeat dont les IP, les URL et les coordonnées GPS se retrouvent mal typées du jour au lendemain.

*(Pour la théorie complète — mapping, types de champs, cycle de vie des index — voir la partie "Mapping & Templates" du support de formation.)*

Tous les exercices se font dans **Dev Tools**, sauf le TP 8 qui se termine dans **Stack Management > Data Views**.

---

## 📚 Rappels express

### ECS (Elastic Common Schema)
ECS est un **dictionnaire de noms et de types de champs** commun à toute la stack : Beats, Elastic Agent, Logstash, intégrations, règles de sécurité, dashboards prêts à l'emploi. Un même concept porte partout le même nom et le même type :

| Champ ECS | Type attendu | Ce que le type permet |
|---|---|---|
| `source.ip`, `host.ip`, `related.ip` | `ip` | recherche par plage CIDR (`10.0.0.0/8`), agrégations |
| `source.geo.location` | `geo_point` | cartes, requêtes de distance |
| `url.path`, `url.original` | `wildcard` (ou `keyword`) | agrégations, recherche `*motif*` performante |
| `error.type`, `event.category` | `keyword` | agrégations `terms`, filtres exacts |
| `message` | `match_only_text` / `text` | recherche plein texte |

Respecter ECS, c'est ce qui fait fonctionner **sans adaptation** les dashboards, les règles SIEM et les corrélations entre sources.

### Templates legacy vs composables

| | Legacy (`_template`) | Composable (`_index_template`) |
|---|---|---|
| Apparition | historique, **déprécié** | 7.8+, **recommandé** |
| Plusieurs templates correspondent | tous **fusionnés** selon `order` | **un seul** gagne : la plus haute `priority` |
| Réutilisation | aucune | assemblage de **component templates** via `composed_of` |
| Règle d'or | ignoré dès qu'un composable correspond | toujours prioritaire sur le legacy |

---

## 🧪 Niveau 1 : Sans template — le mapping dynamique à l'œuvre

### TP 1 : Laisser Elasticsearch deviner les types
* **Objectif** : Constater que le mapping dynamique ne connaît pas ECS.
* **Commandes** :
  ```json
  POST tp-sans-template/_doc
  {
    "@timestamp": "2026-09-02T06:00:00Z",
    "host":   { "ip": "10.0.0.12" },
    "source": { "ip": "81.250.12.4", "geo": { "location": { "lat": 48.85, "lon": 2.35 } } },
    "url":    { "path": "/api/orders/42" },
    "error":  { "type": 500 },
    "message": "GET /api/orders/42 500"
  }

  GET tp-sans-template/_mapping
  ```
* **À observer** :
  - `host.ip` / `source.ip` → `text` + sous-champ `.keyword` (et non `ip`)
  - `source.geo.location` → `object` avec deux `float` (et non `geo_point`)
  - `url.path` → `text` + `.keyword`
  - `error.type` → `long` (la **première valeur reçue** a décidé du type)

### TP 2 : Les conséquences concrètes
* **Objectif** : Reproduire les erreurs vues dans les dashboards.
* **Requêtes** :
  ```json
  # a) Agrégation sur un champ text → erreur "Fielddata is disabled on [url.path]"
  GET tp-sans-template/_search
  { "size": 0, "aggs": { "top_urls": { "terms": { "field": "url.path" } } } }

  # b) Recherche par plage d'IP → ne renvoie rien (ou erreur) car ce n'est pas un champ ip
  GET tp-sans-template/_search
  { "query": { "term": { "source.ip": "81.250.0.0/16" } } }

  # c) Requête géographique → erreur, le champ n'est pas un geo_point
  GET tp-sans-template/_search
  { "query": { "geo_distance": { "distance": "10km",
      "source.geo.location": { "lat": 48.85, "lon": 2.35 } } } }
  ```
* **À retenir** : l'erreur `Fielddata is disabled` n'est **pas** un problème de configuration à contourner avec `fielddata: true`. C'est le symptôme d'un **mauvais mapping**.

### TP 3 : Le premier document fait la loi
* **Objectif** : Montrer qu'un type est figé dès la création du champ.
* **Commandes** :
  ```json
  POST tp-sans-template/_doc
  { "@timestamp": "2026-09-02T06:01:00Z", "error": { "type": "java.net.SocketTimeoutException" } }
  ```
* **À observer** : le document est **rejeté** (`document_parsing_exception`), car `error.type` est déjà un `long`. Un mapping ne se modifie pas : il faut **réindexer**.

---

## 🏗 Niveau 2 : Templates composables

### TP 4 : Construire un template à partir de briques
* **Objectif** : Définir des mappings ECS réutilisables dans des **component templates**, puis les assembler.
* **Commandes** :
  ```json
  PUT _component_template/tp-ecs-reseau
  {
    "template": {
      "mappings": {
        "properties": {
          "host":    { "properties": { "ip": { "type": "ip" } } },
          "related": { "properties": { "ip": { "type": "ip" } } },
          "source":  { "properties": {
            "ip":  { "type": "ip" },
            "geo": { "properties": { "location": { "type": "geo_point" } } }
          } }
        }
      }
    }
  }

  PUT _component_template/tp-ecs-web
  {
    "template": {
      "mappings": {
        "properties": {
          "url":   { "properties": { "path": { "type": "wildcard" } } },
          "error": { "properties": { "type": { "type": "keyword", "ignore_above": 1024 } } },
          "message": { "type": "match_only_text" }
        }
      }
    }
  }

  PUT _component_template/tp-settings
  { "template": { "settings": { "number_of_shards": 1, "number_of_replicas": 0 } } }

  PUT _index_template/tp-logs
  {
    "index_patterns": ["tp-logs-*"],
    "priority": 200,
    "composed_of": ["tp-settings", "tp-ecs-reseau", "tp-ecs-web"],
    "template": {
      "mappings": { "dynamic_templates": [
        { "strings_as_keyword": { "match_mapping_type": "string",
            "mapping": { "type": "keyword", "ignore_above": 1024 } } }
      ] }
    }
  }
  ```
* **Point clé** : l'ordre de `composed_of` compte. En cas de doublon, la **dernière brique** l'emporte, et le bloc `template` du template d'index passe **après toutes les briques**.

### TP 5 : Simuler avant de créer
* **Objectif** : Vérifier ce qu'un index **recevrait**, sans le créer.
* **Commande** :
  ```json
  POST _index_template/_simulate_index/tp-logs-2026.09.02
  ```
* **À observer** : le résultat contient les settings et les mappings fusionnés. Le champ `overlapping` liste les templates qui correspondaient aussi au nom mais ont **perdu** face à celui-ci.
* **Vérification** : rejouer le document du TP 1 dans `tp-logs-2026.09.02`, puis rejouer les trois requêtes du TP 2. Elles fonctionnent toutes, et le document du TP 3 est accepté.

Les requêtes à rejouer : 
  ```json
POST tp-logs-avec-template/_doc
{
  "@timestamp": "2026-09-02T06:00:00Z",
  "host":   { "ip": "10.0.0.12" },
  "source": { "ip": "81.250.12.4", "geo": { "location": { "lat": 48.85, "lon": 2.35 } } },
  "url":    { "path": "/api/orders/42" },
  "error":  { "type": 500 },
  "message": "GET /api/orders/42 500"
}

GET tp-logs-avec-template



# a) Agrégation sur un champ text → maintenant ok
GET tp-logs-avec-template/_search
{ "size": 0, "aggs": { "top_urls": { "terms": { "field": "url.path" } } } }

# b) Recherche par plage d'IP → renvoie bien le document
GET tp-logs-avec-template/_search
{ "query": { "term": { "source.ip": "81.250.0.0/16" } } }

# c) Requête géographique → ok aussi
GET tp-logs-avec-template/_search
{ "query": { "geo_distance": { "distance": "10km",
    "source.geo.location": { "lat": 48.85, "lon": 2.35 } } } }
  ```

### TP 6 : Un seul template gagne
* **Objectif** : Comprendre la règle de priorité des templates composables.
* **Commandes** :
  ```json
  # a) Même priorité + motifs qui se chevauchent → refusé
  PUT _index_template/tp-logs-concurrent
  { "index_patterns": ["tp-logs-*"], "priority": 200,
    "template": { "settings": { "number_of_replicas": 1 } } }

  # b) Priorité supérieure → accepté… et il masque tp-logs
  PUT _index_template/tp-logs-concurrent
  { "index_patterns": ["tp-logs-*"], "priority": 300,
    "template": { "settings": { "number_of_replicas": 1 } } }

  POST _index_template/_simulate_index/tp-logs-2026.09.03
  ```
* **À observer** : en (b), la simulation ne montre **plus aucun mapping ECS**. Contrairement aux templates legacy, les templates composables **ne se fusionnent pas entre eux**. Seul le gagnant s'applique, avec ses propres briques.
* **Nettoyage** : `DELETE _index_template/tp-logs-concurrent`

---

## 🚨 Niveau 3 : Le cas réel — un composable qui masque un legacy

### TP 7 : Reproduire l'incident
* **Objectif** : Rejouer le scénario de production où un template de 3 lignes a désactivé le template Filebeat.
* **Étape 1 — le template legacy "à la Filebeat"** :
  ```json
  PUT _template/tp-filebeat
  {
    "index_patterns": ["tp-filebeat-*"],
    "order": 1,
    "settings": { "index.lifecycle.name": "tp-policy",
                  "index.lifecycle.rollover_alias": "tp-filebeat" },
    "mappings": { "properties": {
      "host":   { "properties": { "ip": { "type": "ip" } } },
      "source": { "properties": { "ip": { "type": "ip" },
                  "geo": { "properties": { "location": { "type": "geo_point" } } } } },
      "url":    { "properties": { "path": { "type": "wildcard" } } },
      "error":  { "properties": { "type": { "type": "keyword" } } }
    } }
  }

  PUT _ilm/policy/tp-policy
  { "policy": { "phases": {
      "hot":    { "actions": { "rollover": { "max_age": "1d" } } },
      "delete": { "min_age": "7d", "actions": { "delete": {} } } } } }

  PUT tp-filebeat-000001
  { "aliases": { "tp-filebeat": { "is_write_index": true } } }

  POST tp-filebeat/_doc
  { "@timestamp": "2026-09-01T06:00:00Z", "host": { "ip": "10.0.0.12" },
    "url": { "path": "/api/x" }, "error": { "type": 500 },
    "source": { "ip": "81.250.12.4", "geo": { "location": { "lat": 48.85, "lon": 2.35 } } } }
  ```
* **Étape 2 — "je veux juste passer les replicas à 0"** :
  ```json
  PUT _index_template/tp-filebeat
  { "index_patterns": ["tp-filebeat-*"],
    "template": { "settings": { "number_of_replicas": 0 } } }
  ```
  👉 Regarder l'en-tête de réponse `warning` : Elasticsearch prévient que ce template **va masquer** le template legacy.
* **Étape 3 — le rollover suivant** :
  ```json
  POST tp-filebeat/_rollover
  POST tp-filebeat/_doc
  { "@timestamp": "2026-09-02T06:00:00Z", "host": { "ip": "10.0.0.12" },
    "url": { "path": "/api/x" }, "error": { "type": 500 },
    "source": { "ip": "81.250.12.4", "geo": { "location": { "lat": 48.85, "lon": 2.35 } } } }

  GET tp-filebeat-*/_mapping/field/host.ip,url.path,error.type,source.geo.location
  GET tp-filebeat-000002/_ilm/explain
  POST _index_template/_simulate_index/tp-filebeat-000099
  ```
* **À observer** :
  - `000001` est correct, alors que `000002` a des types devinés (`text`, `long`, `object`).
  - `000002` n'est **plus géré par ILM** (`"managed": false`). Il ne basculera plus jamais sur un nouvel index et grossira indéfiniment.
  - La simulation ne renvoie que `number_of_replicas: 0`.

### TP 8 : Diagnostiquer comme en production
* **Objectif** : Utiliser les bons outils pour trouver les index fautifs.
* **Requête** :
  ```json
  GET tp-filebeat-*/_field_caps?fields=host.ip,source.ip,url.path,error.type,source.geo.location
  ```
* **À observer** : pour chaque champ en conflit, la réponse liste **quels index** ont quel type. C'est la commande la plus rapide pour isoler un index malade parmi des centaines.
* **Dans Kibana** : créer une data view `tp-filebeat-*`. Les champs apparaissent en **conflit** (`ip, text`, `keyword, long`, `geo_point, object`). Seul `url.path` n'y figure pas, car Kibana range `wildcard` et `text` dans le même type "string". L'agrégation plante pourtant quand même.

### TP 9 : Corriger proprement
* **Objectif** : Dérouler la procédure de correction complète.
* **Commandes** :
  ```json
  # 1. Supprimer la cause
  DELETE _index_template/tp-filebeat
  POST _index_template/_simulate_index/tp-filebeat-000099     # les mappings sont revenus

  # 2. Faire basculer vers un index sain
  POST tp-filebeat/_rollover                                  # → 000003, correctement typé

  # 3. Réparer l'index fautif par réindexation
  POST _reindex
  { "source": { "index": "tp-filebeat-000002" },
    "dest":   { "index": "tp-filebeat-000002-fixed" } }       # le nom correspond au template → bons types

  GET tp-filebeat-000002/_count
  GET tp-filebeat-000002-fixed/_count

  POST _aliases
  { "actions": [
    { "add":    { "index": "tp-filebeat-000002-fixed", "alias": "tp-filebeat", "is_write_index": false } },
    { "remove_index": { "index": "tp-filebeat-000002" } }
  ] }

  # 4. Remettre l'index réparé sous ILM, en indiquant qu'il ne reçoit plus d'écritures
  PUT tp-filebeat-000002-fixed/_settings
  { "index.lifecycle.name": "tp-policy",
    "index.lifecycle.rollover_alias": "tp-filebeat",
    "index.lifecycle.indexing_complete": true }
  ```
* **Vérification** : rafraîchir la data view, les conflits ont disparu.
* **Et si on voulait vraiment 0 replica ?** Le mettre dans le template legacy, ou mieux, **migrer le template legacy vers un template composable**. Une seule source de vérité.

---

## 🧬 Niveau 4 : ECS "clé en main" avec `ecs@mappings`

### TP 10 : Le component template ECS fourni par Elastic
* **Objectif** : Découvrir le component template `ecs@mappings`, livré avec Elasticsearch (8.x+), qui type les champs ECS **d'après leur nom** grâce à des *dynamic templates*.
* **Commandes** :
  ```json
  GET _component_template/ecs@mappings

  PUT _index_template/tp-ecs-auto
  { "index_patterns": ["tp-ecs-auto-*"], "priority": 200,
    "composed_of": ["ecs@mappings"] }

  POST tp-ecs-auto-1/_doc
  { "@timestamp": "2026-09-02T06:00:00Z",
    "host": { "ip": "10.0.0.12" }, "client": { "ip": "192.168.1.5" },
    "source": { "geo": { "location": { "lat": 48.85, "lon": 2.35 } } },
    "error": { "type": 500 }, "url": { "path": "/api/x" } }

  GET tp-ecs-auto-1/_mapping
  ```
* **À observer** : les champs `*.ip` deviennent `ip` et `*.geo.location` devient `geo_point`, **sans les avoir déclarés**. En revanche, une valeur numérique envoyée dans un champ censé être `keyword` peut encore surprendre. Vérifier le type obtenu pour `error.type`.
* **Discussion** : typage par dynamic template (par nom de champ) contre mapping explicite (TP 4). Lequel choisir pour des données maison ? Pour des données ECS standard ?

---

## 🎓 Pour aller plus loin

- **Data streams** : avec Elastic Agent / Fleet, les templates `logs-*-*` sont composables et gérés. Pour personnaliser, on n'édite **jamais** le template géré, on utilise les briques `…@custom` prévues pour ça (ex. `logs@custom`, `logs-nginx.access@custom`).
- **Audit d'un cluster** : `GET _template` (legacy) et `GET _index_template` (composables) côte à côte. Chercher les motifs qui se chevauchent entre les deux API.
- **Monter en version Filebeat** : Filebeat 8.x utilise des data streams et des templates composables, ce qui supprime ce type de conflit.
- Référence des champs : [Elastic Common Schema](https://www.elastic.co/guide/en/ecs/current/ecs-field-reference.html).

## 🧹 Nettoyage
```json
DELETE tp-sans-template,tp-logs-*,tp-filebeat-*,tp-ecs-auto-*
DELETE _index_template/tp-logs,tp-ecs-auto
DELETE _component_template/tp-ecs-reseau,tp-ecs-web,tp-settings
DELETE _template/tp-filebeat
DELETE _ilm/policy/tp-policy
```

## 🛠 Prérequis
1. Disposer d'une instance Elasticsearch & Kibana (v8.x ou v9.x). L'API legacy `_template` est dépréciée mais reste utilisable pour le niveau 3.
2. Un utilisateur avec les droits `manage_index_templates`, `manage_ilm` et `manage` sur les index `tp-*`.