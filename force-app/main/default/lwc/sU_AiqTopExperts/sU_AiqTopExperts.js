import { LightningElement, api, track, wire } from 'lwc';
import CaseExpertDetail from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseExperts';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { registerListener } from 'c/supubsub';
import {trackEvent} from 'c/sU_AiqUtils';
import {fetchCaseSummaryData, fetchResponseAssistData} from 'c/sU_AiqDataRepository';
import { CurrentPageReference } from 'lightning/navigation';
import {fireEvent} from 'c/supubsub';
import {fetchUsersData} from 'c/sU_AiqDataRepository';
import getDataByObject from '@salesforce/apex/su_vf_console.AgentHelper.getDataByObject';


export default class SU_AiqTopExperts extends LightningElement {
    @wire(CurrentPageReference) objpageReference;
    token;
    @api caseIds;
    @api ownerId; 
    @api eventCode;
    @api recordId;
    @api uid;
    @api endPoint;
    @api maincontainerwidth;
    @api loggedInUserData;
    @api metaData;
    @api isDataError;
    @api token  
    @api s3endpoint



    relatedCasesExperts;//variable used to store Experts data and is used for iteration to display top experts that work on related cases
    @track showCasesExperts = true;//flag variable used to toggle display of data in top experts tab
    @track isExpertOneFlag = false;//flag variable used to toggle display of status modal popup 
    @track showListOfChannels = false; //flag variable used to toggle with listOFChannels
    createSlackChannel = false; //flag variable used to toggle with Create slack channel button
    slackChannelSelectedObjects = []; //variable for the class if channel is selected while creating slack channel
    topExpertsLoading = false; //variable for the loader in top experts
    topExpertsError = false;
    slackChannelsLoading = false;
    slackSelectedClassCss;
    relatedCasesExpertsBckup;
    expertClicked;
    viewExpertPopup = false;
    checkPopupInterval;
    @track firstLoad = true;
    @track slackAuthFailed = false;
    @track slackDisabled = false;
    @track userFilters = { accounts: [{ name: 'Active', selected: true }, { name: 'Inactive', selected: true }] };
    origin;
    requiredFields;
    relatedCasesExpertsData;
    tabName;
    @track slackOpenChannels; //sample array for the open channels

    @api
    set sectionName(value) {
        if (value === 'Top Experts') {
            this.setUserFilters();
            if (this.relatedCasesExperts && this.relatedCasesExperts.length < this.relatedCasesExpertsBckup.length) {
                this.relatedCasesExperts = this.relatedCasesExpertsBckup;
                this.showCasesExperts = this.relatedCasesExperts.length > 0;
            }
        }
        this.tabName = value;
    }
    get caseId() {
        return this.isUtility ? this.caseIdForUtility : this.recordId;
    }

    get sectionName() {
        return this.tabName;
    }

    get showExpertsList() {
        return !this.showListOfChannels;
    }

    get showSlackErrorScreen() {
        return (this.showListOfChannels && this.slackAuthFailed);
    }

    get showSlackDisabledScreen() {
        return (this.showListOfChannels && this.slackDisabled);
    }
    renderedCallback() {
        let e = this.template.querySelector('.expert-section');
        if (this.maincontainerwidth < 450) {
            e.className = 'expert-section su__agent-block-320';
        } else if (this.maincontainerwidth < 650) {
            e.className = 'expert-section su__agent-block-450';
        } else if (this.maincontainerwidth < 800) {
            e.className = 'expert-section su__agent-block-650';
        } else if (this.maincontainerwidth < 1300) {
            e.className = 'expert-section su__agent-block-800';
        } else if (this.maincontainerwidth > 1300) {
            e.className = 'expert-section su__agent-block-1300';
        }
    }

