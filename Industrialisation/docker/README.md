## Etapes d'installation de Docker CE sur Ubuntu Jammy

1. Mise à jour des paquets :
``` sh
sudo apt update
```

2. Prerequis pour que **apt** puisse passer par le HTTPS :
``` sh
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```

3. Ajout de la clef GPG :
``` sh
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

4. Ajout du référentiel Docker :
``` sh
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

5. Mise à jour des paquets :
``` sh
sudo apt update
```

6. Choix du référentiel Docker au lieu d'Ubuntu :
``` sh
apt-cache policy docker-ce
```

7. Installation de Docker CE : 
``` sh
sudo apt install docker-ce
```

8. Vérification de la onne installation : 
``` sh
sudo systemctl status docker
```