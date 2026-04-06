/*
* Class Name :- PAGRequestWrapper
* Author :- Rubrik Dev
* Created Date :- Aug 29th , 2023
* Description : CPQ22-3109 :- Request Wrapper for PAGService API
* TestClass   : PAGServiceTest
// ********************Mofification Log *****************************************************************************
* 
* Modified By          Date             Description (Include Jira Details)
* 
* 
* 
// ********************Modification Log *****************************************************************************
*/
public class PAGRequestWrapper {

    public List<PAGs> pags;
    public List<Entitlements> entitlements;

    public class PAGs {
        public PAGWrap pagWrapper;
    }
    public class PAGWrap {
        public String SKU;
        public Product_Assisted_Growth__c pagRecord;
    }


    public class Entitlements {
        public EntitlementWrapper entWrapper;
    }

    public class EntitlementWrapper {
        public Entitlement entitlementRecord;
        public String SKU;
    }
}