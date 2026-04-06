public class Add_PSOLineItemsExtn {

    public List<PSO_Time_Entry__c> lineItems {get; set;}
    private PSO__c pso;
    public Integer totalCommitedDays {get;set;}
    public Integer totalNumberOfDays {get;set;}
    public Add_PSOLineItemsExtn (ApexPages.StandardController myController) {
        totalNumberOfDays = 0;
        pso=(PSO__c)myController.getrecord();
        pso =[select id, Days_ordered__c from PSO__c where id=:pso.id];
        totalCommitedDays = (Integer)pso.Days_ordered__c;
        lineItems = new List<PSO_Time_Entry__c>();
        PSO_Time_Entry__c pItem = new PSO_Time_Entry__c();
        pItem.PSO_Lookup__c = pso.id;
        lineItems.add(pItem);
        //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Total number of completed dates should not exceed total number of committed(ordered) days[Total Committed days:'+pso.Total_Days_Committed__c+']'));
    }

    public void addrow() {
        PSO_Time_Entry__c lItem = new PSO_Time_Entry__c();
        lItem.PSO_Lookup__c = pso.id;
        lineItems.add(lItem);}
            
    public void removerow(){
        Integer i = lineItems.size();
        lineItems.remove(i-1);}
    public PageReference calculateNumber(){
        system.debug(lineItems);
        totalNumberOfDays= 0;
        for(PSO_Time_Entry__c line : lineItems){
            system.debug(line);
            line.NumberofDays__c = line.start_Date__c.daysBetween(line.End_Date__c)+1;
            system.debug('NumberofDays__c=='+line.NumberofDays__c);
            totalNumberOfDays += Integer.valueOf(line.NumberofDays__c);
        }
        system.debug('totalNumberOfDays=='+totalNumberOfDays);
        return null;
    }
            
    public PageReference save() {
        calculateNumber();
        insert lineItems;
        //PageReference home = new PageReference('/'+pso.Id);
        //home.setRedirect(true);
        return null; }
     
        }