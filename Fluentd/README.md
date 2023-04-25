# Version quelle version d'Ubuntu est installée : 
lsb_release -a

# Installer curl (si nécessaire) 
sudo apt install curl

# Documentation d'installation : 
# https://docs.fluentd.org/installation/install-by-deb

# Installation sur Ubuntu Focal :
curl -fsSL https://toolbelt.treasuredata.com/sh/install-ubuntu-focal-td-agent4.sh | sh

# Le service est installé ici : 
/lib/systemd/system/td-agent.service

# Démarrer Fluentd : 
sudo systemctl start td-agent.service

# Stopper Fluentd : 
sudo systemctl stop td-agent.service

# Les chemins importants :
 # Fichiers de configuration : 
 /etc/td-agent
 # Le fichier par défaut est /etc/td-agent/td-agent.conf

 # Exécutable td-agent :
 /opt/td-agent/bin

# TP 1 :
# Télécharger le fichier suivant : https://raw.githubusercontent.com/vincent2mots/elk/main/data/log_watchlist-service-DK.log
# Positionner le fichier dans /home/user/elastic/data
# Télécharger le fichier suivant : https://raw.githubusercontent.com/vincent2mots/elk/main/Fluentd/idemia_plain.conf
# Positionner le fichier dans le répertoire /home/user/elastic
# /!\ Ouvrir le fichier data, couper le contenu et enregistrer avant de lancer Fluentd
# Lancer Fluentd :
sudo /opt/td-agent/bin/fluentd -c /home/user/elastic/idemia_plain.conf
# Coller à nouveau les données dans le fichier de data et enregistrer

# TP 2 :
# Télécharger le fichier suivant : https://raw.githubusercontent.com/vincent2mots/elk/main/data/log_watchlist-service-DK.log
# Positionner le fichier dans /home/user/elastic/data
# Télécharger le fichier suivant : https://raw.githubusercontent.com/vincent2mots/elk/main/Fluentd/idemia_plain.conf
# Positionner le fichier dans le répertoire /home/user/elastic
# /!\ Ouvrir le fichier data, couper le contenu et enregistrer avant de lancer Fluentd
# Lancer Fluentd :
sudo /opt/td-agent/bin/fluentd -c /home/user/elastic/idemia_plain.conf
# Coller à nouveau les données dans le fichier de data et enregistrer