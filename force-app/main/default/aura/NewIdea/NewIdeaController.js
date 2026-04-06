({
    init : function(component, event, helper) {
        var action = component.get("c.getPiklistValues");
         var bodyCom = component.find('spinner');
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            var plValues = [];
            for (var i = 0; i < result.length; i++) {
                plValues.push({
                    label: result[i],
                    value: result[i]
                });
            }
            component.set("v.CategList", plValues);
            $A.util.addClass(bodyCom, 'slds-hide');
        });
        $A.enqueueAction(action);
    },
    handleGenreChange: function (component, event, helper) {
        //Get the Selected values   
        var selectedValues = event.getParam("value");
        
        //Update the Selected Values  
        component.set("v.selectedCategList", selectedValues);
    },
    save : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        console.log('hell');
        try{
            var com = component.get("v.commId");
            var hasError = false;
            /*-------Title Validation ------*/
            var title = component.find("title");
            var value = title.get("v.value");
            if ($A.util.isEmpty(value)) {
                $A.util.addClass(bodyCom, 'slds-hide');
                title.set("v.errors",  [{message:" Please fill the required field " + value}]);           
                title.focus();
                hasError= true;
            } else {
                title.set("v.errors", null)
            }
            /*------*/
            /*-------body Validation ------*/
            if(!component.get("v.body")){
                $A.util.addClass(bodyCom, 'slds-hide');
                component.set("v.validity", false);
                hasError= true;
            }
            else{
                component.set("v.validity", true);
            }
            
            var selectCateg = component.find("selectCateg");
            var valueC = selectCateg.get("v.value");
            console.log(valueC);
            if ($A.util.isEmpty(valueC)) {
                $A.util.addClass(bodyCom, 'slds-hide');
                
                selectCateg.focus();
                hasError= true;
            } else {
            }
            /*--------*/
            if(!hasError){
                var action = component.get("c.createIdea");
                action.setParams({
                    title : component.get("v.title"),
                    body: component.get("v.body"),
                    categories:component.get("v.selectedCategList"),
                    //  commid:'09a40000000CwnIAAS'
                    commid : component.get("v.commId")
                });
                action.setCallback(component, function(response) {
                    var result = response.getReturnValue();
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({
                        "url": "/ideadetail?id="+result
                    });
                    urlEvent.fire();
                });
                $A.enqueueAction(action);
            }
        }catch(e){ $A.util.addClass(bodyCom, 'slds-hide');}
        
    },
    Cancel : function(component, event, helper){
        var url_string = window.location.href;
        var url = new URL(url_string);
        var isNew = url.searchParams.get("newIdea");
        if(isNew){
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": "/idealist"
            });
            urlEvent.fire();
        }
        component.set("v.ModalOpen",false);
    }
})