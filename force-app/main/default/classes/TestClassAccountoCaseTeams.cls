/********************************************************************************************************
* Name              : TestClassAccountoCaseTeams
* Purpose           : TestClassAccountoCaseTeams is Used for Testing AccounttoCaseTeams Trigger
*********************************************************************************************************/
@isTest
public class TestClassAccountoCaseTeams {
    Public static TestMethod Void TestClassAccountToCaseTeams(){
         insert new TriggerControl__c(Name='AccounttoCaseTeamTrigger');
        CaseTeamRole caseTeamRoleAOId = [select id,name from caseteamrole where name = 'Account Owner'];
        CaseTeamRole caseTeamRoleAMId = [select id,name from caseteamrole where name = 'Account Manager'];
        CaseTeamRole caseTeamRoleSEId = [select id,name from caseteamrole where name = 'Sales Engineer'];
        CaseTeamRole caseTeamRoleSEMId = [select id,name from caseteamrole where name = 'Sales Engineer Manager'];
        CaseTeamRole caseTeamRoleCEMId = [select id,name from caseteamrole where name = 'Customer Experience Manager'];

        User usr = new User();
        usr.FirstName = 'Rajesh';
        usr.LastName = 'Gosety';
        usr.Username = 'rajesh.gos@rubrik.com';
        usr.Email = 'rajesh.gos@rubrik.com';
        usr.EmailEncodingKey = 'UTF-8';
        usr.Alias = 'rgose';    
        usr.CommunityNickname = 'rgos';
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.LocaleSidKey = 'en_IN';
        usr.ProfileId = '00e400000014GzH';
        usr.LanguageLocaleKey = 'en_US';
        insert Usr;

        User usr2 = new User();
        usr2.FirstName = 'Naveen';
        usr2.LastName = 'Kum';
        usr2.Username = 'naveen.kum@rubrik.com';
        usr2.Email = 'naveen.kum@rubrik.com';
        usr2.EmailEncodingKey = 'UTF-8';
        usr2.Alias = 'nkmr';    
        usr2.CommunityNickname = 'nkmr';
        usr2.TimeZoneSidKey = 'America/Los_Angeles';
        usr2.LocaleSidKey = 'en_IN';
        usr2.ProfileId = '00e400000014GzH';
        usr2.LanguageLocaleKey = 'en_US';
        insert Usr2;

        User usr3 = new User();
        usr3.FirstName = 'Bhanu';
        usr3.LastName = 'Mumman';
        usr3.Username = 'bhanu.mumman@rubrik.com';
        usr3.Email = 'bhanu.mumman@rubrik.com';
        usr3.EmailEncodingKey = 'UTF-8';
        usr3.Alias = 'bhmu';    
        usr3.CommunityNickname = 'bhmu';
        usr3.TimeZoneSidKey = 'America/Los_Angeles';
        usr3.LocaleSidKey = 'en_IN';
        usr3.ProfileId = '00e400000014GzH';
        usr3.LanguageLocaleKey = 'en_US';
        insert Usr3;

        User usr4 = new User();
        usr4.FirstName = 'kiet';
        usr4.LastName = 'Duong';
        usr4.Username = 'kiet.dong@rubrik.com';
        usr4.Email = 'kiet.dong@rubrik.com';
        usr4.EmailEncodingKey = 'UTF-8';
        usr4.Alias = 'kidu';    
        usr4.CommunityNickname = 'kidu';
        usr4.TimeZoneSidKey = 'America/Los_Angeles';
        usr4.LocaleSidKey = 'en_IN';
        usr4.ProfileId = '00e400000014GzH';
        usr4.LanguageLocaleKey = 'en_US';
        insert Usr4;

        Account a = new Account();
        a.Name = 'test34343434';
        a.Heads_Up_to_Support_Team__c = 'Hello';
        a.OwnerId = Usr.Id;
        a.Case_Notifications__c = True;
        insert a;

        Account a1 = new Account();
        a1.Name = 'test34343434';
        a1.Heads_Up_to_Support_Team__c = 'Hello';
        a1.OwnerId = Usr.Id;
        a1.Rubrik_Sales_Engineer__c = Usr2.Id;
        a1.Case_Notifications__c = True;
        insert a1;

        Account a2 = new Account();
        a2.Name = 'test34343434';
        a2.Heads_Up_to_Support_Team__c = 'Hello';
        a2.OwnerId = Usr.Id;
        a2.Rubrik_Sales_Engineer__c = Usr2.Id;
        a2.Case_Notifications__c = True;
        insert a2;

        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.AccountId = a.Id;
        atm1.TeamMemberRole = 'Sales Engineer';
        atm1.UserId = Usr.Id;
        insert atm1;

        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.AccountId = a2.Id;
        atm2.TeamMemberRole = 'Sales Engineer Manager';
        atm2.UserId = Usr2.Id;
        insert atm2;

        AccountTeamMember atm3 = new AccountTeamMember();
        atm3.AccountId = a2.Id;
        atm3.TeamMemberRole = 'Customer Experience Manager';
        atm3.UserId = Usr3.Id;
        insert atm3;

        AccountTeamMember atm4 = new AccountTeamMember();
        atm4.AccountId = a1.Id;
        atm4.TeamMemberRole = 'Account Manager';
        atm4.UserId = Usr4.Id;
        insert atm4;

        Contact ct = new Contact();
        ct.Email = 'usmummaneni@gmail.com';
        ct.FirstName = 'hbn';
        ct.LastName = 'hi';
        ct.Account=a;
        insert ct;

        Case caseTest = new Case();
        caseTest.Subject = 'testing one more';
        caseTest.Description = 'Helo';
        caseTest.ContactId = ct.Id;
        caseTest.Priority ='P2';
        caseTest.AccountId = a.Id;
        caseTest.Origin = 'Portal';
        insert caseTest;

        List <AccountTeamMember> accTeamMemb = new List<AccountTeamMember>();
        List <Account> accList = new List<Account>();
        accTeamMemb = [select id,AccountId,TeamMemberRole,UserId from AccountTeamMember where AccountId =: caseTest.AccountId];
        accList = [select id,Case_Notifications__c,Rubrik_Sales_Engineer__c from Account where Id =: caseTest.AccountId Limit 1];

        Case caseTest1 = new Case();
        caseTest1.Subject = 'testing one more2';
        caseTest1.ContactId = ct.Id;
        caseTest1.Priority ='P2';
        caseTest1.AccountId = a1.Id;
        insert caseTest1;

        Case caseTest2 = new Case();
        caseTest2.Subject = 'testing one more2';
        caseTest2.ContactId = ct.Id;
        caseTest2.Priority ='P2';
        caseTest2.AccountId = a2.Id;
        insert caseTest2;

        List <AccountTeamMember> accTeamMemb2 = new List<AccountTeamMember>();
        accTeamMemb2 = [select id,AccountId,TeamMemberRole,UserId from AccountTeamMember where AccountId =: caseTest1.AccountId];
        Integer intAccTeam = accTeamMemb2.size();
        
        try{
               If(caseTest1.RSE_Id__c != Null && intAccTeam <= 0)                   
                {
                    CaseTeamMember newCaseMember = new CaseTeamMember();
                      newCaseMember.ParentId = caseTest1.Id;
                      newCaseMember.MemberId = caseTest1.RSE_Id__c;
                      newCaseMember.TeamRoleId = caseTeamRoleSEId.Id;
                      insert newCaseMember;
                }
           }
           catch (System.DmlException e)
           {
                System.DmlException e1 = e;
           }
        
        for(AccountTeamMember actem : accTeamMemb)
            {                            
                try
                {
                    If(actem != Null && actem.TeamMemberRole == 'Sales Engineer' && caseTeamRoleSEId.Id != Null)
                    {
                        CaseTeamMember newCaseMember = new CaseTeamMember();
                        newCaseMember.ParentId = caseTest.Id;
                        newCaseMember.MemberId = actem.UserId;
                        newCaseMember.TeamRoleId = caseTeamRoleSEId.Id;
                        insert newCaseMember;
                    }                    
                    If(actem != Null && actem.TeamMemberRole == 'Customer Experience Manager' && caseTeamRoleCEMId.Id != Null)
                    {
                        CaseTeamMember newCaseMember = new CaseTeamMember();
                        newCaseMember.ParentId = caseTest.Id;
                        newCaseMember.MemberId = actem.UserId;
                        newCaseMember.TeamRoleId = caseTeamRoleCEMId.Id;
                        insert newCaseMember;
                    }
                    If(actem != Null && actem.TeamMemberRole == 'Sales Engineer Manager' && caseTeamRoleSEMId.Id != Null)
                    {
                        CaseTeamMember newCaseMember = new CaseTeamMember();
                        newCaseMember.ParentId = caseTest.Id;
                        newCaseMember.MemberId = actem.UserId;
                        newCaseMember.TeamRoleId = caseTeamRoleSEMId.Id;
                        insert newCaseMember;
                    }
                    If(actem != Null && actem.TeamMemberRole == 'Account Manager' && caseTeamRoleSEMId.Id != Null)
                    {
                        CaseTeamMember newCaseMember = new CaseTeamMember();
                        newCaseMember.ParentId = caseTest.Id;
                        newCaseMember.MemberId = actem.UserId;
                        newCaseMember.TeamRoleId = caseTeamRoleAMId.Id;
                        insert newCaseMember;
                    }                    
                }            
                catch (System.NullPointerException e) 
                { 
                    System.NullPointerException e1 = e; // can be assigned to a variable to display a user-friendly error message
                }
                catch (System.DmlException e5)
                {
                    System.DmlException e2 = e5;
                }
                catch (system.QueryException e4)
                {
                    System.QueryException e3 = e4;
                }
            }
    }
    
