public with sharing class WorkloadAttribute extends HeatMapAttribute{
    @AuraEnabled
    public Decimal automatedObjCount{get;set;}
    @AuraEnabled
    public Decimal manualObjCount{get;set;}
    @AuraEnabled
    public Decimal automatedObjCapacity{get;set;}
    @AuraEnabled
    public Decimal manualObjCapacity{get;set;}
    @AuraEnabled
    public String manualIncumbent{get;set;}
    @AuraEnabled
    public String automatedWorkloadVal{get;set;}
    @AuraEnabled
    public String manualWorkloadVal{get;set;}
    @AuraEnabled
    public String licenseOverride{get;set;} //MKT26-1106

    public WorkloadAttribute() {
        super();
    }
    public WorkloadAttribute(HeatMap_Entry__c entry) {
        super(entry);
        value = entry.Final_Workload_Value__c;
        automatedObjCount = entry.Automated_Object_Count__c;
        manualObjCount = entry.Manual_Object_Count__c;
        manualWorkloadVal = entry.Manual_Workload_Value__c;
        automatedWorkloadVal = entry.Automated_Value__c;
        manualObjCapacity = entry.Manual_Object_Capacity__c;
        automatedObjCapacity = entry.Automated_Object_Capacity__c;
        manualIncumbent = entry.Manual_Incumbent__c;
        licenseOverride = entry.Cell_Highlight_Override__c; //MKT26-1106
    }
}