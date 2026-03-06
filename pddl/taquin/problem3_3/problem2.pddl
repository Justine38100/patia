; problem3_3.pddl
(define (problem taquin_3_3)
  (:domain taquin)

  (:objects
    b1 b2 b3 b4 b5 b6 b7 b8 - brique
    c11 c12 c13 c21 c22 c23 c31 c32 c33 - position
    
    ;        colonnes:   1     2     3
    ;   lignes :     1   c11   c12   c13
    ;                2   c21   c22   c23
    ;                3   c31   c32   c33

    ; Etat final :
    ;        colonnes:   1     2     3
    ;   lignes :     1   b1    b2    b3 
    ;                2   b4    b5    b6
    ;                3   b7    b8    0
  )

  (:init
    ; Etat initial (a 1 coup de la solution)
    ;        colonnes:   1     2     3
    ;   lignes :     1   b4    b2    b3 
    ;                2   b6    b5    b8
    ;                3   b1    b7    0
    (at b4 c11)
    (at b2 c12)
    (at b3 c13)
    (at b6 c21)
    (at b5 c22)
    (at b8 c23)
    (at b1 c31)
    (at b7 c32)
    (blank c33)

    ; Toujours le même pour des taquin_3_3 !!
    ; Adjacences horizontales
    (adjacent c11 c12) (adjacent c12 c11)
    (adjacent c12 c13) (adjacent c13 c12)
    (adjacent c21 c22) (adjacent c22 c21)
    (adjacent c22 c23) (adjacent c23 c22)
    (adjacent c31 c32) (adjacent c32 c31)
    (adjacent c32 c33) (adjacent c33 c32)

    ; Adjacences verticales
    (adjacent c11 c21) (adjacent c21 c11)
    (adjacent c21 c31) (adjacent c31 c21)
    (adjacent c12 c22) (adjacent c22 c12)
    (adjacent c22 c32) (adjacent c32 c22)
    (adjacent c13 c23) (adjacent c23 c13)
    (adjacent c23 c33) (adjacent c33 c23)
  )

  ; Toujours le même pour des taquin_3_3 !!
  (:goal (and
    (at b1 c11)
    (at b2 c12)
    (at b3 c13)
    (at b4 c21)
    (at b5 c22)
    (at b6 c23)
    (at b7 c31)
    (at b8 c32)
    (blank c33)
  ))
)
