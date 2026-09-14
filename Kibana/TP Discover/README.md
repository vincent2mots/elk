# 🔎 Travaux Pratiques : Recherches avec Discover

Ce dépôt contient une série d'exercices pratiques pour maîtriser le menu **Discover** de Kibana : recherche KQL, Lucene, ES|QL, filtres, sauvegarde de recherches et profiling de champs — en utilisant les jeux de données d'exemple `kibana_sample_data_logs`, `kibana_sample_data_ecommerce` et `kibana_sample_data_flights`.

*(Même esprit que le dépôt [`Kibana/TP Lens`](https://github.com/vincent2mots/elk/tree/main/Kibana/TP%20Lens) : un TP = un objectif + une configuration à reproduire.)*

---

## 🟢 Niveau 1 : KQL — les bases

### TP 1 : Recherche simple par mot-clé
* **Objectif** : Trouver toutes les requêtes ayant transité par le navigateur Chrome.
* **Configuration** :
  * Data view : `kibana_sample_data_logs`.
  * Barre de recherche (KQL) : `agent : *Chrome*`
  * *Astuce* : utiliser l'autocomplétion (commencer à taper `agent` puis `:`) pour découvrir les champs disponibles sans avoir à les connaître par cœur.

### TP 2 : Combiner ET / OU / NON
* **Objectif** : Trouver les requêtes en erreur serveur (code ≥ 500) qui ne proviennent pas des États-Unis.
* **Configuration** :
  * `response >= 500 and not geo.src : "US"`
  * *Variante* : demander aux stagiaires de reformuler avec un `or` pour élargir à un deuxième pays exclu, et comparer le nombre de résultats.

### TP 3 : Comparaisons numériques et existence d'un champ
* **Objectif** : Trouver les requêtes qui pèsent plus de 5000 octets et qui ont un champ `referer` renseigné.
* **Configuration** :
  * `bytes > 5000 and referer : *`
  * *Discussion* : que se passe-t-il si on retire `referer : *` ? Faire constater que certains documents n'ont simplement pas ce champ (JSON schema-less).

---

## 🟡 Niveau 2 : Lucene — aller plus loin

### TP 4 : Bascule KQL → Lucene et plage fermée
* **Objectif** : Retrouver les commandes dont le montant total est compris entre 100 et 200, avec la notation `[... TO ...]`.
* **Configuration** :
  * Data view : `kibana_sample_data_ecommerce`.
  * Basculer le sélecteur de langage (en bas à gauche de la barre de recherche) sur **Lucene**.
  * `taxful_total_price:[100 TO 200]`
  * *Comparaison* : refaire la même recherche en KQL (`taxful_total_price >= 100 and taxful_total_price <= 200`) et faire constater aux stagiaires que Lucene est ici plus concis pour une plage fermée.

### TP 5 : Wildcard et expression régulière
* **Objectif** : Retrouver toutes les URL contenant un chemin `/kibana/...` en utilisant une regex.
* **Configuration** :
  * Data view : `kibana_sample_data_logs`, langage **Lucene**.
  * `url:/.*\/kibana\/.*/`
  * *Astuce pédagogique* : montrer d'abord la version wildcard plus simple `url:*kibana*` et discuter des cas où seule une regex peut exprimer le motif recherché (ex. ancre en début/fin de chaîne).

### TP 6 : Recherche floue (fuzzy) et boost
* **Objectif** : Retrouver un client même en cas de faute de frappe dans son nom, et faire remonter en priorité les commandes d'une catégorie donnée.
* **Configuration** :
  * Data view : `kibana_sample_data_ecommerce`, langage **Lucene**.
  * Fuzzy : `customer_first_name:"Kamel~"` (tolère la faute de frappe et doit quand même remonter les commandes de "Kamal").
  * Boost : `category:"Women's Shoes"^3 or category:"Men's Shoes"` — faire remarquer que le tri par pertinence (colonne de score, à activer dans les options de la table) change en conséquence.
  * *Remarque* : si le prénom utilisé n'existe pas (ou plus) dans le jeu de données au moment du TP, utiliser l'onglet **Field statistics** (TP 10) sur `customer_first_name` pour repérer un prénom réel et construire sa propre variante fautive.

---

## 🔵 Niveau 3 : Manipuler le temps, filtrer, sauvegarder

### TP 7 : Plage de dates précise et histogramme
* **Objectif** : Isoler une seule journée de données et observer sa répartition horaire.
* **Configuration** :
  * Data view : `kibana_sample_data_flights`.
  * Sélecteur de temps : choisir une plage "personnalisée" d'une journée (l'histogramme au-dessus du tableau se réajuste automatiquement).
  * *Astuce* : cliquer-glisser directement sur une barre de l'histogramme pour zoomer sur une tranche horaire précise, sans retoucher au sélecteur de dates.

### TP 8 : Filtres épinglés et exclusion
* **Objectif** : Combiner un filtre "structurel" (toujours actif) avec une recherche libre changeante.
* **Configuration** :
  * Ajouter un filtre `Carrier is Logstash Airways` via le bouton "+ Add filter" (plutôt que dans la barre de recherche).
  * Basculer ce filtre en **négation** (bouton "is" → "is not") pour exclure cette compagnie à la place.
  * **Épingler** le filtre (icône épingle) : il reste actif même si on change de data view — bonne pratique à montrer pour un filtre "permanent" (ex. exclure un environnement de test).

### TP 9 : Sauvegarder une recherche et la réutiliser
* **Objectif** : Capitaliser une recherche pour ne pas avoir à la retaper, et la réutiliser comme source d'une visualisation.
* **Configuration** :
  * Reprendre la recherche du TP 2 (erreurs serveur hors US), cliquer **Save** en haut de Discover.
  * Créer une nouvelle visualisation Lens et, à la création, choisir cette recherche sauvegardée comme source plutôt que la data view brute.
  * *Discussion* : quel est l'intérêt ? (réponse attendue : si on modifie la recherche sauvegardée plus tard, toutes les visualisations qui s'appuient dessus se mettent à jour automatiquement).

