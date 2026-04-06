import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import { fetchCaseData, fetchUsersData, } from 'c/sU_AiqDataRepository';

export default class SU_Feedback extends LightningElement {
    @wire(CurrentPageReference) objpageReference;

    @api caseId;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    @api relatedcasedata;
    @api feedbackLocation;
    @api generativeContent;
    negativeSaveButtonDisabler = true;
    showConfirmationModal = false;

    currentCaseNumber;

    feedback = {
        reaction: null,
        feature: "",
        feedbackMessage: {
            feedbackTags: [],
            feedbackComment: "",
        },
    } //variable to store the feedback of the user
    positiveButtonDisabler = false; //variable to disable the buttons of the feedback once a feedback is given
    negativeButtonDisabler = false; //variable to disable the buttons of the feedback once a feedback is given

    negativeFeedbackOptions = [
        {
            data: "Inaccurate Information",
            metaData: "The response contains wrong or misleading details."
        },
        {
            data: "Off Topic",
            metaData: "The response is not relevant to the customer's query or concern."
        },
        {
            data: "Poorly Framed",
            metaData: "The response is confusing, ambiguous, or hard to understand."
        },
        {
            data: "Incomplete Answer",
            metaData: "The response does not fully address the customer's question or lacks necessary details."
        },
        {
            data: "Tone Inappropriateness",
            metaData: "The response does not use the appropriate tone for the context, such as being too informal or impolite."
        }
    ];

    negativeOptions = [];

    connectedCallback() {
        Promise.all([fetchCaseData(this.caseId), fetchUsersData([USER_ID])])
            .then(([caseData, userData]) => {
                this.caseData = caseData;
                this.userData = userData[USER_ID];
            }).catch(error => {
                console.log('<--- Error in getting details for feedback --->', error);
            });
    }


    renderedCallback() { }

    disconnectedCallback() { }

    closeFeedbackModal() {

        this.negativeOptions = [];
        this.negativeSaveButtonDisabler = true;
        this.negativeFeedbackOptions.forEach((item) => {
            const gettingLi = this.template.querySelector(`li.negative-options-li[data-index="${item.data}"]`);
            if (gettingLi) gettingLi.classList.remove("selected-li");
        })

        let negativeFeedbackMessage = this.template.querySelector(".feedback-textarea");
        if (negativeFeedbackMessage) negativeFeedbackMessage.value = "";

        const outerDiv = this.template.querySelector('.negative-feedback-modal');
        outerDiv.classList.toggle('popup-case-summary');
        outerDiv.style.display = "none";
    }

    closeFeedbackModalHandler() {
        this.showConfirmationModal = true;
    }

    //negative feedback save button handler
    handleSaveFeedbackModal() {
        let negativeFeedbackMessage = this.template.querySelector(".feedback-textarea").value.toString();
        negativeFeedbackMessage = negativeFeedbackMessage.replace(/\s+/g, ' ').trim();
        this.feedback = {
            ...this.feedback,
            feedbackMessage: {
                feedbackTags: [...this.negativeOptions],
                feedbackComment: negativeFeedbackMessage,
            },
        };

        this.feedbackSubmitHandler();
        this.feedbackChangeHandler();
        // this.disableFeedbackButtons();
        //opening thank you modal
        const thankYouModal = this.template.querySelector('.negative-feedback-thanks-modal-backdrop');
        thankYouModal.classList.toggle('popup-case-summary');
        thankYouModal.style.display = "flex";

        setTimeout(() => {
            thankYouModal.classList.toggle('popup-case-summary');
            thankYouModal.style.display = 'none';
            this.closeFeedbackModal();
        }, 2000);
    }

    //func give styling to the selected feedback
    feedbackChangeHandler() {
        const positiveSvg = this.template.querySelector(".positive-feedback-svg-circle");
        const positiveSvgStroke = this.template.querySelector(".positive-feedback-svg-path");
        const negativeSvg = this.template.querySelector(".negative-feedback-svg-circle");
        const negativeSvgStroke = this.template.querySelector(".negative-feedback-svg-path");

        if (this.feedback.reaction) {
            positiveSvg.style.fill = "rgba(22,168,66,1)";
            positiveSvgStroke.style = "stroke: white !important";
        } else {
            positiveSvg.style.fill = "rgba(213,255,220,0.43)";
            positiveSvgStroke.style.stroke = "#16a842";
        }
        if (this.feedback.reaction === false) {
            negativeSvg.style.fill = "#e91b37";
            negativeSvgStroke.style = "stroke: white !important";
        } else {
            negativeSvg.style.fill = "rgba(255,213,214,0.43)";
            negativeSvgStroke.style.stroke = "#e91b37";
        }
    }

