import { LightningElement, track, api } from 'lwc';
import updateBLIAndRelatedBooking from '@salesforce/apex/SyncBookingWithOpportunity.updateBLIAndRelatedBooking'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';


export default class SyncBookingWithOpportunity extends LightningElement {
    @track error ; 
    @track hideSpinner = false;
    @api isInsideVF = false;
    
    loadData() {
		updateBLIAndRelatedBooking({ opptyId: this.recordId , isUpdateBook : true, isUpdateBLI : true, isUpdateBSplit : true})
		.then(result => {
            this.hideSpinner= true;
            if(!result.isSuccess){
                this.showToast(result.errorMessage, 'error','Error');
                if(!this.isInsideVF){
                    const closeQA = new CustomEvent('close', { detail:{onlyCloseQA: 'true'} });
                    // Dispatches the event.
                    this.dispatchEvent(closeQA);
                    this.dispatchEvent(new CloseActionScreenEvent());
                }
                return;
            }
            var rec= [];
            //this.pocRecord = result.pocRecords[0];
			//this.orders = result.assetRecords;
			this.error = undefined;
           
            
            this.hideSpinner= true;
            if(this.isInsideVF){
                alert('Booking and related BLI records updated');
                //window.history.back();
                window.location.href = '/'+this.recordId;
            }else{
                this.showToast('Booking and related BLI records updated', 'success','Success');
                const closeQA = new CustomEvent('close', {
                detail:{onlyCloseQA:''} });
                // Dispatches the event.
                this.dispatchEvent(closeQA);
                this.dispatchEvent(new CloseActionScreenEvent());
                //setTimeout(function(){ location.reload(); }, 1000);
            }
		}) 
		.catch(error => {
            this.hideSpinner= true;
			this.error = error;
			this.allReturnRecords = undefined;
            this.showToast(error.body.message, 'error','Error');
            if(!this.isInsideVF){
                 const closeQA = new CustomEvent('close', {
                detail:{onlyCloseQA:'true'} });
                // Dispatches the event.
                this.dispatchEvent(closeQA);
                this.dispatchEvent(new CloseActionScreenEvent());
            }
		})
    }

    handleCancel(event) {
        if(!this.isInsideVF){
            const closeQA = new CustomEvent('close', {
                detail:{onlyCloseQA:'true'} });
                // Dispatches the event.
            this.dispatchEvent(closeQA);
            this.dispatchEvent(new CloseActionScreenEvent());
        }
        else
            window.location.href = '/'+this.recordId;
    }

    @api set recordId(value) {
        this._recordId = value;
        if(value)
            this.loadData();

    }

    get recordId() {
        return this._recordId;
    }

    showToast(message, type,title){
        if(type=='error')
            this.error = message;

        if(this.isInsideVF) return;
            
        this.dispatchEvent(
                    new ShowToastEvent({
                        title: title,
                        message: message,
                        variant: type,
                        mode: 'sticky'
                    }), 
        ); 
    }
}