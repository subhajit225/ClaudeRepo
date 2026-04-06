public class FuzzyMethod{

/*public static double levenshteinDistance(String s, String t) {
    Integer len0 = s.length() + 1;
    integer len1 = t.length() + 1;
    list<integer> cost = new list<integer>();
    List<Integer> newcost = new list<Integer>();
    for(Integer i = 0; i < len0; i++)
        cost.add(i);
    for(integer j = 1; j< len1; j++) {
        newcost.add(j);
        System.debug('test code '+newcost);
        System.debug('test code '+cost);
        for(Integer i = 1; i< len0; i++) {
            integer match = (s.charAt(i-1) == t.charat(j-1)) ? 0 : 1;
            System.debug('test code '+cost[i-1]);
            System.debug('test code '+cost[i]);
            System.debug('test code '+newcost[i - 1]);
            Integer cost_replace = cost[i-1] + match;
            Integer cost_insert = cost[i] + 1;
            Integer cost_delete = newcost[i - 1] + 1;
            System.debug('test code '+cost_replace);
            System.debug('test code '+cost_insert);
            System.debug('test code '+cost_delete);
            if(newcost.size() > i )
                newcost[i] = Math.min(Math.min(cost_replace,cost_delete),cost_replace);
            else
                newcost.add(Math.min(Math.min(cost_replace,cost_delete),cost_replace));
        }
        list<integer> swap = new list<Integer>();
        swap.addAll(cost);
        cost = new List<Integer>();
        cost.addAll(newcost);
        newcost = new list<integer>();
        newcost.addall(swap);
    }
    integer bigger = Math.max(s.length(),t.length());
    system.debug(cost[len0 - 1]);
    Double perentage = (double.valueOf(bigger)-double.valueOf(cost[len0 - 1])) * 100 /double.valueOf(bigger);
    return perentage;
}
*/
public static Decimal JaroFuzzyMethod( String s1,  String s2) {

        s1 = s1.toLowerCase();
        s2 = s2.toLowerCase();
        System.debug('test code '+s1);
        System.debug('test code '+s2);
        
        s1 = s1.replaceAll('&', 'and');
        s2 = s2.replaceAll('&', 'and');
        
        String strText = 'Welcome - to! % $sale&sforce \\ /code # crack %';
        s1 = s1.replaceAll('[^a-zA-Z0-9\\s+]', '');
        s2 = s2.replaceAll('[^a-zA-Z0-9\\s+]', '');
        s1 = s1.replaceAll(' ', '');
        s2 = s2.replaceAll(' ', '');
        
        
        
        System.debug('strText ======> '+strText);
        System.debug('test code '+s1);
        System.debug('test code '+s2);
        // lowest score on empty strings
        if (s1 == null || s2 == null || String.isEmpty(s1) || String.isEmpty(s2)) {
            return 0;
        }
        // highest score on equal strings
        if (s1.equals(s2)) {
            return 1;
        }
        // some score on different strings
        Integer prefixMatch = 0; // exact prefix matches
        Integer matches = 0; // matches (including prefix and ones requiring transpostion)
        Integer transpositions = 0; // matching characters that are not aligned but close together 
        Integer maxLength = Math.max(s1.length(), s2.length());
        Integer maxMatchDistance = Math.max((Integer) Math.floor(maxLength / 2.0) - 1, 0); // look-ahead/-behind to limit transposed matches
        // comparison
         String shorter = s1.length() < s2.length() ? s1 : s2;
         String longer = s1.length() >= s2.length() ? s1 : s2;

        for (Integer i = 0; i < shorter.length(); i++) {
            // check for exact matches
            boolean match = shorter.charAt(i) == longer.charAt(i);
            if (match) {
                if (i < 4) {
                    // prefix match (of at most 4 characters, as described by the algorithm)
                    prefixMatch++;
                }
                matches++;
                continue;
            }
            // check fro transposed matches
            for (Integer j = Math.max(i - maxMatchDistance, 0); j < Math.min(i + maxMatchDistance, longer.length()); j++) {
                if (i == j) {
                    // case already covered
                    continue;
                }
                // transposition required to match?
                match = shorter.charAt(i) == longer.charAt(j);
                if (match) {
                    transpositions++;
                    break;
                }
            }
        }
        // any matching characters?
        if (matches == 0) {
            return 0;
        }
        // modify transpositions (according to the algorithm)
        transpositions = (Integer) (transpositions / 2.0);
        // non prefix-boosted score
        Decimal score = 0.3334 * (matches / (Decimal) longer.length() + matches / (Decimal) shorter.length() + (matches - transpositions)
                / (Decimal) matches);
        if (score < 0.7) {
            return score;
        }
        // we already have a good match, hence we boost the score proportional to the common prefix
        Decimal boostedScore = score + prefixMatch * 0.1 * (1.0 - score);
        return boostedScore;
    }
    
   /* public static string retAcro(string s){
        String str = s;
        String result = str.replaceAll('\\B.|\\P{L};','').toUpperCase();
        return result;
    }*/

}