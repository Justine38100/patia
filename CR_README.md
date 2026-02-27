# CR_README.md

Ce document explique, pour chaque script de génération de graphes, ce que le graphe montre, comment le lancer, comment l'interpréter, et les limites/forces de la méthode.

Tous les scripts sont maintenant rangés dans `n_puzzle/plot_generation/`, un sous-dossier par type de graphe. Par défaut, chaque script enregistre ses PNG dans son propre dossier.

---

## 1) Graphes "puzzles triés" (1 graphe avec 3 courbes)

**Script :** `n_puzzle/plot_generation/sorted_puzzles_time/plot_sorted_puzzles_time.py`

### Ce que le graphe montre
Un seul graphe avec 3 courbes (BFS, DFS, A*).  
L'axe X = l'index des puzzles, triés du plus simple au plus difficile (par longueur BFS ou temps BFS).  
L'axe Y = temps de résolution.

### Options importantes
- `pattern` : glob de fichiers puzzles (ex: `puzzles/*.txt`)
- `--timeout` : limite par algo et par puzzle
- `--sort` : `bfs_len` (défaut) ou `bfs_time`
- `--logy` : échelle log sur Y
- `--out` : fichier PNG (par défaut dans le dossier du script)

Exemple :
```bash
python3 n_puzzle/plot_generation/sorted_puzzles_time/plot_sorted_puzzles_time.py \
  "puzzles/*.txt" --timeout 5 --logy --show
```

### Points forts
- Comparaison directe BFS/DFS/A* sur un même jeu de puzzles.
- Met en évidence l'effet de la difficulté (tri par BFS).

### Points fragiles / limites
- Le tri dépend de BFS (si BFS time-out, l'ordre est biaisé).
- DFS est très instable (peut time-out rapidement).
- Nécessite des puzzles existants sur disque.

---

## 2) Taille vs temps (1 graphe, 3 courbes)

**Script :** `n_puzzle/plot_generation/size_vs_time_combined/plot_size_vs_time_combined.py`

### Ce que le graphe montre
Un seul graphe avec 3 courbes (BFS, DFS, A*).  
X = taille du taquin (N).  
Y = temps moyen (moyenne sur plusieurs puzzles).

### Options importantes
- `--min-size`, `--max-size`
- `--shuffle` : longueur de mélange
- `--samples` : puzzles par taille
- `--seed` : reproductibilité
- `--timeout`, `--logy`, `--out`, `--show`

Exemple :
```bash
python3 n_puzzle/plot_generation/size_vs_time_combined/plot_size_vs_time_combined.py \
  --min-size 2 --max-size 5 --shuffle 10 --samples 10 --seed 42 \
  --timeout 5 --logy --show
```

### Points forts
- Vue globale de la croissance de complexité avec la taille.
- Simple à lancer.

### Points fragiles / limites
- Un shuffle fixe ne garantit pas la même difficulté réelle.
- Peu d'échantillons = courbes bruitées.

---

## 3) Taille vs temps (3 graphes séparés)

**Script :** `n_puzzle/plot_generation/size_vs_time_three/plot_size_vs_time_three.py`

### Ce que le graphe montre
Trois graphes séparés : un pour BFS, un pour DFS, un pour A*.  
X = taille du taquin (N).  
Y = temps moyen.

### Options importantes
Identiques au script combiné, avec `--out-prefix` pour les PNG.

Exemple :
```bash
python3 n_puzzle/plot_generation/size_vs_time_three/plot_size_vs_time_three.py \
  --min-size 2 --max-size 6 --shuffle 10 --samples 10 --seed 42 \
  --timeout 5 --logy --out-prefix size_time --show
```

### Points forts
- Lecture plus claire (une courbe par graphe).
- Même jeu de puzzles pour tous les algos.

### Points fragiles / limites
- Même limites que le graphe combiné (difficulté approximative).

---

## 4) Coups vs temps (1 graphe, 3 nuages de points)

**Script :** `n_puzzle/plot_generation/moves_vs_time_combined/plot_moves_vs_time_combined.py`

### Ce que le graphe montre
Un graphe unique avec 3 nuages de points (BFS, DFS, A*).  
X = longueur de solution **trouvée par l'algo**.  
Y = temps de résolution.

### Options importantes
- `--size` : taille fixe
- `--min-shuffle`, `--max-shuffle`, `--step`
- `--samples`, `--seed`, `--timeout`, `--logy`, `--out`, `--show`

Exemple :
```bash
python3 n_puzzle/plot_generation/moves_vs_time_combined/plot_moves_vs_time_combined.py \
  --size 3 --min-shuffle 1 --max-shuffle 20 --samples 5 --seed 42 \
  --timeout 5 --logy --show
```

### Points forts
- Montre l'effet de la difficulté (longueur de solution) sur le temps.

### Points fragiles / limites
- L'axe X n'est pas comparable entre algos (DFS n'est pas optimal).
- La longueur de mélange ne fixe pas une longueur de solution.

---

## 5) Coups vs temps (3 graphes séparés)

**Script :** `n_puzzle/plot_generation/moves_vs_time_three/plot_moves_vs_time_three.py`

### Ce que le graphe montre
Trois graphes séparés (BFS, DFS, A*), chacun avec son nuage de points.  
X = longueur de solution trouvée par l'algo.  
Y = temps de résolution.

### Options importantes
Identiques au script combiné, avec `--out-prefix`.

Exemple :
```bash
python3 n_puzzle/plot_generation/moves_vs_time_three/plot_moves_vs_time_three.py \
  --size 3 --min-shuffle 1 --max-shuffle 20 --samples 5 --seed 42 \
  --timeout 5 --logy --out-prefix moves --show
```

### Points forts
- Même puzzles pour BFS/DFS/A*.
- Lecture plus claire qu'un graphe unique.

### Points fragiles / limites
- Même limite sur l'axe X (dépend de l'algo).

---

## Conseils pour une comparaison "juste"
- Fixer `--seed` pour la reproductibilité.
- Garder le même nombre d'échantillons (`--samples`).
- Utiliser `--logy` si les temps varient fortement.
- Pour comparer la "difficulté", préférer une longueur de solution optimale (via BFS) si possible.
