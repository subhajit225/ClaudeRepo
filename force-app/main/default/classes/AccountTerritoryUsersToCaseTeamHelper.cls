/**
* @Author       :   Saakshi Gupta
* @CreatedDate  :   23-03-2021
* @Jira Ticket  :   CS21-288 - Update Case Notification Workflow Rule For ETM 2.0 Impacts
* @Description  :   Creates/Updates/Deletes Account Territory users from Case Team
*/
public class AccountTerritoryUsersToCaseTeamHelper {
    
    public static Map<Id,Id> caseAccountIdMap = new Map<Id,Id>();
    public static Map<Id,Map<Id,Id>> accounttoUserIdsMap = new Map<Id,Map<Id,Id>>();

    public static void insertNewAccountOwner(Set<Id> accountIdSet, String process) {
        List<String> caseTeamRolesList = new List<String>();
        for(Case_Team_Mapping__c mapping : Case_Team_Mapping__c.getall().values()){
            if(!accounttoUserIdsMap.containsKey(mapping.Account_Id__c)){
                accounttoUserIdsMap.put(mapping.Account_Id__c, new Map<Id,Id>());
            }
            accounttoUserIdsMap.get(mapping.Account_Id__c).put(mapping.Original_User_Id__c, mapping.Updated_User_Id__c);
        }
        

        if(process.containsIgnoreCase('Account Owner;')) {
            caseTeamRolesList.add('Account Owner');
        }
        if(process.containsIgnoreCase('CEM;')) {
            caseTeamRolesList.add('Customer Experience Manager');
        }
        if(process.containsIgnoreCase('SE;')) {
            caseTeamRolesList.add('Sales Engineer');
            caseTeamRolesList.add('Sales Engineer Manager');
        }

        Set<String> caseTeamRolesSet = new Set<String>();
        caseTeamRolesSet.addAll(caseTeamRolesList);
        List<Case> caseList = getCasesWithAccountOwnerTeamMembers(accountIdSet, caseTeamRolesSet);

        Map<String, Id> mapCaseTeamRoles = new Map<String, Id>();
        if(!caseList.isEmpty()) {
            mapCaseTeamRoles = getCaseTeamRoles(caseTeamRolesList);
        }

        List<CaseTeamMember> lstToInsert = new List<CaseTeamMember>();
        List<CaseTeamMember> listToDelete = new List<CaseTeamMember>();
        CaseTeamMember newCaseMember;

        for(Case eachCase : caseList) {
            if(!caseAccountIdMap.containsKey(eachCase.Id)){
                caseAccountIdMap.put(eachCase.Id, eachCase.AccountId);
            }
            if(!eachCase.TeamMembers.isEmpty()) {
                listToDelete.addAll(eachCase.TeamMembers);
            }

            if(caseTeamRolesSet.contains('Account Owner')) {
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account_Owner__c, mapCaseTeamRoles.get('Account Owner')));
            }

