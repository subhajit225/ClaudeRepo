/**
 * Anonymous Apex script to insert a Product2 record for RA-TRN-VTL-PP.
 * Skip any field that causes a compile error in the target org.
 */
Product2 prod = new Product2();
prod.Name = 'RA-TRN-VTL-PP';
prod.ProductCode = 'RA-TRN-VTL-PP';
prod.IsActive = true;
prod.Description = 'Public Rubrik Security Cloud Administration - 4 Day Virtual Bootcamp is one person / per seat / pre-paid. For customers with on-premise workloads like VMs, Filesets, Databases. 12-month expiration from time of purchase. UCL/SaaS/Ransomware courses use SKU RA-TRN-PP. For questions contact rubriku@rubrik.com.sandbox.sandbox.';
prod.SBQQ__DefaultQuantity__c = 1.00;
prod.Category__c = 'Support';
prod.Product_Type__c = 'Training';
prod.Product_Level__c = 'Addon';
prod.Item_Type__c = 'Non-inventory Item';
prod.Availability__c = 'GA';
// prod.Cost_Group__c = 'Training Costs'; // Field does not exist in org
prod.Availability_Stage__c = 'All Transactions';
prod.Searchable__c = 'Yes';
// prod.Quotable_Start_Date__c = Date.newInstance(2023, 12, 18); // Field does not exist in org
prod.Allow_PSO_Task_Creation__c = true;
prod.Is_Available_For_Amendment__c = true;
// prod.Member_of_Bundle_Editions__c = 'Scale Utility'; // Field does not exist in org
prod.Sales_Comp_Category__c = 'TRAINING';
prod.SalesCompCategoryChangedDate__c = DateTime.newInstance(2023, 12, 17, 22, 15, 0);
prod.Replacement_Category__c = 'Not Replaceable';
// prod.Product_Pillar_1__c = 'Enterprise Data Protection'; // Field does not exist in org
prod.Welcome_Letter_Content__c = 'https://rubrik.docebosaas.com/customers/pages/54/instructor-led-training';
prod.Is_MSP_Product__c = false;
// prod.SBQQ__MinimumQuantity__c = 1.00; // Field does not exist in org

Database.SaveResult sr = Database.insert(prod, false);
if (sr.isSuccess()) {
    System.debug('Product2 inserted successfully. Id: ' + sr.getId());
} else {
    for (Database.Error err : sr.getErrors()) {
        System.debug('Error: ' + err.getStatusCode() + ' - ' + err.getMessage());
        System.debug('Fields affected: ' + err.getFields());
    }
}
