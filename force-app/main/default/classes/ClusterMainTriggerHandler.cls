/**
 * @description :
 * @Author      : 
 * @CreatedDate : 
 * @TstClass    : ClusterMainTriggerTest
 * -------------------------- @History ------------------------------------- -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-2619          Vijay Kumar K R          Spe 4, 2024    End of Support (EOS) Notifications for Clusters Running CDM 8.1 (or earlier)
 * -------------------------------------------------------------------------
 */
public class ClusterMainTriggerHandler {
    public static void existingCode(List<Cluster__C> clusterList,Map<Id, Cluster__C> clusterOldMap){
        List<Id> contactIdsList = new List<Id>();
        List<Contact> updateContactIdsList = new List<Contact>();
        List<Id> updatedClusterIds =new  List<Id>();
        List<Id> updatedClusterAccountIds =new  List<Id>();
        Map<Id, Id> updatedClusterIdsMap =new  Map<Id, Id>();
        Map<Id, Id> updatedOppAccMap =new  Map<Id, Id>();
        Map<Id, Id> updatedOppContactRoleMap =new  Map<Id, Id>();
        for(Cluster__C cluster : clusterList){
            if( cluster.Enable_Email_Alert__c== true && clusterOldMap.get(cluster.id).Email_Sent_for_80_Consumption__c != cluster.Email_Sent_for_80_Consumption__c && cluster.Email_Sent_for_80_Consumption__c == true){
                system.debug('in iffff');
                updatedClusterAccountIds.add(cluster.Account__c);
                updatedClusterIdsMap.put(cluster.Id,cluster.Account__c);
                updatedClusterIds.add(cluster.Id);
            }
        }
        system.debug('updatedClusterAccountIds=='+updatedClusterAccountIds);
        for(Opportunity Opp : [SELECT Id, AccountId FROM Opportunity WHERE AccountId = :updatedClusterAccountIds ORDER BY CreatedDate DESC LIMIT 1]){
        //for(Account accts : [select id,name,(select id, Createddate ,name from Opportunities ORDER BY Createddate Desc) from Account where id in :updatedClusterAccountIds]){
            updatedOppAccMap.put(Opp.Accountid,Opp.id);
        }

        /*for(Opportunity oppty :  [select id, (Select ID,ContactID, isPrimary from OpportunityContactRole where isPrimary= true LIMIT 1) from Opportunity where Id IN :updatedOppAccMap.KeySet()] ){
            updatedOppContactRoleMap.put(oppty.Id,Oppty.OpportunityContactRole.ContactID);
        }*/

        for(OpportunityContactRole ocr : [SELECT Id, Contactid,OpportunityId FROM OpportunityContactRole WHERE OpportunityId in :updatedOppAccMap.Values() AND ispRimary = true]){
            //DO SOME WHIT OPPORTUNITY CONTACT ROLE
            updatedOppContactRoleMap.put(ocr.OpportunityId,ocr.ContactID);
        }
        System.debug('updatedOppContactRoleMap =='+ updatedOppContactRoleMap);

        for(Cluster__c clstr : [select id , name from Cluster__c where id IN: updatedClusterIds]){
            if(updatedClusterIdsMap.containsKey(clstr.ID)){
                contactIdsList.add(updatedOppContactRoleMap.get(updatedOppAccMap.get(updatedClusterIdsMap.get(clstr.ID))));
            }
        }
        System.debug('contactIdsList =='+ contactIdsList+'=== size--'+contactIdsList.size());

        for(Contact con: [select id, Lead_Source_Details__c, mkto2__Lead_Score__c from Contact where id IN: contactIdsList]){
            con.Lead_Source_Details__c='Capacity Alert';
            con.mkto2__Lead_Score__c =90;
            con.mkto71_Lead_Score__c =90;
            con.mkto_si__Last_Interesting_Moment_Date__c = System.Now();
            con.LeadSource ='Sales';
            updateContactIdsList.add(con);
        }
        if(!updateContactIdsList.isEmpty()){
            update updateContactIdsList;
        }
    }
    public static void clusterupdate(List<Cluster__C> clusterList,Map<Id, Cluster__C> clusterOldMap){
        List<ClusterAttribute__b> NewClusterAttributeList = new List<ClusterAttribute__b>();
        set<id> clusterIds = new set<id>();
        for(Cluster__C cluster : clusterList)
            if(clusterOldMap.get(cluster.id).software_version__c != cluster.software_version__c)
                clusterIds.add(cluster.id);

        if(clusterIds !=null && !clusterIds .isEmpty())
            createAttribute(clusterIds);
    }

    public static void clusterInsert(List<Cluster__C> clusterList){
        List<ClusterAttribute__b> NewClusterAttributeList = new List<ClusterAttribute__b>();
        set<id> clusterIds = new set<id>();
        for(Cluster__C cluster : clusterList)
            if(cluster.software_version__c != null)
                clusterIds.add(cluster.id);

        if(clusterIds !=null && !clusterIds .isEmpty())
            createAttribute(clusterIds);
    }

