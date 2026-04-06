({
    doInit: function (component, event, helper) {
        const path = $A.get("$Resource.Deploymentjs");
        if (typeof path != 'undefined') {
            $A.createComponent("ltng:require", {
                "scripts": $A.get("$Resource.Deploymentjs")
            }, function (newButton, status, errorMessage) {
                console.log('Deploymentjs status', status);
            });
        }

        helper.doInitialization(component, event, helper);
    },
    handleOnLoad: function (component, event, helper) {
        console.log('here');
    },
    handleOnSubmit: function (component, event, helper) {
        console.log('handle handleOnSubmit')
    },
    changeLang: function (component, event, helper) {
        component.set("v.form", "false");
        localStorage.setItem("selectedLang", component.get("v.currentLanguage"))
        // console.log('test',component.get("v.currentLanguage"));
        var thumbUp = document.getElementsByClassName('thumb-up-img') ? document.getElementsByClassName('thumb-up-img') : [];
        var thumbDown = document.getElementsByClassName('thumb-up-img') ? document.getElementsByClassName('thumb-up-img') : [];
        for (let i = 0; i < thumbUp.length; i++) {
            document.getElementsByClassName('thumb-up-img')[i].setAttribute('disabled', true);
            document.getElementsByClassName('thumb-up-img')[i].style.cursor = 'not-allowed';
        }
        for (let i = 0; i < thumbDown.length; i++) {
            document.getElementsByClassName('thumb-down-img')[i].setAttribute('disabled', true);
            document.getElementsByClassName('thumb-down-img')[i].style.cursor = 'not-allowed';
        }
    },
    myFunction: function (component, event, helper) {
        var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
        if (isMobile) {
            helper.scrollToBottom(document.querySelector('.chat-section'), document.querySelector('.chat-section').scrollHeight, 500, helper);
        }
    },
    keyPressFuntion: function (component, event, helper) {
        if(!component.get("v.SFDC_liveAgent_invoked")) {
            if (typeof component.get('v.inactivityLimit') != 'undefined') {
                component.set('v.count', 0);
                var new_id = setInterval(function () {
                    if (component.get('v.count') == 0) {
                        if (component.get('v.inactivityMessage').length == 1)
                            helper.updateChat(component, component.get("v.robot"), component.get('v.inactivityMessage'), undefined, helper)
                        else
                            helper.updateChat(component, component.get("v.robot"), component.get('v.inactivityMessage')[Math.floor(Math.random() * Math.floor(2))], undefined, helper)
                    }
                    component.set('v.count', component.get('v.count') + 1);
                }, component.get('v.inactivityLimit') * 1000);
                for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                    var idToClear = component.get('v.inactivityLimitArray').pop();
                    clearInterval(idToClear);
                }
                component.get('v.inactivityLimitArray').push(new_id);
            }
        }
    },
    handleSaveSuccess: function (component, event, helper) {
        let responseJSON = event.getParams().response;
        let responseData = responseJSON.fields.CaseNumber.value;
        let recordId = responseJSON.id;
        let communityUrl = window.location.href.split('/s/')[0] + '/s/case/' + recordId;
        let result = 'The case has been created on Salesforce. Here’s the link <a href="' + communityUrl + '" target="_blank" >' + responseData + '</a>'
        helper.updateChat(component, component.get("v.robot"), result, undefined, helper);

        helper.createSession(component, responseData, helper);
        helper.remainingResponse(component,helper);
        let caseForm = component.find("recorded");
        $A.util.addClass(caseForm, "slds-hide");
    },
    handleOnError: function (component, event, helper) {
        let errorsMsg = JSON.parse(JSON.stringify(event.getParam("error"))).body.error ? JSON.parse(JSON.stringify(event.getParam("error"))).body.error : JSON.parse(JSON.stringify(event.getParam("error"))).body.message;
        component.set("v.errorsMsg", errorsMsg);
        component.set("v.cPermission", false);
        let caseForm = component.find("recorded");
        $A.util.addClass(caseForm, "slds-hide");
        helper.updateChat(component, component.get("v.robot"), errorsMsg, undefined, helper);
        helper.remainingResponse(component,helper);
    },
    createCase: function () {
        let windowHash = window.location.hash;
        let createCaseEvent = $A.get("e.force:createRecord");
        createCaseEvent.setParams({
            "entityApiName": "Case",
            'Origin': 'Phone',
            'Subject': 'calling from bot',
            'Description': 'calling from bot',
            "panelOnDestroyCallback": function (event) {
                $A.get('e.force:refreshView').fire();
            },
        });
        createCaseEvent.fire();
        let caseForm = component.find("recorded");
        $A.util.addClass(caseForm, "slds-hide");
    },
    endChat: function (component, event, helper) {
        helper.endChat(component, event, helper);
    },
    jump: function (component, event, helper) {
        document.querySelector('.text-bar input').value = event.target.innerText;
        helper.submitChat(component, true, helper);
    },
    getAgentChat: function (component, event, helper) {
        helper.getAgentChat(component, event, helper);
    },
    skipSubmit: function (component, event, helper) {
        //component.set("v.skip", true);
        document.getElementById('skip-img').style.pointerEvents = 'none';
        document.getElementById('skip-img').style.cursor = 'default';
        helper.submitChat(component, true, helper, true);
    },
    shownew: function (component, event, helper) {
        if (document.querySelector(".chat")) {
            var nodes = document.querySelector(".chat");
            while (nodes.childNodes.length > 1) {
                nodes.removeChild(nodes.lastChild);
            }
        }
        component.set("v.startBot", true);
        helper.welComeMsg(component, event, helper);
    },
    fldChanged: function (component, event, helper) {
        if (component.get("v.date") != undefined) {
            component.set("v.showDatepicker", false);
            helper.submitChatNew(component, true, helper);
        }
    },
    showResult: function (component, event, helper) {
        for (var i = 0; i < component.get("v.timeLimitArray").length; i++) {
            clearInterval(component.get("v.timeLimitArray").pop());
        }
        document.getElementById("waitingId").style.display = "none";
        component.set("v.startBot", false);
        document.querySelector(".contact-form-page").classList.toggle('show-profile');
        helper.welComeMsg(component, event, helper);

        document.querySelector('.contact-form-page').classList.add('chat-enter-to');
        setTimeout(function () {
            document.querySelector('.contact-form-page').classList.remove('chat-enter-to');
        }, 500);
        document.querySelector('.buttom-btn').classList.toggle('buttom-btn-hide');
        document.getElementById("live-chat").style.display = "block";

    },
    endAgentChatFromDialog: function (component, event, helper) {
        helper.endSFDCAgentChat(component, event, helper);
        document.getElementById('endAgentChatDialog').style.display = 'none';
    },
    closeEndAgentChatDialog: function (component, event, helper) {
        document.getElementById('endAgentChatDialog').style.display = 'none';
    },
    hideChat: function (component, event, helper) {

        if (component.get("v.SFDC_liveAgent_invoked")) {
            document.getElementById('endAgentChatDialog').style.display = 'block';
        }
        else {
            document.getElementById("waitingId").style.display = "none";

            if (document.querySelector('.chatbot-links-youtube') && document.querySelector('.chatbot-links-youtube').length) {
                document.querySelector('.chatbot-links-youtube').each(function () {
                    this.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', window.location.href);
                    console.log("Video Paused");
                })
            }

            if (typeof component.get("v.timeLimit") != 'undefined') {
                var ide = setInterval(function () {
                    document.getElementById("waitingId").style.display = "block";
                }, component.get("v.timeLimit") * 1000);
                for (var i = 0; i < component.get("v.timeLimitArray").length; i++) {
                    clearInterval(component.get("v.timeLimitArray").pop());
                }
                component.get("v.timeLimitArray").push(ide);
            }
            if (typeof component.get('v.inactivityLimit') != 'undefined') {
                for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                    var idToClear = component.get('v.inactivityLimitArray').pop();
                    clearInterval(idToClear);
                }
            }

            document.querySelector('.buttom-btn').classList.remove('buttom-btn-hide');
            document.querySelector('.contact-form-page').classList.remove('show-profile');
            document.getElementById('live-chat').style.display = 'none';
            document.querySelector('.contact-form-page').classList.add('chat-leaving');
            document.querySelector('.contact-form-page').classList.add('chat-leave-to');
            setTimeout(function () {
                document.querySelector('.contact-form-page').classList.remove('chat-leaving');
                document.querySelector('.contact-form-page').classList.remove('chat-leave-to');
            }, 500)
            if (document.querySelector(".chat")) {
                var nodes = document.querySelector(".chat");
                while (nodes.childNodes.length > 1) {
                    nodes.removeChild(nodes.lastChild);
                }
            }
        }
    },
    showConv: function (component, event, helper) {
        document.getElementById("live-chat").style.display = "block";
    },
    submitConv: function (component, event, helper) {
        if (event.keyCode == 13 && document.querySelector('.text-bar input').value.trim().length > 0) {

            helper.submitChat(component, true, helper);
        }
    },
    submitClick: function (component, event, helper) {
        helper.submitChat(component, true, helper);
    },
    updateChat: function (component, event, helper) {
        helper.updateChat(component, "party", "text", "label", helper);
    },
    openLang: function (component, event, helper) {
        document.querySelector('.settings-new').style.display = "block";
        if (typeof component.get('v.inactivityLimit') != 'undefined') {
            for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                var idToClear = component.get('v.inactivityLimitArray').pop();
                clearInterval(idToClear);
            }
        }
    },
    closeLang: function (component, event, helper) {
        document.querySelector('.settings-new').style.display = "none";
        if (typeof component.get('v.inactivityLimit') != 'undefined') {
            component.set('v.count', 0);
            var new_id = setInterval(function () {
                if (component.get('v.count') == 0) {
                    if (component.get('v.inactivityMessage').length == 1)
                        helper.updateChat(component, component.get("v.robot"), component.get('v.inactivityMessage'), undefined, helper)
                    else
                        helper.updateChat(component, component.get("v.robot"), component.get('v.inactivityMessage')[Math.floor(Math.random() * Math.floor(2))], undefined, helper)
                }
                component.set('v.count', component.get('v.count') + 1);
            }, component.get('v.inactivityLimit') * 1000);
            for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                var idToClear = component.get('v.inactivityLimitArray').pop();
                clearInterval(idToClear);
            }
            component.get('v.inactivityLimitArray').push(new_id);
        }
    }
})