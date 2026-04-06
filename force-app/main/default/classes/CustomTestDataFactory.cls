@isTest
public class CustomTestDataFactory{
    
    public static List<TriggerControl__c> TriggerControlSetting(boolean b) {
        List<TriggerControl__c> TriggerControlSettinglst = new List<TriggerControl__c>();
        TriggerControl__c tc = new TriggerControl__c();
        insert new TriggerControl__c(Name = 'Opportunity', Disable_Trigger__c = false, DisableTrigger__c=false, Last_Batch_Run_Date__c =system.now(),SendEmail__c=false );
        return TriggerControlSettinglst;
    } 
    
    public static void insertTriggerControls () {
        insert new list<TriggerControl__c> {
            new TriggerControl__c(Name='Contact', DisableTrigger__c=false),
                new TriggerControl__c(Name='Opportunity', DisableTrigger__c=false),
                new TriggerControl__c(Name='Entitlement', DisableTrigger__c=false),
                new TriggerControl__c(Name='Asset', DisableTrigger__c=false),
                new TriggerControl__c(Name='User', DisableTrigger__c=false)
                };
                    }
    public static void insertCustomSettings () {
        insertTriggerControls ();
        ShGl_DisableFunctionalityLogic__c disFuncCS = ShGl_DisableFunctionalityLogic__c.getInstance(); 
        disFuncCS.Disable_Account_Old_Trigger__c = true;
        disFuncCS.Disable_Opportunity_Old_Trigger__c = true;
        insert disFuncCS;
    }
    
    public static List<Account> testAccounts(Integer numAccts) {
        List<Account> actlst = new List<Account>();
        for(Integer i=0;i<numAccts;i++) {
            Account acc = new Account();
            acc.Name = 'Test Account'+i;
            acc.BillingCountry = 'United States';
            acc.BillingState ='United States Minor Outlying Islands';
            actlst.add(acc);
        }
        insert actlst;
        return actlst;
    }
    
    public static List<Opportunity> TESTOpp(List<Account> actlst){
        List<Opportunity> opplst = new List<Opportunity>();
        for (Integer j=0;j<actlst.size();j++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'testopp';
            opp.StageName = '1 Discovery';
            opp.AccountId = actlst[0].id;
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.CloseDate = system.today();
            opp.Business_Unit__c = 'Mosaic';
            opp.Deal_Registration_Type__c = 'Rubrik Sourced';
            opplst.add(opp);
        }
        insert opplst; 
        return opplst;
    }
    
    public static List<Order> testorders (List<Account> actlst ,List<Opportunity> opplst){
        List<order> ordlst = new List<order>();
        for(Integer i=0; i< 5; i++){
            Order od2 = new Order();
            od2.AccountId = actlst[0].Id;
            od2.OpportunityId =opplst[0].Id;
            od2.EffectiveDate = Date.Today();
            //od2.Status = 'PO Received';
            od2.Order_Status__c = 'PO Received';
            od2.ShippingStreet ='Test Street';
            od2.ShippingCity ='Test City';
            od2.ShippingState ='California';
            od2.ShippingCountry ='United States';
            od2.ShippingPostalcode ='94820';
            //od2.ship_To_Name__c=acc.id;
            od2.Shipping_Address_Label__c = null;
            ordlst.add(od2);
        }
        insert ordlst;   
        return ordlst;          
    }
    
    public static List<PS_Project__c> testPSProject_c(List<Account> actlst){
        List<PS_Project__c> projlst =  new List<PS_Project__c>();
        for(Integer i=0; i<= actlst.size(); i++){
            PS_Project__c proj = new PS_Project__c(Account__c=actlst[0].Id,Project_Status__c='Open');
            projlst.add(proj);
        }
        insert projlst;   
        return projlst;
    }
    
