public with sharing class MQLRoutingOwnerAssignService1 {
    Set<Id> recordIds;
    String objectName;
    Map<String, String> metadataToObjectFields;
    List<Lead_Routing_Rule__mdt> allRules;
    map<Id,Account> accountRecordmap= new  map<Id,Account>();
    map<Id,PatchManager__c> patchmanagerRecordmap= new  map<Id,PatchManager__c>();
    Map<String,map<String,String>> accountTerriteryMap= new Map<String,map<String,String>>();
    map<Id,set<Id>> patchRRMap = new  map<Id,set<Id>>();
    map<Id,set<Id>> QueueRRMap = new  map<Id,set<Id>>();
    //comment 
    public MQLRoutingOwnerAssignService1(Set<Id> recordIds, List<Lead_Routing_Rule__mdt> allRules) {
        this.recordIds = recordIds;
        Id firstrecordId = new List<Id> (recordIds).get(0);
	    this.ObjectName =  String.valueOf( firstrecordId.getsObjectType() ); 
        this.allRules = allRules;
    }

    public  void assignOwners(Map<Id, Lead_Routing_Rule__mdt> recordIdToRule, Map<Id, Sobject> recordIdToSObject, Map<Id, Boolean> mapIdWithIsFallback){
        List<Lead> lstLeadsUpdated = new List<Lead>();
        List<Contact> lstContactsUpdated = new List<Contact>();
        map<String,set<Id>> routingSournceRecordMap = new map<String,set<Id>>();
        set<String> routingSourceAccountIDs = new set<String>();  
        Set<String> AccountFields = new Set<String>();
        Set<String> PatchFieldsSet = new Set<String>();
        Set<Id> patchKeyIds = new Set<Id>();
        Id ownerId;
        Map<String, String> mapFieldtoReferenceField = new Map<String, String>(); // Fallback - Nandish
        
        // Start Logic to Generate Record Set Map for all Routing SOurce //
        for(Id recordId :recordIdToRule.keySet()) {            
            Lead_Routing_Rule__mdt rule = recordIdToRule.get(recordId);
            system.debug('#MQLRoutingOwnerAssignService1#assignOwners#rule:'+rule);
            Map<String, Set<Id>> requiredIds = new Map<String, Set<Id>>();
            //Fallback By Nandish - Start
            if(rule.Fallback_Source__c == 'Account Territory') {
                String accountId = ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')) : String.ValueOf(recordIdToSObject.get(recordId).get('AccountId'));
            	if(!routingSournceRecordMap.containsKey('Account Territory')){
                    routingSournceRecordMap.put('Account Territory',new set<Id> {accountId}); 
                } else {
                    routingSournceRecordMap.get('Account Territory').add(accountId);
                }   
            } 
            if(rule.Fallback_Source__c == 'Account' || rule.Fallback_Source__c == 'Account Territory' ) {
                String accountId =  ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')) : 
                                    String.ValueOf(recordIdToSObject.get(recordId).get('AccountId'));
                if(!routingSournceRecordMap.containsKey('Account')){
                    routingSournceRecordMap.put('Account',new set<Id> {accountId}); 
                } else {
                    routingSournceRecordMap.get('Account').add(accountId);
                }
                if(rule.Fallback_Source__c == 'Account') {
                    AccountFields.add(rule.Fallback__c);
                    AccountFields.add('Owner.isActive'.toLowerCase());
                    AccountFields.add('Owner.Name');
                }
                 AccountFields.add('OwnerId');
                
            } else if( rule.Fallback_Source__c == 'Patch Key') {
                String patchId = ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c')) : 
                                            String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c'));
                if(!routingSournceRecordMap.containsKey('Patch Key')){
                    routingSournceRecordMap.put('Patch Key',new set<Id> {patchId}); 
                } else {
                    routingSournceRecordMap.get('Patch Key').add(patchId);
                }
                PatchFieldsSet.add(rule.Fallback__c);
            }
            //Fallback By Nandish - End
            if(rule.Routing_Source__c == 'Account'){
                /*String accountId =  ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')) : 
                                    String.ValueOf(recordIdToSObject.get(recordId).get('AccountId'));
                if(!routingSournceRecordMap.containsKey('Account')){
                    routingSournceRecordMap.put('Account',new set<Id> {accountId}); 
                } else {
                    routingSournceRecordMap.get('Account').add(accountId);
                }
                String field = String.valueOf(recordIdToRule.get(recordId).User_Role_Field_Value__c);
                String refField = getReferenceField(field.toLowerCase());
                mapFieldtoReferenceField.put(field, refField);
                AccountFields.add(field);
                AccountFields.add((refField + '.isActive').toLowerCase());  //Fallback
                AccountFields.add(refField + '.Name');*/
            }
            else if(rule.Routing_Source__c == 'Account Territory'){
                String accountId = ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')) : 
                                                    String.ValueOf(recordIdToSObject.get(recordId).get('AccountId'));
                if(!routingSournceRecordMap.containsKey('Account Territory')){
                    routingSournceRecordMap.put('Account Territory',new set<Id> {accountId}); 
                } else {
                    routingSournceRecordMap.get('Account Territory').add(accountId);
                }
                if(recordIdToRule.get(recordId).DeveloperName == 'Account_Based_ETM_Role'){
                    AccountFields.add('ABR_ETM_Role__c');
                }
            }
            else if(rule.Routing_Source__c == 'Patch Key'){
                String patchId = ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c')) : 
                                            String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c'));
                if(!routingSournceRecordMap.containsKey('Patch Key')){
                    routingSournceRecordMap.put('Patch Key',new set<Id> {patchId}); 
                } else {
                    routingSournceRecordMap.get('Patch Key').add(patchId);
                }
                String field = String.valueOf(recordIdToRule.get(recordId).User_Role_Field_Value__c);
                String refField = getReferenceField(field.toLowerCase());
                mapFieldtoReferenceField.put(field, refField);
                PatchFieldsSet.add(field);
                PatchFieldsSet.add(refField + '.isActive');  //Fallback
            }
            else if(rule.Routing_Source__c == 'PatchKey-RoundRobin'){
                String patchId =  ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c')) : 
                                            String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c'));
                if(!routingSournceRecordMap.containsKey('PatchKey-RoundRobin')){
                    routingSournceRecordMap.put('PatchKey-RoundRobin',new set<Id> {patchId}); 
                } else {
                    routingSournceRecordMap.get('PatchKey-RoundRobin').add(patchId);
                }
            }
            else if(rule.Routing_Source__c =='Round Robin'){
                 
                 String queueId = String.valueOf(recordIdToRule.get(recordId).User_Role_Field_Value__c);
                 
                 if(!routingSournceRecordMap.containsKey('Round Robin')){
                    routingSournceRecordMap.put('Round Robin',new set<Id> {queueId}); 
                } else {
                    routingSournceRecordMap.get('Round Robin').add(queueId);
                }
                 
             }
        }
        System.debug('#MQLRoutingOwnerAssignService1#assignOwners#routingSournceRecordMap:'+routingSournceRecordMap);
        // End Logic to Generate Record Set Map for all Routing SOurce //  

        // Start call initilazation Method
        if(!routingSournceRecordMap.IsEmpty())
            initiateMap(routingSournceRecordMap,AccountFields,PatchFieldsSet);

        // Start Logic to Assign Record Owner //
        for(Id recordId :recordIdToSObject.keySet()) {
            Lead_Routing_Rule__mdt rule = recordIdToRule.get(recordId);
            ownerId = null;
            system.debug('#MQLRoutingOwnerAssignService1#assignOwners#rule:'+rule);
            system.debug('#MQLRoutingOwnerAssignService1#assignOwners#accountTerriteryMap:'+accountTerriteryMap);
            if(rule.Routing_Source__c =='Hard-coded'){
                system.debug('hard Code');
                ownerId = rule.User_Role_Field_Value__c;
            }
            else if(rule.Routing_Source__c =='Current Record'){
                ownerId = String.valueOf(recordIdToSObject.get(recordId).get(rule.User_Role_Field_Value__c));
            }
            else if(rule.Routing_Source__c =='Account') {
                /*system.debug('INSIDE ACCOUNT ');  
                Id AccountID = ObjectName=='Lead'?String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')):String.ValueOf(recordIdToSObject.get(recordId).get('accountId')) ;
                if( accountRecordmap.get(AccountID).get(rule.User_Role_Field_Value__c) != null && 
                  		Boolean.valueOf(accountRecordmap.get(AccountID).getsObject( mapFieldtoReferenceField.get(rule.User_Role_Field_Value__c)).get('isactive')) &&
                        !String.valueOf(accountRecordmap.get(AccountID).getsObject( mapFieldtoReferenceField.get(rule.User_Role_Field_Value__c)).get('Name')).containsIgnoreCase('TBH')) { // Fallback - Nandish
                    ownerId = String.valueOf(accountRecordmap.get(AccountID).get(rule.User_Role_Field_Value__c));
                }*/
            }
            else if(rule.Routing_Source__c =='Account Territory'){
                system.debug('INSIDE Accpunt Territory ');
                Id accountId = ObjectName=='Lead'?String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')):String.ValueOf(recordIdToSObject.get(recordId).get('accountId')) ;
                if(accountTerriteryMap.containsKey(accountId)) {
                    if(rule.User_Role_Field_Value__c == 'ETM_Role__c' && accountTerriteryMap.get(String.valueOf(accountId)).containsKey(String.valueOf(recordIdToSObject.get(recordId).get(rule.User_Role_Field_Value__c)))){
                        ownerId = accountTerriteryMap.get(String.valueOf(accountId)).get(String.valueOf(recordIdToSObject.get(recordId).get(rule.User_Role_Field_Value__c)));
                    }else if(rule.User_Role_Field_Value__c == 'ABR_ETM_Role__c' && accountTerriteryMap.get(String.valueOf(accountId)).containsKey(String.valueOf(accountRecordmap.get(accountId).get(rule.User_Role_Field_Value__c)))){
                        ownerId = accountTerriteryMap.get(String.valueOf(accountId)).get(String.valueOf(accountRecordmap.get(accountId).get(rule.User_Role_Field_Value__c)));
                    }else if(rule.User_Role_Field_Value__c != 'ETM_Role__c' && accountTerriteryMap.get(String.valueOf(accountId)).containsKey(rule.User_Role_Field_Value__c)){
                        ownerId = accountTerriteryMap.get(String.valueOf(accountId)).get(rule.User_Role_Field_Value__c);//TODO: replace with a single line Done
                    }
                }
            } 
            else if(rule.Routing_Source__c =='Patch Key'){
                    system.debug('INSIDE Patch Key ');
                if('MQL To ETM' == recordIdToSObject.get(recordId).get('Last_Applied_Routing_Modifier__c')){
                    mapIdWithIsFallback.put(recordId, true);
                }
                Id patchID = String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c'));
                if(String.valueOf(patchmanagerRecordmap.get(patchID).get(rule.User_Role_Field_Value__c)) !=null && 
                  		Boolean.valueOf(patchmanagerRecordmap.get(patchID).getsObject( mapFieldtoReferenceField.get(rule.User_Role_Field_Value__c)).get('isactive')))
                    ownerId = String.valueOf(patchmanagerRecordmap.get(patchID).get(rule.User_Role_Field_Value__c));
            }
            else if(rule.Routing_Source__c =='PatchKey-RoundRobin'){
                system.debug('INSIDE Patch Key ');
                if('MQL To ETM' == recordIdToSObject.get(recordId).get('Last_Applied_Routing_Modifier__c')){
                    mapIdWithIsFallback.put(recordId, true);
                }
                Id patchID = String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c'));
                if(!patchRRMap.isEmpty())
                ownerId = generateRandomOwner(patchRRMap.get(patchID));
            }
            else if(rule.Routing_Source__c =='Round Robin'){
               
                String QueueID =rule.User_Role_Field_Value__c;
                ownerId = generateRandomOwner(QueueRRMap.get(Id.valueOf(QueueID)));
            }
            if(ownerId == null) { 
                mapIdWithIsFallback.put(recordId, true);
                if( rule.Fallback_Source__c == 'Account Territory' ) {
                    Id accountId = ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')) : String.ValueOf(recordIdToSObject.get(recordId).get('accountId')) ;
                    for( String role : rule.Fallback__c.split(';') ){
                        if( accountTerriteryMap.containsKey(String.valueOf(accountId)) && accountTerriteryMap.get(String.valueOf(accountId)).containsKey(role) ) {
                            ownerId = accountTerriteryMap.get(String.valueOf(accountId)).get(role);
                            break;
                        }
                    }
                    if( ownerId == null ) {
                        Account acc = accountRecordmap.get(AccountID);
                        //if( acc.Owner.isActive ) {
                            ownerId = acc.OwnerId;
                       // } 
                    }
                } else if( rule.Fallback_Source__c == 'Patch Key' ) {
                    String patchID = String.ValueOf(recordIdToSObject.get(recordId).get('PatchManager__c'));
                    ownerId = String.valueOf(patchmanagerRecordmap.get(patchID).get( rule.Fallback__c ));
                } else if ( rule.Fallback_Source__c == 'Account' ) {
                    String accountId = ObjectName=='Lead' ? String.ValueOf(recordIdToSObject.get(recordId).get('Winning_L2A_Account__c')) : String.ValueOf(recordIdToSObject.get(recordId).get('accountId')) ;
                    if(!String.valueOf(accountRecordmap.get(AccountID).getsObject( mapFieldtoReferenceField.get(rule.User_Role_Field_Value__c)).get('Name')).containsIgnoreCase('TBH')){
                        ownerId = String.valueOf(accountRecordmap.get(AccountID).get( rule.Fallback__c ));
                    }
                } 
                else if(rule.Fallback_Source__c == 'Next Rule'){
                    MQLRoutingService service = new MQLRoutingService(new Set<Id>{recordId}, objectName);
                    String query = service.getRoutingRulesQuery(objectName);
                    query += ' AND Priority__c > '+rule.Priority__c + ' ORDER BY Priority__c ASC';
                    List<Lead_Routing_Rule__mdt> ruleSet = Database.query(query);     
            		Map<Id, Lead_Routing_Rule__mdt> leadToRule = service.stampRulesOnRecords(ruleSet);
            		Map<Id, sObject> leadIdToLead = new Map<Id, sObject>();
                    leadIdToLead.put(recordId, recordIdToSObject.get(recordId));
                    Map<Id, Boolean> mapIdWithTrueFallback = new Map<Id, Boolean>();
                    mapIdWithTrueFallback.put(recordId, true);
                    if(!leadToRule.isEmpty()){
                        MQLRoutingOwnerAssignService1 ownerService = new MQLRoutingOwnerAssignService1(new Set<Id>{recordId}, ruleSet);
                		ownerService.assignOwners(leadToRule, leadIdToLead, mapIdWithTrueFallback);
            		}
                 }
            }
            if(ownerId != null) { 
                if( ObjectName=='Lead') {
                    lstLeadsUpdated.add(New Lead(Id=recordIdToSObject.get(recordId).id,OwnerId=ownerId, Routing_Rule_Applied__c = recordIdToRule.get(recordId).MasterLabel, AssignLeadInAfter__c=false, Owner_Fallback__c = mapIdWithIsFallback.get(recordId)));
                } else {
                   	lstContactsUpdated.add(New Contact(Id=recordIdToSObject.get(recordId).id,Routing_Rule_Applied__c=recordIdToRule.get(recordId).MasterLabel,OwnerId=ownerId, Owner_Fallback__c = mapIdWithIsFallback.get(recordId), ReRoute_Contact__c = false));
                }
                
            }
        }
        // End  Logic to Assign Record Owner //
        // Update Lead Record//
        system.debug('#MQLRoutingOwnerAssignService1#assignOwners#lstLeadsUpdated:'+lstLeadsUpdated);
       if(!lstLeadsUpdated.isEmpty()) {
            database.update(lstLeadsUpdated, false);
        }  
        if(!lstContactsUpdated.isEmpty()) {
            database.update(lstContactsUpdated, false);
        }   
    }
	
    private String getReferenceField(String field) {
        if( field.toLowerCase().endsWith('id')) {
            return field.toLowerCase().removeEnd('id') ;
        } else {
            return field.toLowerCase().removeEnd('__c') + '__r';
        }
    }
    
    public void initiateMap( map<String,set<Id>> routingSournceRecordMap,set<String> AccountFields, Set<String> PatchFieldsSet){
        if(routingSournceRecordMap.containsKey('Account')) {
            //generate queries//
            String setStringLoop = '';
            for(String eachElement : AccountFields){
                setStringLoop += (',' + eachElement);
            }
            System.debug('#MQLRoutingOwnerAssignService1#initiateMap#setStringLoop:'+setStringLoop);
            set<Id> accountIDs = routingSournceRecordMap.get('Account');
            String accQuery ='SELECT Id'+setStringLoop+ ' From Account where Id IN : accountIDs';
            System.debug('#MQLRoutingOwnerAssignService1#initiateMap#accQuery:'+accQuery);
            List<Account> accountList= Database.query(accQuery);
            for(Account rsAcc:accountList){
                accountRecordmap.put(rsAcc.Id,rsAcc);
            }
        }
        if(routingSournceRecordMap.containsKey('Account Territory')) {
            set<Id> accountIDs = routingSournceRecordMap.get('Account Territory');
            accountTerriteryMap=findOwnerFromAccount(accountIDs);   
        }
        if(routingSournceRecordMap.containsKey('Patch Key')) {
            //generate queries//
            String setStringLoop = '';
            for(String eachElement : PatchFieldsSet){
                setStringLoop += eachElement +',';
            }
            setStringLoop = setStringLoop.substring(0,setStringLoop.length()-1);
            system.debug(setStringLoop);
            set<Id> patchKeyIds = routingSournceRecordMap.get('Patch Key');
            String Queries ='SELECT Id,'+setStringLoop+ ' From PatchManager__c  where Id IN : patchKeyIds';
            System.debug('#MQLRoutingOwnerAssignService1#initiateMap#Queries:'+Queries);
            List<PatchManager__c> patchMList= Database.query(Queries);
            for(PatchManager__c pmRs:patchMList){
                patchmanagerRecordmap.put(pmRs.Id,pmRs);
            }
        }
        if(routingSournceRecordMap.containsKey('PatchKey-RoundRobin')) {
            set<Id> patchKeyIds = routingSournceRecordMap.get('PatchKey-RoundRobin');
           patchRRMap= getAvailableUsersSDRPool(patchKeyIds);
        }
        if(routingSournceRecordMap.containsKey('Round Robin')) {
            set<Id> queueKeyIds = routingSournceRecordMap.get('Round Robin');
           QueueRRMap= getAvailableUsersQueue(queueKeyIds);
        }
    }

    private  static Map<String,map<String,String>>  findOwnerFromAccount(Set<Id> accountIds){
        Map<Id, Set<Id>> territoryIdToAccountIds = new Map<Id, Set<Id>>();
        Map<String,map<String,String>> AccountTerriteryUserMap = new Map<String,map<String,String>>();
                
        for(ObjectTerritory2Association obj: [SELECT Id, ObjectId, Territory2Id, Territory2.Name
                                                FROM ObjectTerritory2Association
                                                WHERE ObjectId IN: accountIds
                                                AND Territory2.Territory2Model.State = 'Active']){                             
            if(territoryIdToAccountIds.containsKey(obj.Territory2Id))
                territoryIdToAccountIds.get(obj.Territory2Id).add(obj.ObjectId);
            else
                territoryIdToAccountIds.put(obj.Territory2Id, new Set<Id>{obj.ObjectId});
        }
        //MKT23-745: 1st priority to IAM then SDR
        for(UserTerritory2Association userTerritory: [SELECT Id,Territory2Id,UserId, RoleInTerritory2, User.isActive, User.Name
                                                    FROM UserTerritory2Association
                                                    WHERE Territory2Id IN: territoryIdToAccountIds.keySet()]){
            
            for(Id accountId : territoryIdToAccountIds.get(userTerritory.Territory2Id)){
                if(!AccountTerriteryUserMap.containsKey( accountId )) {
                    AccountTerriteryUserMap.put(accountId, new Map<String,String>());
                }
                Map<String,String> TerritoryMap = AccountTerriteryUserMap.get(accountId);
                if( userTerritory.User.isActive && !userTerritory.User.Name.containsIgnoreCase('TBH')) {
                    TerritoryMap.put(userTerritory.RoleInTerritory2,userTerritory.UserId); 
                } 
            }
        }

        return AccountTerriteryUserMap;
    }

    public static Map<Id, Set<Id>> getAvailableUsersSDRPool(Set<Id> patchKeySet){ 
        Map<Id, Set<Id>> patchKeyToUsers = new Map<Id, Set<Id>>();
        Set<Id> workingUsers = new Set<Id>();
        for(Patch_Manager_User_Pool__c usrPool : [SELECT id,User__c,Patch_Key__c from Patch_Manager_User_Pool__c where Patch_Key__c IN:patchKeySet AND User__r.IsActive = TRUE]) {
            if(patchKeyToUsers.containsKey(usrPool.Patch_Key__c)) {
                patchKeyToUsers.get(usrPool.Patch_Key__c).add(usrPool.User__c);
            }
            else 
                patchKeyToUsers.put(usrPool.Patch_Key__c, new Set<Id>{usrPool.User__c});
                
            workingUsers.add(usrPool.User__c);
        }
        DateTime myDate = getUTCDateTime(system.now());
        Date myDateFinalUTC = date.newinstance(myDate.year(), myDate.month(), myDate.day());
        System.debug('#MQLRoutingOwnerAssignService1#getAvailableUsersSDRPool#myDateFinalUTC:'+myDateFinalUTC);
            Date myDateFinal = date.today();//.newinstance(myDate.year(), myDate.month(), myDate.day());
        //remove all on PTO
        for(PTOCalendar__c ptoCalendar : [SELECT Id,User__c,StartDate__c,EndDate__c 
                                        FROM PTOCalendar__c 
                                        WHERE  User__c IN :workingUsers 
                                        AND StartDate__c <=: myDateFinal 
                                        AND EndDate__c >=:  myDateFinal 
                                        ORDER BY CreatedDate DESC]){
            workingUsers.remove(ptoCalendar.User__c);
        }

        for(Id patchKey : patchKeyToUsers.keySet()){
            for(Id userId : patchKeyToUsers.get(patchKey)){
                if(!workingUsers.contains(userId)) {
                        patchKeyToUsers.get(patchKey).remove(userId); //return this map
                }
            }
        }
        return patchKeyToUsers;
    } 
    
    
    public static Map<Id, Set<Id>> getAvailableUsersQueue(Set<Id> queueIdSet){ 
        Map<Id, Set<Id>> queueToUsers = new Map<Id, Set<Id>>();
        Set<Id> workingUsers = new Set<Id>();
        Set<Id> activeUsers = new Set<Id>();
        for(GroupMember usrPool : [SELECT id,UserOrGroupId,GroupId,Group.DeveloperName FROM GroupMember 
                       WHERE Group.Id IN:queueIdSet AND Group.Type='Queue']) {
            if(queueToUsers.containsKey(usrPool.Group.Id)) {
                queueToUsers.get(usrPool.Group.Id).add(usrPool.UserOrGroupId);
            }
            else 
                queueToUsers.put(usrPool.Group.Id, new Set<Id>{usrPool.UserOrGroupId});
                
                 workingUsers.add(usrPool.UserOrGroupId);
        }
        
        if(workingUsers.size()>0) {
                List<User> userRSList = [Select id from user where id IN :workingUsers and isActive=true];
                for(User rsus:userRSList){
				 activeUsers.add(rsus.Id);   
             }
			}
        
        if(activeUsers.size()>0) {
            
             DateTime myDate = getUTCDateTime(system.now());
            Date myDateFinalUTC = date.newinstance(myDate.year(), myDate.month(), myDate.day());
            System.debug('#MQLRoutingOwnerAssignService1#getAvailableUsersQueue#myDateFinalUTC: '+myDateFinalUTC);
                Date myDateFinal = date.today();//.newinstance(myDate.year(), myDate.month(), myDate.day());
            //remove all on PTO
            for(PTOCalendar__c ptoCalendar : [SELECT Id,User__c,StartDate__c,EndDate__c 
                                            FROM PTOCalendar__c 
                                            WHERE  User__c IN :activeUsers 
                                            AND StartDate__c <=: myDateFinal 
                                            AND EndDate__c >=:  myDateFinal 
                                            ORDER BY CreatedDate DESC]){
                activeUsers.remove(ptoCalendar.User__c);
            }
        }
           

        for(Id patchKey : queueToUsers.keySet()){
            for(Id userId : queueToUsers.get(patchKey)){
                if(!activeUsers.contains(userId)) {
                        queueToUsers.get(patchKey).remove(userId); //return this map
                }
            }
        }
        return queueToUsers;
    }
    
    public static Id generateRandomOwner(Set<Id> availableUsers){
        Id recordOwnerId; 
        List<Id> MemeberList = new List<Id>(availableUsers);
        if(MemeberList.size()>0){
            Integer random = Integer.valueof(Math.random() * MemeberList.size());
            System.debug('#MQLRoutingOwnerAssignService1#generateRandomOwner#random:'+random);
            //ContactOwnerId = MemeberList[random].UserOrGroupId;
            recordOwnerId = MemeberList[random];
        }
        System.debug('#MQLRoutingOwnerAssignService1#generateRandomOwner#recordOwnerId:'+recordOwnerId);
        return recordOwnerId;  
    }

    public static DateTime getUTCDateTime(DateTime dt){ 
        Datetime GMTDate = Datetime.newInstanceGmt(
                                dt.year(),
                                dt.month(),
                                dt.day(),
                                dt.hour(),
                                dt.minute(),
                                dt.second());
        return GMTDate;
    }
}