## Prérequis pour une formation sur Windows :

1. Télécharger et installer Docker Desktop pour Windows disponible sur le **[lien suivant](https://www.docker.com/products/docker-desktop/)**

2. Une fois Docker Desktop complètement installé, télécharger les images Docker 
suivantes, à l'aide de l'invite de commande Windows :
``` sh
docker pull  docker.elastic.co/elasticsearch/elasticsearch:8.18.2
```
``` sh
docker pull  docker.elastic.co/kibana/kibana:8.18.2
```

Le reste de l'installation / configuration pourra se faire en séance :

3. Augmentation du paramètre vm.max_map_count, à l'aide de commandes Windows :
``` sh
wsl -d docker-desktop
```
``` sh
echo 262144 >> /proc/sys/vm/max_map_count
```
Il faut redémarrer Docker Desktop pour que cette modification soit bien prise en compte :

 ![](https://raw.githubusercontent.com/vincent2mots/elk/main/Windows/images/restart_windows_docker_desktop.PNG)

4. Installation et configuration de Portainer :
``` sh
docker volume create portainer_data
```

``` sh
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```

Aller sur l'URL [suivante](https://localhost:9443) pour continuer les actions

``` sh
docker container ls
```
``` sh
docker stop <ID_CONTENEUR>
```
``` sh
docker start portainer
```

Lien vers l'ajout de données de démo : http://localhost:5601/app/home#/tutorial_directory/sampleData