    //connectedCallback called on component loading to fetch experts working on case using case ids passed from parent component
//  connectedCallback() {

// if (this.ownerId && this.caseIds) {

// this.topExpertsLoading = true;
    
//     try {
//         this.topExpertsLoading = true;

//         if (!this.metaData.detailedSummaryData) {
//             this.fetchSummaryData();
//         } 

//         if (!this.metaData.responseAssistDataMarkdown) {
//             this.getResponseAssistData();
//         }

        
//         this.origin = window.location.origin;

//         if (!Array.isArray(this.ownerId)) {
//             throw new Error('ownerId is not an array');
//         }
// console.log("ownerId>>>>>", JSON.stringify(this.ownerId));
//         const fullData = this.ownerId; // original array of objects
//         const ownerIds = fullData.map(item => item.Contentname).filter(Boolean); // ensure IDs are valid
//         const closeCountsRaw = fullData.map(item => {
//             console.log("item>>>>", JSON.stringify(item))
//             return ({ id: item.Contentname, value: item.value })});

//         let userData = [];                // from fetchUsersData
//         let relatedCaseCloseCount = {};  // from original aggregation
//         let caseClosedCount = {};        // from getDataByObject
//         let responseDataVals = [];

//         closeCountsRaw.forEach(item => {
//             if (item.id) {
//                 relatedCaseCloseCount[item.id] = item.value || 0;
//             }
//         });

//         Promise.all([fetchUsersData(ownerIds)])
//                             .then((resultArray) => {
//                                 console.log('🔎 Result from fetchUsersData:', JSON.stringify(resultArray));

//                                 const userMap = resultArray[0]; // It's a single object with keys as user Ids
//                                 if (typeof userMap !== 'object' || userMap === null) {
//                                     throw new Error('User data is not a valid object');
//                                 }

//                 userData = Object.values(userMap); // Convert map to array

//                 const sObjectName = 'Case';
//                 const fieldsToFetch = ['Id'];

//                 const caseCountPromises = ownerIds.map(ownerId => {
//                     const whereClause = {
//                         "and": [
//                             {
//                                 "operator": "equals",
//                                 "key": "OwnerId",
//                                 "value": ownerId
//                             },
//                             {
//                                 "operator": "equals",
//                                 "key": "Status",
//                                 "value": "Closed"
//                             }
//                         ]
//                     };

//                     return getDataByObject({
//                         sObjectName,
//                         fieldsToFetch,
//                         whereClause: JSON.stringify(whereClause),
//                         orderBy: '',
//                         recordsLimit: null
//                     }).then(result => {
//                         try {
//                             const records = JSON.parse(result[sObjectName]) || [];
//                             console.log("ownerId>>>>", ownerId,"records>>>>>>>", records.length);
//                             if(ownerId == '0058Y00000C7ZjBQAV'){
//                                 console.log("recordsrecords>>", JSON.stringify(records))

//                             }
//                             caseClosedCount[ownerId] = records.length;

//                         } catch (e) {
//                             console.error(`Error parsing case result for ${ownerId}:`, e);
//                             caseClosedCount[ownerId] = 0;
//                         }
//                     }).catch(err => {
//                         console.error(`❌ Error fetching case count for ${ownerId}:`, err);
//                         caseClosedCount[ownerId] = 0;
//                     });
//                 });

//                 return Promise.all(caseCountPromises);
//             })
//             .then(() => {
//                 responseDataVals = userData.map(user => {
//                     const userId = user.Id;
//                     console.log("userId>>>", userId)
//                     return {
//                         OwnerName: user.Name,
//                         OwnerDepartment: user.Department,
//                         OwnerTitle: user.Title,
//                         Icon: user.FullPhotoUrl,
//                         isActive: user.IsActive,
//                         Email: user.Email,
//                         TotalClosedCasesCount: caseClosedCount[userId] || 0,
//                         RelatedClosedCaseCount: relatedCaseCloseCount[userId] || 0,
//                         previewUrl: `${this.origin}/${userId}`
//                     };
//                 });


//                 this.relatedCasesExperts = responseDataVals;
//                 this.topExpertsLoading = false;
//                 this.relatedCasesExpertsBckup = responseDataVals;
//                 this.showCasesExperts = responseDataVals.length > 0;

//                 //loop to format the data if values greater then 1000 and geting the first letter 
//                 this.relatedCasesExperts = this.relatedCasesExperts.map((item) => {
//                     const relatedCount = item.RelatedClosedCaseCount;
//                     const totalCount = item.TotalClosedCasesCount;

//                     let relatedThousands, totalThousands;

//                     if (relatedCount >= 1000) {
//                         relatedThousands = Math.floor(relatedCount / 1000) + "k";
//                     } else {
//                         relatedThousands = relatedCount;
//                     }

//                     if (totalCount >= 1000) {
//                         totalThousands = Math.floor(totalCount / 1000) + "k";
//                     } else {
//                         totalThousands = totalCount;
//                     }

//                     return {
//                         ...item,
//                         firstLetterName: String(item.OwnerName).substring(0, 1).toUpperCase(),
//                         closedCasesCountInThousands: relatedThousands,
//                         totalClosedCasesInThousands: totalThousands,
//                     };

//                 }).filter((item) => item.closedCasesCountInThousands !== 0 && item.isActive === true);
                
//                 if(responseDataVals.length <= 0) this.topExpertsError = true;

//                 if (!this.relatedCasesExperts.length) {
//                     this.topExpertsError = true
//                 } else {
//                     this.topExpertsError = false
//                 }

//                 console.log('✅ Final response data:', JSON.stringify(responseDataVals));
//             })
//             .catch(error => {
//                 try {
//                     const rawError = JSON.stringify(error, Object.getOwnPropertyNames(error));
//                     console.error('❌ Error during processing in Promise chain:', rawError);
//                 } catch (e) {
//                     console.error('❌ Unknown error, cannot stringify:', error);
//                 }
//             });
//     } catch (err) {
//         console.error('❌ Exception in outer try-catch:', err);
//         this.showCasesExperts = false;
//         return console.log(err);
//     }
// }else{
//         this.topExpertsError = true;
//         this.topExpertsLoading = false;
//         }



//         this.requiredFields = {
//             'Case': 'Subject , Account.name, Status, CreatedDate,ClosedDate',
//             'user': 'name, FullPhotoUrl, Department, Title, IsActive , Email'
//         };
    

//         this.setUserFilters();

//         let self = this;
//         window.addEventListener('message', function (event) {
//             if (self.endPoint.split('/back')[0] === event.origin) {
//                 self.token = event.data;
//                 localStorage.setItem('slackTokenLWC_' + self.uid, event.data);
//                 clearInterval(self.checkPopupInterval);
//                 self.getSlackChannels();
//             }
//         });
//         registerListener('getSlackChannels' + this.eventCode, this.getSlackChannels, this);

//     }


connectedCallback() {

    if (this.ownerId && this.caseIds) {
    
    this.topExpertsLoading = true;
        
        try {
        this.topExpertsLoading = true;

        if (!this.metaData.detailedSummaryData) {
            this.fetchSummaryData();
        }

        if (!this.metaData.responseAssistDataMarkdown) {
            this.getResponseAssistData();
        }

            
        this.origin = window.location.origin;

        if (!Array.isArray(this.ownerId)) {
            throw new Error('ownerId is not an array');
        }
        console.log("ownerId>>>>>", JSON.stringify(this.ownerId));
        const fullData = this.ownerId; // original array of objects
        const ownerIds = fullData.map(item => item.Contentname).filter(Boolean); // ensure IDs are valid
        const closeCountsRaw = fullData.map(item => {
            console.log("item>>>>", JSON.stringify(item))
            return { id: item.Contentname, value: item.value };
        });

        let userData = [];                // from fetchUsersData
        let relatedCaseCloseCount = {};   // from original aggregation
        let caseClosedCount = {};         // from getDataByObject
        let responseDataVals = [];

        // Process close counts
        closeCountsRaw.forEach(item => {
            if (item.id) {
                relatedCaseCloseCount[item.id] = item.value || 0;
            }
        });

        Promise.all([fetchUsersData(ownerIds)])
            .then(resultArray => {
                console.log('🔎 Result from fetchUsersData:', JSON.stringify(resultArray));
    
                const userMap = resultArray[0]; // It's a single object with keys as user Ids
                if (typeof userMap !== 'object' || userMap === null) {
                    throw new Error('User data is not a valid object');
                }

                userData = Object.values(userMap); // Convert map to array

                const sObjectName = 'Case';
                const fieldsToFetch = ['Id'];

                // Fetch case counts for each ownerId
                const caseCountPromises = ownerIds.map(ownerId => {
                    const whereClause = {
                        "and": [
                            {
                                "operator": "equals",
                                "key": "OwnerId",
                                "value": ownerId
                            },
                            {
                                "operator": "equals",
                                "key": "Status",
                                "value": "Closed"
                            }
                        ]
                    };

                    return getDataByObject({
                        sObjectName,
                        fieldsToFetch,
                        whereClause: JSON.stringify(whereClause),
                        orderBy: '',
                        recordsLimit: null
                    }).then(result => {
                        try {
                            const records = JSON.parse(result[sObjectName]) || [];
                            console.log("ownerId>>>>", ownerId, "records>>>>>>>", records.length);
                            caseClosedCount[ownerId] = records.length;
                        } catch (e) {
                            console.error(`Error parsing case result for ${ownerId}:`, e);
                            caseClosedCount[ownerId] = 0;
                        }
                    }).catch(err => {
                        console.error(`❌ Error fetching case count for ${ownerId}:`, err);
                        caseClosedCount[ownerId] = 0;
                    });
                });

                return Promise.all(caseCountPromises);
            })
            .then(() => {
                responseDataVals = userData.map(user => {
                    const userId = user.Id;
                    console.log("userId>>>", userId);
                    return {
                        OwnerName: user.Name,
                        OwnerDepartment: user.Department,
                        OwnerTitle: user.Title,
                        Icon: user.FullPhotoUrl || 'https://r041902s.searchunify.com/resources/Asset-Library/1e2b824f923c31731b047dd1a8b783f7/photo.png',
                        isActive: user.IsActive,
                        Email: user.Email,
                        TotalClosedCasesCount: caseClosedCount[userId] || 0,
                        RelatedClosedCaseCount: relatedCaseCloseCount[userId] || 0,
                        previewUrl: `${this.origin}/${userId}`
                    };
                });
    
                this.relatedCasesExperts = responseDataVals;
                this.topExpertsLoading = false;
                this.relatedCasesExpertsBckup = responseDataVals;
                this.showCasesExperts = responseDataVals.length > 0;

                // Loop to format the data if values greater than 1000 and getting the first letter
                this.relatedCasesExperts = this.relatedCasesExperts.map((item) => {
                    const relatedCount = item.RelatedClosedCaseCount;
                    const totalCount = item.TotalClosedCasesCount;
                
                    let relatedThousands, totalThousands;
                
                    if (relatedCount >= 1000) {
                        relatedThousands = Math.floor(relatedCount / 1000) + "k";
                    } else {
                        relatedThousands = relatedCount;
                    }
                
                    if (totalCount >= 1000) {
                        totalThousands = Math.floor(totalCount / 1000) + "k";
                    } else {
                        totalThousands = totalCount;
                    }
                
                    return {
                        ...item,
                        firstLetterName: String(item.OwnerName).substring(0, 1).toUpperCase(),
                        closedCasesCountInThousands: relatedThousands,
                        totalClosedCasesInThousands: totalThousands,
                    };
                }).filter((item) => {
                    const relatedCount = item.RelatedClosedCaseCount;
                    const totalCount = item.TotalClosedCasesCount;
                    const isValid = totalCount > 0 && (relatedCount <= totalCount * 2); 
                
                    return item.closedCasesCountInThousands !== 0 && item.isActive === true && isValid;
                });
                if(responseDataVals.length <= 0) this.topExpertsError = true;
                if (!this.relatedCasesExperts.length) {
                    this.topExpertsError = true;
                } else {
                    this.topExpertsError = false;
                }

                console.log('✅ Final response data:', JSON.stringify(responseDataVals));
            })
            .catch(error => {
                    try {
                        const rawError = JSON.stringify(error, Object.getOwnPropertyNames(error));
                        console.error('❌ Error during processing in Promise chain:', rawError);
                    } catch (e) {
                        console.error('❌ Unknown error, cannot stringify:', error);
                    }
                });
        } catch (err) {
            console.error('❌ Exception in outer try-catch:', err);
                this.showCasesExperts = false;
            return console.log(err);
        }
    }else{
        this.topExpertsError = true;
        this.topExpertsLoading = false;
    }
    
    

    this.requiredFields = {
        'Case': 'Subject , Account.name, Status, CreatedDate,ClosedDate',
        'user': 'name, FullPhotoUrl, Department, Title, IsActive , Email'
    };
        

    this.setUserFilters();

    let self = this;
    window.addEventListener('message', function (event) {
        if (self.endPoint.split('/back')[0] === event.origin) {
            self.token = event.data;
            localStorage.setItem('slackTokenLWC_' + self.uid, event.data);
            clearInterval(self.checkPopupInterval);
            self.getSlackChannels();
        }
    });
    registerListener('getSlackChannels' + this.eventCode, this.getSlackChannels, this);

        }


