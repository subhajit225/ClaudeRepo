import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport'
export default class MipFormFlowButtons extends LightningElement {

    //output
    @api addMilestone;
    @api backToElement;
    @api rebateMilestone;
    @api psnlBookings;
    @api totalBookings;

    //input
    @api elementType;
    @api milestoneCreated;
    @api psnlOrTotalOrRebateCreated;
    @api comingFromRebateMilestone;
    @api rebateType; //Variable is of no use : Story PRIT24-267

    //calculate on runtime
    showAddMilestoneBtn;
    showPSNLBtn;
    showTotalBtn;
    showBackToElementBtn;
    disableTotal = false;
    disablePSNL = false;
    showRebateMilestoneBtn;
    disableRebate = false;

    handleAddMilestone() {
        this.resetAllProperties();
        this.addMilestone = true;
        this.handleNext();
    }

    handleRebateMilestone(){
        this.resetAllProperties();
        this.rebateMilestone = true;
        this.handleNext();
    }

    handlePSNL(){
        this.resetAllProperties();
        this.psnlBookings = true;
        this.handleNext();
    }

    handleTotalBookings(){
        this.resetAllProperties();
        this.totalBookings = true;
        this.handleNext();
    }

    handleBackToElement() {
        this.resetAllProperties();
        this.backToElement = true;
        this.handleNext();
    }

    handleBackToRebateElement(){
        this.comingFromRebateMilestone = false;
        //this.autoRedirectIfCompleted();
    }

    resetAllProperties() {
        this.addMilestone = false;
        this.rebateMilestone = false;
        this.psnlBookings = false;
        this.totalBookings = false;
        this.backToElement = false;
    }

    handleNext() {
        console.log('in Next');
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }

    /*endFlow(){
        console.log('in end');
        this.resetAllProperties();

        const event = new ShowToastEvent({
            title: 'SUCCESS',
            message: 'MIP Contract Created',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);

        this.handleNext();
    }*/

    /*autoRedirectIfCompleted(){
        if(this.elementType === 'Rebate Milestone' && this.disablePSNL && this.disableTotal && this.disableRebate && !this.comingFromRebateMilestone){
            this.handleBackToElement();
        }
    }*/

    connectedCallback() {
        console.log('elementType : '+this.elementType);
        console.log('milestoneCreated : ' +this.milestoneCreated);
        console.log('psnlOrTotalOrRebateCreated : '+this.psnlOrTotalOrRebateCreated);

        this.showAddMilestoneBtn = this.showPSNLBtn = this.showTotalBtn = this.showRebateMilestoneBtn = this.showBackToElementBtn = false;

        if(this.elementType === 'Funded Head'){
            this.showAddMilestoneBtn = true;
            this.header1 = '<p>Add Milestones to your Funded Head Element</p>';
        }else if(this.elementType === 'Rebate Milestone'){
            //Commented as a part of story PRIT24-237,267
            /*if(this.rebateType === 'Concierge'){
                this.showRebateMilestoneBtn = true;
                this.showTotalBtn = true;
                this.showPSNLBtn = true;
                this.header2 = '<p>Add Milestones to your Rebate Milestone Element</p>';
            }else if(this.rebateType === 'Elite Plus'){
                this.showPSNLBtn = true;
            }else if(this.rebateType === 'Concierge PSNL Only'){
                this.showRebateMilestoneBtn = true;
                this.showPSNLBtn = true;
                this.header2 = '<p>Add Milestones to your Rebate Milestone Element</p>';
            }*/
            this.showRebateMilestoneBtn = true;
            this.showTotalBtn = true;
            this.showPSNLBtn = true;
            this.header2 = '<p>Add Milestones to your Rebate Milestone Element</p>';
        }

        if(this.psnlOrTotalOrRebateCreated !== null && this.psnlOrTotalOrRebateCreated.includes('PSNL Bookings')){
            this.disablePSNL = true;
        }
        if(this.psnlOrTotalOrRebateCreated !== null && this.psnlOrTotalOrRebateCreated.includes('Total Bookings')){
            this.disableTotal = true;
        }
        if((this.disablePSNL || this.disableTotal) && this.elementType === 'Rebate Milestone'){
            this.showBackToElementBtn = true;
        }

        console.log('after elementType : '+this.elementType);
        console.log('after milestoneCreated : ' +this.milestoneCreated);
        console.log('after psnlOrTotalOrRebateCreated : '+this.psnlOrTotalOrRebateCreated);

        //this.autoRedirectIfCompleted();
    }
}