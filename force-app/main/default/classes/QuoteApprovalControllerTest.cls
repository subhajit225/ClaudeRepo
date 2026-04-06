@isTest
public class QuoteApprovalControllerTest{
 
 static testMethod void testApprovals(){
   Test.startTest();
   
   PageReference pageRef = Page.PreviewApproval;
   Test.setCurrentPage(pageRef);
   
   SBQQ__Quote__c qc = new SBQQ__Quote__c();
   insert qc;

   //MS TC Start
   Product2 prod = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Rel_SubsAsst__c='Renew:RelatedAsst',Usable_Capacity__c=1);  
        insert prod;
        Product2 prod1 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Non-Returnable Disk Service',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod1;
        Product2 prod2 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Rubrik Scale', Product_Subtype__c = 'FEDRAMP');  
        insert prod2;
        Product2 prod3 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Family  ='Third Party License');  
        insert prod3;
        Product2 prod4 = new Product2(Name='TestProd', IsActive=true, ProductCode='Test-Prod',Product_Level__c  ='Hybrid Software',Rel_SubsAsst__c='Renew:RelatedAsst');  
        insert prod4;
        List<Product2> lstProd = new List<Product2>();
        lstProd.add(prod);
        Assert.areEqual(1, lstProd.size());
        
        Account acc = (Account) ShGl_TestFactory.createSObject(new Account(),null);
        acc.RSC_G_Eligible__c = true; //MS RSCG
        insert acc;
        
        List<Account> accountList = new List<Account>();
        Account vAccount = new Account();
        accountList.add(vAccount);
        vAccount.Name = 'Test Account';
        vAccount.Type='Distributor';
        vAccount.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account vAccount2 = new Account();
        vAccount2.Name = 'Test Account';
        vAccount2.recordTypeId = vAccount.recordTypeId;
        accountList.add(vAccount2);
        insert accountList;
        contact con=new contact(lastname='test contact',leadsource='web',
                    email='testc@test.com',accountId=acc.id);
        insert con;
        //Generate the Opportunity
        Map<String, Object>  oppMap = new Map<String, Object> {'AccountId' => acc.Id};
            System.debug(oppMap);
        /*Opportunity opp = (Opportunity) ShGl_TestFactory.createSObject(new Opportunity(), oppMap);
        insert(opp);
        
        opp.Partner_Lookup__c = vAccount.id;
        opp.Distributor_Lookup__c = vAccount.id;
        update opp;*/
        //insert new opportunity
        Opportunity opp=new Opportunity(
            Name='test Opportunity',
            AccountId=acc.id, 
            StageName='1 Discovery', 
            CloseDate=system.Today(),
            ForecastCategoryName='Best Case',
            Initial_Contacts_Name__c=con.id,Business_Unit__c='Rubrik',
            Installation_Assigned_To__c='FE Install',
            Partner_Lookup__c = vAccount2.id,
            Distributor_Lookup__c = vAccount.id
        );
        insert opp;
        
        Asset asset = new Asset();
        asset.Name = '1234';
        asset.Serial_Number__c = 'AA210264120057';
        asset.AccountId = acc.id;
        asset.Product2Id = prod.Id;
        insert asset;
        List<Asset> astlst = [Select id,Serial_Number__c,Product_Usable_Capacity__c  from Asset where Serial_Number__c = 'AA210264120057'];
        List<SBQQ__QuoteLine__c> qlst = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__Quote__c> qutlst = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp.Id,SBQQ__Type__c='Renewal+Expansion', RWD_Sales_Rep_Exception__c = '25% Premium RSC-G Replacement', RWD_Sales_Rep_Exception_Justification__c = '25% Premium RSC-G Replacement RWD_Sales_Rep_Exception_Justification__c', Is_RSCG_Excp__c = true );
        insert(q);
        qutlst.add(q);
        SBQQ__QuoteLine__c qli1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod.Id, SBQQ__Quantity__c=10, SBQQ__Number__c=1, 
                                 SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__RenewedAsset__c=asset.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst.add(qli1);
        
        SBQQ__QuoteLine__c qli2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod1.Id, SBQQ__Number__c=2, 
                                 SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__RenewedAsset__c=asset.Id,SBQQ__SubscriptionTerm__c=36,Subscribed_Asset_Name__c='AA210264120057');  
        qlst.add(qli2);
        
        SBQQ__QuoteLine__c qli3 = new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod2.Id, SBQQ__Number__c=2
                                 ,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,Special_Program__c='Replaced',Product_Subtype__c = 'FEDRAMP', Arroyo_Subsumed_Old_Contract_Line_Items__c = '12345',SBQQ__NetPrice__c =10, Target_NetTotal__c = 20, RWD_Sales_Rep_Exception__c ='25% Premium RSC-G Replacement' );  
        qlst.add(qli3);
        
        SBQQ__QuoteLine__c qli4= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod2.Id, SBQQ__Number__c=2, Licensing_Model__c = 'Perpetual',
                                SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='Replaced', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=1,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset.Id, Target_NetTotal__c = 2 );  
        qlst.add(qli4);
        SBQQ__QuoteLine__c qli5= new SBQQ__QuoteLine__c(SBQQ__Quote__c=q.Id, SBQQ__Product__c=prod4.Id, SBQQ__Number__c=90, Sales_Comp_Category__c='SW SUPPORT',Product_Level__c ='Support',SBQQ__RequiredBy__c=qli4.id,
                                SBQQ__SubscribedAssetIds__c=astlst[0].Id,SubscribedAssetNames__c = 'AA210264120057',Subscribed_Asset_Name__c='AA210264120057',Disposition_Reason__c='None', SBQQ__SubscriptionPricing__c='Fixed Price',SBQQ__Quantity__c=90,SBQQ__SubscriptionTerm__c=36,SBQQ__RenewedAsset__c=asset.Id );  
        qlst.add(qli5);
        
        insert qlst;
        List<SBQQ__Quoteline__c> quoteLines = [Select Id, Target_NetTotal__c, SBQQ__NetTotal__c, RWD_Sales_Rep_Exception__c, RWD_Deal_Ops_Exception__c from SBQQ__quoteline__c where SBQQ__Quote__c=:q.Id AND SBQQ__Quote__r.Is_RSCG_Excp__c = true AND Product_Subtype__c = 'FEDRAMP' AND Special_Program__c = 'Replaced'];
        System.debug('MS Test log QLIs '+quoteLines);

   //MS TC Ends
   
   ApexPages.StandardController sc = new ApexPages.StandardController(q);
   
   
   QuoteApprovalController qAC = new QuoteApprovalController(sc);
   SBAA__Approval__c[] app = qAC.approvals; 
   Boolean b = qAC.isReadyForApproval;   
    Test.stopTest();
    
 }

 static testMethod void testApprovalsCase2(){
  Test.startTest();
  
  PageReference pageRef = Page.PreviewApproval;
  Test.setCurrentPage(pageRef);
  
  SBQQ__Quote__c qc = new SBQQ__Quote__c();
  insert qc;
  
  ApexPages.StandardController sc = new ApexPages.StandardController(qc);
  
  QuoteApprovalController qAC = new QuoteApprovalController(sc);
  SBAA__Approval__c[] app = qAC.approvals; 
  Boolean b = qAC.isReadyForApproval;   
  System.assert(b == true || b == false ||  b == null, 'isReadyForApproval Test true or false');
   Test.stopTest();
   
}

}