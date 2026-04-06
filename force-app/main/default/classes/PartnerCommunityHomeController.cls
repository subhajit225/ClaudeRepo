public class PartnerCommunityHomeController {

    /* This class drives the components to be displayed on the Homepage of the Partner Community Portal */  

      // Webinars
       public List<ContentVersion> getWebinars() {
                     List<ContentVersion> webinarFinalList = [select OwnerId, Title, TagCsv, ContentDocumentId,
                    						CreatedBy.Name, 
                                            FileType, CreatedDate, FeaturedContentDate from ContentVersion 
                                            where  IsLatest=true and FeaturedContentBoost>0
                                            and Content_Type__c ='Webinar'
                                            order by FeaturedContentDate desc
                                            LIMIT 5];
         
         if (webinarFinalList.isEmpty()) {
            return null;
          } 
          
          return webinarFinalList;
       }
       
       
          // Webinars
       public List<ContentVersion> getCampaigns() {
           List<String> tags = new List<String>();
           
           List<ContentVersion> campaignList = [select OwnerId, Title, TagCsv, ContentDocumentId, 
           									CreatedBy.Name,
                                            FileType, CreatedDate from ContentVersion 
                                            where  IsLatest=true 
                                             and ContentDocument.ParentId =:label.marketingworkspace 
                                             and Content_Type__c ='Campaign'
                                            ];

         if (campaignList.isEmpty()) {
            return null;
          } 
          
          return campaignList;
       }

      // Incentives
       public List<Incentives__c> getIncentives() {
           List<Incentives__c> incentiveList = [select Id, Name, End__c, Start__c
                                              from Incentives__c
                                              where Start__c<=TODAY and End__c>TODAY
                                              LIMIT 5];

          if (incentiveList.isEmpty()) {
            return null;
          } 
          return incentiveList;
       }

 
}