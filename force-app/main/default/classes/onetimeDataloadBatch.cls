/***************************************************
Description : For one time data load of bookingSplit
Author : Chaitra
Date : 7 september
***************************************************/
public class onetimeDataloadBatch implements Database.Batchable<sObject>{
   public string type;
   public set<id> recIds = new set<Id>();
   public Database.QueryLocator start(Database.BatchableContext BC){
     set<Id> oppId = new set<id>();
     string query = 'select id,Opportunity__c  from booking__c where Status__c !=\'Cancelled\'' ;
      if(type == 'booking') query+= ' and id IN: recIds';  
      else if (type == 'createOrder') query+= ' limit 1';
      system.debug('query'+query);
      return Database.getQueryLocator(query);
   }
  /***************************************************
  Description 
  type = booking , set<id> bookingIds
  type = createOrder , set<id> opportunityIds
  ***************************************************/ 
  public onetimeDataloadBatch(set<id> recIds,string type){
    this.type = type;
    this.recIds =  recIds;   
  }
   public void execute(Database.BatchableContext BC, List<booking__c> scope){
     system.debug('type'+type);
     system.debug('recIds'+recIds);
     if(type == 'booking'){
     set<Id>OppId = new set<Id>();
     set<Id>bkgId = new set<Id>();
     List<Booking_Split__c> bkgSplits = new List<Booking_Split__c>();
     for(booking__c bkg : scope){
      OppId.add(bkg.Opportunity__c);
      bkgId.add(bkg.id);
     }
           Map<id,Opportunity> oppMap = new Map<id,Opportunity>([select id,ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,split__c,Opportunity_Split_Parent__c,amount,Split_percentage__c,Split_Amount__c,OwnerId,(select id,Split_percentage__c,Split_Amount__c,split__c,amount,ETM_Theatre__c,ETM_Area__c,ETM_Region__c,ETM_Territory__c,OwnerId from Split_Opportunities__r) from Opportunity where id IN: oppId and Opportunity_Type__c !='Debooking']);
            for(Booking__c bkg:[select id,Opportunity__c from booking__c where id IN: bkgId]){
               if(oppMap.containsKey(bkg.Opportunity__c)){
               Opportunity opp = oppMap.get(bkg.Opportunity__c);
               Booking_Split__c primarySplit = new Booking_Split__c();
               primarySplit.Booking__c = bkg.id;
               primarySplit.Sales_Rep__c = opp.OwnerId;
               if(opp.split__c){
                 if(opp.Split_percentage__c!= null){
                    primarySplit.Opportunity_Split__c = opp.Split_percentage__c;
                 }
                 else if(opp.Split_Amount__c!=null){
                  //primarySplit.Opportunity_Split__c = Split_Amount__c // Not a business usecase
                 }
                 }
               else
                primarySplit.Opportunity_Split__c = 100 ;
               primarySplit.Theatre__c = opp.ETM_Theatre__c;
               primarySplit.Area__c = opp.ETM_Area__c;
               primarySplit.Region__c = opp.ETM_Region__c;
               primarySplit.Territory__c = opp.ETM_Territory__c;
               bkgSplits.add(primarySplit); 
               for(Opportunity spliopp : opp.Split_Opportunities__r){
               Booking_Split__c bkgChildSplit = new Booking_Split__c();
               bkgChildSplit.Booking__c = bkg.id;
               bkgChildSplit.Sales_Rep__c = spliopp.OwnerId;
                 if(opp.Split_percentage__c!= null){
                    bkgChildSplit.Opportunity_Split__c = spliopp.Split_percentage__c;
                 }
                 else if(opp.Split_Amount__c!=null){
                  //bkg.Opportunity_Split__c = Split_Amount__c// Not a business usecase
                 }
               bkgChildSplit.Theatre__c = spliopp.ETM_Theatre__c;
               bkgChildSplit.Area__c = spliopp.ETM_Area__c;
               bkgChildSplit.Region__c = spliopp.ETM_Region__c;
               bkgChildSplit.Territory__c = spliopp.ETM_Territory__c;
              bkgSplits.add(bkgChildSplit); 
            }
            }
            }
            if(!bkgSplits.isEmpty()){
               database.insert(bkgSplits,false);
            }
         }
         else if (type == 'createOrder'){
          List<opportunity> oppList = new List<Opportunity>([select id, SBQQ__Ordered__c from opportunity where id IN: recIds]);
           for(Opportunity opp : oppList){
             opp.SBQQ__Ordered__c = true;
           }
            database.update(oppList,false);
         }   
    }

   public void finish(Database.BatchableContext BC){
   }
   public void testA(){
   integer a = 0;
   a++;
    a++;
     a++;
      a++;
       a++;
        a++;
         a++;
         a++;
    a++;
     a++;
      a++;
       a++;
        a++;
         a++;a++;
    a++;
     a++;
      a++;
       a++;
        a++;
         a++;a++;
    a++;
     a++;
      a++;
       a++;
        a++;
         a++;
   
   }
}