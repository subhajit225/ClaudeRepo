/**
 * @Author        :  
 * @description   :  
 * @TstClass      : ProactiveClusterControllerTest
 * -------------------------------------------------------------- @History -------------------------------------------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-45           Vijay Kumar K R        May 06, 2025      Add ability to select multiple clusters and bulk update proactive contact
 * -------------------------------------------------------------------------------------------------------------------------------------------------
 */
public without sharing class ProactiveClusterController {
    
    @AuraEnabled
    public static proactiveContactClass getProactiveInfo(String recordId){
        if(recordId == Userinfo.getUserId()){
            List<String> userZonesList = new List<String>();
            //Integer count;
            User u = [select id,AccountID from User where id =: Userinfo.getUserId()];
            /*Account act = [SELECT Id, Proactive_Case_Contact__c,Proactive_Case_Contact__r.Name,Proactive_Case_Contact__r.Email,Proactive_Case_Contact__r.Phone,
                           Proactive_Case_Contact_OBH__c,Proactive_Case_Contact_OBH__r.Name,Proactive_Case_Contact_OBH__r.Email,Proactive_Case_Contact_OBH__r.Phone, 
                           Preferred_Time__c,Business_Hours__c,Working_Day__c,
                           Shipping_Address_Contact_for_RMA_handlin__c,Special_Delivery_Instruction__c,(Select id, name,email from contacts) FROM Account where id =: u.AccountId];
            for(AggregateResult userZones : [SELECT count(Id) counts ,TimeZoneSidKey tz from user where AccountID =: u.AccountId Group by TimeZoneSidKey ORDER BY count(Id) DESC]){
                userZonesList.add((String)userZones.get('tz'));
}*/
            Account act = [SELECT Id, Proactive_Case_Contact__c,Proactive_Case_Contact__r.Name,Proactive_Case_Contact__r.Email,Proactive_Case_Contact__r.Phone,
                           Proactive_Case_Contact_OBH__c,Proactive_Case_Contact_OBH__r.Name,Proactive_Case_Contact_OBH__r.Email,Proactive_Case_Contact_OBH__r.Phone, 
                           Preferred_Time__c,Business_Hours__c,Working_Day__c,
                           Shipping_Address_Contact_for_RMA_handlin__c,Special_Delivery_Instruction__c FROM Account where id =: u.AccountId];
            //--------Modifications By Anmol Baweja 04 feb, 2020-----------------//
            //Added because of aggregate result error due to large no. of contacts on an account as per CS-512
            List<Contact> conList = [Select id,AccountId,name,email from contact where accountId =: act.id];
            //Added to resolve the aggregate query error due to large no. of users on an account as per CS-512
            Map<String,List<User>> timezoneToUserListMap = new Map<String,List<User>>();
            for(User eachUser : [SELECT Id,TimeZoneSidKey from user where AccountID =: u.AccountId]){
                if(timezoneToUserListMap.containskey(eachUser.TimeZoneSidKey)){
                    List<User> userListTemp = timezoneToUserListMap.get(eachUser.TimeZoneSidKey);
                    userListTemp.add(eachUser);
                    timezoneToUserListMap.put(eachUser.TimeZoneSidKey,userListTemp);
                }
                else{
                    timezoneToUserListMap.put(eachUser.TimeZoneSidKey,new List<User>{eachUser});  
                }
            }
            List<Integer> userCountList = new List<Integer>();
            Map<Integer,String> UserCountToTimezoneMap = new Map<Integer,String>();
            for(String eachTZ : timezoneToUserListMap.keyset()){
                if(timezoneToUserListMap != null && timezoneToUserListMap.containsKey(eachTZ)){
                    if(timezoneToUserListMap.get(eachTZ) != null){
                        UserCountToTimezoneMap.put(timezoneToUserListMap.get(eachTZ).size(),eachTZ);
                    }
                }
            }
            
            userCountList.addAll(UserCountToTimezoneMap.keyset());
            if(userCountList != null && !userCountList.isEmpty()){
                userCountList.sort();
            }
            //-----------Modifications--------//
            String defaultTimeZone;
            String defaultTimeZoneLabel;
            /*if(userZonesList != null && !userZonesList.isEmpty()){
                defaultTimeZone = userZonesList[0];
            }*/
            //-----Modifications By Anmol Baweja 04 feb, 2020-----//
            //Added to resolve the aggregate query error due to large no. of users on an account as per CS-512
            if(userCountList != null && !userCountList.isEmpty() && UserCountToTimezoneMap != null && UserCountToTimezoneMap.size()>0 && UserCountToTimezoneMap.containsKey(userCountList[userCountList.size()-1]) && UserCountToTimezoneMap.get(userCountList[userCountList.size()-1]) != null){
                defaultTimeZone = UserCountToTimezoneMap.get(userCountList[userCountList.size()-1]);
            }
            //-------Modifications----//
            Schema.DescribeFieldResult fieldResult = User.TimeZoneSidKey.getdescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            list<selectList> timeZoneList = new List<selectList>();
            for(Schema.PicklistEntry p : ple){
                timeZoneList.add(new selectList(p.getlabel(),p.getValue()));
                if(defaultTimeZone == p.getValue()){
                    defaultTimeZoneLabel = p.getlabel();
                }
            }
            
            Schema.DescribeFieldResult fieldResults = User.Countrycode.getdescribe();
            List<Schema.PicklistEntry> ples = fieldResults.getPicklistValues();
            list<selectList> countryList = new List<selectList>();
            for(Schema.PicklistEntry p : ples){
                if(p.getlabel() != '--None--')
                    countryList.add(new selectList(p.getlabel(),p.getValue()));
            }
            return new proactiveContactClass(act,conList,timeZoneList,countryList,defaultTimeZone,defaultTimeZoneLabel);
        }else{
            User u = [select id,AccountID from User where id =: Userinfo.getUserId()];
            Account act = [SELECT Id, Proactive_Case_Contact__c,Proactive_Case_Contact__r.Name,Proactive_Case_Contact__r.Email,Proactive_Case_Contact__r.Phone,
                           Proactive_Case_Contact_OBH__c,Proactive_Case_Contact_OBH__r.Name,Proactive_Case_Contact_OBH__r.Email,Proactive_Case_Contact_OBH__r.Phone, 
                           Preferred_Time__c,Business_Hours__c,Working_Day__c,
                           Shipping_Address_Contact_for_RMA_handlin__c,Special_Delivery_Instruction__c FROM Account where id =: u.AccountId];
            List<String> userZonesList = new List<String>();
            /*for(AggregateResult userZones : [SELECT count(Id) counts ,TimeZoneSidKey tz from user where AccountID =: u.AccountId Group by TimeZoneSidKey ORDER BY count(Id) DESC]){
                userZonesList.add((String)userZones.get('tz'));
            }*/
            
            //--------Modifications By Anmol Baweja 04 feb, 2020-----------------//
            //Added because of aggregate result error due to large no. of contacts on an account as per CS-512
            List<Contact> conList = [Select id,AccountId,name,email from contact where accountId =: act.id];
            //Added to resolve the aggregate query error due to large no. of users on an account as per CS-512
            Map<String,List<User>> timezoneToUserListMap = new Map<String,List<User>>();
            for(User eachUser : [SELECT Id,TimeZoneSidKey from user where AccountID =: u.AccountId]){
                if(timezoneToUserListMap.containskey(eachUser.TimeZoneSidKey)){
                    List<User> userListTemp = timezoneToUserListMap.get(eachUser.TimeZoneSidKey);
                    userListTemp.add(eachUser);
                    timezoneToUserListMap.put(eachUser.TimeZoneSidKey,userListTemp);
                }
                else{
                    timezoneToUserListMap.put(eachUser.TimeZoneSidKey,new List<User>{eachUser});  
                }
            }
            List<Integer> userCountList = new List<Integer>();
            Map<Integer,String> UserCountToTimezoneMap = new Map<Integer,String>();
            for(String eachTZ : timezoneToUserListMap.keyset()){
                if(timezoneToUserListMap != null && timezoneToUserListMap.containsKey(eachTZ)){
                    if(timezoneToUserListMap.get(eachTZ) != null){
                        UserCountToTimezoneMap.put(timezoneToUserListMap.get(eachTZ).size(),eachTZ);
                    }
                }
            }
            
            userCountList.addAll(UserCountToTimezoneMap.keyset());
            if(userCountList != null && !userCountList.isEmpty()){
                userCountList.sort();
            }
            //-----------Modifications--------//
            String defaultTimeZone ;
            String defaultTimeZoneLabel;
            /*if(userZonesList != null && !userZonesList.isEmpty()){
                defaultTimeZone = userZonesList[0];
            }*/
            //-----Modifications By Anmol Baweja 04 feb, 2020-----//
            //Added to resolve the aggregate query error due to large no. of users on an account as per CS-512
            if(userCountList != null && !userCountList.isEmpty() && UserCountToTimezoneMap != null && UserCountToTimezoneMap.size()>0 && UserCountToTimezoneMap.containsKey(userCountList[userCountList.size()-1]) && UserCountToTimezoneMap.get(userCountList[userCountList.size()-1]) != null){
                defaultTimeZone = UserCountToTimezoneMap.get(userCountList[userCountList.size()-1]);
            }
            //-------Modifications----//
            Schema.DescribeFieldResult fieldResult = User.TimeZoneSidKey.getdescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            list<selectList> timeZoneList = new List<selectList>();
            for(Schema.PicklistEntry p : ple){
                timeZoneList.add(new selectList(p.getlabel(),p.getValue()));
                if(defaultTimeZone == p.getValue()){
                    defaultTimeZoneLabel = p.getlabel();
                }
            }
            Cluster__c clus = [SELECT Id, Proactive_Case_Contact__c,Proactive_Case_Contact__r.Name,Proactive_Case_Contact__r.Email,Proactive_Case_Contact__r.Phone,
                               Proactive_Case_Contact_OBH__c,Proactive_Case_Contact_OBH__r.Name,Proactive_Case_Contact_OBH__r.Email,Proactive_Case_Contact_OBH__r.Phone, 
                               Preferred_Time__c,Business_Hours__c,Working_Day__c,uuid__c,tag__c,
                               Shipping_Address_Contact_for_RMA_handlin__c,Special_Delivery_Instruction__c from Cluster__c where id =: recordId];
            
            Schema.DescribeFieldResult fieldResults = User.Countrycode.getdescribe();
            List<Schema.PicklistEntry> ples = fieldResults.getPicklistValues();
            list<selectList> countryList = new List<selectList>();
            for(Schema.PicklistEntry p : ples){
                if(p.getlabel() != '--None--')
                    countryList.add(new selectList(p.getlabel(),p.getValue()));
            }
            return new proactiveContactClass(clus,timeZoneList,countryList,defaultTimeZone,defaultTimeZoneLabel,act,conList);
        }
    }
    
    @AuraEnabled
    public static void updateProactiveInfo(String recordId,Boolean isBusinessHours,proactiveContactClass record){
        if(record.isParent){
        Account act = (Account)record.account;
        if(isBusinessHours)
            act.Proactive_Case_Contact__c = recordId;
        else
            act.Proactive_Case_Contact_OBH__c = recordId;
        updateAccount(JSON.serialize(act));
        }else{
            Cluster__c act = (Cluster__c)record.account;
            if(isBusinessHours)
                act.Proactive_Case_Contact__c = recordId;
            else
                act.Proactive_Case_Contact_OBH__c = recordId;
            updateCluster(JSON.serialize(act));
        }
    }
    @future
    public static void updateCluster(String clus){
        update (Cluster__c)JSON.deserialize(clus,Cluster__c.class);
        
    }
    
    @future
    public static void updateAccount(String acc){
        update (Account)JSON.deserialize(acc,Account.class);
        
    }
    
    @AuraEnabled
    public static proactiveContactClass updateBusinessHourInfo(proactiveContactClass record,String timeString,List<String> wdays){
        if(record.isParent){
            Account act = (Account)record.account;
            act.Preferred_Time__c = timeString;
            act.Working_Day__c = string.join(wdays,';');
            updateAccount(JSON.serialize(act));
            record.account = act;
            return record;
        }else{
            Cluster__c act = (Cluster__c)record.account;
            act.Preferred_Time__c = timeString;
            act.Working_Day__c = string.join(wdays,';');
            updateCluster(JSON.serialize(act));
            record.account = act;
            return record;
        }
    }
    
    @AuraEnabled
    public static proactiveContactClass updateRecordAddress(proactiveContactClass record,String address,String spclDelvryInstr){
        if(record.isParent){
            Account act = (Account)record.account;
            act.Shipping_Address_Contact_for_RMA_handlin__c = address;
            act.Special_Delivery_Instruction__c = spclDelvryInstr;
            updateAccount(JSON.serialize(act));
            return record;
        }else{
            Cluster__c act = (Cluster__c)record.account;
            act.Shipping_Address_Contact_for_RMA_handlin__c = address;
            act.Special_Delivery_Instruction__c = spclDelvryInstr;
            updateCluster(JSON.serialize(act));
            return record;
        }
    }
    
    @AuraEnabled
    public static map<String,List<String>> fetchCountryToStatesMap(){
        DependentPicklists dp = new DependentPicklists();
        return dp.controllingToDependentValues(Account.ShippingCountryCode.getDescribe().getSObjectField(),Account.ShippingStateCode.getDescribe().getSObjectField()); 
    }
    
    public class proactiveContactClass {
        @AuraEnabled public Sobject account{get;set;}
        @AuraEnabled public Boolean isParent{get;set;}
        @AuraEnabled public Sobject parent{get;set;}
        @AuraEnabled public List<selectList> zoneList{get;set;}
        @AuraEnabled public List<selectList> countryList{get;set;}
        @AuraEnabled public List<Contact> contactList{get;set;}
        @AuraEnabled public String defaultTimeZoneLabel{get;set;}
        @AuraEnabled public String defaultTimeZone{get;set;}
        
        public Integer count=0;
        public proactiveContactClass(account a, List<Contact> contactList, List<selectList> zoneList,List<selectList> countryList,String defaultTimeZone,String defaultTimeZoneLabel){
            this.account = a;
            this.contactList = contactList;
            this.zoneList =zoneList;
            this.defaultTimeZone = defaultTimeZone;
            this.defaultTimeZoneLabel = defaultTimeZoneLabel;
            this.isParent = true;
            this.countryList = countryList;
        }
        
        public proactiveContactClass(Cluster__c a,List<selectList> zoneList,List<selectList> countryList,String defaultTimeZone,String defaultTimeZoneLabel,account ac, List<Contact> conList){
            this.account = a;
            this.parent = ac;
            this.contactList = conList;
            this.zoneList =zoneList;
            this.defaultTimeZone = defaultTimeZone;
            this.defaultTimeZoneLabel = defaultTimeZoneLabel;
            this.isParent = false;
            this.countryList = countryList;
        }
        public proactiveContactClass(){}
    }
    
    public class selectList{
        @AuraEnabled public String label{get;set;}
        @AuraEnabled public String value{get;set;}
        public selectList(String label,String value){
            this.label = label;
            this.value = value;
        }
        public selectList(){}
    }

    /**
    * @description CS21-46
    * @param proContactId
    * @param accId
    * @param clusterIds
    * @param uncheckedclusterIds
    * @param isUpdateAllClusters
    */
    @AuraEnabled
    public static void updateProactiveContactOnClusters(String proContactId, String accId, List<Id> clusterIds, List<Id> uncheckedclusterIds, Boolean isUpdateAllClusters) {
        Map<Id, Cluster__c> clusterUpdateMap = new Map<Id, Cluster__c>();
        
        try{
            String query = 'SELECT Id, Proactive_Case_Contact__c FROM Cluster__c WHERE Account__c = :accId AND archived__c = false ';
            if(!isUpdateAllClusters){

                if (clusterIds != null && !clusterIds.isEmpty()) {
                    query += ' AND Id IN :clusterIds';
                }
                if (uncheckedclusterIds != null && !uncheckedclusterIds.isEmpty()) {
                    query += ' AND Id NOT IN :uncheckedclusterIds';
                }
            }
            
            if(Schema.sObjectType.Cluster__c.isAccessible()) {
                for (Cluster__c cluster : Database.query(query)) {
                    cluster.Proactive_Case_Contact__c = proContactId;
                    clusterUpdateMap.put(cluster.Id, cluster);
                }
            }else{
                throw new AuraHandledException('You do not have access to Cluster object.');
            }
            
            if(!clusterUpdateMap.isEmpty()) {
                String clusterJson = JSON.serialize(clusterUpdateMap.values());
                UPDATE (List<Cluster__c>) JSON.deserialize(clusterJson, List<Cluster__c>.class);
            }

        } catch (Exception e) {
            // Return clean error message to Aura or LWC
            throw new AuraHandledException('Error updating clusters: ' + e.getMessage());
        }
    }
}