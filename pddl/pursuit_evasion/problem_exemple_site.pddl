; problem.pddl
; Exemple concret pour le domaine pursuit_evasion.

; Debut de la definition du probleme.
(define (problem pursuit_4_noeuds_pb_site_exemple)

  (:domain pursuit_evasion)

  (:objects
    ; Quatre noeuds du graphe.
    n1 n2 n3 n4 n5 n6 - node

    ; Deux poursuivants disponibles.
    s1 s2 - searcher
  )

  ; Etat initial.
  (:init
    (edge n1 n2)
    (edge n2 n1)

    (edge n2 n3)
    (edge n3 n2)

    (edge n2 n4)
    (edge n4 n2)

    (edge n4 n5)
    (edge n5 n4)

    (edge n5 n6)
    (edge n6 n5)

    (edge n6 n2)
    (edge n2 n6)

    ; Le poursuivant s1 commence sur n1.
    (at s1 n1)
    ; Le poursuivant s2 commence sur n4.
    (at s2 n1)

    ; Le noeud n1 est occupe.
    (occupied n1)

    ; Zone initialement contammee.
    (contaminated n2)
    (contaminated n3)
    (contaminated n4)
    (contaminated n5)
    (contaminated n6)


    ; Le premier tour est celui des poursuivants.
    (searcher-turn)
  )

  ; But a atteindre.
  (:goal (and
    (not (contaminated n1))
    (not (contaminated n2))
    (not (contaminated n3))
    (not (contaminated n4))
    (not (contaminated n5))
    (not (contaminated n6))
  ))
)
