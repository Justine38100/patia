; problem.pddl
; Niveau simple Sokoban (ligne de 4 cases).

(define (problem sokoban_4_cases_lineaires)
  (:domain sokoban)

  (:objects
    ; Cases jouables (pas de murs dans objects).
    c1 c2 c3 c4 - cell
    ; Une caisse.
    b1 - box
  )

  (:init
    ; Voisinages est/ouest.
    (east c1 c2)
    (east c2 c3)
    (east c3 c4)

    (west c4 c3)
    (west c3 c2)
    (west c2 c1)

    ; Position initiale du joueur.
    (at-player c1)

    ; Position initiale de la caisse.
    (at-box b1 c2)

    ; Cible.
    (goal c4)

    ; Cases libres initiales.
    (clear c3)
    (clear c4)
  )

  (:goal (and
    ; La caisse b1 doit etre sur la cible c4.
    (at-box b1 c4)
  ))
)
