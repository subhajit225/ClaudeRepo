/*
Author: Madhura Tare
JIRA : CPQ22-3936 : Remove Delete capability 
*/

public class OverrideDelQuoteGroup{
    public SBQQ__QuoteLineGroup__c qlg;
    public string retAdd;
    public string delID;
    public string quoteId{get;set;}
    public String runningUser;
    public OverrideDelQuoteGroup(ApexPages.StandardController stdController){ 
        retAdd = ApexPages.CurrentPage().getParameters().get('retURL');
        delID = ApexPages.CurrentPage().getParameters().get('delID');
       
        List<SBQQ__QuoteLineGroup__c> ql= [select id,Name ,SBQQ__Quote__c,SBQQ__Quote__r.Running_User_Record__c from SBQQ__QuoteLineGroup__c where id=:delID];
        if(ql != null & ql.size()>0){
            qlg=ql[0];
            quoteId = ql[0].SBQQ__Quote__c;
            runningUser = ql[0].SBQQ__Quote__r.Running_User_Record__c;
        }
           
    }
    
    public pagereference checksystemGrp(){
        system.debug('@@@ in');
        system.debug('qlg.Name'+qlg.Name);
         system.debug('user Name'+runningUser);
      
               if(qlg != null && (qlg.Name == system.label.Arry_expansion_group ||  qlg.Name == system.label.Arry_Disposition_Group || qlg.Name == system.label.Arry_renewal_Group) && runningUser!= 'CPQ Admin'){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,system.label.QuoteGrpDelmsg);
                ApexPages.addMessage(myMsg);
                 return null;
               }else{
                   delete qlg;
                   PageReference pocPage = new PageReference('/' + quoteId);
        pocPage.setRedirect(true);
        return pocPage;
               }
               
           
    } 
    
    
     public pageReference cancelDel(){
        PageReference pocPage = new PageReference('/' + quoteId);
        pocPage.setRedirect(true);
        return pocPage;
    }
}