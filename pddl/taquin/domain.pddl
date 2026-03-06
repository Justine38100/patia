; domain.pddl
(define (domain taquin)
  (:requirements :strips :typing)

  ; une brique = une tuile numerotee
  (:types
    brique position
  )

  (:predicates
    ; Le brique ?b est sur la case ?p
    (at ?b - brique ?p - position)

    ; La case ?p est vide
    (blank ?p - position)

    ; Les deux cases sont voisines (haut/bas/gauche/droite)
    (adjacent ?p1 - position ?p2 - position)
  )

  (:action slide
    :parameters (?b - brique ?from - position ?to - position)
    :precondition (and

      ; La brique a deplacer doit etre sur le support d'origine.
      (at ?b ?from)

      ; La case de destination doit etre la case qui a le blanc (le "0").
      (blank ?to)

      ; La case de depart doit etre adjacente a la case d'arrivee.
      (adjacent ?from ?to)
    )
    :effect (and

      ; si l'action est executee : la brique n'est plus sur sa case d'origine.
      (not (at ?b ?from))

      ; si l'action est executee : la brique est sur la case d'arrivee.
      (at ?b ?to)

      ; si l'action est executee : le blanc est sur la case de depart (a interverti sa place avec la brique).
      (blank ?from)

      ; si l'action est execute : le blanc n'est plus sur la case d'arrivee (il est sur to).
      (not (blank ?to))
    )
  )
)
