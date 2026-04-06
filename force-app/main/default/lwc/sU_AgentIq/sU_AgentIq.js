import { LightningElement, track, api, wire } from 'lwc';
// import {fetchSentimentData} from 'c/sU_AiqDataRepository';
import {fetchCaseData, fetchUsersData, fetchCaseRecord} from 'c/sU_AiqDataRepository';
import { registerListener, unregisterListener, fireEvent} from 'c/supubsub';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import {checkAccess} from 'c/sU_AiqDataRepository';

export default class SU_AgentIq extends LightningElement {
    @wire(CurrentPageReference) objpageReference;
    @api endPoint;
    @api isUtility;
    @api caseIdForUtility;
    @api recordId;
    @api token;
    @api s3endpoint;
    @api uid;
    @api searchUidAH;
    @api searchUidRA;
    @api eventCode;
    @api utilityTop;
    @api suComponentHeight;
    @api maincontainerwidth;
    @api isCaseInBg;
    @track catGif;
    @track currentCaseNumberForAh;
    @track loggedInUserData;
    @track metaData = {};
    @track ahLogo = '';
    showDatesInSystemTimezone = true;
    overViewFirst = true;
    @track activeTab = this.overViewFirst ? 'overview' : 'actions';
    isLoading = true;
    somethingWentWrong = false;
    isvalidCase = true;
    hasAccess =true;
    hashtags = [];
    sentimentScore;
    sentimentType;
    sentimentSentences = [];
    smallScreenStr = false;

    connectedCallback() {
        this.catGif = this.s3endpoint + '/Assets/cat.gif';
        if(!this.caseId){
            this.isvalidCase = false;
            this.isLoading = false;
        }else{
            checkAccess(this.recordId)
            .then((accessResponse) => {
                if (accessResponse && accessResponse.hasAccess) {
                    this.hasAccess = true;
                    fetchCaseRecord(this.caseId, 'IsClosed,Description')
                    .then(async (caseRecord)=>{
                        if(caseRecord){
                            this.currentCaseNumberForAh = caseRecord.CaseNumber;
                            this.metaData = {
                                caseNumber: this.currentCaseNumberForAh,
                                uid: this.uid,
                                isClosed: caseRecord.IsClosed,
                                description: caseRecord.Description,
                                token: this.token,
                                eventCode: this.eventCode,
                                searchUidAH: this.searchUidAH,
                                searchUidRA: this.searchUidRA,
                                responseAssistDataHtml: null,
                                responseAssistDataMarkdown: null,
                                detailedSummaryData: null,
                            };
                            this.isvalidCase = true;  

                            // fetchSentimentData(this.caseId, 5)
                            try {
                                const [caseData, userData] = await Promise.all([
                                    fetchCaseData(this.caseId),
                                    fetchUsersData([USER_ID])
                                ]);
                                this.loggedInUserData = userData[USER_ID];
                                if(this.showDatesInSystemTimezone){
                                    this.loggedInUserData.TimeZoneSidKey = Intl.DateTimeFormat().resolvedOptions().timeZone;
                                }
                                this.getCaseSentiments(caseData);
                                this.isLoading = false;
                                this.sectionName = 'Overview';
                            } catch (error) {
                                console.log(error);
                                this.isLoading = false;
                                this.somethingWentWrong = true;
                            }

                        }else{
                            this.isvalidCase = false;
                            this.isLoading = false;
                        }
                    })
                    .catch((error)=>{
                        console.log(error);
                        this.isLoading = false;
                        this.somethingWentWrong = true;
                    });
                } else {
                    this.isLoading = false;
                    this.hasAccess = false;
                }
            })
            .catch((err) => {
                console.log("Error validating access to Agent Helper:", err);
                this.isLoading = false;
                this.somethingWentWrong = true;
            });
        }
        registerListener('aiqHastags' + this.eventCode, this.recieveHastags, this);
        registerListener("handleAhError" + this.eventCode, this.handleAhError, this );
        registerListener('summaryData' + this.eventCode, this.handleSummaryData, this);
        registerListener('responseAssistData' + this.eventCode, this.handleResponseAssistData, this);
        window.addEventListener('resize', this.resizeCheck.bind(this));
        this.resizeCheck();
        this.ahLogo = this.s3endpoint + '/Assets/ah-logo.svg';
    }

    renderedCallback(){
        this.resizeCheck();
    }
    disconnectedCallback() {
        unregisterListener('aiqHastags' + this.eventCode, this.recieveHastags, this);
        unregisterListener('handleAhError' + this.eventCode, this.recieveHastags, this);
        unregisterListener('summaryData' + this.eventCode, this.recieveHastags, this);
        unregisterListener('responseAssistData' + this.eventCode, this.recieveHastags, this);
        window.removeEventListener('resize', this.resizeCheck.bind(this));
    }

    errorCallback(error, stack) {
        console.log("-----------ERROR AGENT Helper-----------", error, stack);
        this.isLoading = false;
        this.somethingWentWrong = true;
    }


