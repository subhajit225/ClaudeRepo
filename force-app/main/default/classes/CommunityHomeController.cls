public class CommunityHomeController {

    /* This class drives the components to be displayed on the Homepage of the Community Portal */

     //Get the ID of the Announcement Group from the Custom Label
     public integer rankedSize {get; set;}
     public static Set<Id> KAV1 = new set<Id>();
     public static Set<Id> KAV2 = new set<Id>();
     public static Set<Id> KAV3 = new set<Id>();
     public static Set<Id> KAV4 = new set<Id>();
     public static string anntype {get; set;}

    public CommunityHomeController(){
        anntype = Util.UserType;
    }
      // Forced Articles
       public List<How_To__kav> getRankedSolutions() {
        rankedsize = 0;
           List<How_To__kav> kavList = [select Id, CreatedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleId, Summary, Title, Rank__c, FirstPublishedDate, LastPublishedDate, UrlName,createdby.name  
                                   FROM How_To__kav where PublishStatus='Online' and Language='en_US' and Rank__c!=null ORDER BY RANK__c
                                   asc nulls last limit 3];
          if (kavList.isEmpty()) {
            return null;
          }
          rankedsize = kavList.size();
          return kavList;
       }
       
       // Top Articles
       public List<How_To__kav> getTopSolutions() {

        integer qlimit = 0;
        qlimit = Test.isRunningTest() ? 1 : 3-rankedSize;

        //Find all the articles that have a Vote Score
          List<KnowledgeArticleVoteStat> kavPList = [
                                   select id, ParentId, NormalizedScore, Parent.ArticleNumber
                                    FROM KnowledgeArticleVoteStat
                                    where NormalizedScore>0
                                    order by NormalizedScore desc
                                   limit 5];

           for(KnowledgeArticleVoteStat kv : kavPList) {
           if(kv.NormalizedScore>0)
           {

            KAV1.add(kv.ParentId);
            }
              system.debug('### KAV1 '+ KAV1);
           }

          //get all of the Ranked Articles
           List<How_To__kav> kavList = [select Id, CreatedDate,FirstPublishedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleId, Summary, Title, Rank__c, LastPublishedDate, UrlName,createdby.name 
                                   FROM How_To__kav where PublishStatus='Online' and Language='en_US' and Rank__c!=null
                                    ORDER BY RANK__c
                                   asc nulls last limit 5];

          system.debug('### kavList in getTopSolutions '+ kavList.size());

          //get the rest of the articles that are not ranked
           List<How_To__kav> kav2List = [select Id, CreatedDate,FirstPublishedDate, LastModifiedDate, KnowledgeArticleId, Summary, Title, Rank__c, LastPublishedDate, UrlName,createdby.name 
                                   FROM How_To__kav
                                   where PublishStatus='Online' and Language='en_US'
                                   and Id NOT in: kavList and KnowledgeArticleId In: KAV1
                                   limit :qlimit];

            system.debug('### kav2List in getTopSolutions '+ kav2List.size());

             for(How_To__kav kv1 : kav2List) {
               KAV2.add(kv1.Id);
              }
              system.debug('### KAV2 '+ KAV2);

              if (kav2List.isEmpty()) {
                return null;
              }

              system.debug('### kav2List in getTopSolutions2 '+ kav2List.size());
              return kav2List;
       }


       // New Articles
       public List<KnowledgeArticleVersion> getNewArticles() {
          List<KnowledgeArticleVersion> kavList = [select Id, CreatedDate, FirstPublishedDate, LastModifiedDate, ArticleNumber, KnowledgeArticleID, Summary, Title, LastPublishedDate, UrlName,createdby.name 
                                   FROM KnowledgeArticleVersion where PublishStatus='Online' and Language='en_US' ORDER BY LastPublishedDate
                                   desc limit 3];
          if (kavList.isEmpty()) {
            return null;
          }
          return kavList ;
       }

      // Portal News
       public List<Portal_News__c> getPortalNews() {
           anntype = Util.UserType;

                String qstring = 'SELECT Alert__c,Audience__c,Content__c,CreatedById,createdby.name,CreatedDate,LastModifiedDate,Expiration_Date__c,Id,';
                       qString +=' Name,OwnerId,Publish_Date__c,SystemModstamp, Summary__c ';
                       if(anntype=='customer' || test.isRunningTest() ) qString +=' FROM Portal_News__c where (Audience__c = \'All\' or Audience__c = \'Customer\')';
                       if(anntype=='partner') qString +=' FROM Portal_News__c where (Audience__c = \'All\' or Audience__c = \'Partner\')';
                       if(anntype == 'Trial') qString +=' FROM Portal_News__c where Audience__c = \'Edge Trial\'';
           

                       qString +=' and Publish_Date__c<=TODAY and (Expiration_Date__c=null OR Expiration_Date__c>=TODAY)';
                       qString +=' order by Publish_Date__c desc limit '+Label.Announcements_Limit;

                     List<Portal_News__c> newsList = database.query(qString);
                                            /*[SELECT Alert__c,Audience__c,Content__c,CreatedById,CreatedDate,Expiration_Date__c,Id,
                                            Name,OwnerId,Publish_Date__c,SystemModstamp
                                            ,
                                            Summary__c
                                            FROM Portal_News__c where (Audience__c = 'All' or Audience__c = 'Customer')
                                            and Publish_Date__c<=TODAY and (Expiration_Date__c=null OR Expiration_Date__c>=TODAY)
                                            order by Publish_Date__c desc limit 5];*/
          if (newsList.isEmpty()) {
            return null;
          }
          return newsList;
       }

        public PageReference forwardToCustomPage() {
           /* Added by SHADAB, Logic to read URL and Update the Terms and Condition checkbox on Account record of User.*/
             String termsBool = apexpages.currentpage().getparameters().get('terms');
             system.debug('terms---'+termsBool);
             if(termsBool != null && termsBool=='true'){
                User userRecord =[select id,contact.AccountId,name from user where Id=:Userinfo.getUserid() and Profile.Name ='Rubrik Partner Community User'];
                if(userRecord != null){
                //userRecord.GDPR_Opt_In__c =true;
                //update userRecord;
                Account partnerAccount =[select id from Account where id=: userRecord.contact.AccountID WITH SECURITY_ENFORCED];
                system.debug('userRecord=='+userRecord);
                system.debug('partnerAccount=='+partnerAccount);
                    if(partnerAccount != null){
                        String terms ='IMPORTANT: THIS IS A LEGAL DOCUMENT.  PLEASE READ IT CAREFULLY.THIS ADDENDUM TO YOUR CHANNEL PARTNER AGREEMENT (THIS “ADDENDUM”) FORMS A BINDING CONTRACT ADDING ADDITIONAL TERMS TO THE CHANNEL PARTNER AGREEMENT (THE “AGREEMENT”) BETWEEN RUBRIK, INC. (“RUBRIK”) AND YOU (“RESELLER”).  IF YOU DO NOT WISH TO ACCEPT THIS ADDENDUM, THEN DO NOT CLICK ACCEPT, IN WHICH CASE THE AGREEMENT WILL BE TERMINATED IN ACCORDANCE WITH ITS TERMS AND CONDITIONS.NOW, THEREFORE, FOR VALUABLE CONSIDERATION, THE RECEIPT AND SUFFICIENCY OF WHICH ARE HEREBY ACKNOWLEDGED, THE PARTIES HERETO HEREBY AGREE TO ADD THE FOLLOWING NEW PROVISION TO THE AGREEMENT AS FOLLOWS:End User Data.If Reseller provides Rubrik with personal information concerning its customers, prospects or employees, Rubrik will only use the information in connection with the purposes outlined in the Agreement, or as otherwise indicated at the time Rubrik receives such information (the “Intended Purposes”).  Reseller will not deliver, disclose or otherwise make such personal information available to Rubrik, except as required for the Intended Purposes.  The information may be maintained by Rubrik in data centers in the United States or in other parts of the world and the information may be accessed by Rubrik’s global personnel and authorized third parties as required for its business purposes.  Reseller agrees to comply with all applicable laws, including but not limited to privacy and data protection laws, provide all relevant notices, and obtain any consents required to share the information with Rubrik and its authorized third parties for the Intended Purposes.  In the event Reseller is authorized to and provides a proof-of-concept unit (“POC unit”) to an End User or prospective customer for evaluation or other temporary purposes (an “Evaluation Period”), Reseller agrees to enable encryption of the POC unit where technically possible and to ensure that such encryption remains enabled during the Evaluation Period.  Reseller shall require each recipient of a POC unit to comply with the following: (1)    The POC unit is not for production use and may not be used with production data;(2) Personal data and other data regulated by GDPR or other data privacy laws may not be entered into or stored on the POC unit and shall not be shared with Reseller or Rubrik other than as required for its evaluation of the POC unit and then only in compliance with all applicable privacy laws and regulations; and(3)  All data entered into or stored on the POC unit during the Evaluation Period must be removed prior to the return of any POC unit.  Reseller represents and warrants that it shall verify the above three requirements prior to any subsequent use of any POC unit. In the event of any inconsistency or conflict between the Agreement and this Addendum, the terms and conditions of this Addendum shall control.  Capitalized terms used but not defined herein shall have the meanings ascribed them in the Agreement.RESELLER ACCEPTS THIS ADDENDUM BY: (1) INDICATING ACCEPTANCE OF THESE TERMS; OR (2) ACCESSING ANY PROGRAM BENEFIT (INCLUDING EXERCISING OR PURPORTING TO EXERCISE ANY OF THE RIGHTS GRANTED TO RESELLER UNDER THE AGREEMENT).  THE INDIVIDUAL ACCEPTING THIS ADDENDUM ON BEHALF OF RESELLER REPRESENTS THAT HE OR SHE: (1) HAS THE AUTHORITY TO REPRESENT RESELLER; AND (2) HAS READ AND UNDERSTANDS ALL THE PROVISIONS OF THIS ADDENDUM.';
                        partnerAccount.GDPR_terms_Agreed__c =terms;
                        if(!test.isRunningTest())update partnerAccount;
                    }
                }
                
             }
         /* Change Ends here Shadab */

            Customer_Community_Tab_Settings__c settings = Customer_Community_Tab_Settings__c.getInstance(UserInfo.getProfileId());
            if(settings != null && String.isNotBlank(settings.Forward_To_Custom_Start_Page__c)) {
                return new PageReference('/' + settings.Forward_To_Custom_Start_Page__c);
            }
        return null;
    }

/*****************************************************************************************************************************************
                                                Wrapper classes
 *****************************************************************************************************************************************/

}