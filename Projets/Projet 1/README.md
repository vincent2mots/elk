# PROJET INGESTION DE LOGS TALEND ETL

## But du projet : 
>- Etape 1 : Envoi de la donnée par Filebeat
>- Etape 2 : Collecte de la donnée par Logstash
>- Etape 3 : Découpage de la log dans Logstash
>- Etape 4 : Envoi vers Elasticsearch
>- Etape 5 : Design d'un dashboard dans Kibana

&#128161; Une des difficulté de ce type de projet consiste à identifier quel ensemble de lignes forme un événément.

## Etape 1 : Envoi de la donnée par Filebeat
Exemple de configuration input Filebeat :
``` yml
filebeat.inputs:
# Type log pour permettre le multiline :
- type: log
  # ID unique de l'input :
  id: mes-logs-talend
  # Input activé :
  enabled: true
  # Où se trouve le fichier en entrée :
  paths:
    - c:\data\demo\20230605_log.txt
  # Un événement commence par un de ces patterns :
  multiline.pattern: '^SMP|^SUR|^FRAIS|^SMB|^NAL|^FEL|^ALI'
  multiline.negate: true
  multiline.match: after
  # Un événement termine par un de ces patterns :
  multiline.flush_pattern: '^SMP|^SUR|^FRAIS|^SMB|^NAL|^FEL|^ALI'
  # Ajout de champs additionnels :
  fields:
   application: talend
   environnement: recette
   type_interface: etl
```

&#128161; **Astuce** : Dans Filebeat, n'oubliez pas de supprimer le contenu du répertoire data entre deux exécutions, sinon l'agent ne renvoie pas la donnée. Pratique en phase de dev quand on est dans un processus itératif / expérimental

L'output de l'agent :
``` yml
output.logstash:
  # Sortie vers Logstash :
  hosts: ["localhost:5044"]
```

&#128161; **Astuce** : Dans Filebeat, une seule sortie peut être configurée à la fois.

## Etape 2 : Collecte de la donnée par Logstash

``` yml
input {
  beats {
    port => 5044
  }
}
```

&#128161; **Astuce** : Dans l'ordre, on définit d'abord l'agent Filebeat mais, dans les faits, on lance d'abord Logstash avant de lancer l'agent

## Etape 3 : Découpage de la log dans Logstash

## Etape 4 : Envoi vers Elasticsearch
Définition de la sortie vers Elasticsearch :
``` yml
output {
 elasticsearch {
   hosts => ["https://localhost:9200"]
   index => "logs-%{[fields][application]}-%{[fields][environnement]}"
   action => "create"
   user => "elastic"
   password => "formation"
   ssl_certificate_verification => "false"
 }
}
```
## Etape 5 : Design d'un dashboard dans Kibana