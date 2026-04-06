({
    doInit : function(component,event,helper) {
        helper.doInitFunc(component,event,helper);
    },
    searchButtonPress : function(component,event,helper) {
        helper.searchButtonPressFunc(component,event,helper);
    },
    fillSearchBoxOnSuggest : function(component,event,helper){
        var fillBoxData = event.getParam("searchString");
        component.set("v.searchString",fillBoxData);
    },
    enterKeySearch : function(component,event,helper) {
        helper.enterKeySearchFunc(component,event,helper);
    },
    mouseleft: function(component,event,helper){
        helper.mouseleftFunc(component,event,helper);
    },
    fillSearchbox: function(component,event,helper){
        if(component.get("v.isEnableTitleRedirect")){
            var target;
            if (event.target.closest('a')){
            target = event.target.closest('a');
            var data_Id = target.getAttribute("data-id") || "";
            var data_type = target.getAttribute("data-type") || "";
            var data_index = target.getAttribute("data-index") || "";
            var data_rank = target.getAttribute("data-rank") || "";
            var data_url = target.getAttribute("data-url") || "";
            var data_sub = target.getAttribute("data-subject") || "";
            var result_count = target.getAttribute("data-Count") || 0;
            if (data_rank != '') {
             data_rank = (+data_rank) + 1;
             }
            }
            gza("search", 
              { "searchString": component.get("v.searchString"),
                "result_count" : result_count,
                "page_no" : 0,
                "platformId" : component.get("v.uid"),
                "filter" : [],
                "conversion": [{
                rank: data_rank,
                url: data_url,
                subject: data_sub,
                es_id:data_index +"/"+ data_type + "/" + encodeURIComponent(data_Id)
            }]});
            var url = event.currentTarget.dataset.url;
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "isredirect": true,
                "url": url
            });
            urlEvent.fire(); 
        }
        else{
                helper.fillSearchboxFunc(component,event,helper);
        }
    },
    onfocus: function(component,event,helper){
        var input = document.getElementById("form-search");
        if(input.getAttribute("autocomplete") !== "off"){
            input.setAttribute("autocomplete","off");
        }
    },
    submitForm: function(component, event, helper) {
       	helper.searchButtonPressFunc(component, event, helper);
        event.preventDefault();     
    }
})