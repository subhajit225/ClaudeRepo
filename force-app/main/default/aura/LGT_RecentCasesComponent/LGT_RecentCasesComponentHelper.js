({
    getCasesRelatedToClusterUUID : function(cmp,event,helper) {
        var clusterRelatedCaseList = [];
        var clusterRelatedCaseListLess = [];
        var clusterUuidValue = cmp.get("v.clusterUUID");
        var clusterUuidToLowerCase = clusterUuidValue.toLowerCase();
        var clusterUuidVal = clusterUuidToLowerCase.trim();
        var originalCaseList = cmp.get("v.casesList");
        if(clusterUuidVal == '' || clusterUuidVal == null && originalCaseList.length>5 ){
            cmp.set("v.casesList",cmp.get("v.casesListOriginal"));
            cmp.set("v.showError", false);
            cmp.set("v.hideCases", false);
            cmp.set("v.showAllButton",true);
        }
        else{
            
            for(var i =0; i<originalCaseList.length; i++){
                if(!!originalCaseList[i].Cluster__r && originalCaseList[i].Cluster__r.Name.toLowerCase().includes(clusterUuidVal)){
                    clusterRelatedCaseList.push(originalCaseList[i]);
                }
                else{
                    cmp.set("v.errorMessage", 'No Records Available');
                    cmp.set("v.showError", true);
                    cmp.set("v.hideCases", true);
                    cmp.set("v.allRecords",false);
                    cmp.set("v.showAllButton",false);
                }
            }
            if(clusterRelatedCaseList.length>5){
                cmp.set("v.showAllButton",true);
            }
            else if(clusterRelatedCaseList.length<5){
                cmp.set("v.showAllButton",false);
            }
            if(clusterRelatedCaseList != null && clusterRelatedCaseList.length>0){
                cmp.set("v.casesList",clusterRelatedCaseList);
                cmp.set("v.hideCases", false);
                cmp.set("v.showError", false);
                cmp.set("v.allRecords",false);
                
            }
        }
        var tempList = cmp.get("v.casesList")
        var tempListLess = [];
        for(i=0;i<5;i++){
            if(i<tempList.length)
                tempListLess.push(tempList[i]);
        }
        
        cmp.set("v.casesListLess",tempListLess);
        if(tempListLess.length<5){
            cmp.set("v.showAllButton",false);
        }
        
    },
    sortData: function (cmp, fieldName, sortDirection,helper) {
        var data = cmp.get("v.casesList");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse));
        
        cmp.set("v.casesList", data);
        var caseList = [];
        for(var i=0; i<5;i++){
            if(i<data.length)
                caseList.push(data[i]); 
        }
        cmp.set("v.casesListLess",caseList);
    },
    sortBy: function (field, reverse, primer) {
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
    },
    
})