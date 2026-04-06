/**
* @Author      : Sai Kishore
*/
public class PSTimeCardTriggerHelper{    
    
    //Hanlde all before update trigger actions
    public void BeforeUpdateHelper(List<PS_Time_Card__c> newPsTimeCards, Map<Id, PS_Time_Card__c > mapOldPsTimeCards){
        
        for (PS_Time_Card__c newRec : newPsTimeCards) {
            
            PS_Time_Card__c oldRec = mapOldPsTimeCards.get(newRec.Id);
            
            if (newRec.OwnerId == UserInfo.getUserId() && newRec.Status__c == 'Approved' && newRec.Status__c != oldRec.Status__c) {
                newRec.Status__c.addError('Operation not permitted. Please contact your manager for assistance.');
            }
        }
        System.debug('BeforeUpdate Called');  		
    }
    
}