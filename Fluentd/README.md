
## Prérequis
**Version quelle version d'Ubuntu est installée :**
``` sh
lsb_release -a
```

**Installer curl (si nécessaire) :**
``` sh
sudo apt install curl
```

## Documentation d'installation de Fluentd :

[Documentation d'installation de Fluentd](https://docs.fluentd.org/installation/install-by-deb)

## Installation sur Ubuntu Focal :

``` sh
curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-focal-td-agent4.sh | sh
```

## TP 1 : Intégration d'un fichier de log classique
1. Télécharger le fichier suivant : [Fichier de log de formation](https://raw.githubusercontent.com/vincent2mots/elk/main/data/log_watchlist-service-DK.log)
2. Positionner le fichier dans **/home/user/elastic/data**
3. Télécharger le fichier suivant : [Fichier de configuration](https://raw.githubusercontent.com/vincent2mots/elk/main/Fluentd/idemia_plain.conf)
4. Positionner le fichier dans le répertoire **/home/user/elastic**
5. &#128161; **Ouvrir le fichier data, couper le contenu et enregistrer avant de lancer Fluentd**
6. Lancer Fluentd :
``` sh
sudo /opt/td-agent/bin/fluentd -c /home/user/elastic/idemia_plain.conf
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
### Le service est installé ici :
``` sh
more /lib/systemd/system/td-agent.service
```

### Démarrer Fluentd :
``` sh
sudo systemctl start td-agent.service
```

### Stopper Fluentd :
``` sh
sudo systemctl stop td-agent.service
```
### Les chemins importants :

#### Fichiers de configuration :
``` sh
cd /etc/td-agent
```

Le fichier par défaut est **/etc/td-agent/td-agent.conf**

#### Exécutable td-agent :

Il se trouve à l'emplacement suivant :
``` sh
cd /opt/td-agent/bin
```