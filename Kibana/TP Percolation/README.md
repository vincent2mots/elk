# 🔄 Travaux Pratiques : Percolation

La percolation, c'est une **recherche inversée** : au lieu de chercher des documents qui correspondent à une requête, on indexe des **requêtes** (champ de type `percolator`) puis on demande, pour chaque nouveau document, lesquelles matchent. C'est le mécanisme qui sous-tend par exemple l'alerting Elasticsearch.

*(Pour la théorie complète — cas d'usage, syntaxe détaillée, variantes — voir la partie "Percolation" du support de formation.)*

---

## 🛠 Rappel de syntaxe

**Mapping avec un champ `percolator` :**
```json
PUT /alertes_support
{
  "mappings": {
    "properties": {
      "requete_alerte": { "type": "percolator" },
      "contenu":        { "type": "text" },
      "canal":          { "type": "keyword" }
    }
  }
}
```

**Indexer des requêtes (pas des documents "métier") :**
```json
PUT /alertes_support/_doc/1
{
  "requete_alerte": {
    "bool": {
      "must": [
        { "match": { "contenu": "indisponible" } },
        { "term":  { "canal": "production" } }
      ]
    }
  }
}
```

**Percoler un nouveau document :**
```json
GET /alertes_support/_search
{
  "query": {
    "percolate": {
      "field": "requete_alerte",
      "document": {
        "contenu": "Le service de paiement est indisponible depuis ce matin",
        "canal": "production"
      }
    }
  }
}
```
La réponse renvoie les identifiants des requêtes stockées qui matchent, avec leur score — exactement comme une recherche classique, mais où ce sont les requêtes qui sont "trouvées".

---

## 🟢 Niveau 1 : Découverte

### TP 1 : Percolation "mode alerting" sur les logs
* **Objectif** : Construire un mini-système d'alerte en indexant 3 règles de percolation, puis percoler quelques documents extraits de *Sample web logs* pour vérifier lesquelles se déclenchent.
* **Étapes** :
  1. Créer l'index `regles_alerte_logs` avec un champ `percolator`.
  2. Indexer 3 règles avec des `bool`/`match`/`range` portant sur `response`, `url`, `bytes` (ex. "erreur serveur sur une URL d'API", "code retour 404", "volume anormalement élevé en octets").
  3. Prendre 3-4 documents réels de `kibana_sample_data_logs` (`GET kibana_sample_data_logs/_search`) et les percoler un par un contre `regles_alerte_logs`.
* **Discussion** : quel est l'intérêt par rapport à une simple règle d'alerting Kibana ? *(réponse attendue : la percolation est le mécanisme sous-jacent, utile pour du custom/API, alors que l'alerting Kibana en est une couche prête à l'emploi.)*

### TP 2 : Classification automatique de commandes
* **Objectif** : Indexer des règles de "segment marketing" et percoler des commandes réelles de *Sample eCommerce orders* pour voir à quel(s) segment(s) elles appartiennent.
* **Étapes** :
  1. Créer l'index `regles_segment_ecommerce` avec un champ `percolator`.
  2. Indexer au moins 3 règles, par exemple :
     - "gros client" = `range` sur `taxful_total_price > 200`
     - "vente flash" = `match` sur `category` contenant une catégorie précise
     - une 3e règle au choix
  3. Percoler 3-4 commandes réelles de `kibana_sample_data_ecommerce`.
* **Variante** : demander aux stagiaires d'ajouter une 4ᵉ règle eux-mêmes et de vérifier qu'elle se déclenche sur le bon type de commande.

---

## 🔵 Niveau 2 : Aller plus loin

### TP 3 : Percoler un document déjà indexé
* **Objectif** : Montrer la syntaxe permettant de percoler un document existant, identifié par son `_index`/`_id`, plutôt que de le fournir en ligne dans la requête — pour illustrer le cas "je veux re-tester tous mes documents historiques contre une nouvelle règle que je viens d'ajouter".
* **Configuration** :
  ```json
  GET /regles_alerte_logs/_search
  {
    "query": {
      "percolate": {
        "field": "requete_alerte",
        "index": "kibana_sample_data_logs",
        "id": "<id_d_un_document_existant>"
      }
    }
  }
  ```
* **Bonus** : ajouter `"highlight"` à la requête pour identifier précisément quelle partie du document a déclenché le match — utile pour bien faire comprendre le mécanisme aux stagiaires.

## 🛠 Prérequis
1. Disposer d'une instance Elasticsearch & Kibana (v9).
2. Charger les jeux de données de démo utilisés : *Sample web logs* et *Sample eCommerce orders*.