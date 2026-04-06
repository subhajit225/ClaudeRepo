@RestResource(urlMapping='/UpdateOrder')
global with sharing class RPSOrderUpdate {
    
    @HttpPatch
    global static void updateScreeningStatus() {
        List<Error_Logs__c> IntegrationLogs = new List<Error_Logs__c>();
        string resBody ;
        RestRequest request = RestContext.request;
        system.debug('request.requestURI'+request.requestURI);
        RestResponse res = RestContext.response;
        Map<string,string>Field_API = new Map<string,string>{'ShipToContactScreenStatus__c'=>'ShipToContact','Shipto_EndUser_Screen_Status__c'=>'ShipTo_EU','Billto_EndUser_Screen_Status__c'=>'BillTo_EU','ShipToScreenStatus__c'=>'ShipTo'};
        /*String OrderId = request.requestURI.substring(
        request.requestURI.lastIndexOf('/')+1);*/
        Order updateOrd = new order();
        string ordStatus ='';
        string query ='Select id,IsDeleted';
        string whereClause;
        Map<string,string>ordFieldLabel_Value = new map<string,string>();
        try{
        Map<String, Object> reqBody = (Map<String, Object>)JSON.deserializeUntyped(request.requestbody.tostring());
        for(String fieldName : reqBody.keySet()) {
            if(fieldName=='ShipToContactScreenStatus__c'||fieldName=='Shipto_EndUser_Screen_Status__c'||fieldName=='Billto_EndUser_Screen_Status__c'||fieldName=='ShipToScreenStatus__c'){
             ordStatus = String.isEmpty(ordStatus)? Field_API.get(fieldName)+' :'+reqBody.get(fieldName): ordStatus+'\n'+Field_API.get(fieldName)+' :'+reqBody.get(fieldName);
            }
            if(fieldName.equalsIgnoreCase('Billto_EndUser_Screening_Id__c')||fieldName.equalsIgnoreCase('ShipToContactScreeningId__c')||fieldName.equalsIgnoreCase('Shipto_EndUser_ScreeningId__c')||fieldName.equalsIgnoreCase('ShipToScreeningId__c')){
               query +=','+fieldName ; 
               ordFieldLabel_Value.put(fieldName,(string)reqBody.get(fieldName));
            }
            else{
             if(fieldName.equalsIgnoreCase('id')){
                whereClause = String.isBlank(WhereClause)? 'WHERE '+fieldName +'=\''+reqBody.get(fieldName)+'\'' : WhereClause+' AND '+fieldName+'=\''+reqBody.get(fieldName)+'\'' ;
            }
                updateOrd.put(fieldName, reqBody.get(fieldName));
        }
           
        }
        if(String.isNotBlank(whereClause))
        query +=' from order '+whereClause+' ALL ROWS' ; 
        system.debug('Query'+query);
        List<Order> existingOrd = Database.query(query);
        if(existingOrd.size()>0){
        if(existingOrd[0].isdeleted)
        {
             IntegrationLogs.add(new Error_Logs__c(Success__c = false, RecordId__c =updateOrd.id,Error_Type__c ='Restricted Party Screening',Object__c = ordStatus ,Error_Message__c='Invalid screeningId',Type__c ='Integration'));  
             resBody ='{"status":"unsuccessful","description":"Cannot update - Order is deleted"}';                          
             res.responseBody =Blob.valueof(resBody); 
             insert IntegrationLogs;
             return ; 
        }
        for(string fieldLabel : ordFieldLabel_Value.keySet()){
            if(existingOrd[0].get(fieldLabel)!=ordFieldLabel_Value.get(fieldLabel)){
                 IntegrationLogs.add(new Error_Logs__c(Success__c = false, RecordId__c =updateOrd.id,Error_Type__c ='Restricted Party Screening',Object__c = ordStatus ,Error_Message__c='Invalid screeningId',Type__c ='Integration'));  
                 resBody ='{"status":"unsuccessful","description":"Invalid screeningId"}';                          
                 res.responseBody =Blob.valueof(resBody); 
                 //insert IntegrationLogs;
                 //return ;
            }
        }
        if(!IntegrationLogs.isEmpty()){
            insert IntegrationLogs;
            return;
        }
        Database.SaveResult Ord_SR = Database.update(updateOrd);
        system.debug('CP After update'+Ord_SR);
        if (Ord_SR.isSuccess()) {
         IntegrationLogs.add(new Error_Logs__c(Success__c = true, Error_Type__c ='Restricted Party Screening',Object__c = ordStatus ,Error_Message__c='Success',
                                  Related_Order__c = updateOrd.id,Type__c ='Integration'));
         resBody ='{"status":"Success"}';                          
         res.responseBody =Blob.valueof(resBody);                         
         
    }
    else {               
        for(Database.Error err : Ord_SR.getErrors()) {
             system.debug('Integration error'+err);
             IntegrationLogs.add(new Error_Logs__c(Success__c = false,RecordId__c =updateOrd.id,Error_Type__c ='Restricted Party Screening',Object__c = ordStatus ,Error_Message__c=err.getMessage(),Type__c ='Integration'));
             res.statusCode = 500;
              resBody ='{"status":"unsuccessful","error description":"'+err.getMessage()+'"}';                          
              res.responseBody =Blob.valueof(resBody);
        }
    }
    }
    else{  // If the Order Id is not present in salesforce
     resBody ='{"status":"unsuccessful","description":"Invalid Order"}';                        
     res.responseBody =Blob.valueof(resBody); 
    }   
    }
    catch(exception excep){
       IntegrationLogs.add(new Error_Logs__c(Success__c = false, RecordId__c =updateOrd.id,Error_Type__c ='Restricted Party Screening',Object__c = ordStatus ,Error_Message__c=excep.getMessage()+ '\nSTACK TRACE : ' +excep.getStackTraceString(),Type__c ='Integration'));  
       res.statusCode = 500;
       resBody ='{"status":"unsuccessful","error description":"'+excep.getMessage()+'"}';                          
       res.responseBody =Blob.valueof(resBody);
    }
    if(IntegrationLogs.size()>0)
    insert IntegrationLogs;
    
        
    }    
}