    @future
    public static void createAttribute(set<id> clusterids){
        List<ClusterAttribute__b> NewClusterAttributeList = new List<ClusterAttribute__b>();
        for(Cluster__C cluster : [select id,software_version__c from cluster__c where Id IN : clusterids]){
            ClusterAttribute__b NewClusterAttribute = new ClusterAttribute__b();
            NewClusterAttribute.Cluster__c = cluster.Id;
            NewClusterAttribute.Modification_time__c = system.now();
            NewClusterAttribute.Name__c = 'software_version__c';
            NewClusterAttribute.Value__c = cluster.software_version__c;
            NewClusterAttributeList.add(NewClusterAttribute);
        }
        if(!Test.isRunningTest())
            database.insertImmediate(NewClusterAttributeList);
    }

    /**
     * Author       :   Saakshi Gupta
     * CreatedDate  :   29th April 2021
     * Description  :   CS21-521 : The method checks if Insight Matches field was updated on Cluster by Sentry AI.
     *                  If yes, then it set the checkbox to true and time to now. The fields are then used in a
     *                  Workflow rule to trigger time based workflow.
    */
    public static void setInsightMatches(List<Cluster__c> newClusterList, Map<Id, Cluster__c> oldClusterMap){
        Cluster__c oldCluster;
        for(Cluster__c eachCluster : newClusterList){
            oldCluster = oldClusterMap.get(eachCluster.Id);
            if(!String.isBlank(eachCluster.Insight_Matches__c) && eachCluster.Insight_Matches_Updated__c != null && eachCluster.Insight_Matches_Updated__c != oldCluster.Insight_Matches_Updated__c){
                eachCluster.Is_Insight_Matches_Updated__c = true;
                eachCluster.Insight_Matches_Update_Time__c = System.now();
            }

            // CS21-2342: clusters are upgraded to supported releases (8.1 or higher for now), then we would like to automatically remove the snooze on these clusters
            Double cdmVersion = Double.valueOf(System.Label.Current_CDM_Version);
            Double clusterCdmVersion = eachCluster.software_version__c != null ? Double.valueOf(eachCluster.software_version__c.substring(0,3)) : null;   
            if(eachCluster.software_version__c != null
                && eachCluster.Reason_for_alerts_snooze__c != null
                && eachCluster.Reason_for_alerts_snooze__c.containsIgnoreCase('EOS')
                && eachCluster.software_version__c != oldCluster.software_version__c
                && clusterCdmVersion >= cdmVersion){
                    eachCluster.Snooze_Alerts_Until__c = null;
                    eachCluster.Reason_for_alerts_snooze__c = null;
            }
        }
    }

    /**
     * @description : CS21-2619 End of Support (EOS) Notifications for Clusters Running CDM 8.1 (or earlier)
     * @param newClusterList List of new Cluster records
     * @param oldClusterMap map of old Cluster records
     * @createdDate 4th Sept 2024
     * @author Vijay Kumar K R
    */
    public static void updateEndOfSupportFromAcc(List<Cluster__c> newClusterList, Map<Id, Cluster__c> oldClusterMap, Boolean isInsert){
        Set<String> softwareVersionSet = new Set<String>();
        for (Cluster__c objCluster : newClusterList) {

            Cluster__c oldCluster = isInsert ? null : oldClusterMap.get(objCluster.Id);
            // If the “Software Version” is changed
            if ((oldCluster != null && objCluster.Software_Version__c != oldCluster.Software_Version__c) || isInsert){
                // If the “Software Version” is not null
                if(String.isNotBlank(String.valueOf(objCluster.Software_Version__c))) {
                    softwareVersionSet.add(String.valueOf(objCluster.Software_Version__c).deleteWhitespace());
                } 
            }
        }

        if(!softwareVersionSet.isEmpty() && Schema.sObjectType.Releases__c.isAccessible()) {
                
            // Collect relevant releases
            Map<String, Date> endOfSupDateByVersion = new Map<String, Date>();
            for (Releases__c objReleases : [SELECT Id, Version__c, Release_Version__r.End_Of_Support_Date__c 
                                            FROM Releases__c
                                            WHERE Version__c =: softwareVersionSet
                                            AND Release_Version__r.End_Of_Support_Date__c != null]) {

                endOfSupDateByVersion.put(objReleases.Version__c, objReleases.Release_Version__r.End_Of_Support_Date__c);
            }

            Map<Id, Cluster__c> clusterUpdatemap = new Map<Id, Cluster__c>();
            for (Cluster__c objCluster : newClusterList) {
                Cluster__c updatedCluster = new Cluster__c(Id = objCluster.Id);
                if (String.isNotBlank(String.valueOf(objCluster.Software_Version__c))
                    && endOfSupDateByVersion.containsKey(objCluster.Software_Version__c)) {
                        Date endOfSupportDate = endOfSupDateByVersion.get(objCluster.Software_Version__c);
                        if (isInsert) {
                            updatedCluster.Release_Version_End_Of_Support_Date__c = endOfSupportDate;
                        }else{
                            objCluster.Release_Version_End_Of_Support_Date__c = endOfSupportDate;
                        }
                }else{
                    if (isInsert) {
                            updatedCluster.Release_Version_End_Of_Support_Date__c = null;
                    }else{
                        objCluster.Release_Version_End_Of_Support_Date__c = null;
                    }
                }
                clusterUpdatemap.put(updatedCluster.Id, updatedCluster);
            }
            
            if(!clusterUpdatemap.isEmpty() && isInsert && Schema.sObjectType.Cluster__c.isUpdateable()){
                UPDATE clusterUpdatemap.values();
            }

        }
    }
}