    Public static TestMethod Void TestClassAccountToCaseTeamsForTeamMembAsNull(){
        
        User usr = new User();
        usr.FirstName = 'Rajesh';
        usr.LastName = 'Gosety';
        usr.Username = 'rajesh.gos@rubrik.com';
        usr.Email = 'rajesh.gos@rubrik.com';
        usr.EmailEncodingKey = 'UTF-8';
        usr.Alias = 'rgose';    
        usr.CommunityNickname = 'rgos';
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.LocaleSidKey = 'en_IN';
        usr.ProfileId = '00e400000014GzH';
        usr.LanguageLocaleKey = 'en_US';
        insert Usr;


        Account a = new Account();
        a.Name = 'test34343434';
        a.Heads_Up_to_Support_Team__c = 'Hello';
        a.OwnerId = Usr.Id;
        a.Rubrik_Sales_Engineer__c = Usr.Id;
        a.Case_Notifications__c = True;
        insert a;

        Contact ct = new Contact();
        ct.Email = 'usmummaneni@gmail.com';
        ct.FirstName = 'hbn';
        ct.LastName = 'hi';
        ct.Account=a;
        insert ct;

        Case caseTest = new Case();
        caseTest.Subject = 'testing one more';
        caseTest.Description = 'Helo';
        caseTest.ContactId = ct.Id;
        caseTest.Priority ='P2';
        caseTest.AccountId = a.Id;
        caseTest.Origin = 'Portal';
        insert caseTest;
    }
    
