trigger RMAOrderMain on RMA_Order__c (before update, after insert ,after update,before insert) {
    ShGl_DisableFunctionalityLogic__c disableFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance();
    system.debug('@@ disableFuncCS.Disable_old_RMA_Trigger__c '+disableFuncCS.Disable_old_RMA_Trigger__c);
    if(!disableFuncCS.Disable_old_RMA_Trigger__c){
        List<RMA_Order__c> RMAOrderList = new List<RMA_Order__c>();
        Set<Id> RMAOrderListToResendFlashEmails = new Set<Id>();
        Set<Id> RMAIdsSmarthandremovedEmails = new Set<Id>();
        Set<Id> RMAIdsResendButton = new Set<Id>();
        Set<Id> RMAIdsUpsertTechOrder = new Set<Id>();
        string valflag;
        if(trigger.isInsert && trigger.isAfter){
            for(RMA_Order__c RMA : Trigger.New){
                if(RMA.Status__c=='Approved'){
                RMAOrderList.add(RMA);
                }
            }
        }
        if(trigger.isUpdate && trigger.isBefore){
            //Logic updated for PRDOPS21_436
            for(RMA_Order__c RMA : Trigger.New){
                 if(RMA.Additional_Interested_Parties_RMA__c !=NULL){
                        String emailRegex = '^[a-zA-Z][a-zA-Z0-9]*(?:[\\.|\\-|\\_][a-zA-Z0-9]+)*@[rR][uU][bB][rR][iI][kK].[cC][oO][mM](?:,[a-zA-Z][a-zA-Z0-9]*(?:[\\.|\\-|\\_][a-zA-Z0-9]+)*@[rR][uU][bB][rR][iI][kK].[cC][oO][mM])*$';
                        Pattern EmailPattern = Pattern.compile(emailRegex);
                        Matcher EmailMatcher = EmailPattern.matcher(RMA.Additional_Interested_Parties_RMA__c );
                        if(!EmailMatcher.matches())
                        {
                            RMA.addError('Please Enter comma seperated Rubrik email Address');
    
                        }
                   }
                if(checkRecursive.runOnce() && RMA.Status__c=='Approved' && //&& RMA.Send_Smart_Hands_Service__c ==true &&
                    ((RMA.Send_Smart_Hands_Service__c !=trigger.oldMap.get(RMA.Id).Send_Smart_Hands_Service__c) ||
                     (RMA.Date_of_Smart_Hands_Arrival__c != null && trigger.oldMap.get(RMA.Id).Date_of_Smart_Hands_Arrival__c != RMA.Date_of_Smart_Hands_Arrival__c))) {
                         RMA.Smart_Hands_Change_Requested__c =true;
                         RMA.Status__c ='Submitted';
                     }
            }
        }
    
        if(trigger.isUpdate && trigger.isAfter){
            for(RMA_Order__c RMA : Trigger.New){
                if(checkRecursive.runAfterOnce()){
                    if((RMA.Status__c != trigger.oldMap.get(RMA.Id).Status__c) && RMA.Status__c=='Approved' && RMA.Smart_Hands_Change_Requested__c ==false){
                        RMAOrderList.add(RMA);
                    }
    
                    if (RMA.Status__c!= trigger.oldMap.get(RMA.Id).Status__c && RMA.Status__c=='Approved' && RMA.Smart_Hands_Change_Requested__c ==true) {
                        if(RMA.Send_Smart_Hands_Service__c == true ||(RMA.Date_of_Smart_Hands_Arrival__c != null && trigger.oldMap.get(RMA.Id).Date_of_Smart_Hands_Arrival__c != RMA.Date_of_Smart_Hands_Arrival__c)){
                            RMAOrderListToResendFlashEmails.add(RMA.Id);
                        }
                        else if(RMA.Send_Smart_Hands_Service__c == false )
                        {
                            RMAIdsSmarthandremovedEmails.add(RMA.Id);
                        }
                    }
                    else if (RMA.Valid_Support__c == True && RMA.Entitled_for_Smart_Hands_Service__c ==True && RMA.Status__c == 'Submitted' && RMA.Smart_Hands_Change_Requested__c ==true) // Auto Approved
                        {
                            if(RMA.Send_Smart_Hands_Service__c == true ||(RMA.Date_of_Smart_Hands_Arrival__c != null && trigger.oldMap.get(RMA.Id).Date_of_Smart_Hands_Arrival__c != RMA.Date_of_Smart_Hands_Arrival__c)){
                                RMAOrderListToResendFlashEmails.add(RMA.Id);
                            }
                            else if(RMA.Send_Smart_Hands_Service__c == false )
                            {
                                RMAIdsSmarthandremovedEmails.add(RMA.Id);
                            }
    
                        }
                   else if(RMA.Resend_Flash_Email__c == true){
                        RMAIdsResendButton.add(RMA.Id);
                        }
                        /*
                            @Author: Sukesh K
                            @Description: for DGWD-17
                            update techOrder
                        */
                        if ( RMA.Send_Smart_Hands_Service__c != Trigger.oldMap.get(RMA.Id).get('Send_Smart_Hands_Service__c')) {
                            if (RMA.Send_Smart_Hands_Service__c) {
                                RMAIdsUpsertTechOrder.add(RMA.Id);
                            }
                        }
                     }
    
    
        }
    }
        if(!RMAOrderList.isEmpty()) {
            RMAOrderService.createOrder(RMAOrderList);
        }
        if(!RMAOrderListToResendFlashEmails.isEmpty()) {
            RMAOrderService.updateRelatedOrders(RMAOrderListToResendFlashEmails);
        }
        if(!RMAIdsSmarthandremovedEmails.isEmpty()) {
            RMAOrderService.smartHandRemovedEmails(RMAIdsSmarthandremovedEmails);
        }
        if(!RMAIdsResendButton.isEmpty()) {
            RMAOrderService.mailOnResendButton(RMAIdsResendButton);
        }
        if (!RMAIdsUpsertTechOrder.isEmpty()) {
            RMAOrderService.upsertTechOrders(RMAIdsUpsertTechOrder);
        }
    }else{
         if(flowControll.RMATriggerHandler){
            new RMAOrderTriggerHandler().run();
        }
    }

}