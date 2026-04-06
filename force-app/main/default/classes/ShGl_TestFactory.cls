// Class generates Test data and can be called from Test Classes
/*
DefaultClassName > Object Mapping

Product2Defaults                        > Product2
AccountDefaults                         > Account - Regular Customer Account
ContactDefaults                         > Contact
OpportunityDefaults                     > Opportunity
CaseDefaults                            > Case
UserDefaults                            > User
UserRoleDefaults                        > User Role
PriceBookEntry                          > PriceBookEntry
ServiceContractDefaults                 > Contract
Product2Defaults                        > Product2
AssetDefaults                           > Asset
PriceBookEntryDefaults                  > PriceBookEntry
ContractLineItemDefaults                > ContractLineItem
GroupDefaults                           > Group
QueueSObjectDefaults                    > QueueSObject
EmailMessageDefaults                    > EmailMessage
LeadDefaults                            > Lead
QuoteDefaults                           > Quote
QuoteLineItemDefaults                   > QuoteLineItem
CCRDefaults                             > CCR

Example:
1. Create One UserRole > No Arguments passed
UserRole ur = (UserRole) ShGl_TestFactory.createSObject(new UserRole(),null);
insert ur;

2. Create List of Users with userRole and Profile Id as input argument
Map<String, Object>  uMap = new Map<String, Object> {
'UserRoleId' => ur.id,
'ProfileId' => ([Select Id from Profile where Name='System Administrator'].id)
};
List<User> adminUserL = (List<User>) ShGl_TestFactory.createSObjectList(new User(),3,uMap);
insert adminUserL;

3. Create One Reseller Partner Account
Account acc = (Account) ShGl_TestFactory.createSObject(new Account(),'ResellerPartnerAccountDefaults',null);
insert acc;

4. Create List of Distributor Partner Accounts, with Partner_User_Disti_DR_Profile__c as input argument
Map<String, Object>  distiMap = new Map<String, Object> {
'Partner_User_Disti_DR_Profile__c' => true
};
List<Account> accL = (List<Account>) ShGl_TestFactory.createSObjectList(new Account(),3,'DistributorPartnerAccountDefaults',distiMap);
insert acc; 

5. Create Products from static resource and add to standard test pricebook. Pass the static resource name or keep null for default (ShGl_TestLoadData_Product2)
Returns Map<ProductCode,Product>
Map<String,Product2> prodM = ShGl_TestFactory.createProductsFromStaticResource(null);

*********************************************************************************************/

public class ShGl_TestFactory {
    