    Public static TestMethod Void TestClassAccountToCaseTeamsForNewTeamMember(){
        
        User usr = new User();
        usr.FirstName = 'Rajesh';
        usr.LastName = 'Gosety';
        usr.Username = 'rajesh.gos@rubrik.com';
        usr.Email = 'rajesh.gos@rubrik.com';
        usr.EmailEncodingKey = 'UTF-8';
        usr.Alias = 'rgose';    
        usr.CommunityNickname = 'rgos';
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        usr.LocaleSidKey = 'en_IN';
        usr.ProfileId = '00e400000014GzH';
        usr.LanguageLocaleKey = 'en_US';
        insert Usr;


        Account a = new Account();
        a.Name = 'test34343434';
        a.Heads_Up_to_Support_Team__c = 'Hello';
        a.OwnerId = Usr.Id;
        a.Rubrik_Sales_Engineer__c = Usr.Id;
        a.Case_Notifications__c = True;
        insert a;

        Contact ct = new Contact();
        ct.Email = 'usmummaneni@gmail.com';
        ct.FirstName = 'hbn';
        ct.LastName = 'hi';
        ct.Account=a;
        insert ct;
        
        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.AccountId = a.Id;
        atm1.TeamMemberRole = 'Sales Engineer1';
        atm1.UserId = Usr.Id;
        insert atm1;

        Case caseTest = new Case();
        caseTest.Subject = 'testing one more';
        caseTest.Description = 'Helo';
        caseTest.ContactId = ct.Id;
        caseTest.Priority ='P2';
        caseTest.AccountId = a.Id;
        caseTest.Origin = 'Portal';
        insert caseTest;
    }
}