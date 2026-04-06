({
    setdata : function(component) {
        var data = [];
        var pageNumber = component.get("v.pageNum");
        var pageSize = component.get("v.recordsPerPage");
        var allData = component.get("v.alldocuments");
        var x = (pageNumber-1)*pageSize;
        
        component.set('v.startNum',x+1);
        
        if(pageNumber*pageSize<allData.length){
            component.set('v.endNum',pageNumber*pageSize);  
        }else{
            var extraCount = (pageNumber*pageSize)-allData.length;
            console.log('extraCount  >.'+extraCount);
            component.set('v.endNum',(pageNumber*pageSize)-extraCount);
        }
        
        for(; x<(pageNumber)*pageSize; x++){
            if(allData[x]){
                data.push(allData[x]);
            }
        }
        component.set("v.mydocument", data);
        console.log('paged my data >>> '+component.get("v.Pagedmydata"));
    },
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.mydocument");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse))
        component.set("v.mydocument", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ? function(x) {return primer(x[field])} : function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})