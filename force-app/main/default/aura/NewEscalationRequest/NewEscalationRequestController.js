({
    doInit : function(component, event, helper) {
        
        var value = helper.getParameterByName(component , event, 'inContextOfRef');
        if(!!value){
            var context = JSON.parse(window.atob(value));
            if(context.attributes.recordId != null && context.attributes.recordId.startsWith('001')){
                component.find('accIds').set('v.value', context.attributes.recordId);
                component.set("v.accountId",context.attributes.recordId);
                component.set("v.hasAccount",true);
            }
        }else{
            try{
                var url = window.location.href;
                if(url.includes('/Account/')){
                    var splitUrl = url.split("/Account/");
                    splitUrl = splitUrl[1].split('/');
                    component.find('accIds').set('v.value', splitUrl[0]);
                    component.set("v.accountId",splitUrl[0]);
                    component.set("v.hasAccount",true);
                }
            }catch(e){
                console.log(e);
            }
            
           
        }
        
        var action = component.get("c.getDetails");
        action.setParams({
            'recordId':component.get("v.recordId") ,
            'accountId':component.get("v.accountId") 
        });
        action.setCallback(this,function(res){
            var response = res.getReturnValue();
            console.log(response);
            console.log(component.get("v.accountId"));
            var fieldMap = response.fieldMap;
            component.set("v.Factors",fieldMap['Factors_involved_leading_to_escalation__c']);
            component.set("v.Product",fieldMap['Product_Line_involved_in_the_escalation__c']);
            component.set("v.record",response.escalationRecord);
            if(response.escalationRecord != null && response.escalationRecord.Factors_involved_leading_to_escalation__c != null){
                component.set("v.selectedFactors",response.escalationRecord.Factors_involved_leading_to_escalation__c.split(';'));
            }
            if(response.escalationRecord != null && response.escalationRecord.Product_Line_involved_in_the_escalation__c != null){
                component.set("v.selectedProduct",response.escalationRecord.Product_Line_involved_in_the_escalation__c.split(';'));
            }
            component.set("v.accountContacts",response.accountContacts);
            component.set("v.rubrikContacts",response.rubrikContacts);
            component.set("v.primaryContacts",response.primaryContacts);
        });
        $A.enqueueAction(action);
        
    },
    onProceed : function(component, event, helper) {
        component.set("v.isProceed",false);
    },
    addContact: function(component, event, helper) {
        component.set("v.showmodal",true);
        component.set("v.isPrimary",true);
    },
    addRubrikContact: function(component, event, helper) {
        component.set("v.showmodal",true);
        component.set("v.isPrimary",false);
    },
    cancel: function(component, event, helper) {
        component.set("v.showmodal",false);
    },
    selectContact: function(component, event, helper) {
        var index  = event.getSource().get("v.value");
        var list = component.get("v.accountContacts");
        if(component.get("v.isPrimary")){
            var oldList = component.get("v.primaryContacts");
            oldList.push(list[index]);
            component.set("v.primaryContacts",oldList);
        }else{
            var oldList = component.get("v.rubrikContacts");
            oldList.push(list[index]);
            component.set("v.rubrikContacts",oldList);
        }
    },
    Submit: function(component, event, helper) {
        component.set("v.isSave",false);
    },
    Save: function(component, event, helper) {
        component.set("v.isSave",true);
    },
    onSubmit: function(component, event, helper) {
        
        event.preventDefault();       // stop the form from submitting
        //alert('submit'+component.get("v.isSave"));
        var hasError = false; 
        var fields = event.getParam('fields');
        var factors = component.get("v.selectedFactors");
        var products = component.get("v.selectedProduct");
        
        if(component.get("v.isSave")){
            fields.Status__c = 'Draft';
        }else{
            fields.Status__c = 'Submitted';
        }
        if(!!factors){
            fields.Factors_involved_leading_to_escalation__c = factors.join(";")+';';
        }
        if(factors.length < 2){
            hasError = true;
            component.find("factor").setCustomValidity('Please select atleast two values'); //do not get any message
            component.find("factor").reportValidity();
        }else{
            component.find("factor").setCustomValidity(''); //do not get any message
            component.find("factor").reportValidity();
        }
        if(!!products){
            fields.Product_Line_involved_in_the_escalation__c = products.join(";")+';';
        }
        if(products.length < 1){
            hasError = true;
            component.find("product").setCustomValidity('Please select atleast one values'); //do not get any message
            component.find("product").reportValidity();
        }else{
            component.find("product").setCustomValidity(''); //do not get any message
            component.find("product").reportValidity();
        }
        var accountId = component.find("accIds");
        if(!accountId.get('v.value')){
            hasError = true;
        }
        var desc = component.find("desc");
        if(!desc.get('v.value')){
            hasError = true;
        }else if(desc.get('v.value').length > 32000){
            hasError = true;
        }
        var desired = component.find("desired");
        if(!desired.get('v.value')){
            hasError = true;
        }else if(desired.get('v.value').length > 32000){
            hasError = true;
        }
        var areOne = component.find("areOne");
        if(!!areOne.get('v.value') && areOne.get('v.value').length > 32000){
            hasError = true;
        }
        /*var areOne = component.find("areOne");
        if(!areOne.get('v.value')){
            hasError = true;
        }*/
        component.set("v.hasError",hasError);
        if(hasError){
            try{
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title : 'Warning!',
                    message: 'Please fill all the fields',
                    type: 'error',
                    duration : '7000'
                });                  
                toastEvent.fire();    
            }catch(e){
                alert('Please fill all the fields');
            }
            
        }
        else{
            var userId = $A.get("$SObjectType.CurrentUser.Id");
            fields.Reporting_User__c = userId;
            fields.OwnerId = '00G1W000002OCBUUA4';
            fields.Escalation_Severity__c = 'E1';
            component.find('myRecordForm').submit(fields);
        } 
    },
    handleSuccess: function(component, event, helper) {
        
        var updatedRecord = JSON.parse(JSON.stringify(event.getParams()));
        var recordId = updatedRecord.response.id;
        var primaryContacts = component.get("v.primaryContacts");
        var rubrikContacts = component.get("v.rubrikContacts");
        var action = component.get("c.addEscalationContact");
        action.setParams({
            'recordId':recordId ,
            'rubrikContacts':rubrikContacts,
            'primaryContacts':primaryContacts
        });
        action.setCallback(this,function(res){
            console.log(res.getReturnValue());
            component.set("v.showmodal",false);
            component.set("v.isComplete",true);
            component.set("v.recordId",recordId);
            /*var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": recordId,
                "slideDevName": "detail"
            });
            navEvt.fire();*/
        });
        $A.enqueueAction(action);
    },
    updateAccount: function(component, event, helper) {
        var accId = component.find('accIds').get('v.value');
        if(accId.length > 0){
            accId = accId[0];
        }
        if(accId != ''){
            var action = component.get("c.getContactList");
            action.setParams({
                'accountId' : accId
            });
            action.setCallback(this,function(res){
                if(res.getState() == 'SUCCESS'){
                    component.set("v.accountContacts",res.getReturnValue());
                }
            });
            $A.enqueueAction(action);
        }else{
            component.set("v.accountContacts",[]);
            component.set("v.rubrikContacts",[]);
            component.set("v.primaryContacts",[]);
        }
    },
    addRubrikContact: function(component, event, helper) {
        var conId = component.find('selectedContact').get('v.value');
        console.log(conId);
        if(typeof conId != 'string'){
            conId = conId[0];
        }
        var action = component.get("c.getContactDetail");
        action.setParams({
            'contactId' : conId
        });
        action.setCallback(this,function(res){
            if(res.getState() == 'SUCCESS'){
                var rubrikContacts = component.get("v.rubrikContacts");
                rubrikContacts.push(res.getReturnValue());
                component.set("v.rubrikContacts",rubrikContacts);
                component.find('selectedContact').set('v.value','');
            }
        });
        $A.enqueueAction(action);
        
    },
    onDone : function(component, event, helper) {
        try{
            $A.get('e.force:refreshView').fire();
            var navEvt = $A.get("e.force:navigateToSObject");
            navEvt.setParams({
                "recordId": component.get("v.recordId"),
                "slideDevName": "detail"
            });
            navEvt.fire();
        }
        catch(e){
            window.open('/'+component.get("v.recordId"),'_self');
        }
        
    }
})