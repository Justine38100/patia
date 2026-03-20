Play the game on [CodinGame](https://www.codingame.com/training/hard/sokoban)

Maven is needed.

Install pddl4j (https://github.com/pellierd/pddl4j) in your local maven repo:
```
mvn install:install-file \
   -Dfile=<path-to-file-pddl4j-4.0.0.jar> \
   -DgroupId=fr.uga \
   -DartifactId=pddl4j \
   -Dversion=4.0.0 \
   -Dpackaging=jar \
   -DgeneratePom=true
 ```  
Work with maven: mvn clean, mvn compile, mvn test, mvn package

Run with: 
````
java --add-opens java.base/java.lang=ALL-UNNAMED \
      -server -Xms2048m -Xmx2048m \
      -cp "$(mvn dependency:build-classpath -Dmdep.outputFile=/dev/stdout -q):target/test-classes/:target/classes" \
      sokoban.SokobanMain
````
or (after mvn package)
```
java --add-opens java.base/java.lang=ALL-UNNAMED \
      -server -Xms2048m -Xmx2048m \
      -cp target/sokoban-1.0-SNAPSHOT-jar-with-dependencies.jar \
      sokoban.SokobanMain
```
Sorry ```mvn exec:java``` has still an open issue ("Directory src/main/resources/view/assets not found.")

See planning solutions at http://localhost:8888/test.html
## Connect External PDDL Plan To Visualizer

This project expects one move per turn from the agent, using one character in `U`, `R`, `D`, `L`.

The provided `sokoban.Agent` now supports:
- a raw move string (example: `UURDDL`), or
- a full PDDL4J planner output (it extracts actions ending with `north/east/south/west`).

Default solution file is `config/solution.txt`.
You can override it with:
- JVM property: `-Dsolution.file=/path/to/file`
- env var: `SOKOBAN_SOLUTION_FILE=/path/to/file`

### End-to-end example from repository root

```bash
# 1) Run planner and save its textual output
./pddl/pddlj4_auto.sh 1 pddl/sokoban/domain.pddl pddl/sokoban/problem.pddl 60 5 > /tmp/plan.log

# 2) Convert plan to URDL sequence for the visualizer
./sokoban-master/scripts/pddl_plan_to_urdl.sh /tmp/plan.log sokoban-master/config/solution.txt

# 3) Build and run visualizer
cd sokoban-master
mvn clean compile
java --add-opens java.base/java.lang=ALL-UNNAMED \
     -server -Xms2048m -Xmx2048m \
     -cp "$(mvn dependency:build-classpath -Dmdep.outputFile=/dev/stdout -q):target/test-classes/:target/classes" \
     sokoban.SokobanMain
```

Open: http://localhost:8888/test.html

### One-command pipeline (PDDL -> Java visualizer)

```bash
# From repository root
./sokoban-master/scripts/run_pddl_to_sokoban.sh 1 pddl/sokoban/domain.pddl pddl/sokoban/problem.pddl 60 5 test21.json
```

It will:
1. solve with pddl4j,
2. convert plan to URDL,
3. compile Java,
4. start `sokoban.SokobanMain` with your solution.
