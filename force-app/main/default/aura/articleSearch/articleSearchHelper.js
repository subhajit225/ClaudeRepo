({
    getArticles: function(component, event, helper) {
        var action = component.get("c.searchArticle");
        var articleNumber = component.get("v.articleNumber");
        if (articleNumber != null && articleNumber != undefined && articleNumber != '') {
            action.setParams({ 'articleNumber': component.get("v.articleNumber"), 'caseId': component.get("v.recordId") });
            action.setCallback(this, function(response) {
                var state = response.getState();
                if (state === "SUCCESS") {
                    var fieldsWrapper = response.getReturnValue();
                    if (fieldsWrapper.length == 1 && fieldsWrapper[0].ArticleNumber == articleNumber) {
                        var preSelectedArticleIds = component.get('v.kbIds');
                        if (preSelectedArticleIds.length > 0) {
                            var articles = component.get('v.articleList');

                            if (!preSelectedArticleIds.includes(fieldsWrapper[0].KnowledgeArticleId)) {
                                preSelectedArticleIds.push(fieldsWrapper[0].KnowledgeArticleId);
                                var alreadyExit = false;
                                for (var i = 0; i < articles.length; i++) {
                                    if (articles[i].ArticleNumber != fieldsWrapper[0].ArticleNumber) {
                                        continue;
                                    } else {
                                        alreadyExit = true;
                                        break;
                                    }
                                }
                                if (!alreadyExit) {
                                    articles.push(fieldsWrapper[0]);
                                    component.set('v.articleList', articles);
                                }
                            }
                            helper.attachMatchToCase(component, preSelectedArticleIds, helper);
                        } else {
                            component.set('v.articleList', fieldsWrapper);
                            helper.attachMatchToCase(component, fieldsWrapper[0].KnowledgeArticleId, helper);
                        }
                    } else {
                        component.set('v.articleList', fieldsWrapper);
                        component.set("v.totalPages", Math.ceil(fieldsWrapper.length/component.get("v.pageSize")));
                        var i = 1;
                        var arrayList = [];
                        while(i <= component.get("v.totalPages")){
                            arrayList.push(i);
                            i++;
                        }
                        component.set("v.totalPagesList",arrayList);
                        component.set("v.currentPageNumber",1);
                        helper.pagination(component, event);
                        component.find("accordion").set('v.activeSectionName', 'B');
                        if (response.getReturnValue().length == 0) {
                            component.set("v.noResult", true);

                        } else {
                            component.set("v.noResult", false);
                        }
                    }
                }
            });
            $A.enqueueAction(action);
        } else {
            component.set("v.noResult", true);
            component.set('v.articleList', []);
        }
    },
    attachMatchToCase: function(component, kbIds, helper) {
        var action = component.get("c.attachToCase1");
        action.setParams({
            articleIds: kbIds,
            caseId: component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.find("accordion").set('v.activeSectionName', 'A');
                if (component.get("v.type") != null && component.get("v.type") != undefined && component.get("v.type") != '') {
                    var message = 'close';
                    var vfOrigin = baseUrl;
                    window.postMessage(message, vfOrigin);
                } else if (window.location.href.includes('closeCase')) {
                    //alert('Article Attached Successfully');
                    //component.set('v.articleList',null);
                    component.set('v.kbIds', null);
                    //component.set("v.articleNumber",'');
                    //$A.enqueueAction(component.get("c.doInit"));
                } else {
                    if (component.get("v.theme") == 'Theme4u') {
                        helper.refreshFocusedTab(component);
                    } else {
                        let urlString = window.location.href;
                        var vfOrigin = urlString.substring(0, urlString.indexOf("/s"));
                        window.postMessage('refresh', vfOrigin);
                    }
                }
                var attachedArticles = component.get("v.existingArticles");
                var articleList = component.get("v.articleList");

                for (var i = 0; i < articleList.length; i++) {
                    if (kbIds.includes(articleList[i].KnowledgeArticleId)) {
                        attachedArticles.push(articleList[i]);
                    }
                }

                component.set('v.articleList', []);
                component.set('v.existingArticles', attachedArticles);
                component.set('v.kbIds', []);
            }
        });
        $A.enqueueAction(action);
    },
    fetchBaseUrl: function(component, event) {
        var url = window.location.href;
        var pathname = window.location.pathname;
        var index1 = url.indexOf(pathname);
        var index2 = url.indexOf("/", index1);
        var baseUrl = url.substr(0, index2);
        if (baseUrl != null && baseUrl != '') {
            return baseUrl;
        } else {
            return null;
        }
    },
    refreshFocusedTab: function(component) {
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
                var focusedTabId = response.tabId;
                workspaceAPI.refreshTab({
                    tabId: focusedTabId,
                    includeAllSubtabs: false
                });
            })
            .catch(function(error) {
                console.log(error);
            });
    },
    pagination : function(component, event) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.articleList");
        var x = (pageNumber-1)*pageSize;
        
        //creating data-table data
        for(; x<(pageNumber)*pageSize; x++){
            if(allData[x]){
                data.push(allData[x]);
            }
        }
        component.set("v.currentPageRecord", data);
    }
})