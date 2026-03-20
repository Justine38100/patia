; domain.pddl

(define (domain sokoban)

  (:requirements :strips :typing)

  (:types
    ; cell = case libre du niveau, box = caisse.
    cell box
  )

  (:predicates
    ; Position du joueur.
    (at-player ?c - cell)

    ; Position d'une caisse.
    (at-box ?b - box ?c - cell)

    ; Case libre (sans joueur, sans caisse).
    (clear ?c - cell)

    ; Relations de voisinage directionnelles.
    (north ?from - cell ?to - cell)
    (south ?from - cell ?to - cell)
    (east  ?from - cell ?to - cell)
    (west  ?from - cell ?to - cell)

    ; Case cible (utilisee par les problemes).
    (goal ?c - cell)
  )

  ; -----------------------
  ; Mouvements du joueur
  ; -----------------------

  (:action move-north
    :parameters (?from - cell ?to - cell)
    :precondition (and
      (at-player ?from)
      (north ?from ?to)
      (clear ?to)
    )
    :effect (and
      (not (at-player ?from))
      (at-player ?to)
      (clear ?from)
      (not (clear ?to))
    )
  )

  (:action move-south
    :parameters (?from - cell ?to - cell)
    :precondition (and
      (at-player ?from)
      (south ?from ?to)
      (clear ?to)
    )
    :effect (and
      (not (at-player ?from))
      (at-player ?to)
      (clear ?from)
      (not (clear ?to))
    )
  )

  (:action move-east
    :parameters (?from - cell ?to - cell)
    :precondition (and
      (at-player ?from)
      (east ?from ?to)
      (clear ?to)
    )
    :effect (and
      (not (at-player ?from))
      (at-player ?to)
      (clear ?from)
      (not (clear ?to))
    )
  )

  (:action move-west
    :parameters (?from - cell ?to - cell)
    :precondition (and
      (at-player ?from)
      (west ?from ?to)
      (clear ?to)
    )
    :effect (and
      (not (at-player ?from))
      (at-player ?to)
      (clear ?from)
      (not (clear ?to))
    )
  )

  ; -----------------------
  ; Poussees de caisses
  ; -----------------------

  ; Le joueur est au sud de la caisse et pousse vers le nord.
  (:action push-north
    :parameters (?b - box ?player-from - cell ?box-from - cell ?box-to - cell)
    :precondition (and
      (at-player ?player-from)
      (at-box ?b ?box-from)
      (north ?player-from ?box-from)
      (north ?box-from ?box-to)
      (clear ?box-to)
    )
    :effect (and
      (not (at-player ?player-from))
      (at-player ?box-from)
      (not (at-box ?b ?box-from))
      (at-box ?b ?box-to)
      (clear ?player-from)
      (not (clear ?box-from))
      (not (clear ?box-to))
    )
  )

  ; Le joueur est au nord de la caisse et pousse vers le sud.
  (:action push-south
    :parameters (?b - box ?player-from - cell ?box-from - cell ?box-to - cell)
    :precondition (and
      (at-player ?player-from)
      (at-box ?b ?box-from)
      (south ?player-from ?box-from)
      (south ?box-from ?box-to)
      (clear ?box-to)
    )
    :effect (and
      (not (at-player ?player-from))
      (at-player ?box-from)
      (not (at-box ?b ?box-from))
      (at-box ?b ?box-to)
      (clear ?player-from)
      (not (clear ?box-from))
      (not (clear ?box-to))
    )
  )

  ; Le joueur est a l'ouest de la caisse et pousse vers l'est.
  (:action push-east
    :parameters (?b - box ?player-from - cell ?box-from - cell ?box-to - cell)
    :precondition (and
      (at-player ?player-from)
      (at-box ?b ?box-from)
      (east ?player-from ?box-from)
      (east ?box-from ?box-to)
      (clear ?box-to)
    )
    :effect (and
      (not (at-player ?player-from))
      (at-player ?box-from)
      (not (at-box ?b ?box-from))
      (at-box ?b ?box-to)
      (clear ?player-from)
      (not (clear ?box-from))
      (not (clear ?box-to))
    )
  )

  ; Le joueur est a l'est de la caisse et pousse vers l'ouest.
  (:action push-west
    :parameters (?b - box ?player-from - cell ?box-from - cell ?box-to - cell)
    :precondition (and
      (at-player ?player-from)
      (at-box ?b ?box-from)
      (west ?player-from ?box-from)
      (west ?box-from ?box-to)
      (clear ?box-to)
    )
    :effect (and
      (not (at-player ?player-from))
      (at-player ?box-from)
      (not (at-box ?b ?box-from))
      (at-box ?b ?box-to)
      (clear ?player-from)
      (not (clear ?box-from))
      (not (clear ?box-to))
    )
  )
)
