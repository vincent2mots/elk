# 🎓 Travaux Pratiques : Visualisation avec Kibana Lens

Ce dépôt contient une série d'exercices pratiques pour maîtriser l'outil **Lens** dans Kibana, en utilisant les jeux de données d'exemple `kibana_sample_data_ecommerce`, `kibana_sample_data_logs` et `kibana_sample_data_flights`.

---

## 🛒 Niveau 1 : Fondamentaux & Métriques simples

### TP 1 : Volume d'activité (Metric)
* **Objectif** : Afficher le nombre total de commandes.
* **Configuration** :
    * Utiliser le type de visualisation **Metric**.
    * Mesure : `Count`.
    * *Optionnel* : Ajouter une comparaison temporelle (**Time Shift**) de 1 semaine pour voir l'évolution.

### TP 2 : Répartition du CA par Sexe (Donut)
* **Objectif** : Analyser la part des revenus selon le genre du client.
* **Configuration** :
    * Utiliser le type **Pie**. Le type Donut n'existe pas mais un Donut = un Pie dans lequel on a mis un trou au milieu
    * Tranches (Slices) : Top values de `customer_gender`.
    * Taille : Somme de `taxless_total_price`.
    * *Astuce* : Dans les options d'affichage, activer les **pourcentages** dans la légende.

### TP 3 : Chronologie des ventes (Histogramme)
* **Objectif** : Visualiser la répartition des commandes dans le temps.
* **Configuration** :
    * Axe horizontal : `order_date`.
    * Axe vertical : `Count`.
    * *Réglage* : Forcer l'intervalle de temps à **Daily** (Journalier) au lieu de "Auto".

---

## 📈 Niveau 2 : Analyses Avancées & Formules

### TP 4 : Corrélation CA vs Quantité (Combo Chart)
* **Objectif** : Comparer le montant des ventes et le volume d'articles vendus.
* **Configuration** :
    * Axe horizontal : `order_date`.
    * Couche 1 (Barres) : Somme de `taxless_total_price`.
    * Couche 2 (Ligne) : Somme de `total_quantity`.
    * **Important** : Configurer la couche "Ligne" sur un **axe Y secondaire** (à droite) pour éviter que la courbe ne soit écrasée.

### TP 5 : Calcul du Panier Moyen (Formules)
* **Objectif** : Utiliser les fonctions mathématiques pour créer un indicateur personnalisé.
* **Configuration** :
    * Type : **Metric**.
    * Mesure : Sélectionner **Formula**.
    * Syntaxe : `sum(taxless_total_price) / sum(total_quantity)`.
    * Formatage : Définir le format d'affichage en **Currency** (€).

### TP 6 : Tracking du dernier client (Last Value)
* **Objectif** : Identifier dynamiquement le nom du dernier acheteur.
* **Configuration** :
    * Type : **Metric**.
    * Mesure : `Last value` du champ `customer_full_name.keyword`.
    * Trié par : `order_date`.

---

## 👨‍💻 Niveau 3 : Tableaux et Hiérarchies

### TP 7 : Top 5 des Catégories (Table)
* **Objectif** : Créer un tableau de performance avec indicateurs visuels.
* **Configuration** :
    * Lignes (Rows) : `category.keyword` (Top 5).
    * Métriques : `Count` et `Sum of taxless_total_price`.
    * *Design* : Ajouter un **formatage conditionnel** (Cell color) sur la colonne du CA.

### TP 8 : Géographie des ventes (Treemap)
* **Objectif** : Visualiser la hiérarchie géographique des revenus.
* **Configuration** :
    * Type : **Treemap**.
    * Groupements : `geoip.country_iso_code` puis `geoip.region_name`.
    * Taille : Somme de `taxless_total_price`.

### TP 9 : Objectif de Ventes (Layers & Static values)
* **Objectif** : Comparer les ventes réelles par rapport à un objectif fixe.
* **Configuration** :
    * Type : **Area** (Aire) sur le CA par jour.
    * Ajouter une couche (Layer) de type **Reference line** ou utiliser une **Formula** avec une valeur fixe (ex: `5000`) pour tracer la ligne d'objectif.

