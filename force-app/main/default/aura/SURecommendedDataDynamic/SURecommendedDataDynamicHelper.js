({
    doRecommFunc : function(component, event, helper){
        var action = component.get("c.getCommunityCustomSettings");
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result= response.getReturnValue();
                if(result.isCustomSettingFilled){
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
                    component.set("v.customSettingErrorMessage","");
                    var searchQuery = '';
                    searchQuery = helper.getURLParameter('searchString');
                    if(searchQuery === null && searchQuery === 'undefined'){
                    	searchQuery = '';
                    }
                    var pagesize = component.get("v.pagesize");
                    var action = component.get("c.SearchResults");
                    action.setParams({
                    "searchParams":{
                        "searchString":searchQuery,
                        "pageNum" : "1",
                        "sortBy" : "_score",
                        "orderBy" : "desc",
                        "resultsPerPage" : pagesize,
                        "selectedType" : "",
                        "referrer": "",
                        "exactPhrase": "",
                        "withOneOrMore": "",
                        "withoutTheWords": "",
                        "recommendResult": "yes",
                        "indexEnabled":false,
                        "sid":""
                    }
                    });
                    action.setCallback(this, function(response) {
                        if (response.getState() == "SUCCESS") {
                            var result= response.getReturnValue();
                            if(!$A.util.isEmpty(result)){
                            	component.set("v.recommendedList",result.result.hits);
                            }
                        }
                        else{
                            $A.log("Errors", response.getState());
                        }
                    });
                    $A.enqueueAction(action);
                }else{
                    component.set("v.customSettingErrorMessage",'Please configure your SearchUnify and try again.');
                }
            }else {
            	console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
    },
    getURLParameter : function(param) {
        var m = window;
        var s = m.document.URL;
        var result=decodeURIComponent((new RegExp('[?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(s)||[,""])[1].replace(/\+/g, '%20'))
        return result;
    },
    runScriptMethodFunc: function(component,event){
        var data_Id    = event.target.getAttribute("data-Id") || "";
        var data_type  = event.target.getAttribute("data-Type") || "";
        var data_index = event.target.getAttribute("data-Index") || "";
        var data_rank = event.target.getAttribute("data-Rank") || "";
        var data_url = event.target.getAttribute("data-url") || "";
        var data_sub = event.target.getAttribute("data-Sub") || "";
        if(data_rank != ''){
            data_rank = (+data_rank) +1;
        }
        var childCmp = component.find("SuAnalytics");
        if(data_Id != '' && data_sub != ''){
            var auramethodResult = childCmp.analytics('conversion',{index:data_index,type:data_type,id:data_Id, rank:data_rank, convUrl:data_url, convSub:data_sub});
        }
	}
})