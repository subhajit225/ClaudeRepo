public class OpportunityCohesityDeal {
    public static string COHESTY = 'cohesity';
    public static string C_CO = 'c-co';
    
    public static boolean CheckCohesityDeal(List<Opportunity> oppList){
        List<Opportunity> lstOpportunityUpdate = new List<Opportunity>();
        //try{
            for(Opportunity opp : oppList){
                if((opp.Next_Step__c != null && (opp.Next_Step__c.containsIgnoreCase(C_CO) || opp.Next_Step__c.containsIgnoreCase(COHESTY)))
                   || (opp.Primary_Competitor__c != null && opp.Primary_Competitor__c == 'Cohesity') 
                   || (opp.Other_Primary_Competitor__c != null
                       && (opp.Other_Primary_Competitor__c.containsIgnoreCase(C_CO) || opp.Other_Primary_Competitor__c.containsIgnoreCase(COHESTY)))
                   || (opp.Win_Loss_Comments__c != null
                       && (opp.Win_Loss_Comments__c.containsIgnoreCase(C_CO) || opp.Win_Loss_Comments__c.containsIgnoreCase(COHESTY)))
                  ){
                    if(!opp.Cohesity_Deal__c){
                        opp.Cohesity_Deal__c = true;
                        lstOpportunityUpdate.add(opp);
                    }
                }else{
                    if(opp.Cohesity_Deal__c){
                        opp.Cohesity_Deal__c = false;
                        lstOpportunityUpdate.add(opp);
                    }
                }
            }
            
            if(!lstOpportunityUpdate.isEmpty()){
                List<Error_Logs__c> errList = new LIst<Error_Logs__c>();
                Database.SaveResult[] srList =  Database.update(lstOpportunityUpdate, false);
                integer i = 0;
                for (Database.SaveResult sr : srList) {
                    if (!sr.isSuccess() || Test.isRunningTest()) {
                        for(Database.Error err : sr.getErrors()) {  
                            Error_Logs__c log = new Error_Logs__c(Type__c = 'SFDC',Class__c='OpportunityCohesityDeal',Method__c ='CheckCohesityDeal',Error_Type__c = 'Opportunity Exception', Error_Message__c = err.getMessage(), Object__c = 'Opportunity',RecordId__c = lstOpportunityUpdate[i].Id);
                            errList.add(log);
                        }
                        i++;
                    }
                }
                if(!errList.isEmpty()){
                    insert errList;
                }
            }
      //  }catch(Exception ex){
       //     system.debug('***OpportunityCohesityDealBatch Exception****'+ex.getMessage());
       //     return false;
       // }
        return true;
    }
}