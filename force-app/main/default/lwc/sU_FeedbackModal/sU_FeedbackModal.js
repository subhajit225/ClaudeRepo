import { LightningElement, api } from 'lwc';
import { fireEvent } from 'c/supubsub';
export default class SU_FeedbackModal extends LightningElement {

    @api thumbsUpFeedbackButtonOne;
    @api thumbsUpFeedbackButtonTwo;
    @api thumbsUpImage;
    @api thumbsDownImage;
    textFeedback = '';
    isActiveSubmit = false;
    isClickedFeedbackButtonOne = false;
    isClickedFeedbackButtonTwo = false;
    displayThanksModal = false;
    feedbackTags = [];
    _feedbackModal = false;
    @api
    get feedbackModal() {
        return this._feedbackModal;
    }

    set feedbackModal(value) {
        this._feedbackModal = value;
    }
    @api eventCode;
    get thanksYouModalContainer() {
        return this.displayThanksModal ? 'su__anim-fadeindown su__feedback-popup su__position-fixed su__shadow-lg su__bg-white su__radius-1 su__mx-auto su__zindex-3 su__d-block ' : 'visibilityHidden su__position-absolute'
    }
    get submitButton() {
        return this.isActiveSubmit ? ' su__mr-10 su__feedback_action_btn su-cursor-pointer su__ml-10' : 'su__mr-10 su__feedback_action_button su__btn_inactive su__ml-10'
    }
    get submitButtonText() {
        return this.isActiveSubmit ? 'su__feedback_btn-text su__feedback_action_text ' : 'su__feedback_btn-text su__feedback_action_text su__black_color';
    }
    get feedbackButtonClickStyleOne() {
        return this.isClickedFeedbackButtonOne ? 'su__feedback_button su__mr-10 su__highlight_feedback_btn su-cursor-pointer' : 'su__feedback_button su__mr-10 su-cursor-pointer';
    }
    get feedbackButtonClickStyleTwo() {
        return this.isClickedFeedbackButtonTwo ? 'su__feedback_button su__mr-10 su__highlight_feedback_btn su-cursor-pointer' : 'su__feedback_button su__mr-10 su-cursor-pointer';
    }
    /**
     * closefeedbackmodal - when user clicks on overlay on screen to close the modal
     */
    closefeedbackmodal() {
        this._feedbackModal = false;
        this.feedbackTags = [];
        this.isActiveSubmit = false;
        this.isClickedFeedbackButtonOne = false;
        this.isClickedFeedbackButtonTwo = false;
        this.textFeedback = '';
        fireEvent(null, "closeModal" + this.eventCode, this.feedbackModal);
    }
    /**
     * submitFeedback - The function executes when user press on submit button to submit the feedback it fires the event
     * which is to  listened in gpt component i.e. parent component.
     */
    submitFeedback() {
        this.displayThanksModal = true;
        this._feedbackModal = false;
        let feedbackPayload = {
            "feedbackModal": this.feedbackModal,
            "feedbackTags": this.feedbackTags,
            "textFeedback": this.textFeedback
        }
        fireEvent(null, "sendFeedback" + this.eventCode, feedbackPayload)
        fireEvent(null, "closeModal" + this.eventCode, this.feedbackModal);
        setTimeout(()=>{
            this.displayThanksModal = false;
        },3000)
    }
    /**
     * closeThankYouModal - It executes when user clicks on overlay of thank you modal
     */
    closeThankYouModal() {
        this._feedbackModal = false;
        this.feedbackTags = [];
        this.textFeedback = '';
        this.displayThanksModal = false;
    }
    /**
     * writeTextFeedback - It get the input feedback and sets in textFeedback 
     * @param {*} event - event captures the users input value
     */
    writeTextFeedback(event) {
        if (event) {
            var inputFeedback = event.target.value;
            var trimmedFeedback = inputFeedback.trim();
            
            this.isActiveSubmit = (trimmedFeedback.length >= 1 || this.isClickedFeedbackButtonOne || this.isClickedFeedbackButtonTwo) ? this.isActiveSubmit = true : this.isActiveSubmit = false;
        }
        if (inputFeedback.length < 300) {
            this.textFeedback = inputFeedback

        } else {
            this.textFeedback = inputFeedback.slice(0, 300)
        }
    }
    /**
     * feedbackButtonClick - This function captures the button selected by user then push the values into 
     * array
     * @param {*} event - event contains the value of button selected
     */
    feedbackButtonClick(event) {
        const buttonValue = event.currentTarget.getAttribute('data-value'); // Use getAttribute to access data-value      
        if ((buttonValue === 'Accurate' || buttonValue === 'Offensive')) {
            this.isClickedFeedbackButtonOne = !this.isClickedFeedbackButtonOne;
        } else {
            this.isClickedFeedbackButtonTwo = !this.isClickedFeedbackButtonTwo;
        }
        if (buttonValue) {
            if (!this.feedbackTags.includes(buttonValue) && (this.isClickedFeedbackButtonOne || this.isClickedFeedbackButtonTwo)) {
                this.feedbackTags.push(buttonValue);
                this.isActiveSubmit = true;
            } else {
                const indexToRemove = this.feedbackTags.indexOf(buttonValue);
                if (indexToRemove !== -1) {
                    this.feedbackTags.splice(indexToRemove, 1); // Remove the element at indexToRemove
                    this.isActiveSubmit = this.feedbackTags.length === 0 ? false : true;
                }
            }
        }
    }
}