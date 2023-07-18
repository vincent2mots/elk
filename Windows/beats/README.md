
## Exercices agent Beats
Le but de ces exercices est de comprendre comment utiliser des agents Beats et comprendre aussi l'intérêt des modules

## TP 1 : Metricbeat
Télécharger [Metricbeat](https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-8.4.0-windows-x86_64.zip) et le dézipper dans C:\elastic\Metricbeat

Dans le fichier **C:\elastic\Metricbeat\metricbeat-8.4.0-windows-x86_64\metricbeat.yml**, modifier les éléments suivants :
``` yml
setup.kibana:
  host: "localhost:5601"
  username: "elastic"
  password: "formation"
  ssl.verification_mode: none
```
et
``` yml
output.elasticsearch:
  hosts: ["localhost:9200"]
  protocol: "https"
  username: "elastic"
  password: "formation"
  ssl.verification_mode: none
```

Lancer les commandes suivantes :
``` sh
cd C:\elastic\metricbeat\metricbeat-8.4.0-windows-x86_64
```
``` sh
metricbeat modules enable windows
```
``` sh
metricbeat setup
```
``` sh
metricbeat -e
```
Aller voir le dashboard suivant dans Kibana :
![](
https://raw.githubusercontent.com/vincent2mots/elk/main/Beats/images/overview_ecs.PNG)

ou à l'aide du lien suivant :
[Lien vers le dashboard](http://localhost:5601/app/dashboards#/view/Metricbeat-system-overview-ecs?_g=())

## TP 2 : Filebeat
Télécharger [Filebeat](https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.4.0-windows-x86_64.zip) et le dézipper dans C:\elastic\Filebeat

Dans le fichier **C:\elastic\Filebeat\filebeat-8.4.0-windows-x86_64\filebeat.yml**, modifier les éléments suivants :
``` yml
output.elasticsearch:
  hosts: ["localhost:9200"]
  protocol: "https"
  username: "elastic"
  password: "formation"
  ssl.verification_mode: none
```

### 1. Filebeat sans module
Lancer les commandes suivantes :
``` sh
cd C:\elastic\Filebeat\filebeat-8.4.0-windows-x86_64
```
``` sh
filebeat -e
```

Aller voir les données Kibana. Qu'en pensez-vous?

### 2. Filebeat avec module
Lancer les commandes suivantes :
``` sh
C:\elastic\Filebeat\filebeat-8.4.0-windows-x86_64
```
``` sh
filebeat modules enable apache
```

Modifier le fichier **C:\elastic\Filebeat\filebeat-8.4.0-windows-x86_64\modules.dapache.yml** :

``` yml
- module: apache
  # Access logs
  access:
    enabled: true

    # Set custom paths for the log files. If left empty,
    # Filebeat will choose the paths depending on your OS.
    var.paths: ['c:\data\*.logs']
```

Maintenant, retournez voir la donnée dans Kibana. Est-ce mieux?
