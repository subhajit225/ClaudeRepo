({
    doInitialization: function (component, event, helper) {
        var action = component.get("c.getCommunityCustomSettings");
        var permission = ''
        action.setParams({
            "authParams": {
                "permission": permission
            }
        });
        action.setCallback(this, function (response) {
            if (response.getState() == "SUCCESS") {
                var result = response.getReturnValue();
                if (result.isCustomSettingFilled) {
                    component.set("v.endPoint", result.endPoint);
                    component.set("v.uid", result.uid);
                    component.set("v.currentCommunityURL", result.currentCommURL);
                    component.set("v.customSettingErrorMessage", "");
                    component.set("v.Bearer", result.token);
                    component.set("v.commBaseURL", result.commBaseURL);
                    component.set("v.sid", Math.floor(Math.random() * 100000 + 1));
                    component.set("v.icon", result.endPoint + "/resources/Assets/bot_msg.svg");
                    if(typeof GzAnalytics != 'undefined')
                        var sessionId = GzAnalytics.getsid();
                    else{
                        var analyticsCmp = component.find("SuAnalytics");
                        var sessionId = analyticsCmp.analytics('_gz_taid', '');
                    }
                    var userSession = component.get("v.userSession");
                    helper.getLanguages(component, event, helper);
                    var language;
                    if (localStorage.getItem("selectedLang") == undefined || localStorage.getItem("selectedLang") == null) {
                        // language = component.get("v.currentLanguage");
                        language = component.get("v.currentLanguage") ? component.get("v.currentLanguage") : (localStorage.getItem("language") ? localStorage.getItem("language") : 'en');
                    }
                    else {
                        language = localStorage.getItem("selectedLang");
                    }
                    var xmlHttp = new XMLHttpRequest();
                    var url = component.get("v.endPoint") + "/chatbot/api/chat_client_conf?pform=sfdc&uid=" + component.get("v.uid") + "&sessionId=" + sessionId + "&user_session_id=" + userSession + "&startBot=" + component.get("v.startBot") + "&lang=" + language + "&botAnalytics=false";
                    xmlHttp.open("GET", url, true);
                    xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
                    xmlHttp.setRequestHeader('Content-Type', 'application/json');

                    xmlHttp.send();
                    xmlHttp.onreadystatechange = function () {
                        if (xmlHttp.readyState === 4) {
                            if (xmlHttp.status === 200) {
                                var result = JSON.parse(xmlHttp.response);
                                if (result.statusCode != 402) {
                                    if (result.statusCode == 200) {
                                        var welcomeResult = atob(result.data.replace("b'", "").replace("'", ""));
                                        var responseData = JSON.parse(atob(result.data));
                                        helper.setConfig(component, responseData, helper);
                                        setTimeout(function () {
                                            component.set('v.showChatBot', true);
                                            if (responseData.basic_conf_data.user_engagment_message && responseData.basic_conf_data.user_engagment_message.length > 0) {
                                                document.getElementById('waitingId').innerHTML = responseData.basic_conf_data.user_engagment_message.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                                                component.set("v.timeLimit", responseData.basic_conf_data.user_engagment_limit);
                                                var ide = setInterval(function () {
                                                    document.getElementById("waitingId").style.display = "block";
                                                }, component.get("v.timeLimit") * 1000);
                                                for (var i = 0; i < component.get("v.timeLimitArray").length; i++) {
                                                    clearInterval(component.get("v.timeLimitArray").pop());
                                                }
                                                component.get("v.timeLimitArray").push(ide);
                                            }
                                            else
                                                document.getElementById("waitingId").style.display = "none";
                                        }, 1500);

                                    } else {
                                        component.set("v.customSettingErrorMessage", 'Please configure your SearchUnify and try again.');
                                    }
                                } else {
                                    $A.log("Errors", response.getState());
                                }
                            }
                        }
                    }
                }
            }

        });
        $A.enqueueAction(action);
        helper.bot = new helper.chatBot();

        document.addEventListener('click', function (event) {
            if (event.target.tagName === "BUTTON") {
                if (event.target.dataset.onclick) {
                    helper.updateChat(component, event.target.dataset.party, event.target.dataset.text, event.target.dataset.label, helper);
                }
            }

            // Get the modal
            let endAgentChatModal = document.getElementById('endAgentChatDialog');
            if (event.target == endAgentChatModal) {
                endAgentChatModal.style.display = "none";
            }
        });
    },
    endChatSession: function (component, event, helper) {
        window.clearInterval(component.get("v.setIntervalId"));
    },
    getLanguages: function (component, event, helper) {
        var xhttp_ajax = new XMLHttpRequest();
        var url = component.get("v.endPoint") + "/chatbot/api/languages?uid=" + component.get("v.uid");
        xhttp_ajax.open("GET", url, true);
        xhttp_ajax.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xhttp_ajax.setRequestHeader('Content-Type', 'application/json');
        xhttp_ajax.send();
        xhttp_ajax.onreadystatechange = function () {
            if (xhttp_ajax.readyState === 4) {
                if (xhttp_ajax.status === 200) {
                    let text = xhttp_ajax.responseText;
                    let resp = atob(text);
                    let responseData = JSON.parse(resp);
                    let data = JSON.parse(responseData.response);
                    let languages = data.data.languages_support;
                    component.set("v.languages", languages);
                    for (var i = 0; i < component.get("v.languages").length; i++) {
                        if (component.get("v.languages")[i].default == "true" && (localStorage.getItem("selectedLang") == undefined || localStorage.getItem("selectedLang") == null)) {
                            component.set("v.currentLanguage", component.get("v.languages")[i].lang);
                            localStorage.setItem("selectedLang", component.get("v.currentLanguage"));
                        }
                        else if (component.get("v.languages")[i].lang == localStorage.getItem("selectedLang")) {
                            component.set("v.currentLanguage", localStorage.getItem("selectedLang"));
                        }
                    }

                }
            }
        }
    },
    setupLiveAgent: function (component, event, helper) {
        if(typeof GzAnalytics != 'undefined')
            var sessionId = GzAnalytics.getsid();
        else{
            var analyticsCmp = component.find("SuAnalytics");
            var sessionId = analyticsCmp.analytics('_gz_taid', '');
        }
        var userSession = component.get("v.userSession");
        var xmlHttp = new XMLHttpRequest();
        xmlHttp.onreadystatechange = function () {
            if (this.readyState == 4 && this.status == 200) {
                var responseData = JSON.parse(atob(this.response));
                var response = JSON.parse(responseData.response);
                if (response.data) {
                    component.set("v.buttonId", (typeof response.data.buttonId != null) ? response.data.buttonId : '');
                    component.set("v.deploymentId", (typeof response.data.deploymentId != null) ? response.data.deploymentId : '');
                    component.set("v.agnetEndpoint", (typeof response.data.endpoint != null) ? response.data.endpoint : '');
                    component.set("v.orgId", (typeof response.data.orgId != null) ? response.data.orgId : '');
                }

            }
        }
        var url = component.get("v.endPoint") + "/chatbot/api/adapter_settings?type=SFDC&pform=sfdc&uid=" + component.get("v.uid") + "&sessionId=" + sessionId + "&user_session_id=" + userSession;
        xmlHttp.open("GET", url, true);
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.send();

    },
    startLiveAgent: function (component, event, helper) {
        if(typeof GzAnalytics != 'undefined')
            var sessionId = GzAnalytics.getsid();
        else{
            var analyticsCmp = component.find("SuAnalytics");
            var sessionId = analyticsCmp.analytics('_gz_taid', '');
        }
        var userSession = component.get("v.userSession");
        var xmlHttp = new XMLHttpRequest();
        xmlHttp.onreadystatechange = function () {
            if (this.readyState == 4 && this.status == 200) {
                var responseData = JSON.parse(atob(this.response));
                var messageData = JSON.parse(responseData.response);
                var message = messageData.data.replace(/,/g, '\n');

                if (window.liveagent) {
                    if (window.Prototype) {
                        delete Object.prototype.toJSON;
                        delete Array.prototype.toJSON;
                        delete Hash.prototype.toJSON;
                        delete String.prototype.toJSON;
                    }
                    let url = component.get("v.agnetEndpoint");
                    liveagent.init(url, component.get("v.deploymentId"), component.get("v.orgId"));
                    if (!window._laq) { window._laq = []; }
                    window._laq.push(function () {
                        liveagent.showWhenOnline(component.get("v.buttonId"), document.getElementById(component.get("v.buttonId") + '_online'));
                        liveagent.showWhenOffline(component.get("v.buttonId"), document.getElementById(component.get("v.buttonId") + '_offile'));
                        liveagent.addCustomDetail("Message ", message, true);
                    });

                    setTimeout(function () {
                        var liveButton = document.getElementById(component.get("v.buttonId") + '_online');
                        if (liveButton) {
                            liveagent.startChat(component.get("v.buttonId"));
                            if (document.querySelector(".chat")) {
                                var nodes = document.querySelector(".chat");
                                while (nodes.childNodes.length > 1) {
                                    nodes.removeChild(nodes.lastChild);
                                }
                            }
                        }
                    }, 3000);
                }

            }
        }
        var url = component.get("v.endPoint") + "/chatbot/api/chat_history_sfdc?pform=sfdc&uid=" + component.get("v.uid") + "&sessionId=" + sessionId + "&user_session_id=" + userSession;
        xmlHttp.open("GET", url, true);
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.send();

        var a = component.get('c.hideChat');
        $A.enqueueAction(a);
        var e = document.querySelector(".chat");
        var child = e.lastElementChild;
    },
    welComeMsg: function (component, event, helper) {

        component.set("v.type", "");
        component.set("v.Subject", "");
        component.set("v.Description", "");
        if (component.get("v.responseTypeLimit").length) {
            for (var i = 0; i < component.get("v.responseTypeLimit").length;) {
                clearInterval(component.get("v.responseTypeLimit").pop());
            }
        }

        //hide case form
        let caseForm = component.find("recorded");

        if (caseForm)
            $A.util.addClass(caseForm, "slds-hide");
        for (var i = 0; i < component.get("v.languages").length; i++) {
            if (component.get("v.languages")[i].default == "true" && (localStorage.getItem("selectedLang") == undefined || localStorage.getItem("selectedLang") == null)) {
                component.set("v.currentLanguage", component.get("v.languages")[i].lang);
                localStorage.setItem("selectedLang", component.get("v.currentLanguage"));
            }
            else if (component.get("v.languages")[i].lang == localStorage.getItem("selectedLang")) {

                component.set("v.currentLanguage", localStorage.getItem("selectedLang"));
            }
        }
        if (component.get("v.date") == undefined) {
            component.set("v.showDatepicker", false);
        }
        if (document.getElementById('submit')) {
            document.getElementById("submit").removeEventListener("focusout", helper.hideMonth);
            document.getElementById("submit").removeEventListener("click", helper.showMonth);
            document.getElementById("submit").type = "text";
            document.getElementById("submit").readOnly = false;
            document.querySelector(".text-bar a").style.pointerEvents = "auto";
            document.querySelector(".text-bar a").style.display = "pointer";
        }

        document.querySelector('.settings-new').style.display = "none";
        document.getElementById('month_1').style.display = "none";
        document.getElementById('loading').style.display = 'block';
        document.getElementById('notLoading').style.display = 'none';
        document.getElementById('third-section').style.display = 'none';
        document.querySelector('.chat').style.display = 'none';
        document.querySelector('.loading').style.display = 'block';
        component.set("v.entity", '');
        var wel_msg;
        var permission = '';
        if(typeof GzAnalytics != 'undefined')
            var sessionId = GzAnalytics.getsid();
        else{
            var analyticsCmp = component.find("SuAnalytics");
            var sessionId = analyticsCmp.analytics('_gz_taid', '');
        }
        var userSession = component.get("v.userSession");
        var data = JSON.stringify({
            "flag": 1,
            "pform": "sfdc"
        });
        //commented for live agent 
        //helper.setupLiveAgent(component, event, helper);
        var xmlHttp = new XMLHttpRequest();
        var url = component.get("v.endPoint") + "/chatbot/api/chat_client_conf?pform=sfdc&uid=" + component.get("v.uid") + "&sessionId=" + sessionId + "&user_session_id=" + userSession + "&startBot=" + component.get("v.startBot") + "&lang=" + component.get("v.currentLanguage") + "&botAnalytics=true";
        xmlHttp.open("GET", url, true);
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xmlHttp.setRequestHeader('Content-Type', 'application/json');

        xmlHttp.send();
        xmlHttp.onreadystatechange = function () {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.statusCode != 402) {
                        if (result.statusCode == 200) {
                            component.set('v.previousParty', '');
                            var welcomeResult = atob(result.data.replace("b'", "").replace("'", ""));
                            var responseData = JSON.parse(atob(result.data));
                            document.querySelector('.start-over a').style.pointerEvents = 'auto';
                            document.querySelector('.start-over a').style.cursor = 'pointer';
                            helper.setConfig(component, responseData, helper);
                            if (responseData.basic_conf_data.welcome_message.type == 'response') {
                                var data = responseData.basic_conf_data.welcome_message.value;
                                component.set("v.sendResponse", true);
                                helper.bot.respondTo(component, data, helper, function (err, reply) {
                                    if (reply == null) return;
                                    helper.updateChat(component, component.get("v.robot"), reply, undefined, helper);
                                });
                                component.set("v.sendResponse", false);
                            }
                            else {
                                wel_msg = responseData.basic_conf_data.welcome_message.value
                            }

                            // CHECK IF SFDC LIVE AGENT ACTIVE or NOT
                            if (component.get("v.SFDC_liveAgent_invoked")) {
                                // heading
                                document.querySelector('.heading-chat').innerHTML = component.get("v.agentName");
                                // end chat button title change
                                document.querySelector(".close-bot-icon").setAttribute("title", "End Agent Chat");
                            }
                            else {
                                //searchunify bot name change
                                if (responseData.basic_conf_data.bot_title == "" || responseData.basic_conf_data.bot_title == undefined) {
                                    document.querySelector('.heading-chat').innerHTML = "SearchUnify Bot";
                                    component.set("v.actualBotHeading", "SearchUnify Bot");
                                    localStorage.setItem("actualBotHeading", "SearchUnify Bot");
                                }
                                else {
                                    document.querySelector('.heading-chat').innerHTML = responseData.basic_conf_data.bot_title;
                                    component.set("v.actualBotHeading", responseData.basic_conf_data.bot_title);
                                    localStorage.setItem("actualBotHeading", responseData.basic_conf_data.bot_title);
                                }

                                document.querySelector(".close-bot-icon").setAttribute("title", "Close");

                                component.set("v.sendAgain", true);
                                component.set("v.SFDCendchatclicked", false);
                            }

                            // title
                            document.querySelector('.left-first-section').style.backgroundColor = responseData.theme_data.title.board_color;
                            document.querySelector('.heading-chat').style.color = responseData.theme_data.title.text_color;

                            // chat box
                            document.querySelector('.chat-section').style.backgroundColor = responseData.theme_data.chat_box.board_color;
                            document.querySelector('.start-over').style.backgroundColor = responseData.theme_data.chat_box.board_color;
                            // type message area
                            document.querySelector('.third-section').style.backgroundColor = responseData.theme_data.type_message_area.board_color;
                            document.querySelector('.text-bar input').style.backgroundColor = responseData.theme_data.type_message_area.board_color;
                            document.querySelector('.text-bar input').style.color = responseData.theme_data.type_message_area.text_color;

                            // font change
                            document.querySelector('.contact-form-page').style.fontFamily = responseData.theme_data.font.font_style;
                            document.querySelector('.text-bar input').style.fontFamily = responseData.theme_data.font.font_style;

                            //icon change
                            document.querySelector('.logo-bot').src = component.get("v.endPoint") + '/' + responseData.theme_data.chatbot_icons.chatbot_avatar;
                            document.querySelector('.close-bot-icon').src = component.get("v.endPoint") + '/' + responseData.theme_data.chatbot_icons.chatbot_close_icon;
                            component.set("v.icon", component.get("v.endPoint") + '/' + responseData.theme_data.chatbot_icons.chatbot_icon);
                            if (responseData.theme_data.chatbot_icons.chatbot_skip_icon == undefined || responseData.theme_data.chatbot_icons.chatbot_skip_icon == '' || responseData.theme_data.chatbot_icons.chatbot_skip_icon.includes('resources/Assets')) {
                                document.getElementById('skip-img').src = component.get("v.endPoint") + '/assets/img/skip_new.svg';
                            }
                            else {
                                document.getElementById('skip-img').src = component.get("v.endPoint") + '/' + responseData.theme_data.chatbot_icons.chatbot_skip_icon;
                            }
                            if (responseData.theme_data.chatbot_icons.chatbot_startOver_icon == undefined || responseData.theme_data.chatbot_icons.chatbot_startOver_icon == '' || responseData.theme_data.chatbot_icons.chatbot_startOver_icon.includes('resources/Assets')) {
                                document.getElementById('start-img').src = component.get("v.endPoint") + '/assets/img/start.svg';
                            }
                            else {
                                document.getElementById('start-img').src = component.get("v.endPoint") + '/' + responseData.theme_data.chatbot_icons.chatbot_startOver_icon;
                            }
                            document.getElementById('loading').style.display = 'none';
                            document.getElementById('notLoading').style.display = 'block';
                            document.getElementById('third-section').style.display = 'block';
                            document.querySelector('.chat').style.display = 'block';
                            document.getElementById('load-img').style.display = 'none';
                            document.querySelector('.loading').style.display = 'none';
                            if (typeof responseData.basic_conf_data.inactivityData_messageLimit != 'undefined' && responseData.basic_conf_data.inactivityData_messageLimit != null) {
                                component.set('v.inactivityLimit', responseData.basic_conf_data.inactivityData_messageLimit);
                                for (var i = 0; i < responseData.basic_conf_data.inactivityData.responseArray.length; i++) {
                                    responseData.basic_conf_data.inactivityData.responseArray[i] = responseData.basic_conf_data.inactivityData.responseArray[i].replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                                }
                                component.set('v.inactivityMessage', responseData.basic_conf_data.inactivityData.responseArray);
                                var inactive = {};
                                inactive['type'] = "Inactivity"
                                component.set('v.inactive', inactive);
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
                            if (responseData.history_data != undefined && responseData.history_data.length) {

                                document.getElementById('loading').style.display = 'block';
                                document.getElementById('notLoading').style.display = 'none';
                                document.querySelector('.chat').style.display = 'none';
                                document.querySelector('.loading').style.display = 'block';
                                document.getElementById('third-section').style.display = 'none';
                                responseData.history_data.forEach(function (chat) {
                                    if (chat.party != 'You') {
                                        var history = JSON.parse(chat.conversation);
                                        history.forEach(function (data) {
                                            data['history'] = true;
                                            if (data.type == 'case')
                                                data = "Request for Case Creation";
                                            if (data.type == 'sfdcLegacy' || data.type == 'sfdcEmbedded')
                                                data = "Request for Live Agent ";
                                            if (data.type == 'prompt') {
                                                var data1 = {};
                                                data1['type'] = 'text';
                                                data1['history'] = true;
                                                data1['response'] = typeof data.response == 'object' ? '' : data.response;
                                                if (data.position && data.position == 'after')
                                                    data1['response'] = data.title;
                                                else if (data.position && data.position == 'before') {
                                                    var beforeData = {};
                                                    beforeData['type'] = 'text';
                                                    beforeData['history'] = true;
                                                    beforeData['response'] = data.title;
                                                    helper.updateChat(component, component.get("v.robot"), beforeData, undefined, helper);
                                                }
                                                if (data.choices && data.choices.length > 0) {
                                                    var optionData = {};
                                                    optionData['history'] = true;
                                                    optionData['position'] = "before";
                                                    optionData['title'] = data1['response'];
                                                    optionData['type'] = "options";
                                                    optionData['response'] = [];
                                                    for (var i = 0; i < data.choices.length; i++) {
                                                        var response = { 'label': '' };
                                                        response.label = data.choices[i];
                                                        optionData['response'].push(response);
                                                    }
                                                    data1 = optionData;
                                                }
                                                data = data1
                                            }
                                            if (data.type == 'pause')
                                                data.response = '';
                                            if (data.response != '')
                                                helper.updateChat(component, component.get("v.robot"), data, undefined, helper);
                                        })

                                    } else {
                                        var data = {};
                                        data['type'] = 'text';
                                        data['history'] = true;
                                        data['response'] = chat.conversation;
                                        helper.updateChat(component, 'You', data, undefined, helper)
                                    }
                                })
                                document.getElementById('loading').style.display = 'none';
                                document.getElementById('notLoading').style.display = 'block';
                                document.querySelector('.chat').style.display = 'block';
                                helper.scrollToBottom(document.querySelector('.chat-section'), document.querySelector('.chat-section').scrollHeight, 3500, helper);

                                document.querySelector('.loading').style.display = 'none';
                                document.getElementById('third-section').style.display = 'block';

                                let disableButton = document.querySelectorAll('.chatbot-button-response');
                                if (disableButton.length != 0) {
                                    for (var i = 0; i < disableButton.length; i++) {
                                        disableButton[i].setAttribute("disabled", true);
                                        disableButton[i].classList.add('disable-button');
                                        disableButton[i].style.cursor = "not-allowed";
                                    }
                                }

                            }
                            else {
                                if (responseData.basic_conf_data.welcome_message.type == 'text')
                                    helper.updateChat(component, component.get("v.robot"), wel_msg, undefined, helper);
                            }

                        }
                        else if (result.status = 401) {
                            var responseData = JSON.parse(atob(result.data));
                            wel_msg = responseData.response.responses[0].response;
                            helper.updateChat(component, component.get("v.robot"), wel_msg, undefined, helper);
                        }
                    }
                }
            }
        }
        document.querySelector('.start-over a').style.pointerEvents = 'none';
        document.querySelector('.start-over a').style.cursor = 'default';
        document.querySelector('.start-over a').style.position = 'relative';
        document.querySelector('.start-over a').style.display = 'inline-block';

    },
    updateChat: function (component, party, text, label, helper) {
        if (component.get("v.entity") == "date.month") {
            setTimeout(function () {
                document.getElementById("submit").removeEventListener("click", showMonth);
                document.getElementById("submit").removeEventListener("focusout", hideMonth);
            }, 1000);
        }
        var chat = document.querySelector('.chat');
        var you = 'You';
        var x = '';
        var style = '';
        if (component.get('v.previousParty').toLowerCase() == party.toLowerCase())
            component.set('v.partyCheck', false);
        else
            component.set('v.partyCheck', true);
        if (typeof text.ignoreIcon && text.ignoreIcon == false)
            component.set('v.partyCheck', true);
        if (component.get('v.inactive') && component.get('v.inactive').type == "Inactivity" && Array.isArray(text))
            component.set('v.partyCheck', true);
        if (!(typeof text == 'object' && text.type == 'suadapter' || text.type == 'pause' || text.type == 'sfdcEmbedded' || (text.type == 'prompt' && typeof text.position == 'undefined')))
            component.set('v.previousParty', party.toLowerCase());

        for (var i = 0; i < document.querySelector('.chat').childNodes.length; i++) {
            if (document.querySelector('.chat').childNodes[i].lastChild && document.querySelector('.chat').childNodes[i].lastChild.className == 'chatbot-links-youtube')
                document.querySelector('.chat').childNodes[i].remove();
        }

        if (!component.get("v.SFDC_liveAgent_invoked")) {
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

        if (document.querySelector('.chatbot-links-youtube') && document.querySelector('.chatbot-links-youtube').length) {
            document.querySelector('.chatbot-links-youtube').each(function () {
                this.contentWindow.postMessage('{"event":"command","func":"pauseVideo","args":""}', window.location.href);
                console.log("Video Paused");
            })
        }
        if (party != you) {
            // document.getElementById('load-img').style.display = 'block';
            style = 'other';
            var line = helper.getBotHTML(component, text, helper);
            component.set("v.previousResponseType", text.type ? text.type : '');
        } else {
            component.set("v.previousResponseType", '');
            if (label != undefined) {
                if (component.get("v.setSlots") == true) {
                    helper.sendSlotsResponce(component, text, label, helper);
                }
                var line = helper.getUserHTML(component, label, helper);
                setTimeout(function () {
                    if ((text.indexOf('value') == -1 && text.indexOf('response') == -1) || typeof text === "string") {
                        var line2 = helper.getBotHTML(component, text, helper);
                        chat.appendChild(line2);
                        helper.scrollToBottom(document.querySelector('.chat-section'), document.querySelector('.chat-section').scrollHeight, 500, helper);
                        if (document.getElementById('submit')) {
                            document.getElementById('submit').removeAttribute('disabled');
                            document.getElementById('submit').setAttribute('placeholder', 'Start your Conversation');
                            document.getElementById('submit').value = '';
                        }

                        if (window.matchMedia("(min-width: 320px)" && "(max-width: 480px)").matches) {
                            if (document.getElementById('submit')) {
                                document.getElementById("submit").blur();
                            }
                        }
                        else {
                            if (document.getElementById('submit')) {
                                document.getElementById('submit').focus();
                            }
                        }
                    } else {
                        text = JSON.parse(text);
                        var line2 = helper.getBotHTML(component, text, helper);
                        chat.appendChild(line2);
                        helper.scrollToBottom(document.querySelector('.chat-section'), document.querySelector('.chat-section').scrollHeight, 500, helper);
                        if (document.getElementById('submit')) {
                            document.getElementById('submit').removeAttribute('disabled');
                            document.getElementById('submit').setAttribute('placeholder', 'Start your Conversation');
                            document.getElementById('submit').value = '';
                        }
                        if (window.matchMedia("(min-width: 320px)" && "(max-width: 480px)").matches) {
                            document.getElementById("submit").blur();
                        }
                        else {
                            document.getElementById('submit').focus();
                        }
                    }
                }, 1000)
            } else {
                if (typeof text == "object") {
                    var line = helper.getUserHTML(component, text.response, helper);
                }
                else
                    var line = helper.getUserHTML(component, text, helper);
            }
        }
        if (text != '' && typeof line != 'undefined') {
            chat.appendChild(line)
        }
        if (party == 'You') {
            var response = document.querySelectorAll('.right-chat .response');
            helper.colorChange(component, party, response, helper);
            if (!text.history) {
                if (!component.get("v.SFDC_liveAgent_invoked") && component.get("v.caseResponse") && component.get("v.caseResponse").type == "") {
                    setTimeout(function () {
                        if (document.getElementById('submit')) {
                            document.getElementById("submit").setAttribute('disabled', true);
                            document.getElementById("submit").setAttribute('placeholder', component.get("v.robot") + ' is typing ...');
                        }
                    }, 100);
                }

            }
        } else {
            var response = document.querySelectorAll('.chat div .party');
            helper.colorChange(component, party, response, helper);
        }
        helper.scrollToBottom(document.querySelector('.chat-section'), document.querySelector('.chat-section').scrollHeight, 500, helper);

        if (document.getElementById('submit')) {
            document.getElementById('submit').removeAttribute('disabled');
            document.getElementById('submit').setAttribute('placeholder', 'Start your Conversation');

            if (!component.get("v.SFDC_liveAgent_invoked")) {
                document.getElementById('submit').value = '';
            }
        }
        else if (typeof text.type != 'undefined' && text.type == 'prompt' && text.choices && text.choices.length > 0) {
            document.getElementById('submit').setAttribute('disabled', true);
        }
        if (window.matchMedia("(min-width: 320px)" && "(max-width: 480px)").matches) {
            if (document.getElementById('submit')) {
                document.getElementById("submit").blur();
            }
        }
        else {
            if (document.getElementById('submit')) {
                document.getElementById('submit').focus();
            }
        }

        if ((typeof text.disableUserInput != 'undefined' && text.disableUserInput == "true") || (text.type == "pause" && !text.lastPause)) {
            document.getElementById('submit').setAttribute('disabled', true);
            document.querySelector('.text-bar a').style.pointerEvents = 'none';
            document.querySelector('.text-bar a').style.cursor = 'default';
            document.getElementById("submit").disabled = true
        }
        else if (document.getElementById('submit')) {
            document.getElementById('submit').removeAttribute('disabled');
            document.getElementById("submit").disabled = false
        }
        if (text.type && text.type == 'prompt' && text.choices.length > 0) {
            document.getElementById('submit').setAttribute('disabled', false);
            document.querySelector(".text-bar a").style.pointerEvents = "none";
            document.querySelector(".text-bar a").style.display = "default";
        }
    },
    createCaseForm: function (component, casevalues, helper) {
        let resultToPass = [];
        let resultToPasstemp = [];
        for (const [key, value] of Object.entries(casevalues)) {
            resultToPass.push({
                'label': key.charAt(0).toUpperCase() + key.slice(1),
                'value': key.charAt(0).toUpperCase() + key.slice(1),
                'setValue': value,
                "required": false,
                "type": "text"
            });


        }

        component.set("v.fieldsArray", resultToPass);
        component.set("v.isLoaded", true);
        component.set("v.form", false);
        let isPermission = component.get("v.cPermission");
        if (isPermission) {
            setTimeout(function () {
                component.find("recorded").submit();
            }, 1000);
        }
        else {
            component.set("v.errorMessage", "The case could not be created.")
            helper.updateChat(component, component.get("v.robot"), component.get("v.errorMessage"), undefined, helper);
            helper.remainingResponse(component, helper);
        }
        component.set("v.Subject", "");
        component.set("v.Description", "");
    },
    submitChatNew: function (component, input, helper) {
        helper.submitChat(component, input, helper);

    },
    chatBot: function (component, input, helper) {
        this.input;
        this.respondTo = function (component, input, helper, callback) {


            if(typeof GzAnalytics != 'undefined')
                var sessionId = GzAnalytics.getsid();
            else{
                var analyticsCmp = component.find("SuAnalytics");
                var sessionId = analyticsCmp.analytics('_gz_taid', '');
            }
            var userSession = component.get("v.userSession");
            var data = {
                "sessionId": sessionId,
                "query": input,
                "uid": component.get("v.uid"),
                "pform": 'sfdc',
                "user_session_id": userSession,
                "lang": component.get("v.currentLanguage"),
                "name": component.get("v.storySelected").trim().length > 0 ? component.get("v.storySelected") : '',
                "prompt": component.get("v.isPrompt") ? component.get("v.isPrompt") : '',
                "ent_type": component.get("v.ent_type").trim().length > 0 ? component.get("v.ent_type") : '',
                "bot_memory": component.get("v.bot_memory").trim().length > 0 ? component.get("v.bot_memory") : '',
                "start": component.get("v.sendResponse") ? true : false
            };
            if (component.get('v.user_feedback'))
                data['user_feedback'] = component.get('v.user_feedback');
            else
                delete data['user_feedback'];

            if (typeof input == 'object' && input.type == 'prompt') {
                data.query = input.choice;
                Object.assign(data, input);
                delete data['choice'];
                delete data['type'];
            }
            if (typeof input == 'object' && input.type == 'link') {
                data['link_click'] = data.query['link_click'];
                data['response_type'] = data.query['response_type'];
                data['query'] = data.query.response;
            }
            if (data.prompt == '')
                delete data['prompt'];
            if (data.ent_type == '')
                delete data['ent_type']
            if (data.bot_memory == '')
                delete data['bot_memory']
            data = JSON.stringify(data);

            var xmlHttp = new XMLHttpRequest();
            var url = component.get("v.endPoint") + "/chatbot/api/response";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.send(data);
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {

                        document.querySelector('.start-over a').style.pointerEvents = 'auto';
                        document.querySelector('.start-over a').style.cursor = 'pointer';


                        document.querySelector('.start-over a').style.pointerEvents = 'auto';
                        document.querySelector('.start-over a').style.cursor = 'pointer';

                        var result = JSON.parse(atob(xmlHttp.response));
                        if (!(result.message && result.message == 'response recorded')) {

                            component.set("v.storySelected", result.name);
                            component.set("v.isPrompt", result.prompt);
                            component.set("v.feedback_type", result.feedback_type ? result.feedback_type : '');


                            for (var i = 0; i < result.responses.length; i++) {
                                if (result.responses[i].type == 'pause') {
                                    if (i == 0) {
                                        var r = i + 1;
                                        while (r && r < result.responses.length) {
                                            if (result.responses[r].type != 'pause') {
                                                result.responses[r].ignoreIcon = false;
                                                r = 0;
                                            }
                                            else {
                                                result.responses[r].ignoreIcon = false;
                                                r++;
                                            }
                                        }
                                    }
                                    if (i == result.responses.length - 1) {
                                        result.responses[i].lastPause = true;
                                        if (result.responses[result.responses.length - 1].lastPause && (typeof result.responses[result.responses.length - 1].ignoreIcon != 'undefined' && result.responses[result.responses.length - 1].ignoreIcon == false) || result.responses[result.responses.length - 1].lastPause)
                                            result.responses[result.responses.length] = { type: "empty", delay: result.responses[i].delay ? result.responses[i].delay : result.responses[i].response, hideIcon: true }

                                        else
                                            result.responses[result.responses.length] = { type: "empty", delay: result.responses[i].delay }
                                    }
                                    if (typeof result.responses[i].delay != 'undefined') {
                                        result.responses[i].delay -= result.responses[i].response;
                                    }
                                }

                                else if (result.responses[i].type == 'suadapter') {
                                    for (var j = i + 1; j < result.responses.length; j++) {
                                        typeof result.responses[j].delay != 'undefined' ? result.responses[j].delay += 1 : null;
                                    }
                                }
                            }
                            for (var i = 0; i < result.responses.length; i++) {
                                typeof result.responses[i].delay != 'undefined' && result.responses[i].type != 'pause' ? result.responses[i].delay += (i * 0.5) : undefined;
                            }
                            component.set("v.previousResponse", []);
                            result.responses = helper.breakingResponse(component, result.responses);

                            for (var i = 0; i < result.responses.length; i++) {
                                (function (i) {
                                    var pauseTime = 0;
                                    result.responses[i].delay ? pauseTime = result.responses[i].delay : pauseTime = 0;
                                    var idLimit = window.setTimeout(function () {
                                        for (let count = 0; count < document.querySelectorAll('.loading-img').length; count++) {
                                            document.querySelectorAll('.loading-img')[count].parentNode.parentElement.style.margin = 0;
                                            document.querySelectorAll('.loading-img')[count].style.display = "none";
                                            document.getElementById('submit').removeAttribute('disabled');
                                        }
                                        if (result.responses[i].type != 'empty')
                                            callback(null, result.responses[i]);
                                        if (result.responses[i].hideIcon && component.get('v.previousParty') == 'You')
                                            document.querySelectorAll('.left-img')[document.querySelectorAll('.left-img').length - 1].style.display = 'none';

                                    }, pauseTime * 1000)
                                    component.get("v.responseTypeLimit").push(idLimit);
                                }(i));

                            }
                        }
                    } else {
                        document.querySelector('.start-over a').style.pointerEvents = 'auto';
                        document.querySelector('.start-over a').style.cursor = 'pointer';
                        callback(null, 'Sorry, connection interrupted. Please try again after some time.');
                    }
                }
            }


        }
        this.match = function (regex) {
            return new RegExp(regex).test(this.input);
        }
        this.randomElement = function (x) {
            return x[Math.floor(Math.random() * this.length)]
        }
    },
    breakingResponse: function (component, y) {
        var j = 0;
        for (var i = 0; i < y.length; i++) {
            if (i == y.length - 1) {
                component.get("v.previousResponse").push(y.slice(j, y.length))
            }
            else if (y[i + 1] && (y[i].type == 'sfdcLegacy' || y[i].type == 'case' || y[i].type == "sfdcEmbedded")) {
                component.get("v.previousResponse").push(y.slice(j, i + 1));
                j = i + 1;
            }
        }
        return component.get("v.previousResponse").shift();
    },

    submitChat: function (component, condition, helper, skipButton) {
        var input;
        var type = component.get("v.responseType");
        var required = component.get("v.required");
        var entity = component.get("v.entity");
        if (skipButton == undefined) {
            skipButton = false;
        }
        var disable = document.querySelectorAll('.chatbot-button-response');

        if (disable.length != 0) {
            for (var i = 0; i < disable.length; i++) {
                disable[i].setAttribute("disabled", true);
            }
        }
        if (component.get("v.date") == undefined && entity != "date") {

            input = document.querySelector('.text-bar input').value;
        } else if (component.get("v.date") == undefined && entity == "date") {
            input = '';
        }
        else {
            input = component.get("v.date");
            component.set("v.date", undefined);
        }


        if (entity != undefined && entity == "date.month") {
            if (parseInt(input) < 10) {
                var input = "0" + input.toString();
            } else {
                if (input != undefined) {
                    var input = input.toString();
                }
                else {
                    var input = '';
                }
            }

            document.querySelector(".text-bar a").style.pointerEvents = "auto";
            document.querySelector(".text-bar a").style.display = "pointer";
            document.getElementById('month_1').style.display = "none";
        }
        if (component.get("v.date") == undefined) {
            component.set("v.showDatepicker", false);

        }
        else if (entity != undefined && entity == "date.year") {
            var input = document.querySelector('.text-bar input').value;
            document.getElementById("submit").type = 'text';
            document.getElementById("submit").min = '';
            document.getElementById("submit").max = '';
            document.getElementById("submit").readOnly = false;
        }
        if (input == '' && (required == "true" || required == undefined) && (component.get("v.feedback_response") == undefined || component.get("v.feedback_response") !== "true")) {
            if (document.getElementById("submit")) {
                document.getElementById('submit').removeAttribute('disabled');
                document.getElementById('submit').setAttribute('placeholder', 'Start your Conversation');

            }
            document.querySelector('chatbot-button-response').removeAttribute('disabled');
            return false;

        }
        document.getElementById('month_1').style.display = "none";
        if (document.getElementById("submit")) {
            document.querySelector(".text-bar a").style.pointerEvents = "auto";
            document.querySelector(".text-bar a").style.display = "pointer";
            document.querySelector('.text-bar input').value = '';
        }
        if (!input.replace(/\s/g, '').length && skipButton == false && (required == undefined || required == "true" || required == "false")) {
            return;
        }
        if (input == '' && (required == undefined || required == "true") && (component.get("v.feedback_response") == undefined || component.get("v.feedback_response") !== "true")) {
            return;
        }
        if (skipButton == false && input == '') {
            return;
        }
        if (skipButton == true) {
            var input = '';
        }
        document.getElementById('skip-img').style.pointerEvents = 'none';
        document.getElementById('skip-img').style.cursor = 'default';
        document.getElementById('skip-img').style.position = "unset";
        if (input != '') {
            helper.updateChat(component, 'You', input, undefined, helper);
            if (component.get("v.SFDC_liveAgent_invoked")) {
                if (typeof component.get('v.inactivityLimit') != 'undefined') {
                    for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                        var idToClear = component.get('v.inactivityLimitArray')[i];
                        clearInterval(idToClear);
                    }
                    component.set('v.inactivityLimitArray', []);
                }
            }
        }

        if (skipButton == true) {
            input = 'SU-BOT-SKIP';
            component.set('v.partyCheck', true);
        }

        if (type == "case" && component.get("v.Subject") == '' && component.get("v.Description") == '') {
            component.set("v.Subject", input);
            helper.updateChat(component, component.get("v.robot"), component.get('v.caseResponse').description, undefined, helper);
            return;
        }
        if (typeof component.get("v.Subject") != 'undefined' && component.get("v.Subject") != '') {
            component.set("v.Description", input);
            let data = {};
            data['Subject'] = component.get("v.Subject");
            data['Description'] = component.get("v.Description");
            var response = helper.createCaseForm(component, data, helper);
            setTimeout(function () {
                return;
            }, 1000);
        }
        else if (component.get("v.SFDC_liveAgent_invoked")) {
            helper.sendMessageToAgent(component, input, helper);
            if (typeof component.get('v.inactivityLimit') != 'undefined') {
                for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                    var idToClear = component.get('v.inactivityLimitArray')[i];
                    clearInterval(idToClear);
                }
                component.set('v.inactivityLimitArray', []);
            }
        }
        else {
            helper.bot.respondTo(component, input, helper, function (err, reply) {
                if (reply == null) return;
                helper.updateChat(component, component.get("v.robot"), reply, undefined, helper);
            });
        }
    },
    scrollToBottom: function (element, to, duration, helper) {
        if (element.scrollHeight > 500) {
            element.scrollTop = element.scrollHeight;
        }
        else {
            if (duration < 0) return;
            var scrollTop = element.scrollTop;
            var difference = to - scrollTop;
            var perTick = difference / duration * 10;

            setTimeout(function () {
                scrollTop = scrollTop + perTick;
                element.scrollTop = scrollTop;
                if (scrollTop === to) return;
                helper.scrollToBottom(element, to, duration - 10, helper);
            }, 10);
        }
    },
    setConfig: function (component, themeData, helper) {
        component.set("v.robot", themeData.basic_conf_data.bot_name);
        component.set("v.userSession", themeData.user_session_id)
        component.set("v.sessionID", _gr_utility_functions.getCookie("_gz_sid"));
        localStorage.setItem("themeData", JSON.stringify(themeData));
    },
    getConfig: function (component, helper) {
        return localStorage.getItem("themeData");
    },

    getBotHTML: function (component, response, helper) {
        var div = document.createElement('div');
        var a = document.createElement('li');
        var b = document.createElement('div');
        b.className = 'left-chat';
        var img = document.createElement('img');
        img.setAttribute("src", component.get("v.icon"));
        img.className = 'left-img';
        var d = document.createElement('div');
        d.className = 'party';
        document.getElementById("submit").readOnly = false;
        document.querySelector(".text-bar a").style.pointerEvents = "auto";
        document.querySelector(".text-bar a").style.display = "pointer";
        document.getElementById('skip-img').style.display = 'none';
        document.getElementById('skip-img').style.position = "unset";
        component.set("v.form", response.form);
        component.set("v.required", response.required);
        component.set("v.responseType", response.type);
        component.set("v.entity", response.ent_type);

        component.set("v.feedback_response", response.feedback_response);
        component.set("v.user_feedback", false);

        document.getElementById("submit").type = "text";
        document.getElementById("submit").readOnly = false;
        document.getElementById('submit').setAttribute('disabled', false)
        document.getElementById("submit").removeEventListener("click", helper.showMonth);
        document.getElementById("submit").removeEventListener("focusout", helper.hideMonth);


        document.querySelector('.text-bar a').style.cursor = 'pointer';
        var caseResponse = {};
        caseResponse['type'] = "";
        component.set("v.caseResponse", caseResponse);

        if (component.get('v.partyCheck'))
            a.appendChild(img);
        if (document.querySelectorAll('.loading-img-div').length) {
            for (var i = 0; i < document.querySelectorAll('.loading-img-div').length; i++) {
                document.querySelectorAll('.loading-img-div')[i].style.display = "none";
            }
        }
        if (response.type == 'options') {

            var e = document.createElement('p');
            e.className = 'chatbot-heading';
            e.innerHTML = response.title;
            d.appendChild(e);
            var z = document.createElement('div');
            z.className = 'button-msg';
            if (response.confirm != "true") {
                e.innerHTML = response.response.title;
            }
            response.response.forEach(function (data) {
                {

                    var f = document.createElement('button');
                    f.className = 'btn btn-default chatbot-button-response';
                    f.innerHTML = data.label;
                    f.addEventListener('click', function () {
                        helper.updateChat(component, 'You', data.label, undefined, helper);
                        for (var i = 0; i < z.childNodes.length; i++) {
                            z.childNodes[i].setAttribute("disabled", true);
                        }
                        f.setAttribute("class", 'btn btn-default chatbot-response-disable');
                        document.getElementById('submit').setAttribute('disabled', true)
                        document
                            .getElementById('submit')
                            .setAttribute('placeholder', component.get("v.robot") + ' is typing...')

                        helper.bot.respondTo(component, '/' + data.name + '{' + data.label + '}', helper, function (err, reply) {
                            if (reply == null) return;
                            var latency = Math.floor(Math.random() * (helper.delayEnd - helper.delayStart) + helper.delayStart)
                            if (document.querySelector('.busy')) {
                                document.querySelector('.busy').style.display = 'block'
                            }
                            helper.waiting++
                            setTimeout(function () {
                                helper.updateChat(component, component.get("v.robot"), reply, undefined, helper);
                                if (--helper.waiting == 0 && document.querySelector('.busy')) {
                                    document.querySelector('.busy').style.display = 'none';
                                }
                            }, latency)
                        })


                    }, { once: true });
                    z.appendChild(f);
                }
            })

            if (typeof response.position != 'undefined' && response.position.toLowerCase().trim().length == 0) {
                img.className = "left-img option-img"
                b.appendChild(z);
            }
            else {
                d.innerHTML = response.title.trim();
                if (typeof response.position != 'undefined' && response.position.toLowerCase().trim() == 'before') {
                    b.appendChild(d);
                    b.appendChild(z);
                }
                else if (typeof response.position != 'undefined' && response.position.toLowerCase().trim() == 'after') {
                    img.className = "left-img option-img"
                    b.appendChild(z);
                    b.appendChild(d);
                }
            }
            a.appendChild(b);
            div.appendChild(a);
            return div;
        } else if (response.type == 'feedback') {
            var e = document.createElement('p')
            e.className = 'chatbot-heading';
            e.innerHTML = response.title;
            var z = document.createElement('div')
            z.className = 'feedback-button';
            response.response.forEach(function (data) {
                var f = document.createElement('button')
                f.className = 'btn btn-default feedback-response'
                if (data.label.toLowerCase() == 'yes')
                    f.className += ' thumb-up-img';
                else
                    f.className += ' thumb-down-img';
                f.addEventListener('click', function () {
                    component.set("v.user_feedback", true);
                    helper.updateChat(component, 'You', '/user_feedback/' + data.label, undefined, helper);
                    for (var i = 0; i < z.childNodes.length; i++) {
                        z.childNodes[i].setAttribute("disabled", true);
                    }
                    f.setAttribute("class", 'btn btn-default user-feedback-disable');
                    if (data.label.toLowerCase() == 'yes')
                        f.className += ' thumb-up-img';
                    else
                        f.className += ' thumb-down-img';

                    document.getElementById('submit').setAttribute('disabled', true)
                    document
                        .getElementById('submit')
                        .setAttribute('placeholder', component.get("v.robot") + ' is typing...')
                    // responseData = '/' + data.name.replace(/['"]+/g, '') + '{' + data.label + '}';
                    helper.bot.respondTo(component, '/' + data.name + '{' + data.label + '}', helper, function (err, reply) {
                        if (reply == null) return
                        helper.updateChat(component, component.get("v.robot"), reply, undefined, helper);
                    })
                }, {
                    once: true
                });

                z.appendChild(f);
                //e.appendChild(z)
            })
            if (typeof component.get("v.feedback_type") != 'undefined' && (component.get("v.feedback_type").toLowerCase() == "positive" || component.get("v.feedback_type").toLowerCase() == 'not_skipped')) {
                component.set("v.user_feedback", false);
            }

            d.appendChild(e);
            d.appendChild(z);
            b.appendChild(d);
            //b.appendChild(z);
            a.appendChild(b);
            div.appendChild(a);
            return div;
        }


        else if (response.type == 'text') {
            if (typeof response.response != 'undefined')
                d.innerHTML = response.response.trim().split('SU-BOT-SKIP').join('');

            if (component.get("v.storySelected").toLowerCase() == "feedback_no" && component.get("v.feedback_type") == "negative") {

                document.getElementById('skip-img').style.display = 'inline-block';
                document.getElementById('skip-img').style.cursor = 'pointer';
                document.getElementById('skip-img').style.pointerEvents = 'auto';
                // document.getElementById("skip-img").addEventListener('click', function (component, helper) {
                //     document.getElementById('skip-img').style.pointerEvents = 'none';
                //     document.getElementById('skip-img').style.cursor = 'default';
                //     helper.submitChat(component, true, helper, true);
                // });
            }
            if (component.get("v.storySelected").toLowerCase() == "feedback_no" && (typeof component.get("v.feedback_type") == 'undefined' || component.get("v.feedback_type") == "not_skipped" || component.get("v.feedback_type") == "negative" || component.get("v.feedback_type") == "skipped")) {
                component.set("v.user_feedback", true);
            }
            if (component.get("v.storySelected").toLowerCase() == "feedback_no" && (component.get("v.feedback_type") == 'not_skipped' || component.get("v.feedback_type") == 'skipped'))
                component.set("v.user_feedback", false);


            b.appendChild(d);
            a.appendChild(b);
            div.appendChild(a);
            return div;
        } else if (response.type == 'link') {
            var inner_div = document.createElement('div')
            inner_div.className = 'button-msg margin-0';
            a.className += 'margin-0'
            var anchor = document.createElement('a');
            anchor.className = 'chatbot-links';
            if (component.get("v.previousResponseType") != 'link')
                anchor.className += ' top-border';

            var div_text = document.createElement('div');
            div_text.className = 'chatbot-text';
            div_text.addEventListener('click', function () {

                response['link_click'] = true;
                response['response_type'] = typeof response.summary == 'undefined' ? 'link' : 'fallback';
                helper.bot.respondTo(component, response, helper, function (err, reply) {
                    if (reply == null) return
                })

                if (typeof response.new_tab != 'undefined' && response.new_tab.toLowerCase() == 'true') {
                    return window.open(response.response, '_blank');
                }
                else {
                    var youtubeLinkCheck = helper.youtube_parser(response.response);
                    if (youtubeLinkCheck) {
                        if (document.querySelector('.chat').childNodes[document.querySelector('.chat').childNodes.length - 1].lastChild.className == 'chatbot-links-youtube') {
                            document.querySelector('.chat').childNodes[document.querySelector('.chat').childNodes.length - 1].lastChild.src = "https://www.youtube.com/embed/" + youtubeLinkCheck + "?version=3&enablejsapi=1&playlist=" + youtubeLinkCheck + "&loop=1";
                        } else {
                            var iframe = document.createElement('iframe');
                            iframe.className = 'chatbot-links-youtube';
                            iframe.src = "https://www.youtube.com/embed/" + youtubeLinkCheck + "?version=3&enablejsapi=1&playlist=" + youtubeLinkCheck + "&loop=1";
                            iframe.setAttribute("style", "max-height:fit-content;width:66%;");
                            iframe.setAttribute("allowfullscreen", "true");
                            iframe.setAttribute("id", "player");
                            var youtube_div = document.createElement('div');
                            youtube_div.appendChild(iframe);
                            document.querySelector('.chat').appendChild(youtube_div);
                            helper.scrollToBottom(document.querySelector('.chat-section'), document.querySelector('.chat-section').scrollHeight, 3500);
                        }
                    }
                    else
                        return window.open(response.response, '_self');
                }
            });
            div_text.setAttribute("title", response.label);
            response.label = response.label.length > 40 ? response.label.substring(0, 40) + '...' : response.label;
            div_text.innerHTML = '<div class = "design-box"></div>' + response.label.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
            anchor.appendChild(div_text);
            d.appendChild(anchor);
            inner_div.appendChild(anchor);
            b.appendChild(inner_div);
            a.appendChild(b);
            div.appendChild(a);
            return div;
        } else if (response.type == 'pause' && !response.history) {

            var div_inner = document.createElement('div');
            div_inner.className = 'loading-img';
            var loadingIcon = document.createElement('div');
            loadingIcon.className = 'typing-indicator';
            for (var i = 0; i < 3; i++) {
                var spaan = document.createElement('span');
                loadingIcon.appendChild(spaan);
            }
            div_inner.appendChild(loadingIcon);

            if (response.bot_type == 'true') {
                var botDiv = document.createElement('div');
                botDiv.className = 'bot-typing';
                botDiv.innerHTML = "Bot is typing...";
                div_inner.appendChild(botDiv);
            }
            b.appendChild(div_inner);
            a.appendChild(b);
            div.appendChild(a);
            div.className = "loading-img-div"
            return div;

        } else if (response.type == 'prompt' && !response.history) {

            var ent_type = response.ent_type ? response.ent_type : '';
            var bot_memory = response.bot_memory ? response.bot_memory : '';
            component.set("v.ent_type", ent_type);
            component.set("v.bot_memory", bot_memory);

            if (response.title && response.title.trim().length > 0 && response.position.toLowerCase() == "before") {
                var title = {
                    type: 'text',
                    response: response.title.trim().replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                }
                document.querySelector('.chat').appendChild(helper.getBotHTML(component, title, helper));
            }

            if (typeof response.response != 'undefined' && response.response.trim().length > 0) {
                var prompt_title = document.createElement('div')
                prompt_title.className = 'party';
                prompt_title.innerHTML = response.response.trim().replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                b.appendChild(prompt_title);
            }

            //For adding options/choices
            if (typeof response.choices != 'undefined' && response.choices.length > 0) {
                var prompt_choices = document.createElement('div');
                prompt_choices.className = 'button-msg';
                response.choices.forEach(function (data) {

                    var button = document.createElement('button')
                    button.className = 'btn btn-default chatbot-button-response'
                    button.innerHTML = data;

                    button.addEventListener('click', function () {
                        helper.updateChat(component, 'You', data, undefined, helper);
                        for (var i = 0; i < prompt_choices.childNodes.length; i++) {
                            prompt_choices.childNodes[i].setAttribute("disabled", true);
                            prompt_choices.childNodes[i].setAttribute("class", 'btn btn-default chatbot-response-disable');
                        }
                        button.setAttribute("class", 'btn btn-default chatbot-response-disable');
                        document.getElementById('submit').setAttribute('disabled', true)
                        document.getElementById('submit').setAttribute('placeholder', component.get("v.robot") + ' is typing...')
                        var responseData = {
                            'ent_type': response.ent_type,
                            'bot_memory': response.bot_memory,
                            'choice': data,
                            'type': 'prompt'
                        }

                        helper.bot.respondTo(component, responseData, helper, function (err, reply) {
                            if (reply == null) return

                            helper.updateChat(component, component.get("v.robot"), reply, undefined, helper);

                        })
                    }, {
                        once: true
                    });
                    prompt_choices.appendChild(button)
                })
                b.appendChild(prompt_choices);
            }

            //For adding calender if choices/options of prompt is null
            if (typeof response.ent_type != 'undefined' && response.ent_type.toLowerCase() != 'custom' && response.choices.length == 0) {

                switch (response.ent_type.toLowerCase()) {
                    case 'date':
                        component.set("v.showDatepicker", true);
                        document.querySelector(".text-bar a").style.pointerEvents = "none";
                        document.querySelector(".text-bar a").style.display = "default";
                        document.getElementById("skip-img").style.position = "absolute";
                        if (window.matchMedia('(min-width:320px) and (max-width: 480px)').matches) {
                            var x = document.getElementById("skip-img");
                            x.className = "skip-image";

                        } else {
                            // document.getElementById("skip-img").style.bottom = "38px";
                            document.getElementById("skip-img").style.right = "16%";

                        }
                        break;
                    case 'date.month':

                        document.getElementById("submit").readOnly = true;
                        document.querySelector(".text-bar a").style.pointerEvents = "none";
                        document.querySelector(".text-bar a").style.display = "default";
                        document.getElementById("submit").addEventListener("click", helper.showMonth);
                        document.getElementById("submit").addEventListener("focusout", helper.hideMonth);
                        break;
                    case 'date.year':

                        document.getElementById("submit").type = 'number';
                        document.getElementById("submit").min = '1900';
                        document.getElementById("submit").max = '2099';
                        break;
                }
            }

            let required = response.required ? response.required.toLowerCase() : false;
            component.set("v.required", required);

            //For Skip prompt if required is set false
            if (typeof response.required != 'undefined' && response.required.toLowerCase() == "false") {
                document.getElementById('skip-img').style.display = 'inline-block';
                document.getElementById('skip-img').style.cursor = 'pointer';
                document.getElementById('skip-img').style.pointerEvents = 'auto';

            }

            if (response.title && response.title.trim().length > 0)
                a = document.createElement('li');

            a.appendChild(b);

            if (response.title && response.title.trim().length > 0 && response.position.toLowerCase() == "after") {
                var title = {
                    type: 'text',
                    response: response.title.trim().replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
                }
                a.appendChild(helper.getBotHTML(component, title, helper));
            }
            div.appendChild(a);
            return div
        } else if (response.type == 'suadapter') {
            if (response.view == 'list') {
                response.data.forEach(function (data) {
                    data.response = data.response.trim().replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
                    helper.updateChat(component, component.get("v.robot"), data, undefined, helper);
                })
            }
        } else if (response.type == 'sfdcLegacy' && !response.history) {
            if(typeof GzAnalytics != 'undefined')
                var sessionId = GzAnalytics.getsid();
            else{
                var analyticsCmp = component.find("SuAnalytics");
                var sessionId = analyticsCmp.analytics('_gz_taid', '');
            }
            var userSession = component.get("v.userSession");
            var xmlHttp = new XMLHttpRequest();
            xmlHttp.onreadystatechange = function () {
                if (this.readyState == 4 && this.status == 200) {
                    var responseData = JSON.parse(atob(this.response));
                    var response = JSON.parse(responseData.response);
                    if (response.data) {
                        component.set("v.buttonId", (typeof response.data.buttonId != null) ? response.data.buttonId : '');
                        component.set("v.deploymentId", (typeof response.data.deploymentId != null) ? response.data.deploymentId : '');
                        component.set("v.agnetEndpoint", (typeof response.data.endpoint != null) ? response.data.endpoint + '/chat' : '');
                        component.set("v.orgId", (typeof response.data.orgId != null) ? response.data.orgId : '');

                        var xmlHttp = new XMLHttpRequest();
                        xmlHttp.onreadystatechange = function () {
                            if (this.readyState == 4 && this.status == 200) {
                                var responseData = JSON.parse(atob(this.response));
                                var messageData = JSON.parse(responseData.response);
                                var message = messageData.data.replace(/,/g, '\n');

                                if (window.liveagent) {
                                    if (window.Prototype) {
                                        delete Object.prototype.toJSON;
                                        delete Array.prototype.toJSON;
                                        delete Hash.prototype.toJSON;
                                        delete String.prototype.toJSON;
                                    }
                                    let url = component.get("v.agnetEndpoint");
                                    liveagent.init(url, component.get("v.deploymentId"), component.get("v.orgId"));
                                    if (!window._laq) { window._laq = []; }
                                    window._laq.push(function () {
                                        liveagent.showWhenOnline(component.get("v.buttonId"), document.getElementById(component.get("v.buttonId") + '_online'));
                                        liveagent.showWhenOffline(component.get("v.buttonId"), document.getElementById(component.get("v.buttonId") + '_offile'));
                                        liveagent.addCustomDetail("Message ", message, true);
                                    });

                                    setTimeout(function () {
                                        var liveButton = document.getElementById(component.get("v.buttonId") + '_online');
                                        if (liveButton) {
                                            liveagent.startChat(component.get("v.buttonId"));
                                            if (document.querySelector(".chat")) {
                                                var nodes = document.querySelector(".chat");
                                                while (nodes.childNodes.length > 1) {
                                                    nodes.removeChild(nodes.lastChild);
                                                }
                                                var a = component.get('c.hideChat');
                                                $A.enqueueAction(a);

                                            }
                                        }
                                    }, 3000);
                                }

                            }
                        }

                        var url = component.get("v.endPoint") + "/chatbot/api/chat_history_sfdc?pform=sfdc&lang=" + component.get("v.currentLanguage") + "&sessionId=" + sessionId + "&uid=" + component.get("v.uid");
                        xmlHttp.open("GET", url, true);
                        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
                        xmlHttp.setRequestHeader('Content-Type', 'application/json');
                        xmlHttp.send();

                    }
                }
            }
            var url = component.get("v.endPoint") + "/chatbot/api/adapter_settings?type=SFDC&pform=sfdc&uid=" + component.get("v.uid") + "&sessionId=" + sessionId + "&user_session_id=" + userSession;
            xmlHttp.open("GET", url, true);
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.send();
        } else if (response.type == 'sfdcEmbedded' && !response.history) {
            let responseAdminConfig = response;
            component.set("v.SFDC_liveAgent_invoked", true);
            component.set("v.SFDCendchatclicked", false);

            if (typeof component.get('v.inactivityLimit') != 'undefined') {
                for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                    var idToClear = component.get('v.inactivityLimitArray')[i];
                    clearInterval(idToClear);
                }
                component.set('v.inactivityLimitArray', []);
            }

            let maxRetryAttempts = 3;
            let curRetryAttempt = 1;

            let botMsg = responseAdminConfig.waitMsg;
            helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
            document.getElementById("submit").setAttribute('disabled', true);
            document.querySelector('.text-bar a').style.pointerEvents = 'none';

            // Hide start-over conversation
            document.querySelector('.start-over a').style.visibility = 'hidden';
            document.querySelector('.start-over').style.pointerEvents = 'none';

            // 0. =============================GET ADAPTER SETTINGS=============================================
            let sessionId = GzAnalytics.getsid();
            let userSession = component.get("v.userSession");
            let xhrAdapterSettings = new XMLHttpRequest();
            xhrAdapterSettings.onreadystatechange = function () {
                if (this.readyState == 4 && this.status == 200) {
                    let responseData = JSON.parse(atob(this.response));
                    let response = JSON.parse(responseData.response);
                    if (response.data) {
                        component.set("v.buttonId", (typeof response.data.buttonId != null) ? response.data.buttonId : '');
                        component.set("v.deploymentId", (typeof response.data.deploymentId != null) ? response.data.deploymentId : '');
                        component.set("v.agnetEndpoint", (typeof response.data.endpoint != null) ? response.data.endpoint : '');
                        component.set("v.orgId", (typeof response.data.orgId != null) ? response.data.orgId : '');
                        component.set("v.HOST_URL", (typeof response.data.siteURL != null) ? response.data.siteURL : '');

                        // 1. =============================CREATE and GET SESSION INFO===================================
                        let xhr = new XMLHttpRequest();
                        xhr.addEventListener("readystatechange", function () {
                            if (this.readyState === 4) {
                                if (this.status === 200) {
                                    let SFDCresp = JSON.parse(this.response);

                                    component.set("v.sessionKey", SFDCresp.key);
                                    component.set("v.affinityToken", SFDCresp.affinityToken);
                                    component.set("v.clientPollTimeout", SFDCresp.clientPollTimeout);

                                    // 2. =========================SEND CHAT REQUEST============================================
                                    var data = JSON.stringify({
                                        "organizationId": component.get("v.orgId"),
                                        "deploymentId": component.get("v.deploymentId"),
                                        "buttonId": component.get("v.buttonId"),
                                        "userAgent": navigator.userAgent,
                                        "language": component.get("v.language"),
                                        "screenResolution": component.get("v.screenResolution"),
                                        "prechatDetails": component.get("v.prechatDetails"),
                                        "prechatEntities": component.get("v.prechatEntities"),
                                        "receiveQueueUpdates": component.get("v.receiveQueueUpdates"),
                                        "isPost": component.get("v.isPost")
                                    });

                                    let xhr = new XMLHttpRequest();
                                    xhr.addEventListener("readystatechange", function () {
                                        if (this.readyState === 4) {
                                            if (this.status === 200) {
                                                getMessagesFromAgent(component.get("v.ack"));
                                            }
                                            else {
                                                let botMsg = responseAdminConfig.failMsg;
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                                                document.querySelector('.close-bot-icon').setAttribute("title", "Close");

                                                document.querySelector('.start-over a').style.visibility = 'visible';
                                                document.querySelector('.start-over').style.pointerEvents = 'auto';

                                                component.set("v.sendAgain", false);      // to continue sending requests or not
                                                component.set("v.SFDC_liveAgent_invoked", false);

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
                                                helper.remainingResponse(component, helper);
                                            }
                                        }
                                    });

                                    xhr.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                                    xhr.setRequestHeader("AGENT-ACTION", "init-chat-request");
                                    xhr.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                                    xhr.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                                    xhr.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                                    xhr.setRequestHeader("Content-Type", "application/json");
                                    xhr.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                                    xhr.send(data);
                                }
                                else {
                                    let botMsg = responseAdminConfig.failMsg;
                                    helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);

                                    document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                                    document.querySelector('.close-bot-icon').setAttribute("title", "Close");

                                    // Show start-over conversation
                                    document.querySelector('.start-over a').style.visibility = 'visible';
                                    document.querySelector('.start-over').style.pointerEvents = 'auto';

                                    component.set("v.sendAgain", false);      // to continue sending requests or not
                                    component.set("v.SFDC_liveAgent_invoked", false);

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
                                    helper.remainingResponse(component, helper);
                                }
                            }
                        });
                        //xhr.open("GET", HOST_URL+"System/SessionId", true);
                        xhr.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                        xhr.responseType = 'json';
                        xhr.setRequestHeader("AGENT-ACTION", "create-session");
                        xhr.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                        xhr.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                        xhr.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                        //xhr.setRequestHeader('Authorization', 'Bearer ' + component.get("v.LiveAgentAccessToken"));
                        xhr.send("");


                        // 2.A. ===================================GET MESSAGES====================================
                        // It is required to be called indefinitely for maintaining session, else session will expire after pollTimeOut seconds
                        function getMessagesFromAgent(ackFromRequest) {
                            component.set("v.sendAgain", true);

                            let xhr = new XMLHttpRequest();
                            xhr.addEventListener("readystatechange", function () {
                                if (this.readyState === 4) {
                                    if (this.status === 200 || this.status == 500) {
                                        // console.log(`${this.status} ==> ${this.statusText} ==> ${typeof this.response}`);
                                        // console.log(this.response);

                                        let messageEvents = [];
                                        let respSeq = ackFromRequest;
                                        let SFDCresp = null;

                                        if (this.status == 200) {
                                            // COMMENT when working with DEV server as it returns OBJECT
                                            // however SFDC APEX donot support return type OBJECT with HttpGet
                                            SFDCresp = JSON.parse(this.response);

                                            // CHECK RESPONSE TYPE + UPDATE ack parameter + call getMessagesFromAgent()
                                            messageEvents = SFDCresp.messages;
                                            respSeq = SFDCresp.sequence;
                                        }

                                        messageEvents.forEach(function (evt) {
                                            if (evt.type == "ChatRequestSuccess") {

                                                // change title attribute for close icon
                                                document.querySelector(".close-bot-icon").setAttribute("title", "Cancel Chat Request");

                                                component.set("v.sendAgain", true);
                                            }
                                            else if (evt.type == "ChatEstablished") {
                                                component.set("v.agentName", evt.message.name);
                                                let agentUserID = evt.message.userId;
                                                document.querySelector('.heading-chat').innerHTML = component.get("v.agentName");
                                                document.querySelector(".close-bot-icon").setAttribute("title", "End Agent Chat");

                                                // Enable chat text and send button
                                                document.getElementById('submit').removeAttribute('disabled');
                                                document.querySelector('.text-bar a').style.pointerEvents = 'auto';
                                                document.querySelector(".chat").lastElementChild.lastElementChild.lastElementChild.lastElementChild.innerText = "Connected with " + component.get("v.agentName");
                                                component.set("v.sendAgain", true);

                                                let sessionIdChatHistory = GzAnalytics.getsid();
                                                let userSessionChatHistory = component.get("v.userSession");
                                                let xhrChatHistory = new XMLHttpRequest();
                                                xhrChatHistory.onreadystatechange = function () {
                                                    if (this.readyState == 4 && this.status == 200) {
                                                        let responseDataHistory = JSON.parse(atob(this.response));
                                                        let messageDataHistory = JSON.parse(responseDataHistory.response);
                                                        let messageHistory = messageDataHistory.data.replace(/,/g, '\n');

                                                        helper.sendMessageToAgent(component, messageHistory, helper);
                                                        if (typeof component.get('v.inactivityLimit') != 'undefined') {
                                                            for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                                                                var idToClear = component.get('v.inactivityLimitArray')[i];
                                                                clearInterval(idToClear);
                                                            }
                                                            component.set('v.inactivityLimitArray', []);
                                                        }
                                                    }
                                                }
                                                let urlChatHistory = component.get("v.endPoint") + "/chatbot/api/chat_history_sfdc?pform=sfdc&lang=" + component.get("v.currentLanguage") + "&sessionId=" + sessionIdChatHistory + "&uid=" + component.get("v.uid");
                                                xhrChatHistory.open("GET", urlChatHistory, true);
                                                xhrChatHistory.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
                                                xhrChatHistory.setRequestHeader('Content-Type', 'application/json');
                                                xhrChatHistory.send();
                                            }
                                            else if (evt.type == "ChatMessage") {
                                                let msg = evt.message.text;

                                                let tpArrA = msg.split(' ');
                                                for (let ind in tpArrA) {
                                                    if (tpArrA[ind].startsWith("http")) {
                                                        tpArrA[ind] = '<a href="' + tpArrA[ind] + '" target="_blank">' + tpArrA[ind] + '</a>';
                                                    }
                                                }

                                                let botMsg = tpArrA.join(" ");
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);

                                                if (typeof component.get('v.inactivityLimit') != 'undefined') {
                                                    for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                                                        var idToClear = component.get('v.inactivityLimitArray')[i];
                                                        clearInterval(idToClear);
                                                    }
                                                    component.set('v.inactivityLimitArray', []);
                                                }

                                                document.querySelector("#agentTypingText").style.display = "none";

                                                component.set("v.sendAgain", true);
                                            }
                                            else if (evt.type == "ChatEnded") {
                                                let reason = evt.message.reason;

                                                let botMsg = responseAdminConfig.endMsg;
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);

                                                document.querySelector("#agentTypingText").style.display = "none";

                                                // Heading
                                                document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                                                document.querySelector('.close-bot-icon').setAttribute("title", "Close");
                                                document.querySelector('.start-over a').style.visibility = 'visible';
                                                document.querySelector('.start-over').style.pointerEvents = 'auto';

                                                component.set("v.sendAgain", false);      // to continue sending requests or not
                                                component.set("v.SFDC_liveAgent_invoked", false);


                                                let xhrDeleteSession = new XMLHttpRequest();
                                                xhrDeleteSession.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                                                xhrDeleteSession.setRequestHeader("AGENT-ACTION", "delete-session");
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                                                xhrDeleteSession.setRequestHeader("Content-Type", "application/json");
                                                xhrDeleteSession.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                                                xhrDeleteSession.send("");

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
                                                helper.remainingResponse(component, helper);
                                            }
                                            else if (evt.type == "ChatRequestFail") {
                                                let reason = evt.message.reason;

                                                let botMsg = responseAdminConfig.unavailableMsg;
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                                                document.querySelector('.close-bot-icon').setAttribute("title", "Close");

                                                // Show start-over conversation
                                                document.querySelector('.start-over a').style.visibility = 'visible';
                                                document.querySelector('.start-over').style.pointerEvents = 'auto';

                                                component.set("v.sendAgain", false);      // to continue sending requests or not
                                                component.set("v.SFDC_liveAgent_invoked", false);


                                                let xhrDeleteSession = new XMLHttpRequest();
                                                xhrDeleteSession.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                                                xhrDeleteSession.setRequestHeader("AGENT-ACTION", "delete-session");
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                                                xhrDeleteSession.setRequestHeader("Content-Type", "application/json");
                                                xhrDeleteSession.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                                                xhrDeleteSession.send("");

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
                                                helper.remainingResponse(component, helper);
                                            }
                                            else if (evt.type == "AgentDisconnect") {
                                                let reason = "agent disconnected";     // AgentDisconnect event does not send any body

                                                let botMsg = 'Chat session ended because ' + reason;
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                document.querySelector("#agentTypingText").style.display = "none";

                                                // Heading
                                                document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                                                document.querySelector('.close-bot-icon').setAttribute("title", "Close");
                                                document.querySelector('.start-over a').style.visibility = 'visible';
                                                document.querySelector('.start-over').style.pointerEvents = 'auto';

                                                component.set("v.sendAgain", false);      // to continue sending requests or not
                                                component.set("v.SFDC_liveAgent_invoked", false);


                                                let xhrDeleteSession = new XMLHttpRequest();
                                                xhrDeleteSession.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                                                xhrDeleteSession.setRequestHeader("AGENT-ACTION", "delete-session");
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                                                xhrDeleteSession.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                                                xhrDeleteSession.setRequestHeader("Content-Type", "application/json");
                                                xhrDeleteSession.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                                                xhrDeleteSession.send("");

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
                                                helper.remainingResponse(component, helper);
                                            }
                                            else if (evt.type == "AgentTyping") {
                                                document.querySelector("#agentTypingText").style.display = "initial";

                                                component.set("v.sendAgain", true);
                                            }
                                            else if (evt.type == "AgentNotTyping") {
                                                document.querySelector("#agentTypingText").style.display = "none";

                                                component.set("v.sendAgain", true);
                                            }
                                        });

                                        if (component.get("v.sendAgain") && !component.get("v.SFDCendchatclicked")) {
                                            getMessagesFromAgent(respSeq);
                                        }
                                    }
                                    else {
                                        if (curRetryAttempt <= maxRetryAttempts) {
                                            if (curRetryAttempt == 1) {
                                                curRetryAttempt += 1;

                                                let botMsg = "Oh! Something went wrong.<br/>Please hold on. Trying to reconnect...";
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                if (typeof component.get('v.inactivityLimit') != 'undefined') {
                                                    for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                                                        var idToClear = component.get('v.inactivityLimitArray')[i];
                                                        clearInterval(idToClear);
                                                    }
                                                    component.set('v.inactivityLimitArray', []);
                                                }
                                                getMessagesFromAgent(ackFromRequest);
                                            }
                                            else if (curRetryAttempt == 2) {
                                                curRetryAttempt += 1;

                                                let botMsg = "Still on it.<br/>Trying to reconnect...";
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                if (typeof component.get('v.inactivityLimit') != 'undefined') {
                                                    for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                                                        var idToClear = component.get('v.inactivityLimitArray')[i];
                                                        clearInterval(idToClear);
                                                    }
                                                    component.set('v.inactivityLimitArray', []);
                                                }
                                                getMessagesFromAgent(ackFromRequest);
                                            }
                                            else if (curRetryAttempt == 3) {
                                                curRetryAttempt += 1;

                                                let botMsg = "Making another attempt for reconnection.<br/>Please hold on.";
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                if (typeof component.get('v.inactivityLimit') != 'undefined') {
                                                    for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                                                        var idToClear = component.get('v.inactivityLimitArray')[i];
                                                        clearInterval(idToClear);
                                                    }
                                                    component.set('v.inactivityLimitArray', []);
                                                }
                                                getMessagesFromAgent(ackFromRequest);
                                            }
                                            else {
                                                curRetryAttempt += 1;

                                                let botMsg = "Making another attempt for reconnection.<br/>Please hold on.";
                                                helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                                                if (typeof component.get('v.inactivityLimit') != 'undefined') {
                                                    for (var i = 0; i < component.get('v.inactivityLimitArray').length; i++) {
                                                        var idToClear = component.get('v.inactivityLimitArray')[i];
                                                        clearInterval(idToClear);
                                                    }
                                                    component.set('v.inactivityLimitArray', []);
                                                }
                                                getMessagesFromAgent(ackFromRequest);
                                            }
                                        }
                                        else {
                                            let botMsg = responseAdminConfig.failMsg;
                                            helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);

                                            document.querySelector("#agentTypingText").style.display = "none";

                                            // Heading
                                            document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                                            document.querySelector('.close-bot-icon').setAttribute("title", "Close");
                                            document.querySelector('.start-over a').style.visibility = 'visible';
                                            document.querySelector('.start-over').style.pointerEvents = 'auto';

                                            component.set("v.sendAgain", false);      // to continue sending requests or not
                                            component.set("v.SFDC_liveAgent_invoked", false);


                                            let xhrDeleteSession = new XMLHttpRequest();
                                            xhrDeleteSession.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                                            xhrDeleteSession.setRequestHeader("AGENT-ACTION", "delete-session");
                                            xhrDeleteSession.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                                            xhrDeleteSession.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                                            xhrDeleteSession.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                                            xhrDeleteSession.setRequestHeader("Content-Type", "application/json");
                                            xhrDeleteSession.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                                            xhrDeleteSession.send("");

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
                                            helper.remainingResponse(component, helper);
                                        }
                                    }
                                }
                            });

                            let url = new URL(component.get("v.HOST_URL") + "/services/apexrest/live-chat-service");
                            url.searchParams.set('ack', ackFromRequest);
                            xhr.open("POST", url, true);
                            xhr.responseType = 'json';
                            xhr.setRequestHeader("AGENT-ACTION", "get-messages");
                            xhr.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                            xhr.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                            xhr.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                            xhr.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                            xhr.send("");
                        }
                    }
                }
                else if (this.readyState == 4 && this.status != 200) {
                    let botMsg = responseAdminConfig.failMsg;
                    helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);
                    document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));
                    document.querySelector('.close-bot-icon').setAttribute("title", "Close");

                    // Show start-over conversation
                    document.querySelector('.start-over a').style.visibility = 'visible';
                    document.querySelector('.start-over').style.pointerEvents = 'auto';

                    component.set("v.sendAgain", false);      // to continue sending requests or not
                    component.set("v.SFDC_liveAgent_invoked", false);

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
                    helper.remainingResponse(component, helper);
                }
            }
            let url = component.get("v.endPoint") + "/chatbot/api/adapter_settings?type=SFDC&pform=sfdc&uid=" + component.get("v.uid") + "&sessionId=" + sessionId + "&user_session_id=" + userSession;
            xhrAdapterSettings.open("GET", url, true);
            xhrAdapterSettings.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
            xhrAdapterSettings.setRequestHeader('Content-Type', 'application/json');
            xhrAdapterSettings.send();

        } else if (response.type == 'case' && !response.history) {
            component.set("v.caseResponse", response);
            d.innerHTML = response.subject.trim().split('SU-BOT-SKIP').join('');
            b.appendChild(d);
            a.appendChild(img);
            a.appendChild(b);
            div.appendChild(a);
            return div;
        } else {
            d.innerHTML = response;
            b.appendChild(d);
            a.appendChild(b);
            div.appendChild(a);
            return div;
        }

    },


    sendMessageToAgent: function (component, messageFromVisitor, helper) {
        let msg = messageFromVisitor;

        let data = JSON.stringify({
            "text": msg
        });

        // Hide typing text
        document.querySelector("#agentTypingText").style.display = "none";

        let xhr = new XMLHttpRequest();
        xhr.addEventListener("readystatechange", function () {
            if (this.readyState === 4) {
                if (this.status === 200) {
                    // console.log(`${this.status} ==> ${this.statusText} ==> ${typeof this.response}`);
                    // console.log(this.response);
                }
                else {
                    document.querySelector("#agentTypingText").style.display = "none";
                }
            }
        });

        xhr.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
        xhr.setRequestHeader("AGENT-ACTION", "send-message");
        xhr.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
        xhr.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
        xhr.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
        xhr.send(data);
    },
    // 4. SFDC AGENT END CHAT
    endSFDCAgentChat: function (component, event, helper) {
        let data = JSON.stringify({
            "reason": "client"        // DONOT change this reason value, else request will FAIL
        });

        let xhr = new XMLHttpRequest();
        xhr.addEventListener("readystatechange", function () {
            if (this.readyState === 4) {
                if (this.status === 200) {

                    let botMsg = 'Chat session ended.<br/>Have a nice time ahead.';
                    helper.updateChat(component, component.get("v.robot"), botMsg, undefined, helper);

                    // Heading
                    document.querySelector('.heading-chat').innerHTML = (component.get("v.actualBotHeading") == undefined ? localStorage.getItem("actualBotHeading") : component.get("v.actualBotHeading"));

                    // change title attribute of close button
                    document.querySelector('.close-bot-icon').setAttribute("title", "Close");

                    // Hide typing text
                    document.querySelector("#agentTypingText").style.display = "none";

                    // Show start-over conversation
                    document.querySelector('.start-over a').style.visibility = 'visible';
                    document.querySelector('.start-over').style.pointerEvents = 'auto';

                    component.set("v.sendAgain", false);
                    component.set("v.SFDCendchatclicked", true);
                    component.set("v.SFDC_liveAgent_invoked", false);


                    let xhrDeleteSession = new XMLHttpRequest();
                    xhrDeleteSession.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
                    xhrDeleteSession.setRequestHeader("AGENT-ACTION", "delete-session");
                    xhrDeleteSession.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
                    xhrDeleteSession.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
                    xhrDeleteSession.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
                    xhrDeleteSession.setRequestHeader("Content-Type", "application/json");
                    xhrDeleteSession.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
                    xhrDeleteSession.send("");

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
                    helper.remainingResponse(component, helper);

                }
            }
        });
        xhr.open("POST", component.get("v.HOST_URL") + "/services/apexrest/live-chat-service", true);
        xhr.setRequestHeader("AGENT-ACTION", "end-chat");
        xhr.setRequestHeader("X-LIVEAGENT-API-VERSION", component.get("v.apiVersion"));
        xhr.setRequestHeader("X-LIVEAGENT-AFFINITY", component.get("v.affinityToken"));
        xhr.setRequestHeader("X-LIVEAGENT-SESSION-KEY", component.get("v.sessionKey"));
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("SFDC-CHAT-API-URL", component.get("v.agnetEndpoint"));
        xhr.send(data);
    },
    youtube_parser: function (url) {
        var p = /^(?:https?:\/\/)?(?:m\.|www\.)?(?:youtu\.be\/|youtube\.com\/(?:embed\/|v\/|watch\?v=|watch\?.+&v=))((\w|-){11})(?:\S+)?$/;
        if (url.match(p)) {
            return url.match(p)[1];
        }
        return false;
    },
    remainingResponse: function (component, helper) {
        if (component.get("v.previousResponse").length) {
            var result = [];
            var responses = component.get("v.previousResponse").shift();
            for (var i = 0; i < responses.length; i++) {
                result.push(responses[i]);
            }
            for (var i = 0; i < result.length; i++) {
                (function (i) {
                    var pauseTime = 0;
                    result[i].delay ? pauseTime = result[i].delay : pauseTime = 0;
                    var idLimit = window.setTimeout(function () {
                        for (let count = 0; count < document.querySelectorAll('.loading-img').length; count++) {
                            document.querySelectorAll('.loading-img')[count].parentNode.parentElement.style.margin = 0;
                            document.querySelectorAll('.loading-img')[count].style.display = "none";
                            document.getElementById('submit').removeAttribute('disabled');
                        }
                        if (result[i].type != 'empty')
                            helper.updateChat(component, component.get("v.robot"), result[i], undefined, helper);
                        if (result[i].hideIcon && component.get('v.previousParty') == 'You')
                            document.querySelectorAll('.left-img')[document.querySelectorAll('.left-img').length - 1].style.display = 'none';

                    }, pauseTime * 1000)
                    component.get("v.responseTypeLimit").push(idLimit);
                }(i));
            }
        }
    },
    getUserHTML: function (component, response, helper) {
        var div = document.createElement('div')
        var a = document.createElement('li')
        var b = document.createElement('div')
        b.className = 'right-chat'
        a.appendChild(b)
        var c = document.createElement('p')
        if (response.toLowerCase() == '/user_feedback/yes')
            c.className = 'user-res thumb-up-img'
        else if (response.toLowerCase() == '/user_feedback/no')
            c.className = 'user-res thumb-down-img'
        else {
            c.className = 'response'
            c.innerText = response;
        }
        b.appendChild(c)
        a.appendChild(b)
        div.appendChild(a)
        return div
    },
    createSession: function (component, id, helper) {
        let sessionId = GzAnalytics.getsid();
        let userSession = component.get("v.userSession");
        let data = JSON.stringify({
            sessionId: sessionId,
            user_session_id: userSession,
            case_number: id,
            uid: component.get("v.uid"),
            pform: 'sfdc',
        });
        let xmlHttp = new XMLHttpRequest();
        let url = component.get("v.endPoint") + "/chatbot/api/case_analytics";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xmlHttp.setRequestHeader('Content-Type', 'application/json');

        xmlHttp.send(data);
        xmlHttp.onreadystatechange = function () {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {

                }
            }
        }

    },
    sendSlotsResponce: function (component, text, label, helper) {
        let responseData = '/' + text + '{' + component.get("v.slotValue") + ':' + label + '}';
        if(typeof GzAnalytics != 'undefined')
            var sessionId = GzAnalytics.getsid();
        else{
            var analyticsCmp = component.find("SuAnalytics");
            var sessionId = analyticsCmp.analytics('_gz_taid', '');
        }
        var userSession = component.get("v.userSession");
        var form = component.get("v.form");
        var data = JSON.stringify({
            sessionId: sessionId,
            user_session_id: userSession,
            query: responseData,
            use_analytics: 'false',
            uid: component.get("v.uid"),
            pform: 'sfdc',
            form: form,
            nlp: component.get("v.nlp")
        });
        let xmlHttp = new XMLHttpRequest();
        let url = component.get("v.endPoint") + "/response";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + component.get('v.Bearer'));
        xmlHttp.setRequestHeader('Content-Type', 'application/json');

        xmlHttp.send(data);
        xmlHttp.onreadystatechange = function () {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {

                }
            }
        }


    },
    showMonth: function (e) {
        e.preventDefault();
        document.getElementById('month_1').style.display = 'block';
        document.getElementById("submit").removeEventListener("click", helper.showMonth);
        document.getElementById("submit").addEventListener("focusout", helper.hideMonth);
    },
    hideMonth: function (e) {
        e.preventDefault();
        setTimeout(function () {
            document.getElementById('month_1').style.display = 'none';
            document.getElementById("submit").removeEventListener("focusout", helper.hideMonth);
        }, 1000);
    },
    colorChange: function (component, selector, responses, helper) {
        var getData = JSON.parse(helper.getConfig(component, helper));
        if (selector == 'You') {
            [].forEach.call(responses, function (div) {
                div.style.backgroundColor = getData.theme_data.chat_box.user_message_box_color;
                div.style.color = getData.theme_data.chat_box.user_message_font_color;
            });
        } else {
            [].forEach.call(responses, function (div) {
                div.style.backgroundColor = getData.theme_data.chat_box.bot_message_box_color;
                div.style.color = getData.theme_data.chat_box.bot_message_font_color;
            });
            var button = document.querySelectorAll('.chatbot-button-response');
            [].forEach.call(button, function (div) {
                div.style.fontFamily = getData.theme_data.font.font_style;
                div.style.backgroundColor = getData.theme_data.chat_box.chat_box_button_color;
                div.style.color = getData.theme_data.chat_box.chat_box_button_text_color;
            });
        }
    },
    delayStart: function () {
        return 400;
    },
    delayEnd: function () {
        return 800;
    },
    waiting: function () {
        return 0;
    }
});