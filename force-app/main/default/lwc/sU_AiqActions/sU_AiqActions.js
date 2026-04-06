import { LightningElement, track, api } from 'lwc';
import RelatedCaseDetails from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseDetails';
import {trackEvent} from 'c/sU_AiqUtils';
import getDataByObject from '@salesforce/apex/su_vf_console.AgentHelper.getDataByObject';
import {fetchCaseSummaryData} from 'c/sU_AiqDataRepository';

export default class SU_AiqActions extends LightningElement {

    currentUserInfo;
    @api recordId;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    @track refinedQuery;
    @api eventCode;
    @api maincontainerwidth;
    @api loggedInUserData;
    @track activeTab = 'responseAssist';
    @api metaData;
    headerWidth;
    isLoading = false;
    relatedCaseIds;  
    ownerId;  
    topArticlesIds;
    topArticlesData;
    queryApiFired = false;
    queryLoading = false;    
    articlesLoading = true;
    caseSearchError = false;
    articleSearchError = false;
    queryError = false;
    openModal = false;
    isTrackedPageView = false;
    tabModalHeading = "Top Related Articles";
    connectedCallback() {
        window.addEventListener('resize', this.resizeCheck.bind(this));
        this.isTrackedPageView = false;
        this.resizeCheck();
    }

    renderedCallback() {
       //code
       if (!this.queryApiFired) {
            this.queryLoading = true;
            let whereClause = {
                "operator": "equals",
                "key": "Id",
                "value": `${this.recordId}`
            }
            const sObjectName = 'Case';
            const fieldsToFetch = ['Problem_Type__c', 'Sub_Component__c'];
            RelatedCaseDetails({ 'sCaseId': this.recordId })
            .then((result) => {
                getDataByObject({
                    sObjectName,
                    fieldsToFetch,
                    whereClause: JSON.stringify(whereClause),
                    orderBy: '',
                    recordsLimit: null
                }).then(res => {
                    try {
                        const records = JSON.parse(res[sObjectName]) || [];

                        if (records.length > 0) {
                            result.sub = records[0].Sub_Component__c;
                            result.problem = records[0].Problem_Type__c;
                        }
                        this.getRefineQuery(result).then(() => {
                            this.allRelatedCasesBySearch(result);
                            this.topArticlesBySearch(result);
                        }).catch((err) => {
                            console.error("Error in getRefineQuery:", err);
                            this.allRelatedCasesBySearch(result);
                            this.topArticlesBySearch(result);
                        });
                    } catch (e) {
                        console.error(`Error parsing case result for`, e);
                    }
                }).catch(err => {
                    console.error(`❌ Error fetching case count for`, err);
                });
            }).catch(err => {
                console.error("❌ Error fetching related case details", err);
            });
            this.queryApiFired = true;
        }
    }

    errorCallback(error) {
        console.log("==errorCallback===",  error);
    }    
    get isResponseAssistActive() {
        return this.activeTab === 'responseAssist';
    }

    get isRelatedArticlessActive() {
        return this.activeTab === 'relatedArticles';
    }
    get isRelatedCasesActive() {
        return this.activeTab === 'relatedCases';
    }

    get isTopExpertsActive() {
        return this.activeTab === 'topExperts';
    }

    get tabClassOverview() {
        return `tablinks${this.isResponseAssistActive ? ' active' : ''}`;
    }

    get tabClassRelatedArticles() {
        return `tablinks${this.isRelatedArticlessActive ? ' active' : ''}${this.articlesLoading ? ' query-loading' : ''}`;
    }

    get tabClassRelatedCasesActive() {
        return `tablinks${this.isRelatedCasesActive ? ' active' : ''}${this.queryLoading ? ' query-loading' : ''}`;
    }

    get tabClassTopExpertsActive() {
        return `tablinks${this.isTopExpertsActive ? ' active' : ''}${this.queryLoading ? ' query-loading' : ''}`;
    }
    get caseId() {
        return this.isUtility ? this.caseIdForUtility : this.recordId;
    }

    avoidClick(event){
        event.stopPropagation();
    }

    handleTabClick(event) {
        if(!this.queryLoading){
            this.activeTab = event.target.dataset.city;
        }
        this.trackTabChangeEvent({tab: event.target.dataset.city, screen_view: 'large'});
    }

    handleTabClick2(event) {
        if(this.queryLoading && event.currentTarget.dataset.city !== "responseAssist"){
            return
        }
        this.openModal=true;
        this.activeTab = event.currentTarget.dataset.city;
        if(this.isResponseAssistActive) this.tabModalHeading = "Response Assist";
        else if(this.isRelatedArticlessActive) this.tabModalHeading = "Top Related Articles";
        else if(this.isRelatedCasesActive) this.tabModalHeading = "Top Related Cases";
        else if(this.isTopExpertsActive) this.tabModalHeading = "Top Experts";

        this.trackTabChangeEvent({tab: event.currentTarget.dataset.city, screen_view: 'small'});
    }

