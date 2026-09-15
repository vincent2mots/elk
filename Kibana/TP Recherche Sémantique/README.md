# 🧠 Travaux Pratiques : Recherche sémantique (`semantic_text`)

`semantic_text` est un type de champ qui automatise la recherche par **sens** plutôt que par mot-clé : chunking et calcul des embeddings à l'indexation, vectorisation de la requête à la recherche — le tout derrière une syntaxe aussi simple qu'un champ `text` classique.

*(Pour la théorie complète — comment ça marche, modèles d'inférence disponibles sans clé API externe — voir la partie "Recherche sémantique avec semantic_text" du support de formation.)*

**Modèle recommandé pour ces TP** : `.multilingual-e5-small-elasticsearch` (préconfiguré, sans clé API externe, adapté au français). Alternative anglophone : `.elser-2-elasticsearch`.

⚠️ **Prérequis technique** : un nœud *Machine Learning* actif dans le cluster (le modèle se télécharge et se déploie automatiquement au premier appel, ce qui peut prendre quelques minutes) — à vérifier avant la session sur l'environnement de formation.

---

## 🟢 Niveau 1 : L'effet "aha" — mot-clé vs sens

### TP 1 : Deux champs, un seul contenu — comparer ce qui est comparable
* **Objectif** : Comparer une recherche mot-clé (BM25) et une recherche sémantique **sur exactement le même texte source**, pour isoler la seule variable qui compte : la méthode de recherche, pas le contenu.
* **Pourquoi deux champs identiques ?** Si on compare un champ `text` et un champ `semantic_text` qui ne contiennent pas la même valeur (un titre court d'un côté, une description longue de l'autre), on ne sait plus si la différence de résultat vient de la méthode ou du contenu. En dupliquant la même valeur dans deux champs de types différents, la démonstration devient rigoureuse.
* **Configuration** :
  ```json
  PUT /tickets_support
  {
    "mappings": {
      "properties": {
        "titre": { "type": "keyword" },
        "description": {
          "type": "text"
        },
        "description_semantic": {
          "type": "semantic_text",
          "inference_id": ".multilingual-e5-small-elasticsearch"
        }
      }
    }
  }
  ```
  ```json
  POST /tickets_support/_bulk
  { "index": {} }
  { "titre": "Ticket 1", "description": "Le moteur refuse de tourner ce matin, impossible de partir travailler.", "description_semantic": "Le moteur refuse de tourner ce matin, impossible de partir travailler." }
  { "index": {} }
  { "titre": "Ticket 2", "description": "L'écran de mon ordinateur reste noir même après avoir rebranché le câble.", "description_semantic": "L'écran de mon ordinateur reste noir même après avoir rebranché le câble." }
  { "index": {} }
  { "titre": "Ticket 3", "description": "Ma facture d'électricité a doublé par rapport au mois dernier, je ne comprends pas pourquoi.", "description_semantic": "Ma facture d'électricité a doublé par rapport au mois dernier, je ne comprends pas pourquoi." }
  { "index": {} }
  { "titre": "Ticket 4", "description": "Le chauffage ne chauffe plus depuis hier soir, il fait très froid dans l'appartement.", "description_semantic": "Le chauffage ne chauffe plus depuis hier soir, il fait très froid dans l'appartement." }
  ```
* **La comparaison, champ par champ, valeur de requête identique** :
  ```json
  // Recherche mot-clé classique (BM25) sur "description"
  GET /tickets_support/_search
  {
    "query": { "match": { "description": "ma voiture ne veut pas démarrer" } }
  }

  // Recherche sémantique sur "description_semantic" — même requête, même documents sources
  GET /tickets_support/_search
  {
    "query": { "match": { "description_semantic": "ma voiture ne veut pas démarrer" } }
  }
  ```
* **Résultat attendu et discussion** : la recherche sur `description` (BM25) ne renvoie rien de pertinent — aucun mot en commun avec "moteur", "tourner" ; la recherche sur `description_semantic` fait remonter le Ticket 1 en tête malgré l'absence totale de vocabulaire partagé. Comme les deux champs contiennent rigoureusement le même texte, la différence observée ne peut venir que de la méthode de recherche — c'est la démonstration la plus propre possible.

---

## 🟡 Niveau 2 : Recherche hybride et multilingue

### TP 2 : Recherche hybride (RRF) — précision du mot-clé + rappel du sens
* **Objectif** : Montrer qu'on peut combiner, dans une seule requête, un critère exact (référence produit) et une recherche en langage naturel, via un retriever RRF (reciprocal rank fusion).
* **Configuration** :
  ```json
  PUT /catalogue_produits
  {
    "mappings": {
      "properties": {
        "reference":   { "type": "keyword" },
        "description": { "type": "semantic_text", "inference_id": ".multilingual-e5-small-elasticsearch" }
      }
    }
  }

  POST /catalogue_produits/_bulk
  { "index": {} }
  { "reference": "REF-101", "description": "Doudoune légère et chaude, idéale pour les journées d'hiver en ville." }
  { "index": {} }
  { "reference": "REF-102", "description": "Robe élégante pour une soirée ou un mariage, coupe fluide." }
  { "index": {} }
  { "reference": "REF-103", "description": "Chaussures de randonnée imperméables pour la montagne." }
  ```
  ```json
  GET /catalogue_produits/_search
  {
    "retriever": {
      "rrf": {
        "retrievers": [
          { "standard": { "query": { "term": { "reference": "REF-101" } } } },
          { "standard": { "query": { "match": { "description": "vêtement pour avoir chaud en hiver" } } } }
        ]
      }
    }
  }
  ```
* **Discussion** : le premier retriever garantit qu'une référence exacte tapée par un vendeur remonte toujours (précision), le second capte les recherches "en langage naturel" d'un client (rappel). RRF fusionne les deux classements sans que l'un écrase l'autre.

### TP 3 : Recherche multilingue
* **Objectif** : Montrer qu'avec un modèle multilingue, on peut chercher dans une langue et trouver un document écrit dans une autre — impossible avec KQL/Lucene/DSL classique.
* **Configuration** : réutiliser l'index `catalogue_produits` du TP 2.
  ```json
  GET /catalogue_produits/_search
  {
    "query": { "match": { "description": "warm clothes for winter" } }
  }
  ```
* **Résultat attendu** : la requête tapée en anglais fait remonter "Doudoune légère et chaude, idéale pour les journées d'hiver en ville" (rédigé en français). Faire tester aux stagiaires une requête en espagnol ou en allemand pour le même effet.

---

## 🎓 Ce qu'il faut retenir

- `semantic_text` ne remplace pas KQL/Lucene/DSL : il s'y **ajoute**, pour les cas où le vocabulaire de la requête et celui des documents peuvent diverger.
- Pour toute démonstration comparative texte vs sémantique, **dupliquer le contenu dans deux champs de types différents** plutôt que comparer deux champs différents : c'est la seule façon d'isoler la variable "méthode de recherche".

## 🛠 Prérequis
1. Disposer d'une instance Elasticsearch & Kibana (v9) avec un nœud Machine Learning actif.
2. Aucune donnée d'exemple Kibana requise : les jeux de données de ces TP sont créés de toutes pièces (`tickets_support`, `catalogue_produits`).