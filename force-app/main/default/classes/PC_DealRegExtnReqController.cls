public without sharing class PC_DealRegExtnReqController {

    @AuraEnabled
    public static Deal_Registration__c getStatus(string dealRegId){
        string status = '';
        Deal_Registration__c dealreg = new Deal_Registration__c();
        
        //PRIT25-484
        if(!string.isBlank(dealRegId)){
        	dealreg = [select Id,Deal_Registration_Status__c,Days_Before_Expiration__c from Deal_Registration__c where Id =: dealRegId LIMIT 1];
        }
        return dealreg;
    }
    
     @AuraEnabled
    public static string setExtension(string dealRegId){
        string message = '';
        List<Deal_Registration__c> dealregList = new List<Deal_Registration__c>();
        if(!string.isBlank(dealRegId)){
        	dealregList = [select Id,Deal_Registration_Status__c,Requested_for_Extension__c,Deal_Registration_Extension_Request__c,Opportunity__c from Deal_Registration__c where Id =: dealRegId];
            if(!dealregList.isEmpty() && dealregList[0].Requested_for_Extension__c == true){
             	message = 'Deal Registration is already Requested for Extension';  
            }
            if(!dealregList.isEmpty() && dealregList[0].Requested_for_Extension__c == false && (/*dealregList[0].Deal_Registration_Extension_Request__c != '3rd Deal Reg Ext. Req. for next 45 Days' &&*/ dealregList[0].Deal_Registration_Extension_Request__c != 'Pending Meeting Ext. Req. for next 10 Days' && ((String.isNotBlank(dealregList[0].Opportunity__c) && (dealregList[0].Deal_Registration_Status__c == 'Expired' || dealregList[0].Deal_Registration_Status__c == 'Approved')) || (dealregList[0].Deal_Registration_Status__c == 'Pending Meeting')))){
                
                dealregList[0].Requested_for_Extension__c = true;
                dealregList[0].Deal_Registration_Sub_Status__c = 'Extension Requested';
                try{
                    update dealregList;
                    message = 'Deal Registration is successfully Requested for Extension';  
                }catch(Exception e){
                    message = e.getMessage();
                }
            }else if(!dealregList.isEmpty() && dealregList[0].Requested_for_Extension__c == false && (/*dealregList[0].Deal_Registration_Extension_Request__c == '3rd Deal Reg Ext. Req. for next 45 Days' ||*/ dealregList[0].Deal_Registration_Extension_Request__c == 'Pending Meeting Ext. Req. for next 10 Days' || (dealregList[0].Deal_Registration_Status__c == 'Expired' && String.isBlank(dealregList[0].Opportunity__c)))){
                    message = 'This Deal Registration cannot be further Extended';  
            }
        }
        return message;
    }

}