---

## 🟣 Niveau 4 : Profiler ses données avant de les exploiter

### TP 10 : Field statistics
* **Objectif** : Avant de construire un TP d'agrégation, comprendre rapidement la distribution des valeurs d'un champ.
* **Configuration** :
  * Data view : `kibana_sample_data_ecommerce`.
  * Onglet **"Field statistics"** (à côté de "Documents") en haut du tableau Discover.
  * Observer la distribution de `customer_gender` (peu de valeurs distinctes, bien pour une agrégation `terms`) puis celle de `customer_full_name` (beaucoup de valeurs quasi uniques, plutôt un mauvais candidat pour un Pie chart).
  * *Lien avec la section "Types de données" du support* : c'est l'endroit où repérer d'éventuelles variantes de casse ou fautes de saisie avant de les agréger (`"Male"` vs `"MALE"`).

---

## 🟠 Niveau 5 : ES|QL dans Discover

### TP 11 : Premier pipeline ES|QL directement dans Discover
* **Objectif** : Retrouver, sans quitter Discover, le top 5 des pays générant le plus de trafic en erreur.
* **Configuration** :
  * Cliquer sur le sélecteur de langage et choisir **ES|QL** (ou bouton *"Try ES|QL"*).
  * Requête :
    ```esql
    FROM kibana_sample_data_logs
    | WHERE TO_INTEGER(response) >= 400
    | STATS nb_erreurs = COUNT() BY geo.src
    | SORT nb_erreurs DESC
    | LIMIT 5
    ```
  * *Lien avec la partie ES|QL du support* : c'est exactement le TP 5 de cette partie, exécuté ici dans Discover plutôt que dans Dev Tools.

### TP 12 : D'ES|QL vers une visualisation Lens
* **Objectif** : Transformer en un clic un résultat ES|QL de Discover en visualisation.
* **Configuration** :
  * Reprendre la requête du TP 11.
  * Bouton **"Save"** puis **"Visualize"** (ou équivalent selon la version) pour ouvrir directement le résultat dans Lens en mode ES|QL.
  * Mapper `geo.src` en axe et `nb_erreurs` en métrique, type **Bar**.

---

## 🔴 Bonus — Recherche sémantique dans Discover

### TP 13 : Chercher "par le sens" sans quitter Discover
* **Prérequis** : avoir réalisé le TP 19 de la partie "Recherche sémantique avec `semantic_text`" du support (index `tickets_support`).
* **Objectif** : montrer que Discover fonctionne aussi nativement sur un champ `semantic_text`, sans manipulation particulière.
* **Configuration** :
  * Créer une data view sur l'index `tickets_support`.
  * Dans la barre de recherche (KQL), taper simplement : `description : "ma voiture ne veut pas démarrer"`.
  * Constater que le Ticket 1 ("Le moteur refuse de tourner...") remonte malgré l'absence de mots communs — exactement le même mécanisme qu'en Query DSL, mais depuis l'interface de découverte de données que les stagiaires utilisent depuis le début de la formation.

---

## 🛠 Prérequis généraux
1. Disposer d'une instance Elasticsearch & Kibana (v9).
2. Charger les 3 jeux de données de démo : Accueil Kibana > **Add data** > *Sample web logs*, *Sample eCommerce orders*, *Sample flight data*.
3. Pour le TP 13 (bonus) uniquement : avoir un nœud Machine Learning actif dans le cluster et avoir réalisé le TP 19 de la partie `semantic_text` du support.