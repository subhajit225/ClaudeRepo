import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent, scriptsLoaded, getCommunitySettings } from 'c/authsupubsub_b6b3_13';
import UserId from '@salesforce/user/Id';

export default class SU_AuthRecommendations extends LightningElement {
    @api getRecommendationsEnable;
    @api recommendationsData;
    @api similiarSearchData;
    @track getRecommendationsDataShow = []
    @track endPoint;
    @track currentUserId = UserId;
    currentUserEmail;
    @track withSearchPage = false
    @track JWTToken;
    customSettingErrorMessage = " "
    recommendationTitle = "Recommended Results"
    customSettingsFilled;
    @track bearer = '';
    @track searchstring;
    searchquery;
    @track redirectionUrl;
    @track getRecommendations = false;
    @api knowledgeGraph;
    @track endPoint = '';
    @track bearer = '';
    @track uid = '';
    @api
    set searchQueryData(val){
        this.searchquery = val
        if(this.searchquery.searchString){
           this.getRecommendationsFunc()
        }
    }

    get searchQueryData(){
        return this.searchquery;
    }
    get getRecommendationsDataShowList() {
        this.getRecommendationsDataShow = JSON.parse(JSON.stringify(this.recommendationsData));
        for (let i = 0; i < this.getRecommendationsDataShow.length; i++) {
            const value = this.getRecommendationsDataShow[i];
            if (value) {
                value.highlight.titleShow = value.highlight.TitleToDisplay != '' ? true : false;
                value.contentTagShow = value.contentTag  && value.contentTag.length ? true : false;
                value.contentTagShowClass = value.contentTag ? 'su-recommend-element su__d-flex su__align-items-start su__w-60' : '';
                value.highlight.titleToShowText = value.highlight.TitleToDisplay[0] || value.href;
                value.highlight.titleToDisplayString = value.highlight.TitleToDisplayString[0];
            }
        }
        return this.getRecommendationsDataShow;
    }

    get recommendationPadding() {
        return this.knowledgeGraph ? 'su__col-lg-12 su__col-md-12 su__col-xs-12 recommendationsPadding-0' : 'su__col-lg-12 su__col-md-12 su__col-xs-12 recommended-main'
    }

    setCommunityCustomSettings(result) {
        var self = this;
        if (result && result.isCustomSettingFilled) {
            self.endPoint = result.endPoint;
            self.customSettingsFilled = true;
            self.bearer = result.token;
            self.uid = result.uid;
            if (result.UserType == "Guest" || result.UserType == undefined) {
                result.userEmail = '';
            } else if (result.userEmail != null && result.userEmail != '') {
                self.currentUserEmail = result.userEmail;
            }
            var oldTitle = document.title;
            var count = 0;
            var checkPageTitle = setInterval(function () {
                count++
                if (document.title !== oldTitle && count > 5) {
                    self.getRecommendationsFunc();
                    clearInterval(checkPageTitle)
                } else if (document.title == oldTitle && count > 5) {
                    self.getRecommendationsFunc();
                    clearInterval(checkPageTitle);
                }
                oldTitle = document.title;
            }, 200);

        } else {
            self.customSettingsFilled = result.isCustomSettingFilled;
            self.customSettingErrorMessage = result.customSettingErrorMessage;
        }
    }

    async connectedCallback() {
        this.loadScriptStyle = await scriptsLoaded();
        this.redirectionUrl = window.scConfiguration && window.scConfiguration.recommendations_widget_config ? window.scConfiguration.recommendations_widget_config.rec_widget_redirect_url : null;
        if (this.getRecommendationsEnable || window.scConfiguration.rec_widget) {
            this.getCommunityCustomSettings = await getCommunitySettings();
            this.setCommunityCustomSettings(this.getCommunityCustomSettings);
        }
    }

    getRecommendationsFunc() {
        if (this.bearer && this.customSettingsFilled) {
            var data = {
                "searchString": [],
                "uid": (window.scConfiguration.rec_widget && typeof this.searchquery === 'undefined') ? this.uid : this.searchquery.uid,
                "language": localStorage.getItem('language') || 'en',
                "sid": (window.scConfiguration.rec_widget && typeof this.searchquery === 'undefined') ? window._gr_utility_functions.getCookie("_gz_taid") + '$Enter$' : this.searchquery.sid + '$Enter$',
                "cookie": (window.scConfiguration.rec_widget && typeof this.searchquery === 'undefined') ? '' : this.searchquery.cookie,
                "useremail": this.currentUserEmail
            }
            if (window.scConfiguration.rec_widget && typeof this.searchquery === 'undefined') {
                data.recommendationType = 2;
                if (!window.scConfiguration.recommendations_widget_config.rec_widget_regex || !location.href.match(new RegExp(window.scConfiguration.recommendations_widget_config.rec_widget_regex, 'gm'))) {
                    data.searchString.push(document.title.trim());
                    var h1Elements = document.getElementsByTagName('h1');
                    if (h1Elements && h1Elements.length > 0) {
                        data.searchString.push(h1Elements[0].textContent.trim());
                    }
                    var h2Elements = document.getElementsByTagName('h2');
                    if (h2Elements && h2Elements.length > 0) {
                        data.searchString.push(h2Elements[0].textContent.trim());
                    }
                } else {
                    data.searchString = "";
                }
            } else {
                data.searchString = this.searchquery.searchString
            }
            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/ai/authSURecommendation";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.bearer);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.send(JSON.stringify(data));
            xmlHttp.onreadystatechange = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var result = JSON.parse(xmlHttp.response);
                        if (result.statusCode != 402) {
                            if (result.statusCode == 200 || result.statusCode == 400) {
                                this.recommendationsData = result.result.hits;
                                this.getRecommendations = this.recommendationsData && this.recommendationsData.length ? true : false;
                            }
                        }
                    }
                }
            }
        }
    }

}