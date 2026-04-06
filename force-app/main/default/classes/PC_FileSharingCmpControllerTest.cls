@isTest
public class PC_FileSharingCmpControllerTest {
	@isTest static void PC_FileSharingCmpControllertestMethod() {
        List<ChannelProgramLevel> cplRecords = new List<ChannelProgramLevel>();
        List<ChannelProgram> cpRecords = new List<ChannelProgram>();
        List<Account> accRecords = new List<Account>();
        
        User u = [select id,name from user where profile.name ='System Administrator' and userRoleId != null and isactive=true limit 1];
        List<User> lstUserRec = new List<User>();
        Account accRec = new Account();
        system.runas(u){
            accRec = ShGl_TestFactory.testMethod_PartnerAccount('Test Account');
        }
        accRecords.add(accRec);
        ChannelProgram cp = new ChannelProgram(Name='Authorized');
        insert cp;
        cpRecords.add(cp);
        ChannelProgramLevel cpl = new ChannelProgramLevel(ProgramId=cp.Id,Name='EMEA',Rank=1);
        insert cpl;
        cplRecords.add(cpl);
        
		test.startTest();
        File_Sharing__c fs = new File_Sharing__c(Active__c=true,AccountIds__c=accRec.Id);
        insert fs;
        PC_FileSharingCmpController.saveRecord(fs,accRecords,cpRecords,cplRecords);
        PC_FileSharingCmpController.getCPLNames(fs.Id);
        PC_FileSharingCmpController.getCPNames(fs.Id);
        PC_FileSharingCmpController.getAccNames(fs.Id);
        PC_FileSharingCmpController.getFSRecord(fs.Id);
        test.stopTest();
    }
}