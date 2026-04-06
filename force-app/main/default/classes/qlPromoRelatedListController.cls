public class qlPromoRelatedListController {
    
    @AuraEnabled(cacheable=true)
    public static String getQuoteLines(Id quoteId) {
        List<SBQQ__QuoteLine__c> quoteLines = Database.query(System.Label.qlPromoRelatedListQuery);
        system.debug('quoteLines >>'+quoteLines);
        List<String> result = new List<String>();
        for (SBQQ__QuoteLine__c line : quoteLines) {
            result.add(replaceJSON(System.Label.qlPromoRelatedListDataMapping,line,'SBQQ__QuoteLine__c'));
        }

        return JSON.serialize(result);
    }
    
    public static String replaceJSON(String wrapper, SObject obj, String objAPIName){
        wrapper = wrapper.deleteWhitespace();
        String toReplace;
        String toSearch;
        String value;
        String newWrapper='';
        Schema.DisplayType fieldDataType;
        List<String> newList=wrapper.split(',');
        for(String s:newList)
        {
            if(s.contains('{!'+objAPIName))
            {
                toReplace = s.substringBetween('{!','}');
                if(toReplace.startsWithIgnoreCase(objAPIName)){
                    toSearch = toReplace.removeStart(objAPIName+'.');
                    if(toSearch.containsAny('.')){
                        value = sObjectDrilling( obj, toSearch );
                    }
                    else{
                        value = obj.get(toSearch)!=null?String.valueOf(obj.get(toSearch)):'';
                    }
                    toReplace='\\{!'+toReplace+'\\}';
                    s=s.replaceAll(toReplace,value);
                }
            }
            newWrapper +=s+',';
        }
        newWrapper=newWrapper.substring(0, newWrapper.length()-1);
        return newWrapper;
    }
    private static String sObjectDrilling( sObject sobjInst, String field ) {
        List<String> lstFields = field.split('\\.', 2);
        if( sobjInst == null ) {
            return '';
        }
        if( lstFields.size() >= 2 ) {
            return sObjectDrilling( sobjInst.getSObject(lstFields[0]), lstFields[1] );
        } else {
            if( sobjInst.get(lstFields[0]) == null ) {
                return '';
            }
            return String.valueOf(sobjInst.get(lstFields[0]));
        }
    }
    
}