/**
 * @description       : Class for PC_DealRegButtonsConsole LWC
 * @author            : Sidhant Jain
 * @group             : Deal Registration
 * @last modified on  : 01-29-2026
 * @last modified by  : Sidhant Jain
**/
public without sharing class PC_DealRegistrationApexController{
    public static string AllianceRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Alliance').getRecordTypeId();
    public static string ResellerRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Reseller').getRecordTypeId();
    public static string ServiceDeliveryRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Service_Delivery_Partner').getRecordTypeId(); // PRIT24-887
    public static string OEMRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('OEM').getRecordTypeId();
    private static String ResellerDealExists = 'Reseller Deal Exists';
    private static String NoDealExists = 'No Deal Exists';
    private static String AllowDRAssociation = 'Allow DR Association';
    private static String Opp30DayDuration = 'Opp 30 Day Selection';
    private static String OppTimeViolationORNotStage1OR2 = 'Opp Stage Time Violation';
    private static String OppAccountMismatch = 'Account Mismatch';
    private static String OppPSExpand = 'Opp PS Expand';
    private static String OppDRMSP = 'DR is MSP';
    private static String DRPSEscalation = 'DR PS Escalation';//prit25-17
    private static String OppDistriError = 'Opp Distributor Error';
    private static String OppDistriMisMatchError = 'DR Dist is Mismatch';
    private static String DealTypeAutoSetMsg = 'Deal Type Auto-Set'; //PRIT26-520
 
    /**
    * @description Sends data used to control button enable/disable visibility.
    * @param parentRecordId The ID of the account.
    * @return List of contact.
    */
    @AuraEnabled
    public static List<Contact> getRelatedRecords(String parentRecordId){
        return [SELECT Id, Name, Email, Phone, Title
                FROM Contact
                WHERE AccountId = :parentRecordId
                ORDER BY CreatedDate DESC];
    }

    /**
    * @description Sends data used to control button enable/disable visibility.
    * @param drRecordId The ID of the current Deal Registration.
    * @return An instance of buttonVisibilityWrapper containing the result of the visibility.
    * @throws Exception if any unexpected error occurs.
    */
    @AuraEnabled
    public static buttonVisibilityWrapper getUserInOwnerTerritory(String drRecordId){
        Deal_Registration__c dealReg = [SELECT Id, Name, OwnerId, BDM__c, CDM__c,  Global_Account_Manager__c, Sales_Manager__c, Deal_Registration_Status__c, Deal_Registration_Sub_Status__c, RecordTypeId, Theatre_VP__c, PS_Escalated__c, Opportunity__c, OEM_SubType__c, OEM_L1_Approver__c, GSI_NDA__c
                                        FROM Deal_Registration__c
                                        WHERE Id = :drRecordId
                                        LIMIT 1];

        List<GroupMember> salesDataOpsMembers = [SELECT Id, UserOrGroupId
                                                 FROM GroupMember
                                                 WHERE GroupId = :System.Label.Sales_Data_Ops_Queue_Id AND UserOrGroupId = :UserInfo.getUserId()]; // PRIT24-843 : SalesDataOps Change

        Set<Id> territoryIdSet = new Set<Id>();
        Map<Id, UserTerritory2Association> userIDAndTerritoryMap = new Map<Id, UserTerritory2Association>();
        List<String> profileWithAccessSet = new List<String>();
        buttonVisibilityWrapper btnWrap = new buttonVisibilityWrapper();

        try{
            System.debug(LoggingLevel.DEBUG,'dealReg.dealReg'+dealReg);
            System.debug(LoggingLevel.DEBUG,'salesDataOpsMembers->'+salesDataOpsMembers);
            if (dealReg != null){
                profileWithAccessSet = System.Label.DealRegProfileIds.split(';');
                //Profile based visibilty (Admin/Sales Ops)
                if (profileWithAccessSet.contains(UserInfo.getProfileId())){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }

                //Service Delivery (Internal)/Alliance BDM onwership visibilty
                else if ((dealReg.RecordTypeId == ServiceDeliveryRecordTypeId || dealReg.RecordTypeId == AllianceRecordTypeId) && dealReg.Deal_Registration_Status__c == 'Submitted'){// && !dealReg.OwnerId.equals(UserInfo.getUserId())){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }

                //Escalated & RSM visibility
                else if (dealReg.Deal_Registration_Status__c == 'Escalated' && dealReg.Deal_Registration_Sub_Status__c == 'Pending RSM Approval' && dealReg.PS_Escalated__c && dealReg.Opportunity__c != null && dealReg.Sales_Manager__c != null && dealReg.Sales_Manager__c.equals(UserInfo.getUserId())){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }
                //Escalated & RVP visibility
                else if (dealReg.Deal_Registration_Status__c == 'Escalated' && dealReg.Deal_Registration_Sub_Status__c == 'Pending RVP Approval' && dealReg.PS_Escalated__c && dealReg.Opportunity__c != null && dealReg.Theatre_VP__c != null && dealReg.Theatre_VP__c.equals(UserInfo.getUserId())){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }
                //PRIT25-479
                //GSI-NDA Escalated & Sales ops visibility
                else if(dealReg.Deal_Registration_Status__c == 'Escalated' && dealReg.Deal_Registration_Sub_Status__c =='GSI-NDA Pending Approval' && dealReg.GSI_NDA__c && UserInfo.getUserId().equals(System.Label.exceptionalEMEA_APAC)){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }
                //OEM Revshare L1 Approver Visibilty
                else if (dealReg.RecordTypeId == OEMRecordTypeId && dealReg.Deal_Registration_Status__c == 'Submitted' && dealReg.Deal_Registration_Sub_Status__c == 'Pending L1 Approval' && dealReg.OEM_SubType__c == 'Revshare' && dealReg.OEM_L1_Approver__c.equals(UserInfo.getUserId())){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }
                //OEM Revshare TVP Approver Visibilty
                else if (dealReg.RecordTypeId == OEMRecordTypeId && dealReg.Deal_Registration_Status__c == 'Submitted' && dealReg.Deal_Registration_Sub_Status__c == 'Pending TVP Approval' && dealReg.OEM_SubType__c == 'Revshare' && dealReg.Theatre_VP__c.equals(UserInfo.getUserId())){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }
                //OEM Revshare disable for other actors
                else if (dealReg.RecordTypeId == OEMRecordTypeId && dealReg.Deal_Registration_Status__c == 'Submitted' && (((dealReg.Deal_Registration_Sub_Status__c == 'Pending L1 Approval' || dealReg.Deal_Registration_Sub_Status__c == 'Pending TVP Approval') && dealReg.OwnerId.equals(UserInfo.getUserId())) || (dealReg.Deal_Registration_Sub_Status__c == 'Pending TVP Approval' && dealReg.OEM_L1_Approver__c.equals(UserInfo.getUserId())) || (dealReg.Deal_Registration_Sub_Status__c == 'Pending L1 Approval' && dealReg.Theatre_VP__c.equals(UserInfo.getUserId())))){
                    btnWrap.enableMainButtonPanel = false;
                    btnWrap.disableConvertLeadButton = true;
                }
                //Escalated disable for other actors
                else if (dealReg.Deal_Registration_Status__c == 'Escalated' && (((dealReg.Deal_Registration_Sub_Status__c == 'Pending RSM Approval' || dealReg.Deal_Registration_Sub_Status__c == 'Pending RVP Approval') && dealReg.OwnerId.equals(UserInfo.getUserId())) || (dealReg.Deal_Registration_Sub_Status__c == 'Pending RVP Approval' && dealReg.Sales_Manager__c.equals(UserInfo.getUserId())) || (dealReg.Deal_Registration_Sub_Status__c == 'Pending RSM Approval' && dealReg.Theatre_VP__c.equals(UserInfo.getUserId())))){
                    btnWrap.enableMainButtonPanel = false;
                    btnWrap.disableConvertLeadButton = true;
                }
                //Reseller/OEM Sales Data Ops Queue
                else if ((dealReg.RecordTypeId == ResellerRecordTypeId || dealReg.RecordTypeId == OEMRecordTypeId) && dealReg.Deal_Registration_Status__c == 'Pending Conversion' && salesDataOpsMembers.size() > 0){
                    btnWrap.enableMainButtonPanel = true;
                    btnWrap.disableConvertLeadButton = false;
                }
                //Visibilty Based on owner territory
                else if (dealReg.Deal_Registration_Status__c != 'Escalated'){
                    //PRIT26-165
                    btnWrap.enableMainButtonPanel = (dealReg.OwnerId == UserInfo.getUserId()) || (dealReg.CDM__c == UserInfo.getUserId());
                    btnWrap.disableConvertLeadButton = !(dealReg.OwnerId == UserInfo.getUserId());
                }

                //expire button access
				//PRIT26-57
                List<UserTerritory2Association> npmUser = [SELECT Id, UserId FROM UserTerritory2Association WHERE RoleInTerritory2 = 'Channel Manager' AND Territory2.ParentTerritory2.ParentTerritory2.ParentTerritory2.Name =: Label.EnableExpiryButtonParentTerritory
                AND Territory2.Territory2Type.DeveloperName = 'Territory' AND UserId =: UserInfo.getUserId() AND Territory2.Territory2Model.State = 'Active' LIMIT 1];
                if(profileWithAccessSet.contains(UserInfo.getProfileId()) || !npmUser.isEmpty()){
                    btnWrap.enableExpireButton = true;
                }
            }
            return btnWrap;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Wrapper class to pass data in LWC component
     */
    public class ButtonVisibilityWrapper{
        /**
         * @description Flag for enabling Approve/Pending Meeting/Reject buttons
         */
        @AuraEnabled
        public Boolean enableMainButtonPanel{ get; set; }
        
		/**
         * @description Flag for disabling Convert Leqad button
         */
        @AuraEnabled
        public Boolean disableConvertLeadButton{ get; set; }
		
        /**
         * @description Flag for enabling Expire Extension button
         */
        @AuraEnabled
        public Boolean enableExpireButton { get; set; }
		
        /**
         * @description Constructor for Wrapper class for initiating the flags values
         */
        public buttonVisibilityWrapper(){
            enableMainButtonPanel = false;
            disableConvertLeadButton = true;
            enableExpireButton = false;
        }

    }
    
    /**
    * @description Validates whether a Deal Registration can be associated with the selected Opportunity.
    * @param currentDealRegID The ID of the current Deal Registration.
    * @param selectedOpptyId The ID of the Opportunity to associate with the Deal Registration.
    * @return An instance of attachDROpptyWrapper containing the result of the validation.
    * @throws Exception if any unexpected error occurs.
    */
    @AuraEnabled
    public static attachDROpptyWrapper allowDRAssociationToOpportunity(String currentDealRegID, String selectedOpptyId){
        try{
            attachDROpptyWrapper drOppData = new attachDROpptyWrapper();
            Map<String, Deal_Registration__c> drNameAndDRMap = new Map<String, Deal_Registration__c>();
            List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();

            Deal_Registration__c currDealReg = [SELECT ID, Name, Distributor__c, RecordTypeId, Deal_Reg_Submitted_Date__c, Deal_Registration_Type__c, Registration_Type__c, Partner_Lookup__c, Partner_Lookup__r.Distributor__c, Company_Name__c, 
                                                Company_Name__r.Type, Alliance_Type__c, Dedicated_Managed_Service__c, GSI_NDA__c, Deal_Registration_Status__c, Deal_Registration_Sub_Status__c FROM Deal_Registration__c
                                                WHERE ID = :currentDealRegID
                                                LIMIT 1];

            Opportunity selOpp = [SELECT ID, Name, OwnerId, StageName, IsClosed, Deal_Registration__c, Deal_Registration_Number__c, Deal_Reg_Approval_Status__c, CreatedDate, SDR_Led__c, Partner_Lookup__c, PSNL_Eligible__c, AccountId, Alliance_Partner_Name__c, Opportunity_Type__c, RecordType.Name, MSP_End_User_Lookup__c, Opportunity_Sub_Type__c, ACV_Amount__c, Partner_Lookup__r.Distributor__c, Distributor_Lookup__c, Account.BillingCountryCode, ETM_Area__c, ETM_Theatre__c,
                                  Account.Type, Account.RecordType.DeveloperName
                                  FROM Opportunity
                                  WHERE ID = :selectedOpptyId
                                  LIMIT 1];

            List<Deal_Registration__c> opptyAndDRList = [SELECT ID, Name, RecordTypeId
                                                         FROM Deal_Registration__c
                                                         WHERE ((RecordTypeId = :ResellerRecordTypeId OR RecordTypeId = :ServiceDeliveryRecordTypeId OR (RecordTypeId = :AllianceRecordTypeId AND Alliance_Type__c = 'Cloud')) AND (Opportunity__c = :selectedOpptyId OR Name = :selOpp.Deal_Registration_Number__c))];


            if (!opptyAndDRList.isEmpty()){
                for (Deal_Registration__c deal : opptyAndDRList){
                    drNameAndDRMap.put(deal.Name, deal);
                }
            }
            List<String> profileWithAccessSet = System.Label.DealRegProfileIds.split(';');
            Integer dealOppTimeDiff = selOpp.CreatedDate.Date().daysBetween(currDealReg.Deal_Reg_Submitted_Date__c.Date()); //PRIT26-358 - removed Math.abs and reversed the dates : new logic opp date - deal date
            Boolean isGSINDA = currDealReg.GSI_NDA__c && currDealReg.Deal_Registration_Status__c == 'Escalated' && currDealReg.Deal_Registration_Sub_Status__c == 'GSI-NDA Pending Approval';
            //PRIT25-17-start
            drOppData.opp = selOpp;
            //PRIT25-17-end
            //Closed Opp
            if (selOpp != null && selOpp.StageName.contains('7 Closed')){
                drOppData.message = selOpp.StageName;
            }
            //PRIT26-329 Block Renewals from being linked during Deal Registration approvalsp
            else if(selOpp != null && !selOpp.RecordType.Name.contains('Sales')){
                drOppData.message = selOpp.RecordType.Name;
            }
            //Alliance Stage 6
            else if (selOpp != null && selOpp.StageName.contains('6 PO With Channel') && currDealReg.RecordTypeId == AllianceRecordTypeId){
                drOppData.message = selOpp.StageName;
            }
            //Account Mismatch
            //prit24-741-start
            else if (selOpp != null && currDealReg.Company_Name__c != selOpp.AccountId && !currDealReg.Dedicated_Managed_Service__c){
                //check if msp checkbox is false
                drOppData.message = OppAccountMismatch;
            }
            //new else if = + add another OR condition(msp true and accountname == sdp account user lookup on opty)
            else if (currDealReg.Dedicated_Managed_Service__c && currDealReg.Company_Name__c != selOpp.MSP_End_User_Lookup__c){
                drOppData.message = OppDRMSP;
            }
            //prit24-741-end
            else if(selOpp.Distributor_Lookup__c != currDealReg.Partner_Lookup__r.Distributor__c 
                    && currDealReg.Partner_Lookup__r.Distributor__c != null && selOpp.Distributor_Lookup__c != null  
                    && !profileWithAccessSet.contains(UserInfo.getProfileId()) && selOpp.Account.BillingCountryCode == 'US' 
                    && !selOpp.ETM_Area__c.contains('SLED') && !selOpp.ETM_Area__c.contains('FED') 
                    && selOpp.ETM_Theatre__c.contains('EMEA') && currDealReg.RecordTypeId == ResellerRecordTypeId){
                drOppData.message = OppDistriError;
            }
            else if(currDealReg.RecordTypeId == ResellerRecordTypeId 
                    && (currDealReg.Distributor__c == null || (selOpp.Distributor_Lookup__c != currDealReg.Distributor__c && selOpp.Distributor_Lookup__c != null ))) {
                drOppData.message = OppDistriMisMatchError;
            }
            //PRIT26-520
            else if (selOpp != null && currDealReg.Deal_Reg_Submitted_Date__c != null &&
                     selOpp.IsClosed == false && selOpp.StageName != '6 PO With Channel' &&
                     currDealReg.Deal_Reg_Submitted_Date__c.Date() <= selOpp.CreatedDate.Date() && selOpp.Account.RecordType.DeveloperName == 'Customer_Prospect'&& opptyAndDRList.isEmpty()) {        
                   drOppData.message = DealTypeAutoSetMsg;
            }
            //DR - No Time Violation - Opp PSNL Eligible - New Logo
            else if (selOpp != null && (selOpp.StageName == '0 Nurture' || selOpp.StageName == '1 Discovery' || selOpp.StageName == '2 Consensus') 
                     && selOpp.PSNL_Eligible__c && ((selOpp.Opportunity_Type__c == 'New Customer') || (selOpp.Opportunity_Type__c == 'Existing Customer' && currDealReg.Dedicated_Managed_Service__c))
                     && currDealReg.Registration_Type__c == 'Partner Sourced' && dealOppTimeDiff <= 30 
                     && ((selOpp.Deal_Registration_Number__c == null && selOpp.Deal_Reg_Approval_Status__c == null && opptyAndDRList.isEmpty()) || currDealReg.RecordTypeId == OEMRecordTypeId || (currDealReg.RecordTypeId == AllianceRecordTypeId && currDealReg.Alliance_Type__c == 'Security'))){
                drOppData.message = Opp30DayDuration;
            }
            //DR - No Time Violation - Opp PSNL Eligible - PS Expand
            else if (selOpp != null 
                     && (selOpp.StageName == '0 Nurture' || selOpp.StageName == '1 Discovery' || selOpp.StageName == '2 Consensus') 
                     && selOpp.RecordType.Name == 'Sales Opportunity' && selOpp.Opportunity_Type__c == 'Existing Customer' 
                     && currDealReg.Registration_Type__c == 'Partner Sourced' && dealOppTimeDiff <= 30 
                     && ((selOpp.Deal_Registration_Number__c == null && selOpp.Deal_Reg_Approval_Status__c == null && opptyAndDRList.isEmpty()) || currDealReg.RecordTypeId == OEMRecordTypeId || (currDealReg.RecordTypeId == AllianceRecordTypeId && currDealReg.Alliance_Type__c == 'Security'))){ //PRIT26-358 Removed Value Add, added Partner Sourced
                drOppData.message = OppPSExpand;
            }
            //prit25-17-start
            else if (!isGSINDA && selOpp != null && !selOpp.StageName.contains('7 Closed') && selOpp.PSNL_Eligible__c && dealOppTimeDiff <= 90 && ((selOpp.Deal_Registration_Number__c == null && selOpp.Deal_Reg_Approval_Status__c == null && opptyAndDRList.isEmpty()) || currDealReg.RecordTypeId == OEMRecordTypeId || (currDealReg.RecordTypeId == AllianceRecordTypeId && currDealReg.Alliance_Type__c == 'Security'))){
                drOppData.message = DRPSEscalation;
            }
            //prit25-17-end
            //DR - Time/Stage Violation/Not PSNL Eligible/Value Add
            else if (selOpp != null && selOpp.Deal_Registration_Number__c == null && selOpp.Deal_Reg_Approval_Status__c == null 
                     && ((selOpp.StageName != '0 Nurture' && selOpp.StageName != '1 Discovery' && selOpp.StageName != '2 Consensus') || dealOppTimeDiff > 30 || !selOpp.PSNL_Eligible__c) && opptyAndDRList.isEmpty()){
                drOppData.message = OppTimeViolationORNotStage1OR2;
            }
            
            //DR - Replace Expired DR with New DR
            else if (opptyAndDRList.isEmpty() && selOpp != null && selOpp.Deal_Registration_Number__c != null 
                     && selOpp.Deal_Reg_Approval_Status__c == 'Expired' && drNameAndDRMap.get(selOpp.Deal_Registration_Number__c) != null 
                     && ((drNameAndDRMap.get(selOpp.Deal_Registration_Number__c).RecordTypeId == ResellerRecordTypeId && currDealReg.RecordTypeId == ResellerRecordTypeId && currDealReg.Partner_Lookup__c == selOpp.Partner_Lookup__c) 
                         || (drNameAndDRMap.get(selOpp.Deal_Registration_Number__c).RecordTypeId == AllianceRecordTypeId && currDealReg.RecordTypeId == AllianceRecordTypeId && currDealReg.Partner_Lookup__c != '' && selOpp.Alliance_Partner_Name__c != null && selOpp.Alliance_Partner_Name__c.contains('Microsoft')))){
                drOppData.message = NoDealExists;
            }
            //DR -  Reseller Deal Exists
            else if (!drNameAndDRMap.isEmpty() && currDealReg.RecordTypeId == ResellerRecordTypeId && selOpp.Deal_Registration__c && selOpp.Deal_Registration_Number__c == drNameAndDRMap.get(selOpp.Deal_Registration_Number__c).Name && selOpp.Deal_Reg_Approval_Status__c == 'Approved' && drNameAndDRMap.get(selOpp.Deal_Registration_Number__c).RecordTypeId == ResellerRecordTypeId){
                drOppData.message = ResellerDealExists;
            } else{
                drOppData.message = AllowDRAssociation;
            }
            return drOppData;
        } catch (Exception e){
            system.debug(LoggingLevel.DEBUG,'exception->'+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        
    }

    /**
     * @description Wrapper class for throwing Message when Oppty is attached to DR PRIT25-17
     */
    public class AttachDROpptyWrapper{
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Opportunity opp;

    }

    /**
    * @description Creates a DR_PS_Escalation__c record based on a given Deal Registration and Opportunity.
    * @param drObj SObject of type Deal_Registration__c on which the escalation is to be created.
    * @param oppObj SObject of type Opportunity to be associated with the escalation.
    * @param escType Type of escalation being created.
    * @return The newly created DR_PS_Escalation__c record.
    */
    @AuraEnabled
    public static DR_PS_Escalation__c createEscalation(SObject drObj, SObject oppObj, String escType){
        Opportunity opp = (Opportunity)oppObj;
        Deal_Registration__c deal = (Deal_Registration__c)drObj;
        DR_PS_Escalation__c escObj = new DR_PS_Escalation__c();
        escObj.Team__c = 'GSI';
        escObj.Escalation_Type__c = escType;
        escObj.Status__c = 'Submitted';
        escObj.Deal_Reg_AE__c = opp.OwnerId;
        escObj.Existing_Opportunity__c = opp.Id;
        escObj.Opportunity_ACV__c = opp.ACV_Amount__c;
        escObj.Opportunity_Stage__c = opp.StageName;
        escObj.Deal_Registration__c = deal.Id;
        escObj.Deal_Initiated_Type__c = deal.Deal_Registration_Type__c;
        escObj.End_User_Account__c = deal.Company_Name__c;
        escObj.Partner_Lookup__c = deal.Partner_Lookup__c;
        escObj.RVP__c = deal.Theatre_VP__c;
        escObj.CDM__c = deal.CDM__c;
        escObj.Requester_Manager__c = UserInfo.getUserId();
        escObj.Escalation_Reason__c = 'Pre-DR Approval Escalation';
        insert escObj;
        return escObj;
    }
	
    /**
    * @description Extends the Deal Registration Expiration Date by 45 days if eligible.
    * @param drObj SObject of type Deal_Registration__c to be updated.
    * @return 'success' if the operation is completed, otherwise the exception message.
    * @throws Exception if any unexpected error occurs.
    * @jira PRIT25-342
    */
    @AuraEnabled
    public static String extendDealRegistrationExpiration(SObject drObj){
        try{
            Deal_Registration__c deal = (Deal_Registration__c)drObj;
            if(deal.Deal_Registration_Status__c == 'Expired'){
                deal.Deal_Reg_Exp_Date__c = Date.today().addDays(45);
            }else if(deal.Deal_Registration_Status__c == 'Approved'){
                Date newDate = deal.Deal_Registration_Expiration__c.addDays(45);
                deal.Deal_Reg_Exp_Date__c = newDate;
            }
            update deal;

            return 'success';
        }catch(exception e){
            return e.getMessage();
        }
    }
}