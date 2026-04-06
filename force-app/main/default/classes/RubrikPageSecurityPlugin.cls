global class RubrikPageSecurityPlugin implements SBQQ.PageSecurityPlugin2 {
    public Boolean isFieldEditable(String pageName, Schema.SObjectField field) {
        return null;
    }
    
    public Boolean isFieldEditable(String pageName, Schema.SObjectField field, SObject record) {
        if ((pageName == 'EditLines') && (record instanceof SBQQ__QuoteLine__c)) {
            SBQQ__QuoteLine__c line = (SBQQ__QuoteLine__c) record;
            if ((String.isBlank(line.SBQQ__SubscriptionPricing__c )) && (field.getDescribe().getName() == 'SBQQ__SubscriptionTerm__c')) {
                return false;
            }
        }
        return null;
    }
    
    public Boolean isFieldVisible(String pageName, Schema.SObjectField field) {
        return null;
    }
    
    public Boolean isFieldVisible(String pageName, Schema.SObjectField field, SObject record) {
        return null;
    }
}