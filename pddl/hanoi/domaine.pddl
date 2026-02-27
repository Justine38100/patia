(define (domain hanoi_3_3)

(:predicates
    (at piquet1 grand moyen petit)
    (connected piquet1 piquet2)
    (connected piquet1 piquet3)
    (connected piquet2 piquet1)
    (connected piquet2 piquet3)
    (connected piquet3 piquet1)
    (connected piquet3 piquet2)
)

(:action move
    :parameters (piquet1 piquet2 piquet3 grand moyen petit)
    :precondition (and
        (at piquet1 grand moyen petit)
    )
)
)