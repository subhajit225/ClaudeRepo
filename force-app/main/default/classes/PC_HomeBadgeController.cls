/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community - HomePageBadge components controller.
*******************************************************************************************************/
public with sharing class PC_HomeBadgeController {
    
    /*******************************************************************************************************
* @description Returns User record
* @param N/A
* @return the DealReg Count, Training Badges, Marketing Badges by logged in user.
***********************************************************************************************************/
    @AuraEnabled
    Public Static Map<String,Integer> getDealRegCount(){
        Map<String,Integer> mapBadges = new Map<String,Integer>();
        Integer dealRegCount = 0;
        Integer trainingsCount = 0;
        Integer marketingBadges = 0;
        
        User loggedInUser = [select Id,Name,Contact.Account.Type,Contact.AccountId, AccountId,Userrole.Name from User where Id =: userinfo.getUserId()];
        
        //dealRegCount =  [Select Count() from Deal_Registration__c];
        dealRegCount =  [Select Count() from Deal_Registration__c where createdById =: UserInfo.getUserId()];
        trainingsCount = [Select count() from DOCEBO2_CO__c 
                          where User__c =: UserInfo.getUserId() and C_DC_COURSE_STATUS__c ='COMPLETED'];
        marketingBadges =  [Select Count() from Campaign where Campaign_Partner__c =: loggedInUser.Contact.AccountId];
        
        mapBadges.put('dealsRegBadges',dealRegCount);
        mapBadges.put('trainingBadges',trainingsCount);
        mapBadges.put('marketingBadges',marketingBadges);
        
        return mapBadges;
    }
}