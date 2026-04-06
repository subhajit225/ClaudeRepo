import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener } from "c/authsupubsub_b6b3_13";


export default class SU_AuthSandboxGptFeedback extends LightningElement {
    @api searchString;
    @api gptContext;
    @api gptResponse;
    @track responseIssue = '';
    @track citationRelevance = '';
    @track performance = '';
    @track expectedResult = '';
    @track showHideWidgetValue = true;
    @track thanksModalValue = false;
    @api endPoint;
    @api bearer;
    @api uid
    @track showHideSandboxFeedback = false;

    connectedCallback() {
        this.showHideWidgetValue = true
        registerListener('gptResponse', this.getGptResponse, this);
        registerListener('getGptSandboxVal', this.updateSandboxFeedbackVisibility, this);
    }

    updateSandboxFeedbackVisibility(data) {
        if (window.scConfiguration  &&  window.scConfiguration?.instanceName?.toLowerCase() == 'sandbox' && data) {
            this.showHideWidgetValue = true;
            this.showHideSandboxFeedback = true;
        } else {
            this.showHideWidgetValue = false;
            this.showHideSandboxFeedback = false;
        }
    }

    disconnectedCallback() {
        unregisterListener('gptResponse', this.getGptResponse, this);
        unregisterListener('getGptSandboxVal', this.getGptSandboxVal, this);
    }

    handleRadioChange(event) {
        this.responseIssue = event.target.value;
    }

    handleOptionClick(event) {
        this.performance = event.target.value;
    }

    handleFeedbackOptionClick(event) {
        this.citationRelevance = event.target.value;
    }

    submitSandboxFeedback() {
        this.thanksModalValue = true;
        let queryPassed = {};
        queryPassed.responseIssue = this.responseIssue;
        queryPassed.citationRelevance = this.citationRelevance;
        queryPassed.performance = this.performance;
        queryPassed.searchString = this.searchString;
        queryPassed.gptContext = this.gptContext || '';
        queryPassed.gptResponse = this.gptResponse || '';
        queryPassed.ExpectedResult = this.expectedResult || '';
        queryPassed.uuid = this.uid
        var data = JSON.stringify(queryPassed);

        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/resources/gptfeedback/add-feedback";
        xmlHttp.withCredentials = true;
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.bearer);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.send(data);
        xmlHttp.onreadystatechange = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    console.log("Feedback Uploaded successfully");
                }else{
                    Error.log("Error while uploading the feedback");
                }
            }
        }

        this.responseIssue = '';
        this.citationRelevance = '';
        this.performance = '';
        this.expectedResult = ''
        setTimeout(() => {
            this.showHideWidgetValue = false;
        }, 300);
        setTimeout(() => {
            this.thanksModalValue = false;
        }, 1000);
        this.gptResponse = '';
    }

    getGptResponse(data) {
        this.gptResponse = data
    }

    getGptDocLink(event) {
        this.expectedResult = event?.target?.value.length > 500 ? event?.target?.value.substring(0, 500) : event?.target?.value;;
    }
}