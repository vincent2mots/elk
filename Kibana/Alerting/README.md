## Exercice autour de l'alerting avec Kibana

### Etape 1 : configurer un connecteur

### Etape 2 : Analyser la donnée avant de créer la règle
A l'aide du menu Discover, chercher les erreurs 404 dans la Data View **Kibana Sample Data Logs** :

![](https://raw.githubusercontent.com/vincent2mots/elk/main/Kibana/Alerting/analyse_discover.PNG)

Dans cet exemple, on retrouve 1 erreur sur les 15 dernières minutes. 

Par la suite, nous allons configurer une règle pour nous alerter lorsqu'au moins une erreur 404 survient.

### Etape 2 : configurer une règle

Une fois dans le menu **Stack Management > Rules**, créer une nouvelle règle et lui donner un nom : 
![](https://raw.githubusercontent.com/vincent2mots/elk/main/Kibana/Alerting/create_rule_1.PNG)

Il existe plusieurs types de règles pré-configurées. Choisir dans **STACK RULES > Elasticsearch query** :
![](https://raw.githubusercontent.com/vincent2mots/elk/main/Kibana/Alerting/create_rule_2.PNG)

Choisir **KQL or Lucene** :
![](https://raw.githubusercontent.com/vincent2mots/elk/main/Kibana/Alerting/create_rule_3.PNG)

Configurer comme ci-après :
![](https://raw.githubusercontent.com/vincent2mots/elk/main/Kibana/Alerting/create_rule_4.PNG)

Choisir la Data View **Kibana Sample Data Logs**
Mettre un filtre KQL : **response.keyword: "404"**
Mettre la valeur **0** dans **IS ABOVE**
Mettre le filtre temporel à **15** minutes

Il est possible de tester la requête pour vérifier que l'on obtient comme dans le menu Discover.

Enfin, il ne reste plus qu'à choisir la ou les actions à effectuer :
![](https://raw.githubusercontent.com/vincent2mots/elk/main/Kibana/Alerting/create_rule_5.PNG)

