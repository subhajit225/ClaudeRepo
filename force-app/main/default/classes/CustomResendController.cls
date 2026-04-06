/***********************************************************************************************************
 * Class Name           : CustomResendController
 * Date Created/Modified: 11/03/2026
 * Author               : RAHUL KAPPA
 * @description         : This class is controller for CustomResendRequest VF Page                  
 /**********************************************************************************************************/
public class CustomResendController {
    /**
    * @description disableButton
    */
	public Boolean disableButton {get;set;}
    /**
    * @description comments
    */
    public String comments {get;set;}
    /**
    * @description approvalId
    */
    public Id approvalId;
    /**
    * @description appRecord
    */
    public sbaa__Approval__c appRecord;

/***********************************************************************************************************
 * Method Name           : CustomResendController
 * Date Created/Modified: 11/03/2026
 * Author               : RAHUL KAPPA
 * @description         : constructor
 * @param	sc			              
 /**********************************************************************************************************/
    public CustomResendController(ApexPages.StandardController sc){
        approvalId = sc.getId();
        sbaa__Approval__c ac = [SELECT Id, 	Quote__c, sbaa__Rule__c,sbaa__Approver__c,sbaa__Status__c,sbaa__CommentsLong__c FROM sbaa__Approval__c WHERE Id = :approvalId LIMIT 1];
        appRecord  = ac;
    }
/***********************************************************************************************************
 * Method Name           : resendRequest
 * Date Created/Modified: 11/03/2026
 * Author               : RAHUL KAPPA
 * @description         : method for resend request   
 * @return				:  PageReference             
 /**********************************************************************************************************/
    public PageReference resendRequest(){
        disableButton = true;
        if(comments != null){
            appRecord.sbaa__CommentsLong__c = comments;
            try{ 
                update appRecord;
            }catch(exception e){
                system.debug(LOGGINGLEVEL.DEBUG, 'exception found in CustomResendController '+e);
            }
            
        }
        List<sbaa__Approval__c> appList = new List<sbaa__Approval__c>{appRecord};
        AutoApproveQueueable.smartApprovePendingEmail.add(appRecord.Id);
        AutoApproveQueueable.sendEmailForSmartApprovals(appList);
        PageReference pr = new PageReference('/' + appRecord.Quote__c);
        pr.setRedirect(true);
        return pr;
    }
/***********************************************************************************************************
 * Method Name           : cancel
 * Date Created/Modified: 11/03/2026
 * Author               : RAHUL KAPPA
 * @description         : Method for cancel button    
 * @return				:  PageReference             
 /**********************************************************************************************************/
    public PageReference cancel(){
        disableButton = true;
		PageReference pr = new PageReference('/' + appRecord.Quote__c);
        pr.setRedirect(true);
        return pr;
    }
}