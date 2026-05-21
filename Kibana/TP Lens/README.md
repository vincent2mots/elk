# 🎓 Travaux Pratiques : Visualisation avec Kibana Lens

Ce dépôt contient une série d'exercices pratiques pour maîtriser l'outil **Lens** dans Kibana, en utilisant le jeu de données d'exemple `kibana_sample_data_ecommerce`.

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
    * Utiliser le type **Donut**.
    * Tranches (Slices) : Top values de `customer_gender`.
    * Taille : Somme de `taxless_total_price`.
    * *Astuce* : Dans les options d'affichage, activer les **pourcentages** dans la légende.

### TP 3 : Chronologie des ventes (Histogramme)
* **Objectif** : Visualiser la répartition des commandes dans le temps.
* **Configuration** :
    * Axe X : `order_date`.
    * Axe Y : `Count`.
    * *Réglage* : Forcer l'intervalle de temps à **Daily** (Journalier) au lieu de "Auto".

---

## 📈 Niveau 2 : Analyses Avancées & Formules

### TP 4 : Corrélation CA vs Quantité (Combo Chart)
* **Objectif** : Comparer le montant des ventes et le volume d'articles vendus.
* **Configuration** :
    * Axe X : `order_date`.
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

## 🛠 Prérequis
1. Disposer d'une instance Elasticsearch & Kibana.
2. Charger les données de test : Accueil Kibana > **Add data** > **Sample eCommerce orders**.