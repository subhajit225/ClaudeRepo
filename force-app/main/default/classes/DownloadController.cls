public without sharing class DownloadController {
    
    //Get the user from the Util and then split it into a Set of values.
    public List<String> releaseString {get; set;}
    public string acctId {get; set;}
    public string acctTypeString {get; set;}
    public string releaseId {get; set;}
    public string docQueryID {get; set;}
    public Set<String> ProdTypes {get; set;}
    public Set<String> EntProdTypes {get; set;}
    public List<String> PartnerAccountTypes {get; set;}
    public List<String> pickListValuesList {get; set;}
    public boolean isPartner {get; set;}
    public boolean isPartnerType {get; set;}
    
 
     /*
        Release Versions are the high-level used to categorize a "number" release, ex: 4.0
        Releases are the individual releases of different types 4.0 GA, 4.0 DA
        Product Type Permissions are handled in CommunityEntitlementCheck
        Release Type Permissions are handled at the User and Account Level
    */ 
    
    /* notes for May 2018 
    
    User Type = ALL, if they have the entitlement, they see it
    User Type all >= 1 active opportunity, show CDM doc and downloads
    User Type = Partner >=1 active opportunity (at the customer level, show CDM doc and downloads)
    
    */
    
  
    public DownloadController() {
        
            releaseString = new List<String>();
            docQueryID = '';
            ProdTypes = new Set<String>();
            PartnerAccountTypes = new List<String>();
            getUserReleases();
            getEntitlements();
                 
    }
    
    public void getUserReleases(){
        
            if(System.Label.PartnerTypes!=null) PartnerAccountTypes = System.Label.PartnerTypes.split(';');  
            system.debug('### PartnerAccountTypes '+ PartnerAccountTypes);
    
            List<Opportunity> partnerOpps = new List<Opportunity>();
            User userRelease = [SELECT Contact.AccountId, Releases__c FROM User WHERE Id = :UserInfo.getUserId() limit 1];
            system.debug('### Releases__c ' + userRelease.Releases__c + ' ' +UserInfo.getUserId() ); 
            if(userRelease.Releases__c!=null) releaseString = userRelease.Releases__c.split(';'); 
            if(userRelease.Contact.AccountId!=null) acctId = userRelease.Contact.AccountId;
            isPartner = false;
            isPartnerType = false;
            

            
            
             acctTypeString = '';
            
            if(acctId!=null) { 
            List<Account> acctType = [select id, Type, Total_Open_Opportunities__c, Partner_Agreement_Status__c, Total_Closed_Opportunities__c  From Account where Id =: acctId];
            partnerOpps = [select id, Partner_Lookup__c From Opportunity where Partner_Lookup__c =: acctId and (isClosed = false OR isWon = true)];
            system.debug('### acctType '+ acctType[0].Type);
     
            acctTypeString = acctType[0].Type;

             for(String pts : PartnerAccountTypes){     
                if(pts==acctTypeString) isPartnerType = true;
            }       
            system.debug('### isPartnerType '+ isPartnerType);         
            
            isPartner = isPartnerType && acctType[0].Partner_Agreement_Status__c=='Signed - Active' && (acctType[0].Total_Closed_Opportunities__c>0 || acctType[0].Total_Open_Opportunities__c>0 || partnerOpps.size()>0) ? true : false;
            if(acctType[0].Total_Open_Opportunities__c>0) ProdTypes.add('CDM');
            }
            
            system.debug('### isPartner '+ isPartner);
             
            if(isPartner) {
                system.debug('### partnerOpps size ==> ' +partnerOpps.size() );
                if(partnerOpps.size()>0) ProdTypes.add('CDM');
            } 
            
            
            system.debug('### ProdTypes after isPartner '+ ProdTypes);
    
    }
    
    public static list<Entitlement> entList; 
    public List<Entitlement> getEntitlements()
        {   
            if(ProdTypes==null) ProdTypes = new Set<String>();
            EntProdTypes = new Set<String>();
            pickListValuesList = new List<String>();
            Schema.DescribeFieldResult fieldResult = Releases__c.Product_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }   
            system.debug('### fieldresult ' + fieldResult);
        
            string q = 'select Id, Product__r.Family, Product__r.Release_Product_Types__c, Product__c, EndDate from Entitlement  ';
             q+= ' where EndDate>=TODAY and AccountId=: acctId';
            if (entList == null)
                entList = Database.query(q);         
            if (entList.isEmpty()) { 
                return null;
            }
            
            if(!entList.isEmpty()){
            for(Entitlement ent : entList) {
            
            if(ent.Product__r.Release_Product_Types__c!=null) {
                for(String key : ent.Product__r.Release_Product_Types__c.split(';'))
                {
                EntProdTypes.add(key);
                }
               }
               
            }
            
              for(String ptypes : pickListValuesList) {
                 
               if(EntProdTypes.contains(ptypes)) ProdTypes.add(ptypes);
               }
            
            
            }
            return entList;
        }   
    
 
     
 
    ////NEW
    public static list<Release_Version__c> relvList; 
    public List<Release_Version__c> getReleaseVersions()
        {   
            getUserReleases();
            system.debug('### getReleaseVersions '+ releaseString.isEmpty());
        
            string q = 'Select Id, Name, Visible__c, Release_Date__c, Release_Type__c , Version__c, LastModifiedDate from Release_Version__c ';
             q+= ' where Visible__c = true ';
            if(Util.UserType == 'Trial'){
                q+= ' and (Release_Type__c = \'Edge Trial\') ';
            }else{
                if(Util.CurrentUser.Contact.Agreed_to_Edge_Trial_Agreement__c){
                    if(!releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\' OR Release_Type__c = \'Edge Trial\' OR Release_Type__c=null OR Version__c in:releaseString) ';
                    if(releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\'  OR Release_Type__c = \'Edge Trial\' OR Release_Type__c=null) ';
                }else{
                    if(!releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\' OR Release_Type__c=null OR Version__c in:releaseString) ';
                    if(releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\' OR Release_Type__c=null) ';
                }
                
            }
             
             q+= ' order by Release_Date__c desc';         
            if (relvList == null)
                relvList = Database.query(q);         
            if (relvList.isEmpty()) { 
                return null;
            }
            return relvList;
        }   
    
    
    //Get the docs from the Releases for a SPECIFIC Release Version
      public static list<Releases__c> relDocList; 
        public List<Releases__c> getReleaseDocs()
        {   
            string q = 'SELECT Id,Name,Product_Type__c,Release_Date__c,Release_Type__c,LastModifiedDate,Release_Version__c,Version__c, (SELECT Description,Id,Name,OwnerId,LastModifiedDate,ParentId FROM Attachments) FROM Releases__c   ';
             q += ' where Release_Version__c =:releaseId ';
             q += ' and Product_Type__c  in: ProdTypes ';
             q += ' order by Name desc';         
            if (relDocList == null)
                relDocList = Database.query(q);         
            if (relDocList.isEmpty()) { 
                return null;
            }
            
            return relDocList;
        }
   
   
    
    //Get the aggregate software downloads for a version
      public static list<Release_Software__c> relSoftwareVList; 
        public List<Release_Software__c> getReleaseSoftwareV()
        {   
         
         string q = ' SELECT Release__r.Release_Version__c, Release__r.Release_Date__c, Bytes__c,Id,Link__c,MD5__c,Name,Release__c, LastModifiedDate, Release_Type__c, Release__r.Name,  Product_Type__c FROM Release_Software__c ';
             q += ' where Release__r.Release_Version__c =:releaseId '; 
            q += ' and Product_Type__c  in: ProdTypes ';
            
             q += ' order by Name desc';         
            if (relSoftwareVList == null)
                relSoftwareVList = Database.query(q);         
            if (relSoftwareVList.isEmpty()) { 
                return null;
            }

            return relSoftwareVList;
        } 
        
    
    
     //Get the docs from the Releases for a SPECIFIC Release Version
      public static list<Attachment> relDocsList; 
        public List<Attachment> getReleaseVDocs()
        {          
            system.debug('#### docQueryID ' + docQueryID);
            list<Release_Version__c> versionList = [select id, LastModifiedDate from Release_Version__c where Id =: docQueryID];
            
            string rq = 'select id, Release_Version__c, Product_Type__c, LastModifiedDate from Releases__c where Release_Version__c =: versionList ';
            if(acctTypeString=='Customer') rq += ' and Product_Type__c  in: ProdTypes';
            
            list<Releases__c> releasesList = Database.query(rq);   //[select id, Release_Version__c, Product_Type__c, LastModifiedDate from Releases__c where Release_Version__c =: versionList and Product_Type__c  in: ProdTypes ];//and Entitlement_Mapping__c in: ProdTypes ];
            system.debug('### releasesList ' + ' versionList ' + versionList + releaseId + ' ' + releasesList);
        
            string q = 'SELECT Description,Id,Name,OwnerId,ParentId,LastModifiedDate FROM Attachment ';
             q += ' where ParentId in: releasesList '; 
             q+= ' order by Name desc';         
            if (relDocsList == null)
                relDocsList = Database.query(q);         
            if (relDocsList.isEmpty()) { 
                return null;
            }
            return relDocsList;
        }    
        
  
      public List<String> getReleaseProductType(){
           List<String> pickListValuesList= new List<String>();
            Schema.DescribeFieldResult fieldResult = Releases__c.Product_Type__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                pickListValuesList.add(pickListVal.getLabel());
            }     
            return pickListValuesList;
        }
      
  

}