## Exercice 1 : Premier cluster et test d'API

**Objectifs pédagogiques**
>- Tester plusieurs API et comprendre les résultats obtenus
>- Comprendre le mécanisme de la réplication intra-noeuds
>- Comprendre les différents niveaux de santé des index / du cluster (rouge / jaune / vert)

**Prérequis :**
>- Avoir monté une architecture avec 2 noeuds Elasticsearch et 1 Kibana
>- Avoir installé les 3 jeux de données de démo Elasticsearch

### Q1 : Lancer les appels API suivants et expliquer ce qu’ils produisent comme résultats
``` yml
GET _cluster/health
GET _cat/nodes?v
GET _cat/indices?v
GET _cat/shards?v
```