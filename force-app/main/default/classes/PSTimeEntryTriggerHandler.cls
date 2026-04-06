public class PSTimeEntryTriggerHandler extends TriggerHandler {
    
    private Boolean isDisabled = false;
   
    public PSTimeEntryTriggerHandler () {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
    }
    
    public override void beforeInsert() {
        if(!isDisabled) {
            Set<Id> taskIds = new Set<Id>();
            for (SObject record : Trigger.new) {
                PS_Time_Entry__c timeEntry = (PS_Time_Entry__c) record;
                if (timeEntry.PS_Task__c != null) {
                    taskIds.add(timeEntry.PS_Task__c);
                }
            }
            Map<Id, PS_Task__c> taskMap = new Map<Id, PS_Task__c>([SELECT Id, Name, Project__c, Project__r.Name FROM PS_Task__c WHERE Id IN :taskIds]);
            
             for(Sobject pst : Trigger.New){
                PS_Time_Entry__c pstrecord = (PS_Time_Entry__c) pst;
                 if(pstrecord.Project_Type__c =='Internal' && taskMap.get(pstrecord.PS_Task__c).Project__r.Name != 'ADMIN'){
                     pstrecord.Status__c ='Approved';
                     pstrecord.PS_Time_Entry_Approved_Date__c = System.now();
                 } 
                 pstrecord.Billable__c = pstrecord.Is_Billable__c;
                 pstrecord.TaskType__c = pstrecord.Task__c;   
                 if(pstrecord.TaskType__c.contains('Resident Engineer-PD')){
                     pstrecord.Billable__c =true;
                 }
                 if(pstrecord.Status__c =='Approved')   
                     pstrecord.PS_Time_Entry_Approved_Date__c = System.now();         
             }
            System.debug('BeforeInsert Called');
             projectSubTasksController.createOrUpdateTimeCard(Trigger.New);
        }
    }
    
    public override void beforeUpdate() {
        if(!isDisabled) {
            Set<Id> taskIds = new Set<Id>();
            for (SObject record : Trigger.new) {
                PS_Time_Entry__c timeEntry = (PS_Time_Entry__c) record;
                if (timeEntry.PS_Task__c != null) {
                    taskIds.add(timeEntry.PS_Task__c);
                }
            }
            Map<Id, PS_Task__c> taskMap = new Map<Id, PS_Task__c>([SELECT Id, Name, Project__c, Project__r.Name FROM PS_Task__c WHERE Id IN :taskIds]);
            
            for(Sobject pst : Trigger.New){
                PS_Time_Entry__c pstrecord = (PS_Time_Entry__c)pst;
                if(pstrecord.Project_Type__c =='Internal' && taskMap.get(pstrecord.PS_Task__c).Project__r.Name != 'ADMIN'){
                     pstrecord.Status__c ='Approved';
                     pstrecord.PS_Time_Entry_Approved_Date__c = System.now();
                }
                pstrecord.Billable__c = pstrecord.Is_Billable__c;
                pstrecord.TaskType__c    = pstrecord.Task__c ;
                PS_Time_Entry__C oldpte = (PS_Time_Entry__c)Trigger.OldMap.get(pstrecord.id);
                if(pstrecord.Hours_Spent__c != oldpte.Hours_Spent__c && pstrecord.Status__C !='Pending') {
                    pstrecord.Status__c ='Draft';
                }
                 
                if(pstrecord.Status__c =='Approved')   
                     pstrecord.PS_Time_Entry_Approved_Date__c = System.now();    
                else
                     pstrecord.PS_Time_Entry_Approved_Date__c = null;    
                     System.debug('in here' + pstrecord.TaskType__c );
                 if(pstrecord.TaskType__c.contains('Resident Engineer-PD')){
                     pstrecord.Billable__c =true;
                 }
                 system.debug('in here' + pstrecord.Billable__c );
             }
            System.debug('BeforeUpdate Called');
             projectSubTasksController.createOrUpdateTimeCard(Trigger.New);
        }
        
    }
    
    public override void afterInsert() {
        if(!isDisabled) {
            System.debug('AfterInsert Called');
            projectSubTasksController.calculateTimeCardHours(Trigger.New, null);
        }
    }
    
    public override void afterUpdate() {
        if(!isDisabled) {
            System.debug('AfterUpdate Called');
            projectSubTasksController.calculateTimeCardHours(Trigger.New, Trigger.oldMap);   
        }
    }
    
     public override void BeforeDelete() {
        if(!isDisabled) {
        if(Trigger.isbefore && Trigger.isdelete){
            projectSubTasksController.calculateTimeCardHoursDelete(Trigger.old);   
        
        }
        }
    }
    
}