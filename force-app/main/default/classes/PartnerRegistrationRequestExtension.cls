public without sharing class PartnerRegistrationRequestExtension{
    public Partner_Registration_Request__c PR_Request{get;set;}
    public boolean isSavedBool{get;set;}
    public boolean isduplicateContactBool{get;set;}
    public boolean isdisabled {get;set;}
    public string companyName;
    public static boolean success {get;set;}
    public static boolean errordr {get;set;}
    public list<SelectOption> statePickList{get; set;}
    public list<SelectOption> countryPickList{get; set;}
    public boolean ziperror {get;set;}
    public boolean isRequired {get; set;}
    public boolean ziplength {get; set;}
     
    public PartnerRegistrationRequestExtension(ApexPages.StandardController controller) {
         PR_Request = (Partner_Registration_Request__c) controller.getRecord();
         string urlParam=ApexPages.currentPage().getParameters().get('isSaved');
         isduplicateContactBool= false;
         companyName ='';
         success=false;
         errordr=false; 
         ziperror=false;
         isrequired=true;
         ziplength=true;
         populateCountryPickList();
         populateStatePickList();

         /*if(urlParam == '' || urlParam == null)
         isSavedBool=false;
         else
         isSavedBool=true;*/
         String currentRequestURL = URL.getCurrentRequestUrl().toExternalForm();
         System.debug('Current request URL: ' + currentRequestURL);
         if(currentRequestURL.contains('partners')) {
             PR_Request.Company_Name__c = [select id,contact.Account.Name from User where id=:userinfo.getuserid() Limit 1].contact.Account.Name;
             //companyName= PR_Request.Company_Name__c;
             System.debug('PR_Request.Company_Name__c: ' + PR_Request.Company_Name__c);
             isdisabled= true;
         }
                     PR_Request.Partner_Registration_Status__c ='Submitted';
    }
    /* 
    Developer: Shadab Hussain
    Date: 09/29/2016
    Desc: Method to fetch all values from form and save the record to database
    */
    public ApexPages.PageReference saveRequest() {
        // I can do custom logic here before I save the record.
        ApexPages.StandardController controller = new ApexPages.StandardController(PR_Request);
        try {
            ziperror=false;
            isduplicateContactBool=false; 
            success=false;
            PR_Request.Partner_Registration_Status__c ='Submitted';
            
            String currentRequestURL = URL.getCurrentRequestUrl().toExternalForm();
            if(currentRequestURL.contains('partners')) {
             PR_Request.Company_Name__c = [select id,contact.Account.Name from User where id=:userinfo.getuserid() Limit 1].contact.Account.Name;
             System.debug('PR_Request.Company_Name__c: ' + PR_Request.Company_Name__c);
             isdisabled= true;
             }
            system.debug('PR_Request Company Name==='+PR_Request.Company_Name__c);
            
            
            try{
            if(PR_Request.Country_Picklist__c == 'USA' || PR_Request.Country_Picklist__c == 'United States') {
            ziperror=false;
            string zip = PR_Request.Postal_Code__c;
            boolean zipnull = String.isBlank(zip);
            system.debug('### zipfield '+ zip + ' zipnull ' + zipnull + ' PR_Request.Country_Picklist__c ' + PR_Request.Country_Picklist__c);
            
            Pattern isnumbers = Pattern.Compile('^[0-9]+$');
            Matcher postalMatch = isnumbers.matcher(zip);
            
            boolean zipNum = postalMatch.Matches();                       
            ziperror = PR_Request.Country_Picklist__c == 'USA' && zipnull==true ? true : PR_Request.Country_Picklist__c == 'USA' && zip.length()<5 ? true : PR_Request.Country_Picklist__c == 'USA' && zip.length()>4 && !zipNum ? true : false;
            system.debug('### 1 ziperror '+ ziperror);
            }
            }
             catch(Exception e) {
                ziperror=true;
            }
           system.debug('### ziperror '+ ziperror);
            
            isduplicateContactBool=dulicateContactCheck(PR_Request);
            system.debug('### isduplicateContactBool '+ isduplicateContactBool);
            
            //if(!dulicateContactCheck(PR_Request) && ziperror==false){
                if(!isduplicateContactBool && ziperror==false){
                
                if(!String.isBlank(PR_Request.Company_Name__c)){
                    system.debug('PR_Request Company Name==='+PR_Request.Company_Name__c);
                    List<Account> relatedAccount = [select id,name,OwnerId from Account where Name =: PR_Request.Company_Name__c Limit 1];
                    system.debug('PR_Request relatedAccount==='+relatedAccount);
                    List<Contact> relatedContact = [select id,name,Email from Contact where Email =: PR_Request.Email__c order by Createddate desc Limit 1];
                    system.debug('PR_Request relatedContact==='+ relatedContact);
                    if(relatedContact.size()>0){
                        PR_Request.Auto_Approval__c = true;
                    }
                    if(relatedAccount != null && relatedAccount.size() >0){
                        PR_Request.OwnerId = relatedAccount[0].OwnerId;
                    }
                    else{
                        PR_Request.OwnerId = label.Unassigned_Partner_Request_Queue_Id;
                    }
                
                 
                
                }
                database.insert(PR_Request,false);
                //controller.save();
            } 
            success=true;
            return null;
        }
        catch(Exception e) {
            success=false;
            errordr=true;
            isduplicateContactBool=dulicateContactCheck(PR_Request);
            SYSTEM.DEBUG('EXCEPTION=='+e);
            return null;
        }
    }
    
    public boolean dulicateContactCheck(Partner_Registration_Request__c PR_Request){
        if(!String.isBlank(PR_Request.email__c)){
          List<Partner_Registration_Request__c> PRRecord = [select id, name,Email__c, Partner_registration_Status__c from Partner_Registration_Request__c where email__C =: PR_Request.email__C and  Partner_Registration_Status__c !='Rejected'];
          if(PRRecord != null && PRRecord.size() > 0){
              isduplicateContactBool = true;
              
          }
          else if(!isduplicateContactBool){
              List<User> userRecord = [select id, name,Profile.Name,contact.Email from user where Profile.Name = 'Rubrik Partner Community User' and contact.Email =: PR_Request.email__c and isActive=true];
              if(userRecord != null && userRecord.size() > 0){
                  isduplicateContactBool = true;
                  
              }
          }
          else
          isduplicateContactBool= false;
        }
        return isduplicateContactBool;
    }
    
     public list<SelectOption> populateCountryPickList(){

        //OLD Method
        /*countryPickList = new List<SelectOption>();
        countryPickList.add( new SelectOption('','Select...'));
        for (Countries__c countryInstance : [SELECT Name
                                               FROM Countries__c
                                           ORDER BY Name ASC]) {
            countryPickList.add( new SelectOption(
                countryInstance.Name,
                countryInstance.Name
            ));
        }*/
        
        countryPickList = new List<SelectOption>();
        countryPickList.add( new SelectOption('','Select...'));

        Schema.DescribeFieldResult fieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple){
        System.debug(f.getLabel() +'::'+ f.getValue());
        countryPickList.add( new SelectOption(
                f.getLabel(),
                f.getLabel()
            ));
        
        }

        
        
        return countryPickList;
    }//end populateCountryPickList
    
    
    public list<SelectOption> populateStatePickList(){

        statePickList = new List<SelectOption>();
        statePickList.add( new SelectOption('','Select...'));

        Schema.DescribeFieldResult fieldResult = User.Statecode.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        System.debug('Picklist::'+ple);
        for( Schema.PicklistEntry f : ple){
        System.debug(f.getLabel() +'::'+ f.getValue());
        statePickList.add( new SelectOption(
                f.getLabel(),
                f.getLabel()
            ));
        
        }
        
        return statePickList;
    }
    
    
   public void isItRequired(){
      if(PR_Request.Country_Picklist__c == 'USA' || PR_Request.Country_Picklist__c == 'United States'){
        isRequired = true;
      }else{
        isRequired = false;
        ziplength = false;

      }
    }

    public void zipLength(){
      if((PR_Request.Country_Picklist__c == 'USA' || PR_Request.Country_Picklist__c == 'United States') && PR_Request.Postal_Code__c.length()<5){
        ziplength = true;
      }else{
        ziplength = false;
      }
    }
    
    
}