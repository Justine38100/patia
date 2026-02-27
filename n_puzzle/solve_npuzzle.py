import argparse
import math
import time
import heapq

from node import Node
from typing import List
from collections import deque

from npuzzle import (Solution, State, Move, UP, DOWN, LEFT, RIGHT, create_goal, get_children, is_goal, load_puzzle, to_string, is_solution)

BFS = 'bfs'
DFS = 'dfs'
ASTAR = 'astar'
IDDFS = 'iddfs'

def solve_bfs(open : List[Node]) -> Solution:
    '''Solve the puzzle using the BFS algorithm'''
    
    # On récupère la racine
    racine : Node = open[0] 

    # On calcule la dimension du puzzle (si on a 9 case alors la dimension est 3)
    dimension : int = int(math.sqrt(len(racine.state)))

    objectif : State = create_goal(dimension) # On crée l'état objectif => [1, 2, 3, ..., 0]
    coups_possibles : List[Move] = [UP, DOWN, LEFT, RIGHT]

    # On crée une file avec un seul élément dedans pour l'instant.
    file_bfs : deque[Node] = deque([racine])

    # Ensemble des états déjà visités
    visites : set[tuple[int]] = set()
    visites.add(tuple(racine.state)) # On ajoute la racine aux visités

    # Tant que la liste n'est pas vide on continue!
    while file_bfs:
        noeud_courant : Node = file_bfs.popleft()  # on explore le plus ancien

        # Si on a atteint l'état objectif, on reconstruit la solution
        if is_goal(noeud_courant.state, objectif):
            return noeud_courant.get_path() # Pour remonter de parents en parents (gardé dans Node)

        # On veut ajouter les enfants du noeud courant dans la file
        for etat_enfant, coup in get_children(noeud_courant.state, coups_possibles, dimension):
            cle : tuple[int] = tuple(etat_enfant)

            # Si déjà vu, on passe
            if cle in visites:
                continue

            # Sinon, on enregistre et on ajoute dans la file
            visites.add(cle)
            noeud_enfant = Node(state=etat_enfant, move=coup, parent=noeud_courant)
            file_bfs.append(noeud_enfant)

    # Si la file est vide => pas de solution trouvée
    return []


def solve_dfs(open : List[Node]) -> Solution:
    '''Solve the puzzle using the DFS algorithm'''

    # On récupère la racine
    racine : Node = open[0] 

    # On calcule la dimension du puzzle (si on a 9 case alors la dimension est 3)
    dimension : int = int(math.sqrt(len(racine.state)))

    objectif : State = create_goal(dimension) # On crée l'état objectif => [1, 2, 3, ..., 0]
    coups_possibles : List[Move] = [UP, DOWN, LEFT, RIGHT]

    # On crée une pile avec un seul élément dedans pour l'instant.
    pile : List[Node] = [racine]

    # Ensemble des états déjà visités
    visites : set[tuple[int]]= set()
    visites.add(tuple(racine.state)) # On ajoute la racine aux visités

    # Tant que la liste n'est pas vide on continue!
    while pile:
        noeud_courant : Node = pile.pop()  # on explore le plus récent

        # Si on a atteint l'état objectif, on reconstruit la solution
        if is_goal(noeud_courant.state, objectif):
            return noeud_courant.get_path() # Pour remonter de parents en parents (gardé dans Node)

        # On veut ajouter les enfants du noeud courant dans la pile
        for etat_enfant, coup in get_children(noeud_courant.state, coups_possibles, dimension):
            cle : tuple[int] = tuple(etat_enfant)

            # Si déjà vu, on passe
            if cle in visites:
                continue

            # Sinon, on enregistre et on ajoute dans la file
            visites.add(cle)
            noeud_enfant = Node(state=etat_enfant, move=coup, parent=noeud_courant)
            pile.append(noeud_enfant)

    return []

