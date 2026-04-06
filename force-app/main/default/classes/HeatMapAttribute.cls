public abstract with sharing class HeatMapAttribute {
    @AuraEnabled
    public Id accountId{get; set;}
    @AuraEnabled
    public String accountName{get; set;}
    @AuraEnabled
    public String accountType{get; set;}
    @AuraEnabled
    public String value;
    @AuraEnabled
    public String backgroundColour;
    /*@AuraEnabled
    public Boolean showModal{get;private set;}*/ //TODO: decide if this should be here or in the column only
    @AuraEnabled
    public Boolean readOnly{get; set;}
    @AuraEnabled
    public Id columnId{get;set;} //to map it with the corresponding column
    @AuraEnabled
    public String columnName{get;set;}
    @AuraEnabled
    public String columnType{get; set;}
    @AuraEnabled
    public String heatMapEntryId{get;private set;} //to map it with the corresponding entry
    @AuraEnabled
    public String columnFilter{get; set;}
    @AuraEnabled
    public Boolean columnClickable{get; set;}
    @AuraEnabled
    public String columnAlignment{get; set;}

    public HeatMapAttribute() {
    }

    public HeatMapAttribute(HeatMap_Entry__c entry) {
        //initialize with params
        heatMapEntryId = entry.Id;
        accountId = entry.Account__c;
        accountName = entry.Account__r.Name;
        columnId = entry.HeatMap_Column__c;
        columnName = entry.HeatMap_Column__r.Name;
        columnFilter = entry.HeatMap_Column__r.Column_Filter__c;
        columnClickable = false;
    }
}