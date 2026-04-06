import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthFeedbackModal extends LightningElement {
@api showFeedbackModal;
    @api uid;
    @api endPoint;
    @track inputFeedbackValue;
    @track feedbackRatingVal;
    @track feedbackRateVal;
    @api searchString;
    @track displayThanksModal = false;
    @api searchFeedbackEnabled;
    @track showFollowupEmail = true;
    @api isSubmitButtonActive;
    @api currentUserEmail;
    @api searchConversionFeedback;
    @api listResponseData;
    @api feedbackResultClick;
    @api customData;
    @api updateLocalStorage;
    conversionFeedback = false;
    feedbackConversionObject = {};
    @api pageNum;
    @api totalPages;
    @api totalResults;
    @api pageSize
    @api titleClickedValue;
    @api pageRatingObject;
    @api handleSearchFeedback;
    @api searchPageRegex;
    @api displayTextModal;
    @api searchFeedbackHeading = false;
    textFeedbackSubmitButton = false;
    textInputFeedbackValue = '';
    @api pageRatingCustomization;
    @api showPageRatingWidget;
    @api rating;
    @api setStarEmoticonsRating;
    @api searchFeedbackResponseData;
    @api displayCrossIcon;
    @api openTextSearchFeedbackModal;
    @api feedbackPosition;
    @api dynamicEmoticonClass;
    @api resetSelected;
    @api userTypeCheck;
    @api displayThanksModal;
    @api isModalContent;
    conversionButtonClicked = false;
    searchFeedbackSvgClicked = false;
    showModal = false;
    userEmail = ''
    searchEmailId = '';
    searchFeedbackData = {};
    @api isInputDisabled;
    pageRatingSelectedTemplate = '';
    starsClass = "su__star-gray su__ratingicon su__star su__mr-2 su__cursor su__star"
    dynamicStarsClass = [{ class: this.starsClass, id: 1 }, { class: this.starsClass, id: 2 }, { class: this.starsClass, id: 3 }, { class: this.starsClass, id: 4 }, { class: this.starsClass, id: 5 }]
    dynamicEmoticonsClass = [{ class: "su__emoji su__ratingicon su__mr-1 su__cursor su__emoji-icon1", id: 1 }, { class: "su__emoji su__ratingicon su__mr-1 su__cursor su__emoji-icon2", id: 2 }, { class: "su__emoji su__ratingicon su__mr-1 su__cursor su__emoji-icon3", id: 3 }, { class: "su__emoji su__ratingicon su__mr-1 su__cursor su__emoji-icon4", id: 4 }, { class: "su__emoji su__ratingicon su__mr-1 su__cursor su__emoji-icon5", id: 5 }];



    get StarsRating() {
        return this.searchFeedbackData.selectedSearchTemplate == 'Stars' ? true : false;
    }
    get EmoticonsRating() {

        return this.searchFeedbackData.selectedSearchTemplate == 'Emoticons' ? true : false;
    }
    get feedbackModalContainer() {
        return this.feedbackPosition == 'Center' ? 'su__feedback-modal su__zindex-2' : 'su__position-relative';
    }
    get feedbackModalInnerDiv() {
        return this.feedbackPosition == 'Center' ? 'su__anim-fadeindown su__feedback-popup su__position-fixed su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-3 su__d-block' : 'su__position-relative m-l-0 su__anim-fadeindown su__feedback_bottom';
    }
    get thanksYouModalContainer() {
        return this.displayThanksModal ? 'su__anim-fadeindown su__feedback-popup su__position-fixed su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-3 su__d-block ' : 'visibilityHidden su__position-absolute'
    }
    get thankyouModalOverlay() {
        return this.displayThanksModal ? 'su__bg-overlay' : 'su__d-none';
    }
    get displayModalOverlay() {
        return this.showFeedbackModal && this.feedbackPosition == 'Center' ? 'su__bg_feedback_overlay' : 'su__d-none';
    }
    get usersEmailValue() {
        return this.currentUserEmail != '' && this.userTypeCheck != 'Guest' ? this.userEmail = this.currentUserEmail : this.userEmail 
    }
    get showSearchFeedbackHeading() {
        return this.displayTextModal ? this.searchFeedbackHeading = false : this.searchFeedbackHeading = true;
    }
    get disableButton() {
        return this.isSubmitButtonActive ? 'su__bookmark-save su__submit_button su__top_align button-disabled' : 'su__bookmark-save su__submit-feedback su__top_align'
    }
    get isModalContentfound() {
        if ((this.openTextSearchFeedbackModal || this.showFeedbackModal) && this.isModalContent && (!this.displayCrossIcon || this.conversionButtonClicked || this.searchFeedbackSvgClicked)) {
            return true;
        } else {
            return false;
        }
    }
    get alreadySubmittedThanksModalClass() {
        return this.displayCrossIcon === true ? 'su__thankyou_modal' : 'visibilityHidden su__position-absolute'
    }
    get thankyouText(){
        if(this.searchPageRegex === false && this.displayTextModal === true){
            return this.pageRatingCustomization.selectedAck
        } else if(this.searchPageRegex === false && this.displayTextModal === false){
            return this.pageRatingCustomization.selectedAck
        } else{
            return this.searchFeedbackData.selectedSearchAcknowledgement
        }
    }
    feedbackEmailChange(event){
        this.userEmail = event.currentTarget.value;
        event.target.value.length >= 1 ? this.isSubmitButtonActive = false : this.isSubmitButtonActive = true;
       
    }

    /**
     * The function executes when user clicked on search feedback svg and then pop up opens and when clicked on cross icon again this function
     * is called
     */

    openFeedbackModal() {
        this.userEmail = '';
        this.inputFeedbackValue = '';

        if(this.conversionButtonClicked){
            this.conversionButtonClicked = false;
        }
        
        if (this.showModal === true || this.displayTextModal === true  ) {
            if (this.openTextSearchFeedbackModal === true) {
                this.rating = 0;
                if (this.pageRatingSelectedTemplate?.selectedPageTemplete == 'Stars' || this.pageRatingSelectedTemplate?.selectedPageTemplete == 'Emoticons') {
                    this.resetSelected();
                }

                if(!this.displayCrossIcon){
                this.openTextSearchFeedbackModal = false;
                }
                fireEvent(null, "hideModal", this.openTextSearchFeedbackModal);
            }
            this.showModal = false;
            this.showFeedbackModal = false;
            this.searchPageRegex = false;
            this.feedbackRatingVal = 0;
            this.displayTextModal = false;
            this.isSubmitButtonActive = true;
            return
        }
        this.searchFeedbackSvgClicked = true;
        this.showModal = true;
        this.showFeedbackModal = true;
        this.searchPageRegex = true;
        this.isModalContent = true;
        if (this.currentUserEmail != '' && this.searchFeedbackData.followUpToggle && this.userTypeCheck != 'Guest') {
            this.isInputDisabled = true;
            this.isSubmitButtonActive = false;
        } 
        else if(this.currentUserEmail != '' && this.searchFeedbackData.followUpToggle && this.userTypeCheck == 'Guest'){
            this.isInputDisabled = false;
        } else {
            this.isSubmitButtonActive = true;
        }
    }
    /**
     * The function executes when user clicks on three dotes conversion svg and this will open the modal
     * @param event event contains title and href of result clicked
     */

    feedbackOnResult(event) {
        this.showModal = true;
        this.userEmail ='';
        this.conversionButtonClicked = true;
        this.inputFeedbackValue ='';
        this.searchPageRegex = true;
        this.showFeedbackModal = true;
        this.isModalContent = true;
        if (this.currentUserEmail != '' && this.searchFeedbackData.followUpToggle && this.userTypeCheck != 'Guest') {
            this.isInputDisabled = true;
            this.isSubmitButtonActive = false;
        }
        else if(this.currentUserEmail != '' && this.searchFeedbackData.followUpToggle && this.userTypeCheck == 'Guest'){
            this.isInputDisabled = false;
        }
         else {
            this.isSubmitButtonActive = true;
        }
        if (event) {
            let obj = {
                href: event.href,
                title: event.title,
                titleClickedValue: event.titleClickedValue
            }
            this.feedbackConversionObject = obj;
        }
        this.conversionFeedback = true;
    }
    /**
     * The function stores the value in the variable that user types in the text box of page rating text feedback.
     * @param event event contains information of the types text in the textarea.
     */

    textFeedbackAreaChange(event) {
        this.textInputFeedbackValue = event.target.value;
        event.target.value.length >= 1 ? this.isSubmitButtonActive = false : this.isSubmitButtonActive = true;
    }
    /**
     * The function stores the value in the variable that user types in the text box.
     * @param event event contains information of the types text in the textarea.
     */

    feedbackAreaChange(event) {
        this.inputFeedbackValue = event.target.value;
        event.target.value.length >= 1 ? this.isSubmitButtonActive = false : this.isSubmitButtonActive = true;
    }
    /**
    * The function called when user clicks on cross icon of thank you pop up
     */
    closeThankYouModal() {
        this.displayThanksModal = false;
        this.conversionFeedback = false;
        // this piece of code will run specifically for when page rating widget is clicked
        if (this.openTextSearchFeedbackModal) {
            this.displayCrossIcon = true;
            this.openTextSearchFeedbackModal = false;
            this.showPageRatingWidget = false;
            fireEvent(null, "hidePageRatingWidget", this.showPageRatingWidget);
        }
    }


    connectedCallback() {

        if (this.pageRatingCustomization) {
            this.pageRatingSelectedTemplate = JSON.parse(JSON.stringify(this.pageRatingCustomization));
        }
        this.getSearchExp();
        if (this.displayTextModal === true && this.searchPageRegex === false) {
            this.handleSubmitButton();
        }
        registerListener("openConversionModal", this.feedbackOnResult, this);
        registerListener("openFeedbackModal", this.openFeedbackModal, this);
    }

    disconnectedCallback() {
        unregisterListener("openConversionModal", this.feedbackOnResult, this);
        unregisterListener("openFeedbackModal", this.openFeedbackModal, this);
    }

    /**
     * This function executes on intitial load when only text feedback is enabled from page rating and also search page regex is false
     * @param null;
     */
    handleSubmitButton() {
        this.textFeedbackSubmitButton = true;
    }
    /**
     * The function calls on intial load and having the data of search experience feedback
     * @param null
     */
    getSearchExp() {
        if (this.endPoint != 'undefined') {
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
                        self.searchFeedbackData = JSON.parse(response.searchFeedback)
                        self.searchEmailId = self.searchFeedbackData.searchEmailId
                        self.isModalContent = true;
                    }
                }
            }
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
    resetStarEmoticonsSelected = () => {
        let ratingIcons = this.template.querySelectorAll('.su__ratingicon');
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

    applyEffectOnEmoticonsStars(rowIndex) {
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

    setStarEmoticons(event) {
        var clicked = event.currentTarget;
        var rowIndex = Number(clicked.dataset.index);
        this.feedbackRatingVal = rowIndex;
        let ratingIcons = this.template.querySelectorAll('.su__ratingicon');
        if (ratingIcons.length != 0) {
            this.isSubmitButtonActive = false
            this.resetStarEmoticonsSelected();
            this.applyEffectOnEmoticonsStars(rowIndex);
        }
        this.isSubmitButtonActive = false;
    }
    /**
     * The function executes when user submits the feedback and checks for feeddback type whether it is page rating and search feeback or
     *  search feedback/conversion and fire the analytics event accordingly
     */

    submitFeedback() {
        if (this.handleSearchFeedback === true) {
            if (this.searchPageRegex === true) {
                let searchFeedbackPayload = {
                    referer: document.referrer,
                    uid: this.uid,
                    window_url: window.location.href || '',
                    feedback: this.inputFeedbackValue || '',
                    rating: this.feedbackRatingVal || '',
                    text_entered: this.searchString || '',
                    reported_by: this.userEmail || ''
                };
                fireEvent(null, 'trackAnalyticsRating', {
                    type: 'searchfeedback', objToSend: searchFeedbackPayload
                });
            }

            let pageRatingPayload = {
                articlesFeedback: this.pageRatingObject.articlesFeedback,
                articleFeedback: this.textInputFeedbackValue || '',
                referer: this.pageRatingObject.referer,
                window_url: this.pageRatingObject.window_url,
                uid: this.pageRatingObject.uid,
                feedback: this.pageRatingObject.feedback,
                rating: this.pageRatingObject.rating || 0,
                feedback_type: Number(this.pageRatingObject.feedback_type)
            }
            fireEvent(null, 'trackAnalyticsRating', {
                type: 'pagerating', objToSend: pageRatingPayload
            });
            this.updateLocalStorage();

        } else {
            let objToSend = {
                referer: document.referrer,
                uid: this.uid,
                window_url: window.location.href || '',
                feedback: this.inputFeedbackValue || '',
                rating: this.feedbackRatingVal || '',
                text_entered: this.searchString || '',
                reported_by: this.userEmail || ''
            };
            if (this.conversionFeedback === true) {
                objToSend["conversion_url"] = this.feedbackConversionObject.href;
                objToSend["conversion_title"] = this.feedbackConversionObject.title;
                objToSend["conversion_position"] = this.feedbackConversionObject.titleClickedValue + +1;
                objToSend["pageSize"] = this.pageSize || '';
                objToSend["page_no"] = this.pageNum || '';
            }
            fireEvent(null, 'trackAnalytics', {
                type: 'searchfeedback', objToSend: objToSend
            });
        }
        this.isModalContent = false;
        this.showFollowupEmail = true;
        this.isSubmitButtonActive = true;
        this.showFeedbackModal = false;
        this.displayThanksModal = true;
        this.showPageRatingWidget = false;
        this.showModal = false;
        this.conversionButtonClicked = false;
        this.searchFeedbackSvgClicked = false;
    }
    /**
     * The function executes when user toggles the follow up for email
     * @param event : event contains details of yes or no radio button clicked details.
     */
    toggleFollowUpEmail(event) {
        if (event && event.currentTarget && event.currentTarget.value) {
            var radioValue = event.currentTarget.value;
        }
        this.showFollowupEmail = true;
        if (radioValue == 'No') {
            this.showFollowupEmail = false;
            this.userEmail = '';
            return
        }
        this.userTypeCheck !='Guest' ? this.userEmail = this.currentUserEmail : this.userEmail;
        this.userEmail.length >=1 ? this.isSubmitButtonActive = false : this.isSubmitButtonActive = true;
        if (this.currentUserEmail.length == 0 && this.currentUserEmail.length == '') {
            this.isSubmitButtonActive = false;
            return
        }
    }
  
}