def solve_astar(open : List[Node]) -> Solution:
    '''Solve the puzzle using the A* algorithm'''

    # On récupère la racine
    racine : Node = open[0] 

    # On calcule la dimension du puzzle (si on a 9 case alors la dimension est 3)
    dimension : int = int(math.sqrt(len(racine.state)))

    objectif : State = create_goal(dimension) # On crée l'état objectif => [1, 2, 3, ..., 0]
    coups_possibles : List[Move] = [UP, DOWN, LEFT, RIGHT]

    # Initialisation de la file à priorité

    compteur : int = 0 # On veut différencier les noeuds dans la file à priorité.
    # En effet, dans pour savoir quel élément est prioritaire, python regarde d'abord le coût f() (premier élement) de notre triplet,
    # puis si deux éléments ont le même coût, il regarde le compteur (deuxième élément) pour les différencier.

    racine.cost = 0 # Coût g()
    racine.heuristic = heuristic(racine.state, objectif) # Coût h()
    file_prio = []
    heapq.heappush(file_prio, (racine.cost + racine.heuristic, compteur, racine)) # Le tas garde l'élément le plus petit toujours en haut

    meilleur_g : dict[tuple[int], int] = {tuple(racine.state): 0} # Meilleur coût g() pour chaque état rencontré
    # Initialisé à 0 pour la racine, et on met à jour au fur et à mesure

    while file_prio:
        _, _, noeud_courant = heapq.heappop(file_prio) # On explore le noeud avec le plus petit f() = g() + h() si égalité, on va regarder le compteur.

        # Si on a atteint l'état objectif, on reconstruit la solution
        if is_goal(noeud_courant.state, objectif):
            return noeud_courant.get_path() # Pour remonter de parents en parents (gardé dans Node)
        
        for etat_enfant, coup in get_children(noeud_courant.state, coups_possibles, dimension):
            cle : tuple[int] = tuple(etat_enfant)
            g_nouveau : int = noeud_courant.cost + 1 # Coût pour atteindre le noeud enfant

            # Si cet état a déjà été vu, et que le coût pour y arriver maintenant est plus grand ou égal au meilleur coût déjà connu, alors on n’explore pas ce chemin.
            if cle in meilleur_g and g_nouveau >= meilleur_g[cle]:
                continue # On a déjà un meilleur chemin, pas besoin de l'explorer.

            h : int = heuristic(etat_enfant, objectif)
            f : int = g_nouveau + h

            enfant : Node = Node(state=etat_enfant, move=coup, cost=g_nouveau, heuristic=h, parent=noeud_courant)
            compteur += 1
            heapq.heappush(file_prio, (f, compteur, enfant))
            meilleur_g[cle] = g_nouveau # On met à jour le meilleur coût pour cet état

    return []

def heuristic(current_state : State, goal_state : State) -> int:
    '''Calculate the Manhattan distance of the puzzle'''
    # On veut faire la somme des distances de Manhattan de chaque brique sauf 0.

    distance = int(math.sqrt(len(current_state)))

    # position_cibles de chaque tuile : {valeur: (ligne, colonne)}
    position_cibles : dict[int, tuple[int, int]] = {}

    for index, value in enumerate(goal_state):
        position_cibles[value] = (index // distance, index % distance)

    distance_manhattan : int = 0
    for index, value in enumerate(current_state):
        if value == 0:
            continue # On ignore la brique 0
        ligne, colonne= index // distance, index % distance
        ligne_cible, colonne_cible = position_cibles[value]
        distance_manhattan += abs(ligne - ligne_cible) + abs(colonne - colonne_cible)

    return distance_manhattan

def depth_limited_search(node: Node, limit: int, goal_state: State, moves: List[Move], dimension: int) -> Solution | None:
    '''Perform a depth-limited search'''
    
    # Todo: implement depth-limited search
    pass

def solve_iddfs(root: Node, max_depth: int) -> Solution:
    '''Solve the puzzle using the Iterative Deepening Depth-First Search algorithm'''
    
    # Todo: implement IDDFS algorithm
    pass

def main():
    parser = argparse.ArgumentParser(description='Load an n-puzzle and solve it.')
    parser.add_argument('filename', type=str, help='File name of the puzzle')
    parser.add_argument('-a', '--algo', type=str, choices=['bfs', 'dfs', 'astar', 'iddfs'], required=True, help='Algorithm to solve the puzzle')
    parser.add_argument('-v', '--verbose', action='store_true', help='Increase output verbosity')
    parser.add_argument('-d', '--max_depth', type=int, default=100, help='Maximum depth for IDDFS')
    
    args = parser.parse_args()
    
    puzzle = load_puzzle(args.filename)
    
    if args.verbose:
        print('Puzzle:\n')
        print(to_string(puzzle))
    
    if not is_goal(puzzle, create_goal(int(math.sqrt(len(puzzle))))):   
         
        root = Node(state = puzzle, move = None)
        open = [root]
        
        if args.algo == BFS:
            print('BFS\n')
            start_time = time.time()
            solution = solve_bfs(open)
            duration = time.time() - start_time
            if solution:
                print('Solution:', solution)
                print('Valid solution:', is_solution(puzzle, solution))
                print('Duration:', duration)
            else:
                print('No solution')
        elif args.algo == DFS:
            print('DFS\n')
            start_time = time.time()
            solution = solve_dfs(open)
            duration = time.time() - start_time
            if solution:
                print('Solution:', solution)
                print('Valid solution:', is_solution(puzzle, solution))
                print('Duration:', duration)
            else:
                print('No solution')
        elif args.algo == ASTAR:
            print('A*')
            start_time = time.time()
            solution = solve_astar(open)
            duration = time.time() - start_time
            if solution:
                print('Solution:', solution)
                print('Valid solution:', is_solution(puzzle, solution))
                print('Duration:', duration)
        elif args.algo == IDDFS:
            print('IDDFS')
            start_time = time.time()
            solution = solve_iddfs(root, args.max_depth)
            duration = time.time() - start_time
            if solution:
                print('Solution:', solution)
                print('Valid solution:', is_solution(puzzle, solution))
                print('Duration:', duration)        
            else:
                print('No solution')
    else:
        print('Puzzle is already solved')
    
if __name__ == '__main__':
    main()