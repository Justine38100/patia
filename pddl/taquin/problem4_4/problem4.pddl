; problem4_4.pddl
(define (problem taquin_4_4)
  (:domain taquin)

  (:objects
    b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15 - brique
    c11 c12 c13 c14 c21 c22 c23 c24 c31 c32 c33 c34 c41 c42 c43 c44 - position

    ;        colonnes:   1     2     3     4
    ;   lignes :     1   c11   c12   c13   c14
    ;                2   c21   c22   c23   c24
    ;                3   c31   c32   c33   c34
    ;                4   c41   c42   c43   c44

    ; Etat final :
    ;        colonnes:   1     2     3     4
    ;   lignes :     1   b1    b2    b3    b4 
    ;                2   b5    b6    b7    b8
    ;                3   b9    b10   b11   b12
    ;                4   b13   b14   b15   0
  )
  (:init

    ; Etat final :
    ;        colonnes:   1     2     3     4
    ;   lignes :     1   b10   b8    b12   b7 
    ;                2   b13   b15   b5    b11
    ;                3   b1    b6    b4    b14
    ;                4   b9    b2    b3    0
    (at b1 c11)
    (at b2 c12)
    (at b3 c13)
    (at b4 c14)
    (at b5 c21)
    (at b10 c22)
    (at b6 c23)
    (blank c24)
    (at b9 c31)
    (at b7 c32)
    (at b15 c33)
    (at b8 c34)
    (at b13 c41)
    (at b14 c42)
    (at b12 c43)
    (at b11 c44)

    ; Adjacences horizontales
    (adjacent c11 c12) (adjacent c12 c11)
    (adjacent c12 c13) (adjacent c13 c12)
    (adjacent c13 c14) (adjacent c14 c13)
    (adjacent c21 c22) (adjacent c22 c21)
    (adjacent c22 c23) (adjacent c23 c22)
    (adjacent c23 c24) (adjacent c24 c23)
    (adjacent c31 c32) (adjacent c32 c31)
    (adjacent c32 c33) (adjacent c33 c32)
    (adjacent c33 c34) (adjacent c34 c33)
    (adjacent c41 c42) (adjacent c42 c41)
    (adjacent c42 c43) (adjacent c43 c42)
    (adjacent c43 c44) (adjacent c44 c43)

    ; Adjacences verticales
    (adjacent c11 c21) (adjacent c21 c11)
    (adjacent c21 c31) (adjacent c31 c21)
    (adjacent c31 c41) (adjacent c41 c31)
    (adjacent c12 c22) (adjacent c22 c12)
    (adjacent c22 c32) (adjacent c32 c22)
    (adjacent c32 c42) (adjacent c42 c32)
    (adjacent c13 c23) (adjacent c23 c13)
    (adjacent c23 c33) (adjacent c33 c23)
    (adjacent c33 c43) (adjacent c43 c33)
    (adjacent c14 c24) (adjacent c24 c14)
    (adjacent c24 c34) (adjacent c34 c24)
    (adjacent c34 c44) (adjacent c44 c34)
  )

  (:goal (and
    (at b1 c11)
    (at b2 c12)
    (at b3 c13)
    (at b4 c14)
    (at b5 c21)
    (at b6 c22)
    (at b7 c23)
    (at b8 c24)
    (at b9 c31)
    (at b10 c32)
    (at b11 c33)
    (at b12 c34)
    (at b13 c41)
    (at b14 c42)
    (at b15 c43)
    (blank c44)
  ))
)