            if(caseTeamRolesSet.contains('Customer Experience Manager')) {
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Account_SAM__c, mapCaseTeamRoles.get('Customer Experience Manager')));
            }

            if(caseTeamRolesSet.contains('Sales Engineer')) {
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.RSE_Id__c, mapCaseTeamRoles.get('Sales Engineer')));
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Rubrik_Sales_Engineer__r.ManagerId, mapCaseTeamRoles.get('Sales Engineer Manager')));
            }
        }
        System.debug('listToDelete==='+listToDelete);
        System.debug('lstToInsert==='+lstToInsert);
        Database.delete(listToDelete, false);
        Database.insert(lstToInsert, false);
    }

    //When a new user is added to the Account Territory
    public static void insertCtmOnNewAccTerrUser(Set<Id> userTerrAssocIdSet) {
        Set<String> roleSet = new Set<String>();
        Map<Id, List<UserTerritory2Association>> terrIdUserAssocMap = new Map<Id, List<UserTerritory2Association>>();
        //Fetch Sales Engineers for the accounts gathered above from their assigned active Territories
        List<UserTerritory2Association> userTerritoryAssocList = [SELECT Id, UserId, RoleInTerritory2,
                                                                    Territory2Id, User.ManagerId
                                                                    FROM UserTerritory2Association
                                                                    WHERE IsActive = true
                                                                    AND Id =: userTerrAssocIdSet];

        for(UserTerritory2Association eachUta : userTerritoryAssocList) {
            if(!String.isBlank(eachUta.RoleInTerritory2))
                roleSet.add(eachUta.RoleInTerritory2);

            if(!terrIdUserAssocMap.containsKey(eachUta.Territory2Id))
                terrIdUserAssocMap.put(eachUta.Territory2Id, new List<UserTerritory2Association>());

            terrIdUserAssocMap.get(eachUta.Territory2Id).add(eachUta);
        }

        if(roleSet.isEmpty()) return;

        List<Case_Team_Member_Role_Mapping__mdt> mappingList = getCaseTeamMemberRoleMapping(roleSet);

        if(mappingList.isEmpty()) return;

        List<ObjectTerritory2Association> objectAssocList = getObjectTerritory2Assoc(terrIdUserAssocMap.keyset());

        if(objectAssocList.isEmpty()) return;

        Map<Id, Id> accountIdTerrIdMap = new Map<Id, Id>();
        for(ObjectTerritory2Association eachObjectAssoc : objectAssocList) {
            accountIdTerrIdMap.put(eachObjectAssoc.ObjectId, eachObjectAssoc.Territory2Id);
        }

        List<Case> caseList = getCasesWithoutTeamMembers(accountIdTerrIdMap.keySet());

        if(caseList.isEmpty()) return;

        Map<String, String> ctmRoleAccTerrRoleMap = new Map<String, String>();
        for(Case_Team_Member_Role_Mapping__mdt eachMapping : mappingList) {
            ctmRoleAccTerrRoleMap.put(eachMapping.Role_in_Territory__c, eachMapping.MasterLabel);
        }

        Map<String, Id> mapCaseTeamRoles = getCaseTeamRoles(ctmRoleAccTerrRoleMap.values());

        insertDeleteCaseTeamMember(caseList, mapCaseTeamRoles, ctmRoleAccTerrRoleMap, terrIdUserAssocMap, accountIdTerrIdMap);
    }

    //When the role of existing user in the territory is updated
    public static void updateCtmOnAccTerrUserUpdate(Set<Id> userTerrAssocIdSet, String jsonOldMap) {
        Map<Id, UserTerritory2Association> oldMap = (Map<Id, UserTerritory2Association>)JSON.deserialize(jsonOldMap, Map<Id, UserTerritory2Association>.class);
        Set<String> roleSet = new Set<String>();
        Map<Id, List<UserTerritory2Association>> terrIdUserAssocMap = new Map<Id, List<UserTerritory2Association>>();
        //Fetch Sales Engineers for the accounts gathered above from their assigned active Territories
        List<UserTerritory2Association> userTerritoryAssocList = [SELECT Id, UserId, RoleInTerritory2, Territory2Id, User.ManagerId
                                                                    FROM UserTerritory2Association
                                                                    WHERE IsActive = true
                                                                    AND Id =: userTerrAssocIdSet];

        Set<Id> userIdSet = new Set<Id>();
        for(UserTerritory2Association eachUta : userTerritoryAssocList) {
            userIdSet.add(eachUTA.UserId);
            if(!String.isBlank(eachUta.RoleInTerritory2))
                roleSet.add(eachUta.RoleInTerritory2);

            if(!terrIdUserAssocMap.containsKey(eachUta.Territory2Id))
                terrIdUserAssocMap.put(eachUta.Territory2Id, new List<UserTerritory2Association>());

            terrIdUserAssocMap.get(eachUta.Territory2Id).add(eachUta);
        }

        Set<String> oldRoleSet = new Set<String>();
        Map<Id, UserTerritory2Association> oldSeMap = new Map<Id, UserTerritory2Association>();
        Set<Id> oldSeSet = new Set<Id>();
        Set<Id> seTerritoryIdSet = new Set<Id>();
        for(UserTerritory2Association eachUta : oldMap.values()) {
            if(!String.isBlank(eachUta.RoleInTerritory2)) {
                roleSet.add(eachUta.RoleInTerritory2);
                oldRoleSet.add(eachUta.RoleInTerritory2);
            }
        }

        if(roleSet.isEmpty()) return;

        List<Case_Team_Member_Role_Mapping__mdt> mappingList = getCaseTeamMemberRoleMapping(roleSet);

        if(mappingList.isEmpty()) return;

        List<ObjectTerritory2Association> objectAssocList = getObjectTerritory2Assoc(terrIdUserAssocMap.keyset());

        if(objectAssocList.isEmpty()) return;

        Map<Id, Id> accountIdTerrIdMap = new Map<Id, Id>();
        for(ObjectTerritory2Association eachObjectAssoc : objectAssocList) {
            accountIdTerrIdMap.put(eachObjectAssoc.ObjectId, eachObjectAssoc.Territory2Id);
        }

        Set<String> oldCaseTeamRoles = new Set<String>();
        Map<String, String> ctmRoleAccTerrRoleMap = new Map<String, String>();
        for(Case_Team_Member_Role_Mapping__mdt eachMapping : mappingList) {
            ctmRoleAccTerrRoleMap.put(eachMapping.Role_in_Territory__c, eachMapping.MasterLabel);

            if(oldRoleSet.contains(eachMapping.Role_in_Territory__c))
                oldCaseTeamRoles.add(eachMapping.MasterLabel);
        }

        List<Case> caseList = [SELECT Id, AccountId, Account_Owner__c, RSE_Id__c, OwnerId, Account.Account_SAM__c,
                                (SELECT Id, MemberId, TeamRoleId, TeamRole.Name FROM TeamMembers WHERE TeamRole.Name =: oldCaseTeamRoles
                                    AND MemberId =: userIdSet)
                                FROM Case
                                WHERE AccountId =: accountIdTerrIdMap.keySet()
                                AND Status NOT IN ('Closed')];

        if(caseList.isEmpty()) return;

        Map<String, Id> mapCaseTeamRoles = getCaseTeamRoles(ctmRoleAccTerrRoleMap.values());

        List<CaseTeamMember> lstToInsert = new List<CaseTeamMember>();
        List<CaseTeamMember> lstToUpdate = new List<CaseTeamMember>();
        List<CaseTeamMember> listToDelete = new List<CaseTeamMember>();
        Id territoryId;
        String newRole, oldRole;
 		for(Case_Team_Mapping__c mapping : Case_Team_Mapping__c.getall().values()){
            if(!accounttoUserIdsMap.containsKey(mapping.Account_Id__c)){
                accounttoUserIdsMap.put(mapping.Account_Id__c, new Map<Id,Id>());
            }
            accounttoUserIdsMap.get(mapping.Account_Id__c).put(mapping.Original_User_Id__c, mapping.Updated_User_Id__c);
        }
        for(Case eachCase : caseList) {
            if(!caseAccountIdMap.containsKey(eachCase.Id)){
                caseAccountIdMap.put(eachCase.Id, eachCase.AccountId);
            }
            territoryId = accountIdTerrIdMap.get(eachCase.AccountId);
            for(UserTerritory2Association eachUserAssoc : terrIdUserAssocMap.get(territoryId)) {
                if(!String.isBlank(eachUserAssoc.RoleInTerritory2)) {
                    newRole = ctmRoleAccTerrRoleMap.get(eachUserAssoc.RoleInTerritory2);
                    oldRole = ctmRoleAccTerrRoleMap.get(oldMap.get(eachUserAssoc.Id).RoleInTerritory2);

                    /*Old role in Territory is not part of Case team role mapping but new role is,
                    we need to insert the Case team member*/
                    if(oldRole == null && newRole != null) {
                        lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachUserAssoc.UserId, mapCaseTeamRoles.get(newRole)));
                    }
                    /*Old role in Territory is part of Case team role mapping and new role as well,
                    we need to update the Case team member*/
                    else if(newRole != null) {
                        for(CaseTeamMember eachCTM : eachCase.TeamMembers) {
                            if(eachCTM.MemberId == eachUserAssoc.UserId && mapCaseTeamRoles.get(oldRole) == eachCTM.TeamRoleId) {
                                eachCTM.TeamRoleId = mapCaseTeamRoles.get(newRole);
                                lstToUpdate.add(eachCTM);
                            }
                        }
                    }
                    /*Old role in Territory is part of Case team role mapping but new role is not,
                    we need to delete the Case team member*/
                    else if(newRole == null) {
                        for(CaseTeamMember eachCTM : eachCase.TeamMembers) {
                            if(eachCTM.MemberId == eachUserAssoc.UserId && mapCaseTeamRoles.get(oldRole) == eachCTM.TeamRoleId) {
                                listToDelete.add(eachCTM);
                            }
                        }
                    }
                }
            }
        }

        System.debug('listToDelete==='+listToDelete);
        System.debug('lstToUpdate==='+lstToUpdate);
        System.debug('lstToInsert==='+lstToInsert);
        Database.delete(listToDelete, false);
        Database.update(lstToUpdate, false);
        Database.insert(lstToInsert, false);
    }

    public static void deleteCtmOnAccTerrUserDelete(String jsonOldMap) {
        Map<Id, UserTerritory2Association> oldMap = (Map<Id, UserTerritory2Association>)JSON.deserialize(jsonOldMap, Map<Id, UserTerritory2Association>.class);
        //Fetch Sales Engineers for the accounts gathered above from their assigned active Territories
        Set<Id> territoryIdSet = new Set<Id>();
        Set<String> roleSet = new Set<String>();
        Set<Id> userIdSet = new Set<Id>();

        for(UserTerritory2Association eachUta : oldMap.values()) {
            if(!String.isBlank(eachUta.RoleInTerritory2)) {
                userIdSet.add(eachUta.UserId);
                roleSet.add(eachUta.RoleInTerritory2);
                territoryIdSet.add(eachUta.Territory2Id);
                }
            }

        if(roleSet.isEmpty()) return;

        List<Case_Team_Member_Role_Mapping__mdt> mappingList = getCaseTeamMemberRoleMapping(roleSet);

        if(mappingList.isEmpty()) return;

        List<ObjectTerritory2Association> objectAssocList = getObjectTerritory2Assoc(territoryIdSet);

        if(objectAssocList.isEmpty()) return;

        Map<Id, Id> accountIdTerrIdMap = new Map<Id, Id>();
        for(ObjectTerritory2Association eachObjectAssoc : objectAssocList) {
            accountIdTerrIdMap.put(eachObjectAssoc.ObjectId, eachObjectAssoc.Territory2Id);
        }
        System.debug('accountIdTerrIdMap===='+accountIdTerrIdMap);

        Map<String, String> ctmRoleAccTerrRoleMap = new Map<String, String>();
        for(Case_Team_Member_Role_Mapping__mdt eachMapping : mappingList) {
            ctmRoleAccTerrRoleMap.put(eachMapping.Role_in_Territory__c, eachMapping.MasterLabel);
        }
        System.debug('ctmRoleAccTerrRoleMap===='+ctmRoleAccTerrRoleMap);

        List<CaseTeamMember> existingCtm = [SELECT Id, MemberId, TeamRole.Name, Parent.AccountId
                                                FROM CaseTeamMember
                                                WHERE Parent.Status NOT IN ('Closed')
                                                AND Parent.AccountId =: accountIdTerrIdMap.keyset()
                                                AND TeamRole.Name =: ctmRoleAccTerrRoleMap.values()
                                                AND MemberId =: userIdSet];
        System.debug('existingCtm===='+existingCtm);
        if(existingCtm.isEmpty()) return;

        List<CaseTeamMember> lstToDelete = new List<CaseTeamMember>();
        for(CaseTeamMember eachCtm : existingCtm) {
            for(UserTerritory2Association eachUta : oldMap.values()) {
                if(eachCtm.MemberId == eachUta.UserId && eachCtm.TeamRole.Name == ctmRoleAccTerrRoleMap.get(eachUta.RoleInTerritory2)) {
                    lstToDelete.add(eachCtm);
                    break;
                }
            }
        }

        System.debug('lstToDelete===='+lstToDelete);

        Database.delete(lstToDelete, false);
    }

    public static void deleteInsertCTMOnAccountChange(Set<Id> caseIdSet, String jsonOldMap) {
        Map<Id, Case> oldMap = (Map<Id, Case>)JSON.deserialize(jsonOldMap, Map<Id, Case>.class);
        Set<Id> accountIdSet = new Set<Id>();
        Map<String, String> ctmRoleAccTerrRoleMap = new Map<String, String>();

        List<Case_Team_Member_Role_Mapping__mdt> mappingList = [SELECT MasterLabel, Role_in_Territory__c FROM Case_Team_Member_Role_Mapping__mdt];

        for(Case_Team_Member_Role_Mapping__mdt eachMapping : mappingList) {
            ctmRoleAccTerrRoleMap.put(eachMapping.Role_in_Territory__c, eachMapping.MasterLabel);
        }
        ctmRoleAccTerrRoleMap.put('Account Owner', 'Account Owner');
        ctmRoleAccTerrRoleMap.put('Customer Experience Manager', 'Customer Experience Manager');
        ctmRoleAccTerrRoleMap.put('Sales Engineer', 'Sales Engineer');
        ctmRoleAccTerrRoleMap.put('Sales Engineer Manager', 'Sales Engineer Manager');
        System.debug('case team roles==='+ctmRoleAccTerrRoleMap);

        List<Case> caseList = [SELECT Id, AccountId, Account_Owner__c, RSE_Id__c, OwnerId, Account.Account_SAM__c,
                                Account.Rubrik_Sales_Engineer__r.ManagerId,
                        (SELECT Id FROM TeamMembers WHERE TeamRole.Name =: ctmRoleAccTerrRoleMap.values())
                    FROM Case
                    WHERE Id =: caseIdSet];

        List<CaseTeamMember> lstToDelete = new List<CaseTeamMember>();
        Set<Id> newAccountIdSet = new Set<Id>();
        for(Case c : caseList){
            if(c.AccountId != null) {
                accountIdSet.add(c.accountId);
                newAccountIdSet.add(c.AccountId);
            }
            else {
                lstToDelete.addAll(c.TeamMembers);
            }

            if(oldMap.get(c.Id).AccountId != null)
                accountIdSet.add(oldMap.get(c.Id).AccountId);
        }

        if(newAccountIdSet.isEmpty()) {
            Database.delete(lstToDelete, false);
            return;
        }

        Map<String, Id> mapCaseTeamRoles = new Map<String, Id>();
        for(CaseTeamRole eachRole : [SELECT Id, Name FROM CaseTeamRole WHERE Name =: ctmRoleAccTerrRoleMap.values()]){
            mapCaseTeamRoles.put(eachRole.Name, eachRole.Id);
        }

        System.debug('mapCaseTeamRoles==='+mapCaseTeamRoles);

        ctmRoleAccTerrRoleMap.remove('Account Owner');
        ctmRoleAccTerrRoleMap.remove('Customer Experience Manager');
        ctmRoleAccTerrRoleMap.remove('Sales Engineer');
        ctmRoleAccTerrRoleMap.remove('Sales Engineer Manager');
        System.debug('case team roles==='+ctmRoleAccTerrRoleMap);

        //Fetch Sales Engineers for the accounts gathered above from their assigned active Territories
        Map<Id, Territory2> territoryMap = new Map<Id, Territory2>([SELECT Id,
                                                                    (SELECT Id, UserId, RoleInTerritory2, Territory2Id, User.ManagerId
                                                                        FROM UserTerritory2Associations
                                                                        WHERE IsActive = true
                                                                        AND RoleInTerritory2 =: ctmRoleAccTerrRoleMap.keyset()),
                                                                    (SELECT Territory2Id, ObjectId
                                                                        FROM ObjectTerritory2Associations
                                                                        WHERE ObjectId =: accountIdSet)
                                                                    FROM Territory2
                                                                    WHERE Id in (SELECT Territory2Id
                                                                                FROM ObjectTerritory2Association
                                                                                WHERE ObjectId =: accountIdSet
                                                                                AND Territory2.Territory2Model.State = 'Active')]);

        Map<Id, List<UserTerritory2Association>> terrIdUserAssocMap = new Map<Id, List<UserTerritory2Association>>();
        Map<Id, Id> accountIdTerrIdMap = new Map<Id, Id>();

        for(Territory2 eachTerritory : territoryMap.values()) {
            if(!eachTerritory.UserTerritory2Associations.isEmpty()) {
                terrIdUserAssocMap.put(eachTerritory.Id, eachTerritory.UserTerritory2Associations);

                for(ObjectTerritory2Association eachObjectAssoc : eachTerritory.ObjectTerritory2Associations) {
                    accountIdTerrIdMap.put(eachObjectAssoc.ObjectId, eachTerritory.Id);
                }
            }
        }
        System.debug('terrIdUserAssocMap==='+terrIdUserAssocMap);
        System.debug('accountIdTerrIdMap==='+accountIdTerrIdMap);

        Id oldAccountId, territoryId, oldAccountTerritoryId, newAccountTerritoryId;
        CaseTeamMember newCaseMember;
        List<CaseTeamMember> lstToInsert = new List<CaseTeamMember>();
        List<CaseTeamMember> listToDelete = new List<CaseTeamMember>();

        for(Case eachCase : caseList) {
            System.debug('eachCase==='+eachCase);
            oldAccountId = oldMap.get(eachCase.Id).AccountId;
            System.debug('oldAccountId==='+oldAccountId);
            //If old Account Id was blank and new Account Id is not blank, insert Account Territory users as Case team members
            if(oldAccountId == null) {

                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account_Owner__c, mapCaseTeamRoles.get('Account Owner')));
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Account_SAM__c, mapCaseTeamRoles.get('Customer Experience Manager')));
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.RSE_Id__c, mapCaseTeamRoles.get('Sales Engineer')));
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Rubrik_Sales_Engineer__r.ManagerId, mapCaseTeamRoles.get('Sales Engineer Manager')));

                territoryId = accountIdTerrIdMap.get(eachCase.AccountId);
                for(UserTerritory2Association eachUserAssoc : terrIdUserAssocMap.get(territoryId)) {
                    lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachUserAssoc.UserId, mapCaseTeamRoles.get(ctmRoleAccTerrRoleMap.get(eachUserAssoc.RoleInTerritory2))));
                }
            }
            //If old Account Id was not blank and new Account Id is not blank, check if the Territory Id is same for both the
            //Accounts. If yes, do nothing. If not, delete old case team members and insert new ones
            else {
                oldAccountTerritoryId = accountIdTerrIdMap.get(oldAccountId);
                newAccountTerritoryId = accountIdTerrIdMap.get(eachCase.AccountId);

                if(oldAccountTerritoryId == newAccountTerritoryId) {
                    continue;
                }
                else {
                    lstToDelete.addAll(eachCase.TeamMembers);

                    lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account_Owner__c, mapCaseTeamRoles.get('Account Owner')));
                    lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Account_SAM__c, mapCaseTeamRoles.get('Customer Experience Manager')));
                    lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.RSE_Id__c, mapCaseTeamRoles.get('Sales Engineer')));
                    lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Rubrik_Sales_Engineer__r.ManagerId, mapCaseTeamRoles.get('Sales Engineer Manager')));

                    for(UserTerritory2Association eachUserAssoc : terrIdUserAssocMap.get(newAccountTerritoryId)) {
                        lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachUserAssoc.UserId, mapCaseTeamRoles.get(ctmRoleAccTerrRoleMap.get(eachUserAssoc.RoleInTerritory2))));
                    }
                }
            }
        }
        System.debug('lstToInsert==='+lstToInsert);
        System.debug('lstToDelete==='+lstToDelete);
        Database.delete(lstToDelete, false);
        Database.insert(lstToInsert, false);
    }

    public static void insertCtmOnCaseCreateUpdate(Set<Id> caseIdSet) {
        Set<Id> accountIdSet = new Set<Id>();
        List<Case> userOwnerCaseList = new List<Case>();
 		for(Case_Team_Mapping__c mapping : Case_Team_Mapping__c.getall().values()){
            if(!accounttoUserIdsMap.containsKey(mapping.Account_Id__c)){
                accounttoUserIdsMap.put(mapping.Account_Id__c, new Map<Id,Id>());
            }
            accounttoUserIdsMap.get(mapping.Account_Id__c).put(mapping.Original_User_Id__c, mapping.Updated_User_Id__c);
        }
        List<Case> caseList = [SELECT Id, AccountId, Account_Owner__c, RSE_Id__c, OwnerId, Account.Account_SAM__c,
                                Account.Rubrik_Sales_Engineer__r.ManagerId
                    FROM Case
                    WHERE Id =: caseIdSet];

        for(Case c : caseList){
            if(!caseAccountIdMap.containsKey(c.Id)){
                caseAccountIdMap.put(c.Id, c.AccountId);
            }
            if(c.AccountId != null) {
                accountIdSet.add(c.accountId);
            }
                userOwnerCaseList.add(c);
        }

        if(accountIdSet.isEmpty() && userOwnerCaseList.isEmpty()) {
            return;
        }

        List<Case_Team_Member_Role_Mapping__mdt> mappingList = [SELECT MasterLabel, Role_in_Territory__c FROM Case_Team_Member_Role_Mapping__mdt];

        Map<String, String> ctmRoleAccTerrRoleMap = new Map<String, String>();
        for(Case_Team_Member_Role_Mapping__mdt eachMapping : mappingList) {
            ctmRoleAccTerrRoleMap.put(eachMapping.Role_in_Territory__c, eachMapping.MasterLabel);
        }
        ctmRoleAccTerrRoleMap.put('Account Owner', 'Account Owner');
        ctmRoleAccTerrRoleMap.put('Case Owner', 'Case Owner');
        ctmRoleAccTerrRoleMap.put('Customer Experience Manager', 'Customer Experience Manager');
        ctmRoleAccTerrRoleMap.put('Sales Engineer', 'Sales Engineer');
        ctmRoleAccTerrRoleMap.put('Sales Engineer Manager', 'Sales Engineer Manager');
        System.debug('case team roles==='+ctmRoleAccTerrRoleMap);

        Map<String, Id> mapCaseTeamRoles = new Map<String, Id>();
        for(CaseTeamRole eachRole : [SELECT Id, Name FROM CaseTeamRole WHERE Name =: ctmRoleAccTerrRoleMap.values()]){
            mapCaseTeamRoles.put(eachRole.Name, eachRole.Id);
        }

        System.debug('mapCaseTeamRoles==='+mapCaseTeamRoles);

        ctmRoleAccTerrRoleMap.remove('Account Owner');
        ctmRoleAccTerrRoleMap.remove('Customer Experience Manager');
        ctmRoleAccTerrRoleMap.remove('Sales Engineer');
        ctmRoleAccTerrRoleMap.remove('Sales Engineer Manager');
        System.debug('case team roles==='+ctmRoleAccTerrRoleMap);

        //Fetch Sales Engineers for the accounts gathered above from their assigned active Territories
        Map<Id, Territory2> territoryMap = new Map<Id, Territory2>([SELECT Id,
                                                                    (SELECT Id, UserId, RoleInTerritory2, Territory2Id, User.ManagerId
                                                                        FROM UserTerritory2Associations
                                                                        WHERE IsActive = true
                                                                        AND RoleInTerritory2 =: ctmRoleAccTerrRoleMap.keyset()),
                                                                    (SELECT Territory2Id, ObjectId
                                                                        FROM ObjectTerritory2Associations
                                                                        WHERE ObjectId =: accountIdSet)
                                                                    FROM Territory2
                                                                    WHERE Id in (SELECT Territory2Id
                                                                                FROM ObjectTerritory2Association
                                                                                WHERE ObjectId =: accountIdSet
                                                                                AND Territory2.Territory2Model.State = 'Active')]);

        Map<Id, List<UserTerritory2Association>> terrIdUserAssocMap = new Map<Id, List<UserTerritory2Association>>();
        Map<Id, Id> accountIdTerrIdMap = new Map<Id, Id>();

        for(Territory2 eachTerritory : territoryMap.values()) {
            if(!eachTerritory.UserTerritory2Associations.isEmpty()) {
                terrIdUserAssocMap.put(eachTerritory.Id, eachTerritory.UserTerritory2Associations);

                for(ObjectTerritory2Association eachObjectAssoc : eachTerritory.ObjectTerritory2Associations) {
                    accountIdTerrIdMap.put(eachObjectAssoc.ObjectId, eachTerritory.Id);
                }
            }
        }
        System.debug('terrIdUserAssocMap==='+terrIdUserAssocMap);
        System.debug('accountIdTerrIdMap==='+accountIdTerrIdMap);
        insertDeleteCaseTeamMember(userOwnerCaseList, mapCaseTeamRoles, ctmRoleAccTerrRoleMap, terrIdUserAssocMap, accountIdTerrIdMap);
    }

    public static List<Case> getCasesWithAccountOwnerTeamMembers(Set<Id> accountIdSet, Set<String> caseTeamRoles) {
        return [SELECT Id, AccountId, Account_Owner__c, RSE_Id__c, OwnerId, Account.Account_SAM__c,
                    Account.Rubrik_Sales_Engineer__r.ManagerId,
                    (SELECT Id, MemberId
                    FROM TeamMembers
                    WHERE TeamRole.Name =: caseTeamRoles)
                FROM Case
                WHERE AccountId =: accountIdSet
                AND Status NOT IN ('Closed')];
    }

    public static List<Case> getCasesWithoutTeamMembers(Set<Id> accountIdSet) {
        return [SELECT Id, AccountId, Account_Owner__c, RSE_Id__c, OwnerId, Account.Account_SAM__c,
                Account.Rubrik_Sales_Engineer__r.ManagerId
                FROM Case
                WHERE AccountId =: accountIdSet
                AND Status NOT IN ('Closed')];
    }

    public static Map<String, Id> getCaseTeamRoles(List<String> caseTeamRoles) {
        Map<String, Id> mapCaseTeamRoles = new Map<String, Id>();
        System.debug('case team roles==='+caseTeamRoles);
        for(CaseTeamRole eachRole : [SELECT Id, Name FROM CaseTeamRole WHERE Name =: caseTeamRoles]){
            mapCaseTeamRoles.put(eachRole.Name, eachRole.Id);
            System.debug('mapCaseTeamRoles==='+mapCaseTeamRoles);
        }
        return mapCaseTeamRoles;
    }

    private static List<Case_Team_Member_Role_Mapping__mdt> getCaseTeamMemberRoleMapping(Set<String> territoryRoleSet) {
        return [SELECT MasterLabel, Role_in_Territory__c
                FROM Case_Team_Member_Role_Mapping__mdt
                WHERE Role_in_Territory__c =: territoryRoleSet];
    }

    private static List<ObjectTerritory2Association> getObjectTerritory2Assoc(Set<Id> territoryIdSet) {
        return [SELECT Id, Territory2Id, ObjectId
                FROM ObjectTerritory2Association
                WHERE Territory2Id =: territoryIdSet
                AND Territory2.Territory2Model.State = 'Active'];
    }

    private static CaseTeamMember createCaseTeamMemberObject(Id caseId, Id userId, Id caseTeamRoleId) {
        if(caseAccountIdMap.containsKey(caseId)){
            Id accountId = caseAccountIdMap.get(caseId);
            userId = accounttoUserIdsMap.containsKey(accountId) && accounttoUserIdsMap.get(accountId).containsKey(userId) ? accounttoUserIdsMap.get(accountId).get(userId) : userId;
        }
        CaseTeamMember caseTeamMember = new CaseTeamMember();
        caseTeamMember.ParentId = caseId;
        caseTeamMember.MemberId = userId;
        caseTeamMember.TeamRoleId = caseTeamRoleId;
        return caseTeamMember;
    }

    private static void insertDeleteCaseTeamMember(List<Case> caseList, Map<String, Id> mapCaseTeamRoles, Map<String, String> ctmRoleAccTerrRoleMap,
                                                    Map<Id, List<UserTerritory2Association>> terrIdUserAssocMap, Map<Id, Id> accountIdTerrIdMap) {
        List<CaseTeamMember> lstToInsert = new List<CaseTeamMember>();
        List<CaseTeamMember> listToDelete = new List<CaseTeamMember>();
        CaseTeamMember newCaseMember;
        Id territoryId;
        for(Case_Team_Mapping__c mapping : Case_Team_Mapping__c.getall().values()){
            if(!accounttoUserIdsMap.containsKey(mapping.Account_Id__c)){
                accounttoUserIdsMap.put(mapping.Account_Id__c, new Map<Id,Id>());
            }
            accounttoUserIdsMap.get(mapping.Account_Id__c).put(mapping.Original_User_Id__c, mapping.Updated_User_Id__c);
        }
        for(Case eachCase : caseList) {
            if(!caseAccountIdMap.containsKey(eachCase.Id)){
                caseAccountIdMap.put(eachCase.Id, eachCase.AccountId);
            }
                if(!eachCase.TeamMembers.isEmpty()) {
                    newCaseMember = new CaseTeamMember();
                    newCaseMember = eachCase.TeamMembers[0];

                    if(eachCase.Account_Owner__c != newCaseMember.MemberId) {
                        listToDelete.add(newCaseMember);
                    }
                }

            lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account_Owner__c, mapCaseTeamRoles.get('Account Owner')));
            lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Account_SAM__c, mapCaseTeamRoles.get('Customer Experience Manager')));
            lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.RSE_Id__c, mapCaseTeamRoles.get('Sales Engineer')));
            lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.Account.Rubrik_Sales_Engineer__r.ManagerId, mapCaseTeamRoles.get('Sales Engineer Manager')));

                if(eachCase.OwnerId != null && (String.valueOf(eachCase.OwnerId).startsWith('005'))) {
                lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachCase.OwnerId, mapCaseTeamRoles.get('Case Owner')));
                }

                territoryId = accountIdTerrIdMap.get(eachCase.AccountId);
                if(territoryId != null) {
                    for(UserTerritory2Association eachUserAssoc : terrIdUserAssocMap.get(territoryId)) {
                    lstToInsert.add(createCaseTeamMemberObject(eachCase.Id, eachUserAssoc.UserId, mapCaseTeamRoles.get(ctmRoleAccTerrRoleMap.get(eachUserAssoc.RoleInTerritory2))));
                    }
                }
        }
        System.debug('listToDelete==='+listToDelete);
        System.debug('lstToInsert==='+lstToInsert);
        Database.delete(listToDelete, false);
        Database.insert(lstToInsert, false);
    }
}