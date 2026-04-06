@isTest
public with sharing class PatchManagerTrigger_Test {
    @isTest static void testInsert(){
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].Zip_code__c = '53198';
        patchList[0].City__c = 'Bangalore';
        update patchList;
        try{
            patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
            patchList[0].SMB_Owner__c=userInfo.getUserId();
            patchList[1].SMB_Owner__c=userInfo.getUserId();
            patchList[1].County__c='India';
            patchList[1].CountryGlobal__c = 'India';
            patchList[0].Zip_code__c = '53198';
            patchList[0].City__c = 'Bangalore';
            update patchList;
        }catch(Exception e){

        }
    }
    @isTest static void testInsert2(){
        List<PatchManager__c> patchList=new List<PatchManager__c>();
        patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
        patchList[0].SMB_Owner__c=userInfo.getUserId();
        patchList[1].SMB_Owner__c=userInfo.getUserId();
        patchList[1].County__c='India';
        patchList[1].CountryGlobal__c = 'India';
        patchList[0].City__c = 'Bangalore';
        update patchList;
        try{
            patchList = ShGl_TestFactory.testMethod_createPatchManager(2);
            patchList[0].SMB_Owner__c=userInfo.getUserId();
            patchList[1].SMB_Owner__c=userInfo.getUserId();
            patchList[1].County__c='India';
            patchList[1].CountryGlobal__c = 'India';
            patchList[0].City__c = 'Bangalore';
            update patchList;
        }catch(Exception e){

        }
    }
}