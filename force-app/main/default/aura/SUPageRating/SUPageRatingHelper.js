({
    doInitFunc: function (component, event, helper) {
        helper.getCustomSettingValue(component, event, helper);
        let pageRateFeed = component.get("v.pageRateFeed")
        let articlesFeedbackArray = []
        const currentTime = Date.now();
        const feedbackDelay = 1 * 24 * 60 * 60 * 1000;
        const currentLoc = location.href;
        articlesFeedbackArray = JSON.parse(localStorage.getItem('articlesSaved')) || [];
        if (pageRateFeed == 0) {
            if (articlesFeedbackArray.length) {
                const filteredArray = articlesFeedbackArray.filter(i => i.articleUrl === currentLoc);
                if (filteredArray.length) {
                    const [item] = filteredArray;
                    if (item.articleTimeStamp > currentTime) {
                        component.set("v.ThankYouFlag", true)
                        component.set("v.isThankYou", true)
                    } else {
                        component.set("v.isThankYou", false)
                        component.set("v.ThankYouFlag", false)
                    }
                }
                else {
                    component.set("v.ThankYouFlag", false)
                }
            } else {
                component.set("v.isThankYou", false)
                component.set("v.ThankYouFlag", false)
            }
        }

    },

    getSuResponseValue: function (component, event, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        var permission = '';
        action.setParams({

            "authParams": {
                "permission": permission,
            }
        });

        var data = {
            "uid": component.get("v.uid")
        };
        if (typeof component.get("v.endPoint") != 'undefined') {
            var xmlHttp = new XMLHttpRequest();
            const url = component.get("v.endPoint") + "/pageRating/getPageRatingData";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xmlHttp.send('uid=' + component.get("v.uid"));
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var regexResult = JSON.parse(xmlHttp.response);
                        var contentSearchExp = JSON.parse(regexResult.contentSearchExp);
                        var pageRatingCustomization = JSON.parse(regexResult.pageRatingCustomization);
                        component.set("v.pageRatingCustomization", pageRatingCustomization);
                        var searchFeedback = JSON.parse(regexResult.searchFeedback);
                        component.set("v.searchFeedback", searchFeedback);
                        component.set("v.getFeedbackResData", searchFeedback);
                        var pageRatingInstance = JSON.parse(regexResult.pageRatingInstance);
                        if (contentSearchExp.enabled === true) {
                            regexResult = helper.regexMatch(component, event, helper, pageRatingInstance);
                            if (regexResult.found == 1) {
                                var regexData = JSON.parse(xmlHttp.response);
                                var regexSearchPage = helper.searchInstanceRegexMatch(component, event, helper, pageRatingInstance);
                                if (regexSearchPage.found == 1) {
                                    component.set("v.getSearchRegexData", regexSearchPage);
                                    component.set("v.searchPageRegex", true);
                                } else {
                                    component.set("v.searchPageRegex", false);
                                }
                                regexData = helper.instanceRegexMatch(component, event, helper, pageRatingInstance);
                                if (regexData.found == 1) {
                                    component.set("v.suResponseValues", true);
                                }
                            }
                        }
                    }
                }
            }
        }

    },
    updateLocalStorage: function (component, event, helper) {
        let feedbackDelay = 1 * 24 * 60 * 60 * 1000;
        let articlesFeedbackArray = JSON.parse(localStorage.getItem('articlesSaved')) || [];
        let currentLoc = location.href;
        let currentTime = Date.now();
        let pageRateFeed = component.get("v.pageRateFeed")
        let updated = false
        if (articlesFeedbackArray.length) {
            articlesFeedbackArray = articlesFeedbackArray.map(i => {
                if (i.articleUrl === currentLoc) {
                    i.articleTimeStamp = currentTime + feedbackDelay;
                    updated = true;
                }
                return i;
            })
        }
        if (!updated) {
            articlesFeedbackArray.push({ "articleUrl": location.href, "articleTimeStamp": currentTime + feedbackDelay })
        }
        localStorage.setItem('articlesSaved', JSON.stringify(articlesFeedbackArray));
    },
    /****regexMatch code start****/
    regexMatch: function (component, event, helper, pageRatingArray) {
        var found = 0;
        var pageRatingCategory = '';
        for (var i = 0; i < pageRatingArray.length; i++) {
            if (window.location.href && window.location.href.match(pageRatingArray[i]['regex'])) {
                pageRatingCategory = pageRatingArray[i].instance_name;
                found = 1;
                break;
            }
        }
        return { "found": found, "pageRatingCategory": pageRatingCategory };
    },
    instanceRegexMatch: function (component, event, helper, pageRatingInstanceArray) {
        var found = 0;
        var pageRatingInstanceCategory = '';
        for (var i = 0; i < pageRatingInstanceArray.length; i++) {
            if (typeof document.referrer == 'string' && document.referrer.match(pageRatingInstanceArray[i]['instance_regex'])) {
                pageRatingInstanceCategory = pageRatingInstanceArray[i].instance_name;
                found = 1;
                break;
            }
        }
        return { "found": found, "pageRatingInstanceCategory": pageRatingInstanceCategory };
    },

    searchInstanceRegexMatch: function (component, event, helper, searchPageInstanceArray) {
        var found = 0;
        var searchPageInstanceCategory = '';
          for (var i = 0; i < searchPageInstanceArray.length; i++) {
            const hasKey = searchPageInstanceArray[i].hasOwnProperty('search_regex')
            if (hasKey) {
            if (
              typeof document.referrer == "string" &&
              document.referrer.match(
                searchPageInstanceArray[i]["search_regex"]
              ) &&
              searchPageInstanceArray[i].search_regex.length != 0
            ) {
              searchPageInstanceCategory =
                searchPageInstanceArray[i].search_regex;
              found = 1;
              break;
            }
          }
        }
        return { "found": found, "searchPageInstanceCategory": searchPageInstanceCategory };
    },
    /****regexMatch code end****/

    /*****getCustomSettingValue *****/
    getCustomSettingValue: function (component, event, helper) {
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
                    component.set("v.Bearer", result.token);
                    component.set("v.CommunityUserType", result.UserType);
                    if (component.get("v.CommunityUserType") != 'Guest') {
                        component.set("v.currentCommunityEmail", result.userEmail);
                    } else {
                        component.set("v.currentCommunityEmail", '');
                    }
                    helper.getSuResponseValue(component, event, helper);
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
    onChangeEmail: function (component, event, helper) {
        var feedEmailName = component.find("getFeedbackEmail");
        var feedEmailValue = feedEmailName.get("v.value");
        component.set("v.feedbackTxtEmailVal", feedEmailValue);
    },
    feedbackTxtChange: function (component, event, helper) {
        var feedtxtName = component.find("feedbacktextInput");
        var feedtValue = feedtxtName.get("v.value");
        component.set("v.feedbackTxtInVal", feedtValue);
    },
    buttonClick: function (component, event, helper) {
        var clicked = event.target;
        var rowIndex = clicked.getAttribute("data-index");
        component.set("v.feedbackRatingV", rowIndex);
        component.set("v.feedbackratingVal", rowIndex);
        if (document.getElementsByClassName('su__ratingicon').length != 0) {
            // component.set('v.isButtonActive',false);
            for (var a = 0; a < document.getElementsByClassName('su__ratingicon').length; a++) {
                document.getElementsByClassName('su__ratingicon')[a].classList.remove('su__emoji-active');
                document.getElementsByClassName('su__ratingicon')[a].classList.remove('su__star-yellow');
            }
            for (var i = 0; i < rowIndex; i++) {
                document.getElementsByClassName('su__ratingicon')[i].classList.add('su__emoji-active');
                document.getElementsByClassName('su__ratingicon')[i].classList.add('su__star-yellow');
            }
        }
        // component.set('v.isButtonActive',false);
    },
    submitTextFeedback: function (component, event, helper) {
        helper.updateLocalStorage(component, event, helper);
        var feedbackAreaVal = component.find("feedbacktxArea") ? component.find("feedbacktxArea").get("v.value") : '';
        var feedbackTxtVal = component.get("v.feedbackTxtInVal");
        var childCmp = component.find("SuAnalytics");
        var rating = component.get("v.pageRateFeed");
        var feedback_type = component.get("v.feedback_type")
        childCmp.analytics("pagerating", {
            articlesFeedback: true,
            articleFeedback: feedbackTxtVal,
            referer: document.referrer,
            window_url: window.location.href,
            uid: component.get("v.uid"),
            feedback: component.get("v.feedback"),
            rating: rating ? rating : '',
            feedback_type,
        });

        if (component.get("v.feedback") === "1") {
            component.set("v.feedbackActiveYes", true);
            component.set("v.feedbackActiveNo", false);
        } else {
            component.set("v.feedbackActiveYes", false);
            component.set("v.feedbackActiveNo", true);
        }
        component.set("v.pageRatingResponseRecorded", true);
        component.set('v.displayModal', false);
        component.set("v.emailShowhide", true);
        // component.set('v.isButtonActive',true);
        component.set("v.suResponseValues", false);
        component.set("v.TextdisplayModal", false);
    },
    submitFeedback: function (component, event, helper) {
        helper.updateLocalStorage(component, event, helper);
        // var searchConvData = component.get("v.searchPageRegex");
        var rating = component.get("v.pageRateFeed")
        var feedbackratingVal = component.get("v.feedbackratingVal")
        var feedback_type = component.get("v.feedback_type")
        var currentTxtEmailVal = component.get("v.setCurrentEmail");
        var feedbackAreaVal = component.find("feedbacktxArea") ? component.find("feedbacktxArea").get("v.value") : '';
        var feedbackTxtVal = component.get("v.feedbackTxtInVal");
        var feedbackRated = component.get("v.feedbackRatingV");
        var childCmp = component.find("SuAnalytics");
        childCmp.analytics("pagerating", {
            articlesFeedback: true,
            articleFeedback: feedbackTxtVal,
            referer: document.referrer,
            window_url: window.location.href,
            uid: component.get("v.uid"),
            feedback: component.get("v.feedback"),
            rating: rating ? rating : '',
            feedback_type,
        });
        childCmp.analytics("searchfeedback", {
            feedback: feedbackAreaVal || '',
            rating: feedbackRated ? feedbackRated : '',
            reported_by: currentTxtEmailVal ? currentTxtEmailVal : '',
            conversion_url: window.location.href,
        });

        if (component.get("v.feedback") === "1") {
            component.set("v.feedbackActiveYes", true);
            component.set("v.feedbackActiveNo", false);
        } else {
            component.set("v.feedbackActiveYes", false);
            component.set("v.feedbackActiveNo", true);
        }
        component.set("v.pageRatingResponseRecorded", true);
        component.set('v.displayModal', false);
        component.set("v.emailShowhide", true);
        // component.set('v.isButtonActive',true);
        component.set("v.suResponseValues", false);
        component.set("v.TextdisplayModal", false);
    }
})