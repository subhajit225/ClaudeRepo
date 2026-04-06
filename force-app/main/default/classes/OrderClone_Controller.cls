public class OrderClone_Controller {
    @AuraEnabled
    public static response_Wrapper createClonedRecord(String parentId){
        response_Wrapper response = new response_Wrapper();
        string message = '';
        List<Schema.FieldSetMember> fieldsetValues =  Schema.SObjectType.Order.FieldSets.OrderFieldSet.getFields();
        String query = 'SELECT ';
		for(Schema.FieldSetMember f : fieldsetValues) {
			query += f.getFieldPath() + ', ';
		}
		query += 'Id, SBQQ__Quote__c, AccountId, OpportunityId, SBQQ__Quote__r.SBQQ__Type__c, Rubrik_Forward_Mail__c, Bill_To_Name__c,Payment_Terms__c, Primary_Competitor__c, ShippingStreet,ShippingCity,ShippingCountry,ShippingPostalCode,ShippingState, '+
					'Is_CPQ_Price_Book__c, SBQQ__ContractingMethod__c, Auto_Manual_Split__c, SBQQ__PaymentTerm__c, BillingAddress, ShippingAddress, ShipToContactId, ShipToContactName__c, BillingStreet,BillingCity,BillingCountry,BillingPostalCode,BillingState,'+
					'Pricebook2Id, Distributor_Email__c, Ship_to_Email__c, Ship_To_Phone_Number__c, Is_RWD_Polaris_Quote__c, Overage_PO__c, Shipping_Carrier__c, '+
					'Shipping_Account_Number__c, Discounted_Units_due_to_CSAT_or_Sizing__c, Ship_To_Name__c, Shipping_Method__c, Service_Level__c, Service_Type__c, AddOn_Node_Count__c,Revised_By__c,Booked_By__c FROM Order WHERE Id =: parentId';
        
        Order oldRecord = Database.query(query);
        Order newRecord = oldRecord.clone(false, false, false, false);
        newRecord.Auto_Manual_Split__c = 'Manual';            
        newRecord.Reason_For_Split__c = null;
        newRecord.EffectiveDate = system.today();
        Order oldObjOrder;
        
       if(String.isBlank(oldRecord.Auto_Manual_Split__c)){
        
            oldObjOrder = new Order(Id = oldRecord.Id, Auto_Manual_Split__c = 'System Generated');
        }
         try{
           insert newRecord;
             if(oldObjOrder != null){
             	update oldObjOrder;
             }
               response.ord = newRecord;
               response.newOrderId = newRecord.id;

        }catch(Exception e){
             response.isSuccess = false;
            response.errorMessage = e.getDmlMessage(0);
           
        }
        return response;
    } 
    
    
     public class response_Wrapper {
        @auraEnabled public List<Contact> contactRecords{get;set;}
        @auraEnabled public Order ord{get;set;} 
        @auraEnabled public boolean isSuccess{get;set;}
        @auraEnabled public string errorMessage  {get;set;}
        @auraEnabled public String newOrderId  {get;set;}
        
        public response_Wrapper(){
            this.isSuccess = true;
            this.newOrderId = '';
            this.errorMessage = '';
            this.ord = new Order();
            
        }
        
    }

}