public without sharing class OpportunityAddDealRegLWCController {
private static final string CONTACTROLEERROR = 'Need to fix Contact Roles, new one and only one Primary Contract Role';
private static final string DEALREGERROR = 'Cannot Add a Deal Registration to Opportunity that already has a Deal Registration attached: ';

 @AuraEnabled
    public static List<wrapClass> getAccessDetails(string recId){
        List<wrapClass> wrapClassList = new List<wrapClass>();
        List<Opportunity> opList = new List<Opportunity>();
        String conId = '';
        if(!String.isBlank(recId)){
            opList = [Select Id,Deal_Registration_Number__c,AccountId,Deal_Registration_link__c,Converted_From_Lead__c, Deal_Registration_Type__c,
                        (Select Id, ContactId  from OpportunityContactRoles where isPrimary=true) from Opportunity where Id = :recId ];
            try{
                if(!opList.isEmpty()){
                    OpportunityContactRole oppCR = opList[0].OpportunityContactRoles;
                    conId = oppCR.ContactId;
                }
            } catch (Exception e){
                wrapClassList.add(new wrapClass(CONTACTROLEERROR,conId,'error',opList[0])); 
            }
            if(!opList.isEmpty()){
                if(opList[0].Deal_Registration_Number__c!=null){
                    wrapClassList.add(new wrapClass(DEALREGERROR+opList[0].Deal_Registration_Number__c,conId,'error',opList[0]));
                }else{
                    wrapClassList.add(new wrapClass('',conId,'',opList[0]));
                }
            }else{
                wrapClassList.add(new wrapClass('',conId,'',null));
            }
        }
        return wrapClassList;
    }
    @AuraEnabled
    public static List<Lead> getLeads(string searchText){
        //string searchText = 'test';
        List<Lead> AllLeads = new List<Lead>();
        Integer sizeOfList = 0;
        Integer counter = 0;//TO track the number of records parsed
        Integer limitSize = 20;//Number of records to be displayed
        Integer totalSize =0; //To Store the total number of records available
        List<Lead> LeadsToShow = new List<Lead>();
        List<Deal_Registration__c> dealRegRecds = new List<Deal_Registration__c>();
        String dealRegQuery = 'select Id,name,Lead__c from Deal_Registration__c where Primary__c= true And Name like \'%'+String.escapeSingleQuotes(searchText)+ + '%\' And Lead__c!= null Limit 1000';
        dealRegRecds = (List<Deal_Registration__c>) Database.query(dealRegQuery);
        List<Id> leadIdsToQuery = new List<Id>();
        for(Deal_Registration__c deals:dealRegRecds){
            leadIdsToQuery.add(deals.Lead__c);
        }
        //Get all the contacts which are from Public realations lead source
        String query = 'select Id, Name,Company, Email, Status,LeadSource, Partner_Lookup__r.Name, Partner_Rep__c, Deal_Reg_Number__c, '+
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
        return AllLeads;
    }

    @AuraEnabled
    public static string convertLead(Lead leadRec,Opportunity op,String conId){
        string errmsg = '';
        system.debug('@@leadRec '+leadRec);
        system.debug('@@op '+op);
        system.debug('@@conId '+conId);
        List<Id> leadIdList = new List<Id>();
        leadIdList.add(leadRec.Id);
        if(!leadIdList.isEmpty()) {
         /*   List<String> leadIdList = new List<String>();
            List<Object> leadList = (List<Object>)JSON.deserializeUntyped(jsonStr);
            for(Object o : leadList) {
                String s = (String) o;
                leadIdList.add(s);
            }*/
            List<Lead> queryLeadList = [select id,converting__c from lead where converting__c=false and Id IN:leadIdList];
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
            }catch(Exception e){
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
                errmsg = e.getMessage();
            }
            // Update Deal Reg Link Filed
            
            update updateOp;

            return errmsg;
            
        }
         return errmsg;
        
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
 public class wrapClass{
        @AuraEnabled public string errMsg;
        @AuraEnabled public string conId;
        @AuraEnabled public string variant;
        @AuraEnabled public Opportunity opp;
        public wrapClass(string errMsg1,string conId1,string variant1,Opportunity opp1){
            errMsg = errMsg1;
            conId = conId1;
            variant = variant1;
            opp = opp1;
        }
    }   
}