## Script d'industrialisation
Pour gagner du temps lors de l'installation de la stack complète (avec les exercices) sur les postes des stagiaires

``` sh
cd ~
wget https://raw.githubusercontent.com/vincent2mots/elk/main/Industrialisation/elk_formation_auto.sh -O elk_formation_auto.sh
```

``` sh
sudo chmod +x elk_formation_auto.sh
```

## Installation sur un environnement  :
``` sh
sudo ./elk_formation_auto.sh
```

## Configuration de Portainer :
Une fois le tout bien installé, se rendre sur l'URL suivante pour terminer la configuration :

[Lien vers Portainer](https://localhost:9443)


Compte : **admin**
Mot de passe à créer : **Formation2023**