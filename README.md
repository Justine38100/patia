
# PATIA - Guide d'utilisation

## Table des matières
- [1. Taquin Python (A*, BFS, DFS, IDDFS)](#1-taquin-python-a-bfs-dfs-iddfs)
- [2. PDDL (Hanoi, Taquin, Poursuite-Évasion, Sokoban)](#2-pddl-hanoi-taquin-poursuite-évasion-sokoban)
- [3. Sokoban Java (convert + run)](#3-sokoban-java-convert--run)
- [4. YetAnotherSATPlanner (Java)](#4-yetanothersatplanner-java)
- [5. Remarque](#5-remarque)

## 1. Taquin Python (A*, BFS, DFS, IDDFS)

### Architecture de n_puzzle/

#### Code source

Fichiers non modifiés :
- `n_puzzle/generate_npuzzle.py`: génère des puzzles et les écrit dans des fichiers `.txt`.
  Les fichiers générés sont de la forme :
  - `puzzles/npuzzle_3x3_len3_0.txt`: instance 3x3 générée automatiquement.
  - `puzzles/npuzzle_3x3_len*_*.txt`: famille de tests 3x3 de difficulté croissante.
  - `puzzles/npuzzle_10x10_len*_*.txt`: familles de tests grands formats (performance).

  Ils contiennent une suite d'entiers séparés par des espaces, représentant l'état initial encodé.
- `n_puzzle/node.py`: structure de nœud de recherche et reconstruction du chemin solution.

Fichiers modifiés :
- `n_puzzle/solve_npuzzle.py`: point d'entrée CLI des solveurs et implémentations BFS/DFS/A*/IDDFS.
  Implémentation des fonctions : solve_bfs(), solve_dfs(), solve_astar(), heuristic(), depth_limited_search(), solve_iddfs()

- `n_puzzle/npuzzle.py`: fonctions de base (état but, mouvements, enfants, lecture/écriture, vérification de solution).
  Implémentation de la fonction : `make_move()`.
  Logique d'un mouvement :
    1. Vérifier que l'état courant n'est pas vide, sinon retourner `None`.
    2. Trouver la position de la case vide (`0`) dans la grille.
    3. Calculer la nouvelle position visée selon la direction (`up`, `down`, `left`, `right`).
    4. Vérifier que cette nouvelle position reste dans les bornes de la grille.
    5. Si la position est valide, copier l'état puis échanger `0` avec la tuile voisine.
    6. Retourner le nouvel état après mouvement; sinon retourner `None` si le coup est illégal.

L'encodage d'un état de taquin est basé sur une liste d'entiers.

- Taille d'un état: `n*n` valeurs pour un taquin `n x n`.
- Ordre de lecture: ligne par ligne, de gauche à droite.
- Convention de case vide: la valeur `0`.
- But utilisé dans ce projet: `[0, 1, 2, ..., n*n-1]`.
- Opérateurs autorisés: `up`, `down`, `left`, `right`.
- État invalide: un mouvement qui sort de la grille retourne `None`.

Exemple 3x3:

- Grille
```text
1 2 5
3 4 0
6 7 8
```
- Encodage liste: `[1, 2, 5, 3, 4, 0, 6, 7, 8]`

Ce format est utilisé partout dans `n_puzzle` (`load_puzzle`, `make_move`, `get_children`, solveurs).

#### Pour les graphes :
Chaque sous répertoire de `n_puzzle/plot_generation/` contient une image de graphe au format png, le programme python qui a permis de générer le graphe et un README.md qui donne la commande qui a été utilisée pour générer le graphe.

- `n_puzzle/plot_generation/sorted_puzzles_time/plot_sorted_puzzles_time.py`: graphe trié par difficulté.
- `n_puzzle/plot_generation/size_vs_time_combined/plot_size_vs_time_combined.py`: graphe combiné taille du puzzle vs temps.
- `n_puzzle/plot_generation/size_vs_time_three/plot_size_vs_time_three.py`: version en 3 graphes séparés (BFS/DFS/A*).
- `n_puzzle/plot_generation/moves_vs_time_combined/plot_moves_vs_time_combined.py`: graphe combiné nombre de coups vs temps.
- `n_puzzle/plot_generation/moves_vs_time_three/plot_moves_vs_time_three.py`: version en 3 graphes séparés (BFS/DFS/A*).
- `n_puzzle/plot_generation/*/README.md`: explications locales d'utilisation des scripts de graphes.
- `n_puzzle/plot_generation/*/*.png`: graphes déjà générés (sorties d'exécution).

### Générer des puzzles

#### Prérequis
```bash
sudo apt update
sudo apt install -y python3 python3-pip
```

Vérification rapide:
```bash
python3 --version
pip3 --version
```

Précondition: être à la racine du projet `cd <chemin_vers>/patia`.

```bash
mkdir -p puzzles
python3 n_puzzle/generate_npuzzle.py -s 3 -ml 3 -n 1 puzzles -v
```

Paramètres:
- `-s 3`: puzzles 3x3
- `-ml 3`: longueurs de mélange de 1 à 3
- `-n 1`: 1 puzzle par longueur
- `puzzles`: dossier de sortie
- `-v`: affiche les puzzles

Nombre total de puzzles générés: `ml * n`.

### Lancer un solveur
```bash
python3 n_puzzle/solve_npuzzle.py puzzles/<puzzle.txt a resoudre> -a <methode de resolution> [verbeux] [profondeur maximale]

# Exemple :
python3 n_puzzle/solve_npuzzle.py puzzles/npuzzle_3x3_len3_0.txt -a bfs -v
```
Paramètres:
- `puzzles/<puzzle.txt a resoudre>`: chemin vers le fichier puzzle à résoudre.
- `-a <methode de resolution>`: algorithme de résolution à utiliser.
  Valeurs possibles: `bfs`, `dfs`, `astar`, `iddfs`.
- `-v`: mode verbeux (affiche l'état initial du puzzle).
- `-d <max_depth>`: profondeur maximale pour `iddfs` (optionnel, par défaut `100`).

Comportement IDDFS :
- `depth_limited_search()` explore en profondeur avec une borne de profondeur et évite les cycles sur la branche courante.
- `solve_iddfs()` relance cette recherche pour des bornes successives de `0` à `max_depth`.
- IDDFS retourne la première solution trouvée à profondeur minimale (comme BFS en profondeur, avec une mémoire proche de DFS).

### Générer des graphes
Les scripts sont dans `n_puzzle/plot_generation/`.  
Chaque script enregistre son PNG dans son propre dossier par défaut.

Préconditions :
```bash
python3 -m pip install --user matplotlib
```

#### Puzzles triés par difficulté (1 graphe)
Génération en environ 1 seconde.
```bash
python3 n_puzzle/plot_generation/sorted_puzzles_time/plot_sorted_puzzles_time.py \
  "puzzles/*.txt" --timeout 5 --logy --show
```

#### Taille vs temps (1 graphe)
Génération en environ 3 minutes.
```bash
python3 n_puzzle/plot_generation/size_vs_time_combined/plot_size_vs_time_combined.py \
  --min-size 2 --max-size 5 --shuffle 10 --samples 10 --seed 42 \
  --timeout 5 --logy --show
```

#### Taille vs temps (3 graphes)
Génération en environ 4 minutes.
```bash
python3 n_puzzle/plot_generation/size_vs_time_three/plot_size_vs_time_three.py \
  --min-size 2 --max-size 6 --shuffle 10 --samples 10 --seed 42 \
  --timeout 5 --logy --out-prefix size_time --show
```

#### Coups vs temps (1 graphe)
Génération en environ 2 minutes.
```bash
python3 n_puzzle/plot_generation/moves_vs_time_combined/plot_moves_vs_time_combined.py \
  --size 3 --min-shuffle 1 --max-shuffle 20 --samples 5 --seed 42 \
  --timeout 5 --logy --show
```

#### Coups vs temps (3 graphes)
Génération en environ 4 minutes.
```bash
python3 n_puzzle/plot_generation/moves_vs_time_three/plot_moves_vs_time_three.py \
  --size 3 --min-shuffle 1 --max-shuffle 20 --samples 5 --seed 42 \
  --timeout 5 --logy --out-prefix moves --show
```

## 2. PDDL (Hanoi, Taquin, Poursuite-Évasion, Sokoban)

Précondition: se placer dans `pddl/`.

### Architecture de pddl/
- `pddl/pddl4j-4.0.0.jar`: bibliothèque PDDL4J utilisée par les scripts shell.
- `pddl/pddl4j.sh`: lanceur interactif (choix du solveur + saisie des fichiers). C'est le script que vous nous avez fourni.
- `pddl/pddlj4_auto.sh`: lanceur automatisé (arguments CLI, sans interaction).

#### hanoi
- `pddl/hanoi/domain.pddl`: domaine Hanoi.
- `pddl/hanoi/problem3_3.pddl`: instance Hanoi (3 piquets et 3 disques).

#### taquin
- `pddl/taquin/domain.pddl`: domaine taquin.
- `pddl/taquin/problem3_3/*.pddl`: instances taquin 3x3 (taquin de taille 3 par 3, voir les premières lignes des fichiers problem*.pddl pour visualiser le jeu de taquin qui est en commentaire).
- `pddl/taquin/problem4_4/*.pddl`: instances taquin 4x4. (taquin de taille 4 par 4, voir les premières lignes des fichiers problem*.pddl pour visualiser le jeu de taquin qui est en commentaire).

#### poursuit_evasion
- `pddl/pursuit_evasion/domain.pddl`: domaine poursuite-évasion.
- `pddl/pursuit_evasion/problem_exemple_site.pddl`: instance du "niveau" que l'on retrouve sur votre site (2 poursuivants et 5 zones contaminées (voir les commentaires dans le fichier))
- `pddl/pursuit_evasion/problem_4_noeuds_lineaires.pddl`: autre instance avec 4 nœuds linéaires : @---@---@---@ avec @ des nœuds et --- les arêtes du graphe (2 poursuivants et 2 zones contaminées).

#### sokoban
- `pddl/sokoban/domain.pddl`: domaine Sokoban.
- `pddl/sokoban/pb_json/*.pddl`: instances Sokoban issues de niveaux JSON convertis (les niveaux sont ceux que vous nous avez fournis).

#### blocks, logistics, rover
Ces 3 répertoires n'ont pas été modifiés.

### Prérequis
```bash
# Installer Java 21 :
sudo apt update
sudo apt install -y openjdk-21-jdk
```

### Script interactif
```bash
cd pddl
./pddl4j.sh
```

### Script automatisé
```bash
cd pddl
./pddlj4_auto.sh <solver> <domain.pddl> <problem.pddl> <timeout_sec> [heuristic_id]
```

`solver`:
- `1`: HSP (nécessite `heuristic_id`)
- `2`: FF

Heuristiques HSP (`heuristic_id`):
- `0` AJUSTED_SUM
- `1` AJUSTED_SUM2
- `2` AJUSTED_SUM2M
- `3` COMBO
- `4` MAX
- `5` FAST_FORWARD
- `6` SET_LEVEL
- `7` SUM
- `8` SUM_MUTEX

### Exemples par domaine
#### Hanoi
```bash
cd pddl
./pddlj4_auto.sh 1 hanoi/domain.pddl hanoi/problem3_3.pddl 500 5
```

#### Taquin
```bash
cd pddl
./pddlj4_auto.sh 1 taquin/domain.pddl taquin/problem3_3/problem1.pddl 500 5
```

#### Poursuite-Évasion
```bash
cd pddl
./pddlj4_auto.sh 1 pursuit_evasion/domain.pddl pursuit_evasion/problem_exemple_site.pddl 500 5
```

#### Sokoban
```bash
cd pddl
./pddlj4_auto.sh 1 sokoban/domain.pddl sokoban/pb_json/test1.pddl 500 5
```

## 3. Sokoban Java (convert + run)

Précondition: se placer à la racine du repo `patia/` (certaines commandes vont ensuite dans `sokoban-master/`).

### Architecture

#### Fichiers Ajoutés au projet :
- `sokoban-master/scripts/convert_and_run.sh`: pipeline complet JSON/PDDL -> planning -> visualisation.
- `sokoban-master/scripts/run_pddl_to_sokoban.sh`: pipeline PDDL -> plan -> URDL -> lancement du visualiseur.
- `sokoban-master/scripts/pddl_plan_to_urdl.sh`: convertit la sortie textuelle du planificateur en séquence `URDL`.
- `sokoban-master/scripts/convert_level.sh`: wrapper de conversion de niveau.
- `sokoban-master/scripts/sokoban_level_convert.py`: conversion bidirectionnelle JSON <-> PDDL.
- `sokoban-master/config/test_pddl_custom.json`: niveau de test custom.
- `sokoban-master/config/solution.txt`: séquence de coups consommée par l'agent.

### Explication de l'implémentation

L'implémentation Sokoban suit une chaîne qui part d'un niveau en JSON ou d'un problème en PDDL et aboutit à une visualisation web du plan. Le fichier `sokoban_level_convert.py`, appelé via `convert_level.sh`, joue le rôle de parseur et de convertisseur entre les formats JSON et PDDL afin que les mêmes niveaux puissent être traités par le planificateur et par le visualiseur Java. Le domaine `pddl/sokoban/domain.pddl` contient la modélisation des actions Sokoban utilisées pour la planification. Le script `convert_and_run.sh` orchestre ensuite toutes les étapes automatiquement : conversion éventuelle du niveau, lancement d'un planificateur PDDL4J via `pddlj4_auto.sh`, transformation du plan textuel en séquence de mouvements `URDL` avec `pddl_plan_to_urdl.sh`, puis exécution du code Java fourni pour rejouer la solution. Dans le code Java, l'agent lit la séquence de coups générée et le visualiseur affiche l'évolution du niveau pas à pas, ce qui permet de vérifier concrètement que le plan calculé résout bien le problème d'entrée.

### Prérequis
```bash
# Dépendances système
sudo apt update
sudo apt install -y openjdk-21-jdk maven python3

# Depuis la racine du repo patia/
cd <chemin_vers>/patia

# Pour installer la dépendance à PDDL4J
mvn install:install-file \
  -Dfile=./pddl/pddl4j-4.0.0.jar \
  -DgroupId=fr.uga \
  -DartifactId=pddl4j \
  -Dversion=4.0.0 \
  -Dpackaging=jar \
  -DgeneratePom=true \
  -Djava.net.useSystemProxies=true

# Compiler le projet Sokoban Java
cd sokoban-master
mvn compile -Djava.net.useSystemProxies=true
```

### Lancer la chaîne automatique
```bash
cd sokoban-master
./scripts/convert_and_run.sh <solver> <input.json|input.pddl> <timeout_sec> [heuristic_id]
```

Exemples:
```bash
cd sokoban-master

# Depuis un niveau JSON
./scripts/convert_and_run.sh 1 config/test1.json 500 5

# Depuis un problème PDDL
./scripts/convert_and_run.sh 1 ../pddl/sokoban/pb_json/test1.pddl 500 5
```

Règles de conversion:
- dossier JSON: `sokoban-master/config`
- dossier PDDL: `pddl/sokoban/pb_json`
- même nom de base dans les deux formats (`toto.json` <-> `toto.pddl`)
- entrée `.json` -> sortie `pddl/sokoban/pb_json/<meme_nom>.pddl`
- entrée `.pddl` -> sortie `sokoban-master/config/<meme_nom>.json`

### Visualisation dans une VM :
Essayez avec : `http://<id_VM>:<port_vm>/test.html`

Si cela ne fonctionne pas, essayez avec un tunnel SSH :
1. Lancer le sokoban dans la VM
```bash
# Exemple
cd ~/patia/sokoban-master
./scripts/convert_and_run.sh 1 config/test1.json 500 5
```

2. Sur votre ordinateur, ouvrir un terminal et créer un tunnel SSH :
```bash
ssh -L 8888:localhost:8888 <nom de la VM>@<IP de la VM>
```

3. Dans le navigateur de votre ordinateur :
```bash
http://localhost:8888/test.html
```

## 4. YetAnotherSATPlanner (Java)

Précondition: se placer dans `YetAnotherSATPlanner/`.

### Architecture
- `YetAnotherSATPlanner/yetanothersatplanner.sh`: script de compilation/exécution du solveur.

#### Fichiers Modifiés :
- `YetAnotherSATPlanner/src/fr/uga/pddl4j/yasp/YetAnotherSATPlanner.java`: planificateur SAT principal (parsing, recherche incrémentale en horizon, extraction de plan).
  Implémentation de la fonction : solve()
Idée :
  La fonction `solve()` cherche un plan en augmentant progressivement le nombre d'étapes autorisées.
  Elle utilise SAT4J pour tester s' "il existe un plan de longueur <= k".

  Logique générale :
  1. Initialiser `plan = null` et fixer une borne max `MAXSTEPS`.
  2. Calculer une borne basse avec l'heuristique FastForward (`hlb`).
     Cette borne donne une estimation du nombre minimal d'actions.
  3. Si `hlb > MAXSTEPS`, arrêter tout de suite:
     le solveur estime qu'il faut plus d'étapes que la limite fixée.
  4. Sinon, démarrer avec `steps = hlb` (on commence au plus bas raisonnable).
  5. Construire un encodage SAT du problème pour cet horizon avec `SATEncoding`.
  6. Initialiser SAT4J (timeout, nombre max de variables et de clauses).
  7. Boucler tant qu'on n'a pas trouvé de plan et que `steps <= MAXSTEPS`:
     - ajouter les clauses CNF de l'horizon courant au solveur;
     - imposer le but avec des assumptions temporaires;
     - lancer le test SAT.
  8. Si SAT:
     - récupérer le modèle SAT;
     - convertir ce modèle en plan avec `extractPlan(...)`;
     - arrêter la boucle.
  9. Si UNSAT:
     - augmenter l'horizon (`steps++`);
     - demander à `SATEncoding` de préparer les clauses du niveau suivant (`sat.next()`).
  10. En cas de contradiction immédiate, faire comme UNSAT (passer à l'horizon suivant).
  11. En cas de timeout SAT4J, arrêter la recherche.
  12. Retourner le plan trouvé, ou `null` si rien n'a été trouvé avant la limite.

- `YetAnotherSATPlanner/src/fr/uga/pddl4j/yasp/SATEncoding.java`: encodage CNF du problème de planification.
  Implémentation du constructeur : SATEncoding()
Idée :
  Le constructeur prépare tous les "gabarits" de clauses SAT qui ne dépendent pas encore
  d'un pas de temps précis. Ensuite, il lance un premier encodage jusqu'à l'horizon demandé.

  Logique générale :
  1. Sauvegarder le nombre d'étapes cible (`steps`).
  2. Récupérer l'état initial et compter:
     - le nombre de fluents (`F`);
     - le nombre d'actions (`A`).
  3. Construire les clauses d'état initial:
     pour chaque fluent, créer une clause unitaire qui dit s'il est vrai ou faux au pas 1.
  4. Construire le gabarit du but (`goalList`):
     lister les fluents qui doivent être vrais et ceux qui doivent être faux.
  5. Parcourir toutes les actions pour créer les gabarits:
     - préconditions positives et négatives;
     - effets positifs et négatifs.
  6. Remplir aussi les listes `addList` et `delList`:
     elles indiquent quelles actions peuvent ajouter ou supprimer chaque fluent.
     Ces infos serviront aux axiomes de cadre.
  7. Créer les mutex d'actions:
     pour chaque paire d'actions, ajouter "pas les deux en même temps".
  8. Terminer en appelant `encode(1, steps)` pour générer les clauses du premier horizon.

  Implémentation de la fonction : encode()
Idée :
  La fonction `encode(from, to)` instancie les gabarits au temps réel et remplit:
  - `currentDimacs` (clauses SAT à ajouter),
  - `currentGoal` (but au dernier état).

  Logique générale :
  1. Vider `currentDimacs` et `currentGoal` pour repartir proprement.
  2. Si `from == 1`, réinjecter les clauses de l'état initial.
     Sinon, on ne remet pas l'init (le solveur l'a déjà).
  3. Pour chaque pas `t` entre `from` et `to`:
     - instancier les préconditions au pas `t`;
     - instancier les effets au passage `t -> t+1`;
     - ajouter les axiomes de cadre;
     - ajouter les mutex d'actions au pas `t`.
  4. A la fin, instancier le but au pas `to+1` dans `currentGoal`.
  5. Afficher un message de résumé (nombre de clauses, horizon).

  En version simple:
  `encode()` transforme des règles "génériques" en clauses SAT "avec temps",
  pour que SAT4J puisse tester un horizon précis.

### Prérequis
```bash
cd ~/patia/YetAnotherSATPlanner
mkdir -p lib

# 1) PDDL4J depuis ton repo
cp ../pddl/pddl4j-4.0.0.jar lib/pddl4j-4.0.0.jar

# 2) SAT4J core depuis Maven local (download si absent)
mvn -q dependency:get -Dartifact=org.sat4j:org.sat4j.core:2.3.1 -Djava.net.useSystemProxies=true
cp ~/.m2/repository/org/sat4j/org.sat4j.core/2.3.1/org.sat4j.core-2.3.1.jar lib/org.sat4j.core.jar

# 3) Vérifier
ls -l lib/pddl4j-4.0.0.jar lib/org.sat4j.core.jar
```

### Lancer le script
```bash
cd YetAnotherSATPlanner
./yetanothersatplanner.sh <domain.pddl> <problem.pddl>
```

Exemple:
```bash
cd YetAnotherSATPlanner
./yetanothersatplanner.sh domain.pddl p01.pddl
```

### Résultat observé (preuve expérimentale)

Sortie obtenue:

```text
[INFO] Compilation Java...
[INFO] Domaine : domain.pddl
[INFO] Probleme: p01.pddl
[INFO] Execution du solveur SAT...
parsing domain file "domain.pddl" done successfully
parsing problem file "p01.pddl" done successfully
Encoding : successfully done (255 clauses, 2 steps)
Encoding : successfully done (121 clauses, 3 steps)
Encoding : successfully done (121 clauses, 4 steps)
0: (drop ball1 rooma left) [0]
1: (     move rooma roomb) [0]
2: (pick ball2 rooma left) [0]
3: (drop ball2 roomb left) [0]
```

Ce que montre la trace:
- `parsing domain file "domain.pddl" done successfully` et `parsing problem file "p01.pddl" done successfully`:
  le solveur lit correctement l'entrée demandée (le domaine et le problème passés en argument).
- `Encoding : successfully done (255 clauses, 2 steps)`, puis `3 steps`, puis `4 steps`:
  le solveur teste successivement des horizons de plan de plus en plus grands (`k=2`, puis `k=3`, puis `k=4`).
- l'affichage final des actions:
  ```text
  0: (drop ball1 rooma left)
  1: (move rooma roomb)
  2: (pick ball2 rooma left)
  3: (drop ball2 roomb left)
  ```
  signifie qu'à `k=4`, une solution satisfaisant toutes les contraintes a été trouvée.

Pourquoi c'est correct pour le problème donné:
- les actions affichées proviennent du domaine `domain.pddl` (elles respectent donc ses opérateurs);
- elles sont appliquées dans un ordre temporel (étapes `0..3`);
- chaque action respecte les préconditions/effets encodés;
- l'état final satisfait le but de `p01.pddl`, sinon SAT4J ne pourrait pas valider la formule à cet horizon.

## 5. Remarque
Le travail a été réalisé par Justine Reat.

L’implémentation principale (algorithmes, logique métier et tests) a été développée manuellement.

L’IA a été utilisée uniquement comme aide ponctuelle pour l'écriture des scripts automatiques (exemple : pddl4j.sh).
L'IA m'a également aidée pour la correction de l'orthographe et la reformulation de commentaires déjà rédigés à la main.
