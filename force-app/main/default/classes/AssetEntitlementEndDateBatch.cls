public class AssetEntitlementEndDateBatch implements Database.Batchable<SObject>, Database.Stateful{
    public Map<Id,DataWrapper> latestEndDateEntitlement = new Map<Id,DataWrapper>();
    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([SELECT Id,Name, AssetId, EndDate, Asset.Premium_Support_End_Date__c, 
            Asset.Name, Account.Name, Order_Service_Item__r.Order.OrderNumber 
            FROM Entitlement WHERE assetId != null AND endDate != null and Asset.Status in ('Purchased', 'Dispatched') ORDER BY AssetId, endDate desc]);

    }

    public void execute(Database.BatchableContext BC, List<Entitlement> entitlementsScope){
        for(Entitlement enttlmnt : entitlementsScope){
            if(!latestEndDateEntitlement.containsKey(enttlmnt.assetId)){
                latestEndDateEntitlement.put(enttlmnt.assetId,new DataWrapper(enttlmnt.endDate,enttlmnt.asset.Premium_Support_End_Date__c,enttlmnt.Asset.Name,enttlmnt.Account.Name, enttlmnt.Order_Service_Item__r.Order.OrderNumber,enttlmnt.Id,enttlmnt.Name));
                
            }
        }
    }

    public void finish(Database.BatchableContext BC){
        String finalCsv = formCsv();
        System.debug('-----finalCsv------'+finalCsv);
        sendEmail(finalCsv);

    }

    public String formCsv(){
        String headers = 'AssetId,SerialNumber,Account Name,Order Number,Asset URL,Asset End Date, Entitlement End Date,EntitlementId,Entitlement Name\n';
        String finalCsv = headers;
        for(Id asstId : latestEndDateEntitlement.keySet()){
            DataWrapper dataInst = latestEndDateEntitlement.remove(asstId);
            if((dataInst.earliestEntitlementEndDate == null && dataInst.assetEndDate == null) || (dataInst.earliestEntitlementEndDate != dataInst.assetEndDate) ){
                finalCsv += asstId+','+
                            '"'+dataInst.serialNumber+'"'+','+
                            '"'+dataInst.accountName+'"'+','+
                            '"'+dataInst.orderNumber+'"'+','+
                            '"'+URL.getSalesforceBaseUrl().toExternalForm() + '/' + asstId+'"'+','+
                            '"'+dataInst.assetEndDate+'"'+','+
                            '"'+ dataInst.earliestEntitlementEndDate+'"'+','+
                            '"'+ dataInst.EntitlementId+'"'+','+
                            '"'+ dataInst.EntitlementName+'"'+
                            '\n';
            }
        }
        if(headers == finalCsv){
            finalCsv = 'No Mismatched assets found!!!';
        }
        return finalCsv;
    }

    public void sendEmail(String finalCsv){
        String[] toAddresses = new List<String>();
        for(AssetEntitlementMismatchEmail__mdt mdtRec : [SELECT Id,Email_Address__c,Is_Active__c
                                                         FROM AssetEntitlementMismatchEmail__mdt
                                                         WHERE Is_Active__c = true]){
            toAddresses.add(mdtRec.Email_Address__c);
        }
        if(toAddresses.isEmpty() == false){
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            Blob csvBlob = Blob.valueOf(finalCsv);
            String csvname= 'Mismatched End date Assets.csv';
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
    
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            email.setSubject(System.Label.Asset_Entitlement_end_date_mismatch_report_Email_subject);
            email.setToAddresses(toAddresses);
            email.setPlainTextBody(System.Label.Asset_Entitlement_end_date_mismatch_report_Email_subject);
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] emailRes = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
    }


    private class DataWrapper{
        public Datetime earliestEntitlementEndDate;
        public DateTime assetEndDate;
        public String serialNumber;
        public String accountName;
        public String orderNumber;
        public Id EntitlementId;
        public String EntitlementName;
        public DataWrapper(Datetime earliestEntitlementEndDate,DateTime assetEndDate,String serialNumber, String accountName, String orderNumber,Id EntitlementId,String EntitlementName){
            this.earliestEntitlementEndDate = earliestEntitlementEndDate;
            this.assetEndDate = assetEndDate;
            this.serialNumber = serialNumber;
            this.accountName = accountName;
            this.orderNumber = orderNumber;
            this.EntitlementId = EntitlementId;
            this.EntitlementName = EntitlementName;
        }
    }


}