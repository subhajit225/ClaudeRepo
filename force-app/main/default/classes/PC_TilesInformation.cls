public without sharing class PC_TilesInformation {
    @AuraEnabled
    public static decimal claimDetails(){
        string LoggedinEmail;
        decimal totalAmount=0;
        User u=[select id ,email from user where id=:UserInfo.getUserID()];
        if(!string.isblank(u.email)){
            LoggedinEmail=u.email;
            system.debug('@@ LoggedinEmail '+LoggedinEmail); 
            for(CCR__c cr:[select id,Incentive__c,Partner_Rep_Email__c,Partner_REP_Amount__c,Partner_SE_Amount__c,Partner_SE_Email__c from CCR__c]){
                if(LoggedinEmail==cr.Partner_Rep_Email__c && cr.Partner_REP_Amount__c!=null ){
                    totalAmount+=cr.Partner_REP_Amount__c;
                }
                if( LoggedinEmail==cr.Partner_SE_Email__c && cr.Partner_SE_Amount__c!=null){
                    totalAmount+=cr.Partner_SE_Amount__c;
                }
            }
			system.debug('@@ totalAmount '+totalAmount);           
        }
        return totalAmount;
    }
}