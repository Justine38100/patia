; domain.pddl
; ------------------------------------------------------------
; Modele de poursuite-evasion sur graphe avec incertitude.
; ------------------------------------------------------------
; Ce domaine ne suit pas la position exacte de chaque intrus.
; Il suit une "zone possible" via le predicat contaminated.
;
; contaminated(n) signifie:
;   "un intrus peut etre au noeud n"
;
; Objectif de planification:
;   rendre tous les noeuds non contamines, malgre les deplacements
;   possibles des intrus entre les tours des poursuivants.
;
; Les positions initiales des poursuivants sont definies dans le
; fichier problem.pddl.

(define (domain pursuit_evasion)
  (:requirements :adl :typing)

  (:types
    ; node     : noeuds du graphe
    ; searcher : poursuivants
    node searcher
  )

  (:predicates
    ; edge(a,b): arc oriente de a vers b.
    ; Pour un graphe non oriente, mettre edge(a,b) et edge(b,a).
    (edge ?a - node ?b - node)

    ; on(s,n): le poursuivant s est sur le noeud n.
    (at ?s - searcher ?n - node)

    ; occupied(n): le noeud n est occupe par un poursuivant.
    ; En pratique, occupied doit etre coherent avec at.
    (occupied ?n - node)

    ; contaminated(n): un intrus peut etre sur n.
    (contaminated ?n - node)

    ; Controle de tour pour alterner poursuivants / intrus.
    (searcher-turn)
    (intruder-turn)
  )

  ; ----------------------------------------------------------
  ; Action: move-searcher
  ; ----------------------------------------------------------
  ; Deplace un poursuivant d'un noeud source vers un noeud voisin,
  ; seulement pendant le tour des poursuivants.
  ;
  ; Contraintes:
  ; - le poursuivant doit etre present sur la source
  ; - la source et la destination doivent etre reliees par edge
  ; - la destination doit etre non occupee
  ;
  ; Effets:
  ; - mise a jour position (at)
  ; - mise a jour occupation (occupied)
  ; - nettoyage de la destination (si contaminee)
  ; - passage au tour des intrus
  (:action move-searcher
    ; Action: deplacer un poursuivant d'un noeud source vers un noeud voisin.
    :parameters (?s - searcher ?from - node ?to - node)

    :precondition (and
      (searcher-turn)         ; c'est le tour des poursuivants
      (at ?s ?from)           ; le poursuivant ?s est actuellement sur ?from
      (edge ?from ?to)        ; il existe un arc de ?from vers ?to
      (not (occupied ?to))    ; la destination ?to est libre
    )

    :effect (and
      (not (at ?s ?from))     ; ?s n'est plus sur la source
      (at ?s ?to)             ; ?s est maintenant sur la destination
      (not (occupied ?from))  ; la source devient libre
      (occupied ?to)          ; la destination devient occupee
      (not (contaminated ?to)); le noeud occupe est nettoye
      (not (searcher-turn))   ; fin du tour des poursuivants
      (intruder-turn)         ; debut du tour des intrus
    )
  )


  ; ----------------------------------------------------------
  ; Action: intruder-spread
  ; ----------------------------------------------------------
  ; Tour "adversaire".
  ; Les intrus peuvent se propager depuis chaque noeud contamine
  ; vers tout voisin non occupe.
  ;
  ; Ensuite, on applique la capture:
  ; tout noeud occupe est force non contamine.
  ;
  ; Intuition:
  ; - propagation = pire cas de deplacement intrus
  ; - nettoyage des noeuds occupes = capture locale
  ;
  ; Puis on rend la main aux poursuivants.
  (:action intruder-spread
    ; Action "adversaire": propagation possible des intrus.
    ; Elle modele le pire cas entre deux actions de poursuivant.
    :parameters ()

    :precondition (intruder-turn) ; cette action n'est possible qu'au tour des intrus

    :effect (and
      ; Regle de propagation:
      ; si un noeud ?a est contamine et qu'il existe un arc ?a -> ?b,
      ; alors ?b devient contamine, sauf si ?b est occupe par un poursuivant.
      (forall (?a - node ?b - node)
        (when (and (contaminated ?a) (edge ?a ?b) (not (occupied ?b)))
          (contaminated ?b)
        )
      )

      ; Regle de nettoyage/capture:
      ; tout noeud occupe par un poursuivant est force non contamine.
      (forall (?n - node)
        (when (occupied ?n)
          (not (contaminated ?n))
        )
      )

      ; Changement de tour: on rend la main aux poursuivants.
      (not (intruder-turn))
      (searcher-turn)
    )
  )
)
