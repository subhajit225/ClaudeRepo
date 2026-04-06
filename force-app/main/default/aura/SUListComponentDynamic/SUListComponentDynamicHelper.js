({
    doInitListCompFunc : function(component, event, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        action.setCallback(this, function(response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result= response.getReturnValue();
                if(result.isCustomSettingFilled){
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
                    component.set("v.currentCommunityURL",result.currentCommURL);
                    component.set("v.customSettingErrorMessage","");
                    helper.autosearchListFunc(component, event,helper);
                }else{
                    component.set("v.customSettingErrorMessage",'Please configure your SearchUnify and try again.');
                }
            }else {
            	console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
        //Handle Right and Middle Click
        document.addEventListener('mousedown', function(e){
            helper.runScriptMethodFunc(component, e);
        });
    },
    autosearchListFunc : function(component, event, helper){
        var params = event.getParam('arguments');
        var result;
        if(params && params !== undefined){
            result = params.data;
        }else{
            result = component.get("v.advanceFilterData");
        }
    
        if(result !==  undefined && result !== null) {
            helper.createAggregationFilter(component,result);
        }
        helper.autosearchFunc(component, 'true');
    },
    createAggregationFilter : function(component,result){
        if(result !==  undefined && result !== null) {
            if(result.searchString !== undefined && component.get("v.searchString").length !== 0){
            	component.set("v.searchString", result.searchString);
            }
            var sourceType = result.sourceType;
            var valueType = result.valueFilter;
            var openModal = result.openModal;
            if(openModal !== undefined){
            	component.set("v.modalOpen", openModal);
            }
            var totalResult = String(result.pageSize);
            if((sourceType !== undefined && valueType !== undefined) && (sourceType !== '' && valueType !== '')){
                var sourceFilter = sourceType.split(';');
                var valueFilter = valueType.split(';');
                var finalJson = '[';
                var totalAggr = '';
                for(var i=0; i<sourceFilter.length; i++){
                    if(valueFilter[i] != '' && valueFilter[i] != undefined && valueFilter[i] != 'undefined'){
                        var secondFilterChild = valueFilter[i].split('|');
                        if(secondFilterChild.length > 0){
                            var childValue = '';
                            totalAggr += '{"type":"'+sourceFilter[i]+'","filter":[';
                            for(var j=0; j<secondFilterChild.length; j++){
                                childValue += '"'+secondFilterChild[j]+'",';
                            }
                            childValue = childValue.slice(0,childValue.length-1);
                            totalAggr += childValue+']},';
                        }else{
                            totalAggr += '{"type":"'+sourceFilter[i]+'","filter":["'+valueFilter[i]+'"]},';
                        }
                    }
                }
        		totalAggr = totalAggr.slice(0, totalAggr.length -1);
                finalJson = finalJson+totalAggr+']';
                if(finalJson != ''){
                    component.set('v.aggregation', finalJson);
                }
            }
            if(totalResult != undefined && totalResult != ''){
            	component.set("v.pagesize", totalResult);
            }
        }
    },
    autosearchFunc : function(component, runLoader) {
        var bodyCom = component.find('dvSpinner3');
        $A.util.removeClass(bodyCom, 'su_disSpiner');
        component.set("v.loadingResult", 0);
        var analyticsCmp = component.find("SuAnalytics");
        var sid = analyticsCmp.analytics('_gz_taid','');
        var resultPerSize = "10";
        resultPerSize = component.get("v.pagesize");
        if(resultPerSize === 'undefined' || resultPerSize === undefined){resultPerSize = '10';} //default handling
        var searchText = component.get("v.searchString");
        var originalQuery = searchText.trim();
        var EmailregexSlash = '\\\\';
        var regexSlash = new RegExp("\\\\", 'g');
        searchText = searchText.replace(regexSlash, EmailregexSlash);
        var Emailregex = '\\"';
        var regex = new RegExp('\"', 'g')
        searchText = searchText.replace(regex,Emailregex);
        var action = component.get("c.SearchResults");
        action.setParams({
            "searchParams":{
            "searchString": searchText,
            "pageNum" : "1",
            "sortBy" : "_score",
            "orderBy" : "desc",
            "resultsPerPage" : resultPerSize,
            "selectedType" : component.get("v.aggregation"),
            "referrer": "",
            "exactPhrase": "",
            "withOneOrMore": "",
            "withoutTheWords": "",
            "recommendResult": "",
            "indexEnabled":false,
            "sid":sid
            }
        });
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
            var result= response.getReturnValue();
            if(!$A.util.isEmpty(result) && !$A.util.isEmpty(result.result)){
                if(result.searchDownStatus == false){
                    var total = result.result.total;
                    component.set("v.totalResults",total);
                    component.set("v.ListCompautosuggestList",result.result.hits);
                    var emptyArr = [];
                   
                    var auramethodResult = analyticsCmp.analytics('search',{searchString: originalQuery,"result_count":total,page_no: "1","platformId":component.get("v.uid"),"filter": component.get("v.aggregation") != undefined && component.get("v.aggregation") != null && component.get("v.aggregation") != '' ? component.get("v.aggregation") : emptyArr});
                    }else{
                        component.set("v.searchUnifyDownStatus",result.searchDownStatus);
                        if(result.searchCallFail != ''){
                            component.set("v.noResultFoundMsg",'Error while Search call');
                        }
                        if(result.searchDownStatus == true){
                            component.set("v.noResultFoundMsg","Search is not working. Please try again.");
                        }
                	}	
            	}
            }
            else{
            	$A.log("Errors", response.getState());
            }
            $A.util.addClass(bodyCom, 'su_disSpiner');
            component.set("v.loadingResult",1);
        });
        $A.enqueueAction(action);
    },
    searchButtonPressFunc: function(component, event) {
        var SearchQuery = component.get("v.searchString");
        if(SearchQuery != null && SearchQuery != '' && SearchQuery != undefined){
            SearchQuery = SearchQuery.trim();
        }
        var searchPageNewTab = component.get("v.openNewTab");
        if(searchPageNewTab){
            event.target.href = component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(SearchQuery);
        }else{
            document.getElementById('suggestions').classList.add('su-hidePanel');
            this.redirectFunc(component,SearchQuery,'suggest');
        }
    },
    redirectFunc : function(component, SearchQuery, eventHit){
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "isredirect": false,
            "url": component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(SearchQuery)
        });
        urlEvent.fire();
        if(eventHit ==='suggest'){
            this.fillSearchBoxEventFire();
        }
    },
    fillSearchBoxEventFire : function(){
        var SearchQuery = this.getURLParameter('searchString');
        var searchBoxEvent = $A.get("e.SU_Ltng:fillSearchBox");
        searchBoxEvent.setParams({"searchString": SearchQuery});
        searchBoxEvent.fire();
    },
    getURLParameter : function(param) {
        var m = window;
        var s = m.document.URL;
        var result=decodeURIComponent((new RegExp('[?|&]' + param + '=' + '([^&;]+?)(&|#|;|$)').exec(s)||[,""])[1].replace(/\+/g, '%20'))
        return result;
    },
    openModalFunc : function(component,event,helper){
        //helper.runScriptMethodFunc(component,event);
        var data ={"title":event.target.title,"accessKey":event.target.accessKey,"href":event.target.getAttribute("data-url")};
        if(component.get("v.modalOpen")){
            var eventCall = $A.get("e.SU_Ltng:ComponentListDisplay");
            eventCall.setParams({"listComponentData": data});
            eventCall.fire();
        }else{
            event.target.href = event.target.getAttribute("data-url");
        }
    },
    runScriptMethodFunc: function(component,event){
        if(component.get('v.searchString') != ""){
            var target;
            if (event.target.closest('a')){
                target = event.target.closest('a');
                var data_Id    = target.getAttribute("data-id") || "";
                var data_type  = target.getAttribute("data-type") || "";
                var data_index = target.getAttribute("data-index") || "";
                var data_rank = target.getAttribute("data-rank") || "";
                var data_url = target.getAttribute("data-url") || "";
                var data_sub = target.getAttribute("data-sub") || "";
                if(data_rank != ''){
                    data_rank = (+data_rank) +1;
                }
                var childCmp = component.find("SuAnalytics");
                if(data_Id!="" && data_sub!=""){
                    var auramethodResult = childCmp.analytics('conversion',{index:data_index,type:data_type,id:data_Id, rank:data_rank, convUrl:data_url, convSub:data_sub});
                }
            }
        }
    }
})