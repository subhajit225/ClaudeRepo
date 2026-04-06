public without sharing class OpportunityAddDealRegController 
{
    //List to store all the Lead according to requirement
    public List<Lead> AllLeads = new List<Lead>();
    public String originalId {get;set;}
    public Boolean showWarning {get;set;}
    public String searchText {get;set;}
    public String jsonHidden{get;set;} 
    //List to show the limited records on the page 
    public List<Lead> LeadsToShow{get;set;}
    public List<Lead> listOfLeads {get;set;}
    public Integer sizeOfList {get;set;}
    private String conId = null;
    
    //Navigation variables
    Integer counter = 0;//TO track the number of records parsed
    Integer limitSize = 20;//Number of records to be displayed
    Integer totalSize =0; //To Store the total number of records available
    private Opportunity op;
    private List<Opportunity> opList;
    //Constructor
    public OpportunityAddDealRegController(){
        showWarning=false;
        sizeOfList = 0;
        LeadsToShow = new list<Lead>();
        originalId = ApexPages.currentPage().getParameters().get('Id');
        if(originalId!=null) {
            op = (originalId != null) ? [Select Id,AccountId,Deal_Registration_link__c,Converted_From_Lead__c, Deal_Registration_Type__c, 
                                        (Select ContactId from OpportunityContactRoles where isPrimary=true)
                                        from Opportunity where id = :originalId] : null;
            opList = [Select Id,AccountId,Deal_Registration_link__c, (Select Id, ContactId  from OpportunityContactRoles where isPrimary=true) from Opportunity where id = :originalId ];
            try{
                OpportunityContactRole oppCR= opList[0].OpportunityContactRoles;
                conId = oppCR.ContactId;
            } catch (Exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Need to fix Contact Roles, new one and only one Primary Contract Role'));
            }
            
        }
        
        if(originalId==null){
            showWarning=true;
        }
        
        if(op!=null){
            if(op.Deal_Registration_Link__c!=null){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot Add a Deal Registration to Opportunity that already has a Deal Registration attached: '+op.Deal_Registration_link__c));
                originalId=null;
            }
           /*if(op.Converted_From_Lead__c){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Cannot Add a Deal Registration to Opportunity that was converted from a lead '));
                originalId=null;
            }*/
        }
        
    }
    
    public void Search(){
        LeadsToShow= new List<Lead>();
        List<Deal_Registration__c> dealRegRecds = new List<Deal_Registration__c>();
        String dealRegQuery = 'select id,name,Lead__c from Deal_Registration__c where Primary__c= true And Name like \'%'+String.escapeSingleQuotes(searchText)+ + '%\' And Lead__c!= null Limit 1000';
        dealRegRecds = (List<Deal_Registration__c>) Database.query(dealRegQuery);
        List<id> leadIdsToQuery = new List<id>();
        for(Deal_Registration__c deals:dealRegRecds){
            leadIdsToQuery.add(deals.Lead__c);
        }
        //Get all the contacts which are from Public realations lead source
        String query = 'select id, name,Company, Email, Status,LeadSource, Partner_Lookup__r.Name, Partner_Rep__c, Deal_Reg_Number__c, '+
            '(Select Deal_Registration_Link__c from Opportunities__r) from Lead where (FirstName like \'%'+String.escapeSingleQuotes(searchText)+ '%\' OR LastName like \'%'+String.escapeSingleQuotes(searchText)+'%\' OR email like \'%'+String.escapeSingleQuotes(searchText)+'%\' OR company like \'%'+String.escapeSingleQuotes(searchText)+'%\' OR full_name__c like \'%'+String.escapeSingleQuotes(searchText)+'%\' OR id IN: leadIdsToQuery ) AND Deal_Registration__c = true AND isConverted = false AND Deal_Reg_Approval_Status__c= \'Approved\' Limit 1000';
        system.debug('query='+query);
        AllLeads = (List<Lead>) Database.query(query);
        system.debug('AllLeads '+AllLeads);
        List<Lead> tempLead = new List<Lead>();
        for(Lead ls: AllLeads) {
            List<Opportunity> o = ls.getSObjects('Opportunities__r');
            system.debug('ooo'+o);
            if(o==null){
                tempLead.add(ls);
            }
        }
        AllLeads.clear();
        AllLeads = tempLead;
        //Store the total size
        totalSize = AllLeads.size();
        sizeOfList = totalSize; 
        //Intial adding of contacts to ContactsToShow
        //check the total records are more than limitSize and assign the records
        if((counter+limitSize) <= totalSize){
            for(Integer i=0;i<limitSize;i++){
                LeadsToShow.add(AllLeads.get(i));
            }
        }else{
            for(Integer i=0;i<totalSize;i++){
                LeadsToShow.add(AllLeads.get(i));
            }
        }
    }
    
    public Pagereference convertLead(){
        system.debug('@@jsonHidden '+jsonHidden);
        system.debug('@@conId '+conId);
        
        if(jsonHidden != null) {
            List<String> leadIdList = new List<String>();
            List<Object> leadList = (List<Object>)JSON.deserializeUntyped(jsonHidden);
            for(Object o : leadList) {
                String s = (String) o;
                leadIdList.add(s);
            }
            
            List<Lead> queryLeadList = [select id,converting__c from lead where converting__c=false and id in:leadIdList];
            system.debug('@@queryLeadList '+queryLeadList);
            List<Lead> updateList = new List<Lead>();
            for(Lead l: queryLeadList){ 
                l.converting__c=true;
                updateList.add(l);
            }
            system.debug('@@updateList '+updateList);
            if(updateList.size()>0){
                update updateList;
            }
            
            list<Database.LeadConvert> leadConverts = new list<Database.LeadConvert>();
            LeadStatus lStatus= [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
            for(String myLead : leadIdList){
                Database.LeadConvert lc = new database.LeadConvert();
                lc.setAccountId(op.AccountId);
                lc.setOpportunityId(op.Id);
                lc.setLeadId(myLead);
                lc.setConvertedStatus(lStatus.MasterLabel);
                if(conId != null){
                    lc.setContactId(conId);
                }
                
                leadConverts.add(lc);
            }
            List<Database.LeadConvertResult> lcr;
           
           Opportunity updateOp = new Opportunity(Id=op.Id);
           updateOp.Deal_Registration_Link__c = leadIdList[0];
           updateOp.Deal_Registration__c=true;
           
            try{
                lcr = Database.convertLead(leadConverts);
                 
                for(Database.LeadConvertResult cResult : lcr) {
                    system.debug('cResult.isSuccess()=> '+cResult.isSuccess());
                }
                //Search();
                
                  
            }
            catch(Exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, e.getMessage()));
                Lead vLead = [Select Id, Deal_Reg_Approval_Status__c, Deal_Reg_Submitted_Date__c, Deal_Reg_Approval_Timestamp__c,
                              Deal_Reg_Exp_Date__c,Deal_Registration_Number__c,Rubrik_Complete_Edition_Reg__c,
                              Partner_Rep_Phone_Number__c,Partner_Rep_Email_Address__c,Distributor_Rep_Phone_Number__c, Sell_to_Partner__c, //FCUS-117
                              Distributor_Secondary_Email_Address__c,Partner_SE_Name__c,Partner_SE_Phone__c,Partner_SE_Email__c 
                              from Lead where Id=:leadIdList[0]];//removed Alliance_Partner_Program__c as part of SAL26-702
                //FCUS-117n118
                //DealRegUtilityHelper.copyDealRegLeadToOpportunity(updateOp,vLead);
                copyDealRegLeadToOpportunity(updateOp,vLead);
                system.debug('@@e=> '+e);
                Error_Logs__c log = new Error_Logs__c();
                log.Type__c = 'Add DealReg on Oppty';
                log.Class__c='OpportunityAddDealRegController';
                log.Method__c ='convertLead';
                log.Error_Type__c = 'Lead Exception';
                log.Error_Message__c = e.getMessage();
                log.RecordId__c = 'Lead';
                log.RecordId__c = vLead.Id;
                insert log;
            }
            // Update Deal Reg Link Filed
            
            update updateOp;

            //switch the active response for PID
            /*if('Partner Initiated Deal' == op.Deal_Registration_Type__c){
                op.FCRM__FCR_Response_ID__c = null;
                update op;
                List<CampaignMember> updateMembers = new List<CampaignMember>();
                for(CampaignMember cm : [SELECT Id FROM CampaignMember WHERE FCRM__FCR_Opportunity__c = :op.Id AND HasResponded = TRUE]){
                    cm.FCRM__FCR_Opportunity__c = null;
                    cm.FCRM__FCR_Admin_Response_Control__c = 1;
                    updateMembers.add(cm);
                }
                update updateMembers;
                updateMembers = new List<CampaignMember>();
                CampaignMember latestCM = [SELECT Id FROM CampaignMember 
                                            WHERE Campaign.Name = 'Partner Portal Deal Registration'
                                            AND HasResponded = TRUE
                                            ORDER BY CreatedDate DESC LIMIT 1];
                latestCM.FCRM__FCR_Opportunity__c = op.Id;
                latestCM.FCRM__FCR_Admin_Response_Control__c = 8;
                update latestCM;
            }*/
            PageReference nextPage = new PageReference('/' + op.Id);
            return nextPage;
            
        }
         return null;
        
    }
    public Pagereference cancel(){
        return new PageReference('/' + op.Id);
    }
    public void beginning(){
        
        LeadsToShow.clear();
        counter=0;
        if((counter + limitSize) <= totalSize){
            
            for(Integer i=0;i<limitSize;i++){
                LeadsToShow.add(AllLeads.get(i));
            }   
            
        } else{
            
            for(Integer i=0;i<totalSize;i++){
                LeadsToShow.add(AllLeads.get(i));
            }       
            
        }
        
    }
    
    
    public void next(){
        
        LeadsToShow.clear();
        counter=counter+limitSize;
        system.debug('Counter=> '+counter);
        System.debug('totalSize=> '+totalSize);
        System.debug('All Leads=> '+AllLeads);
       
        if((counter+limitSize) <= totalSize){
            for(Integer i=counter-1;i<(counter+limitSize);i++){
                LeadsToShow.add(AllLeads.get(i));
            }
        } else{
            for(Integer i=counter;i<totalSize;i++){
                system.debug('AllLeads.get(i) '+AllLeads.get(i));
                LeadsToShow.add(AllLeads.get(i));
            }
        }
    }
    public void previous(){
        
        LeadsToShow.clear();
        
        counter=counter-limitSize;       
        
        for(Integer i=counter;i<(counter+limitSize); i++){
            LeadsToShow.add(AllLeads.get(i));
        }
    }  
    public void last (){
        
        LeadsToShow.clear();
        
        if(math.mod(totalSize , limitSize) == 0){
            counter = limitSize * ((totalSize/limitSize)-1);
        } else if (math.mod(totalSize , limitSize) != 0){
            counter = limitSize * ((totalSize/limitSize));
        }
        
        for(Integer i=counter-1;i<totalSize-1;i++){
            LeadsToShow.add(AllLeads.get(i));
        }
        
    }  
    public Boolean getDisableNext(){
        
        if((counter + limitSize) >= totalSize )
            return true ;
        else
            return false ;
    }  
    public Boolean getDisablePrevious(){
        
        if(counter == 0)
            return true ;
        else
            return false ;
    }  
    
    /**********************************************************************
      Copies date from the Lead (Deal Reg) Onto an opportunity
    ***********************************************************************/
    //FCUS-117n118
    public static void copyDealRegLeadToOpportunity(Opportunity vOpportunity, Lead regLink){
		System.debug('@@copy to: '+vOpportunity);
		
		vOpportunity.Deal_Reg_Approval_Status__c= regLink.Deal_Reg_Approval_Status__c;
		vOpportunity.Deal_Reg_Submitted_Date__c=regLink.Deal_Reg_Submitted_Date__c;
		vOpportunity.Deal_Reg_Approval_Timestamp__c=regLink.Deal_Reg_Approval_Timestamp__c;
		vOpportunity.Deal_Reg_Expiration_Date__c= regLink.Deal_Reg_Exp_Date__c;
		//vOpportunity.Alliance_Partner_Program__c = regLink.Alliance_Partner_Program__c;//removed Alliance_Partner_Program__c as part of SAL26-702
		vOpportunity.Converted_From_Lead__c=false;
		vOpportunity.Deal_Registration_Number__c = regLink.Deal_Registration_Number__c;
		vOpportunity.Partner_Rep_Phone_Number__c=regLink.Partner_Rep_Phone_Number__c;
		vOpportunity.Partner_Rep_Email_Address__c=regLink.Partner_Rep_Email_Address__c;
		vOpportunity.Distributor_Rep_Phone_Number__c=regLink.Distributor_Rep_Phone_Number__c;
		vOpportunity.Distributor_Secondary_Email_Address__c=regLink.Distributor_Secondary_Email_Address__c;
		vOpportunity.Partner_SE_Name__c=regLink.Partner_SE_Name__c;
		vOpportunity.Partner_SE_Phone__c=regLink.Partner_SE_Phone__c;
		vOpportunity.Partner_SE_Email__c=regLink.Partner_SE_Email__c;

		//FCUS-117n118
		String stpId = regLink.Sell_to_Partner__c;
        //SF-17573
		/*
        vOpportunity.Sell_to_Partner__c = (regLink.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(stpId)) ? regLink.Sell_to_Partner__c : vOpportunity.Sell_to_Partner__c;
		vOpportunity.Alliance_HW_Partner__c = (regLink.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(stpId)) ? 'NetApp' : vOpportunity.Alliance_HW_Partner__c;
		vOpportunity.Alliance_Source_Type_HW__c = (regLink.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(stpId)) ? 'Alliance Initiated Deal' : vOpportunity.Alliance_Source_Type_HW__c;
        */
        if(regLink.Sell_to_Partner__c != null && Label.NetApp_Account_Ids.contains(stpId)){
            vOpportunity.Sell_to_Partner__c = regLink.Sell_to_Partner__c;
            vOpportunity.Alliance_HW_Partner__c = 'NetApp'; 
        }
    }
}