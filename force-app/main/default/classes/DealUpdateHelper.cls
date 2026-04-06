public class DealUpdateHelper{   
    // newDealUpdates : Newly created deal Updates
    public static void updateParent(List<Deal_Update__c> newDealUpdates,map<id,Deal_Update__c> triggerRecords){

        
        Map<string, DealUpdate__c > cusSetDealUpdate = DealUpdate__c.getAll();
        Map<string,Set<string>> objFieldMap = new Map<string,Set<string>>();
        List<sObject> recordList=new List<sObject>();
        Set<id> Ids = new Set<id>();
        boolean hasError = false;
        for(Deal_Update__c du: newDealUpdates){
            
            if(cusSetDealUpdate != null){
                String tempKey = du.Object_type__c+''+du.Type__c;
                System.debug('test palak '+tempKey); 
                string fieldApi = cusSetDealUpdate.get(tempKey) != null? cusSetDealUpdate.get(tempKey).Field_API_Name__c :'';
                string datefieldApi = cusSetDealUpdate.get(tempKey) != null? cusSetDealUpdate.get(tempKey).Date_Field_API_Name__c :'';
                string dateMRfieldApi = cusSetDealUpdate.get(du.Object_type__c) != null? cusSetDealUpdate.get(du.Object_type__c).Date_Field_API_Name__c :'';
                
                System.debug('test palak '+fieldApi);
                if(fieldApi !=''){
                    Date cd = Date.valueOF(du.createdDate);
                    String textBody = cd+' : '+du.createdby.firstname+' '+du.createdby.lastname;
                    Integer bodyLen = du.body__c != null  && du.body__c != '' ? du.body__c.length(): 0;
                    Integer finalLen = bodyLen>4000 ? 4000 :bodyLen;
                    if(finalLen > 0){
                        try{
                        textBody = du.body__c != null  && du.body__c != '' ?textBody+' '+du.body__c.substring(0,finalLen):textBody+'';
                        SObject castRecord = (sObject)Type.forname(du.Object_type__c).newInstance();
                        System.debug('test PALAK '+du.get(du.Object_type__c+'__c'));
                        if(du.get(du.Object_type__c+'__c') == null){
                             triggerRecords.get(du.id).addError('Please Select the Object Record corresponding to Object Type');
                             hasError = true;
                        }        
                        castRecord.id =(ID)du.get(du.Object_type__c+'__c');
                        castRecord.put(fieldApi,textBody);
                        if(datefieldApi != '' && datefieldApi != null)
                            castRecord.put(datefieldApi,cd);
                         if(dateMRfieldApi != null && dateMRfieldApi !='')
                            castRecord.put(dateMRfieldApi,cd);
                        if(!Ids.contains(castRecord.id)){
                            recordList.add(castRecord);
                            Ids.add(castRecord.id);
                        }
                        
                        }Catch(Exception e){
                            String exceptionMess = e.getMessage();
                            if(exceptionMess.contains('Invalid field')){
                                triggerRecords.get(du.id).addError('Please match the fields in deal updates custom setting and parent object');
                                system.debug('Please match the fields in deal updates custom setting and parent object');    
                            }
                        }
                    
                    }
                }
                
            }
        }
        System.debug('test palak '+recordList.size());
        if(recordList.size()>0 && !hasError)
            update recordList;
            



    }

}