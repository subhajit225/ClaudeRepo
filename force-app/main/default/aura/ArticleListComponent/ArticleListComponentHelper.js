({
    getarticlevalue : function(component, event, helper ) {
        var categ =   component.get("v.categoryType_Article");
        
        var pageNum = component.get("v.pageNum");
        var currentPageNumber = Number(pageNum);
        var pageSize = component.get("v.pageSize");
        var orderBy = component.get("v.sortBy");

        var action = component.get("c.getArticleList");
        action.setParams({
            pageNumber: pageNum,
            pageSize: pageSize, 
            category : categ
        });
        
        action.setCallback(this, function(response){
            var result=response.getReturnValue();
            console.log(result);
            
            var replaced = categ.split('_').join(' ');
            //component.set("v.categoryType_Article",replaced);
            component.set("v.kavlist", result);
            component.set("v.allData", result);
            helper.sortData(component);  
            component.set("v.totalCount", result.length);
            console.log(result);
            component.set("v.totalPages", Math.ceil(result.length/component.get("v.pageSize")));
            var i = 1;
            component.set("v.currentPageNumber",1);
            helper.buildData(component, helper,component.get("v.allData"));
            if (result.length > 0){
                component.set("v.totalResults",result[0].totalcount);
            }
            
            component.set("v.pageNum",pageNum);
            var action = component.get("c.checkIfSubscribed");
            action.setParams({
                label: categ
            });
             
            action.setCallback(this, function(responseA){
                var resultA=responseA.getReturnValue();
                if(resultA){
                     component.set("v.subLabel",'Subscribe');
                }else{
                     component.set("v.subLabel",'Unsubscribe');
                }
                  component.set("v.isSubscribed",resultA);
            });
            $A.enqueueAction(action);   
            
            
            
        });
        $A.enqueueAction(action);
        
    },
    pageFunc: function(component,event,helper){
        console.log('__________',event);
        var currentPage =  parseInt(component.get("v.pageNum")) - 1;
        component.set("v.pageNum",currentPage);
        helper.getarticlevalue(component);
    },
    nextPageFunc : function(component,event,helper){
        var currentPage =  parseInt(component.get("v.pageNum")) + 1;
        component.set("v.pageNum",currentPage);
        helper.getarticlevalue(component);
    },
    subscribed : function(component ) {
        
        
    },
    sortData: function (cmp ) {
        var data = cmp.get("v.allData");
        var fieldName = cmp.get("v.sortBy");
        var reverse = false;
        data = Object.assign([],data.sort(this.sortBy(fieldName, reverse ? -1 : 1)));
        cmp.set("v.allData", data);
    },
    sortBy: function (field, reverse, primer) {
        var key;
        if(field.includes('.')){
            var fields = field.split(".");
            var field1 = fields[0];
            var field2 = fields[1];
            key = function(x) {
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
    buildData : function(component,helper,allData) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        if(pageNumber > 0){
            var x = (pageNumber-1)*pageSize;
            //creating data-table data
            for(; x<(pageNumber)*pageSize; x++){
                if(allData[x]){
                    data.push(allData[x]);
                }
            }
        }
        
        component.set('v.kavlist',data);
       
        
    }
})