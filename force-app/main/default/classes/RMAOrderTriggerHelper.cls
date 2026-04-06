public class RMAOrderTriggerHelper {
    public static final string DATETIME_CHANGE = 'DATETIME_CHANGE_REQUESTED'; 
    public static void checkRecordApprovedOnInsert(List<RMA_Order__c> newList){
        List<RMA_Order__c> RMAOrderList = new List<RMA_Order__c>();
        for(RMA_Order__c RMA : newList){
            if(RMA.Status__c=='Approved'){
                RMAOrderList.add(RMA);
            }
        }
        if(!RMAOrderList.isEmpty()) {
            RMAOrderService.createOrder(RMAOrderList);
        }
    }
    public static void checkEmailRegex(Map<Id,RMA_Order__c> oldMap,List<RMA_Order__c> newList){
        for(RMA_Order__c RMA : newList){
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
               ((RMA.Send_Smart_Hands_Service__c !=oldMap.get(RMA.Id).Send_Smart_Hands_Service__c) ||
                (RMA.Date_of_Smart_Hands_Arrival__c != null && oldMap.get(RMA.Id).Date_of_Smart_Hands_Arrival__c != RMA.Date_of_Smart_Hands_Arrival__c) ||
                (RMA.Time_of_Smart_Hands_Tech_Arrival__c != null && oldMap.get(RMA.Id).Time_of_Smart_Hands_Tech_Arrival__c != RMA.Time_of_Smart_Hands_Tech_Arrival__c))) {
                    RMA.Smart_Hands_Change_Requested__c =true;
                    RMA.Status__c ='Submitted';
            }
            //PRODOPS23-19
            if(oldMap.get(RMA.Id).Send_Smart_Hands_Service__c == true && 
               ((RMA.Date_of_Smart_Hands_Arrival__c != null && oldMap.get(RMA.Id).Date_of_Smart_Hands_Arrival__c !=null && oldMap.get(RMA.Id).Date_of_Smart_Hands_Arrival__c != RMA.Date_of_Smart_Hands_Arrival__c) ||
                (RMA.Time_of_Smart_Hands_Tech_Arrival__c != null && oldMap.get(RMA.Id).Time_of_Smart_Hands_Tech_Arrival__c != null &&oldMap.get(RMA.Id).Time_of_Smart_Hands_Tech_Arrival__c != RMA.Time_of_Smart_Hands_Tech_Arrival__c))){
                    RMA.Flash_Email_History__c = RMA.Flash_Email_History__c + '\n' + DATETIME_CHANGE;
                }
        }    
    }
    public static void checkRecordApprovedOnUpdate(Map<Id,RMA_Order__c> oldMap,List<RMA_Order__c> newList){
        List<RMA_Order__c> RMAOrderList = new List<RMA_Order__c>();
        Set<Id> RMAOrderListToResendFlashEmails = new Set<Id>();
        Set<Id> RMAIdsSmarthandremovedEmails = new Set<Id>();
        Set<Id> RMAIdsResendButton = new Set<Id>();
        Set<Id> RMAIdsUpsertTechOrder = new Set<Id>();
        for(RMA_Order__c RMA : newList){
            if(checkRecursive.runAfterOnce()){
                if((RMA.Status__c != oldMap.get(RMA.Id).Status__c) && RMA.Status__c=='Approved' && RMA.Smart_Hands_Change_Requested__c ==false){
                    RMAOrderList.add(RMA);
                }
                if (RMA.Status__c!= oldMap.get(RMA.Id).Status__c && RMA.Status__c=='Approved') {
                    if(RMA.Send_Smart_Hands_Service__c == true && RMA.Flash_Email_History__c != null && RMA.Flash_Email_History__c.contains(DATETIME_CHANGE)){
                        RMAOrderListToResendFlashEmails.add(RMA.Id);
                    }
                    else if(RMA.Send_Smart_Hands_Service__c == false && RMA.Smart_Hands_Change_Requested__c ==true )
                    {
                        RMAIdsSmarthandremovedEmails.add(RMA.Id);
                    }
                }
                else if (RMA.Valid_Support__c == True && RMA.Entitled_for_Smart_Hands_Service__c ==True && RMA.Status__c == 'Submitted') // Auto Approved
                {
                    if(RMA.Send_Smart_Hands_Service__c == true && RMA.Flash_Email_History__c != null && RMA.Flash_Email_History__c.contains(DATETIME_CHANGE)){
                        RMAOrderListToResendFlashEmails.add(RMA.Id);
                    }
                    else if(RMA.Send_Smart_Hands_Service__c == false && RMA.Smart_Hands_Change_Requested__c ==true)
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
                if ( RMA.Send_Smart_Hands_Service__c != oldMap.get(RMA.Id).get('Send_Smart_Hands_Service__c')) {
                    if (RMA.Send_Smart_Hands_Service__c) {
                        RMAIdsUpsertTechOrder.add(RMA.Id);
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
    }
	public static void populateSmartHandsProvider(List<RMA_Order__c> newList){
        Map<String, List<String>> countryStateMap = new Map<String, List<String>>();
        Map<String, Country_With_State_RMARequest__mdt> countryStateRMAMap = new Map<String, Country_With_State_RMARequest__mdt>();
        List<Country_With_State_RMARequest__mdt> countryRMARequestList = Country_With_State_RMARequest__mdt.getAll().values();
        for(Country_With_State_RMARequest__mdt countryStateMdt : countryRMARequestList){
            if(countryStateMdt.Country__c != null){
                countryStateRMAMap.put(countryStateMdt.Country__c, countryStateMdt);
                countryStateMap.put(countryStateMdt.Country__c, new List<String>{});
                if (countryStateMdt.State__c != null) {
                    String state = countryStateMdt.State__c;
                    List<String> stateList = state.split(',');
                    countryStateMap.get(countryStateMdt.Country__c).addall(stateList);
                }
            }
        }
        
        for(RMA_Order__c RMA : newList){
            if(countryStateMap.containsKey(RMA.ShippingCountry__c) && (countryStateMap.get(RMA.ShippingCountry__c).contains(RMA.ShippingState__c) || countryStateMap.get(RMA.ShippingCountry__c).isEmpty())){
            	RMA.Smart_Hands_Provider__c = countryStateRMAMap.get(RMA.ShippingCountry__c).Vendor__c;
            }
            else{
                RMA.Smart_Hands_Provider__c = 'Flash Global';
            }
        }
    }
}