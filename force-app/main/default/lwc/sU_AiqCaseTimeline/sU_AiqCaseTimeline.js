import { LightningElement, track, api, wire } from 'lwc';

import {fireEvent} from 'c/supubsub';
import {fetchTimelineData} from 'c/sU_AiqDataRepository';
import {convertToTimezone, trackEvent} from 'c/sU_AiqUtils';

import { CurrentPageReference } from 'lightning/navigation';
import getCommunityCustomSettings from '@salesforce/apex/su_vf_console.SU_LtngCaseAnalyticsCTRL.getCommunityCustomSettings';

export default class SU_AiqCaseTimeline extends LightningElement {
    @wire(CurrentPageReference) objpageReference;
    @api recordId;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    @api eventCode;
    @api isUtility;
    @api utilityTop;
    @api suComponentHeight;
    @api loggedInUserData;
    @api metaData; 
    @track timelineData = {"activities": []};
    @track agentsWorkedOnCase = [];
    @track openSince;
    @track closedIn;
    @track caseCreateDate;
    @track isLoading = true;
    @track somethingWentWrong = false;
    @track searchActivityData = []; 
    @track showSearchHistory = false;
    @track secondTooltipData = [];
    @track timelinePopupView = false;
    @track isUtilityPopout = false;

    
    @track currentSlide = 0; // Current slide index
    @track sliderStyle = 'transform: translateX(0);'; // Initial slider style
    @track prevButtonDisabled = true; // State variable to disable/enable the "previous" button
    @track nextButtonDisabled = false; // State variable to disable/enable the "next" button
    @track showNavigationButtons = false; // State variable to conditionally show the navigation buttons
    @track customSettingErrorMessage;
    @track communityUid;
    @track agentsHistoryAvailable = false;
    readMoreLink = "https://docs.searchunify.com/Content/Apps/Agent-Helper-Overview.htm";


    // Width of each slide (set to the same width as the list item width)
    slideWidth = 130;
    // Number of items visible in the slider at once
    numVisibleItems = 2; // Adjust this to the desired number of items visible at once

    caseTimelineData;

    connectedCallback() {
        this.fetchData();
        this.getCommunityCustomSettings(this.recordId);
         if(window.location.pathname.includes('lightning/popout/utility')){
            this.isUtilityPopout = true;
        }
    }

    @api
    childMethod() {
        this.slideWidth = 160;
        this.currentSlide = 0;
        this.sliderStyle ='transform: translateX(0);';
        this.prevButtonDisabled = true; 
        this.nextButtonDisabled = false;
        this.calculateButtonVisibility();
        const outerDiv = this.template.querySelector('.outer-div');
        outerDiv?.classList.toggle('popup-timeline');
        !outerDiv && console.log("didnt got the element outer div");
    }

    getCommunityCustomSettings(id) {
        getCommunityCustomSettings({ caseId: id }).then(result => {
            if (result) {
                this.communityBearer = result.token;
                this.communityEndpoint = result.endPoint;
                this.communityUid = result.uid;
                this.getSUCustomerJourney();
            } else {
                this.customSettingErrorMessage = 'Please configure your SearchUnify and try again.';
            }
        })
        .catch(error => {
            console.log('[error]', error);
        });
    }

