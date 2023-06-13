# PROJET INGESTION DE LOGS TALEND ETL

## But du projet : 
>Etape 1 : Envoi de la donnée par Filebeat
>Etape 2 : Collecte de la donnée par Logstash
>Etape 3 : Etape 3 : Découpage de la log dans Logstash
>Etape 4 : Etape 4 : Envoi vers Elasticsearch
>Etape 5 : Etape 5 : Design d'un dashboard dans Kibana

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
    - c:\data\biocoop\20230605_log.txt
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

## Etape 2 : Collecte de la donnée par Logstash

## Etape 3 : Découpage de la log dans Logstash

## Etape 4 : Envoi vers Elasticsearch

## Etape 5 : Design d'un dashboard dans Kibana