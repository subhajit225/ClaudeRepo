public class AllianceLeadConvertExtention {
    private Alliance_Lead__c leadAlliance;
    private Map<String, String> mapOfMapping;
    public AllianceLeadConvertExtention(ApexPages.StandardController stdController) {
        this.leadAlliance = (Alliance_Lead__c)stdController.getRecord(); 
        mapOfMapping = new Map<String, String>();
        system.debug(' this.leadAlliance'+ this.leadAlliance);
        getMapping();
    }
    public void getMapping(){
        List<AllianceleadLeadMapping__c> leadMappings = AllianceleadLeadMapping__c.getAll().values();
        for(AllianceleadLeadMapping__c mapping : leadMappings) {
            mapOfMapping.put(mapping.Name,mapping.LeadFields__c); 
        }
    }
    
    public Pagereference convertToLead(){
        String query = 'Select Id,';
        for(String s : mapOfMapping.keySet()) {
            query += String.escapeSingleQuotes(s) + ',';
        }
        query = query.removeEnd(',');
        query += ' FROM Alliance_Lead__c where Id = \''+ String.escapeSingleQuotes(this.leadAlliance.Id) +'\'';
        system.debug('@@query = '+query);
        List<sObject> result = Database.query(query);
        system.debug('@@result1 '+result);
        Alliance_Lead__c leadObj = (Alliance_Lead__c) result[0];
        Lead convLead = new Lead();
        Object source = leadObj.get('Customer__c'); // SF-295:Satish- Changed from Name to Customer__c. 
        integer count=[Select count() from Lead where company=:(string)source];
        if(count!=0){
            lead l=[Select id from Lead where company=:(string)source];
            system.debug('@@id=> '+l.id);
            system.debug('@@convLead=> '+convLead);
            String htmlText = 'Duplicate Record Found <a href=https://rubrikinc--devrob.cs19.my.salesforce.com/'+l.id+'>Click to view Record</a>';
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,htmlText);
            ApexPages.addMessage(myMsg);
            return null;
        }
        else{
            leadObj.isConverted__c=True;
            update leadObj;
            AllianceLeadConvert leadConvert = new AllianceLeadConvert();
            
            Id l=leadConvert.convertLeadReg(result[0]);
            //ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.CONFIRM,'Successfully Converted');
            //ApexPages.addMessage(myMsg);
            PageReference send = new PageReference('/' + l);
            send.setRedirect(true);
            return send;  
        }
        
    }
}