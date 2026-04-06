/**
 * @description Controller extension for Opportunity Visualforce page.
 *              Populates Opportunity fields using URL parameters.
 */
Public class OpportunityOverrideClass{
    /**
     * @description 
     * Public property to hold the Opportunity record.
     */
	public Opportunity Opp { get; set; }
    /**
     * @description 
     * Constructor that initializes Opportunity record 
     *              and populates fields using URL parameters.
     * @param controller StandardController for Opportunity object.
     */
    public OpportunityOverrideClass(ApexPages.StandardController controller) {
		this.Opp = (Opportunity)controller.getRecord();
        populateOpportunityFromParams();
    }
    /**
     * @description Populates Opportunity fields using parameters from the current page URL.
     */
    private void populateOpportunityFromParams() {
        Map<String, String> urlParams = ApexPages.currentPage().getParameters();

        String contactId = urlParams.get('contactId');
        String accountId = urlParams.get('AccId');
        String leadSource = urlParams.get('conLead');
        String accountName = urlParams.get('AccName');

        if (String.isNotBlank(contactId)) {
            Opp.Initial_Contacts_Name__c = contactId;
        }

        if (String.isNotBlank(accountId)) {
            Opp.AccountId = accountId;
        }

        Opp.ForecastCategoryName = 'Best Case';

        if (String.isNotBlank(leadSource)) {
            Opp.LeadSource = leadSource;
        }

        Opp.Name = (String.isNotBlank(accountName) ? accountName : '') + '-';
        Opp.CloseDate = System.today().addDays(90);
        Opp.StageName = '1 Discovery';
    }
        /*String conparam =ApexPages.currentPage().getParameters().get('contactId');
        String accParam =ApexPages.currentPage().getParameters().get('AccId');
        String LeadSourceParam =ApexPages.currentPage().getParameters().get('conLead');
        this.Opp = (Opportunity)controller.getRecord();
        populateOpportunityFromParams();
        Opp.Initial_Contacts_Name__c =conparam;
        Opp.AccountId= accParam;
        Opp.ForecastCategoryName= 'Best Case';
        Opp.LeadSource =LeadSourceParam;
        Opp.Name= ApexPages.currentPage().getParameters().get('AccName')+'-';
        Opp.Closedate= System.Today().addDays(90);
        Opp.StageName ='1 Discovery';*/
        //SAL22-465/SAL23-21 //SAL24-405 - commented below lines as it no more in use
        //Opp.SDR_Led__c = ApexPages.currentPage().getParameters().get('sdrLed') == '0' ? false: true;
        //Opp.OriginalLeadOwner__c = ApexPages.currentPage().getParameters().get('userProf') == 'Rubrik Inside Sales' ? UserInfo.getUserId() : null;
        //Opp.SDR_Led_Checked_Date__c= System.Now(); 
    //}
    /**
     * @description  
     * 
     * This is Save method call for validation
     * @return PageReference
     * */
	public PageReference save() {
        if (String.isBlank(opp.Projected_Product_Edition__c)) {
            ApexPages.addMessage(new ApexPages.Message(
                ApexPages.Severity.ERROR, 
                'Please select at least one Projected Product Edition.'
            ));
            return null;
        }
        try {
            upsert opp;
            return new ApexPages.StandardController(opp).view();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }      
}