    public static List<PS_Task__c> createPstaskInstall(List<PS_Project__c> projlst, boolean dml){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_Task__c task1 = new PS_Task__c(Project__c=projlst[0].Id,Task_Type__c='Install',Task_Status__c='Open');
            tasklst.add(task1);
        }
        if(dml) insert tasklst;
        return tasklst;
    }
    
    public static List<PS_Task__c> createPstaskConsult(List<PS_Project__c> projlst , boolean dml){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_Task__c task1 = new PS_Task__c(Project__c=projlst[0].Id,Task_Type__c='Consult',Task_Status__c='Open');
            tasklst.add(task1);
        }
        if(dml) insert tasklst;
        return tasklst;
    }
    
    public static List<PS_SubTask__c> createPSSubtaskInstall(List<PS_Task__c> createPstaskInstall, boolean dml){
        List<PS_SubTask__c> SUBtaskInsert =  new List<PS_SubTask__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_SubTask__c subtask11 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=createPstaskInstall[0].Id,Task_Type__c='Install');
            SUBtaskInsert.add(subtask11); 
        }
        if(dml) insert SUBtaskInsert;
        return SUBtaskInsert;
    }
    
    public static List<PS_SubTask__c> createPSSubtaskConsult(List<PS_Task__c> createPstaskConsult,  boolean dml){
        List<PS_SubTask__c> SUBtaskInsert =  new List<PS_SubTask__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_SubTask__c subtask11 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=createPstaskConsult[0].Id,Task_Type__c='Install');
            SUBtaskInsert.add(subtask11); 
        }
        if(dml) insert SUBtaskInsert;
        return SUBtaskInsert;
    }
    
    public static List<PS_Time_Entry__c> createPSTimeEntryInstall(List<PS_Task__c> createPstaskInstall,List<PS_SubTask__c> createPSSubtaskInstall){
        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=5,PS_SubTask__c=createPSSubtaskInstall[0].Id,Time_Entry_Date__c=system.today().addDays(-2),PS_Task__c=createPstaskInstall[0].id,comments__c='test',Status__c='Submitted');
        psoList.add(psot1);
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=1,PS_SubTask__c=createPSSubtaskInstall[0].Id,Time_Entry_Date__c=system.today(),PS_Task__c=createPstaskInstall[0].id);
        psoList.add(psot2);
        PS_Time_Entry__c psot3 = new PS_Time_Entry__c(Hours_Spent__c=2,PS_SubTask__c=createPSSubtaskInstall[0].Id,Time_Entry_Date__c=system.today().addDays(1),PS_Task__c=createPstaskInstall[0].id);
        psoList.add(psot3);
        insert psoList;
        return psoList;
    }
    
    public static List<PS_Time_Entry__c> createPSTimeEntryConsult(List<PS_Task__c> createPstaskConsult,List<PS_SubTask__c> createPSSubtaskConsult){
        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=1,PS_SubTask__c=createPSSubtaskConsult[0].Id,Time_Entry_Date__c=system.today().addDays(-2),PS_Task__c=createPstaskConsult[0].id);
        psoList.add(psot1);
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=2,PS_SubTask__c=createPSSubtaskConsult[0].Id,Time_Entry_Date__c=system.today(),PS_Task__c=createPstaskConsult[0].id);
        psoList.add(psot2);
        PS_Time_Entry__c psot3 = new PS_Time_Entry__c(Hours_Spent__c=3,PS_SubTask__c=createPSSubtaskConsult[0].Id,Time_Entry_Date__c=system.today().addDays(1),PS_Task__c=createPstaskConsult[0].id);
        psoList.add(psot3);
        insert psoList;
        return psoList;
    }
    
    public static List<PS_Time_Card__c> CreatTimecard(List<PS_Project__c> testPSProject_c){
        List<PS_Time_Card__c> PsTimeInsert = new List<PS_Time_Card__c>();
        for(Integer i=0; i <=testPSProject_c.size();  i++){
            PS_Time_Card__c PST = new PS_Time_Card__c();
            PST.Name = 'TEST';
            PST.Approver__c = userinfo.getuserid();
            PST.PS_Project__c = testPSProject_c[0].id;
            PST.Time_Card_Start_Date__c = system.today();
            PST.Time_Card_End_Date__c   = system.today();
            PST.Status__c ='Draft';
            PST.Assignee__c = userinfo.getuserid();
            //  PST.Total_Billable_Hours__c = 5;
            PsTimeInsert.add(PST);
        }
        insert PsTimeInsert;
        return PsTimeInsert;
    }
    
    public static List<Account> createAccounts(Integer numAccts) {
        List<Account> actlst = new List<Account>();
        for(Integer i=0;i<numAccts;i++) {
            Account acc = new Account();
            acc.Name = 'Test Account'+i;
            acc.BillingCountry = 'United States';
            acc.BillingState ='United States Minor Outlying Islands';
            actlst.add(acc);
        }
        insert actlst;
        return actlst;
    } 
    
    public static list<Contact> createcont (List<Account> actlst){
        List<Contact> conlst = new List<Contact>();
        for(Integer i=0; i<actlst.size();i++){
            contact c =(new contact(LastName = 'testcon'+i, AccountId = actlst[0].id,email = 'sfdctesting7@gmail.com'));
            conlst.add(c);    
        }
        insert conlst;
        return conlst;
    }
    
    public static list<Contact> createContacts(List<Account> actlst){
        List<Contact> conlst = new List<Contact>();
        for(Integer i=0; i<actlst.size();i++){
            contact c =(new contact(LastName = 'testContact'+i, AccountId = actlst[0].id));
            conlst.add(c);    
        }
        insert conlst;
        return conlst;
    }
    
    public static list<Contact> createContactsNQ(List<Account> actlst){
        List<Contact> conlst = new List<Contact>();
        for(Integer i=0; i<actlst.size();i++){
            contact c =(new contact(LastName = 'testContact'+i, AccountId = actlst[0].id, Contact_Status__c = 'Meeting Set'));
            conlst.add(c);    
        }
        insert conlst;
        return conlst;
    }
    
    
    public static List<Opportunity> createOpp(List<Account> actlst, List<Contact> conlst){
        List<Opportunity> opplst = new List<Opportunity>();
        for (Integer j=0;j<actlst.size();j++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'testopp';
            opp.StageName = '1 Discovery';
            opp.AccountId = actlst[0].id;
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.CloseDate = system.today();
            opp.Business_Unit__c = 'Mosaic';
            //opp.ForecastCategory = 'Upside';
            opp.ContactId = conlst[0].id;
            opp.Deal_Registration_Type__c = 'Rubrik Sourced';
            opplst.add(opp);
        }
        insert opplst; 
        return opplst;
    }
    
    public static List<Order> createOrder (List<Account> actlst ,List<Opportunity> opplst){
        List<order> ordlst = new List<order>();
        for(Integer i=0; i< 5; i++){
            Order od2 = new Order();
            od2.AccountId = actlst[0].id;
            od2.OpportunityId =opplst[0].Id;
            od2.EffectiveDate = Date.Today();
            //od2.Status = 'PO Received';
            od2.Order_Status__c = 'Shipped';
            od2.ShippingStreet ='Test Street';
            od2.ShippingCity ='Test City';
            od2.ShippingState ='California';
            od2.ShippingCountry ='United States';
            od2.ShippingPostalcode ='94820';
            // od2.PS_Project__c = projlst[i].id;
            od2.Status = 'Draft';
            od2.Order_Number__c = '12979';
            od2.ship_To_Name__c=  '24/6'+i;
            od2.Shipping_Address_Label__c = null;
            ordlst.add(od2);
        }
        insert ordlst;   
        return ordlst;          
    }
    
    public static List<OrderItem> createordItem (List<Order> ordlst, list<Product2> prodlst, List<PricebookEntry> prcbklst){
        List<OrderItem> ordItemlst = new List<OrderItem>();
        for(Integer i =0; i< ordlst.size(); i++){
            OrderItem orditm = new OrderItem();
            orditm.OrderId= ordlst[0].id;
            orditm.Quantity = 3;
            orditm.UnitPrice = 100;
            orditm.PricebookEntryId = prcbklst[0].id;
            orditm.Product2Id = prodlst[0].id;
            ordItemlst.add(orditm);
        }
        insert ordItemlst;
        return ordItemlst;
    }
    
    public static List<PricebookEntry> CreatPriceBookEntry(List<Product2> prodlst){
        Id pricebookId =  Test.getStandardPricebookId();
        //List<Pricebook2> prc2lst  = [SELECT id, Name, Description FROM Pricebook2 WHERE Name='CPQ PriceBook'];
        List<PricebookEntry> prcbklst =  new List<PricebookEntry>();
        PricebookEntry prcbk =  new PricebookEntry();
        prcbk.Product2Id = prodlst[0].id;
        prcbk.UnitPrice = 100;
        prcbk.Pricebook2Id = pricebookId;
        prcbklst.add(prcbk);
        insert prcbklst;
        return prcbklst;       
    }  
    
    public static List<Product2> CreatProductINSTALL(List<order> ordlst){
        List<Product2> prod2lst =  new List<Product2>();
        for(Integer i=0; i<= 1; i++){
            Product2 prod =  new Product2();
            prod.Name='RBK-PS-INST';
            prod.ProductCode='RBK-PS-INST';
            prod.isActive=true;
            prod.Allow_PSO_Task_Creation__c = true;
            prod2lst.add(prod);
        }
        insert prod2lst;
        return prod2lst;       
    }
    
    public static List<Product2> ALLPRODUCT(List<order> ordlst){
        List<Product2> prod2lst =  new List<Product2>();
        Product2 prod =  new Product2();
        prod.Name='RBK-PS-INST';
        prod.ProductCode='RBK-PS-INST';
        prod.isActive=true;
        prod.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod);
        
        Product2 prod1 =  new Product2();
        prod1.Name='RBK-CONSULT';
        prod1.ProductCode='RBK-CONSULT';
        prod1.isActive=true;
        prod1.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod1);
        
        Product2 prod2 =  new Product2();
        prod2.Name='RBK-INSTALL';
        prod2.ProductCode='RBK-INSTALL';
        prod2.isActive=true;
        prod2.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod2);
        
        Product2 prod3 =  new Product2();
        prod3.Name='RBK-DATA-MIGRATION';
        prod3.ProductCode='RBK-DATA-MIGRATION';
        prod3.isActive=true;
        prod3.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod3);
        
        Product2 prod4 =  new Product2();
        prod4.Name='RBK-PS-CNSLT-ONST';
        prod4.ProductCode='RBK-PS-CNSLT-ONST';
        prod4.isActive=true;
        prod4.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod4);
        
        Product2 prod5 =  new Product2();
        prod5.Name='RBK-PS-CNSLT-RMOT';
        prod5.ProductCode='RBK-PS-CNSLT-RMOT';
        prod5.isActive=true;
        prod5.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod5);
        
        Product2 prod6 =  new Product2();
        prod6.Name='RBK-PS-TE';
        prod6.ProductCode='RBK-PS-TE';
        prod6.isActive=true;
        prod6.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod6);
        
        Product2 prod7 =  new Product2();
        prod7.Name='RBK-INSTALL-RE';
        prod7.ProductCode='RBK-INSTALL-RE';
        prod7.isActive=true;
        prod7.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod7);
        
        Product2 prod8 =  new Product2();
        prod8.Name='RBK-PS-RES';
        prod8.ProductCode='RBK-PS-RES';
        prod8.isActive=true;
        prod8.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod8);
        
        Product2 prod9 =  new Product2();
        prod9.Name='RBK-PS-CONSULT';
        prod9.ProductCode='RBK-PS-CONSULT';
        prod9.isActive=true;
        prod9.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod9);
        
        insert prod2lst;
        return prod2lst;       
    }
    public static List<Product2> RBKINSTALL(List<order> ordlst){
        List<Product2> prod2lst =  new List<Product2>();
        Product2 prod1 =  new Product2();
        prod1.Name='RBK-INSTALL';
        prod1.ProductCode='RBK-PS-INST';
        prod1.isActive=true;
        prod1.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod1);
        insert prod2lst;
        return prod2lst;       
    }
    public static List<Product2> RBKDATAMIGRATION(List<order> ordlst){
        List<Product2> prod2lst =  new List<Product2>();
        Product2 prod1 =  new Product2();
        prod1.Name='RBK-PS-INST';
        prod1.ProductCode='RBK-PS-INST';
        prod1.isActive=true;
        prod1.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod1);
        insert prod2lst;
        return prod2lst;       
    }
    public static List<Product2> RBKCONSULTRE(List<order> ordlst){
        List<Product2> prod2lst =  new List<Product2>();
        Product2 prod1 =  new Product2();
        prod1.Name='RBK-CONSULT-RE';
        prod1.ProductCode='RBK-PS-INST';
        prod1.isActive=true;
        prod1.Allow_PSO_Task_Creation__c = true;
        prod2lst.add(prod1);
        insert prod2lst;
        return prod2lst;       
    }
    
    public static List<PS_Project__c> createPS_Project(List<Contact> conlst, List<Account> actlst){
        List<PS_Project__c> projlst =  new List<PS_Project__c>();
        for(Integer i=0; i<= conlst.size(); i++){
            PS_Project__c pro = new PS_Project__c();
            pro.Account__c = actlst[0].id;
            pro.Name = 'Test Project';
            pro.Welcome_Letter_Contact__c = conlst[0].Id;
            pro.Customer_Project_Contact__c = conlst[0].id;
            projlst.add(pro);
        }
        insert projlst;
        return projlst;
    }
    
    public static List<PS_Project__c> createPS_Projectwithopp(List<Opportunity> opplst, List<Contact> conlst, List<Account> actlst){
        List<PS_Project__c> projlst =  new List<PS_Project__c>();
        for(Integer i=0; i<= conlst.size(); i++){
            PS_Project__c pro = new PS_Project__c();
            pro.Account__c = actlst[0].id;
            pro.Project_Manager__c =userinfo.getuserid();
            pro.Project_Status__c = 'Open';
            pro.Name = 'Test Project';
            pro.Welcome_Letter_Contact__c = conlst[0].Id;
            pro.Customer_Project_Contact__c = conlst[0].id;
            pro.Opportunity__c = opplst[0].id; 
            projlst.add(pro);
        }
        insert projlst;
        return projlst;
    }
    
    public static List<PS_Task__c> createPS_Task(List<PS_Project__c> projlst, list<Account> actlst, integer count){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=115; i<= count+115; i++){
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today().AddDays(-i);
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'Consult';
            pt.Consult_Quantity__c = 1;
            pt.Project__c = projlst[0].Id;
            pt.Task_End_date__c = system.today();
            pt.Account__c = actlst[0].id;
            pt.Billable_Hours_Expected__c = 40;
            tasklst.add(pt);
        }
        insert tasklst;
        return tasklst;
    }
    
    public static List<PS_Task__c> createPS_TaskwithOrd (List<PS_Project__c> projlst, list<Account> actlst, list<order> ordlst){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i<= projlst.size(); i++){
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today();
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'Install';
            pt.Project__c = projlst[0].Id;
            pt.Task_End_date__c = system.today()+14;
            pt.Account__c = actlst[0].id;
            tasklst.add(pt);
        }
        insert tasklst;
        return tasklst;
    }
    
    public static List<Product2> CreatProduct(){
        List<Product2> ProductListUpdated =  new List<Product2>();
        for(Integer i=0; i<= 1; i++){
            Product2 pro =  new Product2();
            pro.Name='Pord B';
            pro.ProductCode='Product123XYZ';
            pro.isActive=true;
            ProductListUpdated.add(pro);
        }
        insert ProductListUpdated;
        return ProductListUpdated;       
    } 
    
    public static List<Case> CreatCase(list<Account> actlst,list<Contact> createcont,List<PS_Task__c> tasklst){
        List<Case> CaseListUpdated = new List<Case>();
        Case cse = new Case(AccountId = actlst[0].id,ContactId = createcont[0].id,PS_Task__c = tasklst[0].Id,Description = System.label.Go_Refresh_Description,
                            Resolution__c = 'Operational Assistance',Sub_Component__c = 'Decommission',Problem_Type__c = 'Rubrik CDM Appliance - Cluster',
                            Product_Area__c = 'Cluster Management',Platform__c = 'CDM',Next_Step__c = System.label.Go_Refresh_Next_Steps,
                            Current_Status__c = System.label.Go_Refresh_Current_Steps,Subject = 'Go Refresh data migration request from r300 to r6000 (RBK-DATA-MIGRATION)',
                            Origin = 'PS Project',Priority = 'P4');
        CaseListUpdated.add(cse); 
        insert CaseListUpdated;
        return CaseListUpdated;
    }
    
    /*public static List<Case> create_Case(list<Account> actlst,list<Contact> createcont,List<PS_Task__c> tasklst){
List<Case> caseList = new List<Case>();
for(integer j=0 ; j<=1 ;j++){
caseList.add(new Case(Status = 'New',
Priority='P3',
Subject='sasadf',
AccountId = actlst[0].id,
PS_Task__c = tasklst[0].Id,
ContactId = createcont[0].id,
Description = System.label.Go_Refresh_Description
));
}
insert caseList;
return caseList;
} */
    
    public static List<Order> createOrderWithOutPricebook (List<Account> actlst ,List<Opportunity> opplst){
        List<order> ordlst = new List<order>();
        for(Integer i=0; i< 5; i++){
            Order od2 = new Order();
            od2.AccountId = actlst[0].id;
            od2.OpportunityId =opplst[0].Id;
            od2.EffectiveDate = Date.Today();
            //od2.Status = 'PO Received';
            od2.Order_Status__c = 'Shipped';
            od2.ShippingStreet ='Test Street';
            od2.ShippingCity ='Test City';
            od2.ShippingState ='California';
            od2.ShippingCountry ='United States';
            od2.ShippingPostalcode ='94820';
            // od2.PS_Project__c = projlst[i].id;
            od2.Status = 'Draft';
            od2.Order_Number__c = '12979';
            od2.ship_To_Name__c=  '24/6'+i;
            od2.Shipping_Address_Label__c = null;
            ordlst.add(od2);
        }
        insert ordlst;   
        return ordlst;          
    }
    
    public static List<PS_Task__c> createPS_Task1(List<PS_Project__c> projlst, list<Account> actlst){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <= projlst.size() ; i++){
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today().AddDays(-i);
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'Consult';
            pt.Consult_Quantity__c = 1;
            pt.Project__c = projlst[0].Id;
            pt.Task_End_date__c = system.today();
            pt.Account__c = actlst[0].id;
            pt.Billable_Hours_Expected__c = 40;
            tasklst.add(pt);
        }
        insert tasklst;
        return tasklst;
    }
    
    public static List<PS_SubTask__c> createPSSubtaskAdmin(List<PS_Task__c> createPstaskInstall, boolean dml){
        List<PS_SubTask__c> SUBtaskInsert =  new List<PS_SubTask__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_SubTask__c subtask11 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=createPstaskInstall[0].Id,Task_Type__c='Admin');
            SUBtaskInsert.add(subtask11); 
        }
        if(dml) insert SUBtaskInsert;
        return SUBtaskInsert;
    }
    
    public static List<PS_Time_Entry__c> createPSTimeEntryAdmin(List<PS_Task__c> createPstaskInstall,List<PS_SubTask__c> createPSSubtaskAdmin){
        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        for(integer i = 0; i<createPSSubtaskAdmin.size(); i++) {
            PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=0,PS_SubTask__c=createPSSubtaskAdmin[i].Id,Time_Entry_Date__c=system.today().addDays(-2),PS_Task__c=createPstaskInstall[0].id);
            psoList.add(psot1);
        }
        insert psoList;
        return psoList;
    }
    
    public static List<PS_Time_Entry__c> createPSTimeEntryConsult1(List<PS_Task__c> createPstaskConsult,List<PS_Time_Card__c> CreatTimecard){
        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=1,Time_Entry_Date__c=system.today().addDays(-2),PS_Task__c=createPstaskConsult[0].id,PS_Time_Card__c =CreatTimecard[0].id);
        psoList.add(psot1);
        PS_Time_Entry__c psot2 = new PS_Time_Entry__c(Hours_Spent__c=2,Time_Entry_Date__c=system.today(),PS_Task__c=createPstaskConsult[0].id,PS_Time_Card__c =CreatTimecard[0].id);
        psoList.add(psot2);
        PS_Time_Entry__c psot3 = new PS_Time_Entry__c(Hours_Spent__c=3,Time_Entry_Date__c=system.today().addDays(1),PS_Task__c=createPstaskConsult[0].id,PS_Time_Card__c =CreatTimecard[0].id);
        psoList.add(psot3);
        insert psoList;
        return psoList;
    }
    
    public static List<PS_Task__c> createPS_Task_RE(List<PS_Project__c> projlst, list<Account> actlst){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <= projlst.size() ; i++){
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today().AddDays(-i);
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'Resident Engineer';
            pt.Consult_Quantity__c = 1;
            pt.Project__c = projlst[0].Id;
            pt.Account__c = actlst[0].id;
            pt.Billable_Hours_Expected__c = 40;
            tasklst.add(pt);
        }
        insert tasklst;
        return tasklst;
    }
    
    public static List<PS_Task__c> createPS_Task_TE (List<PS_Project__c> projlst, list<Account> actlst){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <= projlst.size() ; i++){
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today().AddDays(-i);
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'T&E';
            pt.Consult_Quantity__c = 1;
            pt.Project__c = projlst[0].Id;
            pt.Account__c = actlst[0].id;
            pt.Billable_Hours_Expected__c = 40;
            tasklst.add(pt);
        }
        insert tasklst;
        return tasklst;
    }
    
    public static List<PS_Time_Entry__c> createPSTime(List<PS_Task__c> createPstaskInstall){
        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=5,Time_Entry_Date__c=system.today().addDays(-2),PS_Task__c=createPstaskInstall[0].id,comments__c='test',Status__c='Submitted');
        psoList.add(psot1);
        insert psoList;
        return psoList;
    }
    
    public static List<PS_Project_Team_Member__c> createTeamMem(list<PS_Project__c> projlst){
        List<PS_Project_Team_Member__c> PsTeam =  new List<PS_Project_Team_Member__c>(); 
        PS_Project_Team_Member__c Pt = new PS_Project_Team_Member__c();
        Pt.PS_Project__c = projlst[0].id;
        pt.Team_Member__c = userinfo.getuserid();
        PsTeam.add(Pt); 
        Insert PsTeam;
        return PsTeam;
    }
    
    public static List<PS_SubTask__c> createPSSubtask(List<PS_Task__c> createPstaskInstall){
        List<PS_SubTask__c> SUBtaskInsert =  new List<PS_SubTask__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_SubTask__c subtask11 = new PS_SubTask__c(PS_Assignee__c=userinfo.getuserid(),Task__c=createPstaskInstall[0].Id);
            SUBtaskInsert.add(subtask11); 
        }
        insert SUBtaskInsert;
        return SUBtaskInsert;
    }
    
    public static List<PS_Time_Card__c> CreatTimecard1(List<PS_Project__c> testPSProject_c){
        List<PS_Time_Card__c> PsTimeInsert = new List<PS_Time_Card__c>();
        for(Integer i=0; i <=testPSProject_c.size();  i++){
            PS_Time_Card__c PST = new PS_Time_Card__c();
            PST.Name = 'TEST';
            PST.Approver__c = userinfo.getuserid();
            PST.PS_Project__c = testPSProject_c[0].id;
            PST.Time_Card_Start_Date__c = system.today();
            PST.Time_Card_End_Date__c   = system.today();
            PST.Status__c ='Submitted';
            PST.Assignee__c = userinfo.getuserid();
            PsTimeInsert.add(PST);
        }
        insert PsTimeInsert;
        return PsTimeInsert;
    }
    
    public static List<PS_Time_Card__c> CreatTimecard3(List<PS_Project__c> testPSProject_c){
        List<PS_Time_Card__c> PsTimeInsert = new List<PS_Time_Card__c>();
        for(Integer i=0; i <=testPSProject_c.size();  i++){
            PS_Time_Card__c PST = new PS_Time_Card__c();
            PST.Name = 'TEST';
            PST.Approver__c = userinfo.getuserid();
            PST.PS_Project__c = testPSProject_c[0].id;
            PST.Time_Card_Start_Date__c = system.today();
            PST.Time_Card_End_Date__c   = system.today();
            PST.Status__c ='Recalled';
            PST.Assignee__c = userinfo.getuserid();
            PsTimeInsert.add(PST);
        }
        insert PsTimeInsert;
        return PsTimeInsert;
    }
    public static List<PS_Time_Card__c> CreatTimecard2(List<PS_Project__c> testPSProject_c){
        List<PS_Time_Card__c> PsTimeInsert = new List<PS_Time_Card__c>();
        for(Integer i=0; i <=testPSProject_c.size();  i++){
            PS_Time_Card__c PST = new PS_Time_Card__c();
            PST.Name = 'TEST';
            PST.Approver__c = userinfo.getuserid();
            PST.PS_Project__c = testPSProject_c[0].id;
            PST.Time_Card_Start_Date__c = system.today();
            PST.Time_Card_End_Date__c   = system.today();
            PST.Status__c ='Submitted';
            PST.Assignee__c = userinfo.getuserid();
            PsTimeInsert.add(PST);
        }
        insert PsTimeInsert;
        return PsTimeInsert;
    }
    
    public static List<PS_Task__c> createPstaskConsult1(List<PS_Project__c> projlst, boolean dml){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <=3 ; i++){
            PS_Task__c task1 = new PS_Task__c(Project__c=projlst[0].Id,Task_Type__c='Consult',Task_Status__c='Open',Comments__c = 'hii',Billable_Hours_Expected__c=5);
            tasklst.add(task1);
        }
        if(dml) insert tasklst;
        return tasklst;
    }
    
    public static List<PS_Time_Entry__c> createPSTimeEntryConsult2(List<PS_Task__c> createPstaskConsult1,List<PS_Time_Card__c> CreatTimecard){
        list<PS_Time_Entry__c> psoList = new list<PS_Time_Entry__c>();
        PS_Time_Entry__c psot1 = new PS_Time_Entry__c(Hours_Spent__c=1,Time_Entry_Date__c=system.today().addDays(-2),PS_Task__c=createPstaskConsult1[0].id,PS_Time_Card__c = CreatTimecard[0].id,Assignee__c =userinfo.getuserid(),Comments__c='hii',Status__c ='Draft');
        psoList.add(psot1);
        insert psoList;
        return psoList;
    }
    
    public static List<PS_Task__c> createPS_Task2(List<PS_Project__c> projlst, list<Account> actlst){
        List<PS_Task__c> tasklst =  new List<PS_Task__c>();
        for(Integer i=0; i <= projlst.size() ; i++){
            PS_Task__c pt = new PS_Task__c();
            pt.Task_Start_Date__c =  system.today();
            pt.Task_Status__c = 'Open';
            pt.Task_Type__c = 'T&E';
            pt.Consult_Quantity__c = 1;
            pt.Project__c = projlst[0].Id;
            pt.Task_End_date__c = system.today();
            pt.Account__c = actlst[0].id;
            pt.Billable_Hours_Expected__c = 40;
            tasklst.add(pt);
        }
        insert tasklst;
        return tasklst;
    }
    
    //========================================================================================================================
    public static List<Opportunity> createOppo(List<Account> actlst, List<Contact> createcont){
        List<Opportunity> opplst = new List<Opportunity>();
        for (Integer j=0;j<actlst.size();j++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'testopp';
            opp.StageName = '1 Discovery';
            opp.AccountId = actlst[0].id;
            opp.Opportunity_Type__c = 'New Customer';
            opp.Opportunity_Sub_Type__c = 'Regular';
            opp.CloseDate = system.today();
            opp.Business_Unit__c = 'Mosaic';
            //opp.ForecastCategory = 'Upside';
            opp.ContactId = createcont[0].id;
            opp.Deal_Registration_Type__c = 'Rubrik Sourced';
            opp.Initial_Contacts_Name__c = createcont[0].id;
            opplst.add(opp);
        }
        insert opplst;
        return opplst;
    }
    
    public static List<OpportunityContactRole> createOpportunityContactRole(List<Contact> createcont,List<Opportunity> createOppo){
        List<OpportunityContactRole> opplstc = new List<OpportunityContactRole>();
        for (Integer j=0;j<createcont.size();j++) {
            OpportunityContactRole oppC = new OpportunityContactRole();
            oppC.ContactId     = createcont[0].id;
            oppC.Role          = 'Technical Buyer';
            oppC.IsPrimary     = true;
            oppc.OpportunityId = createOppo[0].id;
            opplstc.add(oppC);
        }
        insert opplstc;
        return opplstc; 
    }
    
    public static List<PS_Project__c> createPS_Projectwithoppp(List<Opportunity> createOppo, List<Contact> createcont, List<Account> actlst){
        List<PS_Project__c> projlst =  new List<PS_Project__c>();
        for(Integer i=0; i<= createOppo.size(); i++){
            PS_Project__c pro = new PS_Project__c();
            pro.Account__c = actlst[0].id;
            pro.Project_Manager__c =userinfo.getuserid();
            pro.Project_Status__c = 'Open';
            pro.Name = 'Test Project';
            pro.Welcome_Letter_Contact__c = createOppo[0].Id;
            pro.Customer_Project_Contact__c = createOppo[0].id;
            pro.Opportunity__c = createOppo[0].id; 
            //  pro.PO_Number__c  = '65475677';
            projlst.add(pro);
        }
        insert projlst;
        return projlst;
    }
    
    public static List<Order> testordersRevenue (List<Account> actlst ,List<Opportunity> opplstc,List<PS_Project__c> createPS_Projectwithoppp){
        List<order> ordlst = new List<order>();
        for(Integer i=0; i< 5; i++){
            Order od2 = new Order();
            od2.AccountId = actlst[0].Id;
            od2.OpportunityId =opplstc[0].Id;
            od2.EffectiveDate = Date.Today();
            od2.Order_Number__c = '56474';
            od2.Order_Status__c = 'PO Received';
            od2.ShippingStreet ='Test Street';
            od2.ShippingCity ='Test City';
            od2.ShippingState ='California';
            od2.ShippingCountry ='United States';
            od2.ShippingPostalcode ='94820';
            od2.PS_Project__c = createPS_Projectwithoppp[0].id;
            od2.Type = 'Revenue';
            od2.Status ='Draft';
            //od2.ship_To_Name__c=acc.id;
            od2.Shipping_Address_Label__c = null;
            ordlst.add(od2);
        }
        insert ordlst;   
        return ordlst;          
    }
    
    public static List<Order> testorderPoc (List<Account> actlst ,List<Opportunity> opplstc,List<PS_Project__c> createPS_Projectwithoppp){
        List<order> ordlst = new List<order>();
        for(Integer i=0; i< 10; i++){
            Order od2 = new Order();
            od2.AccountId = actlst[0].Id;
            od2.OpportunityId =opplstc[0].Id;
            od2.EffectiveDate = Date.Today();
            od2.Order_Number__c = '56474';
            od2.Order_Status__c = 'PO Received';
            od2.ShippingStreet ='Test Street';
            od2.ShippingCity ='Test City';
            od2.ShippingState ='California';
            od2.ShippingCountry ='United States';
            od2.ShippingPostalcode ='94820';
            od2.PS_Project__c = createPS_Projectwithoppp[0].id;
            od2.Type = 'POC';
            od2.PoNumber = 'weeded22';
            od2.POC_Opportunity__c = opplstc[0].Id;
            od2.Status ='Draft';
            //od2.ship_To_Name__c=acc.id;
            od2.Shipping_Address_Label__c = null;
            ordlst.add(od2);
        }
        insert ordlst;   
        return ordlst;          
    }
    public static List<task> createTaskcontact(Integer numTasks, list<Contact> createContactsNQ) {
        List<task> tasklst = new List<task>();
        for(Integer i=0;i<numTasks;i++) {
            task tsk = (new task(WhoID = createContactsNQ[0].id, Priority='Normal',Status='In progress',Subject='Meeting Set',ActivityDate=system.today()+30));
            tasklst.add(tsk);
        }
        insert tasklst;
        return tasklst;
    }
    
    public static list<Lead> createLead(Integer numLeads){
        List<Lead> ldlst = new List<Lead>();
        for(Integer i=0; i<numLeads; i++){
            Lead ld = new Lead();
            ld.FirstName = 'Test'+i;
            ld.LastName = 'Lead';
            ld.Phone = '123456789';
            ld.Company = 'REdSky';
            ld.Email = 'Test@REdSky.com';
            ld.Title = 'Sr.Dev';
            ld.Purchase_Timeframe__c = 'N/A';
            ld.Street = 'Street';
            ld.StateCode = 'AK';
            ld.LeadSource = 'E-mail';
            ld.PostalCode = '421302';
            ld.City = 'City';
            ld.CountryCode = 'US';
            ld.SDR_Led__c=true;
            ld.Partner__c = 'Rubrik';
            ld.Partner_Rep__c = 'Rep Name';
            ld.Partner_Rep_Phone_Number__c = '1234567890';
            ld.Partner_Rep_Email_Address__c = 'partner@redsky.com';
            ld.Secondary_Email_for_Deal_Reg__c = 'partner@redsky.com';
            ldlst.add(ld);    
        }
        insert ldlst;
        return ldlst;
    }
    
    public static List<task> createTasklead(Integer numTasks, list<Lead> createLead) {
        List<task> tasklst = new List<task>();
        for(Integer i=0; i<numTasks; i++) {
            task tsk = (new task(WhoID = createLead[0].id, Priority='Normal',Status='In progress',Subject='Meeting Set',ActivityDate=system.today()+30));
            tasklst.add(tsk);
        }
        insert tasklst;
        return tasklst;
    }
}