    getSUCustomerJourney() {
        try{
            var xmlHttp = new XMLHttpRequest();
            var url = this.communityEndpoint + "/admin/contentSources/byCaseUidAuth?uid=" + this.communityUid;
            xmlHttp.withCredentials = true;
            xmlHttp.open("POST", url, true);
            xmlHttp.setRequestHeader("Accept", "application/json");
            xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.communityBearer);
            xmlHttp.setRequestHeader('Content-Type', 'application/json');
            xmlHttp.send();
            xmlHttp.onreadystatechange =  () => {
                if (xmlHttp.readyState === 4) {
                    try{
                        if (xmlHttp.status === 200) {
                            var result = JSON.parse(xmlHttp.response);
                            if (result.statusCode === 200) {
                                let suCustomerJourney = [];
                                if(result && result.array && result.array.length){
                                    suCustomerJourney = result.array;
                                    suCustomerJourney = suCustomerJourney.filter((ele) => 
                                        ["search", "conversions"].includes(ele.ActivityType.toLowerCase()));
                                    
                                    suCustomerJourney.sort((a,b) => {
                                        if(a.StartDate != b.StartDate) {
                                            return a.StartDate > b.StartDate ? 1 : -1;
                                        }
                                        else{
                                            return a.ActivityType === "Search" ? -1 : 1
                                        }
                                    });
                                }
                                let formattedData = [];
                                let searchObj = {};
                                let activityIndex = 0;
                                suCustomerJourney.forEach(ele => {
                                    if(ele.ActivityType === 'Search'){
                                        if(searchObj.searchQuery){
                                            formattedData.push(searchObj);
                                            searchObj = {};
                                        }
                                        searchObj = {
                                            searchQuery : ele.ActivityValue,
                                            conversions : [],
                                            countingIndex : ++activityIndex
                                        }
                                    }
                                    if(ele.ActivityType === 'Conversions'){
                                        searchObj.conversions.push(ele.ActivityValue);
                                    }
                                });
                                if(searchObj.searchQuery){
                                    formattedData.push(searchObj);
                                    searchObj = {};
                                }
                                this.searchActivityData = formattedData;
                                this.showSearchHistory = this.searchActivityData.length !== 0;
                            }
                        }
                    }catch(err){
                        console.log("Error fetching the case journey details:", err);
                    }
                }
            }
        }catch(err){
            console.log("Error fetching the case journey request:", err);
        }
    }

    renderedCallback() {
        if(this.somethingWentWrong === false){
            this.calculateButtonVisibility();
        }
        // Listen for window resize event to recalculate visibility of navigation buttons
        window.addEventListener('resize', this.calculateButtonVisibility.bind(this));
        if(this.suComponentHeight === 0){
            fireEvent(this.objpageReference, "checkHeight" + this.eventCode, null);
        }
    }

    disconnectedCallback() {
        // Remove the event listener on component disconnection
        window.removeEventListener('resize', this.calculateButtonVisibility.bind(this));
    }

    fetchData() {
        fetchTimelineData(this.recordId)
            .then(result => {
                if(result.success){
                    let timelineData = JSON.parse(JSON.stringify(result.data));
                    
                    if(timelineData.agentsHistoryAvailable){
                        this.agentsHistoryAvailable = true;
                        let agentsData = JSON.parse(JSON.stringify(timelineData.agents));
                        if(timelineData.status.toLowerCase() === 'closed'){
                            agentsData[agentsData.length - 1].toDate = timelineData.closedDate;
                        }
                        agentsData.map((agent)=>{
                            // const [year, month, day] = new Date(agent.fromDate).toISOString().split('T')[0].split('-');

                            let date = convertToTimezone(agent.fromDate, this.loggedInUserData.TimeZoneSidKey);
                            agent.formattedDate = date.split('T')[0].split('-').reverse().join('.');
                            agent.timeSpent=this.getTimeDiffString(agent.fromDate, agent.toDate, agent.voidTime);
                            return agent;
                        });
                        this.agentsWorkedOnCase = agentsData;
                    }

                    if(timelineData.status.toLowerCase() === 'closed'){
                        this.closedIn = this.getTimeDiffString(timelineData.createdDate, timelineData.closedDate);

                    }else{
                        this.openSince = this.getTimeDiffString(timelineData.createdDate, new Date().getTime());
                    }

                    let caseCreateDate = timelineData.createdDate;
                    this.getTimelineDataFromMl(timelineData)
                    .then((data)=>{
                        fireEvent(this.objpageReference, "aiqHastags" + this.eventCode, data.hashtags);
                        this.timelineData  = this.formatTimelineDataFromMl(data, caseCreateDate);                    
                        if(this.timelineData.activities.length === 0 && !this.showSearchHistory) this.somethingWentWrong = true; 
                        this.isLoading = false;
                    })
                    .catch(err =>{
                        console.log(err);
                        this.isLoading = false;
                        this.somethingWentWrong = true;
                    });
                }else{
                    console.log("Error fetching Sf data:", result);
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

    getTimelineDataFromMl(dataPayload) {
        return new Promise((resolve, reject)=>{
        var sendData = JSON.stringify({
            "uid": this.uid,
            "streaming": false,
            "data": dataPayload,
            "llm": true,
            "custom_model_name": "openai"
        });
      
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/mlService/case-timeline";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.setRequestHeader('Origin', window.location.hostname);
        xmlHttp.setRequestHeader('uid', this.uid);
        const startTime = performance.now();
        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    let result = JSON.parse(xmlHttp.response);
                    if (result.status === 200) {
                        resolve(result.data);
                    } else if (result.status === 403) {
                        reject("LLM is Inactive or not Configured.");
                    }
                    else {
                        reject("Unable to generate timeline data .");
                    }
                } else {
                    reject("Unable to generate timeline data .");
                }

                trackEvent({
                    ...this.metaData,
                    feature_category: "Case Timeline",
                    feature_name: "Time to Response",
                    interaction_type: 'response_time',   
                    feature_description: "Time taken to generate response", 
                    metric: {
                        response_time: performance.now()-startTime,
                        api_status: xmlHttp.status
                        }
                }, this.loggedInUserData);
            } else {
                reject("Unable to generate timeline data .");
            }
        }
        xmlHttp.send(sendData);
        });
    }
    
    formatTimelineDataFromMl(tlData, caseCreateDate){
        tlData.activities = tlData.activities.filter((activity)=>{
            activity.llm_response.activityData = activity.llm_response.activityData.filter((actData) => {
                return actData.value.length !== 0;
            });
            return activity.llm_response.activityData.length !== 0;
        });
        tlData.activities = tlData.activities.map((activity, index) => {
            activity.isCaseCreateEvent = activity.type === 'caseCreate';
            activity.isNewCommentEvent = activity.type === 'CaseCommentPost' || activity.type === 'TextPost' || activity.type === 'EmailMessageEvent';

            if (activity.visibility === 'InternalUsers') {
                activity.isInternalComment = true;
            } else {
                activity.isInternalComment = false;
            }

            activity.uniqueId = activity.ts + index;
            activity.timeSpent = this.getTimeDiffString(caseCreateDate, activity.ts);
            
            let date = convertToTimezone(activity.ts, this.loggedInUserData.TimeZoneSidKey);
            activity.formattedDate = date.split('T')[0].split('-').reverse().join('.');


                let sentimentValue = activity.llm_response.sentiment;
                if(sentimentValue > 0.25){
                    activity.cssClassForActivity = "aiq-user-action activity-sentiment-positive";
                }else if(sentimentValue < -0.25){
                    activity.cssClassForActivity = "aiq-user-action activity-sentiment-negative";
                }else{
                    activity.cssClassForActivity = "aiq-user-action activity-sentiment-neutral";
                }
            
            if(!activity.isCaseCreateEvent && activity.actorType === 'agent'){
                activity.cssClassForActivity = activity.cssClassForActivity + ' agent-replied';
            }
            activity.isActivityByAgent = activity.actorType === 'agent';
            activity.actorNameUpper = activity.actorFirstName 
            ? activity.actorFirstName.toUpperCase() 
            : activity.actorName 
                ? activity.actorName.toUpperCase()
                : "";

            return activity;
        });

        this.ensureArrayForValueKey(tlData);
        this.caseTimelineData = JSON.stringify(tlData)
        return tlData;
    }

    ensureArrayForValueKey(data) {
        data.activities.forEach(activity => {
            if (activity.llm_response && activity.llm_response.activityData) {
                activity.llm_response.activityData.forEach(item => {
                    if (typeof item.value === 'string') {
                        item.value = [item.value];
                    }
                });
            }
        });
    }

    getTimeDiffString(fromDate, toDate, voidTime = 0){
        const fromTime = new Date(fromDate).getTime();
        const toTime = new Date(toDate).getTime();
        const timeSpentHours = Math.abs(toTime - fromTime - voidTime) / (1000 * 3600);
        let timeSpent = '';
        if (timeSpentHours < 1) {
            const timeSpentMinutes = Math.round(timeSpentHours * 60);
            timeSpent = `${timeSpentMinutes} mins`;
        } else if (timeSpentHours < 24) {
            timeSpent = `${timeSpentHours.toFixed(2)} Hrs`;
        } else {
            timeSpent = `${(timeSpentHours/24).toFixed(2)} Days`;
        }
        return timeSpent;
    }
    

    // Go to the previous slide
    prevSlide() {
        if (this.currentSlide > 0) {
            this.currentSlide--;
            this.updateSliderPosition();
        }
    }

    // Go to the next slide
    nextSlide() {
        if (this.currentSlide < this.timelineData.activities.length - this.numVisibleItems) {
            this.currentSlide++;
            this.updateSliderPosition();
        }
    }

    // Update the slider position based on the current slide
    updateSliderPosition() {
        const translateX = -(this.currentSlide * this.slideWidth);
        this.sliderStyle = `transform: translateX(${translateX}px);`;
        this.calculateButtonState();
    }

    // Calculate and update the state of the buttons
    calculateButtonState() {
        this.prevButtonDisabled = (this.currentSlide === 0);
        this.nextButtonDisabled = (this.currentSlide >= this.timelineData.activities.length - this.numVisibleItems);
    }

    // Calculate the visibility of the navigation buttons
    calculateButtonVisibility() {
        // Get the container and list elements
        const container = this.template.querySelector('.slider-container');
        const list = this.template.querySelector('.slider-ul');

        // Calculate the container width and list width
        if(container && list){
            const containerWidth = container.offsetWidth;
            const listWidth = list.scrollWidth; // Using scrollWidth for total width

            // Determine if the list width exceeds the container width
            this.showNavigationButtons = listWidth > containerWidth;
        }
    }

    // Search history activity toolitps
    @track showTooltipSearchActivity = false;
    @track searchTooltipX = 0;
    @track searchTooltipY = 0;
    @track searchTooltipHovered = false;
    searchTooltipTimeout;

    handleMouseOverSearchActivity(event) {
        let tooltipLocation;
        this.showActivityTooltip = false;
        this.showTooltipAgent = false;
        clearTimeout(this.searchTooltipTimeout); // Clear any existing timeout
        this.showTooltipSearchActivity = true;
        // Calculate coordinates
        const rect = event.target.getBoundingClientRect();
        this.searchTooltipX = rect.left + window.scrollX;
        // this.searchTooltipY = rect.top + window.scrollY; 

        const tooltipHolder = this.template.querySelector(`span.suMouseHoverClass`).getBoundingClientRect();
        if(tooltipHolder) tooltipLocation = tooltipHolder.top;
        if(this.isUtility && !this.isUtilityPopout) this.searchTooltipY = tooltipLocation - (window.innerHeight -  this.suComponentHeight) + 80;
        // else this.searchTooltipY = rect.top + window.screenY;
        else this.searchTooltipY = tooltipLocation;
    }

    handleMouseLeaveSearchActivity() {
        // Set a timeout to hide the tooltip after 1 second if not hovered over tooltip
        if (!this.searchTooltipHovered) {
            this.searchTooltipTimeout = setTimeout(() => {
                this.showTooltipSearchActivity = false;
            }, 300);
        }
    }

    handleSearchTooltipMouseOver() {
        clearTimeout(this.searchTooltipTimeout); // Clear any existing timeout
        this.searchTooltipHovered = true;
    }

    handleSearchTooltipMouseLeave() {
        this.searchTooltipHovered = false;
        // Set a timeout to hide the tooltip after 300ms second if not hovered over target element
        this.searchTooltipTimeout = setTimeout(() => {
            this.showTooltipSearchActivity = false;
        }, 300);
    }

    get searchTooltipStyle() {
        return `top: ${this.searchTooltipY + 40}px; left: ${this.searchTooltipX}px;`;
    }

    // Tooltip for activity nodes other than search activity.
    @track showActivityTooltip = false;
    @track activityTooltipX = 0;
    @track activityTooltipY = 0;
    @track activityTooltipHovered = false;
    activityTooltipTimeout;

    handleMouseOverActivityNode(event) {
        let tooltipLocation;
        this.showTooltipAgent = false;
        this.showTooltipSearchActivity = false;
        clearTimeout(this.activityTooltipTimeout); // Clear any existing timeout
        this.secondTooltipData = this.timelineData.activities[event.target.dataset.index].llm_response.activityData;
        this.secondTooltipData.sort((a, b) => {
            if (a.title === "Highlights") return -1;
            if (b.title === "Highlights") return 1;
            return 0;
          });
        this.showActivityTooltip = true;
        // Calculate coordinates
        const rect = event.target.getBoundingClientRect();
        this.activityTooltipX = rect.left + window.scrollX;
        // if(this.isUtility) this.activityTooltipY = rect.top  - (window.innerHeight- this.suComponentHeight) + 80;
        // else this.activityTooltipY = rect.top + window.screenY;

        const tooltipHolder = this.template.querySelector(`span.aiq-user-icon[data-index='${event.target.dataset.index}']`).getBoundingClientRect();
        if(tooltipHolder) tooltipLocation = tooltipHolder.top;
        if(this.isUtility && !this.isUtilityPopout) this.activityTooltipY = tooltipLocation - (window.innerHeight -  this.suComponentHeight) + 120;
        // else this.activityTooltipY = rect.top + window.screenY + 40;
        else this.activityTooltipY = tooltipLocation + 40;


    }

    handleMouseLeaveActivityNode() {
        if (!this.activityTooltipHovered) {
            this.activityTooltipTimeout = setTimeout(() => {
                this.showActivityTooltip = false;
            }, 300);
        }
    }

    handleActivityTooltipMouseOver() {
        clearTimeout(this.activityTooltipTimeout); // Clear any existing timeout
        this.activityTooltipHovered = true;
    }

    handleActivityTooltipMouseLeave() {
        this.activityTooltipHovered = false;
        // Set a timeout to hide the tooltip after 1 second if not hovered over target element
        this.activityTooltipTimeout = setTimeout(() => {
            this.showActivityTooltip = false;
        }, 300);
    }

    get activityTooltipStyle() {
        return `top: ${this.activityTooltipY }px; left: ${this.activityTooltipX}px;`;
    }





    // agent replied tooltip

    @track showTooltipAgent = false;
    @track agentTooltipX = 0;
    @track agentTooltipY = 0;
    @track agentTooltipData;
    @track agentTooltipHovered = false;
    agentTooltipTimeout;

    handleMouseOverAgent(event) {
        if(!this.showActivityTooltip){
            let tooltipLocation;
            // this.showActivityTooltip = false;
            // this.showTooltipSearchActivity = false;
            clearTimeout(this.agentTooltipTimeout); // Clear any existing timeout
            this.showTooltipAgent = true;
            this.agentTooltipData = this.timelineData.activities[event.target.dataset.index];
            // Calculate coordinates
            const rect = event.target.getBoundingClientRect();
            this.agentTooltipX = rect.left + window.scrollX;
            // this.agentTooltipY = rect.top + window.scrollY;

            const tooltipHolder = this.template.querySelector(`p.aiq-tag[data-index='${event.target.dataset.index}']`).getBoundingClientRect();
            if(tooltipHolder) tooltipLocation = tooltipHolder.top;
             if(this.isUtility && !this.isUtilityPopout) this.agentTooltipY = tooltipLocation - (window.innerHeight -  this.suComponentHeight) + 80;
            // else this.agentTooltipY = rect.top + window.screenY ;
            else this.agentTooltipY = tooltipLocation;

        }
    }

    handleMouseLeaveAgent() {
        if (!this.agentTooltipHovered) {
            this.agentTooltipTimeout = setTimeout(() => {
                this.showTooltipAgent = false;
            }, 300);
        }
        
    }

    handleMouseOverAgentTooltip() {
        clearTimeout(this.agentTooltipTimeout); // Clear any existing timeout
        this.agentTooltipHovered = true;
    }

    handleMouseLeaveAgentTooltip() {
        this.agentTooltipHovered = false;
        // Set a timeout to hide the tooltip after 1 second if not hovered over target element
        this.agentTooltipTimeout = setTimeout(() => {
            this.showTooltipAgent = false;
        }, 300);
    }

    get tooltipStyleAgent() {
        return `top: ${this.agentTooltipY + 25}px; left: ${this.agentTooltipX}px;`;
    }

    readMoreCaseTimelineHandler(){
        window.open(this.readMoreLink, '_blank');
    }

    // Timeline popup view
    toggleDiv() {
        const outerDiv = this.template.querySelector('.outer-div');
        if (outerDiv.classList.contains('popup-timeline')) {
            this.slideWidth = 130;
        } else {
            trackEvent({
                ...this.metaData,
                feature_category: "Case Timeline",
                feature_name: "Case Timeline",
                interaction_type: 'click',   
                feature_description: "Clicked on Zoom icon", 
                metric: {}
            }, this.loggedInUserData);

            this.slideWidth = 160;
        }
        this.updateSliderPosition();
        outerDiv?.classList.toggle('popup-timeline');

        const event = new CustomEvent('callparentmethod');
        this.dispatchEvent(event);
    }

}