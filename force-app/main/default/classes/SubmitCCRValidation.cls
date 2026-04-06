/**
 * @description SubmitCCRValidation 
 **/
global class SubmitCCRValidation{
  global static final string RETURNREFUNDERROR1 ='Select atleast one booking adjustment record before processing for approval of Type Customer Returns/Refunds';
  global static final string RETURNREFUNDERROR2 ='Return Reasons and Comments are required to submit for Approval';
  global static final string PARTNERREFERRALERROR1 ='Partner Company Name is required and should not be same as Account Name'; 
  global static final string PARTNERREFERRALERROR2 = 'If Booking is populated,it should be a OriginalBooking related to Opportunity & Account should be the Account on Booking';
  global static Id VPManagerId;
  /**
  * @description ApprovalValidation 
  * @param CCRId
  * @return string
 **/
  webService static string ApprovalValidation(Id CCRId){     
          CCR__c ccrRec = [select id,Manager_at_VP_level__c,Affective_Person__r.id,Customer_Returns_Type__c,OwnerId,Affective_Person__r.UserRole.Name,Return_Reasons__c,Comment__c,BookingAdjustmentCount__c,Account_Name__r.Id,CCR_Type__c,Opportunity__r.Owner.Id,Booking__r.RecordType.Name,Booking__r.Opportunity__r.Id,Booking__r.Account_Name__r.Id,Opportunity__c,Booking__c,Referral_Fee_Amount__c,Partner_Company_Name__c,Partner_Company_Name__r.Id,Impacts_Commission__c,Affective_Person__c from ccr__c where id=:CCRId];
            if(Constants.CCR_TYPES.contains(ccrRec.CCR_Type__c)
            ){
                
                 if(ccrRec.BookingAdjustmentCount__c < 1 && ccrRec.Customer_Returns_Type__c!=null && ccrRec.Customer_Returns_Type__c.equalsIgnoreCase('LineItem Based')){
                     return RETURNREFUNDERROR1;  
                 }else if(ccrRec.Comment__c == NULL || ccrRec.Return_Reasons__c == NULL){
                     return RETURNREFUNDERROR2;
                 }
                 if(ccrRec.Affective_Person__r.id != NULL){
                     if(!ccrRec.Affective_Person__r.UserRole.Name.contains('VP')){
                         getVPManager(ccrRec.Affective_Person__r.id);
                         if(VPManagerId != NULL){
                             ccrRec.Manager_at_VP_level__c=VPManagerId;
                         }
                         update ccrRec;
                     }
                 }
            }else if(ccrRec.CCR_Type__c.equalsIgnoreCase('Partner Referral Fee')){
                if(ccrRec.Partner_Company_Name__c == NULL || ccrRec.Partner_Company_Name__r.Id == ccrRec.Account_Name__r.Id ){
                    return PARTNERREFERRALERROR1;
                }else if(ccrRec.Booking__c != NULL && ( (ccrRec.Booking__r.Opportunity__r.Id != ccrRec.Opportunity__r.Id || ccrRec.Booking__r.RecordType.Name != 'Booking') || (ccrRec.Account_Name__r.Id != ccrRec.Booking__r.Account_Name__r.Id) ) ){
                    return PARTNERREFERRALERROR2;
                }
            }
            return 'No error';
        
  }

  /**
  * @description getVPManager 
  * @param AffectedPersonId
 */
  global static void getVPManager(Id AffectedPersonId){
        List<User> usrs = [select id,Name,UserRole.DeveloperName,Manager.UserRole.DeveloperName,ManagerId,
                                                                 Manager.Manager.UserRole.DeveloperName,Manager.ManagerId,
                                                                 Manager.Manager.Manager.UserRole.DeveloperName,Manager.Manager.ManagerId,
                                                                 Manager.Manager.Manager.Manager.UserRole.DeveloperName,Manager.Manager.Manager.ManagerId
                          FROM user where Id= :AffectedPersonId];
        for(User usr : usrs){
            if(String.isNotBlank(usr.Manager.UserRole.DeveloperName) && usr.ManagerId != NULL){
                if(usr.Manager.UserRole.DeveloperName.contains('VP')){
                    VPManagerId = usr.ManagerId;
                    break;
                }else{
                    if(String.isNotBlank(usr.Manager.Manager.UserRole.DeveloperName) && usr.Manager.ManagerId != NULL){
                        if(usr.Manager.Manager.UserRole.DeveloperName.contains('VP')){
                            VPManagerId = usr.Manager.ManagerId;
                            break;
                        }else{
                             if(String.isNotBlank(usr.Manager.Manager.Manager.UserRole.DeveloperName) && usr.Manager.Manager.ManagerId != NULL){
                                 if(usr.Manager.Manager.Manager.UserRole.DeveloperName.contains('VP')){
                                     VPManagerId = usr.Manager.Manager.ManagerId;
                                     break;
                                }else{
                                     if(String.isNotBlank(usr.Manager.Manager.Manager.Manager.UserRole.DeveloperName) && usr.Manager.Manager.Manager.ManagerId != NULL){
                                         if(usr.Manager.Manager.Manager.Manager.UserRole.DeveloperName.contains('VP')){
                                             VPManagerId = usr.Manager.Manager.Manager.ManagerId;
                                             break;
                                         }else{
                                             getVPManager(usr.Manager.Manager.Manager.ManagerId);                                           
                                         }      
                                    }else{
                                         break;
                                    }             
                                } 
                            }else{
                                break;
                            }                   
                        }
                    }else{
                        break;
                    }
                }
            }else{
                break;
            }
        }
  }
}