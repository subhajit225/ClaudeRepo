Public Class OppWithTrainingOrderProduct{
   
    @InvocableMethod      
      public static void relatedOpp(List<Id> OrderIds){          
          List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
          
          EmailTemplate templateId = [Select id,developername from EmailTemplate where developername = 'Notification_for_Training_Product'];
          OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'donotreply@rubrik.com'];
          for(OrderItem oItem: [Select Id,product2.name,product2.Product_Type__c,orderId,order.status From orderItem where orderId IN :orderIds]){
                if(oItem.product2.name.containsIgnoreCase('RBK-SVC-TRN') || oItem.Product2.Product_Type__c == 'Training'){
                        
                        Messaging.SingleEmailMessage mail      = Messaging.renderStoredEmailTemplate(templateid.id ,null, oItem.id);
                        String[] sendingToAdd                  = new String[]{System.Label.TrainingInfo};  
                        mail.setToAddresses(sendingToAdd);                        
                         
                         if (owea.size() > 0 ) mail.setOrgWideEmailAddressId(owea.get(0).Id);                       
                        mail.setSaveAsActivity(false);
                        mail.setWhatId(oItem.id);
                        allmsg.add(mail);       
                  }    
               }     
            
         Messaging.sendEmail(allmsg,true);
      }
}