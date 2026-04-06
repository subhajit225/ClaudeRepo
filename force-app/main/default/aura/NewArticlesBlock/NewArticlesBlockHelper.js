({
	sortData: function (cmp ) {
        var data = cmp.get("v.kavList");
        var reverse = false;
        data = Object.assign([],data.sort(this.sortBy('kV.LastModifiedDate', reverse ? -1 : 1)));
        cmp.set("v.kavList", data);
    },
    sortDataForPopular: function (cmp ) {
        var data = cmp.get("v.kavList1");
        var reverse = false;
        data = Object.assign([],data.sort(this.sortBy('kV.ArticleTotalViewCount', reverse ? -1 : 1)));
        cmp.set("v.kavList1", data);
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
    }
})