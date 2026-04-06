@isTest
public class AllianceLeadConvertExtention_Test {
    public static testMethod void AllianceLeadConvertExtentionTest(){
        TestDataFactory.setWorkflowTriggerBypassCS(true);
        Lead l = TestDataFactory.insertLead();
        l.LastName='Test';
        l.Company='unitTest';
        //EXCL-6
        l.Status = 'Open';
        insert l;
        Alliance_Lead__c leadObj=new Alliance_Lead__c();
        leadObj.Alliance_ATU__c='Test';
        leadObj.Alliance_Partner__c='Test';
        leadObj.Customer__c='unitTest';
        leadObj.Name='Test';
        insert leadObj;
        System.assertEquals(leadObj.Name,'Test');
        String jsonStr=' [{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwHEAU"},"Id":"a5L290000005KwHEAU","Name":"Lead_Type__c","LeadFields__c":"Lead_Type__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwlEAE"},"Id":"a5L290000005KwlEAE","Name":"Current_Alliance_Customer__c","LeadFields__c":"Current_Alliance_Customer__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwvEAE"},"Id":"a5L290000005KwvEAE","Name":"Alliance_Partner__c","LeadFields__c":"Alliance_Partner__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005Kx5EAE"},"Id":"a5L290000005Kx5EAE","Name":"Campaign__c","LeadFields__c":"Campaign"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005Kx0EAE"},"Id":"a5L290000005Kx0EAE","Name":"Date_Mapped__c","LeadFields__c":"Date_Mapped__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwCEAU"},"Id":"a5L290000005KwCEAU","Name":"Customer__c","LeadFields__c":"Company"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwREAU"},"Id":"a5L290000005KwREAU","Name":"Rubrik_BDM__c","LeadFields__c":"Rubrik_BDM__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwgEAE"},"Id":"a5L290000005KwgEAE","Name":"Alliance_ATU__c","LeadFields__c":"Alliance_ATU__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwqEAE"},"Id":"a5L290000005KwqEAE","Name":"Comments__c","LeadFields__c":"Comments__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KxIEAU"},"Id":"a5L290000005KxIEAU","Name":"Name","LeadFields__c":"Lastname"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwMEAU"},"Id":"a5L290000005KwMEAU","Name":"Rubrik_AE__c","LeadFields__c":"Rubrik_AE__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwWEAU"},"Id":"a5L290000005KwWEAU","Name":"Rubrik_Region__c","LeadFields__c":"Rubrik_Region__c"}]';
        Type t=Type.forName('List<AllianceleadLeadMapping__c>'); 
        List<SObject> lSOOM = (List<SObject>)JSON.deserialize(jsonStr, t);
        List<AllianceleadLeadMapping__c> lstAllianceLeadMapping = (List<AllianceleadLeadMapping__c>)lSOOM;
        for(AllianceleadLeadMapping__c v:lstAllianceLeadMapping){
            v.Id=null;
        }
        insert lstAllianceLeadMapping;
        list<AllianceleadLeadMapping__c> AllianceList=[Select id,name,LeadFields__c from AllianceleadLeadMapping__c];
        System.assert(AllianceList.size()==lstAllianceLeadMapping.size(),'List is not inserted');
        Map<String,String> mapOfMapping=new Map<String,String>();
        
        ApexPages.StandardController std=new ApexPages.StandardController(leadObj);
        AllianceLeadConvertExtention testDeal=new AllianceLeadConvertExtention(std);
        PageReference pgf=Page.AllianceLeadConvert;
        pgf.getParameters().put('Id',leadObj.Id);
        String id = pgf.getParameters().get('id');
        System.assertEquals(true,id!=null);
        Test.setCurrentPage(pgf);
        testDeal.getMapping();
        PageReference testPage=testDeal.convertToLead();
        
        
    }
    public static testMethod void unitTest(){
        TestDataFactory.setWorkflowTriggerBypassCS(true);
        Alliance_Lead__c leadObj=new Alliance_Lead__c();
        leadObj.Alliance_ATU__c='Test';
        leadObj.Alliance_Partner__c='Test';
        leadObj.Customer__c='unitTest';
        leadObj.Name='Test';
        insert leadObj;
        System.assertEquals(leadObj.Name,'Test');
        String jsonStr=' [{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwHEAU"},"Id":"a5L290000005KwHEAU","Name":"Lead_Type__c","LeadFields__c":"Lead_Type__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwvEAE"},"Id":"a5L290000005KwvEAE","Name":"Alliance_Partner__c","LeadFields__c":"Alliance_Partner__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005Kx5EAE"},"Id":"a5L290000005Kx5EAE","Name":"Campaign__c","LeadFields__c":"Campaign"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwCEAU"},"Id":"a5L290000005KwCEAU","Name":"Customer__c","LeadFields__c":"Company"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwREAU"},"Id":"a5L290000005KwREAU","Name":"Rubrik_BDM__c","LeadFields__c":"Rubrik_BDM__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwqEAE"},"Id":"a5L290000005KwqEAE","Name":"Comments__c","LeadFields__c":"Comments__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KxIEAU"},"Id":"a5L290000005KxIEAU","Name":"Name","LeadFields__c":"Lastname"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwMEAU"},"Id":"a5L290000005KwMEAU","Name":"Rubrik_AE__c","LeadFields__c":"Rubrik_AE__c"},{"attributes":{"type":"AllianceleadLeadMapping__c","url":"/services/data/v43.0/sobjects/AllianceleadLeadMapping__c/a5L290000005KwWEAU"},"Id":"a5L290000005KwWEAU","Name":"Rubrik_Region__c","LeadFields__c":"Rubrik_Region__c"}]';
        Type t=Type.forName('List<AllianceleadLeadMapping__c>'); 
        List<SObject> lSOOM = (List<SObject>)JSON.deserialize(jsonStr, t);
        List<AllianceleadLeadMapping__c> lstAllianceLeadMapping = (List<AllianceleadLeadMapping__c>)lSOOM;
        for(AllianceleadLeadMapping__c v:lstAllianceLeadMapping){
            v.Id=null;
        }
        insert lstAllianceLeadMapping;
        list<AllianceleadLeadMapping__c> AllianceList=[Select id,name,LeadFields__c from AllianceleadLeadMapping__c];
        System.assert(AllianceList.size()==lstAllianceLeadMapping.size(),'List is not inserted');
        Map<String,String> mapOfMapping=new Map<String,String>();
        
        ApexPages.StandardController std=new ApexPages.StandardController(leadObj);
        AllianceLeadConvertExtention testDeal=new AllianceLeadConvertExtention(std);
        PageReference pg=Page.AllianceLeadConvert;
        pg.getParameters().put('Id',leadObj.Id);
        String id = pg.getParameters().get('id');
        System.assertEquals(true,id!=null);
        Test.setCurrentPage(pg);
        testDeal.getMapping();
        PageReference testPage=testDeal.convertToLead();
        
        
        
    }
    
}