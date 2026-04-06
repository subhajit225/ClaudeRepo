global class Opportunity_Renewal_Batch implements Database.Batchable<sObject>, Database.stateful{
    
    public Set<Opportunity> processedOpptys = new Set<Opportunity>();
    global Database.QueryLocator start(Database.BatchableContext BC){ //and OpportunityId = \'006S0000009yFdQ\' ,Order_Service_Item__r.Product2Id
    /* FOR TEST PURPOSE ONLY
        string entl='5500q00000005G7';
        string whereClause = ' id = \'' + entl + '\' ';
        return Database.getQueryLocator('select id ,Account.name,AccountID, Renewed__c, Account.OwnerID,startDate,EndDate,Order_Service_Item__r.Order.Opportunity.OwnerID,Order_Service_Item__r.Order.Opportunity.LeadSource,Order_Service_Item__r.Order.Opportunity.Partner_Lookup__c,Order_Service_Item__r.Order.Opportunity.Distributor_Lookup__c  from Entitlement where '+whereClause);
    */
        date triggerDate = System.Today().addMonths(4);
        String query = 'select id ,Account.name,AccountID, Product__c, Renewed__c, Account.OwnerID,startDate,EndDate,Order_Service_Item__r.Order.Opportunity.OwnerID,Order_Service_Item__r.Order.Opportunity.LeadSource,Order_Service_Item__r.Order.Opportunity.Partner_Lookup__c,Order_Service_Item__r.Order.Opportunity.Distributor_Lookup__c  from Entitlement where EndDate =: triggerDate and Renewed__c = false' + (Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(query);
    }
    // Execute Metjod to perform Logic on Batch
    global void execute(Database.BatchableContext BC, List<Entitlement> scope){
      Map<Id,List<Entitlement>> mapParentAccList = new Map<Id,List<Entitlement>>();
      List<Opportunity> oppListToCreate = new List<Opportunity>();
      Set<Id> parentAccList = new Set<Id>();
      List<Opportunity> oppListToUpdate = new List<Opportunity>();
      List<OpportunityLineItem> oppLineItemsListToCreate = new List<OpportunityLineItem>();
      List<Entitlement> entitlementsList; // = new List<Entitlement>();
      List<Entitlement> entitlementsUpdateList = new List<Entitlement>();
      List<Id> OrderLineItemIDList ;
      List<Id> ProductIDList;
      List<Id> allOrderLineItemIDList =new List<Id>();
      List<Id> allProductIDList=new List<Id>();
      Map<Id,ID> mapOItemPEntryList = new Map<Id,ID>();
      Map<Id,Decimal> mapOItemPEntryUnitPriceList = new Map<Id,Decimal>();
      Map<Id,List<Entitlement>> mapAccountIDEntilements = new Map<Id,List<Entitlement>>();
      Map<Id,List<ID>> mapAccountIDOli = new Map<Id,List<Id>>();
      Map<Id,List<ID>> mapAccountIDprod = new Map<Id,List<Id>>();
      system.debug('scope  =='+scope);
      for(Entitlement ent : scope){
          parentAccList.add(ent.AccountID);
      }
      for(Id accId : parentAccList){
          entitlementsList = new List<Entitlement>();
          OrderLineItemIDList = new List<ID>();
          ProductIDList = new List<ID>();
          for(Entitlement ent : scope){
            system.debug('ent.EndDate.addDays(-120) =='+ent.EndDate.addMonths(-4));
            system.debug('System.Today() =='+System.Today());
            if(ent.EndDate != null && ent.EndDate.addMonths(-4)== System.Today() && ent.Renewed__c ==false && ent.accountID ==accId){
              entitlementsList.add(ent);
              if(ent.Order_Service_Item__c != null )
              OrderLineItemIDList.add(ent.Order_Service_Item__c);
              else
              ProductIDList.add(ent.Product__c);
              
              
            } 
          }
          system.debug('initial entitlementsList Size()==='+entitlementsList.size()+'==Values ==='+entitlementsList);
          system.debug('initial OrderLineItemIDList Size()==='+OrderLineItemIDList.size()+'==Values ==='+OrderLineItemIDList);
          system.debug('initial ProductIDList Size()==='+ProductIDList.size()+'==Values ==='+ProductIDList);
          if(entitlementsList.size()>0 )
            mapAccountIDEntilements.put(accId,entitlementsList);
          if(OrderLineItemIDList.size()>0 ) {   
              mapAccountIDOli.put(accID,OrderLineItemIDList);
              allOrderLineItemIDList.addAll(OrderLineItemIDList);
              }
          if(ProductIDList.size()>0 ){
              mapAccountIDprod.put(accID,ProductIDList);
              allProductIDList.addAll(ProductIDList);
              }
          
          
      }
      system.debug('@@@ value of mapAccountIDEntilements=='+mapAccountIDEntilements+'size()=='+mapAccountIDEntilements.size());
      
      /*  COMMENTED LOGIC FOR GROUPING BY NEXT 60 DAYS BASED ON ENTITLEMENTS
        if(entitlementsList.size()>0){
        for(Entitlement ent : entitlementsList){
          system.debug('entitlementsList[0].enddate.daysBetween(ent.EndDate) =='+entitlementsList[0].enddate.daysBetween(ent.EndDate));
          system.debug('Integer.valueOf(System.label.RenewalGroupingDuration) =='+Integer.valueOf(System.label.RenewalGroupingDuration));
            if(entitlementsList.size()>0 && entitlementsList[0].enddate.daysBetween(ent.EndDate) <= Integer.valueOf(System.label.RenewalGroupingDuration) && entitlementsList[0].enddate.daysBetween(ent.EndDate)>0){
              system.debug(' 2222 entitlementsList[0].enddate.daysBetween(ent.EndDate) =='+entitlementsList[0].enddate.daysBetween(ent.EndDate));
              entitlementsList.add(ent);
              OrderLineItemIDList.add(ent.Order_Service_Item__c);
            }
          }
        }
      */
      system.debug('entitlementsList Size()==='+entitlementsList.size()+'==Values ==='+entitlementsList);
      Set<Entitlement> tempSet = new Set<Entitlement>();
      tempSet.addAll(entitlementsList);
      entitlementsList.clear();
      entitlementsList.addAll(tempSet);
      system.debug('entitlementsList after set Size()==='+entitlementsList.size()+'==Values ==='+entitlementsList);
      system.debug('OrderLineItemIDList Size()==='+OrderLineItemIDList.size()+'==Values ==='+OrderLineItemIDList);

      for(OrderItem oi : [select id, PricebookentryId,unitPrice from OrderItem where Id In: allOrderLineItemIDList ]){
        mapOItemPEntryList.put(oi.id,oi.PricebookentryId);
        mapOItemPEntryUnitPriceList.put(oi.id, oi.unitPrice); //]
      }
      for(PricebookEntry pbe : [SELECT Id, Product2Id, unitPrice
                                             FROM PricebookEntry WHERE Product2Id in: allProductIDList AND Pricebook2.IsStandard = TRUE]){
            mapOItemPEntryList.put(pbe.Product2Id,pbe.id);
            mapOItemPEntryUnitPriceList.put(pbe.Product2Id, pbe.unitPrice);                                                                          
      }
      system.debug('mapOItemPEntryList Size()==='+mapOItemPEntryList.size()+'==Values ==='+mapOItemPEntryList);
      system.debug('mapOItemPEntryUnitPriceList Size()==='+mapOItemPEntryUnitPriceList.size()+'==Values ==='+mapOItemPEntryUnitPriceList);
      for(Id accId: mapAccountIDEntilements.keySet()){
          Opportunity renewalOpp ;
            Entitlement entl = mapAccountIDEntilements.get(accId)[0];
            renewalOpp = new Opportunity(AccountID = entl.AccountId,Name= entl.Account.name+' - Renewal',OwnerID= entl.Account.OwnerID,
            StageName = '1 Discovery' ,
            Type = 'Existing Customer',
            Opportunity_Type__c = 'Existing Customer',
            Opportunity_Sub_Type__c = 'Renewal',
            CloseDate = System.Today().addMonths(4));
            for(Entitlement entlobj : mapAccountIDEntilements.get(accId) ){
                system.debug('entlobj--'+entlobj);
                system.debug('entlobj os--'+entlobj.Order_Service_Item__r.Order.Opportunity.Partner_Lookup__c);
                system.debug('entlobj os--'+entlobj.Order_Service_Item__c);
                if(entlobj.Order_Service_Item__c != null){
                    renewalOpp.LeadSource=entlobj.Order_Service_Item__r.Order.Opportunity.LeadSource;
                    renewalOpp.Partner_Lookup__c= entlobj.Order_Service_Item__r.Order.Opportunity.Partner_Lookup__c;
                    renewalOpp.Distributor_Lookup__c = entlobj.Order_Service_Item__r.Order.Opportunity.Distributor_Lookup__c;
                }
            }
            oppListToCreate.add(renewalOpp);
            
      }
      if(!oppListToCreate.isEmpty()){
        database.insert(oppListToCreate,false);
        
      }
     
      System.debug('mapAccountIDOli=='+mapAccountIDOli);
      System.debug('mapAccountIDprod=='+mapAccountIDprod);
     
      for(Opportunity oppty : oppListToCreate){
          
          if(mapAccountIDOli.containsKey(oppty.AccountId) && mapAccountIDOli.get(oppty.AccountId) != null ){
              for(id pbe : mapAccountIDOli.get(oppty.AccountId)){
                  System.debug('pbe=='+pbe);
                  oppLineItemsListToCreate.add( new OpportunityLineItem(PricebookEntryId = mapOItemPEntryList.get(pbe), quantity=1 ,unitPrice =mapOItemPEntryUnitPriceList.get(pbe),OpportunityId=oppty.Id));
              }
          }
          if(mapAccountIDprod.containsKey(oppty.AccountId) && mapAccountIDprod.get(oppty.AccountId) != null ){
              for(id pbe : mapAccountIDprod.get(oppty.AccountId)){
                  System.debug('pbe22=='+pbe);
                  decimal unitprice =mapOItemPEntryUnitPriceList.get(pbe) != null? mapOItemPEntryUnitPriceList.get(pbe):0.00;
                  if(mapOItemPEntryList.get(pbe) != null)
                  oppLineItemsListToCreate.add( new OpportunityLineItem(PricebookEntryId = mapOItemPEntryList.get(pbe), quantity=1 ,unitPrice = unitprice,OpportunityId=oppty.Id));
              }
          }
      }
      System.debug('oppLineItemsListToCreate=='+oppLineItemsListToCreate+'size()'+oppLineItemsListToCreate.size());
      for(List<Entitlement> entl : mapAccountIDEntilements.values()){
      for(Entitlement entlobj : entl){
        if(entlobj.renewed__c != true)
          entitlementsUpdateList.add(new Entitlement(id=entlobj.id, renewed__c=true));
        }
      processedOpptys.addAll(oppListToCreate);  
    }
      
      

      /*for(Opportunity opp : oppListToCreate){
        for(Entitlement entl : entitlementsList){
        oppLineItemsListToCreate.add( new OpportunityLineItem(PricebookEntryId = mapOItemPEntryList.get(entl.Order_Service_Item__c), quantity=1 ,unitPrice =mapOItemPEntryUnitPriceList.get(entl.Order_Service_Item__c),OpportunityId=opp.Id));
        
      }*/
      Set<Entitlement> EntSet = new Set<Entitlement>();
      EntSet.AddAll(entitlementsUpdateList);
      entitlementsUpdateList.clear();
      entitlementsUpdateList.addAll(EntSet);
      System.debug('test entitlementsUpdateList'+ entitlementsUpdateList);
      System.debug('test oppLineItemsListToCreate'+ oppLineItemsListToCreate);
      if(!oppLineItemsListToCreate.isEmpty())
          insert oppLineItemsListToCreate;

      if(!entitlementsUpdateList.isEmpty())
        Database.update(entitlementsUpdateList,false);
      //}
      }
      global void finish(Database.BatchableContext processOpptys) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {System.Label.RenewalOpptyAlertRecieversEmail});
        email.setSaveAsActivity(false);
        system.debug('processedOpptys '+processedOpptys);
        String subject = 'Renewal Opportunity Creation';
        email.setSubject(subject);

        String allOpptys='';
        
        for(Opportunity opp : processedOpptys){
            allOpptys += '<tr><td style="text-align:center; vertical-align:middle;">'+opp.Name+'</td><td style="text-align:center; vertical-align:middle;"><a href='+system.URL.getSalesforceBaseUrl().toExternalForm()+'/'+opp.Id+' target="_Blank">Link</a></td></tr>';
        }
        if(allOpptys != ''){
            String tableBody ='<table border="1"><tbody><th>Name</th><th>Detail Link</th>'+allOpptys+'</tbody></table>';
            email.setHTMLBody(System.Label.RenewalOpptyAlertMessage +'<br/><br/>'+ tableBody+'<br/><br/><br/> Thanks');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }
    }
}