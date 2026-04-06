public Without Sharing class OpportunityRubrikInitiatedDeal {
    Opportunity currentOpp{get;set;}
    string btnClicked ;
    public OpportunityRubrikInitiatedDeal(ApexPages.StandardController controller) {
        currentOpp = (Opportunity) controller.getRecord(); 
        system.debug('currentOpp =='+currentOpp.id);
        btnClicked = '';
        if(apexpages.currentpage().getparameters().get('type') != null){
        btnClicked = apexpages.currentpage().getparameters().get('type');
        }
        system.debug('btnClicked =='+btnClicked);
    }
    
    public pagereference saveOpp(){
    try{
        Opportunity Opp =[select id,Name,Partner__c,Partner_Lookup__C, Deal_Registration_Type__c, Partner_Rep_Email_Address__c,Partner_Rep_Phone_Number__c,Partner_Rep_Title__c,Deal_Reg_Approval_Status__c, Partner_Representative__c, Deal_Registration__c, Deal_Reg_Expiration_Date__c, Deal_Registration_Number__c,Deal_Reg_Submitted_Date__c, Deal_Reg_Approval_Timestamp__c from Opportunity where Id=:currentOpp.id];
         //opp.Partner__c=  currentOpp.Partner__C;
         opp.Partner_Lookup__c=  currentOpp.Partner_Lookup__C;
         opp.Partner_Rep_Title__c=  currentOpp.Partner_Rep_Title__c;
         opp.Partner_Rep_Email_Address__c =  currentOpp.Partner_Rep_Email_Address__c;
         opp.Partner_Rep_Phone_Number__c=  currentOpp.Partner_Rep_Phone_Number__c;
         opp.Deal_Registration__c = true;
         opp.Deal_Reg_Approval_Status__c ='Approved';
         if(btnClicked == 'RID')
         opp.Deal_Registration_Type__c = 'Rubrik Sourced';
         else if(btnClicked == 'JID')
         opp.Deal_Registration_Type__c = 'Partner Sourced Expand';
         opp.Partner_Representative__c = currentOpp.Partner_Representative__c;
         String Month = System.Now().Month()<10? '0'+String.vAlueof(System.Now().Month()): String.vAlueof(System.Now().Month());
         opp.Deal_Registration_Number__c =  String.ValueOf(System.Now().Year())+Month+String.ValueOf(System.Now().Day())+' '+String.ValueOf(System.Now().Hour())+String.ValueOf(System.Now().minute())+String.ValueOf(System.Now().second());
         system.debug('opp.Deal_Registration_Number__c =='+opp.Deal_Registration_Number__c);
         opp.Deal_Reg_Expiration_Date__c =  system.Today().addDays(90);
         opp.Deal_Reg_Approval_Timestamp__c=  system.NOw();
         opp.Deal_Reg_Submitted_Date__c=  system.NOw();
         update opp;
         return new pagereference('/'+Opp.Id);
         }
         catch(Exception ex){
             system.debug(ex);
             return null;
         }
        
            
    }

}