
## Exercices agent Beats
Le but de ces exercices est de comprendre comment utiliser des agents Beats et comprendre aussi l'intérêt des modules

## TP 1 : Metricbeat
Lancer les commandes suivantes :
``` sh
cd ~/elastic/metricbeat-8.11.1-linux-x86_64
```
``` sh
./metricbeat modules enable linux
```
``` sh
./metricbeat setup
```
``` sh
./metricbeat -e
```
Aller voir le dashboard suivant dans Kibana :
![](
https://raw.githubusercontent.com/vincent2mots/elk/main/Beats/images/overview_ecs.PNG)

ou à l'aide du lien suivant :
[Lien vers le dashboard](http://localhost:5601/app/dashboards#/view/Metricbeat-system-overview-ecs?_g=())

## TP 2 : Filebeat
### 1. Filebeat sans module
Lancer les commandes suivantes :
``` sh
cd ~/elastic/filebeat-8.11.1-linux-x86_64
```
``` sh
./filebeat -e
```

Aller voir les données Kibana. Qu'en pensez-vous?

### 2. Filebeat avec module
Lancer les commandes suivantes :
``` sh
cd ~/elastic/filebeat-8.11.1-linux-x86_64
./filebeat modules enable apache
```

Modifier le fichier **/home/user/elastic/filebeat-8.11.1-linux-x86_64/modules.d/apache.yml** :

``` yml
- module: apache
  # Access logs
  access:
    # Il faut simplement activer :
    enabled: true
    # et expliquer où se trouve le fichier à lire :
    var.paths: ["/home/${USER}/elastic/data/*.logs"]
```

Maintenant, retournez voir la donnée dans Kibana. Est-ce mieux?
