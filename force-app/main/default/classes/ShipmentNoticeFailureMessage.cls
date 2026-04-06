/*****************************************************************************

 * @description       : Send Email on ASN failure
 * @author            : Chaitra
 * @last modified on  : 01-20-2022
 * @last modified by  : Chaitra
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   01-20-2022   Chaitra        Initial Version
 * 2.0   24-08-2022   Sailaja        ASPEN1B-247-ASN Quote based Validations
 ****************************************************************************/
public class ShipmentNoticeFailureMessage {
    final static Map<String, AspenConfig__mdt> ASPEN_CONFIGS;
    final static Map<String, String> ASPEN_CONFIG_LABEL;
    final static Map<Id, String> ASPEN_CONFIG_ACC_ID;
    final static Id OM_EMAIL_OW_ADDRESS_ID;
    final static String OM_EMAIL,PROD_OPS_DEV_EMAIL,PROD_OPS_DEV_EMAIL_CC;  
    static {
    
        ASPEN_CONFIGS = AspenConfig__mdt.getAll();
        ASPEN_CONFIG_LABEL = new Map<String, String>();
        ASPEN_CONFIG_ACC_ID = new Map<Id, String>();
        OM_EMAIL = Email_Preferences__mdt.getInstance('SendEmailSalesOps').From__c;
        PROD_OPS_DEV_EMAIL = Email_Preferences__mdt.getInstance('ProdOpsDevelopers').Receipient__c;
        PROD_OPS_DEV_EMAIL_CC = Email_Preferences__mdt.getInstance('ProdOpsDevelopers').cc__c;
    
        for (AspenConfig__mdt aspenConfig : ASPEN_CONFIGS.values()) {
            ASPEN_CONFIG_LABEL.put(aspenConfig.MasterLabel, aspenConfig.DeveloperName);
            if(aspenConfig.Id__c != null) ASPEN_CONFIG_ACC_ID.put(aspenConfig.Id__c, aspenConfig.DeveloperName);
        }
        OM_EMAIL_OW_ADDRESS_Id = [SELECT Id FROM OrgWideEmailAddress WHERE Address = : OM_EMAIL LIMIT 1].Id;
    
    }
    
    String type, subject, htmlMessageBody='';
    String cm,orderNumber, distributor;
    List<String> recipients;
    public ShipmentNoticeFailureMessage(SBQQ__Quote__c relQuote, String type, List<ShipmentDetail__c> sdRecs, Order relOrder,Set<String> failureReason) {
        try{
            this.type = type;
            this.cm = relOrder?.Contract_Manufacturer__c != null ? relOrder?.Contract_Manufacturer__c : (sdRecs != null && !sdRecs.isEmpty()) ? sdRecs[0].ContractManufacturer__c: null;
            this.orderNumber = relOrder?.OrderNumber;
            this.distributor = relOrder?.Bill_To_Name__c;
            if(relOrder == null) {
                ShipmentDetail__c sd = sdRecs.get(0);
                this.cm = sd.ContractManufacturer__c;
                this.orderNumber = sd.SalesOrderNumber__c;
                this.distributor = relQuote?.SBQQ__Distributor__c; //ASPEN1B-247
            }
            string quoteName= relQuote?.Name==null? sdRecs[0].QuoteNumber__c:relQuote.Name;
            string orderNum = this.orderNumber == null? '-': this.orderNumber;
            setSubject(this.cm, quoteName, relQuote?.SBQQ__Account__r.Name);
            setBodyHeaderMessage(quoteName, orderNum,failureReason);
            if(sdRecs != null && !sdRecs.isEmpty()) {
                addTableToMessageBody();
            }
            for (ShipmentDetail__c sdRec : sdRecs) {
                addRecordRowToTable(relQuote, sdRec);
            }
            closeMessageBody();
            setRecipients( this.cm, this.distributor);
        }
        catch(Exception ex)
        {
            system.debug('error in ShipmentNoticeFailureMessage: '+ex.getMessage());
        }
    }
    
    public Messaging.SingleEmailMessage getSingleEmail() {
        Messaging.SingleEmailMessage e = new Messaging.SingleEmailMessage();
        try
        {
            if(recipients == null || recipients.isEmpty()) {return null;}
            e.setSubject(subject);
            e.setToAddresses(recipients);
            e.setHtmlBody(htmlMessageBody);
            e.setPlainTextBody(htmlMessageBody.stripHtmlTags());
            e.setOrgWideEmailAddressId(OM_EMAIL_OW_ADDRESS_Id);
            return e;
        }
        catch(Exception ex)
        {
            system.debug('error: '+ex.getMessage());
            return e;
        }
    }
    
