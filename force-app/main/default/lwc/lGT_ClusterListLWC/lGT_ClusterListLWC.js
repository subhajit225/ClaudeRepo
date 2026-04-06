/*<Created By: Ashish thakur 23 march, 2022>
    <Reason>
    To make LWC component for Account's Cluster section. 
    </Reason>*/

    import { LightningElement, api,track } from 'lwc';
    import getClusterListLWC from '@salesforce/apex/ClusterListControllerLWC.getClusterListLWC';
    import { NavigationMixin } from 'lightning/navigation';
    
    export default class LGT_ClusterListLWC extends NavigationMixin(LightningElement) {
    
    @track clusterList=[];
    showButton = true;
    showLess = true;
    @api recordId;
    @api isTrueAccordion=false;
    @track isName = true;
    @track isTag= false;
    @track isArchived = false;
    @track isSoftware = false;
    @track Desc = true;
    SpinnerForCluster = false;
    @track currentfield = 'Name';
    @track currentSortingOrder = 'desc';
    @track AccountClusterMigrationStatus='0';
    @track AccountOverallClusterMigration=0;
    @track AccountTotalTaskInprogress=0;
    @track activeSectionName='None';
    @track AccountTotalNoOfSLAsWithObjects=0;
    @track AccountTotalNoOfSLAsMigrated=0; 
    connectedCallback() {
        this.getClusterList();
    }
    handleToggleSection() {
            this.getClusterList();
    }
    renderedCallback(){
       if(this.isTrueAccordion==false)
       {
         this.activeSectionName='A';
       }
    }
    getClusterList(){
        this.SpinnerForCluster = true;
            getClusterListLWC(
                {
                caseId: this.recordId,
                showLess: this.showLess
                
                })
                .then((result) => {
                      this.SpinnerForCluster = false;
                if (result !== null && result !== undefined) {
                        var accountId=result[0].clusterList[0].account__c;
                        this.AccountTotalNoOfSLAsWithObjects=result[0].accountIdToNoOfSLAsWithObjects[accountId]!=undefined?result[0].accountIdToNoOfSLAsWithObjects[accountId]:0;
                        this.AccountTotalNoOfSLAsMigrated=result[0].accountIdToNoOfSLAsMigrated[accountId]!=undefined?result[0].accountIdToNoOfSLAsMigrated[accountId]:0;
                        var dataList=[];
                        var clusterData=result[0].clusterList;
                    
                   for(let i=0;i<result[0].clusterList.length;i++){
                    
                      var clusterId=clusterData[i].Id;
                      var data={
                           Id:clusterData[i].Id,
                           Name:clusterData[i].Name,
                           Overall_Cluster_Migration__c:clusterData[i].Overall_Cluster_Migration__c!=undefined?clusterData[i].Overall_Cluster_Migration__c:0,
                           RSC_Migration_Tasks_Inprogress__c:clusterData[i].RSC_Migration_Tasks_Inprogress__c!=undefined?clusterData[i].RSC_Migration_Tasks_Inprogress__c:0,
                           RSC_Migrations_Tasks_Completed__c:clusterData[i].RSC_Migrations_Tasks_Completed__c!=undefined?clusterData[i].RSC_Migrations_Tasks_Completed__c:0,
                           Total_RSC_Migration_Tasks__c:clusterData[i].Total_RSC_Migration_Tasks__c!=undefined?clusterData[i].Total_RSC_Migration_Tasks__c:0,
                           account__c:clusterData[i].account__c,
                           archived__c:clusterData[i].archived__c!=undefined?clusterData[i].archived__c:'',
                           software_version__c:clusterData[i].software_version__c!=undefined?clusterData[i].software_version__c:'',
                           NoOfSLAsWithObjects:result[0].clusterIdToNoOfSLAsWithObjects[clusterData[i].Id]!=undefined?result[0].clusterIdToNoOfSLAsWithObjects[clusterData[i].Id]:0,
                           NoOfSLAsMigrated:result[0].clusterIdToNoOfSLAsMigrated[clusterData[i].Id]!=undefined?result[0].clusterIdToNoOfSLAsMigrated[clusterData[i].Id]:0,
                           tag__c:clusterData[i].tag__c!=undefined?clusterData[i].tag__c:''

                      };
                      dataList.push(data);
                   }

                    let clusterListWithTaks=[];
                    let clusterListWithoutTasks=[];
                 
                   this.clusterList=[];
                   if (result[0].clusterList[0].account__r.RSC_Migrations_Tasks_Completed__c!=null && result[0].clusterList[0].account__r.RSC_Migrations_Tasks_Completed__c!==undefined && result[0].clusterList[0].account__r.Overall_Cluster_Migration__c!=undefined && result[0].clusterList[0].account__r.Total_RSC_Migration_Tasks__c!=undefined) {
                           let taskCompleted=result[0].clusterList[0].account__r.RSC_Migrations_Tasks_Completed__c!=null?result[0].clusterList[0].account__r.RSC_Migrations_Tasks_Completed__c:0;
                           let taskInprogress=result[0].clusterList[0].account__r.RSC_Migration_Tasks_Inprogress__c!=undefined?result[0].clusterList[0].account__r.RSC_Migration_Tasks_Inprogress__c:0;
                           let totalTask=result[0].clusterList[0].account__r.Total_RSC_Migration_Tasks__c!=undefined?result[0].clusterList[0].account__r.Total_RSC_Migration_Tasks__c:0;
                   
                             this.AccountClusterMigrationStatus=taskCompleted+'/'+totalTask;
                             this.AccountOverallClusterMigration=result[0].clusterList[0].account__r.Overall_Cluster_Migration__c!=undefined?result[0].clusterList[0].account__r.Overall_Cluster_Migration__c:0;
                             this.AccountTotalTaskInprogress=taskInprogress+'/'+totalTask;
                   
                            }
                  else{
                       this.AccountClusterMigrationStatus='0';
                       this.AccountOverallClusterMigration=0;
                   }
                
                    for(var i=0; i<dataList.length;i++){
                       
                        if(dataList[i].Total_RSC_Migration_Tasks__c==null || dataList[i].Total_RSC_Migration_Tasks__c==undefined || dataList[i].Total_RSC_Migration_Tasks__c==0)
                        {
                            clusterListWithoutTasks.push(dataList[i]);

                        }
                        else{
                            clusterListWithTaks.push(dataList[i]); 
                        }
                    }
                    if(clusterListWithoutTasks.length>0)
                    {
                        clusterListWithTaks=clusterListWithTaks.concat(clusterListWithoutTasks);
                    }
                    if(clusterListWithTaks.length>0){
                     
                        this.clusterList= this.clusterList.concat(clusterListWithTaks);
                    }
                    if(dataList.length < 5){
                        this.showButton = false;
                    }
                    
                //  this.sortData(this.currentfield, this.currentSortingOrder);
                  
                }
                }).catch((error) => {
                
                });
            
    
    }
    showAllRecords(){
        if(this.showLess == true){
            this.showLess = false;
            this.getClusterList();
        }
        else{
            this.showLess = true;
            this.getClusterList();
        }
    }
    openAccountDetailPage(event){
        let pageReference = {
            type: 'standard__recordPage',
            attributes: {
               
              recordId: event.target.dataset.id,
              actionName: 'view'
              
            }
          };
          // this[NavigationMixin.Navigate](pageReference, true);
          this[NavigationMixin.Navigate](pageReference, false);
    }
    Sorttable(event){
        var fieldName = event.target.name;
        var sortDirection = event.target.dataset.id;
     
        if(sortDirection == 'desc' ){
            this.isName = true;
            this.isArchived = false;
            this.isTag = false;
            this.isSoftware_version = false

        }
        else  if(sortDirection == 'descTag' ){
            this.isTag = true
            this.isName = false
            this.isArchived = false
            
            this.isSoftware_version = false

        }
        else if(sortDirection == 'descArchived' ){
            this.isArchived = true
            this.isName = false
           
            this.isTag = false
            this.isSoftware_version = false

        }
        else if(sortDirection == 'descSoftware' ){
            this.isSoftware_version = true
            this.isArchived = false
            this.isName = false
            this.isTag = false
        }
     
            if(fieldName != this.currentfield){
             
                this.currentSortingOrder ='desc';
                this.Desc= true;
               
                //sortDirection = 'asc';
               
                this.currentfield = fieldName
            }
            else{
                if(this.currentSortingOrder =='desc'){
                    this.currentSortingOrder ='asc';
                    this.Desc= false;
                }
               else{
                this.currentSortingOrder ='desc';
                this.Desc= true;
               }
            }
        
        
        this.sortData(fieldName, this.currentSortingOrder);

    }
    sortData(fieldName, sortDirection){
        var data = this.clusterList;
        var reverse = sortDirection !== 'asc';
         //sorts the rows based on the column header that's clicked
         data.sort(this.sortBy(fieldName, reverse));
         this.clusterList=[];
         for(var i = 0 ; i< data.length ; i++){
             this.clusterList.push(data[i])
         }
    }
    sortBy(field , reverse , primer ) {
        var key;
        if(field.includes('.')){
            var fields = field.split(".");
            var field1 = fields[0];
            
            var field2 = fields[1];
            key = function(x) {
                if(!x[field1]){
                    return null;
                }
                return x[field1][field2];
            };
            
        }else{
            key = primer ?
                function(x) {return primer(x[field])} :
            function(x) {return x[field]}
        }
        
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a)?key(a):'', b = key(b)?key(b):'', reverse * ((a > b) - (b > a));
        }
    }
    OpenRSCtasksList(event){
         this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId:event.target.dataset.id,
                objectApiName: 'Cluster__c',
                relationshipApiName: 'RSC_Migration_Tasks__r',
                actionName: 'view'
            },
        });
    }
    
}