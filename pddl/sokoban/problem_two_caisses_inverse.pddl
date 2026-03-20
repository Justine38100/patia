; problem.pddl

;    ####
; ####. #
; #     #
; #  $ .#
; # # $ #
; #@    #
; #######

;c21 c22 c23 c24 c25
;c16 c17 c18 c19 c20
;c11 c12 c13 c14 c15
;c6  c7  c8  c9  c10
;c1  c2  c3  c4  c5

(define (problem sokoban-difficil)
  (:domain sokoban)

  (:objects
    ; Playable cells
    c1 c2 c3 c4 c5 c6 c8 c9 c10 c11 c12 c13 c14 c15 c16 c17 c18 c19 c20 c21 c22 c23 c24 c25 - cell
    ; Boxes
    b1 b2 - box
  )

  (:init
    ; Directional adjacencies (north = +5, south = -5)
    (north c1 c6)
    (north c3 c8)
    (north c4 c9)
    (north c5 c10)
    (north c6 c11)
    (north c8 c13)
    (north c9 c14)
    (north c10 c15)
    (north c11 c16)
    (north c12 c17)
    (north c13 c18)
    (north c14 c19)
    (north c15 c20)
    (north c16 c21)
    (north c17 c22)
    (north c18 c23)
    (north c19 c24)
    (north c20 c25)

    (south c6 c1)
    (south c8 c3)
    (south c9 c4)
    (south c10 c5)
    (south c11 c6)
    (south c13 c8)
    (south c14 c9)
    (south c15 c10)
    (south c16 c11)
    (south c17 c12)
    (south c18 c13)
    (south c19 c14)
    (south c20 c15)
    (south c21 c16)
    (south c22 c17)
    (south c23 c18)
    (south c24 c19)
    (south c25 c20)

    (east c1 c2)
    (east c2 c3)
    (east c3 c4)
    (east c4 c5)
    (east c8 c9)
    (east c9 c10)
    (east c11 c12)
    (east c12 c13)
    (east c13 c14)
    (east c14 c15)
    (east c16 c17)
    (east c17 c18)
    (east c18 c19)
    (east c19 c20)
    (east c21 c22)
    (east c22 c23)
    (east c23 c24)
    (east c24 c25)
    
    (west c2 c1)
    (west c3 c2)
    (west c4 c3)
    (west c5 c4)
    (west c9 c8)
    (west c10 c9)
    (west c12 c11)
    (west c13 c12)
    (west c14 c13)
    (west c15 c14)
    (west c17 c16)
    (west c18 c17)
    (west c19 c18)
    (west c20 c19)
    (west c22 c21)
    (west c23 c22)
    (west c24 c23)
    (west c25 c24)

    ; Player initial position
    (at-player c1)

    ; Box initial positions
    (at-box b1 c9)
    (at-box b2 c13)

    ; Goal cells
    (goal c24)
    (goal c15)

    ; Initially clear cells
    (clear c2)
    (clear c3)
    (clear c4)
    (clear c5)
    (clear c6)
    (clear c8)
    (clear c10)
    (clear c11)
    (clear c12)
    (clear c14)
    (clear c15)
    (clear c16)
    (clear c17)
    (clear c18)
    (clear c19)
    (clear c20)
    (clear c24)
    (clear c25)
  )

  (:goal (and
    (at-box b2 c24)
    (at-box b1 c15)
  ))
)
