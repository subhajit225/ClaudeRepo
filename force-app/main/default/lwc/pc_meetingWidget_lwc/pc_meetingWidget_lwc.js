import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import createMeeting from '@salesforce/apex/PC_MeetingWidgetController.createMeeting'
import getLatestMeeting from '@salesforce/apex/PC_MeetingWidgetController.getLatestMeeting';
import rescheduleMeeting from '@salesforce/apex/PC_MeetingWidgetController.rescheduleMeeting';
import updateOutcome from '@salesforce/apex/PC_MeetingWidgetController.updateOutcome';


export default class Pc_meetingWidget_lwc extends LightningElement {

    @api leadId;
    @api action;
    @api expDate;

    showSpinner = true;
    isBookingOrReschedule = false;
    isShowMeetOutcome = false;
    startTimeDisable = true;
    endTimeDisable = true;
    noConvertReasonDisable = true;
    cancelReasonDisable = true;
    toggle = true;

    labelMeetingOutcome = 'What was the outcome of the meeting?';
    labelNoConvertReason = 'Do Not Convert Reason?';
    labelCancelReason = 'Cancellation Reason?';

    outcomeValue1 = 'Opportunity sourced';
    outcomeValue2 = 'No Opportunity sourced';
    outcomeValue3 = 'Meeting Cancelled';

    noConvertReasonValue1 = 'No found potential champion';
    noConvertReasonValue2 = 'No found mutually identified pain';
    noConvertReasonValue3 = 'No found problem worth solving';
    noConvertReasonValue4 = 'No calendered next step';
    //noConvertReasonValue5 = 'Other';

    cancelReasonValue1 = 'Customer - No Show';
    cancelReasonValue2 = 'Customer - Reschedule';
    cancelReasonValue3 = 'Customer - Cancellation';
    cancelReasonValue4 = 'Sales - Reschedule';
    cancelReasonValue5 = 'Sales - Cancellation';
    cancelReasonValue6 = 'Created in Error';

    get outcomeOptions() {
        return [
            { label: 'Yes Opportunity', value: this.outcomeValue1 },
            { label: 'No Opportunity', value: this.outcomeValue2 },
            { label: this.outcomeValue3, value: this.outcomeValue3 }
        ];
    }

    get noConvertReasonOptions() {
        return [
            { label: this.noConvertReasonValue1, value: this.noConvertReasonValue1},
            { label: this.noConvertReasonValue2, value: this.noConvertReasonValue2},
            { label: this.noConvertReasonValue3, value: this.noConvertReasonValue3},
            { label: this.noConvertReasonValue4, value: this.noConvertReasonValue4},
            { label: this.noConvertReasonValue5, value: this.noConvertReasonValue5}
        ];
    }
    
    get canceltReasonOptions() {
        return [
            { label: this.cancelReasonValue1, value: this.cancelReasonValue1},
            { label: this.cancelReasonValue2, value: this.cancelReasonValue2},
            { label: this.cancelReasonValue3, value: this.cancelReasonValue3},
            { label: this.cancelReasonValue4, value: this.cancelReasonValue4},
            { label: this.cancelReasonValue5, value: this.cancelReasonValue5},
            { label: this.cancelReasonValue6, value: this.cancelReasonValue6}
        ];
    }

    connectedCallback(){
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            //console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        })
        //this.d = new Date(new Date().toLocaleString('en-US', {timeZone : "America/New_York"}));
        this.d = new Date();
        this.showSpinner = false;

        if(this.leadId && this.action == 'Book a Meeting'){
            this.bookMeeting();
        }else if(this.leadId && this.action == 'Reschedule Meeting'){
            this.rescheduleMeeting();
        }else if(this.leadId && this.action == 'Log Meeting Outcome'){
            this.logMeetingOutcome();
        }
    }

    getDate(){
        //return this.today = this.selectedDate = new Date().toJSON().slice(0,10);
        //return this.today = this.selectedDate = new Date().toLocaleString("en-US",{timeZone : "America/New_York", month : "2-digit", day : "2-digit", year: "numeric"});
        return this.today = this.selectedDate = this.d.getFullYear()+'-'+this.addZero(this.d.getMonth()+1)+'-'+this.addZero(this.d.getDate());
    }

    getTime(){
        //return this.minimumStartTime = new Date().toJSON().slice(11,24);
        return this.minimumStartTime = this.addZero(this.d.getHours())+':'+this.addZero(this.d.getMinutes());
    }

    addZero(ti) {
        if (ti < 10) {ti = "0" + ti}
        return ti;
    }

    bookMeeting(){
        this.getDate();
        this.getTime();
        this.isBookingOrReschedule = true;
        this.startTimeDisable = false;
        this.modalHeading = 'Book a Meeting';
        this.buttonLabel = 'Book';
        this.handleButtonDisable();
    }