    trackTabChangeEvent(data){
        let featureNames = {
            responseAssist: "Response Assist",
            relatedArticles: "Top Articles",
            relatedCases: "Top Related Cases",
            topExperts: "Top Experts"
        };
        trackEvent({
                    ...this.metaData,
                    feature_category: featureNames[data.tab],
                    feature_name: featureNames[data.tab],
                    interaction_type: 'click',   
                    feature_description: `Clicked on ${featureNames[data.tab]} tab`,
                    metric: {screen_view: data.screen_view}
                }, this.loggedInUserData);
    }
    tabModalCloseHandler(){
        this.openModal = false;
        this.activeTab = "";
    }

    applyClasses() {
        const actionHeader = this.template.querySelector('.action-header-holder');
        if (actionHeader) {
            this.headerWidth = actionHeader.clientWidth;
        }
        else console.log("didnt got the component .action-header-holder therefore , not able to add css classes ");
        if(this.headerWidth <=590){
            actionHeader.classList.add("responsive-css-class-width-530px");
            if(!this.openModal) this.activeTab = "";
            this.isTrackedPageView = false;
        }
        else if (this.headerWidth > 590){
            actionHeader.classList.remove("responsive-css-class-width-530px");
            this.openModal = false; 
            this.activeTab = 'responseAssist';
        }
    }

    resizeCheck = () => {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.applyClasses();
        });
    }

    allRelatedCases(relatedCase) {
        return new Promise((resolve, reject) => {
            var data = JSON.stringify({
                "uid": this.uid,
                'doc': {
                    'contactemail': relatedCase.ContactEmail ?? '',
                    'createdDate': relatedCase.CreatedDate ?? '',
                    'su_vf_console__SearchUnifySessionId__c': relatedCase.su_vf_console__SearchUnify_Session_Id__c ?? '',
                    'Id': this.caseId,
                    'Description': relatedCase.Description ?? '',
                    'Subject': relatedCase.Subject ?? '',
                }
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/agentHelper/query";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var result = JSON.parse(xmlHttp.response);
                        this.llmActive = result.llmActive;
                        
                        this.relatedCaseIds = result.hits.hits
                            .filter(x => x._source.Id !== this.caseId)
                            .map(x => x._source.Id);

                        this.isLoading = false;

                        this.articleTabActive = true;
                        this.relatedCaseTabActive = true;
                        this.expertsTabActive = true;
                        this.caseOverview = true;
                        if (this.llmActive) {
                            this.firstResponseTabActive = true;
                            this.summaryTabActive = true;
                        }
                        resolve();
                        this.queryLoading=false;
                    }
                    else {
                        this.queryError = true; this.queryLoading = false;
                        reject('HTTP Error: ' + xmlHttp.status);
                    }
                }else {
                    this.queryError = true; this.queryLoading = false;
                    reject('HTTP Error: ' + xmlHttp.status);
                }
            }

            xmlHttp.onerror = () => {
                reject('Network Error');
            };
            xmlHttp.send(data);
        })
    }