    get caseId() {
        return this.isUtility ? this.caseIdForUtility : this.recordId;
    }
    get isOverviewActive() {
        return this.activeTab === 'overview';
    }

    get isActionsActive() {
        return this.activeTab === 'actions';
    }

    get tabClassOverview() {
        return `tablinks${this.isOverviewActive ? ' active' : ''}`;
    }

    get tabClassActive() {
        return `tablinks${this.isActionsActive ? ' active' : ''}`;
    }

    get loadAH() {
        return !this.isLoading && !this.somethingWentWrong && this.isvalidCase && this.hasAccess;
    }

    handleTabClick(event) {
        this.activeTab = event.target.dataset.city;
    }
    recieveHastags(tags){
        this.hashtags = [...tags];
    }
    handleAhError(error){
        console.log("<-----Error occured ---->", error);
        this.somethingWentWrong = true;
    }

    handleSummaryData(summaryData) {
        this.metaData.detailedSummaryData = summaryData;
    }
    handleResponseAssistData(responseAssistData) {
        this.metaData.responseAssistDataHtml = responseAssistData.htmlData;
        this.metaData.responseAssistDataMarkdown = responseAssistData.markdownData;
    }

    getCaseSentiments(caseData) {
        try{
            let caseComments = [];
            // if (caseData.comments && caseData.comments.length) {
            //     caseComments = caseData.comments.map(comment => comment.body);
            // }
            var data = JSON.stringify({
                "uid": this.uid,
                'case': {
                    'Id': this.caseId,
                    'description': caseData.description ?? '',
                    'title': caseData.subject ?? '',
                    'comments': caseComments
                }
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/mlService/case-sentiments";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.setRequestHeader('uid', this.uid);
            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    try{
                        if (xmlHttp.status === 200) {
                            var result = JSON.parse(xmlHttp.response);
                            let colorCode ={
                                neutral: {
                                color: "#F7C336",
                                background: "#F6FF0757"
                                },
                                negative: {
                                color: "#DD0000",
                                background: "#FADBDB"
                                },
                                positive: {
                                color: "#2FA32F",
                                background: "#D0E9A8"
                                }
                            }
                            this.sentimentScore = result.overall_sentiment;
                            this.sentimentType = result.sentiment_name.toLowerCase();
                            this.sentimentSentences = result.metadata_sentiment;
                            this.activeSentimentSvg(this.sentimentType);

                            this.sentimentSentences.forEach(sentenceObj => {
                                let end = 0;
                                let sentenceHtml = [`<li style="font-size: 12px; color: #707070;">`];

                                sentenceObj.sentiment_keywords.forEach(r => {
                                    r.start_index = Math.max(end, r.start_index);
                                    // Append plain text before the sentiment keyword
                                    sentenceHtml.push(this.escapeHtml(sentenceObj.sentence.slice(end, r.start_index)));
                                    // Append formatted sentiment keyword
                                    let { color, background } = colorCode[r.token_sentiment.toString().toLowerCase()];
                                    sentenceHtml.push(
                                        `<span style="font-weight: bold; padding: 0 2px; display: inline; color: ${color}; background: ${background};">`
                                        + this.escapeHtml(sentenceObj.sentence.slice(r.start_index, r.end_index))
                                        + `</span>`
                                    );

                                    end = r.end_index;
                                });
                                // Append remaining text after the last keyword
                                sentenceHtml.push(this.escapeHtml(sentenceObj.sentence.slice(end)));
                                sentenceHtml.push(`</li>`);
                                sentenceObj.sentenceHtml = sentenceHtml.join('');
                            });
                        }
                    } catch(err){
                        console.log("Error in processing case-sentiments", err);
                        // this.somethingWentWrong = true;
                    }
                    
                }
            }
            xmlHttp.send(data);
        } catch(err){
            console.log("Error in case-sentiments request", err);
            // this.somethingWentWrong = true;
        }
    }

    escapeHtml(text) {
        return text.replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    showSearchConsole(){
        fireEvent(this.objpageReference, "toggleAH" + this.eventCode, true);
    }

    applyClasses() {
        const agentIQHeader = this.template.querySelector(".SUcheckingWidthClass");
        if (agentIQHeader) {
            this.headerWidth = agentIQHeader.clientWidth;
        } else console.log("cant get the header SU component to apply responsive css");
        if(this.headerWidth <= 590)
            this.smallScreenStr = true;
        else if (this.headerWidth > 590)
            this.smallScreenStr = false;

    }

    resizeCheck = () => {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.applyClasses();
        });
        this.sentimentType && this.activeSentimentSvg(this.sentimentType);
        
    }
    
    activeSentimentSvg(sentimentType){
        const sentimentSvg = this.template.querySelector(`.${sentimentType}-sentiment-svg`);
        if(sentimentSvg){
            sentimentSvg.classList.add('active');
        }
    }
}