    rescheduleMeeting(){
        this.showSpinner = true;
        getLatestMeeting({leadId : this.leadId})
            .then(result => {
                console.log(result);
                this.getDate();
                this.modalHeading = 'Reschedule Meeting';
                this.buttonLabel = 'Update';
                /* var tzSDate = new Date(new Date(result.StartDateTime).toLocaleString('en-US', {timeZone : "America/New_York"}));
                var tzEDate = new Date(new Date(result.EndDateTime).toLocaleString('en-US', {timeZone : "America/New_York"})); */
                var tzSDate = new Date(new Date(result.StartDateTime));
                var tzEDate = new Date(new Date(result.EndDateTime));
                this.selectedDate = tzSDate.getFullYear()+'-'+this.addZero(tzSDate.getMonth()+1)+'-'+this.addZero(tzSDate.getDate());
                this.startTime = this.addZero(tzSDate.getHours())+':'+this.addZero(tzSDate.getMinutes());
                this.endTime = this.addZero(tzEDate.getHours())+':'+this.addZero(tzEDate.getMinutes());
                this.minimumStartTime = this.selectedDate == this.today ? this.getTime() : "";
                this.minimumEndTime = this.startTime;
                this.meetId = result.Id;
                this.startTimeDisable = false;
                this.endTimeDisable = false;
                this.isBookingOrReschedule = true;
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.hideModalBox();
                this.showToast('','Unable to fetch any scheduled meetings','INFO','pester');
                console.log('error : ' +JSON.stringify(error));
            });
        
    }

    logMeetingOutcome(){
        this.showSpinner = true;
        this.buttonDisable = true;
        getLatestMeeting({leadId : this.leadId})
            .then(result => {
                this.meetId = result.Id;
                this.isShowMeetOutcome = true;
                this.modalHeading = 'Log Meeting Outcome';
                this.buttonLabel = 'Submit';
                this.outcome = result.Post_Meeting_Status__c;
                this.noConvertReason = result.Disqualified_Reason__c;
                this.cancelReason = result.Cancellation_Reason__c;
                this.showSpinner = false;
            })
            .catch(error => {
                this.showSpinner = false;
                this.hideModalBox();
                this.showToast('','Unable to fetch any meetings','INFO','pester');
                console.log('error : ' +JSON.stringify(error));
            });
    }

    handleOnDateChange(event){
        this.selectedDate = event.detail.value;
        console.log('s : '+this.selectedDate, 't : '+this.today);
        this.blntoggle();
        if(!(this.selectedDate && this.selectedDate >= this.today)){
            this.startTimeDisable = true;
            this.endTimeDisable = true;
        }else{
            this.startTimeDisable = false;
            this.endTimeDisable = true;
            this.minimumStartTime = this.selectedDate == this.today ? this.getTime() : "";
            this.startTime = null;
            this.endTime = null;
        }
        this.handleButtonDisable();
    }

    handleOnStartTimeChange(event){
        this.startTime = event.detail.value;
        if(this.startTime){
            this.endTimeDisable = false;
            var tempTime = new Date(this.selectedDate+'T'+this.startTime);
            tempTime = new Date (tempTime.setMinutes(tempTime.getMinutes() + 15));
            tempTime = this.addZero(tempTime.getHours())+':'+this.addZero(tempTime.getMinutes());
            this.minimumEndTime = this.endTime = tempTime;
            this.blntoggle();
        }else{
            this.endTimeDisable = true;
        }
        this.handleButtonDisable();
    }

    handleOnEndTimeChange(event){
        this.endTime = event.detail.value;
        this.handleButtonDisable();
        console.log('s : '+this.startTime, 'e : '+this.endTime);
    }

    blntoggle(){
        this.toggle = false;
        this.toggle = true;
    }

    handleOnOutcomeChange(event){
        this.outcome = event.detail.value;
        this.noConvertReasonDisable = true;
        this.cancelReasonDisable = true;
        this.noConvertReason = null;
        this.cancelReason = null;

        if(this.outcome === this.outcomeValue2){
            this.noConvertReasonDisable = false;
        }else if(this.outcome === this.outcomeValue3){
            this.cancelReasonDisable = false;
        }

        this.handleButtonDisable();
        this.blntoggle();
    }

    handleOnNoConvertReasonChange(event){
        this.noConvertReason = event.detail.value;
        this.handleButtonDisable();
        this.blntoggle();
    }

    handleOnCancelReasonChange(event){
        this.cancelReason = event.detail.value;
        this.handleButtonDisable();
        this.blntoggle();
    }

    handleButtonDisable(){
        if(this.action === 'Log Meeting Outcome'){
            if(this.outcome && this.outcome === this.outcomeValue1){
                this.buttonDisable = false;
            }else if(this.noConvertReason && this.outcome === this.outcomeValue2){
                this.buttonDisable = false;
            }else if(this.cancelReason && this.outcome === this.outcomeValue3){
                this.buttonDisable = false;
            }else{
                this.buttonDisable = true;
            }
        }else{
            if(this.startTime && this.endTime){
                this.buttonDisable = false;
            }else{
                this.buttonDisable = true;
            }
        }
    }

