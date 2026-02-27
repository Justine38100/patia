; domain.pddl
(define (domain hanoi)
  (:requirements :strips :typing)


  ; un disque peut-être sûr un disque
  ; un disque peut-être sûr un pique 
  ; L'endroit où peut-être un disque s'appelle une place

  (:types
    place - object    disque pique - place
  )


  (:predicates

    ; Un dique peut-être posé sur une place (=pique ou autre disque que lui)
    ; Un disque ? peut-être posé sur une place ?
    ; Cette phrase se traduit par : on ?d ?p
    ; On veut préciser que d est un disque et que p est une place
    ; car dans l'absolu p peut-être un autre disque ou un pique (=place)
    (on ?d - disque ?p - place)

    ; Une place peut-être vide (= rien sur un disque ou rien sur un pique)
    (clear ?p - place)

    ; On ne veut pas pouvoir poser un disque de taille x sur un disque de taille y si y<x !
    ; on va définir ce prédicat dans "problem"
    ; penser à dire que les disques sont forcément plus petits que les piques!!
    (smaller ?d - disque ?p - place)
  )

  (:action move
    ; ?d -> disque a déplacer
    ; ?from -> place d'origine
    ; ?to -> place d'arrivée
    :parameters (?d - disque ?from - place ?to - place)

    :precondition (and

      ; Le disque doit être sur le support d'origine
      (on ?d ?from)

      ; Le disque doit être libre (rien dessus)
      (clear ?d)

      ; La destination doit être libre
      (clear ?to)

      ; Le disque doit être plus petit que le pique ou le disque d'arrivée
      (smaller ?d ?to)
    )
    :effect (and

      ; si l'action est exécutée : le disque n'est plus sur la place d'origine.
      (not (on ?d ?from))

      ; si l'action est exécutée : le disque se trouve sur la place de destination
      (on ?d ?to)

      ; si l'action est exécutée : la place de départ est vide (il n'y a plus le disque ?)
      (clear ?from)

      ; si l'action est exécutée : la place de destination n'est plus vide comme elle contient le disque ?
      (not (clear ?to))
    )
  )
)
