({
    init : function(component, event, helper) {
        var bodyCom = component.find('spinner');
        helper.getValues(component,helper);
        helper.categoriesPicklist(component);
        
    },
    nextPage : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        component.set("v.pageNum",component.get("v.pageNum")+1);
        helper.setdata(component);
    },
    previousPage : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        component.set("v.pageNum",component.get("v.pageNum")-1);
        helper.setdata(component);
    },
    firstPage : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        component.set("v.pageNum",1);
        helper.setdata(component);
    },
    lastPage : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        component.set("v.pageNum",component.get("v.totalPages"));
        helper.setdata(component);
    },
    filterIdeas : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        helper.categoriesPicklist(component);
        helper.getValues(component,helper);
        
        
    },
    openModalCreateIdea :function(component, event, helper) {
        
        component.set("v.ModalOpen", true);
    },
    closeBttn : function(component, event, helper) {
             
        component.set("v.ModalOpen", false);
    },
    changeFilter : function(component, event, helper){
        var bodyCom = component.find('spinner');
        $A.util.removeClass(bodyCom, 'slds-hide');
        var filter = event.target.id;
        component.set("v.selectedFilter" , filter);
        helper.getValues(component,helper);
    },
    
    insertVote : function(component, event, helper){
        var vote =event.currentTarget.dataset.index;
        var currentId = vote.split("`")[0];
        var type = vote.split("`")[1];
        var action = component.get("c.addVote");
        action.setParams({
            parentId : currentId,
            type : type,
            zoneId:component.get("v.commId"),
            selectedFilter : component.get("v.selectedFilter")
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            // console.log('res---' , result);
            component.set("v.IdeasList",result);
        });
        $A.enqueueAction(action);
    }
})