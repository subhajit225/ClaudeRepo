global class GenerateQuoteDocumentBatch implements Database.Batchable<sObject> {
    
    static final String QUOTE_DOCUMENT_STATUS = 'Pending';
    static final String QUOTE_TEMPLATE_MSP = 'Quote Document - MSP Disti';
    static final String QUOTE_TEMPLATE_ELEVATE = 'Quote Document - Elevate';
    static final String EMAIL_TEMPLATE_NAME = 'Quote Approval Request';
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'Select Id'
                          + ', SBQQ__PrimaryContact__c'
                          + ', SBQQ__EmailTemplateId__c'
                          + ', SBQQ__QuoteTemplateId__c'
                          + ', SBQQ__Opportunity2__r.Opportunity_Sub_Type__c'
                          + ', SBQQ__DocumentStatus__c'
                    + ' From SBQQ__Quote__c'
                    + ' Where Generate_Document__c = TRUE'
                    + ' AND SBQQ__Primary__c = TRUE';
                    /*+ ' Where SBQQ__DocumentStatus__c = \'' + QUOTE_DOCUMENT_STATUS + '\''
                    + ' And (SBQQ__PrimaryContact__c = NULL'
                    +     ' OR SBQQ__QuoteTemplateId__c = NULL)'; */
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Contact> listContact = new List<Contact>();
        listContact = [Select Id
                       From Contact
                       Where Name =: System.Label.Dummy_Contact_Name
                       Limit 1
                      ];
        
        List<EmailTemplate> listEmailTemplate = new List<EmailTemplate>();
        listEmailTemplate = [Select Id
                             From EmailTemplate
                             Where Name =: EMAIL_TEMPLATE_NAME
                            ];
        
        Map<String, Id> mapQuoteTemplateNameWithId = new Map<String, Id>();
        for (
                SBQQ__QuoteTemplate__c objQuoteTemplate :
                    [Select Id
                          , Name
                     From SBQQ__QuoteTemplate__c
                     Where Name =: QUOTE_TEMPLATE_MSP
                     OR Name =: QUOTE_TEMPLATE_ELEVATE
                    ]
        ) {
            mapQuoteTemplateNameWithId.put(objQuoteTemplate.Name.toLowerCase(), objQuoteTemplate.Id);
        }
        
        if (!listContact.isEmpty()) {
            List<SBQQ__Quote__c> listQuote = (List<SBQQ__Quote__c>)scope;
            for(SBQQ__Quote__c objQuote : listQuote) {
                objQuote.SBQQ__DocumentStatus__c = QUOTE_DOCUMENT_STATUS;
                if (objQuote.SBQQ__PrimaryContact__c == NULL) {
                    objQuote.SBQQ__PrimaryContact__c = listContact[0].Id;
                }
                
                if (String.isBlank(objQuote.SBQQ__EmailTemplateId__c)) {
                    objQuote.SBQQ__EmailTemplateId__c = listEmailTemplate[0].Id;
                }
                
                if (String.isBlank(objQuote.SBQQ__QuoteTemplateId__c)) {
                    if (
                            objQuote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != NULL
                            && objQuote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c.contains('MSP')
                            && mapQuoteTemplateNameWithId.containsKey(QUOTE_TEMPLATE_MSP.toLowercase())
                    ) {
                        objQuote.SBQQ__QuoteTemplateId__c = mapQuoteTemplateNameWithId.get(QUOTE_TEMPLATE_MSP.toLowercase());
                    } else if (
                           objQuote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c != NULL
                           && !objQuote.SBQQ__Opportunity2__r.Opportunity_Sub_Type__c.contains('MSP')
                           && mapQuoteTemplateNameWithId.containsKey(QUOTE_TEMPLATE_ELEVATE.toLowercase()) 
                    ) {
                        objQuote.SBQQ__QuoteTemplateId__c = mapQuoteTemplateNameWithId.get(QUOTE_TEMPLATE_ELEVATE.toLowercase());
                    } else {
                        objQuote.SBQQ__DocumentStatus__c = '';
                    }
                }
            }
            
            if (!listQuote.isEmpty()) {
                update listQuote;
            }
        }
    }

    global void finish(Database.BatchableContext BC) {
        
    }

}