/* eslint-disable @lwc/lwc/no-inner-html */
import { LightningElement, track, api, wire} from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import USER_ID from '@salesforce/user/Id';
import NAME_FIELD from '@salesforce/schema/User.Name';
import {fetchResponseAssistData} from 'c/sU_AiqDataRepository';
import {convertToTimezone, trackEvent} from 'c/sU_AiqUtils';
import { CurrentPageReference } from 'lightning/navigation';
import {fireEvent} from 'c/supubsub';

export default class SU_AiqResponseAssist extends LightningElement {
    @wire(CurrentPageReference) objpageReference;

    currentUserInfo;
    @api recordId;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    @api loggedInUserData;
    @api metaData;
    @track activeTab = 'responseAssist';
    @track firstResponseData;
    @track citation;
    @track isLoading = false;
    @track somethingWentWrong = false;
    @track failedTones = false; //var for the error in get_tones
    @track tonesLoader = false; //var for the laoder in get_tones
    @track loggedInUsername;
    @track editedData;
    @track isEditMode = false;
    @track errorSaving = false;
    @track savingEditedResponse = false;
    @track savedSuccess;
    @track selectedProfileIndex = 0;
    @track lastUpdatedDate;
    @track selectedProfileTuning; //selected tone 
    @track toneProfiles = [];
    @track customToneIndex =  0;
    @track makingNewTone = false;
    @track newToneError = false;
    @track copyForRichTextEditor = false;
    @track copiedmarkdownData = '';
    @track charLimitExceeded = false;
    @track charCountRA = 0;
    @track showLeftButton = false;
    @track showRightButton = false;
    firstLoad = true;
    generatedContent;
    customToneName = "";
    responseAssistCharLimit = 5000;    readMoreLink = "https://docs.searchunify.com/Content/Apps/Agent-Helper-Overview.htm";


    connectedCallback() {
        this.fetchData(false);
    }

    get isDisabled(){
        return !this.selectedProfileTuning.is_custom;
    }

    get disableRegenerate(){
        return this.isLoading || this.isEditMode || this.metaData.isClosed;
    }
    
    get disableCopy(){
        return this.isLoading || this.isEditMode || this.metaData.isClosed || this.somethingWentWrong;
    }

    get disbaleEdit(){
        return this.isLoading || this.somethingWentWrong || this.metaData.isClosed;
    }

    get getToneProfileInitial() {
        const name = this.updatedProfiles[this.customToneIndex].name;
        return name.substring(0,1).toUpperCase();
    }

    avoidClick(event){
        event.stopPropagation();
    }
    addSampleAddNew(profilesData){
        //here we check if profiles data contain any object with is_custom = true if yes then do nothing other wise add a sample object 
        let flag = false;
        profilesData.map((item,index) => {
            if(item.is_custom){
                flag = true;
                this.customToneIndex = index;
                this.customToneName = item.name;
            }
            return item;
        });

        if(!flag){
            profilesData.push({
                "tone_id": false,
                "user_id": "sample_user_id",
                "name": "Add New",
                "image_path": false,
                "description": false,
                "is_custom": 1,
                "brand_new" : true,  
                "props": [
                    {
                        lowerName: "Casual",
                        upperName: "Formal",
                        value: 0
                    },
                    {
                        lowerName: "Brief",
                        upperName: "Detailed",
                        value: 0
                    },
                    {
                        lowerName: "Natural",
                        upperName: "Confident",
                        value: 0
                    },
                    {
                        lowerName: "Polite",
                        upperName: "Assertive",
                        value: 0
                    },
                    {
                        lowerName: "Emotional",
                        upperName: "Rational",
                        value: 0
                    },
                    {
                        lowerName: "Direct",
                        upperName: "Indirect",
                        value: 0
                    }
                ]
            })

            this.updatedProfiles = profilesData;
            console.log(this.updatedProfiles);
            this.customToneIndex = this.updatedProfiles.length -1;
        }
        
    }

    allowedFormats = [
        'font',
        'size',
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'indent',
        'align',
        'link',
        'image',
        'clean',
        'table',
        'header',
        'color',
        'background',
    ];

