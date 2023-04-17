#!/bin/bash

# Script de preparation de la formation ELK
# Vincent Le Roux
# Script a lancer :
# Donner les droits d'exécution au script
# sudo ./elk_formation_auto.sh
# Mot de passe : user

# Variables
# test
v_dir_source="/home/user"
v_version="8.4.0"
v_dir_elastic=${v_dir_source}/elastic
v_dir_data=${v_dir_elastic}/data
v_dir_exercices=${v_dir_elastic}/exercices
#v_file_id_logstash="15fUABghOO8qVk6xqM25xcdvN3JZ65Ds0"
v_bin_logstash="logstash-${v_version}-linux-x86_64.tar.gz"
#v_file_id_filebeat="14-v97ydn9j9ywzhs-_88IoUCIfjrnwon"
v_bin_filebeat="filebeat-${v_version}-linux-x86_64.tar.gz"
#v_file_id_metricbeat="1cMPkWNQyDscHXI8EjAWZEUTdk-BcThuZ"
v_bin_metricbeat="metricbeat-${v_version}-linux-x86_64.tar.gz"
#v_file_id_apache_logs="18v9B4xIfnxnZD-aZ0rpiEJKZ5SGPVX1y"
v_data_apache_logs="apache.logs"
v_dir_conf_logstash=${v_dir_elastic}/logstash-${v_version}/config
#v_file_id_config1="18jhxsRpRcFYsjv0SOJZa5_xy07BzJzsL"
v_config1="config1.conf"
#v_file_id_config2="18jeAPNMA3syfpDi9qjsNFTrx5EAq9nLI"
v_config2="config2.conf"
#v_file_id_config3="18igaZbtkMgPbSHwp5wj62UixS3W1tRt2"
v_config3="config3.conf"
#v_file_id_exercices="1CCtbEAFZGJYOAvukw2ersqzh8yWeO8P4"
v_exercices="ELK_Exercices.zip"
#v_file_id_metricbeat_config="1xe4UtoNgq3ZeK3z9NIt4wIlFVMC4ndIV"
v_metricbeat_config="metricbeat.yml"
v_dir_metricbeat="${v_dir_elastic}/metricbeat-${v_version}-linux-x86_64"
#v_file_id_filebeat_config="1fMtbQ9TlRSHi-V5vRccevf4lbi540Vy9"
v_filebeat_config="filebeat.yml"
v_dir_filebeat="${v_dir_elastic}/filebeat-${v_version}-linux-x86_64"

v_logstash_url="https://artifacts.elastic.co/downloads/logstash/logstash-${v_version}-linux-x86_64.tar.gz"
v_filebeat_url="https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-${v_version}-linux-x86_64.tar.gz"
v_filebeat_config_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Beats/filebeat.yml"
v_metricbeat_url="https://artifacts.elastic.co/downloads/beats/metricbeat/metricbeat-${v_version}-linux-x86_64.tar.gz"
v_metricbeat_config_url="https://raw.githubusercontent.com/vincent2mots/elk/main/Beats/metricbeat.yml"
v_exercices_url="https://github.com/vincent2mots/elk/raw/main/Exercices/ELK_Exercices.zip"

# Fonctions
telecharger() {
  # Premier parametre   : l'URL à télécharger
  # Deuxième parametre  : le nom du fichier telecharge
  # Troisieme parametre : l'endroit ou le fichier sera telecharge 
  # Quatrième paramètre : si "unzip", le fichier est dézippé et supprimé ensuite
  wget ${1} -O ${3}/${2}
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
#sysctl -w vm.max_map_count=262144                                                          "/!\      A DECOMMENTER!!!           "*****************************


# Redémarrage de Docker
echo "Redemarrage de Docker"
#systemctl restart docker                                                                   "/!\      A DECOMMENTER!!!           "*****************************

# Téléchargement des images Elasticsearch et Kibana
echo "Telechargement des images elasticsearch et kibana"
#docker pull docker.elastic.co/elasticsearch/elasticsearch:${v_version} --quiet             "/!\      A DECOMMENTER!!!           "*****************************
#docker pull docker.elastic.co/kibana/kibana:${v_version} --quiet                           "/!\      A DECOMMENTER!!!           "*****************************

# Création de la partie Portainer
echo "Mise en place Portainer"
#docker volume create portainer_data                                                        "/!\      A DECOMMENTER!!!           "*****************************
#docker run -d -p 8000:8000 -p 9443:9443 --name portainer \                                   "/!\      A DECOMMENTER!!!           "*****************************
#    --restart=always \                                                                       "/!\      A DECOMMENTER!!!           "*****************************
#    -v /var/run/docker.sock:/var/run/docker.sock \                                         "/!\      A DECOMMENTER!!!           "*****************************
#    -v portainer_data:/data \                                                                  "/!\      A DECOMMENTER!!!           "*****************************
#    portainer/portainer-ce:2.9.3                                                             "/!\      A DECOMMENTER!!!           "*****************************

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
#telecharger_light ${v_file_id_apache_logs} ${v_data_apache_logs} ${v_dir_data}
#telecharger_light ${v_file_id_config1} ${v_config1} ${v_dir_conf_logstash}
#telecharger_light ${v_file_id_config2} ${v_config2} ${v_dir_conf_logstash}
#telecharger_light ${v_file_id_config3} ${v_config3} ${v_dir_conf_logstash}

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
chown -R user:user ${v_dir_elastic}
chmod -R 750 ${v_dir_elastic}

