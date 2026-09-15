# 🧮 Travaux Pratiques : ES|QL

Ce dépôt contient une série d'exercices pratiques pour découvrir **ES|QL** (Elasticsearch Query Language), en utilisant les 3 jeux de données d'exemple : `kibana_sample_data_ecommerce`, `kibana_sample_data_logs` et `kibana_sample_data_flights`.

*(Pour la théorie complète — positionnement vs DSL/KQL, liste des commandes, fonctions — voir la partie "ES|QL" du support de formation.)*

Une requête ES|QL s'exécute soit dans **Dev Tools** (`POST /_query`), soit directement dans **Discover** (sélecteur de langage → ES|QL), soit dans **Lens** (visualisation de type ES|QL).

```json
POST /_query?format=txt
{
  "query": """
FROM kibana_sample_data_ecommerce
| STATS nb_commandes = COUNT() BY day_of_week
| SORT nb_commandes DESC
"""
}
```

---

## 🛒 Niveau 1 : Sample eCommerce orders — agrégations business

### TP 1 : CA et panier moyen par catégorie
* **Objectif** : Produire, en une seule requête, le chiffre d'affaires total, le nombre de commandes et le panier moyen par catégorie de produit, triés par CA décroissant.
* **Requête** :
  ```esql
  FROM kibana_sample_data_ecommerce
  | STATS
      ca = SUM(taxful_total_price),
      nb_commandes = COUNT(),
      panier_moyen = AVG(taxful_total_price)
    BY category.keyword
  | SORT ca DESC
  | LIMIT 10
  ```

### TP 2 : Segmentation avec `EVAL` et `CASE`
* **Objectif** : Créer une colonne "segment client" (petit / moyen / gros panier) selon le montant de la commande, puis compter les commandes par segment.
* **Requête** :
  ```esql
  FROM kibana_sample_data_ecommerce
  | EVAL segment = CASE(
      taxful_total_price < 50, "petit panier",
      taxful_total_price < 150, "panier moyen",
      "gros panier"
    )
  | STATS nb = COUNT() BY segment
  | SORT nb DESC
  ```

### TP 3 : Top clients et champs multi-valués (`MV_EXPAND`)
* **Objectif** : Lister, pour les 5 plus gros clients par CA, la liste des catégories de produits achetées (champ multi-valué).
* **Requête** :
  ```esql
  FROM kibana_sample_data_ecommerce
  | STATS ca = SUM(taxful_total_price), categories = VALUES(category.keyword)
    BY customer_full_name.keyword
  | SORT ca DESC
  | LIMIT 5
  ```
* **Variante** : ajouter `| MV_EXPAND categories` à la fin et comparer le nombre de lignes obtenu avant/après — bon exercice pour comprendre les champs multi-valués.

---

## 📈 Niveau 2 : Sample web logs — analyse de logs

### TP 4 : Taux d'erreur par code retour HTTP
* **Objectif** : Compter les requêtes par tranche de code retour (2xx/3xx/4xx/5xx) en un seul passage, avec des filtres **par agrégation** (`STATS ... WHERE`).
* **Requête** :
  ```esql
  FROM kibana_sample_data_logs
  | STATS
      nb_total          = COUNT(*),
      nb_succes         = COUNT(*) WHERE TO_INTEGER(response) < 300,
      nb_erreur_client  = COUNT(*) WHERE TO_INTEGER(response) >= 400 AND TO_INTEGER(response) < 500,
      nb_erreur_serveur = COUNT(*) WHERE TO_INTEGER(response) >= 500
  | EVAL pct_erreur_serveur = ROUND(nb_erreur_serveur * 100.0 / nb_total, 1)
  ```
* **À montrer** : la syntaxe `STATS expression WHERE condition` calcule plusieurs métriques conditionnelles en un seul passage sur les données, sans multiplier les requêtes.

### TP 5 : Top pays sources d'erreurs
* **Objectif** : Identifier les pays (`geo.src`) générant le plus de requêtes en erreur (code ≥ 400).
* **Requête** :
  ```esql
  FROM kibana_sample_data_logs
  | WHERE TO_INTEGER(response) >= 400
  | STATS nb_erreurs = COUNT() BY geo.src
  | SORT nb_erreurs DESC
  | LIMIT 10
  ```

