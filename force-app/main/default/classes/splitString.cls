public class splitString {
    
    @InvocableMethod(label='Process String' description='Returns the list of String')
    public static List<Output> processString(List<Input> stringToProcess) {
        List<Output> output = new List<output>();
        List<String> stringList = new List<String>();
        for (Input s : stringToProcess) {
        system.debug('AB input'+s.text);
            /*if(s.action == 'Split'){
                stringList.addAll(splitStringUsingSeperator(s.text,s.delimiter));
            }*/
            if(s.action == 'Rich'){
                stringList.addAll(getIdsFromRichText(s.text,s.delimiter));
            }
        }
        system.debug('AB stringList'+stringList);
        Output o = new Output();
        o.processedString = stringList;
        output.add(o);
        system.debug('AB output'+o);
        return output;
    }
    
    
    /*public static List<String> splitStringUsingSeperator(String stringsToSplit,String delimiter) {
         return stringsToSplit.split(delimiter);
    }*/
    
    public static List<String> getIdsFromRichText(String richTextString,String delimiter) {
        List<String> stringList = new List<String>();
        List<String> nameList = new List<String>();
        stringList.addall(richTextString.split(delimiter));
        for(String s :stringList){
            nameList.add(s.substringBetween('"/','"'));
        }
        return nameList;
    }
    
    public class Input {
        @InvocableVariable(label='String' required=true)
        public String text;
        @InvocableVariable(label='Delimiter/Seperator' required=true)    
        public String delimiter;
    @InvocableVariable(label='action' required=true)    
        public String action;        
    }
    
    public class Output {
        @InvocableVariable(label='Processed String List' required=true)    
        public List<String> processedString; 
    }

}