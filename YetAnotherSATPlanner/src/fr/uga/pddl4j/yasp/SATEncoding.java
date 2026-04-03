package fr.uga.pddl4j.yasp;

import fr.uga.pddl4j.plan.Plan;
import fr.uga.pddl4j.plan.SequentialPlan;
import fr.uga.pddl4j.problem.Fluent;
import fr.uga.pddl4j.problem.Problem;
import fr.uga.pddl4j.problem.operator.Action;
import fr.uga.pddl4j.problem.operator.Condition;
import fr.uga.pddl4j.problem.operator.Effect;
import fr.uga.pddl4j.util.BitVector;

import java.util.List;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;

/**
 * This class implements a planning problem/domain encoding into DIMACS
 *
 * @author H. Fiorino
 * @version 0.1 - 30.03.2024
 */
public final class SATEncoding {
    /*
     * A SAT problem in dimacs format is a list of int list a.k.a clauses
     */
    private List<List<Integer>> initList = new ArrayList<List<Integer>>();

    /*
     * Goal
     */
    private List<Integer> goalList = new ArrayList<Integer>();

    /*
     * Actions
     */
    private List<List<Integer>> actionPreconditionList = new ArrayList<List<Integer>>();
    private List<List<Integer>> actionEffectList = new ArrayList<List<Integer>>();

    /*
     * State transitions
     */
    private HashMap<Integer, List<Integer>> addList = new HashMap<Integer, List<Integer>>();
    private HashMap<Integer, List<Integer>> delList = new HashMap<Integer, List<Integer>>();
    /*
     * Action disjunctions
     */
    private List<List<Integer>> actionDisjunctionList = new ArrayList<List<Integer>>();

    /*
     * Current DIMACS encoding of the planning problem for #steps steps.
     * Contient les axiomes d'initialisation, d'action, de mutex et de cadre.
     * L'objectif est stocké séparément dans currentGoal.
     */
    public List<List<Integer>> currentDimacs = new ArrayList<List<Integer>>();

    /*
     * Current goal encoding
     */
    public List<Integer> currentGoal = new ArrayList<Integer>();

    /*
     * Current number of steps of the SAT encoding
     */
    private int steps;

    /*
     * Nombre de fluents et d'actions du problème instancié.
     * Utilisé pour maintenir une indexation stable des variables SAT lors des appels à encode().
     */
    private int nbFluents;
    private int nbActions;