    private final static String TABLE_CELL_HTML = '<td style="text-align: left; padding: 15px; border: 2px solid #ddd">';
    private static String generateRow(List<String> orderedCells) {
        String row = '<tr>';
        for (String cell : orderedCells) {
            row += TABLE_CELL_HTML + cell + '</td>';
        }
        row += '</tr>';
        return row;
    }
    private void closeMessageBody() {
        htmlMessageBody += '</tbody></table><br/><p>Kindly resolve this issue and inform Rubrik of the resolution. Please reprocess the ASN with the right Quote # and/or HW part(s) and resend this transaction.</p><p>Thank you,</p><p>Orders@Rubrik.com</p></body>  </html>';
    }
    private void addRecordRowToTable(SBQQ__Quote__c quote, ShipmentDetail__c sd) {
        htmlMessageBody += generateRow(
            new List<String> { sd.ProductName__c, sd.ContractManufacturer__c, sd.HW_SerialNumber__c==null?'-': sd.HW_SerialNumber__c, sd.Quantity__c== null ? '':String.valueOf(sd.Quantity__c.intValue()),  sd.ProcessHistory__c, sd.Status__c }
            );
    }
    
    private void setSubject(String cm, String quoteName, String accountName) {
        quoteName= quoteName==null? '':quoteName;
        accountName= accountName==null? '':accountName;
        this.subject = 'ERROR Notification : ASN sent by ' + cm + ' to RBRK is not matching | ' + quoteName + ' ' + accountName;
    }
    
    private void setRecipients(String cm, String disti) {
        recipients = new List<String> { UserInfo.getUserEmail() /* Send to User Only for Testing puposes, to remove in UAT  */ };
        SYstem.debug('XX:\n' + JSON.serialize(new Map<String,Object> {
                'ASPEN_CONFIG_LABEL'=>ASPEN_CONFIG_LABEL,
                'ASPEN_CONFIGS' => ASPEN_CONFIGS,
                'cm' => cm,
                'disti' => disti,
                'ASPEN_CONFIG_LABEL.get(cm)' => ASPEN_CONFIG_LABEL.get(cm),
                'ASPEN_CONFIG_ACC_ID.get(disti)' => ASPEN_CONFIG_ACC_ID.get(disti)
            }));
        if (type == 'Failed') {
            for (String email : new List<String> { !String.isBlank(cm)?ASPEN_CONFIGS.get(ASPEN_CONFIG_LABEL.get(cm)).ASN_EmailId__c:'', !String.isBlank(disti)?ASPEN_CONFIGS.get(ASPEN_CONFIG_ACC_ID.get(disti)).ASN_EmailId__c:'', !String.isBlank(OM_EMAIL)?OM_EMAIL:'' }) {
                if (email!=null && !String.isBlank(email))
                {
                    recipients.addall(email.split(','));   
                }
            }
        } else {
            for(String email : new List<String> { PROD_OPS_DEV_EMAIL_CC, PROD_OPS_DEV_EMAIL}) {
                system.debug('email: '+email);
                if(email!=null && !String.isBlank(email))
                {
                    recipients.addall(email.split(','));
                }
            }
        }
    }
    
    private void setBodyHeaderMessage(String relQuoteName, String relOrderNumber,Set<String> failureReason) {
        relQuoteName = relQuoteName==null? '-':relQuoteName;
        relOrderNumber = relOrderNumber==null? '-':relOrderNumber;
        if(failureReason != null && !failureReason.isEmpty()) {
            String failureString = '';
            for(String str : failureReason) {
                if(string.isNotBlank(str)) {failureString = failureString + ' ' + str;}
            }
            htmlMessageBody =
                '<html><body><p>The Quote # and/or HW Parts referred in the ASN is not matching to this transaction. See below for the details.</p>' +
                '<p> Quote Number: <strong>' +
                relQuoteName +
                '</strong><br/> Order Number: <strong>' +
                relOrderNumber;
                if(string.isNotBlank(failureString) && failureString.trim()!='NA') { 
                htmlMessageBody+='</strong></p><p> Failure Reason: <strong>' +
                                  failureString +
                                  '</strong></p>';
            }
        }else{
            htmlMessageBody =
                '<html><body><p>The Quote # and/or HW Parts referred in the ASN is not matching to this transaction. See below for the details.</p>' +
                '<p> Quote Number: <strong>' +
                relQuoteName +
                '</strong><br/> Order Number: <strong>' +
                relOrderNumber +   
                '</strong></p><br/>';
    
        }
    }
    
    private void addTableToMessageBody() {
        final String TH_STYLE = '<th style="text-align: left;padding: 15px;background-color: #f2f2f2;border: 2px solid #ddd;">';
        final String TH_CLOSE = '</th>';
        htmlMessageBody +=
            '<table class="ql-table-blob" style="margin: 20px 0px; border-collapse: collapse; border: 2px solid #ddd">' +
            '<thead><tr>' +
            TH_STYLE + 'Product Name' +TH_CLOSE +
            TH_STYLE + 'Contract Manufacturer ' +TH_CLOSE +
            TH_STYLE + 'HW Serial Number ' +TH_CLOSE +
            TH_STYLE + 'Quantity in Shipment Notification ' +TH_CLOSE +
            TH_STYLE + 'Process History ' +TH_CLOSE +
            TH_STYLE + 'Status' +TH_CLOSE + //ASPEN-247.
            '</tr></thead><tbody>';
       }

    }