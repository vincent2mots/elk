
## Exercices Logstash
Le but de ces exercices est de comprendre comment lancer des Pipeline, voir les résultats dans Elasticsearch et découvrir quelques plugins (grok / date / geoip / useragent).

Le fichier de de donnée pour ces TP se trouve ici :
> head -10 /home/user/elastic/data/apache.logs

Pour tous les TP, se positionner dans le répertoire suivant :
> cd /home/user/elastic/logstash-8.4.0

## TP 1 : Découverte d'une configuration Logstash
Lancer la commande suivante :
> bin/logstash -f config/config1.conf

Dans cet exercice, on écrit simplement dans la sortie standard, sans transformations. Quels sont les défauts de cette première configuration?

## TP 2 : Les plugins dans Logstash
Lancer la commande suivante :
> bin/logstash -f config/config2.conf

C'est mieux : tout est bien découpé maintenant. Il ne reste plus qu'à écrire dans Elasticsearch.

## TP 3 : L'écriture dans Elasticsearch
Lancer la commande suivante :
> bin/logstash -f config/config3.conf

Pourquoi rien ne se passe?