/**
 * @description Apex controller to fetch categorized contacts for Stakeholder Map LWC.
 */
public without sharing class StakeholderMapController {

    /**
     * @description Get categorized contacts for a given account.
     * @param accountId The Id of the Account record.
     * @return Map<String, List<Contact>> Contacts grouped by category.
     */
    @AuraEnabled(cacheable=true)
    public static ResponseDTO getCategorizedContacts(Id accountId) {
        try {
            Map<String, List<Contact>> result = new Map<String, List<Contact>>();
            result.put('Key CXO Stakeholders', new List<Contact>());
            result.put('Additional C-Suite Personas', new List<Contact>());
            result.put('VP/Head Personas', new List<Contact>());
            result.put('Infrastructure Technology', new List<Contact>());
            result.put('Technology Architecture', new List<Contact>());
            result.put('Cloud Engineering', new List<Contact>());
            result.put('Security', new List<Contact>());
            result.put('App Owners', new List<Contact>());
            result.put('Others', new List<Contact>());
            
            if(!FeatureManagement.checkPermission('Stakeholder_Persona_Access')){
                return new ResponseDTO(false, 'Opps, you do not have access!', result);
            }

            List<Contact> contacts = [SELECT Id, Name, Title, Email, Key_CXO_Stakeholder_Title__c,Product_Persona__c
                                      FROM Contact
                                      WHERE AccountId = :accountId
                                      AND No_Longer_Employed_Here__c = false AND (Key_CXO_Stakeholder_Title__c != null OR Product_Persona__c != null OR Title != null)];
            
            for(Contact c : contacts) {
                string title = c.Title;
                if (c.Key_CXO_Stakeholder_Title__c != null) {
                    result.get('Key CXO Stakeholders').add(c);
                    continue;
                }
                
                if (c.Key_CXO_Stakeholder_Title__c == null && title != null && (title.contains('CEO') || title.contains('CIO') || title.contains('CISO') || title.contains('COO') || title.contains('Chief') || 
                title.contains('CMO') || title.contains('CTO') || title.contains('CSO') || title.contains('CXO') || title.contains('CDO'))) {
                    result.get('Additional C-Suite Personas').add(c);
                    
                }
                
                if (c.Key_CXO_Stakeholder_Title__c == null && title != null && (title.contains('VP') || title.contains('Head') || title.contains('Vice President'))) {
                    result.get('VP/Head Personas').add(c);
                }
                if (c.Product_Persona__c != null) {
                    if (c.Product_Persona__c =='Infrastructure Technology') {
                        result.get('Infrastructure Technology').add(c);
                    } else if (c.Product_Persona__c == 'Technology Architecture') {
                        result.get('Technology Architecture').add(c);
                    } else if (c.Product_Persona__c == 'Cloud Engineering') {
                        result.get('Cloud Engineering').add(c);
                    } else if (c.Product_Persona__c == 'Security') {
                        result.get('Security').add(c);
                    } else if (c.Product_Persona__c == 'App Owners') {
                        result.get('App Owners').add(c);
                    } else {
                        result.get('Others').add(c);
                    }
                }
            }
            
            return new ResponseDTO(true, 'Success!', result);
        }catch(Exception ex){
            return new ResponseDTO(false, 'Something went wrong please contact your administrator.'+ex.getMessage(), ex);
        }
    }
}