### TP 6 : `CATEGORIZE` pour regrouper des URL similaires *(9.1+)*
* **Objectif** : Regrouper automatiquement les URL consultées par motif, sans écrire de regex à la main.
* **Requête** :
  ```esql
  FROM kibana_sample_data_logs
  | STATS nb = COUNT() BY motif = CATEGORIZE(url)
  | SORT nb DESC
  | LIMIT 10
  ```
* **Discussion** : comparer avec ce qu'il aurait fallu écrire en agrégation `significant_terms` (voir TP Discover / DSL).

---

## ✈️ Niveau 3 : Sample flight data — jointures et séries temporelles

### TP 7 : Taux de retard par compagnie
* **Objectif** : Calculer, par transporteur (`Carrier`), le nombre de vols, le nombre de vols retardés et le taux de retard.
* **Requête** :
  ```esql
  FROM kibana_sample_data_flights
  | STATS
      nb_vols          = COUNT(*),
      nb_retards       = COUNT(*) WHERE FlightDelay == true,
      retard_moyen_min = AVG(FlightDelayMin)
    BY Carrier
  | EVAL taux_retard_pct = ROUND(nb_retards * 100.0 / nb_vols, 1)
  | SORT taux_retard_pct DESC
  ```
* *(la syntaxe `COUNT(*) WHERE ...` filtre uniquement cette métrique, sans affecter les autres agrégations ni le `BY Carrier`.)*

### TP 8 : `LOOKUP JOIN` — enrichir les vols avec un référentiel pays
* **Objectif** : Découvrir la syntaxe de jointure ES|QL en enrichissant les vols avec une zone commerciale associée au pays de destination.
* **Étape 1 — créer l'index de référence, en mode `lookup`** :
  ```json
  PUT /zones_commerciales
  {
    "settings": { "index.mode": "lookup" },
    "mappings": {
      "properties": {
        "DestCountry": { "type": "keyword" },
        "zone": { "type": "keyword" }
      }
    }
  }

  POST /zones_commerciales/_bulk
  { "index": {} }
  { "DestCountry": "US", "zone": "Amérique du Nord" }
  { "index": {} }
  { "DestCountry": "IT", "zone": "Europe" }
  { "index": {} }
  { "DestCountry": "JP", "zone": "Asie" }
  ```
* **Étape 2 — jointure ES|QL** :
  ```esql
  FROM kibana_sample_data_flights
  | LOOKUP JOIN zones_commerciales ON DestCountry
  | STATS nb_vols = COUNT(), ca = SUM(AvgTicketPrice) BY zone
  | SORT ca DESC
  ```
* **Point de vigilance** : `LOOKUP JOIN` exige un index cible explicitement en `index.mode: lookup` — contrairement à `ENRICH`, qui repose sur une policy pré-calculée.

### TP 9 : Répartition des annulations par jour de la semaine
* **Objectif** : Compter les vols annulés par jour de la semaine (manipulation de dates).
* **Requête** :
  ```esql
  FROM kibana_sample_data_flights
  | WHERE Cancelled == true
  | EVAL jour = DATE_FORMAT("EEEE", timestamp)
  | STATS nb_annulations = COUNT() BY jour
  | SORT nb_annulations DESC
  ```

---

## 🎓 Pour aller plus loin

- `INLINE STATS` et les **sous-requêtes** (9.4+) : pour des calculs de type "part du total" sans requête intermédiaire.
- ES|QL est aussi exposé via l'API `_query` — utilisable depuis une application (Node.js, Python, Java...) exactement comme le Query DSL.
- Toutes les fonctionnalités du Query DSL n'ont pas (encore) d'équivalent ES|QL — le champ s'élargit à chaque version.

## 🛠 Prérequis
1. Disposer d'une instance Elasticsearch & Kibana (v9).
2. Charger les 3 jeux de données de démo : Accueil Kibana > **Add data** > *Sample eCommerce orders*, *Sample web logs*, *Sample flight data*.