    //func to disable the other feedback buttons once a feedback is recorded
    disableFeedbackButtons() {
        this.negativeButtonDisabler = true;
        this.positiveButtonDisabler = true;
        if (this.feedback.reaction) {
            const negativeButton = this.template.querySelector(".negative-feedback-container");
            negativeButton.classList.add("click-not-allowed");
        }
        if (this.feedback.reaction === false) {
            const positiveButton = this.template.querySelector(".positive-feedback-container");
            positiveButton.classList.add("click-not-allowed");
        }
    }

    positiveFeedbackHandler() {
        if (this.positiveButtonDisabler || this.negativeButtonDisabler) return;

        this.feedback = {
            reaction: true,
            feature: this.feedbackLocation,
            feedbackMessage: {
                feedbackTags: [],
                feedbackComment: "",
            }
        };
        //showing the thank you for the positive response
        const positiveContainer = this.template.querySelector('.positive-feedback-container');
        const negativeContainer = this.template.querySelector('.negative-feedback-container');
        positiveContainer.style.display = 'none';
        negativeContainer.style.display = "none";
        const thankYouContainer = this.template.querySelector('.positive-thankyou');
        thankYouContainer.style.display = "flex";

        //closing the thank you for the positive response
        // this.disableFeedbackButtons();
        setTimeout(() => {
            positiveContainer.style.display = 'block';
            negativeContainer.style.display = "block";
            thankYouContainer.style.display = "none";
            this.feedbackChangeHandler();
            this.feedbackSubmitHandler();
        }, 2000);
    }

    negativeFeedbackButtonHandler() {
        if (this.positiveButtonDisabler || this.negativeButtonDisabler) {
            return;
        }

        const updatedFeedback = { ...this.feedback, reaction: false, feature: this.feedbackLocation };
        this.feedback = updatedFeedback;

        //opening negative feedback modal
        const outerDiv = this.template.querySelector('.negative-feedback-modal');
        outerDiv.classList.toggle('popup-case-summary');
        outerDiv.style.display = "flex";

    }

    negativeFeedbackOptionsHandler(event) {
        let incomingFeedback;
        if (event && event.currentTarget) {
            incomingFeedback = event.currentTarget.dataset.index;
        }
        let options;
        const index = this.negativeOptions.findIndex((item) => item === incomingFeedback);

        if (index === -1) options = [...this.negativeOptions, incomingFeedback.toString()];
        else options = this.negativeOptions.filter((item) => item !== incomingFeedback.toString());

        this.negativeOptions = [...options];
        this.negativeSaveButtonDisabler = this.negativeOptions.length === 0;

        const gettingLi = this.template.querySelector(`li.negative-options-li[data-index="${incomingFeedback}"]`);
        if (gettingLi) {
            if (index === -1) gettingLi.classList.toggle("selected-li");
            else gettingLi.classList.remove("selected-li");
        }
    }

    pageUrl() {
        const windowHref = window.location.href;
        const lightningIndex = windowHref.indexOf('lightning/');
        let initalhref = "";
        if (lightningIndex !== -1) {
            initalhref = windowHref.substring(0, lightningIndex + 10); // 10 includes the length of 'lightning/'
        }
        else return windowHref;

        initalhref += "r/" + this.caseId + "/view";
        return initalhref;
    }