---

## 📡 Niveau 4 : Visualisation de logs *(nouveau)*

### TP 10 : Répartition des codes retour dans le temps (Bar vertical empilé)
* **Objectif** : Visualiser le volume de requêtes par heure, empilé par famille de code retour.
* **Configuration** :
    * Type **Bar vertical stacked**.
    * Axe horizontal : `@timestamp` (intervalle **Hourly**).
    * Breakdown : `response.keyword` (Top values).
    * Axe vertical : `Count`.

### TP 11 : Carte des origines de trafic (Map)
* **Objectif** : Localiser géographiquement le volume de requêtes.
* **Configuration** :
    * Type **Maps** (ou visualisation Lens de type carte si disponible dans votre licence).
    * Champ géo-point : `geo.coordinates`.
    * Métrique : `Count`, symbolisée par taille de bulle.

### TP 12 : Table des user-agents les plus fréquents avec formatage conditionnel
* **Objectif** : Repérer rapidement les navigateurs générant le plus d'erreurs.
* **Configuration** :
    * Lignes : `machine.os.keyword` (Top 10).
    * Métriques : `Count` et **Formula** `count(kql='response >= 400') / count()` pour le taux d'erreur.
    * Formatage conditionnel (couleur) sur la colonne taux d'erreur.

---

## ✈️ Niveau 5 : Séries temporelles et comparaisons *(nouveau)*

### TP 13 : Retards moyens par compagnie (Bar horizontal + Formula)
* **Objectif** : Comparer visuellement les compagnies selon leur retard moyen.
* **Configuration** :
    * Type **Bar horizontal**.
    * Axe : `Carrier.keyword`.
    * Métrique : **Formula** `average(FlightDelayMin)`, format numérique avec 1 décimale et suffixe "min".

### TP 14 : Prix moyen du billet vs distance (Combo / Scatter)
* **Objectif** : Visualiser la corrélation entre distance parcourue et prix moyen.
* **Configuration** :
    * Type **XY** en nuage de points si disponible, sinon Combo chart avec deux métriques sur le même axe temporel : `Average(DistanceKilometers)` et `Average(AvgTicketPrice)` sur axes Y primaire/secondaire.

---

## 🧮 Niveau 6 : Lens propulsé par ES|QL *(nouveau, v9)*

### TP 15 : Visualisation "Lens ES|QL" : atterrir directement sur un résultat de requête
* **Objectif** : Construire une visualisation Lens directement à partir d'une requête ES|QL plutôt qu'en glisser-déposer visuel — pont concret entre ES|QL et Lens.
* **Configuration** :
    * Créer une nouvelle visualisation Lens, choisir le mode **ES|QL**.
    * Coller la requête suivante (reprise du TP ES|QL "Taux de retard par compagnie") :
      ```esql
      FROM kibana_sample_data_flights
      | STATS
          nb_vols          = COUNT(*),
          nb_retards       = COUNT(*) WHERE FlightDelay == true
        BY Carrier
      | EVAL taux_retard_pct = ROUND(nb_retards * 100.0 / nb_vols, 1)
      | SORT taux_retard_pct DESC
      ```
    * Mapper `Carrier` en axe horizontal et `taux_retard_pct` en métrique, type **Bar**.
* **À savoir** : si vous modifiez la requête ES|QL par la suite, Lens essaie de conserver la configuration (axes, couleurs) tant que la structure du résultat reste compatible. Limite à connaître : les drilldowns ne fonctionnent que sur des valeurs adossées à un vrai champ d'index, pas sur une colonne calculée (`EVAL`/`STATS`).

---

## 🛠 Prérequis
1. Disposer d'une instance Elasticsearch & Kibana (v9 pour le Niveau 6).
2. Charger les données de test : Accueil Kibana > **Add data** > *Sample eCommerce orders* (Niveaux 1-3), *Sample web logs* (Niveau 4), *Sample flight data* (Niveaux 5-6).