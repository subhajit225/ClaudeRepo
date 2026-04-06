/**
 * @Author      :  Saakshi Gupta
 * @CreatedDate :   14-01-2022
 * @Description : Controller for retrieving Account, Case and Cluster data based on the source record and
 *                       Lightning aura component CS_InsightMatchesComponent
 * @TestClass   : CS_InsightMatchesControllerTest.cls
 * ------------------------------------------------- @History --------------------------------------------------------------------------
 * Story Number       Modified By              Date                             Description
 * CS-774            Saakshi Gupta          14-01-2022     Displaying Status Icon (aka Focus) on Account/Cluster/Case objects
 * CS21-926          Vijay Kumar K R        June 22, 2022  SentryAI Focus Enhancement: Missing Cluster UUID in a case
 * CS21-1057         Vijay Kumar K R        Aug 09, 2022   SentryAI Focus Enhancement #2: Identifying Focus with Proactive cases created
 * -------------------------------------------------------------------------------------------------------------------------------------
 */
public class CS_InsightMatchesController {

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-01-2022
    * @Description  :   This method fetches Insight Matches and Insight Matches Updated fields from Account and Cluster
    *                   objects as source objects as well on Case linked with them
    */
    @AuraEnabled
    public static InsightMatchesWrapper getInsightMatchesWrapper(Id recordId, String sourceObject){
        String queryString = '';

        //Generate query string if component or page is opened on Account record
        if(sourceObject.equalsIgnoreCase('Account')){
            queryString = 'SELECT Id, Insight_Matches__c, Insight_Matches_Updated__c FROM Account WHERE Id =: recordId';
        }
        //Generate query string if component or page is opened on Cluster record
        else if(sourceObject.equalsIgnoreCase('Cluster__c')){
            queryString = 'SELECT Id, Insight_Matches__c, Insight_Matches_Updated__c FROM Cluster__c WHERE Id =: recordId';
        }
        //Generate query string if component or page is opened on Case record
        else if(sourceObject.equalsIgnoreCase('Case')){
            queryString = 'SELECT Id, Account.Insight_Matches__c, Account.Insight_Matches_Updated__c,' +
                 			'Cluster__r.Insight_Matches__c, Cluster__r.Insight_Matches_Updated__c ' +
                 			'FROM Case WHERE Id =: recordId';
        }

        List<sObject> s = Database.query(queryString);
        InsightMatchesWrapper insightMatchesList = new InsightMatchesWrapper();
        List<InsightMatch> wrapperList = new List<InsightMatch>();

        //This section processes on Account and Cluster record since the fields are directly fetched from these objects
        if(sourceObject.equalsIgnoreCase('Account') || sourceObject.equalsIgnoreCase('Cluster__c')){
            //Get the Insight matches field value
            String insightMatches = (String)s[0].get('Insight_Matches__c');

            //Proceed only if the insight matches is not empty
            if(!String.isBlank(insightMatches)){
                //Parse the json value in Insight matches field to a wrapper list
                wrapperList = (List<InsightMatch>)JSON.deserialize(insightMatches, List<InsightMatch>.class);

                //Retrieve Insight matches updated data time value
                DateTime insightMatchesUpdateTime = (Datetime)s[0].get('Insight_Matches_Updated__c');

                //Create a wrapper object with the fields data
                if(insightMatchesUpdateTime != null){
                    //Create a wrapper object if the source object is Account
                    if(sourceObject.equalsIgnoreCase('Account')){
                        insightMatchesList = new InsightMatchesWrapper(insightMatchesUpdateTime.format(), null, 0, wrapperList);
                    }
                    //Create a wrapper object if the source object is Cluster
                    else{
                        insightMatchesList = new InsightMatchesWrapper(null, insightMatchesUpdateTime.format(), 0, wrapperList);
                    }
                }
                //Create a wrapper object with the fields data if Insight matches udpated date time field is empty
                else{
                    insightMatchesList = new InsightMatchesWrapper(null, null, 0, wrapperList);
                }
            }
        }

        //This section processes on Case record since the fields are fetched via relationships
        else if(sourceObject.equalsIgnoreCase('Case')){
            DateTime accountFocusUpdatedTime, clusterFocusUpdatedTime;
            String accountFocusUpdated = '', clusterFocusUpdated = '';
            Integer accountClustersCount = 0;

            //Store Insight matches field from Account
            String insightMatches = (String)(((Case)s[0]).Account.Insight_Matches__c);
            if(!String.isBlank(insightMatches)){
                //Parse the json value in Insight matches field to a wrapper list
                wrapperList = (List<InsightMatch>)JSON.deserialize(insightMatches, List<InsightMatch>.class);

                //Retrieve Insight matches updated date time value
                accountFocusUpdatedTime = (Datetime)(((Case)s[0]).Account.Insight_Matches_Updated__c);
                if(accountFocusUpdatedTime != null){
                    accountFocusUpdated = accountFocusUpdatedTime.format();
                }
            }

            //Store Insight matches field from Cluster
            insightMatches = (String)(((Case)s[0]).Cluster__r.Insight_Matches__c);
            if(!String.isBlank(insightMatches)){
                //Parse the json value in Insight matches field to the same wrapper list used above
                wrapperList.addAll((List<InsightMatch>)JSON.deserialize(insightMatches, List<InsightMatch>.class));

                //Retrieve Insight matches updated date time value
                clusterFocusUpdatedTime = (Datetime)(((Case)s[0]).Cluster__r.Insight_Matches_Updated__c);
                if(clusterFocusUpdatedTime != null){
                    clusterFocusUpdated = clusterFocusUpdatedTime.format();
                }
            }
            // If No Case.Cluster
            else if(((Case)s[0]).Cluster__c == null){
                accountClustersCount = getAccountClusters(((Case)s[0]).AccountId);
            }

            insightMatchesList = new InsightMatchesWrapper(accountFocusUpdated, clusterFocusUpdated, accountClustersCount, wrapperList);
        }

        return insightMatchesList;
    }

