/**
 * Date : 27th July 2020
 * Desc : CS21-232 : When the NCC expires, a mail is sent to NCCExpiredEmailService so the case updates run logged in as Support Bot
 */
global class NCCExpiryUpdateService implements Messaging.InboundEmailHandler{

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,Messaging.InboundEnvelope env){
     
        // Create an InboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        try{
            string emailBody = email.plainTextBody;
            system.debug('email.plainTextBody--'+email.plainTextBody);
            String matchingCaseId = emailBody.substringAfter('refStart:').substringBefore(':refEnd');
            system.debug('NCC expiry : '+matchingCaseId);
               
            if(String.isNotBlank(matchingCaseId)){
            
                Case parentCase = [SELECT Id, CaseNumber, Owner.Name, Current_Status__c FROM Case WHERE Id = :matchingCaseId or CaseNumber=:matchingCaseId];
                system.debug('NCC parentCaseId: '+parentCase.Id);
                
                if(parentCase != null){
                    parentCase.Last_NCC_Expiry__c = String.ValueOf(parentCase.Owner.Name);
                    parentCase.NCC_Updated__c = false;
                }
                update parentCase;
            }  
        }
        catch (Exception e){
            System.debug('Exception : ' + e);
        }
        
        result.success = true;
        return result;
    }
}