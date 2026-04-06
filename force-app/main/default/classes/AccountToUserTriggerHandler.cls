/**
 * @Author      :  
 * @CreatedDate : 
 * @TstClass    : AccountToUserTriggerTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * SAL24-679
 * -------------------------------------------------------------------------
 */
public class AccountToUserTriggerHandler extends TriggerHandler {
    private Boolean isDisabled = false;
    public AccountToUserTriggerHandler() {
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_AccountToUser_Triggers__c;
    }
    public override void beforeInsert() {
        if(!isDisabled) {
            for(Account_To_Users__c atu : (List<Account_To_Users__c>) Trigger.new) {
                atu.Unique_Identifier__c = atu.Account__c + '-' + atu.User__c + '-' + atu.Relationship_Type__c;
                atu.Sync_NationalPartnerManager__c = TRUE;
            }
        }
    }
    public override void beforeUpdate() {
        if(!isDisabled) {
            for(Account_To_Users__c atu : (List<Account_To_Users__c>) Trigger.new) {
                atu.Unique_Identifier__c = atu.Account__c + '-' + atu.User__c + '-' + atu.Relationship_Type__c;
                Account_To_Users__c oldATU = (Account_To_Users__c) Trigger.oldMap.get(atu.Id);
                if(atu.Relationship_Type__c == 'National Partner Manager' && (atu.User__c != oldATU.User__c || atu.Disable_Account_User_Relationship__c != oldATU.Disable_Account_User_Relationship__c))  {
                    if(atu.User__c != oldATU.User__c) atu.Old_User__c = oldATU.User__c;
                    atu.Sync_NationalPartnerManager__c = TRUE;
                }
            }
        }
    }
    public override void beforeDelete() {
        if(!isDisabled && UserInfo.getProfileId() != Label.AdminProfileID) {
            for(Account_To_Users__c atu : (List<Account_To_Users__c>) Trigger.old) {
                atu.addError('Account To User Record can not be deleted. Please use Disable Account User Relationship field or reach out to IT Admin for help.');
            }
        }
    }
}