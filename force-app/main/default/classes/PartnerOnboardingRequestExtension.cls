public without sharing class PartnerOnboardingRequestExtension{
    public Partner_Onboarding_Request__c PO_Request{get;set;}
    public boolean isSavedBool{get;set;}
    public boolean isduplicateContactBool{get;set;}
    public List<SelectOption> vendorsList{get;set;}
    public List<String> selectedVendors{get;set;}
    public boolean isRequired {get; set;}
    public boolean ziplength {get; set;}
    //public boolean novendors {get; set;}

    
    public PartnerOnboardingRequestExtension(ApexPages.StandardController controller) {
         PO_Request = (Partner_Onboarding_Request__c) controller.getRecord();
         string urlParam=ApexPages.currentPage().getParameters().get('isSaved');
         isduplicateContactBool= false;
         isRequired = true;
         ziplength = true;
         //novendors = true;
         PO_Request.Partner_Onboarding_Status__c ='Submitted';
         PO_Request.Agreed_Term_Conditions__c = false;
         //PO_Request.Country__c ='';
         selectedVendors= new List<string>();
         
        vendorsList = new list<selectoption>();            
        try 
        {               
        //Product Name is a MultiSelect Picklist               
        Schema.DescribeFieldResult fieldResult = Partner_Onboarding_Request__c.Vendors_your_Org_works_with_today__c.getDescribe();

        list<schema.picklistentry> values = fieldResult.getPickListValues();               
        for (Schema.PicklistEntry a : values) 
        {                  
        vendorsList.add(new SelectOption(a.getLabel(), a.getValue()));
        }           
        }  
        catch (Exception e) 
        {             
        ApexPages.addMessages(e);           
        }
        system.debug('## Product Name Options'+ vendorsList); 
    }
    /* 
    Developer: Shadab Hussain
    Date: 09/29/2016
    Desc: Method to fetch all values from form and save the record to database
    */
    public ApexPages.PageReference saveRequest() {
        // I can do custom logic here before I save the record.
        ApexPages.StandardController controller = new ApexPages.StandardController(PO_Request);
        

        try {
            //if(PO_Request.Territory__c =='Other')
            PO_Request.Partner_Onboarding_Status__c ='Unassigned';
            //else
            PO_Request.Partner_Onboarding_Status__c ='Pending';
            system.debug('PO_Request Company Name==='+PO_Request.Company_Name__c);
            if(!dulicateContactCheck(PO_Request)){
                if(!String.isBlank(PO_Request.Company_Name__c)){
                    system.debug('PO_Request Company Name==='+PO_Request.Company_Name__c);
                    system.debug('PO_Request selectedVendors==='+selectedVendors);
                    string vendors ='';
                    for(string str : selectedVendors){
                        Vendors +=str+';';
                    }
                    if(Vendors.endsWith(';'))
                    vendors.removeEnd(';');
                    system.debug('PO_Request vendors==='+vendors);
                    if(vendors != '')
                    PO_Request.Vendors_your_Org_works_with_today__c = vendors;
                    Map<String,String> ownersMaps = new Map<String,String>();
                    if(PO_Request.Region__c != ''){
                        
                        for (PartnerOnbaordingMapping__c ownerMapping : PartnerOnbaordingMapping__c.getAll().values()){
                            ownersMaps.put(ownerMapping.Region__c,ownerMapping.Channel_Manager_Id__c);
                            
                        }
       
                    }
                    if(ownersMaps.containsKey(PO_Request.Region__c)){
                        PO_Request.OwnerId = ownersMaps.get(PO_Request.Region__c);
                    }
                    else{
                        PO_Request.OwnerId = label.Unassigned_Partner_Request_Queue_Id;
                    }
                    
                    /*List<Account> relatedAccount = [select id,name,OwnerId from Account where Name =: PO_Request.Company_Name__c Limit 1];
                    system.debug('PO_Request relatedAccount==='+relatedAccount);
                    List<Contact> relatedContact = [select id,name,Email from Contact where Email =: PO_Request.Email__c order by Createddate desc Limit 1];
                    system.debug('PO_Request relatedContact==='+ relatedContact);
                    if(relatedContact.size()>0){
                        PO_Request.Auto_Approval__c = true;
                    }
                    if(relatedAccount != null && relatedAccount.size() >0){
                        PO_Request.OwnerId = relatedAccount[0].OwnerId;
                    }
                    else{
                        PO_Request.OwnerId = label.Unassigned_Partner_Request_Queue_Id;
                    }*/
                
                }
                database.insert(PO_request,false);
            }
            return null;
        }
        catch(Exception e) {
            system.debug('exception'+e);
            return null;
        }

        
    }
    
      
        public void isItRequired(){
          if((PO_Request.Country__c == 'USA' || PO_Request.Country__c == 'US' || PO_Request.Country__c == 'United States')){
           if(PO_Request.Postal_Code__c==null) isRequired = true;
          }else{
            isRequired = false;
            ziplength = false;
          }
        }
    
        public void zipLength(){
          if((PO_Request.Country__c == 'USA' || PO_Request.Country__c == 'US' || PO_Request.Country__c == 'United States') && PO_Request.Postal_Code__c.length()<5){
          system.debug('### PO_Request.Postal_Code__c.length() ' + PO_Request.Postal_Code__c.length());
            ziplength = true;
          }else{
            ziplength = false;
            isRequired = false;
          }
        }

    
    public boolean dulicateContactCheck(Partner_Onboarding_Request__c PO_Request){
        if(!String.isBlank(PO_Request.email__c)){
          List<Partner_Onboarding_Request__c> PORecord = [select id, name,Email__c, Partner_Onboarding_Status__c from Partner_Onboarding_Request__c where email__C =: PO_Request.email__C and  Partner_Onboarding_Status__c !='Rejected'];
          if(PORecord != null && PORecord.size() > 0){
              isduplicateContactBool = true;
              
          }
          else if(!isduplicateContactBool){
              List<User> userRecord = [select id, name,Profile.Name,contact.Email from user where Profile.Name = 'Rubrik Partner Community User' and contact.Email =: PO_Request.email__c and isActive=true];
              if(userRecord != null && userRecord.size() > 0){
                  isduplicateContactBool = true;
                  
              }
          }    
          else
          isduplicateContactBool= false;
        }
        return isduplicateContactBool;
    }
}