    public SATEncoding(Problem problem, int steps) {

        this.steps = steps;

        // Encoding of init
        // Each fact is a unit clause
        // Init state step is 1
        // We get the initial state from the planning problem
        // State is a bit vector where the ith bit at 1 corresponds to the ith fluent being true
        final BitVector init = problem.getInitialState().getPositiveFluents();

        // Fluents = booléan
        // On récupère le nombre de fluents et d'actions du problème pour faire le mapping vers les variables SAT
        // F = nombre de fluents -> variables SAT de 1 à F
        this.nbFluents = problem.getFluents().size();
        int F = this.nbFluents;

        // A = nombre d'actions -> variables SAT de F+1 à F+A
        this.nbActions = problem.getActions().size();
        int A = this.nbActions;

        // =======================
        // A) Encodage de l'état initial au pas 1
        // =======================
        // Convention : fluent i -> variable SAT (i+1)
        // On encode aussi les fluents faux pour avoir un état initial complet.

        // Pour chaque fluent, on ajoute une clause unitaire qui dit soit fluent vrai, soit fluent faux
        for (int f = 0; f < F; f++) {

            // fVar est la variable SAT correspondant au fluent f
            int fVar = f + 1;
            List<Integer> unit = new ArrayList<>();

            if (init.get(f)) {
                // Si le fluent est à 1 dans l'état initial, on ajoute la clause (fVar) qui dit que le fluent est vrai
                unit.add(pair(fVar, 1));
            } else {
                // Sinon on ajoute la clause (-fVar) qui dit que le fluent est faux
                unit.add(-pair(fVar, 1));
            }
            // Dans tous les cas, on ajoute la clause unitaire à la liste des clauses d'init
            initList.add(unit);
        }

        // =======================
        // B) Template du but (sans temps pour l’instant)
        // =======================

        // On récupère le but du problème de planification
        Condition g = problem.getGoal();

        // gPos : bit i = 1 => le fluent d'index i doit etre vrai dans le but.
        BitVector gPos = g.getPositiveFluents();

        // gNeg : bit i = 1 => le fluent d'index i doit etre faux dans le but.
        BitVector gNeg = g.getNegativeFluents();

        // On parcourt gPos et on ajoute les clauses unitaires correspondantes à la liste du but
        for (int f = gPos.nextSetBit(0); f >= 0; f = gPos.nextSetBit(f + 1)) {
            goalList.add(f + 1);      // +f
        }

        // On parcourt gNeg et on ajoute les clauses unitaires correspondantes à la liste du but
        for (int f = gNeg.nextSetBit(0); f >= 0; f = gNeg.nextSetBit(f + 1)) {
            goalList.add(-(f + 1));   // -f
        }

        // =======================
        // C) Templates préconditions/effets des actions
        // =======================
        // On parcourt les actions du problème de planification et on encode les préconditions et les effets inconditionnels
        // C'est à dire que pour chaque action a, on ajoute les clauses suivantes :
        // - Préconditions positives : (¬a_t v p_t)
        // - Préconditions négatives : (¬a_t v ¬p_t)
        // - Effets positifs : (¬a_t v p_t+1)
        // - Effets négatifs : (¬a_t v ¬p_t+1)

        for (int a = 0; a < A; a++) {
            // On récupère l'action d'index a dans la liste des actions du problème de planification
            Action act = problem.getActions().get(a);

            // On calcule la variable SAT correspondant à l'action a : aVar = F + a + 1
            int aVar = F + a + 1; 

            // Préconditions positives : (¬a_t v p_t)
            // pPos : bit i = 1 => le fluent d'index i doit etre vrai pour que l'action soit applicable.
            BitVector pPos = act.getPrecondition().getPositiveFluents();

            // On parcourt pPos et on ajoute les clauses correspondantes à la liste des préconditions d'actions
            for (int f = pPos.nextSetBit(0); f >= 0; f = pPos.nextSetBit(f + 1)) {
                actionPreconditionList.add(Arrays.asList(-aVar, f + 1));
            }

            // Préconditions négatives : (¬a_t v ¬p_t)
            // pNeg : bit i = 1 => le fluent d'index i doit etre faux pour que l'action soit applicable.
            BitVector pNeg = act.getPrecondition().getNegativeFluents();

            // On parcourt pNeg et on ajoute les clauses correspondantes à la liste des préconditions d'actions
            for (int f = pNeg.nextSetBit(0); f >= 0; f = pNeg.nextSetBit(f + 1)) {
                actionPreconditionList.add(Arrays.asList(-aVar, -(f + 1)));
            }

            // Effets inconditionnels
            // On récupère les effets inconditionnels de l'action a.
            Effect eff = act.getUnconditionalEffect();

            // Add effects : (¬a_t v p_t+1)
            // ePos : bit i = 1 => le fluent d'index i est ajouté par l'action.
            BitVector ePos = eff.getPositiveFluents();

            // On parcourt ePos et on ajoute les clauses correspondantes à la liste des effets d'actions
            for (int f = ePos.nextSetBit(0); f >= 0; f = ePos.nextSetBit(f + 1)) {
                actionEffectList.add(Arrays.asList(-aVar, f + 1));
                // On ajoute aussi l'action a à la liste des actions qui ajoutent le fluent f (pour les frame axioms)
                addList.computeIfAbsent(f + 1, k -> new ArrayList<>()).add(aVar);
            }

            // Delete effects : (¬a_t v ¬p_t+1)
            // eNeg : bit i = 1 => le fluent d'index i est supprimé par l'action.
            BitVector eNeg = eff.getNegativeFluents();
            // On parcourt eNeg et on ajoute les clauses correspondantes à la liste des effets d'actions
            for (int f = eNeg.nextSetBit(0); f >= 0; f = eNeg.nextSetBit(f + 1)) {
                actionEffectList.add(Arrays.asList(-aVar, -(f + 1)));
                // On ajoute aussi l'action a à la liste des actions qui suppriment le fluent f (pour les frame axioms)
                delList.computeIfAbsent(f + 1, k -> new ArrayList<>()).add(aVar);
            }
        }

        // =======================
        // D) Mutex d’actions (plan séquentiel)
        // =======================
        // "au plus une action par pas" : (¬a_t v ¬b_t)
        // On parcourt toutes les paires d'actions et on ajoute les clauses correspondantes à la liste des disjonctions d'actions
        for (int a1 = 0; a1 < A; a1++) {
            // On calcule la variable SAT correspondant à l'action a1 : v1 = F + a1 + 1
            int v1 = F + a1 + 1;
            // On parcourt les actions suivantes a2 > a1 pour éviter les doublons et on ajoute les clauses correspondantes à la liste des disjonctions d'actions
            for (int a2 = a1 + 1; a2 < A; a2++) {
                // On calcule la variable SAT correspondant à l'action a2 : v2 = F + a2 + 1
                int v2 = F + a2 + 1;
                // On ajoute la clause (¬v1 v ¬v2) qui dit que les actions a1 et a2 ne peuvent pas être exécutées en même temps
                actionDisjunctionList.add(Arrays.asList(-v1, -v2));
            }
        }

        // Makes DIMACS encoding from 1 to steps
        encode(1, steps);
    }
    
