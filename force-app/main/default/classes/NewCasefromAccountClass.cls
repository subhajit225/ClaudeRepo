/*
* @Author           :   Shiva Sharma
* @CreatedDate      :   
* @Page             :   NewCasefromAccount.page
* @TestClass        :   NewCasefromAccountClassTest.cls
* -------------------------- @History ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
* Story Number       Modified By              Date                          Description
* CS21-1325         Vijay Kumar K R        Dec 19 2022    [FedRAMP] Disable case creation from Salesforce
* ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
global with sharing class NewCasefromAccountClass {

    private ApexPages.StandardController stdCtrl;
    private Case cs; // added for CS21-780 
    public Boolean isFedRAMPAcc {get;set;}
    public Boolean isFedRAMPCont {get;set;}
    public string recordId {get;set;}

    public NewCasefromAccountClass(ApexPages.StandardController std) {
        isFedRAMPAcc = false;
        isFedRAMPCont = false;
        stdCtrl = std;
        //added for CS21-780 - Veera 
        cs= new Case();
        cs = (Case) stdCtrl.getRecord();
        // 1325 changes 
        recordId = cs.Id;
        if(recordId == null){
            if(cs.ContactId != null){
                recordId = cs.ContactId;
            }else if(cs.AccountId != null){
                recordId = cs.AccountId;
            }
        }
        //End - CS21-780
    }
    
}