({
    getUsrInfo : function(component) {
        var action = component.get("c.accountInfo");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.AccountInfo",result);
        });
        $A.enqueueAction(action);
    },
    fillColoumn: function (cmp) {
        cmp.set('v.mycolumns', [
            {label: 'First Name', fieldName: 'firstName' },
            {label: 'Last Name', fieldName: 'lastName' },
            {label: 'Email', fieldName: 'email' },
            {label: 'Title', fieldName: 'title'},
            {label: 'Phone', fieldName: 'phone' }
        ]);
    }, 
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.AccountInfo.existingUsers");
        var reverse = sortDirection !== 'desc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.AccountInfo.existingUsers", data);
    },
    sortBy: function (field, reverse, primer) {
        if (field.includes(".")) {
            var string1 = field.substring(0, field.indexOf("."));
            var string2 = field.substring(field.indexOf(".")+1);   
            var key = primer ?
                function(x) {return primer(x[string1][string2])} :
            function(x) {return x[string1][string2]};
        }else{
            var key = primer ?
                function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        }
        
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a)?key(a):'', b = key(b)?key(b):'', reverse * ((a > b) - (b > a));
        }
    }
})