    /*
     * SAT encoding for next step
     */
    public void next() {
        this.steps++;
        encode(this.steps, this.steps);
    }

    public String toString(final List<Integer> clause, final Problem problem) {
        final int nb_fluents = problem.getFluents().size();
        List<Integer> dejavu = new ArrayList<Integer>();
        String t = "[";
        String u = "";
        int tmp = 1;
        int [] couple;
        int bitnum;
        int step;
        for (Integer x : clause) {
            if (x > 0) {
                couple = unpair(x);
                bitnum = couple[0];
                step = couple[1];
            } else {
                couple = unpair(- x);
                bitnum = - couple[0];
                step = couple[1];
            }
            t = t + "(" + bitnum + ", " + step + ")";
            t = (tmp == clause.size()) ? t + "]\n" : t + " + ";
            tmp++;
            final int b = Math.abs(bitnum);
            if (!dejavu.contains(b)) {
                dejavu.add(b);
                u = u + b + " >> ";
                if (nb_fluents >= b) {
                    Fluent fluent = problem.getFluents().get(b - 1);
                    u = u + problem.toString(fluent)  + "\n";
                } else {
                    u = u + problem.toShortString(problem.getActions().get(b - nb_fluents - 1)) + "\n";
                }
            }
        }
        return t + u;
    }

    public Plan extractPlan(final List<Integer> solution, final Problem problem) {
        Plan plan = new SequentialPlan();
        HashMap<Integer, Action> sequence = new HashMap<Integer, Action>();
        final int nb_fluents = problem.getFluents().size();
        int[] couple;
        int bitnum;
        int step;
        for (Integer x : solution) {
            if (x > 0) {
                couple = unpair(x);
                bitnum = couple[0];
            } else {
                couple = unpair(-x);
                bitnum = -couple[0];
            }
            step = couple[1];
            // This is a positive (asserted) action
            if (bitnum > nb_fluents) {
                final Action action = problem.getActions().get(bitnum - nb_fluents - 1);
                sequence.put(step, action);
            }
        }
        for (int s = sequence.keySet().size(); s > 0 ; s--) {
            plan.add(0, sequence.get(s));
        }
        return plan;
    }
    
    // Cantor paring function generates unique numbers
    private static int pair(int num, int step) {
        return (int) (0.5 * (num + step) * (num + step + 1) + step);
    }

    private static int[] unpair(int z) {
        /*
        Cantor unpair function is the reverse of the pairing function. It takes a single input
        and returns the two corespoding values.
        */
        int t = (int) (Math.floor((Math.sqrt(8 * z + 1) - 1) / 2));
        int bitnum = t * (t + 3) / 2 - z;
        int step = z - t * (t + 1) / 2;
        return new int[]{bitnum, step}; //Returning an array containing the two numbers
    }