    get caseId() {
        return this.isUtility ? this.caseIdForUtility : this.recordId;
    }

    handleTabClick(event) {
        this.activeTab = event.target.dataset.city;
    }

    handleSliderChange(event) {
        let sliderValue = parseInt(event.target.value,10);
        let className = this.selectedProfileTuning.props[event.target.dataset.featureindex].lowerName;
        this.selectedProfileTuning.props[event.target.dataset.featureindex].value = sliderValue;
        const sliderValueInHundred = sliderValue * 100;
        this.template.querySelector(`.${className}`).style.background = `linear-gradient(to right, #FFC100 ${sliderValueInHundred}%, #ccc ${sliderValueInHundred}%)`;
        
    }

    resetProfile(){
        this.selectedProfileTuning = JSON.parse(JSON.stringify(this.toneProfiles[this.selectedProfileIndex]));
        this.applyStylingToSliders();
    }

    // func to validate the name of new tone added by user
    validatingNewTone(){
        const name = this.selectedProfileTuning.name;
        if(name.trim() === ""){
            this.newToneError = true;
            this.applyErrorStyle(true);
        } else{
            this.newToneError = false;
            this.applyErrorStyle(false);
        }
    }

    applyErrorStyle(flag){
        const inputField = this.template.querySelector(".sunewToneNameInput");
        !inputField && console.log("error getting sunewToneNameInput");
        if(flag) inputField.style.borderColor = "red";
        else inputField.style.borderColor = "black";
    }

    saveProfile(){
        this.validatingNewTone();
        if(this.newToneError){
            console.log("error in adding new tone");
            return;
        }
        // const tunning = JSON.parse(JSON.stringify(this.selectedProfileTuning));
        // console.log("selectedProfileTunning", tunning);
        this.updatedProfiles[this.selectedProfileIndex] = JSON.parse(JSON.stringify(this.selectedProfileTuning));
        
        const payload = {
            tone_id: this.selectedProfileTuning.tone_id,
            user_id: USER_ID,
            uid: this.uid,
            name: this.selectedProfileTuning.name,
            image_path:this.selectedProfileTuning.image_path,
            is_custom:this.selectedProfileTuning.is_custom,
            props:JSON.parse(JSON.stringify(this.selectedProfileTuning.props)),
        }

        this.postingNewTone(payload);
        this.isToneModal = false;
        this.template.querySelector(`.response-container`).style.position = `relative`;
        this.fetchData(true);

        trackEvent({
                ...this.metaData,
                feature_category: "Response Assist",
                feature_name: "Tone save",
                interaction_type: 'click',   
                feature_description: "Tone for response assist saved", 
                metric: {name: payload.name, is_custom: payload.is_custom}
            }, this.loggedInUserData);
    }

