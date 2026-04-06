/*
Author: Palak Agarwal 
JIRA : SF-1680 : Remove Delete capability 
*/

public class OverrideDelQuoteLine{
    public SBQQ__QuoteLine__c qli;
    public string retAdd;
    public string delID;
    public string quoteId{get;set;}
    public OverrideDelQuoteLine(ApexPages.StandardController stdController){ 
        retAdd = ApexPages.CurrentPage().getParameters().get('retURL');
        delID = ApexPages.CurrentPage().getParameters().get('delID');
        //qli = (SBQQ__QuoteLine__c)stdController.getRecord();
        List<SBQQ__QuoteLine__c> ql= [select id, SBQQ__Quote__c from SBQQ__QuoteLine__c where id=:delID];
        if(ql != null & ql.size()>0){
            qli=ql[0];
            quoteId = ql[0].SBQQ__Quote__c;
        }
           
    }
    
    public pagereference checkProfAndDel(){
        system.debug('@@@ in');
        List<Profile> prof = [select id from profile where name = 'Sales Operations' OR name ='System Administrator' OR name ='Deal Operations'];
        
        if(prof != null && prof.size()>0){
            
            if(userinfo.getProfileId() == prof[0].id || (prof.size() >1 && userinfo.getProfileId() == prof[1].id) || (prof.size() >1 && userinfo.getProfileId() == prof[2].id)){
               
                
                if(qli != null){
                    delete qli;
                    String retAdd1 = String.isBlank(retAdd) ? null : String.escapeSingleQuotes(retAdd.escapeHtml4());
                    PageReference pocPage = null;
                    if(UserInfo.getUiThemeDisplayed() != 'Theme3'){
                    	 pocPage = null;
                         aura.redirect(pocPage);
                    }
                    else{
                         pocPage = new PageReference('/' + retAdd1);
                         pocPage.setRedirect(true);
                    }
                     system.debug('@@@ in2');
                    return pocPage;
                }else
                    return null;
            }else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,system.label.QuoteLineDelMessage);
                ApexPages.addMessage(myMsg);
                return null;
            }
        }else{
         return null;
        }
    } 
    
    
     public pageReference cancelDel(){
        PageReference pocPage = new PageReference('/' + quoteId);
        pocPage.setRedirect(true);
        return pocPage;
    }
}