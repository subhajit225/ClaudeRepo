import { LightningElement, api } from 'lwc';
import { trackEvent } from 'c/sU_AiqUtils';
export default class SU_AiqOverview extends LightningElement {
    @api recordId;
    @api endPoint;
    @api token;
    @api s3endpoint;
    @api uid;
    @api eventCode;
    @api isUtility;
    @api loggedInUserData;
    @api suComponentHeight;
    @api metaData;
    headerWidth;

    connectedCallback() {
        window.addEventListener('resize', this.resizeCheck.bind(this));
        this.resizeCheck();
    }

    applyClasses() {
        const overviewHeader = this.template.querySelector('.aiq-overview');
        // const caseTimelineComponent = this.template.querySelector(".caseTimeline");
        if (overviewHeader) {
            this.headerWidth = overviewHeader.clientWidth;
        }
        else console.log("didnt got the component .aiq-overview therefore , not able to add css classes ");
        if(this.headerWidth <=590){
            // caseTimelineComponent.style.display = "none";
            overviewHeader.classList.add("overview-header-590px");
        }
        else if (this.headerWidth > 590){
            // caseTimelineComponent.style.display = "block";
            overviewHeader.classList.remove("overview-header-590px");
        }
    }

    resizeCheck = () => {
        clearTimeout(this.timeout);
        this.timeout = setTimeout(() => {
            this.applyClasses();
        });
    }

    caseTimeLineClose(){   //child calling function
        if(this.headerWidth <=590){
            const caseTimelineComponent = this.template.querySelector(".caseTimeline");
            if(caseTimelineComponent) {
                caseTimelineComponent.classList.remove("showDisplayDemoClassSU");
                caseTimelineComponent.classList.add("noDisplayDemoClassSU");
            }
        }
        
    }

    caseTimeLineModalHandler(){       
        const caseTimelineComponent = this.template.querySelector(".caseTimeline");
        if(caseTimelineComponent){
            caseTimelineComponent.classList.remove("noDisplayDemoClassSU");
            caseTimelineComponent.classList.add("showDisplayDemoClassSU");
            trackEvent({
                ...this.metaData,
                feature_category: "Case Timeline",
                feature_name: "Case Timeline Small Screen",
                interaction_type: 'click',   
                feature_description: "Case timeline opened from small screen view", 
                metric: {}
            }, this.loggedInUserData);
        }

        this.caseTimelineChildMethod();
    }

    caseTimelineChildMethod(){
        const childComponent = this.template.querySelector('c-s-u_-aiq-case-timeline');
        if(childComponent) childComponent.childMethod();
        else console.log("didnt got the child ")
        
    }
}