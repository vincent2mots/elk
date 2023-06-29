# INSTALLATION D'OPENSEARCH OUTPUT PLUGIN SUR WINDOWS

Le plugin output-opensearch n'existe que sur les distributions suivantes :
 - Linux
 - MacOS
 - Docker

 Pour installer le plugin sur un Logstash Windows, voici la marche à suivre :

 1. Se doter d'une machine Linux, télécharger Logstash avec le plugin output-opensearch (disponible [ici](https://opensearch.org/downloads.html))

 2. Exporter le plugin output-opensearch à l'aide de la commande suivante :
``` sh
bin/logstash-plugin prepare-offline-pack --output logstash-output-opensearch.zip --overwrite logstash-output-opensearch
  ```

  3. Installer le plugin en mode offline sur le Logstash Windows : 
``` sh
bin/logstash-plugin install file:///d:/BINAIRES/logstash-output-opensearch.zip
```

4. Vérifier que le plugin est bien installé : 
``` sh
bin/logstash-plugin list
```

Petit cadeau : le plugin offline pour gagner un peu de temps est disponible [ici](https://github.com/vincent2mots/elk/blob/main/Logstash/opensearch/logstash-8.6.1-output-opensearch.zip)