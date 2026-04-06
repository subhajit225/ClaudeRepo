@isTest
public class MQLRoutingOwnerAssignService1Test{
    
    @testSetup static void testDataSetup(){
        User user1 = createUserAdmin('tUser1');
        system.runas(user1){
            //insert Custom Setting  implements HttpCalloutMock
            WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
            WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
            insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
            Lead newLead = new Lead();
            newLead.firstName = 'fname';
            newLead.lastName = 'lname';
            newLead.CountryCode = 'IN';
            newLead.Email = 'test@rubrik.com';
            newLead.Company = 'trest'; 
            insert newLead;
            PatchManager__c ptch = new PatchManager__c();
            ptch.Country__c = 'US';
            ptch.CountryGlobal__c='United States';
            ptch.SMB_Owner__c=userInfo.getUserId();
            ptch.Zip_code__c = '20006';
            insert ptch;
            List<Territory2Model> TModel = [select id,Name from territory2model where State ='Active'];
            List<Territory2Type> terrType = [Select Id, DeveloperName from Territory2Type where DEveloperNAme = 'Territory'];
            Territory2 terr = new Territory2();
            terr.Name = 'TESTTERR';
            terr.DeveloperName = 'TESTTERR';
            terr.Adaptive_Territory_Id__c = '999999';
            terr.Territory2ModelId = TModel[0].Id;
            terr.Territory2TypeId = terrType[0].Id;
            insert terr;
            
              //Create Parent Group
            Group grp = new Group();
            grp.name = 'AMER-MM';
            grp.Type = 'Queue'; 
            Insert grp; 
            
            Group grp1 = new Group();
            grp1.name = 'FED_Queue';
            grp1.Type = 'Queue'; 
            Insert grp1; 
            
            //Create Group Member
            GroupMember grpMem1 = new GroupMember();
            grpMem1.UserOrGroupId = user1.Id;
            grpMem1.GroupId = grp.Id;
            Insert grpMem1;
        }
    }
    static User createUserAdmin(string alias) {
        Profile profile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator']; //System Administrator
        UserRole portalRole = [SELECT Id FROM UserRole WHERE Name = 'CEO' LIMIT 1];
        User sysAdmin = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile1.Id,
            Username = System.now().millisecond() + 'sys1Admin123@randomtestdomain.com',
            Alias = alias,
            Email = System.now().millisecond() + 'random1.email2343@randomtestdomain.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'test',
            Lastname = 'test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );
        Database.insert(sysAdmin);
        return sysAdmin;
    }
    @isTest static void testonAccountRoutingSource(){
        Account act = new Account(Name = 'Test account',Website='www.test-rubrik.com');
        insert act;
        Opportunity opp= new Opportunity(name='Test Opp',accountId=act.id,stagename='Approved',Amount=1000,Lead_Email_Hidden__c='test@rubrik.com',closeDate=Date.today());
        insert opp;
        Lead newLead = [SELECT Id,L2A_Confidence_Code__c,L2A_Account__c,Winning_L2A_Account__c,Last_Applied_Routing_Modifier__c FROM Lead limit 1];
        newLead.L2A_Confidence_Code__c=3;
        newLead.L2A_Account__c = act.Id;
        newLead.Winning_L2A_Account__c = act.Id;
        update newLead;
        
        String expectedVal = callAssignOwnerMethod(newLead, 'Active Opportunity');
        Assert.areEqual('Active Opportunity',expectedVal);
    }
    @isTest static void testonAccTerrRoutingSource(){
        Account act = new Account(Name = 'Test account',Website='www.test-rubrik.com');
        insert act;
         List<Territory2> terrList =[select id,Adaptive_Territory_Id__c from territory2 where Territory2Model.State ='Active' and Territory2Type.DeveloperName='Territory' and DeveloperName!='Unassigned'limit 1];
        insert new ObjectTerritory2Association(ObjectId =act.id , Territory2Id =terrList[0].id, AssociationCause ='Territory2Manual');
        
        Lead newLead = [SELECT Id,L2A_Confidence_Code__c,L2A_Account__c,Winning_L2A_Account__c FROM Lead limit 1];
        newLead.L2A_Confidence_Code__c=3;
        newLead.L2A_Account__c = act.Id;
        newLead.Winning_L2A_Account__c = act.Id;
        update newLead;
        
        String expectedVal = callAssignOwnerMethod(newLead, 'Prospect');
        Assert.areEqual('Prospect',expectedVal);
    }
    @isTest static void testonRoundRobinFallback(){
        Lead newLead = [SELECT Id,Last_Applied_Routing_Modifier__c,Direct_Routing_AE__c	,L2A_Confidence_Code__c,L2A_Account__c,Winning_L2A_Account__c FROM Lead limit 1];
        newLead.Last_Applied_Routing_Modifier__c = 'Direct Route to User';
        newLead.L2A_Confidence_Code__c = 3;
        update newLead;
        String expectedVal = callAssignOwnerMethod(newLead, 'Campaign to User');
        Assert.areEqual('Campaign to User',expectedVal);
        
    }
    @isTest static void testonPatchKeyRoutingSource(){
        Account act = new Account(Name = 'Test account',Website='www.test-rubrik.com');
        insert act;
        PatchManager__c ptch = [SELECT Id FROM PatchManager__c LIMIT 1];
        Lead newLead = [SELECT Id,L2A_Confidence_Code__c,L2A_Account__c,Winning_L2A_Account__c,Last_Applied_Routing_Modifier__c FROM Lead limit 1];
        newLead.Winning_L2A_Account__c = act.Id;
        newLead.PatchManager__c = ptch.Id;
        update newLead;
        String expectedVal = callAssignOwnerMethod(newLead, 'Domain Match');
        Assert.areEqual('Domain Match',expectedVal);
    }
    @isTest static void testonPatchKeyRRRoutingSource(){
        User userObj = [SELECT Id from User where isactive =true LIMIT 1];
        
        PatchManager__c ptch = [SELECT Id FROM PatchManager__c LIMIT 1];
        
        Patch_Manager_User_Pool__c poolData = new Patch_Manager_User_Pool__c();
        poolData.Patch_Key__c=ptch.id;
        poolData.User__c=userObj.id;
        insert poolData;
        
        PTOCalendar__c ptoCal = new PTOCalendar__c();
        ptoCal.User__c = userObj.id;
        ptoCal.StartDate__c = Date.today();
        ptoCal.EndDate__c = Date.today();
        insert ptoCal;
        
        Lead newLead = [SELECT Id,L2A_Confidence_Code__c,L2A_Account__c,Winning_L2A_Account__c,PatchManager__c,Last_Applied_Routing_Modifier__c FROM Lead limit 1];
        newLead.PatchManager__c = ptch.Id;
        update newLead;
        String expectedVal = callAssignOwnerMethod(newLead, 'Geographic');
        Assert.areEqual('Geographic',expectedVal); 
    }
   
