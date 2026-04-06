//custom
import { LightningElement, track, api, wire } from 'lwc';
import { fetchCaseSummaryData } from 'c/sU_AiqDataRepository';
import { convertToTimezone, trackEvent } from 'c/sU_AiqUtils';
import { CurrentPageReference } from 'lightning/navigation';
import { fireEvent } from 'c/supubsub';

export default class SU_AiqSummary extends LightningElement {
    @wire(CurrentPageReference) objpageReference;
    @api recordId;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    @api loggedInUserData;
    @api metaData;

    @track summaryType = "brief_summary";
    @track summayData = [];
    @track summayDataDetailed
    @track summaryLoading = false;
    @track updated = false;
    @track last_updated;
    @track summayDataError = false;
    @track reloadFeedback = true;
    generativeContent;
    zoomedOrNot = false;

    connectedCallback() {
        this.summaryLoading = true;
        this.summayDataError = false;
        window.addEventListener('resize', this.resizeCheck.bind(this));
        this.resizeCheck();
        this.fetchData();

        trackEvent({
            ...this.metaData,
            feature_category: "Case Summary",
            feature_name: "Brief",
            interaction_type: 'click',
            feature_description: "Clicked on Brief",
            metric: {}
        }, this.loggedInUserData); // As by default brief summary is loaded 

    }

    @track activeTab = 'brief';

    get isBriefActive() {
        return this.activeTab === 'brief';
    }

    get isDetailedActive() {
        return this.activeTab === 'detailed';
    }

    get tabClassBrief() {
        return `tablinks${this.isBriefActive ? ' active' : ''}`;
    }

    get tabClassDetailed() {
        return `tablinks${this.isDetailedActive ? ' active' : ''}`;
    }

    get disableRegenerate() {
        return this.summaryLoading || this.metaData.isClosed;
    }

    get feedbackType() {
        return 'case-summary-' + this.activeTab;
    }


    handleTabClick(event) {
        this.activeTab = event.target.dataset.city;
        // this.summayData = [];
        // this.summayDataDetailed = "";
        // this.summaryLoading = true;
        // this.summayDataError = false;

        if (this.activeTab === "brief") {
            this.summaryType = "brief_summary";
            this.csHeightPreserver(false);
            // this.generativeContent = JSON.stringify(this.summayData);
            this.generativeContent = JSON.stringify(this.getCleanGenerativeContent(this.summayData));

            trackEvent({
                ...this.metaData,
                feature_category: "Case Summary",
                feature_name: "Brief",
                interaction_type: 'click',
                feature_description: "Clicked on Brief",
                metric: {}
            }, this.loggedInUserData);

        } else if (this.activeTab === "detailed") {
            this.csHeightPreserver(true);
            this.summaryType = "detailed_summary";
            this.generativeContent = JSON.stringify(this.summayDataDetailed);
            trackEvent({
                ...this.metaData,
                feature_category: "Case Summary",
                feature_name: "Detailed",
                interaction_type: 'click',
                feature_description: "Clicked on Detailed Summary",
                metric: {}
            }, this.loggedInUserData);
        }
        this.reloadFeedback = false;
        setTimeout(() => {
            this.reloadFeedback = true;
        }, 0);

        // Proceed to fetch the summary data
        // this.fetchData();
    }

    //func to keep the cs height as the breif 
    csHeightPreserver(applyCss) {
        const csHolder = this.template.querySelector(".section-container");
        const currentHeight = csHolder?.offsetHeight;
        if (applyCss) { // brief to detailed 
            csHolder.style = `height: ${currentHeight}px;`
        }
    }

    getCleanGenerativeContent(summaryArray) {
        return summaryArray.map(section => ({
            Title: section.Title,
            Value: section.Value.map(val => typeof val === 'object' ? val.raw : val)
        }));
    }


    feedbackResetChildMethod() {
        const child = this.template.querySelector('c-s-u_-aiq-feedback');
        if (child) {
            child.resetFeedback();
        }
    }

    refreshSummary() {
        this.suResultsLoaderResponse = true;
        this.summayDataError = false;
        this.summaryLoading = true;
        this.fetchData(true)

        trackEvent({
            ...this.metaData,
            feature_category: "Case Summary",
            feature_name: "Regenerate Summary",
            interaction_type: 'click',
            feature_description: "No. of times the summary was Regenerated",
            metric: {}
        }, this.loggedInUserData);
    }

    fetchData(isRefreshed = false) {
        fetchCaseSummaryData(this.recordId, 15)
            .then(result => {
                if (result.success) {
                    this.getFirstResponse(result.data, isRefreshed);
                } else {
                    console.log("Error Fetching data for case summary;", result);
                    this.summaryLoading = false;
                    this.summayDataError = true;
                }
            }).catch(error => {
                console.log("Error Fetching data for case summary;", error);
            });

        this.feedbackResetChildMethod();
    }

