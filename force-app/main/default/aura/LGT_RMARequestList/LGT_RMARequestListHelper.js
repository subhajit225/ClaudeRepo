({
	sortData: function (cmp, fieldName, sortDirection,helper) {
        var data = cmp.get("v.RMAList");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.RMAList", data);
        var RMALists = [];
        for(var i=0; i<5;i++){
            if(i<data.length)
                RMALists.push(data[i]); 
        }
        cmp.set("v.RMAListLess",RMALists);
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