global class AssetCountUnderAccountBatch implements Database.Batchable<SObject> 
{
    global String timestamp;
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        timestamp = String.Valueof(datetime.now());
        // Getting child records (Contact)
        String CLONStr ='%CLON%';
        String CLOUTStr ='%CLOUT%';
        string CLON  = '\'' + CLONstr + '\' ';
        string CLOUT  = '\'' + CLOUTStr + '\' ';
        string filter = 'product2.Name LIKE '+ System.Label.ApplianceAssetFilterString;
        string filterCLON = 'Name LIKE '+CLON;
        string filterCLOUT = 'Name LIKE '+CLOUT;
        Date today = System.TODAY();
        //String query ='Select id, Number_of_Appliances__c,NumberofCLONs__c,NumberofCLOUTs__c, (SELECT id FROM Assets where '+filter+'),(select id,name,status from entitlements where '+filterCLON+' OR '+filterCLOUT +')   from Account' + (Test.isRunningTest()?' LIMIT 5':'');
        String query ='Select id, Number_of_Appliances__c,NumberofCLONs__c,NumberofCLOUTs__c, (SELECT id,Product2.name FROM Assets),(select id,name,status from entitlements) from Account' + (Test.isRunningTest()?' LIMIT 5':'');
        
        system.debug(query);
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope )
    {   
        String relatedAccountId;
        List<Account> accUpdateList = new List<Account>();
        try{
        system.debug ('>>>>> Scope Size >>>>>' + scope.size());

        for(Account acc : scope)
        {
            relatedAccountId = acc.id;
            if(acc.Assets != null)
            {
                system.debug ('>>>>> Scope Contact size Size >>>>>' + acc.Assets.size());
                Integer numberofAppliance =0;
                for(Asset asset : acc.Assets){
                    if(asset.Product2.Name.Startswith('RBK-R')){
                        numberofAppliance = numberofAppliance+1;
                    }
                }
                acc.Number_of_Appliances__c = numberofAppliance;
                //accUpdateList.add(acc);
                
            }
            if(acc.Entitlements != null)
            {
                Integer numberofCLON =0;
                Integer numberofCLOUT =0;
                system.debug ('>>>>> Scope Contact size Size >>>>>' + acc.Entitlements.size());
                for(Entitlement ent : acc.Entitlements){
                system.debug('ent status =='+ent.status);
                    if(ent.Name.contains('CLON') && ent.status !='Expired'){
                        numberofCLON =numberofCLON+1;
                    }
                    else if(ent.Name.contains('CLOUT') && ent.status !='Expired'){
                        numberofCLOUT =numberofCLOUT+1;
                    }
                    
                    acc.NumberofCLONs__c = numberofCLON;
                    acc.NumberofCLOUTs__c = numberofCLOUT;
                    
                }
            }
            accUpdateList.add(acc);
        }
        if(!accUpdateList.isEmpty())
            Database.update(accUpdateList,false);
        }
        catch(Exception ex){
        system.debug('Excpetion in AssetCountUnderAccountBatch Method'+ex);
        EntitlementToSCHelperClass.createErrorRecord(ex.getMessage(),'AssetCountUnderAccountBatch','AssetCountUnderAccountBatch', ex.getTypeName(), ex.getLineNumber(),relatedAccountId,null,timestamp,'');
                
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        
    }
}