    getFirstResponse(data, isRefreshed = false) {
        try {
            let caseComments = [];
            if (data.comments) {
                caseComments = data.comments.map(comment => ({
                    "type": "Comment",
                    "body": comment.body,
                    "author_id": comment.createdById,
                    "created_at": comment.createdDate,
                    "actorType": comment.actorType
                }));
            }

            var sendData = JSON.stringify({
                "uid": this.uid,
                "streaming": false,
                "subject": data.subject ?? '',
                "description": data.description ?? '',
                "type": this.summaryType,
                "case_id": data.Id,
                'token': 'bearer ' + this.token,
                "comments": caseComments,
                "isRefreshed": isRefreshed,
                "jiraIds": (data.jiraIds && data.jiraIds !== '') ? data.jiraIds.split(',') : []
            });
            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/mlService/case-summary";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.setRequestHeader('Origin', window.location.hostname);
            xmlHttp.setRequestHeader('uid', this.uid);
            const startTime = performance.now();
            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    try {
                        if (xmlHttp.status === 200) {
                            let result = JSON.parse(xmlHttp.response);
                            if (result.status === 200) {
                                // if(this.activeTab === "brief"){
                                //     this.summayData = result.brief_response.output.map((pointer)=>{
                                //         if(pointer["Value"].length === 0){
                                //             pointer["Value"].push('NA');
                                //         }
                                //         return pointer;
                                //     });
                                // } else {
                                //     this.summayDataDetailed = result.detailed_response.output;
                                // }

                                this.summayData = result.brief_response.output.map((pointer) => {
                                    if (pointer.Value.length === 0) {
                                        pointer.Value.push('NA');
                                    }

                                    const displayValue = pointer.Value.map((val) => {
                                        let rawValue = typeof val === 'object' ? val.raw : val;

                                        const hasColon = rawValue.includes(':');
                                        const colonTitle = hasColon ? rawValue.split(':')[0] : '';
                                        const colonRest = hasColon ? rawValue.split(':').slice(1).join(':').trim() : '';
                                        const alreadyNumbered = /^\d+\.\s*/.test(rawValue);
                                        const showBullet = !alreadyNumbered;

                                        return {
                                            raw: rawValue,
                                            hasColon,
                                            colonTitle,
                                            colonRest,
                                            showBullet
                                        };
                                    });

                                    return {
                                        Title: pointer.Title,
                                        Value: pointer.Value,
                                        displayValue: displayValue
                                    };
                                });


                                // this.summayData = result.brief_response.output.map((pointer)=>{
                                //     if(pointer.Value.length === 0){
                                //         pointer.Value.push('NA');
                                //     }
                                //     return pointer;
                                // });
                                this.summayDataDetailed = result.detailed_response.output;
                                fireEvent(this.objpageReference, 'summaryData' + this.metaData.eventCode, this.summayDataDetailed);
                                // if(this.activeTab === "brief"){
                                //     this.generativeContent = JSON.stringify(this.summayData);
                                // }else{
                                //     this.generativeContent = JSON.stringify(this.summayDataDetailed);
                                // }

                                if (this.activeTab === "brief") {
                                    const cleanData = this.getCleanGenerativeContent(this.summayData);
                                    this.generativeContent = JSON.stringify(cleanData);
                                } else {
                                    this.generativeContent = JSON.stringify(this.summayDataDetailed);
                                }

                                // Important: ensure reloadFeedback is only set after generativeContent is ready
                                this.reloadFeedback = false;
                                setTimeout(() => {
                                    this.reloadFeedback = true;
                                }, 0);

                                this.updated = result.updated;
                                const [date, time] = convertToTimezone(result.updatedAt, this.loggedInUserData.TimeZoneSidKey).split("T");
                                this.last_updated = `${date} | ${time.split(".")[0]}`;
                                this.summayDataError = false;
                            } else if (result.status === 403) {
                                this.summayDataError = true;
                                // this.summayData = "LLM is Inactive or not Configured.";
                            }
                            else {
                                this.summayDataError = true;
                                // this.summayData = "Unable to generate Response."
                            }
                        } else {
                            this.summayDataError = true;
                            // this.summayData = "Unable to generate Response."
                        }

                        trackEvent({
                            ...this.metaData,
                            feature_category: "Case Summary",
                            feature_name: "Time to Response",
                            interaction_type: 'response_time',
                            feature_description: "Time taken to generate summary",
                            metric: {
                                response_time: performance.now() - startTime,
                                api_status: xmlHttp.status,
                                is_regenerated: isRefreshed
                            }
                        }, this.loggedInUserData);
                    } catch (err) {
                        this.summayDataError = true;
                        console.log("Error fetching the case summary Data:", err);
                    }
                } else {
                    this.summayDataError = true;
                    // this.summayData = "Unable to generate Response."
                }
                this.responseReceived = true;
                this.summaryLoading = false;
                this.suResultsLoaderResponse = false;

            }
            xmlHttp.send(sendData);
        } catch (err) {
            console.log('OUTPUT : ', err);
        }
    }

    toggleSummaryZoom() {
        this.zoomedOrNot = !this.zoomedOrNot;
        const outerDiv = this.template.querySelector('.summary-outer-div');
        outerDiv.classList.toggle('popup-case-summary');
    }

    applyClasses() {
        const overviewHeader = this.template.querySelector('.aiq-case-summary');
        if (overviewHeader) {
            this.headerWidth = overviewHeader.clientWidth;
        }
        else console.log("didnt got the component .aiq-case-summary therefore , not able to add css classes ");
        if (this.headerWidth <= 560) {
            overviewHeader.classList.add("aiq-case-summary-590px");
        }
        else if (this.headerWidth > 560) {
            overviewHeader.classList.remove("aiq-case-summary-590px");
        }
    }

    resizeCheck = () => {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.applyClasses();
        });
    }

}