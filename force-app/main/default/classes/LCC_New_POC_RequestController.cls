public class LCC_New_POC_RequestController {
    public string oppId{get;set;}
    public string initialConId{get;set;}  
    public boolean termsValidation{get;set;}
  
	public LCC_New_POC_RequestController(ApexPages.StandardSetController stdSetController) {

	}
    public PageReference loadPOCmethod(){
        List<Opportunity> oppList = new List<Opportunity>();
        oppId = apexpages.currentPage().getParameters().get('id');
        oppList = [select Id,Name,Initial_Contacts_Name__c,Agreed_to_POC_terms_Validation__c from opportunity where Id =:oppId];
        system.debug('@@ oppList '+oppList);
        PageReference pg = new PageReference('/apex/POCRequest?CF00N40000003KTOe='+oppList[0].Name+'&CF00N40000003KTOe_lkid='+oppList[0].Id+'&save_new=1&sfdc.override=1');
        String uiThemeDisplayed = UserInfo.getUiThemeDisplayed();
        if(uiThemeDisplayed != 'Theme3'){  // Lightning Theme Value          
               aura.redirect(pg);
        }else{
            pg.setRedirect(true);
        }
        return pg;
    }
}