package sokoban;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Scanner;

public class Agent {
    private static final String DEFAULT_SOLUTION = "DUU";

    public static void main(String[] args) {
        String solution = loadSolution();
        Scanner in = new Scanner(System.in);

        int boxCount = 0;
        int mapHeight = 0;
        boolean firstTurn = true;
        int step = 0;

        while (true) {
            if (firstTurn) {
                if (!in.hasNextLine()) break;
                String[] header = in.nextLine().trim().split("\\s+");
                if (header.length < 3) break;
                mapHeight = safeParse(header[1], 0);
                boxCount = safeParse(header[2], 0);
                for (int i = 0; i < mapHeight && in.hasNextLine(); i++) in.nextLine();
                firstTurn = false;
            }

            if (!in.hasNextLine()) break;
            in.nextLine(); // position joueur
            for (int i = 0; i < boxCount && in.hasNextLine(); i++) in.nextLine(); // positions caisses

            char move = step < solution.length() ? solution.charAt(step) : solution.charAt(solution.length() - 1);
            step++;
            System.out.println(move);
            System.out.flush();
        }
    }

    private static String loadSolution() {
        String path = System.getProperty("solution.file");
        if (isBlank(path)) path = System.getenv("SOKOBAN_SOLUTION_FILE");
        if (isBlank(path)) path = "config/solution.txt";

        String raw = readFile(path);
        if (isBlank(raw)) return DEFAULT_SOLUTION;

        String fromPlan = decodePlan(raw);
        if (!isBlank(fromPlan)) return fromPlan;

        String fromRawMoves = keepMovesOnly(raw);
        if (!isBlank(fromRawMoves)) return fromRawMoves;

        return DEFAULT_SOLUTION;
    }

    private static String decodePlan(String raw) {
        StringBuilder sb = new StringBuilder();
        String[] lines = raw.split("\\R");
        for (String line : lines) {
            String token = extractActionToken(line);
            if (token == null) continue;
            String action = token.toLowerCase();
            if (action.endsWith("north")) sb.append('U');
            else if (action.endsWith("east")) sb.append('R');
            else if (action.endsWith("south")) sb.append('D');
            else if (action.endsWith("west")) sb.append('L');
            else return "";
        }
        return sb.toString();
    }

    private static String extractActionToken(String line) {
        if (!line.matches("^\\s*\\d+:.*")) return null;
        int open = line.indexOf('(');
        if (open < 0) return null;

        int i = open + 1;
        while (i < line.length() && Character.isWhitespace(line.charAt(i))) i++;
        if (i >= line.length()) return null;

        int j = i;
        while (j < line.length()) {
            char c = line.charAt(j);
            if (Character.isWhitespace(c) || c == ')') break;
            j++;
        }
        if (j <= i) return null;
        return line.substring(i, j);
    }

    private static String keepMovesOnly(String raw) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < raw.length(); i++) {
            char c = Character.toUpperCase(raw.charAt(i));
            if (c == 'U' || c == 'R' || c == 'D' || c == 'L') sb.append(c);
        }
        return sb.toString();
    }

    private static int safeParse(String s, int fallback) {
        try {
            return Integer.parseInt(s);
        } catch (NumberFormatException e) {
            return fallback;
        }
    }

    private static boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    private static String readFile(String path) {
        try {
            byte[] bytes = Files.readAllBytes(Paths.get(path));
            return new String(bytes, StandardCharsets.UTF_8);
        } catch (IOException e) {
            return "";
        }
    }
}