    postingNewTone(data){
        var payload = JSON.stringify(data);
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/mlService/user-tone";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.setRequestHeader('Origin', window.location.hostname);
        xmlHttp.setRequestHeader('uid', this.uid);
        xmlHttp.setRequestHeader('timeout', 200000);

        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                try{
                    if (xmlHttp.status === 200) {
                    let result = JSON.parse(xmlHttp.response);
                    if (result.status === 200) {
                        console.log(result);
                    } else if (result.status === 403) {
                        console.log("failed");
                    }
                    else {
                        console.log("failed");
                    }
                } else {
                    console.log("failed");
                }                
            }catch(err){
                    console.log("Error saving new tone", err);
                }
            } else {
                console.log("failed");
            }
        }
        xmlHttp.send(payload);

    }


    handleTabClick1(event) {
        const inputClick = event.currentTarget.dataset.index;
        if(inputClick){
            this.updatedProfiles[this.selectedProfileIndex].cssClass = 'tablinks'; 
            this.updatedProfiles[this.selectedProfileIndex].isActive = false;

            this.updatedProfiles[parseInt(inputClick, 10)].cssClass = 'tablinks active'
            this.updatedProfiles[parseInt(inputClick, 10)].isActive = true;

            this.selectedProfileIndex = parseInt(inputClick, 10);
            this.selectedProfileTuning = this.updatedProfiles[parseInt(inputClick,10)];
            setTimeout(()=>{
                this.selectedProfileTuning.props.forEach((feat)=>{
                    const valueInHundred = feat.value * 100;
                    if(this.selectedProfileTuning.is_custom)
                        this.template.querySelector(`.${feat.lowerName}`).style.background = `linear-gradient(to right, #FFC100 ${valueInHundred}%, #ccc ${valueInHundred}%)`;
                    else 
                        this.template.querySelector(`.${feat.lowerName}`).style.background = `linear-gradient(to right, rgb(232 190 56 / 78%) ${valueInHundred}%, rgb(204, 204, 204) ${valueInHundred}%)`;
                });
            },10);

            if(inputClick === this.customToneIndex){ //add new tone selected 
                this.makingNewTone = true;
                if(this.updatedProfiles[parseInt(inputClick, 10)].name === "Add New") 
                    this.updatedProfiles[parseInt(inputClick, 10)].name = "";
                setTimeout(() => {
                const inputToGetName = this.template.querySelector(".sunewToneNameInput");
                if (inputToGetName) {
                    inputToGetName.focus();
                } else {
                        console.log("didn't get the element");
                    }
                }, 0);
            }
            else{
                this.makingNewTone = false;
                if(this.updatedProfiles[this.customToneIndex].name.trim() === ""){
                    if(this.customToneName)
                        this.updatedProfiles[this.customToneIndex].name = this.customToneName;
                    else {
                            this.updatedProfiles[this.customToneIndex].brand_new = true;
                            this.updatedProfiles[this.customToneIndex].name = "Add New";
                        }
                }
            }
        }
    }

    nameInputKeyDownHandler(event){
        if(event.keyCode === 32){
            event.preventDefault();
        }
    }

    nameInputHandler(event){
        let inputValue = event.target.value;
        if (/^[a-zA-Z0-9]*$/.test(inputValue)) {
            this.newToneError = false;
            this.applyErrorStyle(false);
        } else {
            console.log("invalid input");
            inputValue = inputValue.replace(/[^a-zA-Z0-9]/g, '');
            event.target.value = inputValue;
        }
        this.updatedProfiles[this.customToneIndex].name = inputValue;
    }


    @track isToneModal = false;
    toggleToneModal() {
        if(!this.isToneModal && !this.metaData.isClosed){
            this.tonesLoader = true;
            this.isToneModal = true;
            this.getToneData();
            this.template.querySelector(`.response-container`).style.position = `static`;

            trackEvent({
                ...this.metaData,
                feature_category: "Response Assist",
                feature_name: "Tone open",
                interaction_type: 'click',   
                feature_description: "Tonality model opened", 
                metric: {}
            }, this.loggedInUserData);
        }else{
            this.isToneModal = false;
            this.template.querySelector(`.response-container`).style.position = `relative`;
        }
    }

    applyStylingToSliders(){
        setTimeout(()=>{
            this.selectedProfileTuning.props.forEach((feat)=>{
                const valueInHundred = feat.value * 100;
                if(this.selectedProfileTuning.is_custom)
                    this.template.querySelector(`.${feat.lowerName}`).style.background = `linear-gradient(to right, #FFC100 ${valueInHundred}%, #ccc ${valueInHundred}%)`;
                else 
                    this.template.querySelector(`.${feat.lowerName}`).style.background = `linear-gradient(to right, rgb(232 190 56 / 78%) ${valueInHundred}%, rgb(204, 204, 204) ${valueInHundred}%)`;
            });
        },10);
    }


    //<------- Functionality related to Editor Starts--------->
    toggleEditor() {
        this.charCountRA = this.firstResponseData.length;
        this.editedData = this.firstResponseData;
        if (!this.isEditMode && !this.metaData.isClosed) {
            this.isEditMode = true;
            const editButton = this.template.querySelector('.edit-button');
            editButton.classList.add('active');
            trackEvent({
                ...this.metaData,
                feature_category: "Response Assist",
                feature_name: "Edit open",
                interaction_type: 'click',   
                feature_description: "Edit mode turned on", 
                metric: {}
            }, this.loggedInUserData);
        }
    }
    cancelEditor() {
        this.isEditMode = false;
        const editButton = this.template.querySelector('.edit-button');
        editButton.classList.remove('active');
    }


    //getting signed in user name
    @wire(getRecord, { recordId: USER_ID, fields: [NAME_FIELD] })
    wireuser({ error, data }) {
        if (error) {
            console.log(" EROR getting logged in user detils=========", error);
            this.error = error;
        } else if (data) {
            this.loggedInUsername = data?.fields?.Name?.value;
        }
    }
    

    renderedCallback() {
    }

    fetchData(isrefresh, regenerateClick = false) {
        if(this.metaData.isClosed){
            this.firstResponseData = 'Hello! It looks like this case has been resolved and is currently closed. No further actions are required on this case.';
            this.refreshAvailable = false;
            this.lastUpdatedDate = null;
            this.isLoading = false;
            return
        }
        this.isLoading = true;
        this.somethingWentWrong = false;
        fetchResponseAssistData(this.recordId)
            .then(result => {
                if (result.success) {
                    let responseAssistData = JSON.parse(JSON.stringify(result.data));
                    this.getResponseAssistMl(responseAssistData, isrefresh, regenerateClick);
                } else {
                    console.log("error getting data for case timeline=");
                    this.isLoading = false;
                    this.somethingWentWrong = true;
                }
            })
            .catch(error => {
                console.log(error);
                this.isLoading = false;
                this.somethingWentWrong = true;
            })
    }

    refreshFirstResponse() {
        if(!this.isLoading && !this.metaData.isClosed){
            this.isEditMode = false;
            this.savingEditedResponse = false; 
            this.fetchData(true, true);
        }
    }

    tonesInitator(responseData){
        console.log("response data>>>>",responseData);
        this.updatedProfiles = responseData.data.data;
        this.updatedProfiles = this.updatedProfiles.map((item)=>{
            return {
                ...item,
                image_path: `${this.s3endpoint}/Assets/${item.image_path}`,
            }
        })
        this.updatedProfiles = this.updatedProfiles.map((item)=>{
            return {
                ...item,
                props:JSON.parse(item.props),
            }
        });

        this.addSampleAddNew(this.updatedProfiles);
        let index = -1
        if (responseData.data.selected_tone_id) {
            index = this.updatedProfiles.findIndex(item=>item.tone_id === parseInt(responseData.data.selected_tone_id, 10));
        }
        if(responseData.data.is_custom) {
            if(this.updatedProfiles.length === 6){
                index = 5;
            } else {
                index = 0;
            }
        }

        this.selectedProfileIndex = (index === -1) ? 0 : index;

        this.selectedProfileTuning = this.updatedProfiles[this.selectedProfileIndex];

        this.updatedProfiles[this.selectedProfileIndex].cssClass = 'tablinks active'; 
        this.updatedProfiles[this.selectedProfileIndex].isActive = true;

        this.applyStylingToSliders();
    }

    getToneData(){
        var payload = JSON.stringify({
            "user_id":USER_ID,
        });

        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/mlService/get-tones";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.setRequestHeader('Origin', window.location.hostname);
        xmlHttp.setRequestHeader('uid', this.uid);
        xmlHttp.setRequestHeader('timeout', 200000);

        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    let result = JSON.parse(xmlHttp.response);
                    if (result.status === 200) {
                        this.tonesInitator(result);
                        this.failedTones = false;
                        this.tonesLoader = false;
                    } else if (result.status === 403) {
                        this.failedTones = true;
                        this.tonesLoader = false;
                    }
                    else {
                        this.failedTones = true;
                        this.tonesLoader = false;
                    }
                } else {
                    this.failedTones = true;
                    this.tonesLoader = false;
                }
            } else {
                this.failedTones = true;
                this.tonesLoader = false;
            }
        }
        xmlHttp.send(payload);
    }

    getResponseAssistMl(data, isrefresh, regenerateClick = false) {
        this.feedbackResetChildMethod();
        try{
            var payload = JSON.stringify({
                "uid": this.uid,
                "agent_name": this.loggedInUsername,
                "subject": data.subject ?? '',
                "description": data.description ?? '',
                "caseId": data.caseId ?? '',
                "activities": data.activities ?? [],
                'token': 'bearer ' + this.token,
                "case_owner": data.ownerName,
                "customer_name": data.customer_name,
                "isRefreshed": isrefresh,
                "user_id":USER_ID,
                "search_uid": this.metaData.searchUidRA,
                "jiraIds": (data.jiraIds && data.jiraIds !== '' ) ? data.jiraIds.split(',') : []
            });

            var xmlHttp = new XMLHttpRequest();
            var url = this.endPoint + "/mlService/first-response";
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.setRequestHeader('Origin', window.location.hostname);
            xmlHttp.setRequestHeader('uid', this.uid);
            xmlHttp.setRequestHeader('timeout', 200000);
            const startTime = performance.now();

            xmlHttp.onload = () => {
                if (xmlHttp.readyState === 4) {
                    if (xmlHttp.status === 200) {
                        try{
                                console.log("Fetching Response ===> ");
                            let result = JSON.parse(xmlHttp.response);
                            if (result.status === 200) {
                                this.firstResponseData = result.output;
                                this.citation = result.citation;
                                this.copiedmarkdownData = result.markdownData;

                                // console.log("firstResponseData ===> ", JSON.stringify(this.firstResponseData));

                                //let urls = [...result.output.matchAll(/<a [^>]*>(.*?)<\/a>/g)].map(match => match[1]);


                                //this.firstResponseData = this.firstResponseData.replace(/<p>For further information, you can refer to the following resources:<br><a href=".*?"\s*target="_blank">.*?<\/a>/, '');


                                //console.log("result.markdownData ===> ", result?.markdownData);
                                //console.log("Final firstResponseData ===> ", JSON.stringify(this.firstResponseData));

                                fireEvent(this.objpageReference, 'responseAssistData' + this.metaData.eventCode, {htmlData:this.firstResponseData, markdownData: result.markdownData});

                                this.refreshAvailable = result.updated;
                                const [date, time] = convertToTimezone(result.updatedAt, this.loggedInUserData.TimeZoneSidKey).split("T");
                                this.lastUpdatedDate = `${date} | ${time.split(".")[0]}`;

                                this.isLoading = false;
                                this.generatedContent = JSON.stringify(this.firstResponseData);
                                if(regenerateClick){
                                    trackEvent({
                                        ...this.metaData,
                                        feature_category: "Response Assist",
                                        feature_name: "Regenerate Response",
                                        interaction_type: 'click',   
                                        feature_description: "No. of times the response was Regenerated", 
                                        metric: {},
                                        generated_response: this.firstResponseData
                                    }, this.loggedInUserData);
                                }
                                if(this.firstLoad){
                                    this.firstLoad = false;
                                    trackEvent({
                                        ...this.metaData,
                                        feature_category: "Response Assist",
                                        feature_name: "Initial load",
                                        interaction_type: 'page view',   
                                        feature_description: "Response generated on first load of response-assist.", 
                                        metric: {},
                                        generated_response: this.firstResponseData
                                    }, this.loggedInUserData);
                                }
                            } else if (result.status === 403) {
                                console.log("You do not have the required permissions.")
                                this.isLoading = false;
                                this.somethingWentWrong = true;
                            }else {
                                console.log("Unable to generate a response.");
                                this.isLoading = false;
                                this.somethingWentWrong = true;
                            }
                        }catch(err){
                            console.log("Something went wrong in response assist data:", err);
                            this.somethingWentWrong = true;
                            this.isLoading = false;
                        }
                    } else {
                        this.firstResponseData = "Unable to generate Response.";
                        this.isLoading = false;
                        this.somethingWentWrong = true;
                    }

                    trackEvent({
                        ...this.metaData,
                        feature_category: "Response Assist",
                        feature_name: "Time to Response",
                        interaction_type: 'response_time',   
                        feature_description: "Time taken to generate response", 
                        metric: {
                            response_time: performance.now() - startTime,
                            api_status: xmlHttp.status,
                            is_regenerated: isrefresh
                            }
                    }, this.loggedInUserData);
                } else {
                    this.firstResponseData = "Unable to generate Response."
                    this.isLoading = false;
                    this.somethingWentWrong = true;
                }
            };

            xmlHttp.onerror = () => {
                console.error("Network error occurred.");
                this.isLoading = false;
                this.somethingWentWrong = true;
            };
            
            xmlHttp.send(payload);
        } catch (err) {
            console.error("Error in getResponseAssistMl:", err);
            this.somethingWentWrong = true;
            this.isLoading = false;
        }
    }
   get hasCitations() {
    return (
        this.citation &&
        Array.isArray(this.citation) &&
        this.citation.length > 0
    );
    }
    get responseClass() {
   return this.hasCitations === true ? 'response-data has-citation' : 'response-data';
   }

  renderedCallback() {
        this.updateScrollButtons();
    }

    handleScroll = () => {
        this.updateScrollButtons();
    };

    updateScrollButtons() {
        const container = this.template.querySelector('[data-container]');
        if (!container) return;

        const scrollLeft = container.scrollLeft;
        const maxScrollLeft = container.scrollWidth - container.clientWidth;

        this.showLeftButton = scrollLeft > 0;
        this.showRightButton = scrollLeft < maxScrollLeft;
    }

    handleScrollLeft = () => {
        const container = this.template.querySelector('[data-container]');
        container.scrollBy({ left: -150, behavior: 'smooth' });
        // Delay update to allow smooth scroll to finish
        setTimeout(() => this.updateScrollButtons(), 300);
    };

    handleScrollRight = () => {
        const container = this.template.querySelector('[data-container]');
        container.scrollBy({ left: 150, behavior: 'smooth' });
        setTimeout(() => this.updateScrollButtons(), 300);
    };


    handleRichTextChange(event) {
        const inputValue = event.target.value;
        this.editedData = inputValue;
        this.charCountRA = this.editedData.length;
        const editTextArea = this.template.querySelector('.response-editor');
        if (inputValue.length <= this.responseAssistCharLimit) {
            if (editTextArea.classList.contains('limit-exceeded')) {
                editTextArea.classList.remove('limit-exceeded');
            }
            this.charLimitExceeded = false; 
        } else {
            if (!editTextArea.classList.contains('limit-exceeded')) {
                editTextArea.classList.add('limit-exceeded');
            }
            this.charLimitExceeded = true;
        }
    }

    saveEditedData() {
        if (this.editedData.length > this.responseAssistCharLimit) {
            return; 
        }
        if(this.editedData){
            this.savingEditedResponse = true;
            this.saveEdit(this.editedData)
                .then(() => {
                    this.savingEditedResponse = false;
                    this.firstResponseData = this.editedData;
                    this.generatedContent = JSON.stringify(this.firstResponseData);
                    this.isEditMode = false;
                    this.savedSuccess = true;
                    setTimeout(() => {
                        const editButton = this.template.querySelector('.edit-button');
                        editButton.classList.remove('active');
                        this.savedSuccess = false;
                    }, 2000);
                    trackEvent({
                        ...this.metaData,
                        feature_category: "Response Assist",
                        feature_name: "Edit save",
                        interaction_type: 'click',   
                        feature_description: "Saved the edited response assist data.", 
                        metric: {},
                        generated_response: this.firstResponseData
                    }, this.loggedInUserData);
                })
                .catch(() => {
                    this.savingEditedResponse = false;
                    this.errorSaving = true;
                    this.somethingWentWrong = true;
                })
        }
        else{
            this.isEditMode = false;
            this.savedSuccess = true; 
            setTimeout(() => {
                        const editButton = this.template.querySelector('.edit-button');
                        editButton.classList.remove('active');
                        this.savedSuccess = false;
            }, 2000);
        }
    }

    saveEdit(dataToSave) {
        this.feedbackResetChildMethod();
        return new Promise((resolve, reject) => {
            try{
                var payload = JSON.stringify({
                    "uid": this.uid,
                    "agent_name": this.loggedInUsername,
                    "updated_response": dataToSave,
                    "caseId": this.recordId ,
                    "llm": true,
                    "custom_model_name": "openai",
                    'token': 'bearer ' + this.token,
                    "user_id":USER_ID
                });
                var xmlHttp = new XMLHttpRequest();
                var url = this.endPoint + "/mlService/update-first-response";
                xmlHttp.open("POST", url, true);
                xmlHttp.setRequestHeader("Accept", "application/json");
                xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
                xmlHttp.setRequestHeader('Content-Type', 'application/json');
                xmlHttp.setRequestHeader('Origin', window.location.hostname);
                xmlHttp.setRequestHeader('uid', this.uid);
                xmlHttp.setRequestHeader('timeout', 20000);

                xmlHttp.onload = () => {
                    try{
                        console.log("going here?")
                        if (xmlHttp.readyState === 4) {
                            if (xmlHttp.status === 200) {
                                let result = JSON.parse(xmlHttp.response);
                                if (result.status === 200) {
                                    const [date, time] = convertToTimezone(result.updatedAt, this.loggedInUserData.TimeZoneSidKey).split("T");
                                    this.lastUpdatedDate = `${date} | ${time.split(".")[0]}`;
                                    fireEvent(this.objpageReference, 'responseAssistData' + this.metaData.eventCode, {htmlData:dataToSave, markdownData: result.markdownData});
                                    resolve(true);
                                } 
                                else {
                                    reject("Something Went Wrong")
                                }    
                            } else {
                                reject("Network Error");
                            }
                        } else {
                            reject("Network Error");
                        }
                    }catch(err){
                        console.error("Error saving the response:", err);
                        this.somethingWentWrong = true;
                        this.isLoading = false;
                    }
                }
                xmlHttp.send(payload);
            }catch(err){
                console.error("Error in saveEdit:", err);
                this.somethingWentWrong = true;
                this.isLoading = false;
            }
        });
    }

    copyToClipboard() {
        let str = this.firstResponseData;
        function listener(e) {
            e.clipboardData.setData("text/html", str);
            e.clipboardData.setData("text/plain", str);
            e.preventDefault();
        }
        if(!this.metaData.isClosed){
            if(this.copyForRichTextEditor){
                document.addEventListener("copy", listener);
                document.execCommand("copy");
                document.removeEventListener("copy", listener);
                this.showNotification('Success!!', 'Copied to Clipboard', 'success');
            }else{
                const tempElement = document.createElement('div');
                tempElement.innerHTML = this.firstResponseData;
                const plainTextWithNewlines = tempElement.innerHTML.replace(/<\/a>/gi, '</a> ').replace(/<\/p>\s*<p>/gi, '\n').replace(/<br\s*\/?>/gi, '\n').replace(/<ol[^>]*>/gi, '\n').replace(/<ul[^>]*>/gi, '\n').replace(/<li[^>]*>/gi, '• ').replace(/<\/li>/gi, '\n').replace(/<[^>]+>/g, '');
                const textarea = document.createElement('textarea');
                textarea.value = plainTextWithNewlines;
                document.body.appendChild(textarea);
                textarea.select();
                try {
                    const successful = document.execCommand('copy');
                    if (successful) {
                        this.showNotification('Success!!', 'Copied to Clipboard', 'success');
                    } else {
                        this.showNotification('Failed to copy!!', 'error');
                    }
                } catch (err) {
                    console.error('Error copying text: ', err);
                }
                document.body.removeChild(textarea);
            }
            
            trackEvent({
                ...this.metaData,
                feature_category: "Response Assist",
                feature_name: "Copy to Clipboard",
                interaction_type: 'click',   
                feature_description: "No. of times Copy to Clipboard was clicked", 
                generated_response: this.firstResponseData,
                metric: {}
            }, this.loggedInUserData);
        }
    }

    // Function to retrieve JSON data from local storage
    retrieveFromLocalStorage(key) {
        const storedData = localStorage.getItem(key);
        return storedData ? JSON.parse(storedData) : null;
    }

    showNotification(notificationTitle, notificationMessage, notificationVariant) {
        const evt = new ShowToastEvent({
            title: notificationTitle,
            message: notificationMessage,
            variant: notificationVariant,
        });
        this.dispatchEvent(evt);
    }

    readMoreCaseTimelineHandler(){
        const url = this.readMoreLink;
        window.open(url, '_blank');
    }

    feedbackResetChildMethod(){
        const child = this.template.querySelector('c-s-u_-aiq-feedback');
        if (child) {
            child.resetFeedback();
        } 
    }
}