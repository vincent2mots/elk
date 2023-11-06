## Création des stacks sur Portainer

Procédure pour la création des stacks sous Portainer

### TP 1
Les docker compose sont maintenant disponibles sur GitHub et il est possible facilement d'intégrer cela avec Portainer :

Créer une nouvelle stack et choisir "Repository" dans les méthodes de construction :
![](https://raw.githubusercontent.com/vincent2mots/elk/main/Portainer/images/tp1.PNG)

Renseigner les champs comme suit :
- Repository URL : 
``` https://github.com/vincent2mots/elk.git ```
- Repository reference : LAISSER LA VALEUR PAR DEFAUT
- Compose path : tp1.yml

### TP 2
Une fois la stack du TP1 supprimé, faire comme ci-après :

Renseigner les champs comme suit :
- Repository URL : https://github.com/vincent2mots/elk.git
- Repository reference : LAISSER LA VALEUR PAR DEFAUT
- Compose path : tp2.yml