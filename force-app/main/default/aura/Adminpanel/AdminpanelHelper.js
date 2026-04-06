({ 
    getUsrInfo : function(component) {
        var action = component.get("c.accountInfo");
        action.setParams({
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.AccountInfo",result);
            component.set("v.ContList",result.newContact);
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
            {label: 'First Name', fieldName: 'firstName' },
            {label: 'Last Name', fieldName: 'lastName' },
            {label: 'Email', fieldName: 'email'},
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
    },
    ValidateData : function(component,helper,event,data,callback) {
        var hasError = false;
        var allEmails = component.get("v.AccountInfo.existingEmails");
        var updatedContact = [];
        for (var i = 0; i < data.length; i++){
            var saveData = data[i];
            saveData.errorMessage = '';
            saveData.hasError = false;

            if(!saveData.firstName){
                saveData.hasError = true;
                hasError = true;
            }else{
            }

            if(!saveData.lastName){
                saveData.hasError = true;
                hasError = true;
            }else{
            }

            if(saveData.email == '')
            {
                saveData.hasError = true;
                hasError = true;
            }else if(allEmails.indexOf(saveData.email) != -1){
                saveData.hasError = true;
                hasError = true;
                saveData.errorMessage = 'User already exist with '+saveData.email+' Email';
            }
                else if (/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(saveData.email)){
                }
            
            /*Removed required validation for Title and Phone -
             updated phone pattern - CS21-426 - Veera */
            if(saveData.phone) {
                let pattern = Boolean(/^[^a-z^A-Z]{7,20}$/.test(saveData.phone));

                if (pattern === false) {
                saveData.hasError = true;
                hasError = true;
                } 
            }
            
            /*<Additions By: Anmol Baweja 03 Mar, 2020>*/
            /*<Reason>
				To restrict any community user to make a new user with ignored email domain as per CS-582
			</Reason>*/
            if(saveData.email != null && saveData.email != ''){
                var email=saveData.email.trim().split("@");
                var domain=email[1];
                if(component.get("v.ignoredDomainList") != null && domain != null && component.get("v.ignoredDomainList").includes(domain.toLowerCase()) && component.get("v.isChecked") == true){
                    hasError = true;
                    component.set("v.showModalForInvalidEmail",true);
                    component.set("v.modalMessage",$A.get("$Label.c.S_R_ignoredDomainAdminPanel"));
                }
            }
            /*</Additions By: Anmol Baweja>*/
            updatedContact.push(saveData);
        }
        callback(hasError,updatedContact);
    },
    ValidateContactData: function(component,helper,event,data,EmailValue,callback){
    var hasError=false;
     var updatedContactList = [];
      for (var i = 0; i < data.length; i++){
            var saveData = data[i];
            saveData.errorMessage='';
             if(EmailValue.includes(saveData.email)) 
             {
                saveData.hasError = true;
                hasError=true;
                saveData.errorMessage =EmailValue.replace(saveData.email,'');
             }  
             updatedContactList.push(saveData);
           }
     callback(hasError,updatedContactList);
    
}
})