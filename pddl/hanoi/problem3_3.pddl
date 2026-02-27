; problem.pddl
(define (problem hanoi_3_3)
  (:domain hanoi)

  (:objects
  ; Déclaration des objets qui existent dans le domain

    ; Trois disques
    grand moyen petit - disque
    ; Ces objets sont de type "disque"

    ; Trois piquets
    piquet1 piquet2 piquet3 - pique
    ; Ces objets sont de type "pique"
  )

  (:init
  ; On initialise tous ce qui est VRAI!

    ; Où se trouve les disques au départ?
    ; Le petit disque est sur le moyen
    ; Le moyen disque est sur le grand
    ; Le grand disque est sur le piquet1
    (on grand piquet1)
    (on moyen grand)
    (on petit moyen)

    ; On sait qu'il n'y a rien sur le petit disque
    ; On sait que le piquet 2 n'a rien dessus (tout est sur le piquet 1)
    ; On sait que le piquet 3 n'a rien dessus (tout est sur le piquet 1)
    (clear petit)
    (clear piquet2)
    (clear piquet3)

    ; Comment je connait la taille des éléments de mon espace ? Qui peut aller sur qui?
    ; Le petit disque a le droit d'aller sur le moyen
    (smaller petit moyen)

    ; Le petit disque a le droit d'aller sur le grand
    (smaller petit grand)

    ; Le petit disque a le droit d'aller sur le grand
    (smaller moyen grand)

    ; Le petit disque a le droit d'aller sur les piquets
    (smaller petit piquet1)
    (smaller petit piquet2)
    (smaller petit piquet3)

    ; Le moyen disque a le droit d'aller sur les piquets
    (smaller moyen piquet1)
    (smaller moyen piquet2)
    (smaller moyen piquet3)

    ; Le grand disque a le droit d'aller sur les piquets
    (smaller grand piquet1)
    (smaller grand piquet2)
    (smaller grand piquet3)
  )

  (:goal (and
  ; On veut reconstruire la pile complète
  ; sur piquet3.
  ; Cette olution se traduit par : 
  ;  - le grand disque doit être sur le piquet3
  ;  - le moyen disque doit être sur le dique2
  ;  - le petit disque doit être sur le disque1
    (on grand piquet3)
    (on moyen grand)
    (on petit moyen)
  ))
)
