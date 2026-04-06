import { LightningElement, api } from "lwc";
import getRMAList from "@salesforce/apex/CaseDetailController.getRMAList";
import { NavigationMixin } from 'lightning/navigation';

export default class RmaRequestListLWC extends NavigationMixin(LightningElement) {
    @api recordId;
    RMAList = [];
    RMAListLess = [];
    allRecords = false;
    showAllButton = false;
    sortedBy = "Name";
    sortedDirection = "desc";
    spinnerForRMA = false;

    get sortedByName() {
        return this.sortedBy === "Name";
    }

    get sortedDirectionAsc() {
        return this.sortedDirection === "asc";
    }

    get sortedByNode() {
        return this.sortedBy === "Node__c";
    }

    get sortedByServiceType() {
        return this.sortedBy === "Service_Type__c";
    }

    get sortedByCluster() {
        return this.sortedBy === "Cluster__c";
    }

    get sortedByStatus() {
        return this.sortedBy === "Status__c";
    }

    get sortedByCaseNumber() {
        return this.sortedBy === "Parent_Case__r.CaseNumber";
    }

    get rmaRecords() {
        return this.allRecords ? this.RMAList : this.RMAListLess;
    }

    get showAllRecords() {
        return !this.allRecords;
    }
    connectedCallback() {
        this.getRMAList();
    }
    getRMAList(){
        this.spinnerForRMA = true;
        getRMAList({caseId:this.recordId}).then(response => {
            this.spinnerForRMA = false; 
            var result = response;
            if(result != null && result != ''){
                var RMAsList = [];
                this.RMAList = result;
                if(this.RMAList.length>5){
                    this.showAllButton = true;
                }
                else{
                    this.showAllButton = false;
                }
                for(var i=0; i<5;i++){
                    if(i < result.length)
                        RMAsList.push(result[i]); 
                }
                this.RMAListLess = RMAsList;
            }
        })
        .catch((error) => {
            console.log(error);
        });
    }

    handleSectionToggle(event) {
        this.getRMAList();
    }

    handleShowAllBtn(event) {
        this.allRecords = true;
    }

    handleShowLessBtn(event) {
        this.allRecords = false;
    }

    openRmaRequestDetailPage(event) {
        var recId = event.target.id.substring(0, 15);
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recId,
                objectApiName: 'RMA_Order__c',
                actionName: 'view'
            },
        });
    }

    sortTable(event) {
        try{
            var fieldName = event.target.name;
            var sortDirection = event.target.id.substring(0, 4);
            var currentSortingOrder =  this.sortedDirection;
            var currentfield =  this.sortedBy;
            if(!!fieldName && !!currentfield && fieldName != currentfield){
                currentSortingOrder ='desc';
                sortDirection = 'asc';
            }
            if(sortDirection == currentSortingOrder){
                sortDirection = 'asc';
            }
            this.sortedBy = fieldName;
            this.sortedDirection = sortDirection;
            this.sortData(fieldName, sortDirection);
        }
        catch(e){
            console.log(e);
        }
    }

    sortData(fieldName, sortDirection, helper) {
        var data = this.RMAList;
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse));
        this.RMAList = data;
        var RMALists = [];
        for(var i=0; i<5;i++){
            if(i<data.length)
                RMALists.push(data[i]); 
        }
        this.RMAListLess = RMALists;
    }

    sortBy(field, reverse, primer) {
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
}