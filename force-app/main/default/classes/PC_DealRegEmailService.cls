/**
* Date : Feb 20, 2024
* Developer : Anshul Gupta (Channel)
* Desc : Custom approval for Escalated PSNL DR for RD/RVP
* Change Log :
*/
global without sharing class PC_DealRegEmailService implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail (Messaging.InboundEmail email,Messaging.InboundEnvelope envelope){
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        String subToCompareRDApproval = 'Partner Sourced Escalation RD Approval';
        String subToCompareRVPApproval = 'Partner Sourced Escalation RVP Approval';
        Boolean isUpdateFlag = false;
        String firstLine = (email.plainTextBody.split('\n')[0] + email.plainTextBody.split('\n')[1]).toLowerCase();
        String dealRegName = '';

        if (email.subject.containsIgnoreCase(subToCompareRDApproval) || email.subject.containsIgnoreCase(subToCompareRVPApproval)){
            dealRegName = email.subject.substringAfter('-').trim();
        }

        List<Deal_Registration__c> dealRegList = [SELECT ID,Name,PS_Escalated__c,Deal_Registration_Status__c,Deal_Registration_Sub_Status__c,
                                                  ACV_at_Escalation__c,Primary__c,DR_Approved_Date__c,Approval_Timestamp__c,Deal_Reg_Exp_Date__c,
                                                  Deal_Registration_Extension_Request__c,Deal_Registration_Type__c,Primary_Deal_Registration__c,
                                                  Registration_Type__c FROM Deal_Registration__c WHERE Name =:dealRegName AND Opportunity__r.IsClosed =false LIMIT 1];

        if (!dealRegList.isEmpty() && dealRegList[0].Deal_Registration_Status__c == 'Escalated' && dealRegList[0].PS_Escalated__c) {
            if (firstLine.contains('approved') || firstLine.contains('approve') || firstLine.contains('yes'))
            {
                if (email.subject.containsIgnoreCase(subToCompareRDApproval) && dealRegList[0].Deal_Registration_Sub_Status__c == 'Pending RSM Approval') {
                    if (dealRegList[0].ACV_at_Escalation__c > 300000) {
                        dealRegList[0].Deal_Registration_Sub_Status__c = 'Pending RVP Approval';
                    } else {
                        dealRegList[0].Deal_Registration_Status__c = 'Approved';
                        dealRegList[0].Deal_Registration_Sub_Status__c = 'RSM Approved';
                        dealRegList[0].Approval_Timestamp__c = System.now();
                        dealRegList[0].DR_Approved_Date__c = System.today();
                        dealRegList[0].Primary__c = true;
                        dealRegList[0].Deal_Reg_Exp_Date__c = null;
                        dealRegList[0].Deal_Registration_Extension_Request__c = '';
                        if(dealRegList[0].Deal_Registration_Type__c == 'Rubrik Sourced' && dealRegList[0].Registration_Type__c == 'Value Add'){
                            dealRegList[0].Deal_Registration_Type__c = 'Partner Sourced Expand';
                            dealRegList[0].Registration_Type__c = 'Partner Sourced';
                        }
                    }
                } else if (email.subject.containsIgnoreCase(subToCompareRVPApproval) && dealRegList[0].Deal_Registration_Sub_Status__c == 'Pending RVP Approval') {
                    dealRegList[0].Deal_Registration_Status__c = 'Approved';
                    dealRegList[0].Deal_Registration_Sub_Status__c = 'RVP Approved';
                    dealRegList[0].Approval_Timestamp__c = System.now();
                    dealRegList[0].DR_Approved_Date__c = System.today();
                    dealRegList[0].Primary__c = true;
                    dealRegList[0].Deal_Reg_Exp_Date__c = null;
                    dealRegList[0].Deal_Registration_Extension_Request__c = '';
                    if(dealRegList[0].Deal_Registration_Type__c == 'Rubrik Sourced' && dealRegList[0].Registration_Type__c == 'Value Add'){
                        dealRegList[0].Deal_Registration_Type__c = 'Partner Sourced Expand';
                        dealRegList[0].Registration_Type__c = 'Partner Sourced';
                    }
                }
                isUpdateFlag = true;
            } else if (firstLine.contains('rejected') || firstLine.contains('reject') || firstLine.contains('no')) {
                if (dealRegList[0].Deal_Registration_Sub_Status__c == 'Pending RSM Approval' && email.subject.containsIgnoreCase(subToCompareRDApproval)) {
                    dealRegList[0].Deal_Registration_Sub_Status__c = 'RSM Rejected';
                } else if (dealRegList[0].Deal_Registration_Sub_Status__c == 'Pending RVP Approval' && email.subject.containsIgnoreCase(subToCompareRVPApproval)) {
                    dealRegList[0].Deal_Registration_Sub_Status__c = 'RVP Rejected';
                }
                dealRegList[0].Deal_Registration_Status__c = 'Approved';
                dealRegList[0].Approval_Timestamp__c = System.now();
                dealRegList[0].DR_Approved_Date__c = System.today();
                dealRegList[0].Primary__c = true;
                dealRegList[0].Deal_Reg_Exp_Date__c = null;
                dealRegList[0].Deal_Registration_Extension_Request__c = '';
                dealRegList[0].Deal_Registration_Type__c = 'Rubrik Sourced';
                dealRegList[0].Registration_Type__c = 'Value Add';
                isUpdateFlag = true;
            }
        }

        if(isUpdateFlag){
            Update dealRegList;
        }
        result.success = true;
        return result;
    }
}