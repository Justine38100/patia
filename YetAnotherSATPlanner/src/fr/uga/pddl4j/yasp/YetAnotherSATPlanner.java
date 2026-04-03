package fr.uga.pddl4j.yasp;

import fr.uga.pddl4j.heuristics.state.FastForward;
import fr.uga.pddl4j.parser.DefaultParsedProblem;
import fr.uga.pddl4j.parser.ErrorManager;
import fr.uga.pddl4j.parser.Message;
import fr.uga.pddl4j.parser.Parser;
import fr.uga.pddl4j.problem.DefaultProblem;
import fr.uga.pddl4j.problem.Problem;
import fr.uga.pddl4j.problem.State;
import fr.uga.pddl4j.planners.statespace.AbstractStateSpacePlanner;
import fr.uga.pddl4j.planners.LogLevel;
import fr.uga.pddl4j.plan.Plan;

import org.sat4j.core.VecInt;
import org.sat4j.minisat.SolverFactory;
import org.sat4j.specs.ContradictionException;
import org.sat4j.specs.IProblem;
import org.sat4j.specs.ISolver;
import org.sat4j.specs.IVecInt;
import org.sat4j.specs.TimeoutException;

import java.io.FileNotFoundException;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

/**
 * The class shows how to use PDDL4J + SAT4J libraries to create a SAT planner.
 *
 * @version 0.1 - 29.03.2024
 */
public class YetAnotherSATPlanner extends AbstractStateSpacePlanner {

    /**
     * The main method the class. The first argument must be the path to the PDDL domain description and the second
     * argument the path to the PDDL problem description.
     *
     * @param args the command line arguments.
     */

    static final int MAXSTEPS = 50;
    // SAT solver max number of var
    static final int MAXVAR = 1000000;
    // SAT solver max number of clauses
    static final int NBCLAUSES = 500000;
    // SAT solver timeout
    static final int TIMEOUT = 3600;

    static final boolean DEBUG = false;

    /**
     * Instantiates the planning problem from a parsed problem.
     *
     * @param problem the problem to instantiate.
     * @return the instantiated planning problem or null if the problem cannot be instantiated.
     */
    @Override
    public Problem instantiate(DefaultParsedProblem problem) {
        final Problem pb = new DefaultProblem(problem);
        pb.instantiate();
        return pb;
    }

    /**
     * Solves the planning problem and returns the first solution found.
     *
     * @param problem the problem to be solved.
     * @return a solution search or null if it does not exist.
     */
    @Override
    public Plan solve(final Problem problem) {

        int stepmax = MAXSTEPS;
        Plan plan = null;

        // Borne inferieure heuristique: nombre minimal d'actions estime pour atteindre le but.
        final FastForward ff = new FastForward(problem);
        final int hlb = ff.estimate(new State(problem.getInitialState()), problem.getGoal());
        if (hlb > MAXSTEPS) {
            System.out.println("Problem has no solution in " + MAXSTEPS + " steps!");
            System.out.println("At least " + hlb + " steps are necessary.");
            System.exit(0);
        } else {

            // Horizon initial de l'encodage SAT: on commence à la borne heuristique.
            int steps = hlb;

            // Construction de l'encodage SAT pour cet horizon.
            SATEncoding sat = new SATEncoding(problem, steps);

            // Initialisation du solveur SAT4J.
            final ISolver solver = SolverFactory.newDefault();
            solver.setTimeout(TIMEOUT);
            // SAT4J demande une borne supérieure sur le nombre de variables manipulables.
            solver.newVar(MAXVAR);
            solver.setExpectedNumberOfClauses(NBCLAUSES);
            IProblem ip = solver;

            // Boucle de recherche incrémentale sur l'horizon.
            boolean doSearch = true;

            // On augmente l'horizon tant qu'aucun plan n'est trouvé et que la borne max n'est pas dépassée.
            while (doSearch && !(steps > stepmax)) {
                try {
                    // 1) Ajout des clauses CNF de l'horizon courant (delta si mode incremental).
                    for (List<Integer> c : sat.currentDimacs) {
                        // Conversion List<Integer> -> int[] pour SAT4J.
                        int[] arr = c.stream().mapToInt(Integer::intValue).toArray();
                        // Injection de la clause dans le solveur.
                        solver.addClause(new VecInt(arr));
                    }

                    // 2) Le but est imposé via assumptions (contraintes temporaires pour ce test SAT).
                    int[] g = sat.currentGoal.stream().mapToInt(Integer::intValue).toArray();
                    IVecInt assumptions = new VecInt(g);

                    // 3) Test SAT sous ces assumptions.
                    if (ip.isSatisfiable(assumptions)) {
                        // SAT: on récupère le modèle puis on extrait le plan.
                        List<Integer> model = Arrays.stream(ip.model()).boxed().collect(Collectors.toList());
                        plan = sat.extractPlan(model, problem);
                        doSearch = false;
                    } else {
                        // UNSAT: aucun plan à cet horizon, on tente horizon+1.
                        steps++;
                        if (steps <= stepmax) {
                            sat.next(); // génère les clauses supplémentaires pour l'horizon suivant
                        }
                    }

                } catch (ContradictionException e) {
                    // Contradiction immédiate pour cet horizon: on essaie l'horizon suivant.
                    steps++;
                    if (steps <= stepmax) {
                        sat.next();
                    }
                } catch (TimeoutException e) {
                    // Timeout SAT4J: on arrête la recherche.
                    doSearch = false;
                }
            }
        }
        // Retourne le plan trouvé, ou null si non trouvé (borne atteinte / timeout).
        return plan;
    }
    public static void main(final String[] args) {

        // Checks the number of arguments from the command line
        if (args.length != 2) {
            System.out.println("Invalid command line");
            return;
        }

        try {
            // Creates an instance of the PDDL parser
            final Parser parser = new Parser();
            parser.setLogLevel(LogLevel.OFF);
            // Parses the domain and the problem files.
            final DefaultParsedProblem parsedProblem = parser.parse(args[0], args[1]);
            // Gets the error manager of the parser
            final ErrorManager errorManager = parser.getErrorManager();
            // Checks if the error manager contains errors
            if (!errorManager.isEmpty()) {
                // Prints the errors
                for (Message m : errorManager.getMessages()) {
                    System.out.println(m.toString());
                }
            } else {
                
                // Creates an instance of the SAT planner
                final YetAnotherSATPlanner planner = new YetAnotherSATPlanner();

                // Prints that the domain and the problem were successfully parsed
                System.out.print("\nparsing domain file \"" + args[0] + "\" done successfully");
                System.out.print("\nparsing problem file \"" + args[1] + "\" done successfully\n\n");
                
                // Create a problem
                final Problem problem = planner.instantiate(parsedProblem);

                // Check if the goal is trivially unsatisfiable
                if (!problem.isSolvable()) {
                    System.out.println("Goal can be simplified to FALSE. No search will solve it");
                    System.exit(0);
                } else {
                    
                    Plan plan = planner.solve(problem);
                        
                        if (plan != null) {
                            System.out.println(problem.toString(plan));
                        } else {
                            System.out.println("No solution found!");
                        }
                }
            }
            // This exception could happen if the domain or the problem does not exist
        } catch (FileNotFoundException e) {
            e.printStackTrace();
        }
    }
}