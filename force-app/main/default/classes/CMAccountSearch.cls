public class CMAccountSearch {

   
    public class Status {
        public String statusCode;
        public String statusDescription;
    }

    public class CMAccount {
        /*{
        if(string.isBlank(CMID))
        return '';
        else 
        return CMID; 
        }
        public string sfdcAccountid{get;set;} . */
        
        @AuraEnabled public String CMID { get;set;}
        @AuraEnabled public String sourceID {
            get{
                if(string.isNotEmpty(sourceID)){
                    if(sourceID.contains('SFDC'))
                        return sourceID.substringAfterLast(':');
                    else if(sourceID.length()== 15 || sourceID.length()== 18){ // Salesforce record.
                        return sourceID ;
                    }
                    else
                        return '';
                }
                else
                    return '';
            }
            set;
        }
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String accountStatus {get;set;}
        @AuraEnabled public String addressLine1 {
            get{
                return string.isBlank(addressLine1)?'':addressLine1 ;
            }
            set;
        }
        @AuraEnabled public String addressLine2 {
            get{
                return string.isBlank(addressLine2)?'':addressLine2 ;
            }
            set;
        }
        @AuraEnabled public String phone {get;set;}
        @AuraEnabled public String website {get;set;}
        @AuraEnabled public String city {get;set;}
        @AuraEnabled public String state {get;set;}
        @AuraEnabled public String stateCode {get;set;}
        @AuraEnabled public String postalCode {get;set;}
        @AuraEnabled public String country {get;set;}
        @AuraEnabled public String isoCountrycode {get;set;}
        @AuraEnabled public string recTypeName {get;set;}
        @AuraEnabled public String dunsNumber {get;set;}
        @AuraEnabled public String accountOwner {get;set;}
        @AuraEnabled public String newAccount {get
        {
          if(newAccount!= null && newAccount.equalsIgnoreCase('Y'))
          return newAccount;
          else
          return 'N';
        }
        set;}
       // public boolean selected{get;set;}
       
       public CMAccount(Id sfdcAccountid ,string accountName,string accountOwner,string addressLine1 ,string city ,string state,string stateCode ,string postalCode ,string country,string dunsNumber,string isocountrycode,string recTypeName,string accountStatus){//
        system.debug('state'+state+'country'+country);
         this.sourceID = string.isBlank((string)sfdcAccountid)?'':(string)sfdcAccountid ;
         this.accountName = accountName; 
         this.accountOwner = string.isBlank(accountOwner)?'':accountOwner;
         this.accountStatus = accountStatus;
         this.state = state;
         this.addressLine1 = addressLine1;
         this.city = city;
         this.recTypeName =recTypeName;
         this.dunsNumber = dunsNumber;
         this.stateCode =stateCode;
         this.postalCode =postalCode;
         this.country = country;
         this.isoCountrycode =isoCountrycode;
       }
        
    }
    
    public String requestId;
    public String requester;
    public Results results ;
    public Status status ;

    public class Results {
        public CMAccount CMAccount;
        public List<CMAccount> potentialAccounts;
    }
    
    
}