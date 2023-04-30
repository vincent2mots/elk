## Exercice 1 : Premier cluster et test d'API

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

### **Q3 : Observez le niveau de santé de l’index kibana_sample_data_ecommerce, puis lancer la commande suivante :**
``` yml
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



