import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent, scriptsLoaded, getCommunitySettings } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthPageRating extends LightningElement {
    @track uid;
    @track endPoint;
    @api currentUserEmail;
    pageRatingCustomization = {}
    yesNoTemplate = '';
    thumbsUpDownTemplate = '';
    starsTemplate = '';
    emoticonsTemplate = '';
    feedback_type = '';
    textFeedbackValue = '';
    feedback = '';
    rating = 0;
    displayThanksModal
    showPageRatingWidget = false;
    starsClass = "su__star-gray su__ratingicon su__star su__mr-2 su__cursor su__star su__stars_widget su__emoticons_widget su__mr_10"
    dynamicStarsClass = [{ class: this.starsClass, id: 1 }, { class: this.starsClass, id: 2 }, { class: this.starsClass, id: 3 }, { class: this.starsClass, id: 4 }, { class: this.starsClass, id: 5 }]
    dynamicEmoticonClass = [{ class: "su__emoji su__ratingicon su__mr-5 su__cursor su__emoji-icon1 su__emoticons_widget", id: 1 }, { class: "su__emoji su__ratingicon su__mr-5 su__cursor su__emoji-icon2 su__emoticons_widget", id: 2 }, { class: "su__emoji su__ratingicon su__mr-5 su__cursor su__emoji-icon3 su__emoticons_widget", id: 3 }, { class: "su__emoji su__ratingicon su__mr-5 su__cursor su__emoji-icon4 su__emoticons_widget", id: 4 }, { class: "su__emoji su__ratingicon su__mr-5 su__cursor su__emoji-icon5 su__emoticons_widget", id: 5 }];
    searchExperienceResponseData = {}
    pageRateFeed = 0;
    displayTextModal = false;
    searchFeedbackToggle = false;
    pageRatingObject = {};
    handleSearchFeedback = false;
    searchPageRegex = false;
    pageRatingRegexData = {};
    @track openTextSearchFeedbackModal = false;
    isInputDisabled = false;
    displayCrossIcon = false;
    searchFeedbackEnabled = '';
    contentSearchExp = false;
    feedbackPosition = '';
    userTypeCheck = '';
    isSubmitButtonActive = true;
    isModalContent = false;
    customSettingErrorMessage = " ";
    customSettingsFilled;


    hideModal(Val) {
        return this.openTextSearchFeedbackModal = Val;
    }
    hidePageRatingWidget(Val) {
        return this.showPageRatingWidget = Val;
    }
    displayThankYou(Val) {
        return this.displayCrossIcon = Val;
    }
    
    async connectedCallback() {
        this.loadScriptStyle = await scriptsLoaded();
        this.getCommunityCustomSettings = await getCommunitySettings();
        this.setCommunityCustomSettings(this.getCommunityCustomSettings);
        this.pageRatingCall();
        registerListener("hideModal", this.hideModal, this);
        registerListener("hidePageRatingWidget", this.hidePageRatingWidget, this);
        registerListener("showThankYou", this.displayThankYou, this);
        registerListener("getstartClassData", this.getstartClassData, this);
        registerListener('trackAnalyticsRating', this.handleTrackAnalytics, this);
    }

    disconnectedCallback() {
        unregisterListener("hideModal", this.hideModal, this);
        unregisterListener("hidePageRatingWidget", this.hidePageRatingWidget, this);
        unregisterListener("showThankYou", this.displayThankYou, this);
        unregisterListener("getstartClassData", this.getstartClassData, this);
        unregisterListener('trackAnalyticsRating', this.handleTrackAnalytics, this);
    }

    async setCommunityCustomSettings(result) {
        if (result && result.isCustomSettingFilled) {
            this.endPoint = result.endPoint;
            this.uid = result.uid;
            // Removed the duplicated line: this.customSettingsFilled = result.isCustomSettingFilled;
            if(result.userEmail === ''){
                this.userTypeCheck = "Guest";
            } else if (result.userEmail != null && result.userEmail != '') {
                this.currentUserEmail = result.userEmail;
                this.userTypeCheck = '';
            }
        } else {
            this.customSettingsFilled = result.isCustomSettingFilled;
            this.customSettingErrorMessage = result.customSettingErrorMessage;
        }
    }

    getstartClassData(data) {
        this.dynamicEmoticonClass = data;
    }
    /**
     * This function is called on initial load to read local storage and checks for article url and sets thank you flag to true for 24hours
     * @param  null;
     */

    readLocalStorage() {
        let articlesFeedbackArray = []
        const currentTime = Date.now();
        const feedbackDelay = 1 * 24 * 60 * 60 * 1000;
        const currentLoc = window.location.href;
        articlesFeedbackArray = JSON.parse(localStorage.getItem('articlesSaved')) || [];
        if (this.pageRateFeed == 0) {
            if (articlesFeedbackArray.length) {
                const filteredArray = articlesFeedbackArray.filter(i => i.articleUrl === currentLoc);
                if (filteredArray.length) {
                    const [item] = filteredArray;
                    if (item.articleTimeStamp > currentTime) {
                        this.displayCrossIcon = true;
                        this.showPageRatingWidget = false;
                        this.openTextSearchFeedbackModal = true;
                        this.isModalContent = false;
                        this.selectThankYouText()
                        return
                    }
                    this.displayThanksModal = false;
                }
            }
            this.displayThanksModal = false;
        }
    }

    /**
     * This function check for configuration of page rating and displays the thank you modal text accordingly
     * @param null;
     */
    selectThankYouText() {
        if (this.pageRatingCustomization.pageFeedbackToggle && !this.pageRatingCustomization.searchToggle) {
            return this.searchPageRegex = false;
        }
        else if (!this.pageRatingCustomization.pageFeedbackToggle && this.pageRatingCustomization.searchToggle) {
            this.searchPageRegex = true;
        }
        else if (this.pageRatingCustomization.pageFeedbackToggle && this.pageRatingCustomization.searchToggle && !this.searchPageRegex) {
            return this.searchPageRegex = false;
        } else if (!this.pageRatingCustomization.pageFeedbackToggle && !this.pageRatingCustomization.searchToggle) {
            return this.searchPageRegex = false;
        }
    }
    
    /**
    * This function calls on intial load to get the value of page template type (yes/no,Stars, Emoticons etc ) and sets the value in corresponding
    * template variables
    * @param null;
    */
    selectedPageRatingTemplate() {
        switch (this.pageRatingCustomization.selectedPageTemplete) {
            case 'Yes/No':
                this.feedback_type = String(0);
                this.yesNoTemplate = this.pageRatingCustomization.selectedPageTemplete;
                break;
            case 'Thumbs up/Down':
                this.feedback_type = String(0);
                this.thumbsUpDownTemplate = this.pageRatingCustomization.selectedPageTemplete;
                break;
            case 'Stars':
                this.feedback_type = String(1);
                this.starsTemplate = this.pageRatingCustomization.selectedPageTemplete;
                break;
            case 'Emoticons':
                this.feedback_type = String(1);

                this.emoticonsTemplate = this.pageRatingCustomization.selectedPageTemplete;
            default:
                break;
        }
    }
    /**
     * This function calls when user hovers over stars and emoticons and add the hover class on that emoji/star.
     * @param event event contains index of star/ emoji till user hovers it down
     */

    hoverButton(event) {
        const hover = event.currentTarget;
        const rowIndexdata = hover.dataset.index;
        const ratingIcons = this.template.querySelectorAll('.su__ratingicon');
        if (ratingIcons.length !== 0) {
            for (let i = 0; i < rowIndexdata; i++) {
                ratingIcons[i].classList.add('su__emoji-hover');
                ratingIcons[i].classList.add('su__star-hover');
            }
        }
    }
    /**
     * This function calls when user removes hovers over stars and emoticons and removes the hover class on that emoji/star.
     * @param event event contains index of star/ emoji till user removes the hover effect
     */

    removeHoverButton(event) {
        var hovered = event.currentTarget;
        var rowIndexs = hovered.dataset.index;
        let ratingIcons = this.template.querySelectorAll('.su__ratingicon');
        if (ratingIcons.length != 0) {
            for (let i = 0; i < rowIndexs; i++) {
                ratingIcons[i].classList.remove('su__emoji-hover');
                ratingIcons[i].classList.remove('su__star-hover');
            }
        }
    }
    /**
    * This function calls whenever needs to reset the selected value of stars/emoticons and removes the active class 
    * @param null;
    */
    resetSelected = () => {
        let ratingIcons = this.template.querySelectorAll('.su__emoticons_widget');
        for (var a = 0; a < 5; a++) {
            ratingIcons[a].classList.remove('su__emoji-hover');
            ratingIcons[a].classList.remove('su__emoji-active');
            ratingIcons[a].classList.remove('su__star-yellow');
        }
    }
    /**
    * This function calls whenever user clicks on the stars/emoticons and active class will be added depending upon the index 
    * index represents wherever user clicks on particular star/emoticons out of 5
    * @param rowIndex represents how many stars/emoticons user clicked out of 5
    */

    applySelectedEffect(rowIndex) {
        let ratingIcons = this.template.querySelectorAll('.su__ratingicon');
        for (var i = 0; i < rowIndex; i++) {
            ratingIcons[i].classList.add('su__emoji-active');
            ratingIcons[i].classList.add('su__star-yellow');
        }
    }

    /**
     * The function called corresponding functions related to selecting and deselecting stars and emoticons.
     * @param event In this we are extracting the index till user clicked on star/emoticons out of 5.
     */
    setStarEmoticonsRating(event) {
        if (event && event.currentTarget) {
            var clicked = event.currentTarget;
            var rowIndex = Number(clicked.dataset.index);
            this.rating = rowIndex;
            this.resetSelected();
            this.applySelectedEffect(rowIndex);
        } else if (this.rating == 0) {
            this.resetSelected();
        }
    }
    /**
   * The function executes on intial load and having page rating call, search feedback data, regex instance data  
   */

    pageRatingCall = () => {
        if (this.endPoint) {
            var xmlHttp = new XMLHttpRequest();
            const url = this.endPoint + "/pageRating/getPageRatingData";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
            xmlHttp.send('uid=' + this.uid);
            var self = this; // Store reference to 'this' for later use
            xmlHttp.onreadystatechange = function () {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200 && xmlHttp.responseText) {
                        var response = JSON.parse(xmlHttp.responseText);
                        self.pageRatingCustomization = JSON.parse(response.pageRatingCustomization);
                        self.searchExperienceResponseData = JSON.parse(response.searchFeedback)
                        self.pageRatingRegexData = JSON.parse(response.pageRatingInstance);
                        let contentSearchExpToggleState = JSON.parse(response.contentSearchExp);
                        self.contentSearchExp = contentSearchExpToggleState.enabled;
                        self.feedbackPosition = self.pageRatingCustomization.selectedPostion
                        self.selectedPageRatingTemplate();
                        let showWidgetRegex = self.showWidgetRegexMatch();
                        let searchPageRegexMatch = self.searchPageRegexMatch();
                        let referrerInstanceRegexMatch = self.referrerInstanceRegexMatch();
                        if (self.contentSearchExp === true) {
                            if (showWidgetRegex.found == 1) {
                                if (searchPageRegexMatch.found == 1) {
                                    self.searchPageRegex = true;
                                } else {
                                    self.searchPageRegex = false;
                                }
                                if (referrerInstanceRegexMatch.found == 1) {
                                    self.showPageRatingWidget = true;
                                    self.readLocalStorage()
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    // this is the regex for widget show hide
    // imp note - this showWidgetRegexMatch and referrerInstanceRegexMatch  can both be combined with each other  because both needs to be true to 
    // generate widget;`
    showWidgetRegexMatch() {
        let found = 0;
        var pageRatingCategory = '';
        for (var i = 0; i < this.pageRatingRegexData.length; i++) {
            if (window.location.href && window.location.href.match(this.pageRatingRegexData[i]['regex'])) {
                pageRatingCategory = this.pageRatingRegexData[i].instance_name;
                found = 1;
            }
            return { "found": found, "pageRatingCategory": pageRatingCategory }
        }

    }

    // now if showPageRatingWidget is true then check for search feedback regex

    searchPageRegexMatch() {
        let found = 0;
        var searchPageInstanceCategory = '';
        for (var i = 0; i < this.pageRatingRegexData.length; i++) {
            const hasKey = this.pageRatingRegexData[i].hasOwnProperty('search_regex')
            if (hasKey) {
                if (
                    typeof document.referrer == "string" &&
                    document.referrer.match(
                        this.pageRatingRegexData[i]["search_regex"]
                    ) &&
                    this.pageRatingRegexData[i].search_regex.length != 0
                ) {
                    searchPageInstanceCategory =
                        this.pageRatingRegexData[i].search_regex;
                    found = 1;
                }
            }
            return { "found": found, "searchPageInstanceCategory": searchPageInstanceCategory }
        }

    }
    // this is the regex to make sure user has come from listed url in admin referrer regex
    // ***** need to change the static referrer ryt now coming empty

    referrerInstanceRegexMatch() {
        let found = 0;
        let pageRatingInstanceCategory = '';
        for (var i = 0; i < this.pageRatingRegexData.length; i++) {
            if (typeof document.referrer == 'string' && document.referrer.match(this.pageRatingRegexData[i]['instance_regex'])) {
                pageRatingInstanceCategory = this.pageRatingRegexData[i].instance_name;
                found = 1;
            }
            return { "found": found, "pageRatingInstanceCategory": pageRatingInstanceCategory }
        }

    }
    /**
     * The function executes when text feedback and search feedback toggle settings are off and directly need to send the analytics as user clicks 
     * on the widget
     * @param feedbackPayload it contains object consists of the pageRationg payload need to send to analytics 
     */

    sendFeedbackAnalytics(feedbackPayload) {
        fireEvent(null, 'trackAnalyticsRating', {
            type: 'pagerating', objToSend: feedbackPayload
        });
    }

    /**
     * This function calls whenever user submits the feedback, it pushes the url of the article/case in the articles Feedback Array.
     */
    updateLocalStorage() {
        let feedbackDelay = 1 * 24 * 60 * 60 * 1000;
        let articlesFeedbackArray = JSON.parse(localStorage.getItem('articlesSaved')) || [];
        let currentLoc = location.href;
        let currentTime = Date.now();
        this.pageRateFeed;
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
            articlesFeedbackArray.push({ "articleUrl": window.location.href, "articleTimeStamp": currentTime + feedbackDelay })
        }
        localStorage.setItem('articlesSaved', JSON.stringify(articlesFeedbackArray));
    }

    /**
     * This function sends the analytics and checks for feedback type whether text feedback enabled or search feedback along with page rating widget 
     * and then it correspondingly sends the analytics
     * @param event contains information about the feedback whether 0 or 1  
     */
    sendAnalytics(event) {
        this.feedback = event.currentTarget.dataset.feedback;
        let value = event.currentTarget.dataset.value;
        let pageRatingPayload = {
            articlesFeedback: true,
            articleFeedback: this.textFeedbackValue || '',
            referer: document.referrer,
            window_url: window.location.href,
            uid: this.uid,
            feedback: Number(this.feedback),
            rating: this.rating || 0,
            feedback_type: Number(this.feedback_type),
        }
        if (this.searchFeedbackToggle === true) {
            this.pageRatingObject = pageRatingPayload
        }
        else if (this.searchFeedbackToggle === false && this.pageRatingCustomization.pageFeedbackToggle === true) {
            this.pageRatingObject = pageRatingPayload
        }
        else {
            this.sendFeedbackAnalytics(pageRatingPayload)
        }
    }
    /**
     * The function executes when user clicks on widget and check for the regex toggles, text feedback and search feedback toggles and to show feedback pop ups accordingly 
     * and then correspondingly performs the action.
     * @param event event contains information regarding clickable area elemnent properties  
     */

    SubmitFeedback(event) {
        if (this.starsTemplate || this.emoticonsTemplate) {
            this.setStarEmoticonsRating(event)
        }
        if ((this.searchPageRegex && this.pageRatingCustomization.searchToggle && this.pageRatingCustomization.pageFeedbackToggle)) {
            this.searchFeedbackToggle = true;
            this.handleSearchFeedback = true;
            this.displayTextModal = true;
            this.openTextSearchFeedbackModal = true;
            this.isInputDisabled = true;
            this.isSubmitButtonActive = false;
            this.sendAnalytics(event);

        }
        else if (this.searchPageRegex && this.pageRatingCustomization.searchToggle) {
            this.searchFeedbackToggle = true;
            this.handleSearchFeedback = true;
            this.displayTextModal = false;
            this.openTextSearchFeedbackModal = true;
            this.isInputDisabled = true;
            this.isSubmitButtonActive = false;
            this.sendAnalytics(event);
        }
        else if ((this.pageRatingCustomization.pageFeedbackToggle)) {
            this.displayTextModal = true;
            this.searchFeedbackToggle = true;
            this.handleSearchFeedback = true;
            this.openTextSearchFeedbackModal = true;
            this.searchPageRegex = false;
            this.isSubmitButtonActive = false;
            this.sendAnalytics(event);
        } else if (!this.pageRatingCustomization.pageFeedbackToggle || (!this.searchPageRegex && !this.pageRatingCustomization.searchToggle)) {
            this.updateLocalStorage();
            this.sendAnalytics(event);
            this.displayThanksModal = true;
            this.openTextSearchFeedbackModal = true;
            this.searchPageRegex = false;
            this.showPageRatingWidget = false;
        }
    }
    /**
     * This function sends the page rating analytics
     * @param event 
     */
    handleTrackAnalytics(event) {
        if (event.type == 'search') {
            if (!event.objToSend) { event.objToSend = { 'searchString': this.isWildCardEnabled && !this.searchString.startsWith('#') ? '#' + this.searchString : this.searchString } }
            event.objToSend = {
                ...event.objToSend,
                responseTime: this.searchResultTime,
                isFreshSearch: this.isFreshSearch == -1 ? true : false,
                result_count: this.resultCountReturned,
                filter: this.searchQuery.aggregations,
                default_search: this.default_search,
                exactPhrase: this.exactPhrase,
                withOneOrMore: this.withOneOrMore,
                withoutTheWords: this.withoutTheWords,
                withWildcardSearch: this.withWildcardSearch,
                page_no: this.pageNum
            }
            this.isFreshSearch = false;
        }
        if (event.type == 'conversion') {
            event.objToSend.pageSize = this.pageSize;
            event.objToSend.page_no = this.pageNum;
        }
        if (event.type == 'autocomplete') {
            event.type = 'search';
            event.objToSend.searchString = this.searchString;
        }
        window.gza(event.type, event.objToSend);
    }
}