    //func to submit the final details of the feedback
    feedbackSubmitHandler() {
        if (this.feedbackLocation == 'response-assist') {
            console.log("this.generativeContent==>", this.generativeContent)
            let responseAssit = JSON.parse(this.generativeContent);
            this.generativeContent = JSON.stringify(`<div class=responseAssist>${responseAssit}</div>`)
        }

        if (this.feedbackLocation == 'top-related-cases') {
            console.log("this.generativeContent==>", this.generativeContent)
            this.generativeContent = JSON.stringify(`
            <div class="feedback-case-wrapper">
            <div class="feedback-box-model"> <div class="case-id-box">
                <b class="feedback-case-number">CASE NUMBER:</b> <a href="${this.generativeContent.previewUrl}" target="_blank">${this.generativeContent.CaseId}</a>
                </div>
                <p class="case-created-label">Created Date: ${this.generativeContent.caseCreated}</p></div>
                <p class="case-subject-text">${this.generativeContent.CaseSubject}</p>
            </div>
            `);

        }
        if (this.feedbackLocation == 'top-related-articles') {
            console.log("this.generativeContent==>", this.generativeContent)
            console.log("this.generativeContent==>", this.generativeContent.Icon)
            this.generativeContent = JSON.stringify(`
            <div class="feedback-article-wrapper">
                <div class="article-header ${this.formatDate(new Date().toISOString())}">
                    <a href="${this.generativeContent.previewUrl}" target="_blank" class="article-title-link">
                        ${this.generativeContent.Title}
                    </a>
                    <div class="article-owner">
                        <img class="article-owner-icon" src="${this.generativeContent.Icon}" alt="Owner Icon" />
                        <span class="article-owner-name">${this.generativeContent.OwnerName}</span>
                    </div>
                </div>
                <div class="article-metadata">
                    <span><b>Last Updated at:</b> ${this.generativeContent.lastModifiedDate}</span> | 
                    <span><b>Source:</b> ${this.generativeContent.sourceLabel}</span>
                </div>
            </div>
        `);
        }

        if (this.feedbackLocation == 'top-experts') {
            console.log("this.generativeContent==>", this.generativeContent);
            this.generativeContent = JSON.stringify(`
            <div class="feedback-expert-wrapper">
                <div class="expert-info">
                    <img class="expert-avatar" src="https://r041902s.searchunify.com/resources/Asset-Library/1e2b824f923c31731b047dd1a8b783f7/photo.png" />
                    <div class="expert-details">
                        <a href="${this.generativeContent.previewUrl}" target="_blank" class="expert-name-link">
                            <div class="expert-name">${this.generativeContent.OwnerName}</div>
                        </a>
                        <div class="expert-title">${this.generativeContent.OwnerTitle || 'Support Agent'}</div>
                        <div class="expert-department">${this.generativeContent.OwnerDepartment || 'Support Team'}</div>
                        <div class="expert-tags">
                            <span class="expert-tag">${this.generativeContent.totalClosedCasesInThousands} Total Cases Solved</span>
                            <span class="expert-tag">${this.generativeContent.closedCasesCountInThousands} Similar Cases Resolved</span>
                        </div>
                    </div>
                </div>
            </div>
        `);
        }

        const payload = {
            event: "ah_response_feedback",
            uid: this.uid,
            caseTitle: this.caseData.subject || '',
            caseId: this.caseId,
            caseNumber: this.caseData.caseNumber,
            agentName: this.userData.Name ? this.userData.Name : null,
            agentEmail: this.userData.Email ? this.userData.Email : null,
            feedbackData: this.feedback,
            ts: this.formatDate(new Date().toISOString()),
            url: this.pageUrl(),
            caseCreatedDate: this.formatDate(this.caseData.createdDate),
            ahResponse: this.generativeContent,
        };

        const data = JSON.stringify(payload);

        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/analytics/suanlytics.png";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.setRequestHeader('Origin', window.location.hostname);
        xmlHttp.setRequestHeader('timeout', 200000);

        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    console.log("feedback successfull")
                } else {
                    console.log("something went wrong in feedback");
                }
            } else {
                console.log("something went wrong in feedback");
            }
        }
        xmlHttp.send(data);
    }

    @api
    resetFeedback() {
        this.feedback = {
            reaction: null,
            feature: "",
            feedbackMessage: {
                feedbackTags: [],
                feedbackComment: "",
            }
        };
        this.negativeOptions = [];
        this.positiveButtonDisabler = false;
        this.negativeButtonDisabler = false;
        this.feedbackChangeHandler();
        const negativeButton = this.template.querySelector(".negative-feedback-container");
        negativeButton.classList.remove("click-not-allowed");
        const positiveButton = this.template.querySelector(".positive-feedback-container");
        positiveButton.classList.remove("click-not-allowed");
    }

    // Input: optional ISO 8601 date string
    formatDate(inputDate = null) {
        let date = inputDate ? inputDate : new Date().toISOString();
        return date.split('.').shift().split('T').join(' ');
    }

    confirmationHandler(event) {
        const callLoc = event.currentTarget.dataset.index;
        this.showConfirmationModal = false;
        if (callLoc === "cancelConfirmation") this.closeFeedbackModal();
    }
}