    /*
    * @Author       :   Vijay Kumar K R
    * @CreatedDate  :   June 22, 2022
    * @return       :   Integer
    * @Jira Ticket  :   CS21-926: SentryAI Focus Enhancement: Missing Cluster UUID in a case
    * @Description  :   This method will return count of Clusters related to Case.Account
    */
    public static integer getAccountClusters(String accId){
        return [SELECT count() 
                FROM Cluster__c 
                WHERE Account__c =: accId
                AND Insight_Matches_Updated__c != null];
    }
    
    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-01-2022
    * @Jira Ticket  :   CS-774 - Displaying Status Icon (aka Focus) on Account/Cluster/Case objects
    * @Description  :   This wrapper class stores the collated result of Insight matches and Insight matches upated
    */
    public Class InsightMatchesWrapper{
        @AuraEnabled 
        public String accountfocusUpdatedDate {get; set;}
        @AuraEnabled 
        public String clusterfocusUpdatedDate {get; set;}
        @AuraEnabled 
        public Integer accountClustersCount {get; set;}
        @AuraEnabled 
        public List<InsightMatch> insightMatchesList {get; set;}

        public InsightMatchesWrapper(String accountfocusUpdatedDate, String clusterfocusUpdatedDate, Integer accountClustersCount, List<InsightMatch> insightMatchesList){
            this.accountfocusUpdatedDate = accountfocusUpdatedDate;
            this.clusterfocusUpdatedDate = clusterfocusUpdatedDate;
            this.accountClustersCount = accountClustersCount;
            this.insightMatchesList = insightMatchesList;
        }

        public InsightMatchesWrapper(){}
    }

    /*
    * @Author       :   Saakshi Gupta
    * @CreatedDate  :   14-01-2022
    * @Jira Ticket  :   CS-774 - Displaying Status Icon (aka Focus) on Account/Cluster/Case objects
    * @Description  :   This wrapper class stores parsed data from Insight matches field
    */
    public Class InsightMatch{
        @AuraEnabled 
        public List<String> organizations {get; set;}
        @AuraEnabled 
        public String severity {get; set;}
        @AuraEnabled 
        public String insight_id {get; set;}
        @AuraEnabled 
        public String match_level {get; set;}
        @AuraEnabled 
        public String insight_title {get; set;}
        @AuraEnabled 
        public String insight_key {get; set;}
        @AuraEnabled 
        public String tooltip {get; set;}
        @AuraEnabled 
        public Boolean customer_facing {get; set;}
        // CS21-1057: Identifying Focus with Proactive cases
        @AuraEnabled 
        public Boolean proactive {get; set;}

        public InsightMatch(){
            this.organizations = new List<String>();
            this.severity = '';
            this.insight_id = '';
            this.match_level = '';
            this.insight_title = '';
            this.insight_key = '';
            this.tooltip = '';
            this.customer_facing = false;
            this.proactive = false;
        }
    }
}