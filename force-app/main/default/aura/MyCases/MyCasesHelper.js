({
    sortData: function (cmp, fieldName, sortDirection,helper) {
        var data = cmp.get("v.CaseList1");
        var reverse = sortDirection !== 'desc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.CaseList1", data);
        this.buildData(cmp,helper,data);
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
    buildData : function(component, helper,data){
        var oppList = data;
        var pageSize = component.get("v.pageSize");
        var currentPage = component.get("v.currentPage");
        currentPage = currentPage-1;
        var paginationList = [];
        for(var i=pageSize * currentPage; i< (currentPage+1) * pageSize; i++)
        {
            paginationList.push(data[i]);
            if(data.length == i+1){
                break;
            }
        }
        component.set('v.caselist', paginationList);
    },
    generateCSV : function(component, caseList){
        let csvStringResult, counter, headers, keys, columnDivider, lineDivider;          
        columnDivider = ',';
        lineDivider =  '\n';

        headers = ['CaseNumber','Contact','Status','Priority','Subject','Type','Opened Date'];
        keys = ['CaseNumber','Contact','Status','Priority','Subject','Type','CreatedDate'];
        
        var selectedOpt = component.get("v.selectedOption");
        if(selectedOpt == 'My Closed Cases'){
            headers.push('Closed Date');
            keys.push('ClosedDate');
        }
        
        csvStringResult = '';
        csvStringResult += headers.join(columnDivider);
        csvStringResult += lineDivider;
        
        for(var i = 0; i < caseList.length; i++) {   
            counter = 0;
            
            keys.forEach(el => {
                if(counter > 0){ 
                	csvStringResult += columnDivider; 
            	}   
                         
                if (el == 'Contact') {
                 	let contactObject = caseList[i][el];
                
                    if ($A.util.isEmpty(contactObject)) {
                        csvStringResult += '""';
                    } else {
                        csvStringResult += '"'+ contactObject['Name']+'"';
                    }
                } else {   
                    if ($A.util.isEmpty(caseList[i][el])) {
                        csvStringResult += '""';   
                    } else {
                        csvStringResult += '"'+ caseList[i][el].replace(/(\r\n|\n|\r|#)/gm, "") +'"';
                    }
                }
            
            	counter++; 
        	}); 
            
            csvStringResult += lineDivider;
        }
        
        return csvStringResult;        
    },
     showToast : function(component, title, message, type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "duration": 500
        });
        toastEvent.fire();
    }
})