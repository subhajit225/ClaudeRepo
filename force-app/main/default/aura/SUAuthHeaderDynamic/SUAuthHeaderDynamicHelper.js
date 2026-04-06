({
    _SUanalytics : function(component, event) {
        let getScreenObject = function() {
            let keysOfWindows = Object.keys(window.Screen.prototype);
            let screen = {};
            for(var i=0; i<keysOfWindows.length; i++){
                screen[keysOfWindows[i]]=window.screen[keysOfWindows[i]]
            }
            return screen
        }
        let fingerprintJSfp = function(cb){
                return cb(null, {"fp_device": "", "fp_result":""})
        }
        var ecoId = component.get("v.scConfigObj.ecoId");
        var fpTracking = false;
        var SuEndpoint = component.get("v.endPoint");
        var SuUid = component.get("v.uid");
        var trackingLoggedUsersOnly = component.get("v.scConfigObj.trackingLoggedUsersOnly");
        var sessionTimeOut = component.get("v.scConfigObj.sessionTimeOut");
        var emailTrackingEnabled = component.get("v.scConfigObj.emailTrackingEnabled");
        var accountName = component.get("v.scConfigObj.accountName");
        var externalUserEnabled = component.get("v.scConfigObj.externalUserEnabled");
        var __extends = (this && this.__extends) || (function () {
            var extendStatics = function (d, b) {
                extendStatics = Object.setPrototypeOf ||
                    (Object.getPrototypeOf(Array) && function (d, b) { Object.setPrototypeOf(d,b); }) ||
                    function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
                return extendStatics(d, b);
            }
            return function (d, b) {
                extendStatics(d, b);
                function __() { this.constructor = d; }
                d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
            };
        })();
        if (window.Element && !Element.prototype.closest) {
            Element.prototype.closest =
                function (s) {
                    var matches = (this.document || this.ownerDocument).querySelectorAll(s), i, el = this;
                    do {
                        i = matches.length;
                        while (--i >= 0 && matches.item(i) !== el) { }
                        ;
                    } while ((i < 0) && (el = el.parentElement));
                    return el;
                };
        }
        var CaptureEvent = /** @class */ (function () {
            function CaptureEvent(endpoint, uid, sessionTimeOut, emailTrackingEnabled, externalUserEnabled, accountName, trackingLoggedUsersOnly, ecoId, fpTracking) {
                this.emailTrackingEnabled = false;
                this.externalUserEnabled = false;
                this.endpoint = endpoint;
                this.uid = uid;
                this.sessionTimeOut = sessionTimeOut;
                this.convertedUrls = [];
                this.accountName = accountName;
                this.trackingLoggedUsersOnly = trackingLoggedUsersOnly;
                this.emailFound = false;
                this.internalState = '';
                this.ecoId = ecoId;
                this.fpTracking = fpTracking
                if (emailTrackingEnabled === true || emailTrackingEnabled === "true" || emailTrackingEnabled === "1" || emailTrackingEnabled === 1)
                    this.emailTrackingEnabled = true;
                if (externalUserEnabled === true || externalUserEnabled === "true" || externalUserEnabled === "1" || externalUserEnabled === 1)
                    this.externalUserEnabled = true;
                this.getsid();
                this.gettaid();
            }
            CaptureEvent.prototype.startClickTracking = function () {
                var _this = this;
                this.utilDocReady(function () {
                    document.addEventListener("click", function (e) {
                        // if (e.target.tagName === "A" || e.target.closest('a'))
                        //     _this.sendAnalytics("click", {
                        //         "target": e.target.href || e.target.closest('a').href
                        //     });        //// used for tracking page view for document type article like pdf
                        return;
                    });
                    document.addEventListener("contextmenu", function (e) {
                        if (e.target.tagName === "A" || e.target.closest('a'))
                            _this.sendAnalytics("click", {
                                "target": e.target.href || e.target.closest('a').href
                            });
                    });
                });
            };
            CaptureEvent.prototype.startTimeTracking = function () {
                var _this = this;
                this.heart = new Beep(function (event, params, cb) { _this.sendAnalytics(event, params, cb); });
                this.utilDocReady(function () {
                    document.addEventListener("mousemove", function () { _this.heart.beat(); });
                    document.addEventListener("mousedown", function () { _this.heart.beat(); });
                    document.addEventListener("mouseup", function () { _this.heart.beat(); });
                    document.addEventListener("scroll", function () { _this.heart.beat(); });
                    document.addEventListener("wheel", function () { _this.heart.beat(); });
                    document.addEventListener("keyup", function () { _this.heart.beat(); });
                });
            };
            CaptureEvent.prototype.getsid = function () {
                // if(!this.sid_session)
                this.sid_session = this.getCookie("_gz_sid");
                if (!this.sid_session){
                    this.sid_session = Date.now() + ("000" + Math.floor(Math.random() * 1000)).slice(-3);
                    this.setCookie("_gz_sid", this.sid_session, this.sessionTimeOut, 1);
                    this.setCookie("smartFacets", true, this.sessionTimeOut, 1);
                }else
                    this.setCookie("_gz_sid", this.sid_session, this.sessionTimeOut);
                return this.sid_session;
            };
            CaptureEvent.prototype.gettaid = function () {
                var taid_device = this.getCookie("_gz_taid");
                if (!taid_device) {
                    taid_device = Date.now() + ("000" + Math.floor(Math.random() * 1000)).slice(-3);
                    this.setCookie("_gz_taid", taid_device, 365 * 24 * 60);
                }
                return taid_device;
            };
            CaptureEvent.prototype.sendAnalytics = function (event, params, cb) {
                if(this.trackingLoggedUsersOnly === "1" && !this.emailFound){
                    console.log('Skip tacking for enail not found and email mandatory checkin enable');
                    return;
                }
                if (!event) {
                    event = "pageView";
                }
                if (!params)          params          = {};
                if (!params.url)      params.url      = window.location.href;
                if (!params.referrer) params.referrer = document.referrer;
                if (!params.e)        params.e        = event;
                if (!params.t)        params.t        = document.title;
                if (!params.uid)      params.uid      = this.uid;
                if (!params.r)        params.r        = Math.floor(Math.random() * 100000); // To disable caching
                if (!params.sid_session)      params.sid_session      = this.getsid();
                if (!params.taid_device)     params.taid_device     = this.gettaid();
                if (!params.screen && this.fpTracking) {
                    params.screen = getScreenObject()
                }
                if (!params.internal){
                    params.internal = this.getCookie("_gza_internal");
                }
                if(event == 'search'){
                    this.convertedUrls = [];
                    this.searchKeyword = params.searchString;
                    if(params.conversion && params.conversion[0] && params.conversion[0].url){
                      this.convertedUrls.push(params.conversion[0].url);
                    }
                    this.searchCookie = params.sid_session;
                    this.analyticsId = this.generate_uuid();
                    this.internalState = params.internal;
                    this.responseTime = params.responseTime;
                    params.analyticsId = this.analyticsId;
                    if(params.isFreshSearch || typeof params.isFreshSearch == 'undefined'){
                        this.isFreshConversionStatus = true;
                        if (params.conversion && params.conversion.length > 0){
                               params.isFreshConversion = isFreshConversionStatus;
                               this.isFreshConversionStatus = false;
                       }
                   }
  
                }
                if (event === "conversion") {
                    if(!this.searchCookie || this.searchCookie!=params.sid_session)
                        return;
                    if (!(params.convUrl && params.convSub))
                        console.info("incomplete object in gza function. missing convUrl or convSub");
                    // params.analyticsID = this.getCookie("analyticsID");
                    params.analyticsId = this.analyticsId;
                    params.searchString = this.searchKeyword;
                    params.isFreshConversion = this.isFreshConversionStatus;
                    params.internal = this.internalState;
                    this.isFreshConversionStatus = false;
                    if(this.convertedUrls.indexOf(params.convUrl)===-1)
                        this.convertedUrls.push(params.convUrl);
                    else
                        return;
                }
                if( event === "searchfeedback"){
                    params.search_id = this.analyticsId;
                }
                if(event === "caseCreated" && (!params.subject || params.subject.trim() == '')){
                    params.subject = this.searchKeyword;
                }
                var url = this.endpoint;   
                let bodyValue = {};
                fingerprintJSfp((err, data) => {
                    if (!err) {
                        params.fp_device = data.fp_device;
                        if (this.fpTracking){
                            params.fp_result = data.fp_result;
                        }
                    }  
                    for (var p in params) {
                        if (typeof params[p] === "object") {
                            params[p] = JSON.stringify(params[p]);
                        }
                        if (encodeURIComponent(p)) {   
                            bodyValue[p] = params[p];  
                        }
                    }
                    var options = {    
                        headers: {     
                            "content-type": "application/json; charset=UTF-8"      
                        },     
                        body: JSON.stringify(bodyValue),       
                        method: 'POST',
                        credentials: 'include'     
                    }          
                    fetch(url,options)     
                        .then(data=>{return data})     
                        .then(res=>{return res})       
                        .catch(error=>console.log(error))
                    /*if(event == 'click' && params.target.indexOf(location.hostname)>-1){
                        this.sendAnalytics('pageView',{});
                    }*/
                })
            };
            CaptureEvent.prototype.setUser = function (email) {
                var obj = {};
                if(email){
                    window.su_utm = email;
                    if (this.emailTrackingEnabled && email) {
                        obj.utm = email.split("").map(function (c) { return c.charCodeAt() ^ 59; }).join(".");
                    }
                    if (this.externalUserEnabled && this.accountName) {
                        this.accountList = this.accountName.split(',');
                        obj.internal = this.accountList.indexOf( (email.split("@")[1])) > -1 ? true : false;
                    }
                        this.setCookie("_gza_internal", obj.internal,this.sessionTimeOut);
                    if(this.trackingLoggedUsersOnly === "1" && !this.emailFound)
                    {
                        this.emailFound = true;
                        let context = this;
                        setTimeout(function(){ context.callPageView(false); }, 1000);
                    }
                    if (obj.utm || typeof obj.internal === "boolean")
                        this.sendAnalytics("setUtm", obj);
                }
               
            };
            CaptureEvent.prototype.utilDocReady = function (cb) {
                if (document.readyState === 'complete') {
                    cb();
                }
                else {
                    document.onreadystatechange = function () {
                        if (document.readyState === 'complete') {
                            cb();
                        }
                    };
                }
            };
            CaptureEvent.prototype.utilAjax = function (url, cb) {
                var ele = document.createElement("img");
                if (cb) {
                    ele.onload = cb;
                    ele.onerror = cb;
                }
                ele.src = url;
                ele.width = 1;
                ele.height = 1;
            };
            CaptureEvent.prototype.getCookie = function (cname) {
                var name = cname + "=";
                var ca = document.cookie.split(';');
                for (var i = 0; i < ca.length; i = i + 1) {
                    var c = ca[i];
                    while (c.charAt(0) === ' ') {
                        c = c.substring(1);
                    }
                    if (c.indexOf(name) === 0) {
                        return c.substring(name.length, c.length);
                    }
                }
                return "";
            };
            CaptureEvent.prototype.setCookie = function (cname, cvalue, exMins, newSession) {
                var expires = '';
                if (exMins) {
                    var d = new Date();
                    d.setTime(d.getTime() + (exMins * 60 * 1000));
                    expires = "expires=" + d.toUTCString();
                }
                document.cookie = cname + "=" + cvalue + ";" + expires + ";path=/";
                if(cname == '_gz_sid' && newSession)
                    this.setUser(window.su_utm);
            };
            CaptureEvent.prototype.generate_uuid = function (){
                var dt = new Date().getTime();
                var uuid = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
                    var r = (dt + Math.random()*16)%16 | 0;
                    dt = Math.floor(dt/16);
                    return (c=='x' ? r :(r&0x3|0x8)).toString(16);
                });
                return uuid;
            };
            CaptureEvent.prototype.callPageView = function(automatedCall){
                if (!automatedCall || trackingLoggedUsersOnly != "1") {
                    this.sendAnalytics("pageView", {});  
                }
            }
            return CaptureEvent;
        }());
        var Beep = /** @class */ (function () {
            function Beep(ping) {
                this.gza = ping;
                this.startTime = Date.now();
                this.lastUsed = this.startTime;
            }
            Beep.prototype.beat = function () {
                var now = Date.now();
                if (document.hasFocus()) {
                    if ((now - this.lastUsed >= 5 * 1000)) {
                        // this.gza("beep", { alive: Math.round((now - this.lastUsed) / 1000) });
                        this.lastUsed = now;
                    }
                }
                else {
                    this.lastUsed = now;
                }
                this.checkActive();
            };
            Beep.prototype.checkActive = function () {
                var _this = this;
                if (this.tmp)
                    clearTimeout(this.tmp);
                this.tmp = setTimeout(function () { _this.beat(); }, 5 * 1000);
            };
            return Beep;
        }());
        var Analytics = /** @class */ (function (_super) {
            __extends(Analytics, _super);
            function Analytics() {
                //var _this = _super.call(this, SuEndpoint+"/analytics/suanlytics.png", SuUid, +"60", "false", "false", "") || this;
                var _this = _super.call(this, SuEndpoint+"/analytics/suanlytics.png", SuUid, +sessionTimeOut, emailTrackingEnabled||false, externalUserEnabled||false, accountName||'', trackingLoggedUsersOnly||false, ecoId, fpTracking) || this;
               
                _super.prototype.callPageView.call(_this, true);
                _super.prototype.startClickTracking.call(_this);
                _super.prototype.startTimeTracking.call(_this);
                return _this;
            }
            return Analytics;
        }(CaptureEvent));
        window.GzAnalytics = window.GzAnalytics || new Analytics();
        window.gza = function (event, params, cb) { window.GzAnalytics.sendAnalytics(event, params, cb); };
        window._gr_utility_functions = {};
        _gr_utility_functions.getCookie = GzAnalytics.getCookie;
        GzAnalytics.setUser(component.get("v.currentUserEmail"));
        window.isFreshConversionStatus = true;
    }
 })