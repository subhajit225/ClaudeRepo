({
    getUsrInfo : function(component) {
        var action = component.get("c.accountInfo");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.AccountInfo",result);
            component.set("v.contactInfo",result.contactList);
            /*<Additions By: Anmol Baweja 03 Mar, 2020>*/
            /*<Reason>
  				To restrict any community user to make a new user with ignored email domain as per CS-582
 			</Reason>*/
            component.set("v.ignoredDomainList",result.ignoredDomainList);
            /*</Additions By: Anmol Baweja>*/
        });
        $A.enqueueAction(action);
    },
    fillColoumn: function (cmp) {
        cmp.set('v.mycolumns', [
            {label: 'First Name', fieldName: 'FirstName' },
            {label: 'Last Name', fieldName: 'LastName' },
            {label: 'Email', fieldName: 'Email' }, 
            {label: 'Title', fieldName: 'Title'},
            {label: 'Phone', fieldName: 'Phone' }
        ]);
    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.contactInfo");
        var reverse = sortDirection !== 'desc';
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.contactInfo", data);
    },
    sortBy: function (field, reverse, primer) {
        try{ if (field.includes(".")) {
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
            }}
        catch(err){
            console.log(err)
        }
    }
})