getRefineQuery(relatedCase) {
    return new Promise((resolve, reject) => {
        this.isLoading = true;
        let caseComments = [];

        fetchCaseSummaryData(this.caseId)
            .then(result => {
                if (result.success) {
                    const commentsData = JSON.parse(JSON.stringify(result.data));
                    if (commentsData.comments) {
                        caseComments = commentsData.comments.map(comment => ({
                            "type": "Comment",
                            "body": comment.body,
                            "author_id": comment.createdById,
                            "created_at": comment.createdDate,
                            "actorType": comment.actorType
                        }));
                    }
                } else {
                    console.error("Error getting data for case comments");
                    this.isLoading = false;
                    this.somethingWentWrong = true;
                    reject("Failed to fetch case comments");
                    return;
                }

                const data = JSON.stringify({
                    uid: this.uid,
                    case: {
                        Id: this.caseId,
                        description: relatedCase?.Description ?? '',
                        title: relatedCase?.Subject ?? '',
                        comments: caseComments,
                        refineQuery: true
                    }
                });

                const xmlHttp = new XMLHttpRequest();
                const url = `${this.endPoint}/mlService/case-sentiments`;

                xmlHttp.open("POST", url, true);
                xmlHttp.setRequestHeader("Accept", "application/json");
                xmlHttp.setRequestHeader("Authorization", `bearer ${this.token}`);
                xmlHttp.setRequestHeader("Content-Type", "application/json");
                xmlHttp.setRequestHeader("uid", this.uid);

                xmlHttp.onload = () => {
                    if (xmlHttp.readyState === 4) {
                        try {
                            const result = JSON.parse(xmlHttp.responseText);
                            if (xmlHttp.status === 200) {
                                this.refinedQuery = result["Search Query"];
                                resolve(this.refinedQuery);
                            } else {
                                console.error("Server returned an error:", result);
                                this.somethingWentWrong = true;
                                reject(result);
                            }
                        } catch (parseError) {
                            console.error("Error parsing response:", parseError);
                            this.somethingWentWrong = true;
                            reject(parseError);
                        }
                    }
                };

                xmlHttp.onerror = () => {
                    console.error("Network error during case-sentiments request");
                    this.somethingWentWrong = true;
                    reject(new Error("Network error"));
                };

                xmlHttp.send(data);
            })
            .catch(error => {
                console.error("Error in fetchCaseSummaryData:", error);
                this.isLoading = false;
                this.somethingWentWrong = true;
                reject(error);
            });
    }).finally(() => {
        this.isLoading = false;
    });
}


    allRelatedCasesBySearch(relatedCase) {
        return new Promise((resolve, reject) => {
            let data = JSON.stringify({
                "searchString": this.refinedQuery || '',
                "from": 0,
                "sortby": "_score",
                "orderBy": "desc",
                "resultsPerPage": 50,
                "uid": this.metaData.searchUidAH,
                "app": "agent-helper",
                "contextLimit": 2000,
                "resultsToConsider": 200,
                "aggregations": [
                    {
                        "type": "1_46_salesforce_sandbox_uat___case___Problem_Type__c",
                        "filter": [
                            relatedCase.problem
                        ]
                    },
                    {
                        "type": "_type",
                        "filter": [
                        "case"
                        ]
                    }
                ]
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var searchResponse = JSON.parse(xmlHttp.response);
                        console.log("searchResponse fetching ... ", JSON.stringify(searchResponse));

                        const ownerIdAgg = searchResponse.aggregationsArray.find(
                            agg => agg.label === "Owner ID"
                        );
                        
                        this.ownerId = ownerIdAgg && ownerIdAgg.values
                            ? ownerIdAgg.values.map(item => item)
                            : [];

                            console.log("ownerId ======> ", JSON.stringify(this.ownerId))

                        this.relatedCaseIds = searchResponse?.result?.hits
                            .filter(x => x?.Id !== this.caseId)
                            .map(x => x?.Id);

                        resolve();
                    }
                    else {
                        reject('HTTP Error: ' + xmlHttp.status);
                        this.caseSearchError = true;
                    }
                    this.queryLoading=false;
                }
            }

            xmlHttp.onerror = () => {
                reject('Network Error');
                this.queryLoading=false;
                this.caseSearchError = true;
            };
            xmlHttp.send(data);
        })
    }

    topArticlesBySearch(relatedCase) {

        return new Promise((resolve, reject) => {
            let data = JSON.stringify({
                "searchString": this.refinedQuery || '',
                "from": 0,
                "sortby": "_score",
                "orderBy": "desc",
                "resultsPerPage": 20,
                "uid": this.metaData.searchUidAH,
                "app": "agent-helper",
                "contextLimit": 2000,
                "resultsToConsider": 20,
                "aggregations": [
                    {
                        "type": "_type",
                        "filter": ["how_to__kav", "page", "issue" ] // how_to__kav -> salesforce, "page"-> confluence, "issue"-> jira
                    }
                ]
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/search/SUSearchResults";
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        var searchResponse = JSON.parse(xmlHttp.response);

                        var kbIds = searchResponse?.result?.hits
                        ?.filter(x => x?.Id?.startsWith("ka"))
                        .map(e => e?.Id);
                        console.log("kbIds ======> ", JSON.stringify(kbIds));

                        
                        //this.topArticlesIds = searchResponse?.result?.hits.map(x => x?.Id);

                        let jiraData = searchResponse?.result?.hits
                        ?.filter(x => x?.objName != 'how_to__kav');

                        console.log("jiraData ======> ", JSON.stringify(jiraData));


                        let allData = searchResponse?.result?.hits;
                        console.log("allData ======> ", JSON.stringify(allData));



                        this.topArticlesData = jiraData;
                        this.topArticlesIds = kbIds;

                        resolve();
                    }
                    else {
                        console.log("Top Article failed: ", xmlHttp.status)
                        this.articleSearchError = true;
                        reject('HTTP Error: ' + xmlHttp.status);
                    }
                    this.articlesLoading = false;
                }
            }
            xmlHttp.onerror = () => {
                reject('Network Error');
                this.articlesLoading = false;
                this.articleSearchError = true;
            };
            xmlHttp.send(data);
        })
    }

}