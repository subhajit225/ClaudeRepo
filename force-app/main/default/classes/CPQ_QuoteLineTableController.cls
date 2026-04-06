public class CPQ_QuoteLineTableController {
    
 
    public Set<String> uniqueFieldSet{get;set;}
    public List<Schema.FieldSetMember> fieldSetMemberList{get;set;}
    public String conFieldSetName{get;set;}
    public String conQuoteLineType{get;set;}
    public String conQuoteID{get;set;}
    public List<SBQQ__QuoteLine__c> QuoteLineDetails;
    public Map<String,String> mapQuoteTypeFieldSet = new Map<String,String>{'Renewal' => 'Renewal_Approval_Request', 'Quote' => 'Approval_Request','Renewal+Expansion'=>'Renewal_Expansion_Approval_Request'};
     
    public List<SBQQ__QuoteLine__c> getQuoteLineDetails(){
    
        system.debug('conQuoteID.  '+conQuoteID);
        if(QuoteLineDetails == null){
            if(conQuoteID != null){
                QuoteLineDetails = getQuoteLines();
            }else{
                QuoteLineDetails = new List<SBQQ__QuoteLine__c>();
            }
        }
        system.debug('QuoteLineDetails.  '+QuoteLineDetails);
        return QuoteLineDetails;
    }

    public CPQ_QuoteLineTableController(){
           
    }
    
    public List<SBQQ__QuoteLine__c> getQuoteLines(){
        system.debug('CalledCalled');
        if(mapQuoteTypeFieldSet.containsKey(conQuoteLineType)){
            fieldSetMemberList = SObjectTYpe.SBQQ__QuoteLine__c.FieldSets.getMap().get(mapQuoteTypeFieldSet.get(conQuoteLineType)).getFields();
        }else{
            fieldSetMemberList = SObjectTYpe.SBQQ__QuoteLine__c.FieldSets.getMap().get('Approval_Request').getFields();
        }
        
        
        system.debug('fieldSetMemberList.  '+fieldSetMemberList);
        uniqueFieldSet = new Set<String>();
        for(Schema.FieldSetMember f : fieldSetMemberList) {
            uniqueFieldSet.add(f.getFieldPath());
        }
        
        String query = 'SELECT ';
        for(String unqField : uniqueFieldSet){
            query += unqField + ', ';
        }
        query += 'Id FROM SBQQ__QuoteLine__c where SBQQ__Quote__c = \'' + String.escapeSingleQuotes(conQuoteID) + '\'';
        
        if(conQuoteLineType == 'Renewal'){
            query += 'AND Quote_Line_Type__c = \'Renewal\' ';
        }
        else if(conQuoteLineType == 'Renewal+Expansion'){
             query += 'AND Quote_Line_Type__c IN (\'Renewal\', \'New\') AND Disposition_Reason__c in (\'\',\'None\',\'Renewing\',\'Upgrade\') ';
       }else if(conQuoteLineType == 'Amendment'){
            query += 'AND Quote_Line_Type__c = \'New\'';
        }
        system.debug('query.   '+query);
        return Database.query(query);
        
    }
    
}