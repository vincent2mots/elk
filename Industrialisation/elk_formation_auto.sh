#!/bin/bash

# Script de preparation de la formation ELK
# Vincent Le Roux
# Script a lancer :
# Donner les droits d'exécution au script
# sudo ./elk_formation_auto.sh
# Mot de passe : user

# Variables
# test
#v_dir_source="/home/user"
v_user=${1}
v_dir_source="/home/${v_user}"
v_version="8.4.0"
v_dir_elastic=${v_dir_source}/elastic
v_dir_data=${v_dir_elastic}/data
v_dir_exercices=${v_dir_elastic}/exercices
v_logstash_url="https://artifacts.elastic.co/downloads/logstash/logstash-${v_version}-linux-x86_64.tar.gz"
v_bin_logstash="logstash-${v_version}-linux-x86_64.tar.gz"
v_filebeat_url="https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${v_version}-linux-x86_64.tar.gz"
v_bin_filebeat="filebeat-${v_version}-linux-x86_64.tar.gz"
v_metricbeat_url="https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-${v_version}-linux-x86_64.tar.gz"
v_bin_metricbeat="metricbeat-${v_version}-linux-x86_64.tar.gz"
v_data_apache_logs_url="https://raw.githubusercontent.com/vincent2mots/elk/main/data/apache.logs"
v_data_apache_logs="apache.logs"
v_dir_conf_logstash=${v_dir_elastic}/logstash-${v_version}/config
v_config1_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Logstash/config1.conf"
v_config1="config1.conf"
v_config2_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Logstash/config2.conf"
v_config2="config2.conf"
v_config3_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Logstash/config3.conf"
v_config3="config3.conf"
v_exercices_url="https://github.com/vincent2mots/elk/raw/main/Exercices/ELK_Exercices.zip"
v_exercices="ELK_Exercices.zip"
v_metricbeat_config_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Beats/metricbeat.yml"
v_metricbeat_config="metricbeat.yml"
v_dir_metricbeat="${v_dir_elastic}/metricbeat-${v_version}-linux-x86_64"
v_filebeat_config_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Beats/filebeat.yml"
v_filebeat_config="filebeat.yml"
v_dir_filebeat="${v_dir_elastic}/filebeat-${v_version}-linux-x86_64"


# Fonctions
telecharger() {
  # Premier parametre   : l'URL à télécharger
  # Deuxième parametre  : le nom du fichier telecharge
  # Troisieme parametre : l'endroit ou le fichier sera telecharge 
  # Quatrième paramètre : si "unzip", le fichier est dézippé et supprimé ensuite
  wget --quiet ${1} -O ${3}/${2}
  if [ ${4} = "untar" ]; then
  	tar -xf ${3}/${2} -C ${3}
  	rm ${3}/${2}
  fi
  if [ ${4} = "unzip" ]; then
  	unzip -q ${3}/${2} -d ${v_dir_exercices}
  	#rm ${3}/${2}
  fi
}

# Augmentation du parametre vm_max_map_count et vérification que tout est OK
echo "Augmentation du parametre vm_max_map_count"
sysctl -w vm.max_map_count=262144


# Redémarrage de Docker
echo "Redemarrage de Docker"
systemctl restart docker

# Téléchargement des images Elasticsearch et Kibana
echo "Telechargement des images elasticsearch et kibana"
docker pull docker.elastic.co/elasticsearch/elasticsearch:${v_version} --quiet
docker pull docker.elastic.co/kibana/kibana:${v_version} --quiet

# Création de la partie Portainer
echo "Mise en place Portainer"
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:2.9.3

# Creation des arborescences pour la formation
echo "Creation des dossiers et recuperation des sources"
if [[ ! -e ${v_dir_elastic} ]]; then
  mkdir ${v_dir_elastic}
fi
if [[ ! -e ${v_dir_data} ]]; then
  mkdir ${v_dir_data}
fi
if [[ ! -e ${v_dir_exercices} ]]; then
  mkdir ${v_dir_exercices}
fi

# Logstash
echo " 1. Logstash"
telecharger ${v_logstash_url}  ${v_bin_logstash} ${v_dir_elastic} "untar"
telecharger ${v_data_apache_logs_url}  ${v_data_apache_logs} ${v_dir_data} "rien"
telecharger ${v_config1_url} ${v_config1} ${v_dir_conf_logstash} "rien"
telecharger ${v_config2_url} ${v_config2} ${v_dir_conf_logstash} "rien"
telecharger ${v_config3_url} ${v_config3} ${v_dir_conf_logstash} "rien"

# Filebeat
echo " 2. Filebeat"
telecharger ${v_filebeat_url}  ${v_bin_filebeat} ${v_dir_elastic} "untar"
telecharger ${v_filebeat_config_url} ${v_filebeat_config} ${v_dir_filebeat} "rien"

# Metricbeat
echo " 3. Metricbeat"
telecharger ${v_metricbeat_url}  ${v_bin_metricbeat} ${v_dir_elastic} "untar"
telecharger ${v_metricbeat_config_url} ${v_metricbeat_config} ${v_dir_metricbeat} "rien"

# Autres exercices
echo " 4. Autres exercices"
telecharger ${v_exercices_url} ${v_exercices} ${v_dir_elastic} "unzip"

# Donner la propriete des dossiers à l'utilisateur "user" et changement des droits
chown -R ${v_user}:${v_user} ${v_dir_elastic}
chmod -R 750 ${v_dir_elastic}

