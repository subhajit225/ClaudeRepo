public class ShGl_TestFactoryHelper {
    
    public static void insertTriggerControls () {
        insert new list<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=false),
                new TriggerControl__c(Name='User', DisableTrigger__c=false)
                };
                    }
    public static void WorkflowTriggerBypass () {
        
        
        List<WorkflowTriggerBypass__c> WTBPList =  new List<WorkflowTriggerBypass__c>(); 
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'CreateSDRLedMeetingTask',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'leadReassignOnBusinessUnitChange',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'salesOperationInvokePatchManager',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'salesOperationsAssignAccountSIC',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'salesOperationsSetEUResident',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'updateLastOwnershipUpdateDate',ByPassTrigger__c = false));
        WTBPList.add(new WorkflowTriggerBypass__c(name = 'updateOpportunitySource',ByPassTrigger__c = false));
       
        insert WTBPList;
    }
    
    public static void insertCustomSettings () {
        insertTriggerControls ();
        
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disFuncCS.Disable_Account_Old_Trigger__c = true;
        disFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        insert disFuncCS;
    }
    
    public static Partner_Page_Configuration__c createPartnerConfigRecord(integer recName){
        Partner_Page_Configuration__c pc = new Partner_Page_Configuration__c(
            Name = 'Partner Configuration '+recName,
            Navigate_Url__c = 'http://',
            Image_Type__c = 'Card',
            Image_Url__c = 'http://', 
            Image_Height__c = 100, 
            Active__c = true,
            Page_Name__c = 'home'
        );
        return pc;
    }
    public static Account createPortalAccount(String recName){
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
        
        Account AccRecord = new Account();
        AccRecord.Name = 'test '+recName;
        AccRecord.BillingStreet = 'street';
        AccRecord.BillingCity = 'city';
        AccRecord.BillingCountry = 'India';
        AccRecord.BillingPostalCode = '55555';
        AccRecord.RecordTypeId= devRecordTypeId;
        AccRecord.Type = 'Reseller';
        return AccRecord;
    }
    public static Contact createPortalContact(integer contactRec,Account AccRecord){
        Contact conObj = new Contact(LastName = 'lastname'+contactRec,
                                     FirstName = 'firstname',
                                     AccountId = AccRecord.Id,
                                     Email = 'a@a.com'+contactRec,Primary_Role__c='Admin');
        return conObj;
    }    
    public static User createPortalUser(integer userRec,Contact conObj){
        User newPortalUser = new User();
        newPortalUser.ProfileID = ID.valueOf(system.label.PartnerManagerSFDCProfileId);
        newPortalUser.EmailEncodingKey = 'ISO-8859-1';
        newPortalUser.LanguageLocaleKey = 'en_US';
        newPortalUser.TimeZoneSidKey = 'America/New_York';
        newPortalUser.LocaleSidKey = 'en_US';
        newPortalUser.Alias ='puser '+userRec;
        newPortalUser.FirstName = conObj.FirstName;
        newPortalUser.LastName = conObj.LastName;
        newPortalUser.Username = system.label.PortalUserNamePrefix+conObj.Email+userRec;   
        newPortalUser.CommunityNickname =String.ValueOf(Math.random());
        newPortalUser.Email = conObj.Email;
        newPortalUser.IsActive = true;
        newPortalUser.ContactId = conObj.Id;
        newPortalUser.Phone = conObj.Phone;
        newPortalUser.Street= conObj.MailingStreet;
        newPortalUser.City = conObj.MailingCity;
        newPortalUser.State = conObj.MailingState;
        newPortalUser.Country = conObj.MailingCountry;
        newPortalUser.PostalCode = conObj.MailingPostalCode;
        newPortalUser.UserPermissionsSFContentUser= true;
        newPortalUser.CompanyName = conObj.Account.Name;
        return newPortalUser;  
    }
    public static ContentVersion createContent(integer contentRec){
        ContentVersion cv=new Contentversion();
        cv.title='ABC'+contentRec;
        cv.PathOnClient ='test';
        Blob b=Blob.valueOf('Unit Test Attachment Body');
        cv.versiondata=EncodingUtil.base64Decode('Unit Test Attachment Body');
        cv.IsMajorVersion = true;
        return cv;
    }    
    public static Partner_Onboarding_Request__c createPartnerOnBoarding(integer onBoardRecord){
        Partner_Onboarding_Request__c pc=new Partner_Onboarding_Request__c();
        pc.Company_Name__c='PARTNER_MSP';
        pc.Address_1__c='test address'+onBoardRecord;
        pc.Address_2__c='test address2'+onBoardRecord;
        pc.Partner_Onboarding_Status__c='Unassigned';
        pc.PartnerType__c = 'Reseller';
        PC.Email__c=onBoardRecord+'test@gmail.com';
        return PC;
    }
    public static Incentives__c createIncentive(integer incentiveRecord,String ccrType){
        Incentives__c incent=new Incentives__c();
        incent.Name = 'Test '+incentiveRecord;
        incent.CCR_Type__c=ccrType;
        return incent;
    }
    public static Attachment createAttachment(integer attRec,Id parentId){
        Attachment attach = new Attachment();
        attach.Name='Unit Test Attachment '+attRec;
        Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
        attach.body=bodyBlob;
        attach.parentId=parentId;
        return attach;
    }
    public static Deal_Registration__c createDealRegistration(integer attRec){
        Deal_Registration__c dc=new Deal_Registration__c();
        dc.FirstName__c='fn'+attRec;
        dc.LastName__c='ln1';
        dc.Deal_Registration_Status__c='Submitted';
        dc.Deal_Reg_Submitted_Date__c=system.today();
        dc.Deal_Registration_Type__c='Partner Initiated Deal';
        return dc;
    }
    public static User createUser(integer userName){
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt'+userName, Email=userName+'testuserdetails@testorg.com', 
                          EmailEncodingKey='UTF-8', LastName='Testing'+userName, LanguageLocaleKey='en_US', 
                          LocaleSidKey='en_US', ProfileId = p.Id, 
                          TimeZoneSidKey='America/Los_Angeles', UserName='testuserdetail@gmail.com'+userName);
        return u;
    }
    public static CCR__c createCCR(String emailID){
        CCR__c  ccr=new CCR__c();
        ccr.Partner_Rep_Email__c=emailID;
        ccr.Partner_REP_Amount__c=100;
        return ccr;
    }
    public static Partner_Registration_Request__c createPRR(){
        Partner_Registration_Request__c pr=new Partner_Registration_Request__c();
        pr.Address__c='test address';
        pr.State__c='testState';
        pr.Country__c='United State';
        pr.Company_Name__c='TestCompany';
        pr.Email__c='abc@gmail.com';
        pr.State_Picklist__c='AZ';
        pr.Country_Picklist__c='United State';
        return pr;
    }
    /* Commenting as part PRIT25-262

    public static Partner_Event__c createPartnerEvent(Integer nameEvent){
        Partner_Event__c eve = new Partner_Event__c(Name='name'+nameEvent,End_date__c=system.today()+5);
        return eve; 
    } */
    
    public static Product2 createProduct(Integer productNumber)
    {
        Product2 prod = new Product2();
        prod.name = 'Test_'+productNumber;
        return prod;
    }
    public static Pricebook2 createPricebook(Integer priceBookNumber) 
    {                
        Pricebook2 customPB = new Pricebook2();
        customPB.Name='Test Pricebook '+priceBookNumber;
        customPB.isActive=true;
        return customPB;                
    }
    public static List<PricebookEntry> createPriceBookEntries(List<Product2> lstProducts,Id priceBookId)
    {
        list<PricebookEntry> lstPriceBookEntries = new list<PricebookEntry>();
        for(Product2 prod:lstProducts)
        {            
            PricebookEntry pbCustomPBEntry = new PricebookEntry(
                Pricebook2Id = priceBookId,
                Product2Id = prod.Id,
                UnitPrice = 100.00,
                IsActive = true);
            lstPriceBookEntries.add(pbCustomPBEntry);
        }
        return lstPriceBookEntries;
    }
    
    public static Order createOrder(Integer orderNumber,Account accRec,Pricebook2 pbID)
    {
        Order o = new Order();
        o.Name = 'Test Order '+orderNumber;
        o.Status = 'Draft';
        o.EffectiveDate = system.today();
        o.EndDate = system.today() + 4;
        o.AccountId = accRec.id;
        o.Pricebook2Id =  pbID.Id ;
        return o;   
    }
    public static PatchManager__c createPatchManager()
    {
        PatchManager__c pm = new PatchManager__c();
        pm.Object_Type__c = 'All';
        pm.CountryGlobal__c = 'United States';
        pm.County__c='United States';
        pm.StateGlobal__c = 'FL';
        return pm;
    }
    public static Lead createLead(integer leadNumber)
    {
        Lead lead=new Lead(Company='Test',LeadSource='Email',Lastname='Test'+leadNumber,
                           Lead_Source_Details__c='Test',Country='United States',City='California');
        return lead;
    }    
    public static DOCEBO1_CO__c createTraining(String dName)
    {
        DOCEBO1_CO__c doRecord=new DOCEBO1_CO__c(Name = dName,
                                                 C_DC_COURSE_NAME__c = dName, 
                                                 D_UPDATE__c = system.now(), 
                                                 C_DC_COURSE_LANG__c = 'test', 
                                                 D_CREATE__c = system.now(), 
                                                 C_DC_COURSE_TYPE__c = 'test', 
                                                 N_REVISION__c =1,
                                                C_DC_COURSE_CODE__c = dName);
        return doRecord;
    }    
    public static DOCEBO2_CO__c createDecebo(integer dNumber,String courseId,String contactId)
    {
        DOCEBO2_CO__c doRecord = new DOCEBO2_CO__c(Name='E'+dNumber,
                                                   C_SF_USER_TYPE__c='UT'+dNumber,
                                                   C_DC_TIMEZONESID__c='EST',
                                                   D_DC_ENROLL__c=system.today(),
                                                   C_DC_COURSE_STATUS__c='COMPLETED',
                                                   D_DC_COURSE_COMP__c = system.today()+2,
                                                   C_DC_COURSE_ID__c = courseId, 
                                                   C_SF_USER_ID__c = 'uid',
                                                   Contact__c = contactId);
        return doRecord;
    }
    
    public static void insertCustomSettings_2 () {
        insertTriggerControls ();
        
        ShGl_DisableBusinessLogic__c disBusinessLogicCS = ShGl_DisableBusinessLogic__c.getInstance(); 
        disBusinessLogicCS.Disable_Opportunity_Validation_Rules__c = true;
        insert disBusinessLogicCS;
        
    }
    
    public static PO_Stage__c createPOStage(String accountName,string enduserPO,date estShipDate,decimal posExpected, string partnerEmail,string partnerName,date poDate,decimal poIndex,string poNumber,string quoteNum,decimal POAmount){

    PO_Stage__c poStage = new PO_Stage__c();
    poStage.Account_name__c = accountName;
    poStage.End_User_PO__c = enduserPO;
    poStage.Est_Ship_Date__c = estShipDate;
    poStage.Expected_number_of_POs__c = posExpected;
    poStage.Partner_Email__c= partnerEmail;
    poStage.Partner_Name__c =partnerName;
    poStage.Payment_Terms__c = 'Net 45';
    poStage.PoDate__c = poDate;
    poStage.PO_Index__c = poIndex;
    poStage.PoNumber__c = poNumber;
    poStage.PO_Validation_Status__c ='Pending';
    poStage.Quote_number__c = quoteNum;
    poStage.Shipment_Method_of_Payment__c='PP';
    poStage.TotalAmount__c = poAmount;
    //poStage.Bill_To_Name_Str__c = 'Promark Technology, Inc.';
    poStage.Shipping_Account_Number__c ='1234';
    poStage.Shipping_Carrier__c ='MainFreight';
    poStage.Service_Level__c = 'Economy';

    return poStage;



    }
    
    
    public static PO_Item_Stage__c  createPOItem(String buyerPartnum,string ediLinenum,string prodCode,decimal quant,id stagePO,decimal subterm, decimal unitnetprice){
    
            PO_Item_Stage__c item = new PO_Item_Stage__c();
            item.Buyer_Part_Number__c=buyerPartnum;
            item.EDI_Line_Number__c =ediLinenum;
            item.ProductCode__c =prodCode;
            item.Quantity__c = quant;
            item.Stage_PO__c= stagePO;
            item.SubscriptionTerm__c =subterm;
            item.UnitPrice__c=unitnetprice;
    
            return item;
    
    }
    
    
    public static PO_Stage_Address__c createPOStageAddress(string atype,string city,string cname,string cphone,string countrycode,string stateCode,string email,id stagePO,string postcode,string street1,string street2){
        PO_Stage_Address__c sa = new PO_Stage_Address__c();
        sa.Address_Type__c = atype;
        sa.City__c = city;
        sa.Contact_Name__c = cname;
        sa.Contact_Number__c = cphone;
        sa.CountryCode__c = countrycode;
        sa.Email__c = email;
        sa.PO_Stage__c =stagePO;
        sa.PostalCode__c = postcode;
        sa.StateCode__c =stateCode;
        sa.Street1__c = street1;
        sa.Street2__c = street2;
        return sa;
    
    }
}