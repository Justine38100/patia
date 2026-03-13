********************************************************************
                 Partie 1 : taquin - A*, BFS et DFS    
********************************************************************
Préconditions: 
- être à la racine du projet

1) Générer des puzzles
```bash
python3 n_puzzle/generate_npuzzle.py -s 3 -ml 3 -n 1 puzzles -v
```
- `-s 3` : puzzles 3x3
- `-ml 3` : longueurs 1 à 3
- `-n 1` : 1 puzzle par longueur
- `puzzles` : dossier de sortie
- `-v` : affiche les puzzles

Nombre total de puzzles = `ml * n`.

2) Lancer un solveur
```bash
python3 n_puzzle/solve_npuzzle.py puzzles/npuzzle_3x3_len3_0.txt -a bfs -v
```
- `-a bfs` : BFS (largeur)
- `-v` : affiche l’état initial

3) Générer des graphes

Les scripts de génération sont dans `n_puzzle/plot_generation/`.
Chaque script enregistre ses PNG dans son propre dossier par défaut.

3.1 Puzzles triés par difficulté (1 graphe)
```bash
python3 n_puzzle/plot_generation/sorted_puzzles_time/plot_sorted_puzzles_time.py \
  "puzzles/*.txt" --timeout 5 --logy --show
```

3.2 Taille vs temps (1 graphe)
```bash
python3 n_puzzle/plot_generation/size_vs_time_combined/plot_size_vs_time_combined.py \
  --min-size 2 --max-size 5 --shuffle 10 --samples 10 --seed 42 \
  --timeout 5 --logy --show
```

3.3 Taille vs temps (3 graphes)
```bash
python3 n_puzzle/plot_generation/size_vs_time_three/plot_size_vs_time_three.py \
  --min-size 2 --max-size 6 --shuffle 10 --samples 10 --seed 42 \
  --timeout 5 --logy --out-prefix size_time --show
```

3.4 Coups vs temps (1 graphe)
```bash
python3 n_puzzle/plot_generation/moves_vs_time_combined/plot_moves_vs_time_combined.py \
  --size 3 --min-shuffle 1 --max-shuffle 20 --samples 5 --seed 42 \
  --timeout 5 --logy --show
```

3.5 Coups vs temps (3 graphes)
```bash
python3 n_puzzle/plot_generation/moves_vs_time_three/plot_moves_vs_time_three.py \
  --size 3 --min-shuffle 1 --max-shuffle 20 --samples 5 --seed 42 \
  --timeout 5 --logy --out-prefix moves --show
```

********************************************************************
                 Partie 2 : hanoi - pddl  
********************************************************************
Préconditions: 
- être dans le répertoire pddl (sinon le solver est inconnu)

Lancer le script de base :
```bash
./pddl4j.sh
```
Puis suivre les instructions.

Exemple pour lancer la résolution de hanoi 3 par 3 :
- Choisir l'option 1
- Entrer le nom de domaine : hanoi/domain.pddl
- Entrer le probleme : hanoi/problem3_3.pddl
- Timeout [int]: 500
- Choisir l'option 5 : 5

Lancer le script automatisé :
```bash
./pddlj4_auto.sh <solver> <domain.pddl> <problem.pddl> <timeout_sec> <heuristic_id>
```

Exemple : 
```bash
./pddlj4_auto.sh 1 hanoi/domain.pddl hanoi/problem3_3.pddl 500 5
```

********************************************************************
                 Partie 3 : taquin - pddl  
********************************************************************
Préconditions: 
- être dans le répertoire pddl (sinon le solver est inconnu)

Lancer le script de base :
```bash
./pddl4j.sh
```
Puis suivre les instructions.

Exemple pour lancer la résolution de hanoi 3 par 3 :
- Choisir l'option 1
- Entrer le nom de domaine : taquin/domain.pddl
- Entrer le probleme : taquin/problem3_3/problem1.pddl
- Timeout [int]: 500
- Choisir l'option 5 : 5

Lancer le script automatisé :
```bash
./pddlj4_auto.sh <solver> <domain.pddl> <problem.pddl> <timeout_sec> <heuristic_id>
```

Exemple : 
```bash
./pddlj4_auto.sh 1 taquin/domain.pddl taquin/problem3_3/problem1.pddl 500 5
```

********************************************************************
                 Partie 3 : poursuite évasion - pddl  
********************************************************************
Préconditions: 
- être dans le répertoire pddl (sinon le solver est inconnu)

Lancer le script de base :
```bash
./pddl4j.sh
```
Puis suivre les instructions.

Exemple pour lancer la résolution de hanoi 3 par 3 :
- Choisir l'option 1
- Entrer le nom de domaine : pursuit_evasion/domain.pddl
- Entrer le probleme : pursuit_evasion/problem_exemple_site.pddl
- Timeout [int]: 500
- Choisir l'option 5 : 5

Lancer le script automatisé :
```bash
./pddlj4_auto.sh <solver> <domain.pddl> <problem.pddl> <timeout_sec> <heuristic_id>
```

Exemple : 
```bash
./pddlj4_auto.sh 1 pursuit_evasion/domain.pddl pursuit_evasion/problem_exemple_site.pddl 500 5
```