    handleButtonClick(){
        var a = new Date(this.expDate).getTime();
        var b = new Date(this.selectedDate).getTime()
        if(a < b && ((b - a)/86400000) > 90){
            this.showToast('','Can\'t schedule a meeting post 90 days of expiration','WARNING','pester');
        }else{
            if(this.action === 'Book a Meeting'){
                this.handleOnSave();
            }else if(this.action === 'Reschedule Meeting'){
                this.handleOnUpdate();
            }else if(this.action === 'Log Meeting Outcome'){
                this.handleOnUpdateOutcome();
            }
        }
    }
    
    handleOnSave(){
        var meetStartx = new Date(this.selectedDate+'T'+this.startTime);
        var meetEndx = new Date(this.selectedDate+'T'+this.endTime);
        console.log('Selected Start : '+meetStartx, 'Selected End : '+meetEndx);
        meetStartx = meetStartx.toISOString();
        meetEndx = meetEndx.toISOString();
        console.log('GMT Start : '+meetStartx, 'GMT End : '+meetEndx);
        this.showSpinner = true;

        createMeeting({ meetStart : meetStartx, meetEnd : meetEndx, leadId : this.leadId })
		.then(result => {
            this.showSpinner = false;
            this.hideModalBox();
            this.showToast('SUCCESS','Meeting Scheduled','success','dismissible');
            console.log(JSON.stringify(result));
		})
		.catch(error => {
            this.showSpinner = false;
			this.error = error;
            this.hideModalBox();
            this.showToast('ERROR','Meeting not Scheduled due to technical Error','error','pester');
            console.log('error : '+JSON.stringify(error));
		})
    }

    handleOnUpdate(){
        /* var meetRescStartx = new Date(this.selectedDate+'T'+this.startTime);
        var meetRescEndx = new Date(this.selectedDate+'T'+this.endTime); */
        /*var meetRescStartx = new Date(new Date(this.selectedDate+'T'+this.startTime).toLocaleString('en-US', {timeZone : "America/New_York"}));
        var meetRescEndx = new Date(new Date(this.selectedDate+'T'+this.endTime).toLocaleString('en-US', {timeZone : "America/New_York"}));*/
        var meetRescStartx = new Date(this.selectedDate+'T'+this.startTime);
        var meetRescEndx = new Date(this.selectedDate+'T'+this.endTime);
        console.log('Updated Start : '+meetRescStartx, 'Updated End : '+meetRescEndx);
        meetRescStartx = meetRescStartx.toISOString();
        meetRescEndx = meetRescEndx.toISOString();
        console.log('GMT Start : '+meetRescStartx, 'GMT End : '+meetRescEndx);
        this.showSpinner = true;

        rescheduleMeeting({ meetStart : meetRescStartx, meetEnd : meetRescEndx, eventId : this.meetId })
		.then(result => {
            this.showSpinner = false;
            this.hideModalBox();
            this.showToast('SUCCESS','Meeting Rescheduled','success','dismissible');
            console.log(JSON.stringify(result));
		})
		.catch(error => {
            this.showSpinner = false;
			this.error = error;
            this.hideModalBox();
            this.showToast('ERROR','Unable to Reschedule Meeting due to technical Error','error','pester');
            console.log('error : '+JSON.stringify(error));
		})
    }

    handleOnUpdateOutcome(){
        this.showSpinner = true;
        /*if(this.outcome === this.outcomeValue2){
            this.cancelReason = null;
        }else if(this.outcome === this.outcomeValue3){
            this.noConvertReason = null;
        }else{
            this.cancelReason = null;
            this.noConvertReason = null;
        }*/
        updateOutcome({ outcome : this.outcome, noConvertReason : this.noConvertReason, cancelReason : this.cancelReason, eventId : this.meetId })
		.then(result => {
            this.showSpinner = false;
            this.hideModalBox();
            this.showToast('SUCCESS','Meeting outcome submitted','success','dismissible');
            //PRIT24-422 - start
            if(this.outcome == this.outcomeValue1){
                const selectedEvent = new CustomEvent('createdealreg', { detail: this.outcome });
                this.dispatchEvent(selectedEvent);
            }
            //PRIT24-422 - end
            console.log(JSON.stringify(result));
		})
		.catch(error => {
            this.showSpinner = false;
			this.error = error;
            this.hideModalBox();
            this.showToast('ERROR','Unable to save Meeting outcome due to technical Error','error','pester');
            console.log('error : '+JSON.stringify(error));
		})
    }

    hideModalBox(){
        this.isBookingOrReschedule = false;
        this.isShowMeetOutcome = false;
        this.dispatchEvent(new CustomEvent('resetmeetingwidget', {
            detail: {
                message: 'Reset Meeting Widget'
            }
        }));
    }

    showToast(title,message,variant,mode){
        console.log('here');
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: mode
        });
        this.dispatchEvent(evt);
        if(title === 'SUCCESS'){
            this.dispatchEvent(new CustomEvent('refresh', {
                detail: {
                    message: 'refresh'
                }
            }));
        }
    }

}