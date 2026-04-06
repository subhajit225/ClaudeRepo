public without sharing class ClusterChartController {

    public Id clusterId;
    public Cluster__c cust{get;set;}

    public ClusterChartController(ApexPages.StandardController sc){
        if(!Test.isRunningTest()){
            sc.addFields(new List<String>{'CreatedDate'});

        }
        this.clusterId = (ID)sc.getId();
        this.cust = new Cluster__c();
        this.cust = (Cluster__c) sc.getRecord();
    }

    public String getVersionHistory(){
        Map<String,Date> versionHistory = new Map<String,Date>();
        String[] months = new List<String>{'January','February','March','April','May','June','July','August','September','October','November','December'};
        List<ClusterAttribute__b> clusAttObject = new List<ClusterAttribute__b>();
        if(!Test.isRunningTest()){
            clusAttObject = [SELECT CreatedById, CreatedDate, SystemModstamp, Cluster__c, Name__c, Modification_time__c, Value__c, Id FROM ClusterAttribute__b where Cluster__c =: clusterId AND Name__c = 'software_version__c' ];
        }else{
            ClusterAttribute__b NewClusterAttribute = new ClusterAttribute__b();
            NewClusterAttribute.Cluster__c = clusterId;
            NewClusterAttribute.Modification_time__c = system.Today();
            NewClusterAttribute.Name__c = 'storage_usage__c';
            NewClusterAttribute.Value__c = '123';
            clusAttObject.add(NewClusterAttribute);
        }

        Integer i = 0;
        for(ClusterAttribute__b clusAtt : clusAttObject){
            if(clusAtt.Value__c != null){
                String newLabel = months[clusAtt.Modification_time__c.month()-1] +' '+ clusAtt.Modification_time__c.year();
                Datetime dt = (Datetime)clusAtt.Modification_time__c;
                Date d = Date.newInstance(dt.year(),dt.month(),dt.day());
                versionHistory.put(clusAtt.Value__c + String.valueOf(i++), d);
            }
        }
        if(versionHistory == null  ){return '';}
        return Json.serialize(versionHistory);
    }

    @AuraEnabled
    public static ChartData getChartsData(){
        User userRecord = [Select id,AccountId from User where id=: UserInfo.getUserId()];
        AggregateResult[] allData = [select count(id) clus,software_version__c version from Cluster__c where software_version__c !=null AND archived__c = false AND  ((NOT Account__r.Name Like '%Rubrik%') AND (NOT Account__r.Name Like 'UNASSIGNED') ) AND ((NOT software_version__c Like '%~%') AND (NOT software_version__c Like '%dev%') )  AND is_callhome_on__c = True Group By software_version__c ];
        AggregateResult[] ownData = [select count(id) clus,software_version__c version from Cluster__c where software_version__c !=null AND Account__c =: userRecord.AccountId AND archived__c = false  Group By software_version__c ];
        return new ChartData(allData,ownData);
    }

    @AuraEnabled
    public static Integer getChartsWeekly(String clusterId,String chartName,String dateString){
        return null;
    }

    @AuraEnabled
    public static specificCluster getClusterData(String clusterId){
        User userRecord = [Select id,AccountId from User where id=: UserInfo.getUserId()];
        List<Cluster__c> clusList = [select id from cluster__c where Account__c =:userRecord.AccountId AND Id =: clusterId ];
        if(clusList.size() == 0 ){
            return null;
        }

        //Prepare Cluster Attribute map based on the name
        Map<String, List<ClusterAttribute__b>> clusterAttributeMap = new Map<String, List<ClusterAttribute__b>>();
        if(!Test.isRunningTest()){
            for(ClusterAttribute__b eachAtt : [SELECT CreatedById, CreatedDate, SystemModstamp, Cluster__c, Name__c, Modification_time__c, Value__c, Id FROM ClusterAttribute__b WHERE Cluster__c =: clusterId]){
                if(!String.isBlank(eachAtt.Name__c) && (System.Label.Cluster_Usage_Attributes.contains(eachAtt.Name__c)
                    || (System.Label.Cluster_Prediction_Attributes.contains(eachAtt.Name__c) && eachAtt.Modification_time__c > System.now()))){
                    if(clusterAttributeMap.containsKey(eachAtt.Name__c)){
                        clusterAttributeMap.get(eachAtt.Name__c).add(eachAtt);
        }
                    else{
                        clusterAttributeMap.put(eachAtt.Name__c, new List<ClusterAttribute__b>{eachAtt});
                }
                }
                }
            }
        else{
            clusterAttributeMap = createTestClusAttData(Id.valueOf(clusterId));
        }

        Map<String, Map<String, Double>> clusMap = new Map<String, Map<String, Double>>();
        Set<String> labels = new Set<String>();
        Set<String> labelPred = new Set<String>();

        if(clusterAttributeMap.containsKey('storage_usage__c'))
            prepareClusterMap(clusterAttributeMap.get('storage_usage__c'), labels, clusMap);

        if(clusterAttributeMap.containsKey('pred_storage_usage__c'))
            prepareClusterMap(clusterAttributeMap.get('pred_storage_usage__c'), labelPred, clusMap);

        if(clusterAttributeMap.containsKey('pred_high_storage_usage__c'))
            prepareClusterMap(clusterAttributeMap.get('pred_high_storage_usage__c'), labelPred, clusMap);

        if(clusterAttributeMap.containsKey('pred_low_storage_usage__c'))
            prepareClusterMap(clusterAttributeMap.get('pred_low_storage_usage__c'), labelPred, clusMap);

        DateTime latestDate;
        String latestValue = '';
        if(clusterAttributeMap.containsKey('total_storage_capacity__c')){
            for(ClusterAttribute__b cb : clusterAttributeMap.get('total_storage_capacity__c')){
            if(cb.Value__c != null){
                    if(latestDate == null){
                        latestDate = cb.Modification_time__c;
                        latestValue = cb.Value__c;
                }
                    if(cb.Modification_time__c > latestDate){
                        latestValue = cb.Value__c;
                }
                }
                }
            }

        if(clusterAttributeMap.containsKey('objects_protected__c'))
            prepareClusterMap(clusterAttributeMap.get('objects_protected__c'), labels, clusMap);

        if(clusterAttributeMap.containsKey('snapshot_count__c'))
            prepareClusterMap(clusterAttributeMap.get('snapshot_count__c'), labels, clusMap);

        return new specificCluster(clusMap, labels, labelPred, latestValue);
        }

    /*
     * Author       :   Saakshi Gupta
     * CreatedDate  :   30th July 2021
     * Description  :   CS21-638 : Refactored the code by moving the repetitive code to this method. Also fixed the issue of the data not appearing for
     *                  the oldest month
    */
    private static void prepareClusterMap(List<ClusterAttribute__b> clusterAttributeList, Set<String> labels, Map<String, Map<String, Double>> clusMap){
        String[] months = new List<String>{'January','February','March','April','May','June','July','August','September','October','November','December'};

        String label = '';
        Integer count = 1;

        //This map will store the data point for x-axis (e.g. July 2021) as key and the monthly average usage as value
        Map<String, Double> labelValueMap = new Map<String, Double>();

        for(ClusterAttribute__b cb : clusterAttributeList){
            if(cb.Value__c != null){
                //Generating the x-axis label from the month and year of the Modification Time on the cluster attribute
                label = months[cb.Modification_time__c.month()-1] +' '+ cb.Modification_time__c.year();

                //Calculating the average of the value. If there was an existing value in the map, multiply it with the old
                //count to get summation of previous values and then add the new value and then divide by the incremented count
                //to get the new average
                if(labelValueMap.containsKey(label)){
                    labelValueMap.put(label, ((labelValueMap.get(label) * count) + Double.valueOf(cb.Value__c)) / ++count);
                }
                else{
                    labelValueMap.put(label, Double.valueOf(cb.Value__c));
                    count = 1;
                    labels.add(label);
                }
                }
            }

        if(!labelValueMap.isEmpty())
            clusMap.put(clusterAttributeList[0].Name__c, labelValueMap);
        }

    @TestVisible private static Map<String, List<ClusterAttribute__b>> createTestClusAttData(Id clusterId){
        List<ClusterAttribute__b> NewClusterAttributeList = new List<ClusterAttribute__b>();
            ClusterAttribute__b NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = System.Today();
            NewClusterAttribute.Name__c = 'storage_usage__c';
            NewClusterAttribute.Value__c = '123';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = System.Today()-10;
        NewClusterAttribute.Name__c = 'storage_usage__c';
        NewClusterAttribute.Value__c = '23';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-25;
            NewClusterAttribute.Name__c = 'storage_usage__c';
        NewClusterAttribute.Value__c = '32';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()+1;
        NewClusterAttribute.Name__c = 'pred_storage_usage__c';
            NewClusterAttribute.Value__c = '123';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()+25;
        NewClusterAttribute.Name__c = 'pred_storage_usage__c';
        NewClusterAttribute.Value__c = '43';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()+2;
        NewClusterAttribute.Name__c = 'pred_high_storage_usage__c';
            NewClusterAttribute.Value__c = '123';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()+30;
        NewClusterAttribute.Name__c = 'pred_high_storage_usage__c';
        NewClusterAttribute.Value__c = '23';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()+6;
        NewClusterAttribute.Name__c = 'pred_low_storage_usage__c';
        NewClusterAttribute.Value__c = '54';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()+30;
        NewClusterAttribute.Name__c = 'pred_low_storage_usage__c';
        NewClusterAttribute.Value__c = '23';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-7;
        NewClusterAttribute.Name__c = 'total_storage_capacity__c';
        NewClusterAttribute.Value__c = '34';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-28;
        NewClusterAttribute.Name__c = 'total_storage_capacity__c';
        NewClusterAttribute.Value__c = '23';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-3;
        NewClusterAttribute.Name__c = 'objects_protected__c';
        NewClusterAttribute.Value__c = '23';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-35;
        NewClusterAttribute.Name__c = 'objects_protected__c';
        NewClusterAttribute.Value__c = '76';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-7;
        NewClusterAttribute.Name__c = 'snapshot_count__c';
        NewClusterAttribute.Value__c = '56';
        NewClusterAttributeList.add(NewClusterAttribute);

        NewClusterAttribute = new ClusterAttribute__b();
        NewClusterAttribute.Cluster__c = clusterId;
        NewClusterAttribute.Modification_time__c = system.Today()-34;
        NewClusterAttribute.Name__c = 'snapshot_count__c';
        NewClusterAttribute.Value__c = '87';
        NewClusterAttributeList.add(NewClusterAttribute);

        Map<String, List<ClusterAttribute__b>> clusterAttributeMap = new Map<String, List<ClusterAttribute__b>>();
        for(ClusterAttribute__b eachAtt : NewClusterAttributeList){
            if(!String.isBlank(eachAtt.Name__c) && (System.Label.Cluster_Usage_Attributes.contains(eachAtt.Name__c)
                || (System.Label.Cluster_Prediction_Attributes.contains(eachAtt.Name__c) && eachAtt.Modification_time__c > System.now()))){
                if(clusterAttributeMap.containsKey(eachAtt.Name__c)){
                    clusterAttributeMap.get(eachAtt.Name__c).add(eachAtt);
                }
                else{
                    clusterAttributeMap.put(eachAtt.Name__c, new List<ClusterAttribute__b>{eachAtt});
            }
        }
        }
        return clusterAttributeMap;
    }

    public class specificCluster{
        @AuraEnabled public Map<String,Map<String,Double>> clusMap{get;set;}
        @AuraEnabled public Set<String> labels{get;set;}
        @AuraEnabled public String totalStorage{get;set;}
        @AuraEnabled public Set<String> predLabels{get;set;}
        public specificCluster(Map<String,Map<String,Double>> clusMap, Set<String> labels,Set<String> predLabels,String totalStorage){
            this.labels = labels;
            this.clusMap = clusMap;
            this.predLabels = predLabels;
            this.totalStorage = totalStorage;
        }
    }

    public class ChartData{
        @AuraEnabled public Map<String, AggregateResult[]> allData{get;set;}
        @AuraEnabled public Map<String, AggregateResult[]> ownData{get;set;}
        public ChartData(AggregateResult[] allData,AggregateResult[] ownData){
            this.allData = new Map<String,AggregateResult[]>();
            this.ownData = new Map<String,AggregateResult[]>();
            for(AggregateResult ad : allData){
                String version = (String)ad.get('version');
                if(version.length() > 3)
                    version = version.substring(0, 3);
                if(!this.allData.containsKey(version)){
                    this.allData.put(version,new List<AggregateResult>());
                }
                this.allData.get(version).add(ad);
            }
            for(AggregateResult ad : ownData){
                String version = (String)ad.get('version');
                if(version.length() > 3)
                version = version.substring(0, 3);
                if(!this.ownData.containsKey(version)){
                    this.ownData.put(version,new List<AggregateResult>());
                }
                this.ownData.get(version).add(ad);
        }
    }
    }

    public class clusterData{
        @AuraEnabled public String versionString{get;set;}
        @AuraEnabled public String versionCount{get;set;}
        @AuraEnabled public List<clusterData> childData{get;set;}
    }
}