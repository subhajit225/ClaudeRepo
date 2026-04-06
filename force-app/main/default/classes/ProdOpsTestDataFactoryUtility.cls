/******************************************************************************
 * @description       : This is Test Data Factory class for ProdOps
 * @author            : Prashik
 * @last modified on  : 11-08-2025
 * @last modified by  :
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   11-08-2025    Prashik       Initial Version
 ******************************************************************************/
@isTest
public without sharing class ProdOpsTestDataFactoryUtility {
  private Map<String, Map<String, Object>> commonFields = new Map<String, Map<String, Object>>();
  private Map<String, Map<String, List<Object>>> indexedFields = new Map<String, Map<String, List<Object>>>();
  private Map<String, Integer> recordCounts = new Map<String, Integer>();
  private Boolean shouldInsertRecord = false;

  public Map<String, List<SObject>> createdRecords = new Map<String, List<SObject>>();

  /**
   * @description This is constructor method
   * @return ProdOpsTestDataFactoryUtility
   */
  public static ProdOpsTestDataFactoryUtility start() {
    return new ProdOpsTestDataFactoryUtility();
  }

  /**
   * @description This method is used to set the commonFields for sObject
   * @param sObjectType
   * @param fieldName
   * @param value
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility withCommonField(String sObjectType, String fieldName, Object value) {
    if (!commonFields.containsKey(sObjectType)) {
      commonFields.put(sObjectType, new Map<String, Object>());
    }
    commonFields.get(sObjectType).put(fieldName, value);
    return this;
  }

  /**
   * @description This method is used to set the IndexedFields for sObject
   * @param sObjectType
   * @param fieldName
   * @param values
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility withIndexedField(String sObjectType, String fieldName, List<Object> values) {
    if (!indexedFields.containsKey(sObjectType)) {
      indexedFields.put(sObjectType, new Map<String, List<Object>>());
    }
    indexedFields.get(sObjectType).put(fieldName, values);
    return this;
  }

  /**
   * @description This method is used to set the Count for sObject to be created
   * @param sObjectType
   * @param count
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility withRecordCount(String sObjectType, Integer count) {
    recordCounts.put(sObjectType, count);
    return this;
  }

  /**
   * @description This method is used to set the Insert Flag
   * @param insertFlag
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility withInsertFlag(Boolean insertFlag) {
    shouldInsertRecord = insertFlag;
    return this;
  }

  /**
   * @description This method is used to generate Accounts
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateAccounts() {
    Integer count = recordCounts.get('Account') == null ? 1 : recordCounts.get('Account');
    List<Account> accs = new List<Account>();
    for (Integer i = 0; i < count; i++) {
      Account acc = new Account(Name = 'Test Account ' + i);
      applyCustomFields(acc, 'Account', i);
      accs.add(acc);
    }
    if (shouldInsertRecord) {
      insert accs;
    }
    createdRecords.put('Account', accs);
    return this;
  }

  /**
   * @description This method is used to generate Contacts
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateContacts() {
    if (!createdRecords.containsKey('Account'))
      generateAccounts();
    Integer count = recordCounts.get('Contact') == null ? 1 : recordCounts.get('Contact');

    List<Account> accs = (List<Account>) createdRecords.get('Account');
    List<Contact> cons = new List<Contact>();
    for (Integer i = 0; i < count; i++) {
      Contact c = new Contact(LastName = 'Test Contact ' + i, AccountId = accs[0].Id);
      applyCustomFields(c, 'Contact', i);
      cons.add(c);
    }
    if (shouldInsertRecord) {
      insert cons;
    }
    createdRecords.put('Contact', cons);
    return this;
  }

  /**
   * @description This method is used to generate Opportunities
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateOpportunities() {
    if (!createdRecords.containsKey('Contact'))
      generateContacts();
    Integer count = recordCounts.get('Opportunity') == null ? 1 : recordCounts.get('Opportunity');

    List<Account> accs = (List<Account>) createdRecords.get('Account');
    List<Opportunity> opps = new List<Opportunity>();
    for (Integer i = 0; i < count; i++) {
      Opportunity opp = new Opportunity(Name = 'Test Opp ' + i, CloseDate = Date.today().addDays(30), StageName = 'Prospecting', AccountId = accs[0].Id);
      applyCustomFields(opp, 'Opportunity', i);
      opps.add(opp);
    }
    if (shouldInsertRecord) {
      insert opps;
    }
    createdRecords.put('Opportunity', opps);
    return this;
  }

  /**
   * @description This method is used to generate Quotes
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateQuotes() {
    if (!createdRecords.containsKey('Opportunity'))
      generateOpportunities();
    Integer count = recordCounts.get('SBQQ__Quote__c') == null ? 1 : recordCounts.get('SBQQ__Quote__c');

    List<Opportunity> opps = (List<Opportunity>) createdRecords.get('Opportunity');
    List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    for (Integer i = 0; i < count; i++) {
      SBQQ__Quote__c q = new SBQQ__Quote__c(SBQQ__Account__c = opps[0].AccountId, SBQQ__Opportunity2__c = opps[0].Id);
      applyCustomFields(q, 'SBQQ__Quote__c', i);
      quotes.add(q);
    }
    SBQQ.TriggerControl.disable();
    if (shouldInsertRecord) {
      insert quotes;
    }
    SBQQ.TriggerControl.enable();
    createdRecords.put('SBQQ__Quote__c', quotes);
    generateQuoteLines();
    return this;
  }

  /**
   * @description This method is used to generate Products based on the Business Models
   * @param bm
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateProducts(String bm) {
    List<Map<String, Object>> prodDefs = ProdOpsTestDataFactoryDefaults.getProductsForBM(bm);
    String priceBookId = ProdOpsTestDataFactoryDefaults.pricebookId;
    List<Product2> products = new List<Product2>();
    for (Integer i = 0; i < prodDefs.size(); i++) {
      Product2 p = new Product2();
      applyCustomFields(p, 'Product2', i);
      for (String f : prodDefs[i].keySet()) {
        p.put(f, prodDefs[i].get(f));
      }
      products.add(p);
    }
    insert products;
    List<PricebookEntry> pbes = new List<PricebookEntry>();
    for (Product2 p : products) {
      PricebookEntry pbe = new PricebookEntry(Product2Id = p.Id, Pricebook2Id = pricebookId, UnitPrice = 100, IsActive = true);
      applyCustomFields(pbe, 'PricebookEntry', 0);
      pbes.add(pbe);
    }
    insert pbes;
    createdRecords.put('Product2', products);
    createdRecords.put('PricebookEntry', pbes);
    return this;
  }

  /**
   * @description This method is used to generate QuoteLines
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateQuoteLines() {
    if (!createdRecords.containsKey('SBQQ__Quote__c'))
      generateQuotes();
    if (!createdRecords.containsKey('Product2'))
      generateProducts('');

    List<SBQQ__Quote__c> quotes = (List<SBQQ__Quote__c>) createdRecords.get('SBQQ__Quote__c');
    List<PricebookEntry> pbes = (List<PricebookEntry>) createdRecords.get('PricebookEntry');

    List<SBQQ__QuoteLine__c> qlis = new List<SBQQ__QuoteLine__c>();
    for (SBQQ__Quote__c q : quotes) {
      for (PricebookEntry pbe : pbes) {
        SBQQ__QuoteLine__c qli = new SBQQ__QuoteLine__c(SBQQ__Quote__c = q.Id, SBQQ__PricebookEntryId__c = pbe.Id, SBQQ__ListPrice__c = pbe.UnitPrice);
        applyCustomFields(qli, 'SBQQ__QuoteLine__c', 0);
        qlis.add(qli);
      }
    }
    SBQQ.TriggerControl.disable();
    if (shouldInsertRecord) {
      insert qlis;
    }
    SBQQ.TriggerControl.enable();
    createdRecords.put('SBQQ__QuoteLine__c', qlis);
    return this;
  }

  /**
   * @description This method is used to generate Orders
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateOrders() {
    if (!createdRecords.containsKey('SBQQ__Quote__c'))
      generateQuotes();
    Integer count = recordCounts.get('Order') == null ? 1 : recordCounts.get('Order');

    List<Account> accs = (List<Account>) createdRecords.get('Account');
    List<Order> orders = new List<Order>();
    for (Integer i = 0; i < count; i++) {
      Order ord = new Order(AccountId = accs[0].Id, EffectiveDate = Date.today(), Status = 'Draft');
      applyCustomFields(ord, 'Order', i);
      orders.add(ord);
    }
    if (shouldInsertRecord) {
      insert orders;
    }
    createdRecords.put('Order', orders);
    generateOrderItems();
    return this;
  }

  /**
   * @description This method is used to generate OrderItems
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateOrderItems() {
    if (!createdRecords.containsKey('Order'))
      generateOrders();
    if (!createdRecords.containsKey('Product2'))
      generateProducts('');

    List<Order> orders = (List<Order>) createdRecords.get('Order');
    List<PricebookEntry> pbes = (List<PricebookEntry>) createdRecords.get('PricebookEntry');

    List<OrderItem> ois = new List<OrderItem>();
    for (Order ord : orders) {
      for (PricebookEntry pbe : pbes) {
        OrderItem oi = new OrderItem(OrderId = ord.Id, PricebookEntryId = pbe.Id, Quantity = 1, UnitPrice = pbe.UnitPrice);
        applyCustomFields(oi, 'OrderItem', 0);
        ois.add(oi);
      }
    }
    if (shouldInsertRecord) {
      insert ois;
    }
    createdRecords.put('OrderItem', ois);
    return this;
  }

  /**
   * @description This method is used to generate Service Contracts
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateServiceContracts() {
    if (!createdRecords.containsKey('Account'))
      generateAccounts();
    Integer count = recordCounts.get('ServiceContract') == null ? 1 : recordCounts.get('ServiceContract');

    List<Account> accs = (List<Account>) createdRecords.get('Account');
    List<ServiceContract> scs = new List<ServiceContract>();
    for (Integer i = 0; i < count; i++) {
      ServiceContract sc = new ServiceContract(AccountId = accs[0].Id);
      applyCustomFields(sc, 'ServiceContract', i);
      scs.add(sc);
    }
    if (shouldInsertRecord) {
      insert scs;
    }
    createdRecords.put('ServiceContract', scs);
    return this;
  }

  /**
   * @description This method is used to generate Contract Line Items
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateContractLineItems() {
    if (!createdRecords.containsKey('ServiceContract'))
      generateServiceContracts();
    if (!createdRecords.containsKey('Product2'))
      generateProducts('');

    List<ServiceContract> scs = (List<ServiceContract>) createdRecords.get('ServiceContract');
    List<PricebookEntry> pbes = (List<PricebookEntry>) createdRecords.get('PricebookEntry');

    List<ContractLineItem> clis = new List<ContractLineItem>();
    for (ServiceContract sc : scs) {
      for (PricebookEntry pbe : pbes) {
        ContractLineItem cli = new ContractLineItem(ServiceContractId = sc.Id, PricebookEntryId = pbe.Id, StartDate = sc.StartDate, EndDate = sc.EndDate, Quantity = 1);
        applyCustomFields(cli, 'ContractLineItem', 0);
        clis.add(cli);
      }
    }
    if (shouldInsertRecord) {
      insert clis;
    }
    createdRecords.put('ContractLineItem', clis);
    return this;
  }

  /**
   * @description This method is used to generate Assets
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateAssets() {
    if (!createdRecords.containsKey('Product2'))
      generateProducts('');
    if (!createdRecords.containsKey('Account'))
      generateAccounts();

    Integer count = recordCounts.get('Asset') == null ? 1 : recordCounts.get('Asset');

    List<Product2> prods = (List<Product2>) createdRecords.get('Product2');
    List<Account> accs = (List<Account>) createdRecords.get('Account');

    List<Asset> assets = new List<Asset>();
    for (Integer i = 0; i < count; i++) {
      Asset a = new Asset(Product2Id = prods[0].Id, AccountId = accs[0].Id);
      applyCustomFields(a, 'Asset', i);
      assets.add(a);
    }
    if (shouldInsertRecord) {
      insert assets;
    }
    createdRecords.put('Asset', assets);
    return this;
  }

  /**
   * @description This method is used to generate Entitlements
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateEntitlements() {
    if (!createdRecords.containsKey('Asset'))
      generateAssets();

    Integer count = recordCounts.get('Entitlement') == null ? 1 : recordCounts.get('Entitlement');
    List<Asset> assets = (List<Asset>) createdRecords.get('Asset');

    List<Entitlement> ents = new List<Entitlement>();
    for (Integer i = 0; i < count; i++) {
      Entitlement e = new Entitlement(AssetId = assets[0].Id);
      applyCustomFields(e, 'Entitlement', i);
      ents.add(e);
    }
    if (shouldInsertRecord) {
      insert ents;
    }
    createdRecords.put('Entitlement', ents);
    return this;
  }

  /**
   * @description This method is used to generate Cases
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateCases() {
    if (!createdRecords.containsKey('Account'))
      generateAccounts();
    if (!createdRecords.containsKey('Contact'))
      generateContacts();

    Integer count = recordCounts.get('Case') == null ? 1 : recordCounts.get('Case');
    List<Account> accs = (List<Account>) createdRecords.get('Account');
    List<Contact> cons = (List<Contact>) createdRecords.get('Contact');

    List<Case> cases = new List<Case>();
    for (Integer i = 0; i < count; i++) {
      Case c = new Case(AccountId = accs[0].Id, ContactId = cons[0].Id);
      applyCustomFields(c, 'Case', i);
      cases.add(c);
    }
    if (shouldInsertRecord) {
      insert cases;
    }
    createdRecords.put('Case', cases);
    return this;
  }

  /**
   * @description This method is used to generate Clusters
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateClusters() {
    Integer count = recordCounts.get('Cluster__c') == null ? 1 : recordCounts.get('Cluster__c');
    List<Cluster__c> clusters = new List<Cluster__c>();

    for (Integer i = 0; i < count; i++) {
      Cluster__c c = new Cluster__c();
      applyCustomFields(c, 'Cluster__c', i);
      clusters.add(c);
    }
    if (shouldInsertRecord) {
      insert clusters;
    }
    createdRecords.put('Cluster__c', clusters);
    return this;
  }

  /**
   * @description This method is used to generate Chassis
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateChassis() {
    if (!createdRecords.containsKey('Asset'))
      generateAssets();

    Integer count = recordCounts.get('Chassis__c') == null ? 1 : recordCounts.get('Chassis__c');
    List<Asset> assets = (List<Asset>) createdRecords.get('Asset');

    List<Chassis__c> chs = new List<Chassis__c>();
    for (Integer i = 0; i < count; i++) {
      Chassis__c c = new Chassis__c(Asset__c = assets[0].Id);
      applyCustomFields(c, 'Chassis__c', i);
      chs.add(c);
    }
    if (shouldInsertRecord) {
      insert chs;
    }
    createdRecords.put('Chassis__c', chs);
    return this;
  }

  /**
   * @description This method is used to generate Power Supplies
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generatePowerSupplies() {
    if (!createdRecords.containsKey('Asset'))
      generateAssets();

    Integer count = recordCounts.get('Power_Supply__c') == null ? 1 : recordCounts.get('Power_Supply__c');
    List<Asset> assets = (List<Asset>) createdRecords.get('Asset');

    List<Power_Supply__c> psus = new List<Power_Supply__c>();
    for (Integer i = 0; i < count; i++) {
      Power_Supply__c psu = new Power_Supply__c(Asset__c = assets[0].Id);
      applyCustomFields(psu, 'Power_Supply__c', i);
      psus.add(psu);
    }
    if (shouldInsertRecord) {
      insert psus;
    }
    createdRecords.put('Power_Supply__c', psus);
    return this;
  }

  /**
   * @description This method is used to generate Nodes
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateNodes() {
    if (!createdRecords.containsKey('Cluster__c'))
      generateClusters();
    if (!createdRecords.containsKey('Asset'))
      generateAssets();
    if (!createdRecords.containsKey('Chassis__c'))
      generateChassis();

    Integer count = recordCounts.get('Node__c') == null ? 1 : recordCounts.get('Node__c');

    List<Cluster__c> clusters = (List<Cluster__c>) createdRecords.get('Cluster__c');
    List<Asset> assets = (List<Asset>) createdRecords.get('Asset');
    List<Chassis__c> chs = (List<Chassis__c>) createdRecords.get('Chassis__c');

    List<Node__c> nodes = new List<Node__c>();
    for (Integer i = 0; i < count; i++) {
      Node__c n = new Node__c(Cluster__c = clusters[0].Id, Asset__c = assets[0].Id, Chassis__c = chs[0].Id);
      applyCustomFields(n, 'Node__c', i);
      nodes.add(n);
    }
    if (shouldInsertRecord) {
      insert nodes;
    }
    createdRecords.put('Node__c', nodes);
    return this;
  }

  /**
   * @description This method is used to generate Drives
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateDrives() {
    if (!createdRecords.containsKey('Asset'))
      generateAssets();
    if (!createdRecords.containsKey('Node__c'))
      generateNodes();

    Integer count = recordCounts.get('Drive__c') == null ? 1 : recordCounts.get('Drive__c');
    List<Asset> assets = (List<Asset>) createdRecords.get('Asset');
    List<Node__c> nodes = (List<Node__c>) createdRecords.get('Node__c');

    List<Drive__c> drives = new List<Drive__c>();
    for (Integer i = 0; i < count; i++) {
      Drive__c d = new Drive__c(Asset__c = assets[0].Id, Node__c = nodes[0].Id);
      applyCustomFields(d, 'Drive__c', i);
      drives.add(d);
    }
    if (shouldInsertRecord) {
      insert drives;
    }
    createdRecords.put('Drive__c', drives);
    return this;
  }

  /**
   * @description This method is used to generate Memories
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateMemory() {
    if (!createdRecords.containsKey('Asset'))
      generateAssets();
    if (!createdRecords.containsKey('Node__c'))
      generateNodes();

    Integer count = recordCounts.get('Memory__c') == null ? 1 : recordCounts.get('Memory__c');
    List<Asset> assets = (List<Asset>) createdRecords.get('Asset');
    List<Node__c> nodes = (List<Node__c>) createdRecords.get('Node__c');

    List<Memory__c> mems = new List<Memory__c>();
    for (Integer i = 0; i < count; i++) {
      Memory__c m = new Memory__c(Asset__c = assets[0].Id, Node__c = nodes[0].Id);
      applyCustomFields(m, 'Memory__c', i);
      mems.add(m);
    }
    if (shouldInsertRecord) {
      insert mems;
    }
    createdRecords.put('Memory__c', mems);
    return this;
  }

  /**
   * @description This method is used to generate Spares Mapping
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateSparesMapping() {
    Integer count = recordCounts.get('Spares_Mapping__c') == null ? 1 : recordCounts.get('Spares_Mapping__c');
    List<Spares_Mapping__c> maps = new List<Spares_Mapping__c>();

    for (Integer i = 0; i < count; i++) {
      Spares_Mapping__c sm = new Spares_Mapping__c();
      applyCustomFields(sm, 'Spares_Mapping__c', i);
      maps.add(sm);
    }
    if (shouldInsertRecord) {
      insert maps;
    }
    createdRecords.put('Spares_Mapping__c', maps);
    return this;
  }

  /**
   * @description This method is used to generate RMA Orders
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateRMAOrders() {
    if (!createdRecords.containsKey('Case'))
      generateCases();
    if (!createdRecords.containsKey('Cluster__c'))
      generateClusters();

    Integer count = recordCounts.get('RMA_Order__c') == null ? 1 : recordCounts.get('RMA_Order__c');
    List<Case> cases = (List<Case>) createdRecords.get('Case');
    List<Cluster__c> clusters = (List<Cluster__c>) createdRecords.get('Cluster__c');

    List<RMA_Order__c> orders = new List<RMA_Order__c>();
    for (Integer i = 0; i < count; i++) {
      RMA_Order__c ord = new RMA_Order__c(Parent_Case__c = cases[0].Id, Cluster_ID__c = clusters[0].Id);
      applyCustomFields(ord, 'RMA_Order__c', i);
      orders.add(ord);
    }
    if (shouldInsertRecord) {
      insert orders;
    }
    createdRecords.put('RMA_Order__c', orders);
    return this;
  }

  /**
   * @description This method is used to Order Configurations
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateOrderConfigurations() {
    if (!createdRecords.containsKey('Order'))
      generateOrders();

    Integer count = recordCounts.get('Order_Configuration__c') == null ? 1 : recordCounts.get('Order_Configuration__c');
    List<Order> orders = (List<Order>) createdRecords.get('Order');

    List<Order_Configuration__c> cfgs = new List<Order_Configuration__c>();
    for (Integer i = 0; i < count; i++) {
      Order_Configuration__c oc = new Order_Configuration__c();
      applyCustomFields(oc, 'Order_Configuration__c', i);
      cfgs.add(oc);
    }
    if (shouldInsertRecord) {
      insert cfgs;
    }
    createdRecords.put('Order_Configuration__c', cfgs);
    return this;
  }

  /**
   * @description This method is used to generate PO Stages
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generatePOStages() {
    if (!createdRecords.containsKey('SBQQ__Quote__c'))
      generateQuotes();

    Integer count = recordCounts.get('PO_Stage__c') == null ? 1 : recordCounts.get('PO_Stage__c');
    List<SBQQ__Quote__c> quotes = (List<SBQQ__Quote__c>) createdRecords.get('SBQQ__Quote__c');

    List<PO_Stage__c> stages = new List<PO_Stage__c>();
    for (Integer i = 0; i < count; i++) {
      PO_Stage__c stage = new PO_Stage__c(Quote__c = quotes[0].Id);
      applyCustomFields(stage, 'PO_Stage__c', i);
      stages.add(stage);
    }
    if (shouldInsertRecord) {
      insert stages;
    }
    createdRecords.put('PO_Stage__c', stages);
    return this;
  }

  /**
   * @description This method is used to generate POC Requestes
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generatePOCs() {
    if (!createdRecords.containsKey('Order'))
      generateOrders();

    Integer count = recordCounts.get('POC__c') == null ? 1 : recordCounts.get('POC__c');
    List<Order> orders = (List<Order>) createdRecords.get('Order');

    List<POC__c> pocs = new List<POC__c>();
    for (Integer i = 0; i < count; i++) {
      POC__c poc = new POC__c(Order__c = orders[0].Id, Opportunity__c = orders[0].OpportunityId, Account__c = orders[0].AccountId);
      applyCustomFields(poc, 'POC__c', i);
      pocs.add(poc);
    }
    if (shouldInsertRecord) {
      insert pocs;
    }
    createdRecords.put('POC__c', pocs);
    return this;
  }

  /**
   * @description This method is used to generate PO Item Stages
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generatePOItemStages() {
    if (!createdRecords.containsKey('PO_Stage__c'))
      generatePOStages();
    if (!createdRecords.containsKey('SBQQ__QuoteLine__c'))
      generateQuoteLines();

    Integer count = recordCounts.get('PO_Item_Stage__c') == null ? 1 : recordCounts.get('PO_Item_Stage__c');
    List<PO_Stage__c> poStages = (List<PO_Stage__c>) createdRecords.get('PO_Stage__c');
    List<SBQQ__QuoteLine__c> qlis = (List<SBQQ__QuoteLine__c>) createdRecords.get('SBQQ__QuoteLine__c');

    // Group quote lines by QuoteId for quick lookup
    Map<Id, List<SBQQ__QuoteLine__c>> quoteLineMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
    for (SBQQ__QuoteLine__c ql : qlis) {
      if (!quoteLineMap.containsKey(ql.SBQQ__Quote__c)) {
        quoteLineMap.put(ql.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>());
      }
      quoteLineMap.get(ql.SBQQ__Quote__c).add(ql);
    }

    List<PO_Item_Stage__c> itemStages = new List<PO_Item_Stage__c>();

    for (PO_Stage__c poStage : poStages) {
      if (quoteLineMap.containsKey(poStage.Quote__c)) {
        for (SBQQ__QuoteLine__c ql : quoteLineMap.get(poStage.Quote__c)) {
          for (Integer i = 0; i < count; i++) {
            PO_Item_Stage__c itemStage = new PO_Item_Stage__c(
              Stage_PO__c = poStage.Id,
              Quote_Line__c = ql.Id,
              Product__c = ql.SBQQ__Product__c,
              Quantity__c = ql.SBQQ__Quantity__c,
              UnitPrice__c = ql.SBQQ__NetPrice__c,
              SubscriptionTerm__c = ql.SBQQ__SubscriptionTerm__c,
              ProductCode__c = ql.SBQQ__ProductCode__c
            );
            applyCustomFields(itemStage, 'PO_Item_Stage__c', i);
            itemStages.add(itemStage);
          }
        }
      }
    }

    if (!itemStages.isEmpty()) {
      if (shouldInsertRecord) {
        insert itemStages;
      }
      createdRecords.put('PO_Item_Stage__c', itemStages);
    }
    return this;
  }

  /**
   * @description This method is used to generate Users
   * @param profileId
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateUsers(Id profileId) {
    Integer count = recordCounts.containsKey('User') ? recordCounts.get('User') : 1;
    List<User> users = new List<User>();

    // Use caller-provided profile or fallback
    Profile profileToUse;
    if (profileId != null) {
      profileToUse = [SELECT Id, Name FROM Profile WHERE Id = :profileId LIMIT 1];
    } else {
      profileToUse = [
        SELECT Id, Name
        FROM Profile
        WHERE Name = 'System Administrator'
        LIMIT 1
      ];
    }

    for (Integer i = 0; i < count; i++) {
      User u = new User(
        FirstName = 'Test',
        LastName = 'User ' + i,
        Email = 'testuser' + i + '@example.com',
        Username = 'testuser' + i + '@example.com.' + System.currentTimeMillis(),
        Alias = 'tusr' + i,
        TimeZoneSidKey = 'America/Los_Angeles',
        LocaleSidKey = 'en_US',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'en_US',
        ProfileId = profileToUse.Id,
        IsActive = true
      );

      applyCustomFields(u, 'User', i);
      users.add(u);
    }
    if (shouldInsertRecord) {
      insert users;
    }
    createdRecords.put('User', users);

    return this;
  }

  /**
   * @description this method creates uniqueSuffix
   * @return String
   */
  private static String uniqueSuffix() {
    return String.valueOf(Datetime.now().getTime()) + '_' + String.valueOf(Math.random()).substring(2, 8);
  }

  /**
   * @description this method creates unique email address
   * @param prefix
   * @return String
   */
  private static String uniqueEmail(String prefix) {
    return prefix + '_' + uniqueSuffix() + '@example.com';
  }

  /**
   * @description this method generates a unique username (valid for Salesforce Users)
   * @param prefix
   * @return String
   */
  private static String uniqueUsername(String prefix) {
    return prefix + '_' + uniqueSuffix() + '@example.com';
  }

  /**
   * @description this method generates a unique string
   * @param prefix
   * @return String
   */
  private static String uniqueValue(String prefix) {
    return prefix + '_' + uniqueSuffix();
  }

  /**
   * @description This is a helper method that creates the default fields for a given object type
   * @param record
   * @param sObjectType
   * @param index
   */
  private void applyCustomFields(SObject record, String sObjectType, Integer index) {
    Map<String, Object> defaultFields = ProdOpsTestDataFactoryDefaults.getDefaultFields(sObjectType);

    if (commonFields != null && commonFields.containsKey(sObjectType)) {
      defaultFields.putAll(commonFields.get(sObjectType));
    }

    for (String fieldName : defaultFields.keySet()) {
      record.put(fieldName, defaultFields.get(fieldName));
    }

    if (indexedFields.containsKey(sObjectType)) {
      for (String f : indexedFields.get(sObjectType).keySet()) {
        List<Object> vals = indexedFields.get(sObjectType).get(f);
        if (index < vals.size()) {
          record.put(f, vals[index]);
        }
      }
    }
    ensureUniqueFields(record, sObjectType, index);
  }

  /**
   * @description This is a helper method for generating unique values for username and emails
   * @param record
   * @param sObjectType
   * @param index
   */
  private void ensureUniqueFields(SObject record, String sObjectType, Integer index) {
    Map<String, String> uniqueFieldPrefixes = new Map<String, String>{
      'User.Email' => 'testuser',
      'User.Username' => 'testuser',
      'Contact.Email' => 'testcontact',
      'Lead.Email' => 'testlead'
    };

    for (String key : uniqueFieldPrefixes.keySet()) {
      List<String> parts = key.split('\\.');
      if (parts.size() == 2 && parts[0] == sObjectType) {
        String fieldName = parts[1];
        if (record.get(fieldName) == null) {
          if (fieldName == 'Email') {
            record.put(fieldName, uniqueEmail(uniqueFieldPrefixes.get(key) + index));
          } else if (fieldName == 'Username') {
            record.put(fieldName, uniqueUsername(uniqueFieldPrefixes.get(key) + index));
          } else {
            record.put(fieldName, uniqueValue(uniqueFieldPrefixes.get(key) + index));
          }
        }
      }
    }
  }

  /**
   * @description This is a helper method that creates the common CRM Data
   * @param bm
   * @return ProdOpsTestDataFactoryUtility
   */
  private ProdOpsTestDataFactoryUtility generateBaseCRMData(String bm) {
    generateAccounts().generateContacts().generateOpportunities().generateQuotes().generateProducts(bm);
    return this;
  }

  /**
   * @description This is a helper method that creates the business model specific data
   * @param bm
   * @return ProdOpsTestDataFactoryUtility
   */
  public ProdOpsTestDataFactoryUtility generateBusinessModelData(String bm) {
    switch on bm.toLowerCase() {
      when 'polarisv2' {
        generateBaseCRMData(bm).generateQuoteLines().generateAssets().generatePOStages().generateOrders().generateOrderItems();
      }
      when 'aspen' {
        generateBaseCRMData(bm).generateQuoteLines().generatePOStages().generatePOItemStages().generateOrders().generateOrderItems();
      }
      when 'rma' {
        // RMA is different: it doesn’t need Opp/Quote/QuoteLines
        generateAccounts()
          .generateContacts()
          .withCommonField('Order', 'Type', 'RMA')
          .generateProducts(bm)
          .generateCases()
          .generateAssets()
          .generateClusters()
          .generateChassis()
          .generatePowerSupplies()
          .generateNodes()
          .generateDrives()
          .generateMemory()
          .generateSparesMapping()
          .generateRMAOrders();
      }
      when 'arroyo' {
        generateBaseCRMData(bm).generateQuoteLines().generateAssets().generateOrders().generateOrderItems();
      }
      when 'scaleutility' {
        generateBaseCRMData(bm).generateQuoteLines().generateOrders().generateOrderItems();
      }
      when 'netapp' {
        generateBaseCRMData(bm).generateQuoteLines().generatePOStages().generatePOItemStages().generateOrders().generateOrderItems();
      }
      when 'poc' {
        generateBaseCRMData(bm)
          .generateQuoteLines()
          .generatePOCs()
          .withCommonField('Order', 'Type', 'POC')
          .generateOrders()
          .generateOrderItems()
          .generateAssets()
          .generateEntitlements();
      }
      when 'replacement' {
        generateBaseCRMData(bm).generateQuoteLines().generateOrders().generateOrderItems().generateAssets();
      }
      when else {
        throw new IllegalArgumentException('Invalid business model: ' + bm);
      }
    }
    return this;
  }
}