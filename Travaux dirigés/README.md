# Exercice 1 : Premier cluster et test d'API

**Objectifs pédagogiques**
>- Tester plusieurs API et comprendre les résultats obtenus
>- Comprendre le mécanisme de la réplication intra-noeuds
>- Comprendre les différents niveaux de santé des index / du cluster (rouge / jaune / vert)

**Prérequis :**
>- Avoir monté une architecture avec 2 noeuds Elasticsearch et 1 Kibana
>- Avoir installé les 3 jeux de données de démo Elasticsearch

### **Q1 : Lancer les appels API suivants et expliquer ce qu’ils produisent comme résultats**
``` yml
GET _cluster/health
GET _cat/nodes?v
GET _cat/indices?v
GET _cat/shards?v
```

### **Q2 : Sur l’appel API *GET _cat/indices?v*, quelle est la différence entre les colonnes *store.size* et *pri.store.size* ?**

### **Q3 : Observez le niveau de santé de l’index kibana_sample_data_ecommerce, puis lancer la commande suivante**
``` json
PUT /kibana_sample_data_ecommerce/_settings
{
 "index" : {
  "number_of_replicas" : 5,
  "auto_expand_replicas": false
 }
}
```
Qu’est ce que vous constatez sur le niveau de santé ?

Pourquoi ?

Lancer l’API *GET _cat/shards?v* et en expliquer le résultat.

Quelles sont les deux solutions pour résoudre ce problème ?

### Q4 : Expliquez les 3 niveaux de santé : **<span style="color:green">green</span>** / **<span style="color:yellow">yellow</span>** / **<span style="color:red">red</span>**. Dans quels cadres les retrouve-t-on ?

# Exercice 2 : Comprendre le scoring dans Elasticsearch
**Objectifs pédagogiques :**
>- Découvrir le langage naturel pour interroger Elasticsearch
>- Découvrir quelques requêtes et en comprendre l’intérêt

**Prérequis : Lancer les commandes suivantes :**
``` json
PUT /library
{
 "settings": {
  "index.number_of_shards": 1,
  "index.number_of_replicas": 0
 }
}

POST /library/_bulk
{ "index": { "_id": 1 }}
{ "title": "The quick brown fox", "price": 5, "colors": ["red", "green", "blue"] }
{ "index": { "_id": 2 }}
{ "title": "The quick brown fox jumps over the lazy dog", "price": 15, "colors": ["blue", "yellow"] }
{ "index": { "_id": 3 }}
{ "title": "The quick brown fox jumps over the quick dog", "price": 8, "colors": ["red", "blue"] }
{ "index": { "_id": 4 }}
{ "title": "Brown fox brown dog", "price": 2, "colors": ["black", "yellow", "red", "blue"] }
{ "index": { "_id": 5 }}
{ "title": "Lazy dog", "price": 9, "colors": ["red", "blue", "green"] }
```

### **Q1 : match ou match_phrase ?**
Lancer les deux requêtes suivantes et expliquer les différences :
``` json
GET /library/_search
{
 "query": {
  "match": {
   "title": "quick dog"
  }
 }
}

GET /library/_search
{
 "query": {
  "match_phrase": {
   "title": "quick dog"
  }
 }
}
```

### **Q2 : Le scoring**
Expliquer pourquoi les documents sont retournés dans cet ordre précis, lors de l’exécution de la requête suivante :
``` json
GET /library/_search
{
 "query": {
  "match": {
   "title": "quick"
  }
 }
}
```

### **Q3 : La recherche floue**
Expliquer ce que retourne la requête suivante. Trouvez quelques intérêts métier :
``` json
GET /library/_search
{
 "query": {
  "fuzzy": {
   "title": {
    "value": "box"
   }
  }
 }
}
```

# Exercice 3 : Comprendre le mécanisme de l’élection du master
**Objectifs pédagogiques :**
>- Comprendre les rôles des noeuds (DILM)
>- Comprendre le principe d’élection d’un nouveau noeud master
>- Identifier un nombre minimal de noeuds dans une architecture Elasticsearch

**Prérequis :**
>- Avoir monté une architecture avec 2 noeuds Elasticsearch et 1 Kibana

### **Q1 : Les rôles des noeuds**
Exécuter l’appel API suivant :
``` json
GET _cat/nodes?v
```

Quels sont les rôles des noeuds ?

Expliquer quels sont les rôles suivants :
- D
- I
- L
- M

### **Q2 : Tuer le master**
Identifier le noeud master et le tuer.

Que se passe t-il ? Le cluster est-il toujours opérationnel ?

Le second noeud a-t-il été élu master à la place du précédent ?

Expliquer le mécanisme de l’élection.

Qu’est ce que le quorum ?

Combien de noeuds minimum aurait-il fallu dans cette architecture pour que cela fonctionne ?


