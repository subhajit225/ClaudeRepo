public without sharing class opportunityDebrief {
        public Opportunity_Debrief__c del;
        public List <Opportunity_Debrief__c> addContactList {get;set;}
        public List <Opportunity_Debrief__c> delContactList {get;set;}
        public List <Opportunity_Debrief__c> contactList {get;set;}
        public Integer totalCount {get;set;}
        public Integer rowIndex {get;set;}
        public List <Opportunity_Debrief__c> delContacts {get;set;}

        public Id opportuntiyId {get;set;}
        public Opportunity theOpp {get;set;}
        public Id projectComponent {get;set;}
        public String billStatus {get;set;}

        public ApexPages.StandardSetController standardController;

        public opportunityDebrief(ApexPages.StandardController controller) {

            this.standardController = standardController;

            String soqlOpp = 'select Id,StageName, What_did_we_think_would_happen__c, What_really_happened__c, What_was_the_difference__c,What_worked_well__c,What_didn_t_work__c,What_would_we_do_different_next_time__c,  Lost_Reason__c, Primary_Competitor__c, Other_Competitor_Field__c, Lost_To_Won_Against__c, Incumbent__c, Other_Incumbent__c '; //Close_Audit_Completed_By__c, Close_Audit_Completed_Date__c,
            soqlOpp += 'from Opportunity where Id = \'' + controller.getRecord().Id + '\' limit 1';
            theOpp = database.query(soqlOpp);    
            
            delContactList = new List <Opportunity_Debrief__c> ();
            delContacts = new List <Opportunity_Debrief__c> ();

            contactList = [Select Id, Name, Area__c, Area_Detail__c,Area_Sub_Detail__c, Details__c, Impact__c, Opportunity__c, Severity__c from Opportunity_Debrief__c where Opportunity__c = :theOpp.Id];
            totalCount = contactList.size();
        }

        public void addRow() {
            addContactList = new List <Opportunity_Debrief__c> ();
            system.debug('contactList: ' + contactList);

            Id userId = UserInfo.getUserId();
            if(contactList == null){
                contactList = [Select Id, Name, Area__c, Area_Detail__c, Details__c, Impact__c, Opportunity__c,Area_Sub_Detail__c, Severity__c from Opportunity_Debrief__c where Opportunity__c = :theOpp.Id];
                Opportunity_Debrief__c cl = new Opportunity_Debrief__c(Opportunity__c = theOpp.Id, Impact__c = 'Primary');
                contactList.add(cl);
            }
            else{
                contactList.add(new Opportunity_Debrief__c(Opportunity__c = theOpp.Id, Impact__c = 'Secondary'));
            }
            
        }

        public PageReference save() {
            theOpp.Most_Recent_Opportunity_Debrief_Date__c = datetime.now();
            //theOpp.Most_Recent_Opportunity_Debrief_User__c = UserInfo.getUserId();
            List<Opportunity_Debrief__c> pteUpsert = new List<Opportunity_Debrief__c>();
            try{
                if(contactList != null){
                    for(Opportunity_Debrief__c cl : contactList){
                        if(cl.Area__c != null){
                            pteUpsert.add(cl);
                        }
                    }        
                    upsert pteUpsert;
                }
                delete delContactList;
                saveOpp();
                PageReference pageRef = new PageReference('/apex/opportunityDebrief?Id='+theOpp.Id);
            	return pageRef;
            }
            catch(exception e){
				system.debug('Exception occurred '+e.getMessage());
                string errorMsg = e.getMessage();
                if(!errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
                }
                return null;
            }
        }

       
        public void deleteRow() {
            rowIndex = Integer.valueOf(ApexPages.currentPage().getParameters().get('rowIndex'));
            del = contactList.remove(rowIndex);
            delContactList.add(del);
        }
    public PageReference saveOpp(){
        List<ShGl_DisableBusinessLogic__c> dflList = new List<ShGl_DisableBusinessLogic__c>();
        ShGl_DisableBusinessLogic__c modifydfl = new ShGl_DisableBusinessLogic__c();
        dflList = [SELECT id,Disable_Opportunity_Validation_Rules__c,Name,SetupOwnerId FROM ShGl_DisableBusinessLogic__c];
        Boolean modifiedflag = false;
        Boolean createflag = false;
        try{
            for(ShGl_DisableBusinessLogic__c dfl : dflList){
                if(userinfo.getUserId() == dfl.SetupOwnerId){
                    modifydfl.Id = dfl.Id;
                    if(!dfl.Disable_Opportunity_Validation_Rules__c){
                        modifydfl.Disable_Opportunity_Validation_Rules__c = true;
                        modifiedflag = true;
                    }
                }
            }
            if(modifiedflag){
                update modifydfl;
            }
            if(modifydfl.Id == null){
                createflag = true;
                modifydfl.Disable_Opportunity_Validation_Rules__c = true;
                modifydfl.SetupOwnerId = userinfo.getUserId();
                insert modifydfl;
            }
            
            update theOpp; //updating Opportunity
            
            if(modifiedflag){
                modifydfl.Disable_Opportunity_Validation_Rules__c = false;
                update modifydfl;
            }  
            if(createflag){
                delete modifydfl;
            }
            PageReference pageRef = new PageReference('/apex/opportunityDebrief?id='+theOpp.Id);
            return pageRef;
        }catch(Exception e){
            system.debug('Exception occurred '+e.getMessage());
            string errorMsg = e.getMessage();
            if(!errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
            }
            return null;
        }
        
    }
}