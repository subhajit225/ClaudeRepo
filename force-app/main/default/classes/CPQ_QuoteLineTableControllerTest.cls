/*
* Class Name :-
* Author :- Kush Dawar
* Created Date :- 2023-11-14
* Description : GLCR-81 :- Test Class for CPQ_QuoteLineTableController
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
* 
* 
// ********************Modification Log *****************************************************************************
*/
@isTest
public class CPQ_QuoteLineTableControllerTest {
    
    static final Id partnerRtId = Schema.SObjectType.Account
      .getRecordTypeInfosByName()
      .get('Partner/Distributor')
      .getRecordTypeId();

  static PricebookEntry getPbe(Id pbId, Id prodId, Decimal unitPrice) {
    return new PricebookEntry(
      Pricebook2Id = pbId,
      Product2Id = prodId,
      UnitPrice = unitPrice,
      IsActive = true
    );
  }
    
  static PricebookEntry getPbe(Id prodId, Decimal unitPrice) {
    return getPbe(Test.getStandardPricebookId(), prodId, unitPrice);
  }

  static Account getAccount(String name, String type, String rtId) {
    Account vAccount = new Account();
    vAccount.Name = name;
    vAccount.Type = type;
    vAccount.recordTypeId = rtId;

    return vAccount;
  }

  static Contact getContact(String name, String accId) {
    return new Contact(
      LastName = name,
      LeadSource = 'web',
      Email = 'testc@test.com',
      AccountId = accId
    );
  }

  static Product2 getProduct(String name, String code) {
    return new Product2(
      Name = name,
      ProductCode = code,
      isActive = true,
      CPQ_Uplift__c = '5'
    );
  }

  static Asset getAsset(String name, Id accountId, Id prodId) {
    return new Asset(
      Name = name,
      SerialNumber = name,
      Serial_Number__c = name,
      Product2ID = prodId,
      Accountid = accountId
    );
  }

  static Opportunity getOppty(String name, String accId, String partner, String disti) {
    Opportunity opp = new Opportunity();
    opp.Name = name;
    opp.AccountId = accId;
    opp.StageName = '1 Discovery';
    opp.CloseDate = System.today();
    opp.ForecastCategoryName = 'Best Case';
    opp.Business_Unit__c = 'Rubrik';
    opp.Installation_Assigned_To__c = 'FE Install';
    opp.Partner_Lookup__c = partner;
    opp.Distributor_Lookup__c = disti;

    return opp;
  }
    static testMethod void  testQuoteLineTable() {

    ShGl_TestFactoryHelper.insertTriggerControls();

    ShGl_DisableBusinessLogic__c cdf1 = new ShGl_DisableBusinessLogic__c(
      SetupOwnerId = userInfo.getUserId(),
      Disable_SBQQ_Quote_Triggers__c = true
    );
    insert cdf1;

    Product2 prod = getProduct('TestProd', 'TestProd');
    insert prod;

    Account acc = (Account) ShGl_TestFactory.createSObject(new Account(), null);
    insert acc;

    List<Account> accountList = new List<Account>();

    Account vAccount = getAccount('Test Account', 'Distributor', partnerRtId);
    accountList.add(vAccount);

    Account vAccount2 = getAccount('Test Account2', null, partnerRtId);
    accountList.add(vAccount2);

    insert accountList;

    Contact con = getContact('test con', acc.Id);
    insert con;

    //insert new opportunity
    Opportunity opp = getOppty('TestOpp', acc.Id, vAccount2.Id, vAccount.Id);
    insert opp;

    Asset asset = getAsset('123456', acc.Id, prod.Id);
    insert asset;

    SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id);

    insert q;
        Test.startTest();
        CPQ_QuoteLineTableController qliTableContInstance = new CPQ_QuoteLineTableController();
        qliTableContInstance.conQuoteID = q.ID;
        qliTableContInstance.conQuoteLineType = 'Renewal';
        qliTableContInstance.getQuoteLineDetails();
        qliTableContInstance.getQuoteLines();
        
        qliTableContInstance.conQuoteLineType = 'Amendment';
        qliTableContInstance.getQuoteLineDetails();
        qliTableContInstance.getQuoteLines();
        
        Test.stopTest(); 
                                
    }
    
    
    
}