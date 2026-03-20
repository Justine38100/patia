package sokoban;

import com.codingame.gameengine.runner.SoloGameRunner;

public class SokobanMain {
    public static void main(String[] args) {
        SoloGameRunner gameRunner = new SoloGameRunner();
        gameRunner.setAgent(Agent.class);
        gameRunner.setTestCase(resolveTestCase());
        gameRunner.start();
    }

    private static String resolveTestCase() {
        String fromProperty = System.getProperty("sokoban.testcase");
        if (fromProperty != null && !fromProperty.trim().isEmpty()) return fromProperty;

        String fromEnv = System.getenv("SOKOBAN_TESTCASE");
        if (fromEnv != null && !fromEnv.trim().isEmpty()) return fromEnv;

        return "test21.json";
    }
}
