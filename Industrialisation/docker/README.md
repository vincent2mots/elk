## Etapes d'installation de Docker CE sur Ubuntu Jammy

1. Mise à jour des paquets :
``` sh
sudo apt update
```

2. Installation de Firefox :
``` sh
sudo apt install firefox
```

3. Prerequis pour que **apt** puisse passer par le HTTPS :
``` sh
sudo apt install apt-transport-https ca-certificates curl software-properties-common
```

4. Ajout de la clef GPG :
``` sh
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

5. Ajout du référentiel Docker :
``` sh
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

6. Mise à jour des paquets :
``` sh
sudo apt update
```

7. Choix du référentiel Docker au lieu d'Ubuntu :
``` sh
apt-cache policy docker-ce
```

8. Installation de Docker CE : 
``` sh
sudo apt install docker-ce
```

9. Vérification de la onne installation : 
``` sh
sudo systemctl status docker
```