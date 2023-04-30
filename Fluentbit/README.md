## Documentation d'installation de Fluent Bit :

[Documentation d'installation de Fluent Bit](https://docs.fluentbit.io/manual/installation/linux/ubuntu)

## Installation sur Ubuntu :

``` sh
curl https://raw.githubusercontent.com/fluent/fluent-bit/master/install.sh | sh
```

## TP 1 : Intégration d'un fichier de log classique
1. Télécharger le fichier suivant : [Fichier de configuration](https://raw.githubusercontent.com/vincent2mots/elk/main/Fluentd/idemia_plain.conf)
4. Positionner le fichier dans le répertoire **/home/user/elastic**
5. &#128161; **Ouvrir le fichier data, couper le contenu et enregistrer avant de lancer Fluentd**
6. Lancer Fluent Bit :
``` sh
sudo /opt/fluent-bit/bin/fluent-bit -c /home/user/elastic/fluent-bit_plain.conf
```
7. Coller à nouveau les données dans le fichier de data et enregistrer

## TP 2 : Intégration d'un fichier de log au format JSON
1. Télécharger le fichier suivant : [Fichier de log JSON](https://raw.githubusercontent.com/vincent2mots/elk/main/data/em.log.test)
2. Positionner le fichier dans **/home/user/elastic/data**
3. Télécharger le fichier suivant : [Fichier de configuration JSON](https://raw.githubusercontent.com/vincent2mots/elk/main/Fluentd/fluent_json.conf)
4. Positionner le fichier dans le répertoire **/home/user/elastic**
5. &#128161; **Ouvrir le fichier data, couper le contenu et enregistrer avant de lancer Fluentd**
6. Lancer Fluentd :
``` sh
sudo /opt/td-agent/bin/fluentd -c /home/user/elastic/fluent_json.conf
```
7. Coller à nouveau les données dans le fichier de data et enregistrer

## ARCHIVE
### Les chemins importants :

#### Fichiers de configuration / parsers / plugins :
``` sh
cd /etc/fluent-bit
```

Le fichier par défaut est **/etc/td-agent/td-agent.conf**

#### Exécutable td-agent :

Il se trouve à l'emplacement suivant :
``` sh
cd /opt/fluent-bit/bin
```