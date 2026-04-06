public class DealRegDetail{
    public Deal_Registration__c vDealReg {get;set;}
    public DealRegDetail(ApexPages.StandardController controller) {
        Id dealRegId =apexpages.currentpage().getparameters().get('id');

    vDealReg = [select Alliance_Partner_Name__c, Authority__c, Budget__c, CDM__c, 
                    City__c, Company__c, Country__c, Current_Backup_Vendor__c, Current_Storage_Vendor__c, 
                    Customer_Category__c, dataComJson__c, Deal_Reg_Submitted_Date__c, Deal_Registration_Status__c, 
                    Deal_Registration_Type__c, Distributor_Company_Name__c, Distributor_Rep_Email__c, 
                    Distributor_Rep_Name__c, Distributor_Rep_Phone_Number__c, Email__c, 
                    FirstName__c, Id, LastName__c, 
                    Lead__c, Lead_Source__c, Lead_Source_Details__c, Matching_Deal_Registration__c, 
                    Name, Need__c, Number_of_protected_machines__c, Partner__c, Partner_Lookup__c, Partner_Rep__c, 
                    Partner_Rep_Email_Address__c, Partner_Rep_Phone_Number__c, Partner_Rep_Title__c, Partner_SE_Email__c, 
                    Partner_SE_Name__c, Partner_SE_Phone__c, PatchManager__c, Phone__c, PostalCode__c, Purchase_Timeframe__c, 
                    Secondary_Email_for_Deal_Reg__c, Segment_Revenue__c, StateCode__c, 
                    Street__c, Title__c, Deal_Registration_Expiration__c, Partner_Lookup__r.name, Distributor__r.Name, Distributor_Secondary_Email_Address__c
                        from Deal_Registration__c where Id=:dealRegId and createdById =: UserInfo.getUserID()]; //set the total size in the constructor
   
    
    }

}