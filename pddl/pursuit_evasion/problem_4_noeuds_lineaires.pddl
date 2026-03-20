; problem.pddl
(define (problem pursuit_4_noeuds_lineaires)

  ; Le probleme utilise le domaine pursuit_evasion.
  (:domain pursuit_evasion)

  ; Objets de cette instance.
  (:objects
    ; Quatre noeuds du graphe.
    n1 n2 n3 n4 - node

    ; Deux poursuivants disponibles.
    s1 s2 - searcher
  )

  ; Etat initial.
  (:init
    (edge n1 n2)
    (edge n2 n1)

    (edge n2 n3)
    (edge n3 n2)

    (edge n3 n4)
    (edge n4 n3)

    ; Le poursuivant s1 commence sur n1.
    (at s1 n1)
    ; Le poursuivant s2 commence sur n4.
    (at s2 n4)

    (occupied n1)
    (occupied n4)

    ; Zone initialement contammee.
    (contaminated n2)
    (contaminated n3)

    ; Le premier tour est celui des poursuivants.
    (searcher-turn)
  )

  ; But a atteindre.
  (:goal (and
    (not (contaminated n1))
    (not (contaminated n2))
    (not (contaminated n3))
    (not (contaminated n4))
  ))
)