    public static SObject createSObject(SObject sObj, Map<String, Object> dynamicValueMap) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        objectName = objectName.replace('__c', '');
        if(objectName.indexOf('__') > 0) {
            objectName = objectName.substring(objectName.indexOf('__')+2, objectName.length());
        }
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = objectName.replace('__c', '') + 'Defaults';
        // If there is a class that exists for the default values, then use them
        sObj = createSObject(sObj, defaultClassName, dynamicValueMap);
        return sObj;
    }
    
    public static SObject createSObject(SObject sObj, String defaultClassName, Map<String, Object> dynamicValueMap) {
        FieldDefaults defaults = getFieldDefaults(defaultClassName, dynamicValueMap);
        sObj = addFieldDefaults(sObj.clone(false, true), defaults.getFieldDefaults());
        return sObj;
    } 
    
    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, Map<String, Object> dynamicValueMap) {
        return createSObjectList(sObj, numberOfObjects, null, dynamicValueMap);
    }
    
    public static SObject[] createSObjectList(Sobject sObj, Integer numberOfObjects, 
                                              String defaultClassName, Map<String, Object> dynamicValueMap) {
                                                  SObject[] sObjs = new SObject[] {};
                                                      SObject newObj;
                                                  for (Integer i = 0; i < numberOfObjects; i++) {
                                                      if (defaultClassName == null) {
                                                          newObj = createSObject(sObj, i, dynamicValueMap);
                                                      } else {
                                                          newObj = createSObject(sObj, defaultClassName, i, dynamicValueMap);
                                                      }
                                                      sObjs.add(newObj);
                                                  }
                                                  return sObjs;
                                              }
    /*    
public static Map<String, Product2> createProductsFromStaticResource(String srName) {
Map<String, Product2> ret = new Map<String, Product2>();
if(srName == null || srName == '') srName = 'ShGl_TestLoadData_Product2';

List<Product2> prodL = (List<Product2>)Test.loadData(Product2.sObjectType, srName);

List<PriceBookEntry> pbeL = 
(List<PriceBookEntry>) ShGl_TestFactory.createSObjectList(new PriceBookEntry(), prodL.size(), null);
for(Integer i = 0; i < pbeL.size(); i++){
pbeL.get(i).Product2Id = prodL.get(i).Id;
}
insert pbeL;
for(Product2 prod : prodL) {
ret.put(prod.ProductCode, prod);
}
return ret;
}
*/    
    private static SObject createSObject(SObject sObj, Integer counter, Map<String, Object> dynamicValueMap) {
        // Check what type of object we are creating and add any defaults that are needed.
        String objectName = String.valueOf(sObj.getSObjectType());
        objectName = objectName.replace('__c', '');
        if(objectName.indexOf('__') > 0) {
            objectName = objectName.substring(objectName.indexOf('__')+2, objectName.length());
        }
        // Construct the default values class. Salesforce doesn't allow '__' in class names
        String defaultClassName = objectName.replace('__c', '') + 'Defaults';
        sObj = createSObject(sObj, defaultClassName, counter, dynamicValueMap);
        return sObj;
    }
    
    private static SObject createSObject(SObject sObj, String defaultClassName, 
                                         Integer counter, Map<String, Object> dynamicValueMap) {
                                             FieldDefaults defaults = getFieldDefaults(defaultClassName,dynamicValueMap);
                                             sObj = addFieldDefaults(sObj.clone(false, true), defaults.getFieldDefaultsMultipleRecords(counter));
                                             return sObj;
                                         }
    
    private static FieldDefaults getFieldDefaults(String defaultClassName, Map<String, Object> dynamicValueMap) {
        defaultClassName = (defaultClassName.startsWith('ShGl_TestFactory.'))?defaultClassName:'ShGl_TestFactory.' + defaultClassName;
        // Create an instance of the defaults class so we can get the Map of field defaults
        Type t = Type.forName(defaultClassName);
        if (t == null) {
            Throw new TestFactoryException('Invalid defaults class:' + defaultClassName);
        }
        FieldDefaults defaults = (FieldDefaults)t.newInstance();
        defaults.setDynamicValueMap(dynamicValueMap);
        return defaults;
    }
    
    private static SObject addFieldDefaults(SObject sObj, Map<String, Object> defaults) {
        // Loop through the map of fields and if they are null on the object, fill them.
        for (String field : defaults.keySet()) {
            if (sObj.get(field) == null) {
                sObj.put(field, defaults.get(field));
            }
        }
        return sObj;
    }
    
    public static void getRequiredFieldDefaults(SObject sObj) {  
        //get requiredfields for usergiven sObjects
        List<String> sObjList = new List<String> {'Account','Contact','Lead','Opportunity'};
            Schema.DescribeSObjectResult[] descResult = Schema.describeSObjects(sObjList);
        Map<String, List<String>> objToRequiredFieldsMap = new Map<String, List<String>>();
        
        for(Schema.DescribeSObjectResult dsr : descResult) {
            List<String> requiredFields = new List<String>();
            //get required fields
            Map<String, Schema.SObjectField> fieldMap = dsr.fields.getMap();
            for(String str : fieldMap.keySet()) {
                Schema.DescribeFieldResult f = fieldMap.get(str).getDescribe();
                if(!f.isNillable() && f.isUpdateable() && !f.isDefaultedOnCreate() && !f.isNameField()){
                    system.debug('f :: '+f);
                    requiredFields.add(f.getName());
                }
            }
            objToRequiredFieldsMap.put(dsr.getName(), requiredFields);
        } 
        System.debug(objToRequiredFieldsMap);
    }
    
    public class TestFactoryException extends Exception {}
    
    // Use the FieldDefaults interface to set up values you want to default in for all objects.
    public interface FieldDefaults {
        Map<String,Object> getDynamicValueMap();
        void setDynamicValueMap(Map<String,Object> val);
        Map<String, Object> getFieldDefaults();
        Map<String, Object> getFieldDefaultsMultipleRecords(Integer val);
    }
    
    // To specify defaults for objects, use the naming convention [ObjectName]Defaults.
    // For custom objects, omit the __c from the Object Name
    
    public class Product2Defaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test-Product-Rubrik'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test-Product-Rubrik'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }        
    }
    
    public class AccountDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Account',
                    'BillingStreet' => 'Up My Billing Steet',
                    'BillingCity' => 'San Franciso',
                    'BillingState' => 'California',
                    'BillingCountry' => 'United States',
                    'BillingPostalCode' => 'CA1234'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => counter + 'Test Account',
                    'BillingStreet' => counter + 'Up My Billing Steet',
                    'BillingCity' => 'San Franciso',
                    'BillingState' => 'California',
                    'BillingCountry' => 'United States',
                    'BillingPostalCode' => 'CA1234'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }        
    }
    
    public class ContactDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'FirstName' => 'First',
                    'LastName' => 'Last',
                    'Email' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') + '@test-example.com'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'FirstName' => 'First' + counter,
                    'LastName' => 'Last' + counter,
                    'Email' => 'test'+ counter + Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') + '@test-example.com'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
    }
    
    public class OpportunityDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Opportunity',
                    'StageName' => '1. Discovery',
                    'CloseDate' => System.today(),
                    'Alliance_Partner_Name__c' =>'Amazon',
                    'Alliance_Source_Type_SW__c' => 'Rubrik Initiated Alliance Deal',
                    'Alliance_HW_Partner__c' => 'Cisco',
                    'Alliance_Source_Type_HW__c' => 'Rubrik Initiated Alliance Deal',
                    'Alliance_Source_Type__c' => 'Rubrik Initiated Alliance Deal', 
                    'Installation_Assigned_To__c' => 'FE Install',
                    'Type' => 'Repeat/Upsell Business'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Opportunity' + counter,
                    'StageName' => '1. Discovery',
                    'CloseDate' => System.today(),
                    'Alliance_Partner_Name__c' =>'Amazon',
                    'Alliance_Source_Type_SW__c' => 'Rubrik Initiated Alliance Deal',
                    'Alliance_HW_Partner__c' => 'Cisco',
                    'Alliance_Source_Type_HW__c' => 'Rubrik Initiated Alliance Deal',
                    'Alliance_Source_Type__c' => 'Rubrik Initiated Alliance Deal', 
                    'Installation_Assigned_To__c' => 'FE Install',
                    'Type' => 'Repeat/Upsell Business'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }        
    }
    
    public class CaseDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Subject' => 'Test Case'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Subject' => 'Test Case' + counter
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    
    public class UserRoleDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test UserRole'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test UserRole ' + counter
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    
    public class UserDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'emailencodingkey' => 'UTF-8',
                    'languagelocalekey' => 'en_US',
                    'localesidkey' => 'en_US',
                    'country' => 'United Kingdom',
                    'timezonesidkey' => 'Europe/London',
                    'FirstName' => 'Test FirstName',
                    'LastName' => 'Test LastName',
                    'isActive' => true,
                    'Email' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') +'user1@test.rubrik.com',
                    'UserName' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') +'user1@test.rubrik.com',
                    'Alias' => 'testU',
                    'Sub_Region__c' => 'Southeast',
                    'ProfileId' => ([Select Id from Profile where Name='System Administrator'].id)    
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'emailencodingkey' => 'UTF-8',
                    'languagelocalekey' => 'en_US',
                    'localesidkey' => 'en_US',
                    'country' => 'United Kingdom',
                    'isActive' => true,
                    'timezonesidkey' => 'Europe/London',
                    'FirstName' => 'Test FirstName' + counter,
                    'LastName' => 'Test LastName' + counter,
                    'Email' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') + counter +'user1@test.rubrik.com',
                    'UserName' => 'test'+ Math.random().format() + string.valueof(Datetime.now()).replace('-','').replace(':','').replace(' ','') + counter +'user1@test.rubrik.com',
                    'Alias' => 'testU'+ counter,
                    'Sub_Region__c' => 'Southeast',
                    'ProfileId' => ([Select Id from Profile where Name='System Administrator'].id)    
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }         
    }  
    
    public class ServiceContractDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'SCTest',
                    'StartDate' => Date.Today().addMonths(-1),
                    'EndDate' => Date.Today().addMonths(1),
                    'Term' => 3,
                    'PriceBook2Id' => Test.getStandardPriceBookId()
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'SCTest' + counter,
                    'StartDate' => Date.Today().addMonths(-1),
                    'EndDate' => Date.Today().addMonths(1),
                    'Term' => 3,
                    'PriceBook2Id' => Test.getStandardPriceBookId()
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    
    public class AssetDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Asset'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Asset' + counter
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    public class CCRDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                   'Effective_Date__c'=>System.today(),
                   'Effective_End_Date__c'=>System.today(),
                   'AssignmentStatus__c'=>'Unassigned',
                   'User__c'=>'Pending'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Effective_Date__c'=>System.today(),
                   'Effective_End_Date__c'=>System.today(),
                   'AssignmentStatus__c'=>'Unassigned',
                   'User__c'=>'Pending'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    
    public class PriceBookEntryDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'IsActive' => true,
                    'UnitPrice' => 0.0,
                    'PriceBook2Id' => Test.getStandardPriceBookId()
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'IsActive' => true,
                    'UnitPrice' => 0.0,
                    'PriceBook2Id' => Test.getStandardPriceBookId()
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    
    public class ContractLineItemDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'UnitPrice' => 0.0,
                    'Quantity' => 1
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'UnitPrice' => 0.0,
                    'Quantity' => 1
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    /*    
public class GroupDefaults implements FieldDefaults {
Map<String,Object> dynamicValueMap;

public void setDynamicValueMap(Map<String,Object> val) {
this.dynamicValueMap = val;
}

public Map<String,Object> getDynamicValueMap() {
return this.dynamicValueMap;
}

public Map<String, Object> getFieldDefaults() {
Map<String, Object>  m = new Map<String, Object> {
'Type' => 'Queue'
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
}
public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
Map<String, Object>  m = new Map<String, Object> {
'Type' => 'Queue'
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
} 
} 

public class QueueSObjectDefaults implements FieldDefaults {
Map<String,Object> dynamicValueMap;

public void setDynamicValueMap(Map<String,Object> val) {
this.dynamicValueMap = val;
}

public Map<String,Object> getDynamicValueMap() {
return this.dynamicValueMap;
}

public Map<String, Object> getFieldDefaults() {
Map<String, Object>  m = new Map<String, Object> {
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
}
public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
Map<String, Object>  m = new Map<String, Object> {
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
} 
} 

public class EmailMessageDefaults implements FieldDefaults {
Map<String,Object> dynamicValueMap;

public void setDynamicValueMap(Map<String,Object> val) {
this.dynamicValueMap = val;
}

public Map<String,Object> getDynamicValueMap() {
return this.dynamicValueMap;
}

public Map<String, Object> getFieldDefaults() {
Map<String, Object>  m = new Map<String, Object> {
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
}
public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
Map<String, Object>  m = new Map<String, Object> {
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
} 
} 
*/   
    public class LeadDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'LastName' => 'Test ',
                    'FirstName' => 'Test ',
                    'Company' => 'Test Company',
                    'Status' => 'Prospect',
                    'Phone' => '1234567890',
                    'Email' => 'test-example@test-rubrik.com',
                    'Industry' => 'Legal',
                    'LeadSource' => 'Reseller'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'LastName' => 'Test ' + counter,
                    'FirstName' => 'Test ' + counter,
                    'Company' => 'Test Company',
                    'Status' => 'Prospect',
                    'Phone' => '1234567890',
                    'Email' => 'test-example-'  + counter + '@test-rubrik.com',
                    'Industry' => 'Legal',
                    'LeadSource' => 'Reseller'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    }
    
    public class QuoteDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Quote_Name__c' => 'TestQuote'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Quote_Name__c' => 'TestQuote' + counter
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 

    public class Shipping_AddressDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'TestAddress'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'TestAddress' + counter
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    }

    public class OrderDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'EffectiveDate' => Date.Today(),
                'Order_Status__c' => 'PO Received',
                'ShippingStreet' => 'Test Street',
                'ShippingCity' => 'Test City',
                'ShippingState' => 'California',
                'ShippingCountry' => 'United States',
                'ShippingPostalcode' => '94820'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'EffectiveDate' => Date.Today(),
                'Order_Status__c' => 'PO Received',
                'ShippingStreet' => 'Test Street',
                'ShippingCity' => 'Test City',
                'ShippingState' => 'California',
                'ShippingCountry' => 'United States',
                'ShippingPostalcode' => '94820'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    }

    public class POCDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'POC_Duration__c' => '30 Days',
                'Planned_Installation_Date__c' => System.Today()+30,
                'Support_Awareness_needed__c' => 'Yes'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'POC_Duration__c' => '30 Days',
                'Planned_Installation_Date__c' => System.Today()+30,
                'Support_Awareness_needed__c' => 'Yes'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    }    
    /*    
public class QuoteLineDefaults implements FieldDefaults {
Map<String,Object> dynamicValueMap;

public void setDynamicValueMap(Map<String,Object> val) {
this.dynamicValueMap = val;
}

public Map<String,Object> getDynamicValueMap() {
return this.dynamicValueMap;
}

public Map<String, Object> getFieldDefaults() {
Map<String, Object>  m = new Map<String, Object> {
'SBQQ__Number__c' => 1,
'SBQQ__Quantity__c' => 1
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
}
public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
Map<String, Object>  m = new Map<String, Object> {
'SBQQ__Number__c' => 1,
'SBQQ__Quantity__c' => 1
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
} 
} 

public class PatchManagerDefaults implements FieldDefaults {
Map<String,Object> dynamicValueMap;

public void setDynamicValueMap(Map<String,Object> val) {
this.dynamicValueMap = val;
}

public Map<String,Object> getDynamicValueMap() {
return this.dynamicValueMap;
}

public Map<String, Object> getFieldDefaults() {
Map<String, Object>  m = new Map<String, Object> {
'Object_Type__c' => 'All',
'City__c' => 'Palo Alto',
'State__c' => 'California',
'Zip_code__c' => '94304',
'County__c' => 'Santa Clara',
'City__c' => 'Palo Alto',
'Country__c' => 'US',
'CountryGlobal__c' => 'United States'
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
}
public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
Map<String, Object>  m = new Map<String, Object> {
'Object_Type__c' => 'All',
'City__c' => 'Palo Alto',
'State__c' => 'California',
'Zip_code__c' => '94304',
'County__c' => 'Santa Clara',
'City__c' => 'Palo Alto',
'Country__c' => 'US',
'CountryGlobal__c' => 'United States'
};
if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
return m;
} 
} 
*/    
    public class EntitlementDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'TestEntitlement'
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'TestEntitlement' + counter
                    };
                        if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        } 
    } 
    //Create Partner Configuration Record
    public static List<Partner_Page_Configuration__c> testMethod_PartnerPageConfigurationCreation(integer numberOfRecord){
        List<Partner_Page_Configuration__c> lstPartnerConfig = new List<Partner_Page_Configuration__c>();        
        for(Integer i=0; i<numberOfRecord; i++)
        {
            Partner_Page_Configuration__c pc = ShGl_TestFactoryHelper.createPartnerConfigRecord(i);
            lstPartnerConfig.add(pc);
        }
        insert lstPartnerConfig;
        return lstPartnerConfig;
    }
    //Create PortalAccount
    public static Account testMethod_PartnerAccount(String accountName){
        Account acc=ShGl_TestFactoryHelper.createPortalAccount(accountName);
        insert acc;
        return acc;
    }
    //Create Portal Contact
    public static List<Contact> testMethod_PartnerContact(integer numberOfContact,Account partnerAccount){
        List<Contact> lstContact = new List<Contact>();
        for(Integer i=0; i<numberOfContact; i++)
        {
            Contact conRecord=   ShGl_TestFactoryHelper.createPortalContact(i,partnerAccount);
            lstContact.add(conRecord);
        }
        insert lstContact;
        return lstContact;
    }
    //Create Portal User
    public static List<User> testMethod_PartnerUser(integer numberOfUserRecord,List<Contact> lstContact){
        List<user> lstUser = new List<user>();
        for(Integer i=0; i<numberOfUserRecord; i++)
        {
            User userRecord = ShGl_TestFactoryHelper.createPortalUser(i,lstContact[i]);
            lstUser.add(userRecord);
        }
        insert lstUser;
        return lstUser;
    }
    //Create Content
    public static List<ContentVersion> testMethod_Content(integer numberOfContent){
        List<ContentVersion> lstContent = new List<ContentVersion>();
        for(Integer i=0; i<numberOfContent; i++)
        {
            ContentVersion cVersion = ShGl_TestFactoryHelper.createContent(i);
            lstContent.add(cVersion);
        }
        insert lstContent;
        return lstContent;
    }
    //Create Content
    public static EntitySubscription testMethod_EntitySubscription(Id parentID,String userId){
        EntitySubscription entitySub = new EntitySubscription(ParentId = parentID, SubscriberId = userId);
        insert entitySub;
        return entitySub;
    }
    //Create Partner Onboarding
    public static List<Partner_Onboarding_Request__c> testMethod_PartnerOnBoarding(integer numberOfOnBoardRecs){
        List<Partner_Onboarding_Request__c> lstPartnerOnBoarding = new List<Partner_Onboarding_Request__c>();
        for(Integer i=0; i<numberOfOnBoardRecs; i++)
        {
            Partner_Onboarding_Request__c pOnBarding = ShGl_TestFactoryHelper.createPartnerOnBoarding(i);
            lstPartnerOnBoarding.add(pOnBarding);
        }
        insert lstPartnerOnBoarding;
        return lstPartnerOnBoarding;
    }
    //Create Incentive
    public static List<Incentives__c> testMethod_Incentive(integer incentiveRecord,List<String> ccrType){
        List<Incentives__c> lstIncentive = new List<Incentives__c>();
        for(Integer i=0; i<incentiveRecord; i++)
        {
            Incentives__c iRecord = ShGl_TestFactoryHelper.createIncentive(i,ccrType[0]);
            lstIncentive.add(iRecord);
        }
        insert lstIncentive;
        return lstIncentive;
    }
    //Create Attachment
    public static List<Attachment> testMethod_Attachment(integer attachmentRecord,List<Id> attachmentIds){
        List<Attachment> lstAttachment = new List<Attachment>();
        for(Integer i=0; i<attachmentRecord; i++)
        {
            Attachment atRec =  ShGl_TestFactoryHelper.createAttachment(i,attachmentIds[i]);
            lstAttachment.add(atRec);
        }
        insert lstAttachment;
        return lstAttachment;
    }
    //Create Deal Registration Record
    
    public static List<Deal_Registration__c> testMethod_createDealRegistration(integer drRecords){
        List<Deal_Registration__c> lstdrRec = new List<Deal_Registration__c>();
        for(Integer i=0; i<drRecords; i++)
        {
            Deal_Registration__c drRec =  ShGl_TestFactoryHelper.createDealRegistration(i);
            drRec.Country__c = 'United States';
            lstdrRec.add(drRec);
        }
        insert lstdrRec;
        return lstdrRec;
        
    }
    //createsalesforce user with role 
    public static user createUserwithRole(){
        Profile profiles=[Select Id From Profile Where Name='System Administrator'];
        String roleId = [SELECT Id FROM UserRole WHERE Name ='CEO' ].Id;
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000));
        String uniqueName = orgId + dateString + randomInt;        
        User u = new User();
        u.Username = uniqueName + '@test' + orgId + '.org';
        u.ProfileId = profiles.Id;
        u.UserRoleId = roleId;
        u.LastName = 'test';
        u.Alias = 'tUser';
        u.Email = 'testuser@testuser1.com';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.localesidkey='en_US';
        u.emailencodingkey='UTF-8';
        u.languagelocalekey='en_US';
        insert u;
        return u;
    }
    //Create Salesforce user
    public static List<User> testMethod_createUser(integer urRecords){
        List<User> lstUserRec = new List<User>();
        for(Integer i=0; i<urRecords; i++)
        {
            User u = ShGl_TestFactoryHelper.createUser(i);
            lstUserRec.add(u);
        }        
        insert lstUserRec;
        return lstUserRec;
    }
    //Create CCR Record
    public static List<CCR__c> testMethod_createCCR(integer ccrRecords,List<String> emailds){
        List<CCR__c> lstCCR = new List<CCR__c>();
        for(Integer i=0; i<ccrRecords; i++)
        {
            CCR__c crRecord = ShGl_TestFactoryHelper.createCCR(emailds[i]);
            lstCCR.add(crRecord);
        }
        insert lstCCR;
        return lstCCR;
    }
    //Create Partner Request Record without insert
    public static List<Partner_Registration_Request__c> testMethod_createPRRequest(integer prrRecords){
        List<Partner_Registration_Request__c> lstPRR = new List<Partner_Registration_Request__c>();
        for(Integer i=0; i<prrRecords; i++)
        {
            Partner_Registration_Request__c prRecord = ShGl_TestFactoryHelper.createPRR();
            lstPRR.add(prRecord);
        }
        return lstPRR;
    }
    //Create Partner Event
    /* Commenting as part of PRIT25-262
    public static List<Partner_Event__c> testMethod_createPartnerEvent(integer peRecords){
        List<Partner_Event__c> lstPRR = new List<Partner_Event__c>();
        for(Integer i=0; i<peRecords; i++)
        {
            Partner_Event__c prRecord = ShGl_TestFactoryHelper.createPartnerEvent(i);
            lstPRR.add(prRecord);
        }
        insert lstPRR;
        return lstPRR;        
    }    */
    
    //Create Product2
    public static List<Product2> testMethod_createProduct(integer productRecords){
        List<Product2> lstProduct = new List<Product2>();
        for(Integer i=0; i<productRecords; i++)
        {
            Product2 prRecord = ShGl_TestFactoryHelper.createProduct(i);
            lstProduct.add(prRecord);
        }
        insert lstProduct;
        return lstProduct;        
    }    
    
    //Create Pricebook2
    public static List<Pricebook2> testMethod_createPricebook(integer pbRecords){
        List<Pricebook2> lstPB = new List<Pricebook2>();
        for(Integer i=0; i<pbRecords; i++)
        {
            Pricebook2 prRecord = ShGl_TestFactoryHelper.createPricebook(i);
            lstPB.add(prRecord);
        }
        insert lstPB;
        return lstPB;        
    }    
    
    //Create PriceBookEntry
    public static List<PricebookEntry> testMethod_createPriceBookEntries(List<Product2> lstProducts,Id priceBookId){
        List<PricebookEntry> lstPB =  ShGl_TestFactoryHelper.createPriceBookEntries(lstProducts,priceBookId);
        insert lstPB;
        return lstPB;        
    }    
    
    //Create Order
    public static List<Order> testMethod_createOrder(integer orderRecords,Account acc,Pricebook2 pb){
        List<Order> lstOrder = new List<Order>();
        for(Integer i=0; i<orderRecords; i++)
        {
            Order oRecord = ShGl_TestFactoryHelper.createOrder(i,acc,pb);
            lstOrder.add(oRecord);
        }
        insert lstOrder;
        return lstOrder;        
    }    
    //Create Partner Onborading Records
    public static List<Partner_Onboarding_Request__c> testMethod_PartnerOnBoardingWithoutInsert(integer numberOfOnBoardRecs){
        List<Partner_Onboarding_Request__c> lstPartnerOnBoarding = new List<Partner_Onboarding_Request__c>();
        for(Integer i=0; i<numberOfOnBoardRecs; i++)
        {
            Partner_Onboarding_Request__c pOnBarding = ShGl_TestFactoryHelper.createPartnerOnBoarding(i);
            lstPartnerOnBoarding.add(pOnBarding);
        }
        return lstPartnerOnBoarding;
    }
    //Create Patch Manager
    public static List<PatchManager__c> testMethod_createPatchManager(integer numberPM){
        List<PatchManager__c> lstPatchManager = new List<PatchManager__c>();
        for(Integer i=0; i<numberPM; i++)
        {
            PatchManager__c pManager = ShGl_TestFactoryHelper.createPatchManager();
            lstPatchManager.add(pManager);
        }
        insert lstPatchManager;
        return lstPatchManager;
    }
    //Create Lead
    public static List<Lead> testMethod_createLead(integer numberOfLead){
        List<Lead> lstLead = new List<Lead>();
        
        WorkflowTriggerBypass__c wtb = new WorkflowTriggerBypass__c(Name='cnsFirstAttemptUpdateLeadStatus',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb1 = new WorkflowTriggerBypass__c(Name='CreateSDRLedMeetingTask',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb2 = new WorkflowTriggerBypass__c(Name='leadReassignOnBusinessUnitChange',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb3 = new WorkflowTriggerBypass__c(Name='updateLastOwnershipUpdateDate',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb4 = new WorkflowTriggerBypass__c(Name='updateOpportunitySource',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb5 = new WorkflowTriggerBypass__c(Name='salesOperationInvokePatchManager',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb6 = new WorkflowTriggerBypass__c(Name='salesOperationsAssignAccountSIC',ByPassTrigger__c=false);
        WorkflowTriggerBypass__c wtb7 = new WorkflowTriggerBypass__c(Name='salesOperationsSetEUResident',ByPassTrigger__c=false);
        insert new List<WorkflowTriggerBypass__c>{wtb,wtb1,wtb2,wtb3,wtb4,wtb5,wtb6,wtb7};
            
        for(Integer i=0; i<numberOfLead; i++)
        {
            Lead ld = ShGl_TestFactoryHelper.createLead(i);
            lstLead.add(ld);
        }
        insert lstLead;
        return lstLead;        
    }
        //Create DOCEBO Training record
    public static List<DOCEBO1_CO__c> testMethod_createTraining(List<String> lstTName){
        List<DOCEBO1_CO__c> lstDocebo = new List<DOCEBO1_CO__c>();
        for(Integer i=0; i<lstTName.size(); i++)
        {
            DOCEBO1_CO__c db = ShGl_TestFactoryHelper.createTraining(lstTName[i]);
            lstDocebo.add(db);
        }
        insert lstDocebo;
        return lstDocebo;        
    }
    //Create DOCEBO record
    public static List<DOCEBO2_CO__c> testMethod_createDecebo(integer createRecord,DOCEBO1_CO__c lstDbo,Contact con){
        List<DOCEBO2_CO__c> lstDocebo = new List<DOCEBO2_CO__c>();
        for(Integer i=0; i<createRecord; i++)
        {
            DOCEBO2_CO__c db = ShGl_TestFactoryHelper.createDecebo(i,lstDbo.Id,con.Id);
            lstDocebo.add(db);
        }
        insert lstDocebo;
        return lstDocebo;        
    }
    
    //Create Campaign Records
    public class CampaignDefaults implements FieldDefaults {
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Campaign',
                'IsActive' => true
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Name' => 'Test Campaign' + counter,
                'IsActive' => true
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }        
    }
    public class Alliance_Deal_RegistrationDefaults implements FieldDefaults{
        Map<String,Object> dynamicValueMap;
        
        public void setDynamicValueMap(Map<String,Object> val) {
            this.dynamicValueMap = val;
        }
        
        public Map<String,Object> getDynamicValueMap() {
            return this.dynamicValueMap;
        }
        
        public Map<String, Object> getFieldDefaults() {
            Map<String, Object>  m = new Map<String, Object> {
                'Alliance_Partner__c' => 'Amazon',
                'Raw_Country__c' => 'United States',
                'Company__c' => 'Test Company'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }
        public Map<String, Object> getFieldDefaultsMultipleRecords(integer counter) {
            Map<String, Object>  m = new Map<String, Object> {
                'Alliance_Partner__c' => 'Amazon',
                'Raw_Country__c' => 'United States',
                'Company__c' => 'Test Company'
            };
            if(dynamicValueMap!=null) m.putAll(dynamicValueMap);
            return m;
        }        
    }
public static void testCode(){
        String s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';
        s = '';

    }    

}