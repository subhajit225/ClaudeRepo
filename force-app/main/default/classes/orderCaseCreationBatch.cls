public class orderCaseCreationBatch implements Database.Batchable<sObject>, Schedulable,Database.AllowsCallouts{


    public void execute(SchedulableContext sc) {
        Database.executeBatch(new orderCaseCreationBatch());
    }
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            'Select OrderId,Product2.Name from OrderItem where (Product2.Name=\'RBK-SVC-CMPLT-RMOT\' OR Product2.Name=\'RA-SVC-CE-RMOT\') AND Order.Order_Status__c = \'Shipped\' AND Order.ActivatedDate = LAST_N_DAYS:3 AND Order.Type = \'Revenue\''
        );
    }
    public void execute(Database.BatchableContext bc, List<OrderItem> odrList){
        Id queId = [Select Id from Group where Name = 'Open Queue (Digital)' and Type = 'Queue'].Id;
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Support Case').getRecordTypeId();
        List<Case> csList = new List<Case>();
        //List<Id> orderIds = new List<Id>();
        Map<Id,String> productName = new Map<Id,String>();
        for(OrderItem od: odrList){
            //orderIds.add(od.OrderId);
            productName.put(od.OrderId,od.Product2.Name);
        }
        String jsonString = '{"resultsPerPage":'+Label.SuggestionLabel+',"aggregations":[{"filter":["how_to__kav"],"type":"_type"},{"filter":["true"],"type":"IsVisibleInPkb"}],"pageNo":1,"orderBy":"desc","sortby":"_score","from":0,"searchString":"'+Label.RBK_SVC_CMPLT_RMOT_Subject+'"}';
        Map<String, Object> suggestionList = SearchUnifyEndpoint.SearchResults(jsonString);
        for(Order od:[Select AccountId, ActivatedDate, Welcome_Letter_Contact__c, OrderNumber,(Select Id from Cases__r) from Order where Id IN:productName.keySet()]){
            if(od.Cases__r.isEmpty()){
                Case cs = new Case();
                cs.RecordTypeId = recordTypeId;
                cs.order__c = od.Id;
                cs.AccountId = od.AccountId;
                cs.ContactId = od.Welcome_Letter_Contact__c;
                cs.OwnerId = queId;
                cs.Origin = 'Proactive-campaign';
                cs.Proactive_customer_campaign_type__c = 'Complete Edition remote installation service';
                cs.Priority = 'P3 - Medium';
                cs.Subject = Label.RBK_SVC_CMPLT_RMOT_Subject.replace('RBK-SVC-CMPLT-RMOT',productName.get(od.Id)).replace('<<order_number>>',od.OrderNumber);
                cs.Current_Status__c = Label.RBK_SVC_CMPLT_RMOT_Current_Status.replace('RBK-SVC-CMPLT-RMOT',productName.get(od.Id));
                cs.Next_Step__c = Label.RBK_SVC_CMPLT_RMOT_Next_Steps;
                cs.Platform__c = 'CDM';
                cs.Product_Area__c = 'Cluster';
                cs.Problem_Type__c = 'Complete Edition';
                cs.Sub_Component__c = 'Install';
                cs.Resolution__c = 'Configuration Assistance';
                cs.Description = Label.RBK_SVC_CMPLT_RMOT_Description.replace('RBK-SVC-CMPLT-RMOT',productName.get(od.Id));
                if(DateTime.now().format('E') != 'Mon' && od.ActivatedDate.Date() == System.today().addDays(-1) || Test.isRunningTest()){
                    CaseTriggerHandler.isRepeat = false;
                    csList.add(cs);
                }
                else if(od.ActivatedDate.Date() == System.today() || od.ActivatedDate.Date() == System.today().addDays(-2) || od.ActivatedDate.Date() == System.today().addDays(-3) || Test.isRunningTest()){
                    CaseTriggerHandler.isRepeat = false;
                    csList.add(cs);
                }
            }
        }
        if(!csList.isEmpty()){
            Database.insert(csList, false);
            List<CaseComment> cscom = new List<CaseComment>();
            Map<Id, Case> cases = new Map<Id, Case>([SELECT Id, Account.Name, AccountId, Order__c, Order__r.OrderNumber FROM Case WHERE Id IN:csList]);

            AccountTerritoryUsersToCaseTeamHelper.insertCtmOnCaseCreateUpdate(cases.keySet());
            for(Case cs: cases.values()){
                CaseTriggerHandler.caseSuggestionMap.put(cs.id,(JSON.serialize(suggestionList)));
                cs.Welcome_Email_Sent__c = true;
                CaseComment com = new CaseComment();
                com.ParentId = cs.ID;
                String body = Label.RBK_SVC_CMPLT_RMOT_Comment.replace('<<account_name>>',cs.Account.Name).replace('RBK-SVC-CMPLT-RMOT',productName.get(cs.Order__c));
                body = body.replace('<<number>>', cs.Order__r.OrderNumber);
                body = body.replace('<<link to the order>>', System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+cs.Order__c);
                com.CommentBody = body;
                cscom.add(com);
            }
            Database.insert(cscom, false);
            Database.update(cases.values(), false);
        }
    }
    public void finish(Database.BatchableContext bc){}
}