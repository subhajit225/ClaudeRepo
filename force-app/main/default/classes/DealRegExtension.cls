public without sharing class DealRegExtension {

    // decalartion of the lead instance
    public Deal_Registration__c vDealReg;
    public User partner;
    public Boolean disable{get;set;}

    //list for state and country values
    public list<SelectOption> countryPickList{get; set;}
    public list<selectOption> statePickList{get; set;}
    public boolean blnMandatory {get;set;}
    //redirection page object after submit is clicked
    public pagereference newpg;
    public static boolean errordr {get; set;}
    public static boolean errordrpartner {get; set;}
    public LeadShare shares { get; private set; }    
    public boolean isRequired {get; set;}
    public boolean isDisty {get; set;}


    // constructor
    public DealRegExtension(ApexPages.StandardController stdController) {
	    vDealReg = (Deal_Registration__c) stdController.getRecord();
	    blnMandatory=false;
	    errordr = false;
	    isRequired = true;
	    
	    partner = [select Id, Name, Email, Phone,AccountID,Contact.Account.Distributor__c, Contact.Account.Distributor__r.Name, Contact.Account.Name, CompanyName,Contact.Account.Type from User where id=:UserInfo.getUserId()];
	    
	    System.debug('Partner: '+partner);
	    
	    //vDealReg.Partner_Rep__c = UserInfo.getName();
	    //removing the "Promark" condition, as it should only have Distributor check per Gregg
	    if(partner.Contact.Account.Type =='Distributor' ){
	    		isDisty= true;
	    } else {
	    		isDisty= false;
	    }
	    
	    if(!isDisty){
	        vDealReg.Partner_Rep_Email_Address__c = UserInfo.getUserEmail();
            // SF-212: commented below code
	        /*if(partner.CompanyName != null){
	            vDealReg.Partner__c = partner.CompanyName;
	        }
	        else*/ 
            if(partner.Contact.Account.Name != null){
	            vDealReg.Partner__c = partner.Contact.Account.Name;
	        }
	        
	        if(partner.AccountID != null)
	        vDealReg.Partner_Lookup__c = partner.AccountId;
	        system.debug('partner.AccountId=='+partner.AccountId);
	        system.debug('partner.Account.Distributor__c=='+partner.Contact.Account.Distributor__c);
	        if(partner.Contact.Account.Distributor__c != null)
	        vDealReg.Distributor_Company_Name__c	 = partner.Contact.Account.Distributor__r.Name;
	        vDealReg.Distributor__c = partner.Contact.Account.Distributor__c; 
	        system.debug('test in not promark');
	        
	    } else {
	    		 vDealReg.Distributor__c = partner.Contact.Account.Id; 
	    		 vDealReg.Distributor_Company_Name__c= partner.Contact.Account.Name;	    	
	    }
	    
	    
	    //makeCityMandatory();
	    populateCountryPickList();
	    populateStatesPickList();
    }//end constructor

    //to populate country picklist from custom settings.
    public list<SelectOption> populateCountryPickList(){

        countryPickList = new List<SelectOption>();
        countryPickList.add( new SelectOption('','Select...'));
        for (Countries__c countryInstance : [SELECT Name
                                               FROM Countries__c
                                           ORDER BY Name ASC]) {
            countryPickList.add( new SelectOption(
                countryInstance.Name,
                countryInstance.Name
            ));
        }
        return countryPickList;
    }//end populateCountryPickList
    
    
    
    public void updateStateSelection(){
        if(vDealReg.Country__c != 'USA' || vDealReg.Country__c != 'US' || vDealReg.Country__c != 'United States'){
            
            //vDealReg.State__c = 'International';
        }
        else{
            //vDealReg.State__c = '';
        }
    }

	////to populate state picklist from custom settings.
    public list<SelectOption> populateStatesPickList(){

        statePickList = new List<SelectOption>();
        statePickList.add( new SelectOption('','Select...'));
        for (States__c stateInstance : [SELECT Name
                                          FROM States__c
                                      ORDER BY Name ASC]) {
            statePickList.add( new SelectOption(
                stateInstance.Name,
                stateInstance.Name
            ));
        }
        return statePickList;
    }//end populateStatesPickList

    
    // method to insert lead and adding the same to a campaign as a campaign member. 
    public PageReference save() {
         disable=true;
        // logic to save lead regardless of the duplicate Lead/Contact.
        //Database.DMLOptions dml = new Database.DMLOptions();
        //dml.DuplicateRuleHeader.AllowSave = true;
        
        // assigning values to lead.
        vDealReg.Deal_Registration_Status__c = system.label.Deal_Reg_Status;
        //vDealReg.Lead_Type__c = system.label.LEAD_TYPE_PROSPECT;
        vDealReg.Lead_Source_Details__c = system.label.Lead_Source_Detail;
        vDealReg.Deal_Reg_Submitted_Date__c = system.now();
        vDealReg.Lead_Source__c = system.label.LEAD_SOURCE_CHANNEL;
        //vDealReg.Deal_Registration__c = true;
        vDealReg.Deal_Registration_Type__c = DealRegUtilityHelper.PID;
       
        
        system.debug('vDealReg---'+vDealReg);
        try {
            //insert vDealReg;
          
	    		Database.DMLOptions dml = new Database.DMLOptions();
			dml.DuplicateRuleHeader.allowSave = true;
			dml.DuplicateRuleHeader.runAsCurrentUser = true; 
	        Datacloud.DuplicateResult duplicateResult;
	        List<Datacloud.MatchRecord> matchRecords;
           
	        Database.SaveResult sr = Database.insert(vDealReg, dml);
            
        } catch (DmlException exceptionInstance) {

            errordr = true;                    
            system.debug('### error message'+ exceptionInstance);
            return null;
        }//end catch
        
         
		system.debug('#### Lead 222---'+vDealReg);
		//to redirect to the leads detail page after successful submittion.
        if(vDealReg.Id <> Null){
              newpg = Page.SubmitThanks;
             newpg.getParameters().put('type', 'dealreg');
        }//end if
        
        return newpg;
    }//end save

	
	//to set state field mandatory
    public void makeStateMandatory(){
        blnMandatory=true;
    }//end makeStateMandatory

	
	//to set state field not mandatory   
   public void makeStateNotMandatory(){
        blnMandatory=false;
    }//end makeStateNotMandatory
    
    
    
    public void isItRequired(){
      if(vDealReg.Country__c == 'USA' || vDealReg.Country__c== 'United States' || vDealReg.Country__c == 'CA'  || vDealReg.Country__c == 'Canada'){
        isRequired = true;
      }else{
        isRequired = false;
      }
    }
    
    public void fetchPartnerAccount(){
        List<Contact> partnerContactList = new List<Contact>();
        if(vDealReg.Partner_Rep_Email_Address__c != null){
                 partnerContactList =[select id,name, AccountId,Account.Name,Account.Distributor__c from contact where email=: vDealReg.Partner_Rep_Email_Address__c]; 
            }
            if(!partnerContactList.isEmpty()){
                if(partnerContactList[0].AccountID != null)
                vDealReg.Partner_Lookup__c = partnerContactList[0].AccountId;
                vDealReg.Partner__c = partnerContactList[0].Account.Name;
                system.debug('partner.AccountId=='+partnerContactList[0].AccountId);
                system.debug('partner.Account.Distributor__c=='+partnerContactList[0].Account.Distributor__c);
                if(partnerContactList[0].Account.Distributor__c != null)
                vDealReg.Distributor__c = partnerContactList[0].Account.Distributor__c;
                errordrpartner= false;
            }
            else{
                vDealReg.Partner_Lookup__c=null;
                vDealReg.Partner__c='';
                vDealReg.Distributor__c=null;
                errordrpartner= true;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'User not found. Please visit https://partner.rubrik.com to request Partner Portal access for this user to continue. For questions, please email GoForward@Rubrik.com'));
            }
    }
    
}//end class