    fetchSummaryData(isRefreshed=false){
        fetchCaseSummaryData(this.recordId, 15)
        .then(result => {
            if(result.success){
                this.getSummaryResponse(result.data, isRefreshed);
            }else{
                console.error("Error Fetching data for case summary;", result);            }
        }).catch(error => {
            console.error("Error Fetching data for case summary;",error);
        });
    }

    getSummaryResponse(data, isRefreshed=false) {
        try{
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
                "type": "detailed_summary",
                "case_id": data.Id,
                "comments": caseComments,
                "isRefreshed": isRefreshed
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/mlService/case-summary";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.metaData.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.setRequestHeader('Origin', window.location.hostname);
            xmlHttp.setRequestHeader('uid', this.uid);

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    try{
                        if (xmlHttp.status === 200) {
                            let result = JSON.parse(xmlHttp.response);
                            if (result.status === 200) {
                                fireEvent(this.objpageReference, 'summaryData' + this.metaData.eventCode, this.summayDataDetailed);
                            } 
                        }
                    }
                    catch(err){
                        console.log("Error fetching the case summary Data:", JSON.stringify(err));
                    }
                }    
            }
            xmlHttp.send(sendData);
        } catch(err) {
            console.log('OUTPUT : ',err);
        }
    }

    getResponseAssistData() {
        console.log("recordId ===> ", JSON.stringify(this.recordId));

        fetchResponseAssistData(this.recordId)
            .then(result => {
                if (result.success) {
                    let responseAssistData = JSON.parse(JSON.stringify(result.data));
                    this.getResponseAssistDataMl(responseAssistData);
                } else {
                    console.log("error getting data for case timeline=");
                }
            })
            .catch(error => {
                console.log(error);
            })
    }

    getResponseAssistDataMl(data) {
        try{
            var payload = JSON.stringify({
                "uid": this.uid,
                "agent_name": this.loggedInUserData.name,
                "subject": data.subject ?? '',
                "description": data.description ?? '',
                "caseId": data.caseId ?? '',
                "activities": data.activities ?? [],
                'token': 'bearer ' + this.metaData.token,
                "case_owner": data.ownerName,
                "customer_name": data.customer_name,
                "isRefreshed": false,
                "user_id": this.loggedInUserData.Id,
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/mlService/first-response";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.metaData.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.setRequestHeader('Origin', window.location.hostname);
            xmlHttp.setRequestHeader('uid', this.uid);
            xmlHttp.setRequestHeader('timeout', 200000);

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        try{
                            let result = JSON.parse(xmlHttp.response);
                            if (result.status === 200) {
                                fireEvent(this.objpageReference, 'responseAssistData' + this.metaData.eventCode, {htmlData:result.output, markdownData: result.markdownData});
                            }
                        }catch(err){
                            console.log("Something went wrong in response assist data:", err);
                        }
                    } 
                }
            }

            xmlHttp.onerror = () => {
                console.error("Network error occurred.");
            };
            
            xmlHttp.send(payload);
        } catch (err) {
            console.error("Error in getResponseAssistMl:", err);
        }
    }

    setUserFilters() {
        this.userFilters = { accounts: [{ name: 'Active', selected: true }, { name: 'Inactive', selected: true }] };
    }

    //method to share the case in slack -> here
    shareToSlack(event) {
        event.currentTarget.blur();
        const index = event.currentTarget.dataset.index;
        const slackToShare = this.slackOpenChannels[index].value;
        this.slackOpenChannels[index].disabled = true;
        
        let caseNumberURL = `${window.location.origin}/${this.recordId}`;

        let preTextMessage = `👋 *Hello Experts!* 👋\nI hope you're doing well. I need your insights on a complex case before I send a response to the customer. Please find the case details below. Your feedback would be greatly appreciated to ensure accuracy and completeness.\n`;
        let textMessage = `*Case Number:* <${caseNumberURL}|${this.metaData.caseNumber}>
${this.metaData.detailedSummaryData ? `\n*Case Summary:* ${this.metaData.detailedSummaryData}` : `*Case Description:* ${this.metaData.description}`}          
${this.metaData.responseAssistDataMarkdown ? `\n*Preliminary Response:* \n"${this.metaData.responseAssistDataMarkdown}"\n\nPlease review this response and provide your suggestions? Should we adjust or add anything before sending it to the customer?\n\nThanks in advance for your valuable input!` : ''}`

        let data = {
            uid: this.uid,
            channelId: slackToShare,
            message: {
                'pretext': preTextMessage,
                'text': textMessage
            },
            token: localStorage.getItem('slackTokenLWC_' + this.uid)
        }
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/slackApis/postMessageOnSlack";
        xmlHttp.withCredentials = true;
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.message === 'Message posted') {
                        this.showNotification('Success!!!', 'Message has been Posted On Slack', 'success');
                        this.slackOpenChannels[index].disabled = false;
                    }
                    else this.showNotification('Error', 'Unable to share case details.', 'error');
                }

                trackEvent({
                    ...this.metaData,
                    feature_category: "Top Experts",
                    feature_name: "Share on slack",
                    interaction_type: 'click',   
                    feature_description: "Shared case details to slack channel.",
                    metric: {}
                }, this.loggedInUserData);
            }
        }
        xmlHttp.send(JSON.stringify(data));
    }

    //method called to register on slack if not done earlier and fetch all the slack channels into a variable
    getSlackChannels() {
        this.token = localStorage.getItem('slackTokenLWC_' + this.uid);
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/slackApis/getSlackChannels?uid=" + this.uid;
        if (this.token) url += '&token=' + encodeURIComponent(this.token);
        xmlHttp.withCredentials = true;
        xmlHttp.open("GET", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Content-Type', 'application/json');

        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.clientId && result.error === 'Not Authenticated') {
                        this.openWindowSlack(result.clientId);
                    } else if (result.ok && result.channels) {
                        this.slackChannelsLoading=false;
                        this.showSlackChannels = true;
                        this.slackOpenChannels = result.channels.map(x => {
                            x.name = '# ' + x.name;
                            return { label: x.name, value: x.id, disabled: false }
                        });
                        this.noSlackChannelsExist = result.channels && result.channels.length ? false : true;
                        if (!this.noSlackChannelsExist) {
                            this.selectedChannelValue = this.slackOpenChannels[0].value;
                        }
                        // this.showChannels(false);
                    } else if (result.error === 'Not Authenticated') {
                        console.log("error from slack channels api. >>>>>>>>>>>>>", result.error);
                        this.slackChannelsLoading = false;
                        this.slackAuthFailed = true;
                    } else if (result.error === 'Slack Disabled') {
                        console.log("Slack Disabled >> Share on slack is currently disabled");
                        this.slackChannelsLoading = false;
                        this.slackDisabled = true;
                    }
                }
            }
        }
        xmlHttp.send();
    }

    openWindowSlack(clientId) {
        var newWindow = window.open(`https://slack.com/oauth/authorize?client_id=${clientId}&scope=channels:read,groups:read,mpim:read,im:read,chat:write:user&redirect_uri=https://oauthsfdc.searchunify.com&state=${this.endPoint}/slackApis/slackAuthsu_csid${this.uid}url=${window.location.origin}`, 'name', 'height=400,width=400');
        this.checkPopupInterval = setInterval(() => {
            if (!newWindow || newWindow.closed) {
                clearInterval(this.checkPopupInterval);
                this.slackChannelsLoading = false;
                this.slackAuthFailed = true;
            }
        }, 500);
    }

    //method to toggle display of status modal popup 
    openExpertModalOne(event) {
        this.isExpertOneFlag = !this.isExpertOneFlag;
        let expertModal = this.template.querySelector('div[data-id="containerExpertModalOne"]');
        let backdrop = this.template.querySelector('div[data-id="backdrop"]');
        if (this.isExpertOneFlag) {
            expertModal.classList.remove('su__d-none');
            backdrop.classList.remove('su__d-none');
        } else {
            expertModal.classList.add('su__d-none');
            backdrop.classList.add('su__d-none');
        }
        let selectedValues = this.userFilters.accounts.filter(function (f) { return f.selected }).map(function (f) { return f.name });
        var chk = this.template.querySelectorAll('lightning-input[data-id="chkStatus"]') || [];
        chk.forEach(element => {
            let i = this.userFilters.accounts.find(f => f.name === element.label);
            element.checked = i.selected;
        });
        let allStatusChecked = this.template.querySelector('lightning-input[data-id="allStatusChecked"]') || {};
        allStatusChecked.checked = selectedValues.length === this.userFilters.accounts.length;
        event.currentTarget.blur();
    }
    //method called when the status checkbox (selects all statuses ) in modal popup is toggled
    handleAllStatusChange(event) {
        let allStatusChecked = this.template.querySelector('lightning-input[data-id="allStatusChecked"]');
        this.userFilters.accounts.forEach((f) => (f.selected = allStatusChecked.checked));
        if (allStatusChecked.checked)
            this.relatedCasesExperts = this.relatedCasesExpertsBckup;
        else this.relatedCasesExperts = [];
        var chk = this.template.querySelectorAll('lightning-input[data-id="chkStatus"]');
        chk.forEach(element => {
            element.checked = allStatusChecked.checked;
        });
        this.showCasesExperts = this.relatedCasesExperts.length > 0;
        event.currentTarget.blur();
    }

    // getSlackChannels(event) {
    //     fireEvent(null, 'getSlackChannels' + this.eventCode, null);
    //     event.currentTarget.blur();
    // }

    expertsDivClicked(event) {
        if (event.currentTarget.dataset.index > -1)
            this.expertClicked = this.relatedCasesExperts[event.currentTarget.dataset.index];
        this.viewExpertPopup = true;
    }

    emailCopyToClipboard() {
        let expert_email = this.expertClicked.Email;
        let tag = document.createElement('textarea');
        tag.setAttribute('id', 'input_test_id');
        tag.value = expert_email;
        this.template.appendChild(tag);
        tag.select();
        document.execCommand('copy');
        this.template.removeChild(tag);

        var linkId = this.template.querySelector('[data-id="toastId"]');
        this.template.querySelector('[data-id="toastId"]').classList.remove('showFormBlock');
        setTimeout(function () { linkId.classList.add('showFormBlock'); }, 1000);
    }

    expertsPopupClosed() {
        this.viewExpertPopup = false;
    }

    //method called when individual status value is toggled in status modal popup .Filters data being displayed in Top Experts Tab
    applyUserFilters(event) {
        var chk = this.template.querySelectorAll('lightning-input[data-id="chkStatus"]');
        chk.forEach(element => {
            let i = this.userFilters.accounts.find(f => f.name === element.label);
            i.selected = element.checked;
        });
        let selectedValues = this.userFilters.accounts.filter(function (f) { return f.selected }).map(function (f) { return f.name });
        if (!selectedValues.length)
            this.relatedCasesExperts = [];
        else {
            this.relatedCasesExperts = this.relatedCasesExpertsBckup.filter(function (u) {
                return (selectedValues.indexOf(u.isActive === 'false' || !u.isActive ? 'Inactive' : 'Active') > -1);
            })
        }

        let allStatusChecked = this.template.querySelector('lightning-input[data-id="allStatusChecked"]')
        allStatusChecked.checked = selectedValues.length === this.userFilters.accounts.length;
        this.showCasesExperts = this.relatedCasesExperts.length > 0;
        event.currentTarget.blur();
    }

    //sort button menu handler
    sortByButtonHandler() {
        const sortMenuHolder = this.template.querySelector('.sort-menu-holder-topExperts');
        sortMenuHolder.style.display = (sortMenuHolder.style.display === 'block') ? 'none' : 'block';
    }

    //function to handle the open list channel button handler
    openChannelListButtonHandler() {
        this.showListOfChannels = !this.showListOfChannels;
        if(this.showListOfChannels){
            this.slackDisabled = false;
            this.slackAuthFailed = false;
            this.slackChannelsLoading = true;
            this.getSlackChannels();
        }
        
        trackEvent({
            ...this.metaData,
            feature_category: "Top Experts",
            feature_name: "Slack Channels",
            interaction_type: 'click',   
            feature_description: "Open slack channels",
            metric: {}
        }, this.loggedInUserData);
    }

    retrySlackAuth(){
        this.slackAuthFailed = false;
        this.slackChannelsLoading = true;
        this.getSlackChannels();
    }

    updatingIndex(channel) {
        //func to update the index of the selected, when any deleted
        const indexOf = this.slackChannelSelectedObjects.findIndex((item) => item.channel === channel);
        const spanCount = this.template.querySelector(`span[data-index="${channel}"]`);
        spanCount.textContent = indexOf + 1;
    }

    //handler to create a list for the creating slack channel
    creatingSlackChannel(event) {
        const channel = event.currentTarget.dataset.index;
        const channelExists = this.slackChannelSelectedObjects.some(obj => obj.channel === channel);
        if (!channelExists) {
            const newSlackList = [...this.slackChannelSelectedObjects, { channel: channel }];
            this.slackChannelSelectedObjects = newSlackList;

            const indexOf = newSlackList.findIndex((item) => item.channel === channel);
            //now updating the css class to give the border that it is selected
            const element = this.template.querySelector(`div[data-index="${channel}"]`);
            element.classList.add('selected-slack-channel');
            //to show the count of selection
            const spanCount = this.template.querySelector(`span[data-index="${channel}"]`);
            spanCount.style.display = (spanCount.style.display === 'block') ? 'none' : 'block';
            spanCount.textContent = indexOf + 1;
        }
        else {
            //if already exist then delete it
            let newSlackList = [...this.slackChannelSelectedObjects];
            newSlackList = newSlackList.filter((item) => item.channel !== channel);
            this.slackChannelSelectedObjects = [...newSlackList];

            //updating the index of the selected on the frontend
            this.slackChannelSelectedObjects.forEach((item) => this.updatingIndex(item.channel));
            const element = this.template.querySelector(`div[data-index="${channel}"]`);
            const spanCount = this.template.querySelector(`span[data-index="${channel}"]`);
            element.classList.remove('selected-slack-channel');
            spanCount.style.display = (spanCount.style.display === 'none') ? 'block' : 'none';
        }
    }

    //function to execute the copy to clipboard
    copyToClipboard2(event) {
        const email = event.currentTarget.dataset.index;
        const textArea = document.createElement('textarea');
        textArea.value = email;
        textArea.style.opacity = 0;
        document.body.appendChild(textArea);
        textArea.focus({ preventScroll: true });
        textArea.select();
         try {
            document.execCommand('copy');
        } catch (err) {
            console.error('Unable to copy', err);
        }
        // const success = document.execCommand('copy');
        document.body.removeChild(textArea);
    }


    //method that displays toast message (error or success message) based on whether slack channel has been registered or not
    showNotification(notificationTitle, notificationMessage, notificationVariant) {
        const evt = new ShowToastEvent({
            title: notificationTitle,
            message: notificationMessage,
            variant: notificationVariant,
        });
        this.dispatchEvent(evt);
    }
    
    agentPreview(){
        trackEvent({
            ...this.metaData,
            feature_category: "Top Experts",
            feature_name: "Agent Detail Preview",
            interaction_type: 'click',   
            feature_description: "Clicked on Agent Detail Preview",
            metric: {}
        }, this.loggedInUserData);
    }

}