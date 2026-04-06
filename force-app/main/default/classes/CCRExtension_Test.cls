/********************************************************************************************************
* Name              : CCRExtension_Test
* Purpose           : CCRExtension_Test is Used for Testing CCRExtension Class
*********************************************************************************************************/
@isTest
public class CCRExtension_Test{
    
    static testMethod void testGetDisplayName(){
        System.runAs(new User(Id = UserInfo.getUserId())) {
            Id usrId = UserInfo.getUserId();
            User usr = [Select id,Country From USER WHERE Id=:usrId LIMIT 1];
            usr.Country='India';
            update usr;
            
            Incentives__c incent = new Incentives__c();
            incent.Name='Test Incentives';
            insert incent;
            CCR__c ccr = new CCR__c ();
            
            ccr.RecordTypeId = Schema.SObjectType.CCR__c.getRecordTypeInfosByName().get('Internal CCR').getRecordTypeId(); 
            ccr.Affective_Person__c = UserInfo.getUserId();   
            ccr.User__c = 'Pending';
            ccr.CCR_Type__c = 'Other';
            ccr.Justifications__c = 'Other';
            ccr.Comment__c = 'test';
            ccr.Effective_Date__c=System.Today();
            ccr.Effective_End_Date__c = System.Today().addDays(90);
            insert ccr;
            
            PageReference pageRef = Page.OrderOverridePage; // Adding VF page Name here
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('incent', incent.id);//for page reference
            pageRef.getParameters().put('uid', UserInfo.getUserId());//for page reference
            pageRef.getParameters().put('type', 'Justifications');//for page reference
            pageRef.getParameters().put('fieldset', 'brik_dollar_incentive_claim_req');//for page reference
            

            ApexPages.standardController controller = new ApexPages.standardController(ccr);
            
            //=============
            List<Schema.FieldSetMember> fsm;
            
            Map<String, Schema.FieldSet> FsMap = Schema.SObjectType.CCR__c.fieldSets.getMap();
            System.debug('FsMap===>'+FsMap);
            
            fsm = SobjectType.CCR__c.FieldSets.getMap().get('brik_dollar_incentive_claim_req').getFields();
            System.debug('fsm===>'+fsm);
            //=============
            
        
            Test.startTest();
            CCRExtension cCRExt = new CCRExtension(controller);
            SobjectType.CCR__c.FieldSets.getMap();
            //cCRExt.fsm=SobjectType.CCR__c.FieldSets.getMap().get('brik_dollar_incentive_claim_req').getFields();
            cCRExt.saveRecord();
            Test.stopTest();
        
        }
        
    }
}