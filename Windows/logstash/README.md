
## Exercices Logstash
Le but de ces exercices est de comprendre comment lancer des Pipeline, voir les résultats dans Elasticsearch et découvrir quelques plugins (grok / date / geoip / useragent).

Le fichier de de donnée pour ces TP se trouve ici :
Télécharger le fichier [suivant](https://raw.githubusercontent.com/vincent2mots/elk/main/data/apache.logs) (l'enregistrer avec le nom *apache.logs*) et le déposer dans le répertoire **C:\data**(répertoire à créer s'il n'existe pas déjà)

Télécharger [Logstash 8.4.0](https://artifacts.elastic.co/downloads/logstash/logstash-8.4.0-windows-x86_64.zip) et le dézipper dans le répertoire **C:\elastic\Logstash** (répertoire à créer s'il n'existe pas) :
Pour tous les TP, se positionner dans le répertoire suivant :
``` sh
cd c:\elastic\Logstash\logstash-8.4.0
```
Télécharger les 4 fichiers de configuration et les déposer ici : 

![](https://raw.githubusercontent.com/vincent2mots/elk/main/Windows/images/logstash_configurations_files.PNG)

## TP 1 : Découverte d'une configuration Logstash
Lancer la commande suivante :
``` sh
bin\logstash -f config\config1.conf
```

Dans cet exercice, on écrit simplement dans la sortie standard, sans transformations. Quels sont les défauts de cette première configuration?

## TP 2 : Les plugins dans Logstash
Lancer la commande suivante :
``` sh
bin\logstash -f config\config2.conf
```

C'est mieux : tout est bien découpé maintenant. Il ne reste plus qu'à écrire dans Elasticsearch.

## TP 3 : L'écriture dans Elasticsearch
Lancer la commande suivante :
``` sh
bin\logstash -f config\config3.conf
```

Pourquoi rien ne se passe?

## TP 4 : Utilisation de l'ingest Pipeline
&#128161; A faire quand les TP autour de Beats sont terminés
``` sh
bin\logstash -f config\config4.conf
```

Pourquoi rien ne se passe?