    @isTest static void testoncurrRecRoutingSource(){
        User userObj = [SELECT Id from User LIMIT 1];
        Lead newLead = [SELECT Id,Partner_of_Record__c,L2A_Account__c,Winning_L2A_Account__c,Last_Applied_Routing_Modifier__c FROM Lead limit 1];
        newLead.Partner_of_Record__c = userObj.Id;
        update newLead;
        String expectedVal = callAssignOwnerMethod(newLead, 'Campaign - Partner of Record');
        Assert.areEqual('Campaign - Partner of Record',expectedVal);
    }
    @isTest static void testonRoundRobinRoutingSource(){
        Lead newLead = [SELECT Id,Last_Applied_Routing_Modifier__c,L2A_Account__c,Winning_L2A_Account__c FROM Lead limit 1];
        newLead.Last_Applied_Routing_Modifier__c = 'Route to Federal';
        update newLead;
        String expectedVal = callAssignOwnerMethod(newLead, 'Campaign - To Fed Queue');
        Assert.areEqual('Campaign - To Fed Queue',expectedVal);
    }
    
    public static Map<Id, Lead_Routing_Rule__mdt> getLeadRoutingRules(Id leadId, String msLabel){
        Lead_Routing_Rule__mdt ldRoutingRule = [SELECT MasterLabel, Priority__c,DeveloperName,ObjectName__c,Routing_Source__c,User_Role_Field_Value__c,Fallback_Source__c,Fallback__c,Campaign_Routing_Method__c,Account_Status__c,BDM_Formula__c,PatchManager_Type__c 
                                                FROM Lead_Routing_Rule__mdt WHERE MasterLabel =: msLabel LIMIT 1];
        Map<Id, Lead_Routing_Rule__mdt> leadToRule = new Map<Id, Lead_Routing_Rule__mdt>();
        leadToRule.put(leadId, ldRoutingRule);
        return leadToRule;
    }
    public static String callAssignOwnerMethod(Lead newLead, String msLabel){
        Set<id> leadIds = new Set<id>();
        leadIds.add(newLead.Id);
        Map<Id,Lead> leadIdToLead = new Map<Id,Lead>();
        Map<Id, Boolean> mapIdWithFalseFallback = new Map<Id, Boolean>();
        leadIdToLead.put(newLead.id,newLead);
        mapIdWithFalseFallback.put(newLead.id, false);
        Map<Id, Lead_Routing_Rule__mdt> leadToRule = getLeadRoutingRules(newLead.id, msLabel);
        List<Lead_Routing_Rule__mdt> allRules = new List<Lead_Routing_Rule__mdt>();
        for(Id ruleKey:leadToRule.keySet()) {
             allRules.add(leadToRule.get(ruleKey));
        }
       
        MQLRoutingOwnerAssignService1 ownerService = new MQLRoutingOwnerAssignService1(new Set<Id>(leadIds),allRules);
        ownerService.assignOwners(leadToRule, leadIdToLead, mapIdWithFalseFallback);
        return leadToRule.get(newLead.id).MasterLabel;
    }
    @isTest
    public static void queueMemeberTest(){
        List<Group> GroupList =[Select id,name from Group where Type='Queue' AND Name ='AMER-MM' Limit 10];
        set<Id> queueIds = new set<Id>();
        queueIds.add(GroupList[0].Id);
        User UserObj = [SELECT Id FROM User Where Alias = 'tUser1' LIMIT 1];
        PTOCalendar__c ptoCal = new PTOCalendar__c();
        ptoCal.User__c = userObj.id;
        ptoCal.StartDate__c = Date.today();
        ptoCal.EndDate__c = Date.today();
        insert ptoCal;
       
        Map<Id, Set<Id>> queueMember =  MQLRoutingOwnerAssignService1.getAvailableUsersQueue(queueIds);
        DateTime myDate = MQLRoutingOwnerAssignService1.getUTCDateTime(system.now());
        Assert.areEqual(True,queueMember.containsKey(GroupList[0].Id));
    }
    
}