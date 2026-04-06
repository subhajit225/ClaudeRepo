({
    doInitListCompFunc : function(component, event, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        var permission = '';
        action.setParams({
            "authParams": {
                "permission": permission
            }
        });

        action.setCallback(this, function (response) {
            if (component.isValid() && response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                if (result.isCustomSettingFilled) {
                    component.set("v.customSettingsFilled", result.isCustomSettingFilled);
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
		            component.set("v.Bearer",result.token);
                    component.set("v.currentCommunityURL", result.currentCommURL);
                    component.set("v.customSettingErrorMessage", "");
                    if(result.UserType == "Guest" || result.UserType == undefined){
                        result.userEmail = '';
                    }
                    if (result.userEmail != null && result.userEmail != '') {
                        component.set("v.currentUserEmail", result.userEmail);
                    }
                    helper.autosearchListFunc(component,event,helper);
                } else {
                    component.set("v.customSettingErrorMessage", 'Please configure your SearchUnify and try again.');
                }
            }
            else {
                console.log("Failed with state: " + response.getState());
            }
        });
        $A.enqueueAction(action);
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
        var data = JSON.stringify({
            "searchString": searchText,
            "from": ((1-1) * resultPerSize).toString(),
            "pageNum" : "1",
            "sortBy" : "_score",
            "orderBy" : "desc",
            "resultsPerPage" : resultPerSize,
            "aggregations" : component.get("v.aggregation"),
            "referrer": "",
            "exactPhrase": "",
            "withOneOrMore": "",
            "withoutTheWords": "",
            "recommendResult": "",
            "indexEnabled":false,
            "sid":sid,
	        "uid": component.get("v.uid")
        });
	    var xmlHttp = new XMLHttpRequest();
        var url = component.get("v.endPoint")+"/search/SUSearchResults";
        xmlHttp.withCredentials = true;
    	xmlHttp.open( "POST", url, true );
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization','bearer ' + component.get('v.Bearer') );
	    xmlHttp.setRequestHeader('Content-Type', 'application/json');
		
	    xmlHttp.send(data);

        xmlHttp.onreadystatechange = function () {
    		if (xmlHttp.readyState === 4) {
    	    	if (xmlHttp.status === 200) {
		        var result = JSON.parse(xmlHttp.response);
                    if(result.flag != 402){
                        if(result.searchClientSettings.ViewedResults == 1) {
                            component.set("v.showViewedResults", true);
                        } else {
                            component.set("v.showViewedResults", false);
                        }
                        var total = result.result.total;
                        component.set("v.totalResults", total);
                        component.set("v.conversion", false);
                        component.set("v.ListCompautosuggestList",result.result.hits);
                        var emptyArr = [];
                        var data = {};
                        data = {"conversion":false,"searchString": originalQuery,"result_count":total,page_no: "1","platformId":component.get("v.uid"),"filter": component.get("v.aggregation") != undefined && component.get("v.aggregation") != null && component.get("v.aggregation") != '' ? component.get("v.aggregation") : emptyArr};
                        var eventCall = $A.get("e.su_vf_console:SUComponentEvent");
                        eventCall.setParams({"searchObject": data});
                        eventCall.fire();
                    //    var auramethodResult = analyticsCmp.analytics('search',{searchString: originalQuery,"result_count":total,page_no: "1","platformId":component.get("v.uid"),"filter": component.get("v.aggregation") != undefined && component.get("v.aggregation") != null && component.get("v.aggregation") != '' ? component.get("v.aggregation") : emptyArr});
                    }else{
                        if(result.flag == 402)
                       	    $A.get('e.force:refreshView').fire()
                    }
                    $A.util.addClass(bodyCom, 'su_disSpiner');
                    component.set("v.loadingResult",1);
                }
		    
		    }
        }
    },
    searchButtonPressFunc: function(component, event) {
        var SearchQuery = component.get("v.searchString");
        if(SearchQuery != null && SearchQuery != '' && SearchQuery != undefined){
            SearchQuery = SearchQuery.trim();
        }
        var searchPageNewTab = component.get("v.openNewTab");
        if(searchPageNewTab){
            //event.target.href = component.get("v.currentCommunityURL") + "?searchString=" + encodeURIComponent(SearchQuery);
            window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(component.get("v.searchString"))+"&pageNum=1&sortBy=_score&orderBy=desc&resultsPerPage=10&exactPhrase=&withOneOrMore=&withoutTheWords=&selectedType=");
            event.target.href = component.get("v.currentCommunityURL") + window.location.hash;
        }else{
            document.getElementById('suggestions').classList.add('su-hidePanel');
            this.redirectFunc(component,SearchQuery,'suggest');
        }
    },
    redirectFunc : function(component, SearchQuery, eventHit){
        var urlEvent = $A.get("e.force:navigateToURL");
        window.location.hash = encodeURIComponent("searchString="+encodeURIComponent(component.get("v.searchString"))+"&pageNum=1&sortBy=_score&orderBy=desc&resultsPerPage=10&exactPhrase=&withOneOrMore=&withoutTheWords=&selectedType=");
        urlEvent.setParams({
            "isredirect": false,
            "url": component.get("v.currentCommunityURL") + window.location.hash
        });
        urlEvent.fire();
        if(eventHit ==='suggest'){
            this.fillSearchBoxEventFire();
        }
    },
    fillSearchBoxEventFire : function(){
        var SearchQuery = this.getURLParameter('searchString');
        var searchBoxEvent = $A.get("e.su_vf_console:fillSearchBox");
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
        helper.runScriptMethodFunc(component,event);
        var emptyArr = [];
        var data ={"conversion":true,"conversionString":component.get("v.searchString") ,"searchString":component.get("v.searchString"),"result_count":component.get("v.totalResults"),"title":event.target.title,"accessKey":event.target.accessKey,"href":event.target.getAttribute("data-url"),page_no: "1","platformId":component.get("v.uid"),"filter": component.get("v.aggregation") != undefined && component.get("v.aggregation") != null && component.get("v.aggregation") != '' ? component.get("v.aggregation") : emptyArr};
        component.set("v.conversion", true);
        var eventCall = $A.get("e.su_vf_console:SUComponentEvent");
        eventCall.setParams({"searchObject": data});
        eventCall.fire();
        if(!component.get("v.modalOpen"))
            event.target.href = event.target.getAttribute("data-url");
    },
    runScriptMethodFunc: function(component,event){
        if(component.get("v.searchString") !== '') {
            var data_Id    = event.target.getAttribute("data-id") || "";
            var data_type  = event.target.getAttribute("data-type") || "";
            var data_index = event.target.getAttribute("data-index") || "";
            var data_rank = event.target.getAttribute("data-rank") || "";
            var data_url = event.target.getAttribute("data-url") || "";
            var data_sub = event.target.getAttribute("data-sub") || "";
            var data_trackAnalytics = JSON.parse(event.target.getAttribute("data-trackAnalytics")) || [];
            if(data_rank != ''){
                data_rank = (+data_rank) +1;
            }
            var emptyArr = [];
            var childCmp = component.find("SuAnalytics");
            var sid;
            var cookies = document.cookie.split(';').map(f => f.trim());
            if (component.get("v.conversion"))
                cookies.forEach(function(g){
                    if(g.split("=") && g.split("=").length && g.split("=")[0].trim() == '_gz_sid') 
                        sid = g.split("=")[1].trim()
                });
            if(data_Id!="" && data_sub!="" && component.get("v.searchString").trim() != ''){
                if(!component.get("v.conversion") || (component.get("v.conversion") && !sid))
                    var auramethodResult1 = childCmp.analytics('search',{"conversionString":component.get("v.searchString") ,searchString: component.get("v.searchString"),"result_count":component.get("v.totalResults"),page_no: "1","platformId":component.get("v.uid"),"filter": component.get("v.aggregation") != undefined && component.get("v.aggregation") != null && component.get("v.aggregation") != '' ? component.get("v.aggregation") : emptyArr,"conversion":[{es_id:data_index+'/'+data_type+'/'+encodeURIComponent(data_Id), rank:data_rank, url:data_url, subject:data_sub, sc_analytics_fields: data_trackAnalytics}]});
                else
                    var auramethodResult = childCmp.analytics('conversion',{index:data_index,type:data_type,id:data_Id, rank:data_rank, convUrl:data_url, convSub:data_sub, sc_analytics_fields: data_trackAnalytics});
            }
        }

    }
})