    private void encode(int from, int to) {
        // On vide le buffer courant pour y mettre uniquement les clauses generees pour l'appel encode(from, to).
        this.currentDimacs.clear();

        // On vide aussi le but courant; il sera reinstancie au dernier etat (to + 1).
        this.currentGoal.clear();

        // Si from == 1, on reconstruit un encodage complet depuis l'etat initial.
        // Sinon (appel via next()), ces clauses sont deja presentes dans le solveur SAT.
        if (from == 1) {
            // On ajoute les clauses d'init à l'encodage courant
            this.currentDimacs.addAll(initList);
        }

        // Nombre de fluents (mémorisé au constructeur).
        final int F = this.nbFluents;

        // Pour chaque pas d'action t
        for (int t = from; t <= to; t++) {

            // =======================
            // A) Instanciation des préconditions à t
            // =======================
            // On parcourt la liste des préconditions d'actions et on ajoute les clauses correspondantes à l'encodage courant
            // en remplaçant les variables génériques a et p par les variables spécifiques au pas t : a_t et p_t
            for (List<Integer> c : actionPreconditionList) {

                // aLit : litteral gabarit de l'action (negatif dans ces clauses de precondition)
                int aLit = c.get(0); // négatif

                // fLit : litteral gabarit du fluent (positif ou negatif selon le type de precondition)
                int fLit = c.get(1); // positif ou négatif

                // aVar : identifiant SAT de l'action (sans temps, sans signe).
                // Le temps t est ajoute ensuite via pair(aVar, t).
                int aVar = Math.abs(aLit);

                // fVar : identifiant SAT du fluent (sans temps, sans signe).
                int fVar = Math.abs(fLit);

                // On crée une nouvelle clause instanciée pour le pas t en remplaçant a par a_t et p par p_t
                List<Integer> inst = new ArrayList<>();

                // Clause : (¬a_t v p_t) si fLit > 0, sinon (¬a_t v ¬p_t).
                inst.add(-pair(aVar, t)); // ¬a_t
                inst.add(fLit < 0 ? -pair(fVar, t) : pair(fVar, t)); // ¬p_t ou p_t
                currentDimacs.add(inst);
            }

            // =======================
            // B) Instanciation des effets à t -> t+1
            // =======================
            // On parcourt la liste des effets d'actions et on ajoute les clauses correspondantes à l'encodage courant
            // en remplaçant les variables génériques a et p par les variables spécifiques au pas t : a_t et p_t+1
            for (List<Integer> c : actionEffectList) {
                int aLit = c.get(0); // négatif
                int eLit = c.get(1); // positif ou négatif
                int aVar = Math.abs(aLit);
                int fVar = Math.abs(eLit);

                List<Integer> inst = new ArrayList<>();
                inst.add(-pair(aVar, t)); // ¬a_t
                inst.add(eLit < 0 ? -pair(fVar, t + 1) : pair(fVar, t + 1)); // effet au pas suivant
                currentDimacs.add(inst);
            }

            // =======================
            // C) Frame axioms
            // =======================
            // On parcourt tous les fluents et pour chaque fluent f, on ajoute les clauses de frame axioms suivantes :
            // - Si f passe de vrai à faux, il faut une action qui le delete : (¬f_t v f_t+1 v delActions_t...)
            // - Si f passe de faux à vrai, il faut une action qui l'ajoute : (f_t v ¬f_t+1 v addActions_t...)
            for (int f = 1; f <= F; f++) {

                // Cas 1 : Si f passe de vrai à faux, il faut une action qui le delete
                // (¬p_t v p_t+1 v delActions_t...)
                List<Integer> delFrame = new ArrayList<>();
                delFrame.add(-pair(f, t));
                delFrame.add(pair(f, t + 1));
                for (int aVar : delList.getOrDefault(f, new ArrayList<>())) {
                    delFrame.add(pair(aVar, t));
                }
                currentDimacs.add(delFrame);

                // Cas 2 : Si f passe de faux à vrai, il faut une action qui l'ajoute
                // (p_t v ¬p_t+1 v addActions_t...)
                List<Integer> addFrame = new ArrayList<>();
                addFrame.add(pair(f, t));
                addFrame.add(-pair(f, t + 1));
                for (int aVar : addList.getOrDefault(f, new ArrayList<>())) {
                    addFrame.add(pair(aVar, t));
                }
                currentDimacs.add(addFrame);
            }

            // =======================
            // D) Mutex actions au pas t
            // =======================
            // On parcourt la liste des disjonctions d'actions et on ajoute les clauses correspondantes à l'encodage courant
            for (List<Integer> c : actionDisjunctionList) {
                int v1 = Math.abs(c.get(0));
                int v2 = Math.abs(c.get(1));
                // La clause de disjonction d'actions est de la forme (¬v1_t v ¬v2_t) qui dit que les actions v1 et v2 ne peuvent pas être exécutées en même temps au pas t
                currentDimacs.add(Arrays.asList(-pair(v1, t), -pair(v2, t)));
            }
        }

        // =======================
        // E) But au dernier état (to+1)
        // =======================
        // On parcourt la liste du but et on ajoute les clauses correspondantes à la liste du but courant en remplaçant les variables génériques p par les variables spécifiques au pas to+1 : p_to+1
        for (int gLit : goalList) {
            int gVar = Math.abs(gLit);
            // Si gLit est positif, on ajoute la clause (p_to+1) qui dit que le fluent doit être vrai au pas to+1
            // Si gLit est négatif, on ajoute la clause (¬p_to+1) qui dit que le fluent doit être faux au pas to+1
            currentGoal.add(gLit < 0 ? -pair(gVar, to + 1) : pair(gVar, to + 1));
        }


        System.out.println("Encoding : successfully done (" + (this.currentDimacs.size()
                + this.currentGoal.size()) + " clauses, " + to + " steps)");
    }

}
