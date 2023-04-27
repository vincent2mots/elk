
## Exercices agent Beats
Le but de ces exercices est de comprendre comment utiliser des agents Beats et comprendre aussi l'intérêt des modules

Pour tous les TP, se positionner dans le répertoire suivant :
``` sh
cd /home/user/elastic/logstash-8.4.0
```

## TP 1 : Metricbeat
Lancer les commandes suivantes :
``` sh
cd /home/user/elastic/metricbeat-8.4.0-linux-x86_64
./metricbeat modules enable linux
./metricbeat setup
./metricbeat -e
```
Aller voir le dashboard suivant dans Kibana :

## TP 2 : Filebeat
### 1. Filebeat sans module
Lancer les commandes suivantes :
``` sh
cd /home/user/elastic/filebeat-8.4.0-linux-x86_64
./filebeat -e
```

Aller voir les données Kibana. Qu'en pensez-vous?

### 2. Filebeat avec module
Lancer les commandes suivantes :
``` sh
cd /home/user/elastic/filebeat-8.4.0-linux-x86_64
./filebeat modules enable apache
```

Modifier le fichier **/home/user/elastic/filebeat-8.4.0-linux-x86_64/modules.d/apache.yml** :

``` yml
- module: apache
  # Access logs
  access:
    # Il faut simplement activer :
    enabled: true
    # et expliquer où se trouve le fichier à lire :
    var.paths: ["/home/user/elastic/data/*.logs"]
```

Maintenant, retournez voir la donnée dans Kibana. Est-ce mieux?
