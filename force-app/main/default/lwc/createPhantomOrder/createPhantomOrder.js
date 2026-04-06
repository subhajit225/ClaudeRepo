import { LightningElement, api,wire } from 'lwc';
import processPhantomOrder from '@salesforce/apex/GeneratePhantomOrdController.createPhantomOrder';
import checkEligibilityForPhantomOrder from '@salesforce/apex/GeneratePhantomOrdController.checkEligibilityForPhantomOrder';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';

export default class CreatePhantomOrder extends LightningElement {
    @api recordId;   
    orderItems = [];
    isLoading = true;
    isValidOrder = false;
    statusMessage = 'Failed to fetch order details';

    submitOrder() {
        this.isLoading = true;
         processPhantomOrder({ orderItemsJSON: JSON.stringify(this.orderItems)})
            .then(result => {
                this.handleCancel();
                this.showToast('Success', result, 'success');
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    @wire(CurrentPageReference)
    getPageRef({ state }) {
        if (state && state.recordId) {
            this.recordId = state.recordId;
        }
        if(this.recordId){
            this.isLoading = true;
            this.validatePhantomOrder();
        }
    }
    validatePhantomOrder(){
        checkEligibilityForPhantomOrder({ parentOrdId: this.recordId })
            .then(result => {
                if (result) {
                    let responseArray = Object.keys(result).map(key =>{
                        return {key : key, value : result[key]};
                    });
                    let orderStatus = responseArray[0].key;
                    let responseData = responseArray[0].value;
                    if(orderStatus == 'InvalidOrder'){
                        this.statusMessage = responseData;
                        this.isValidOrder = false;
                    }
                    else{
                        this.isValidOrder = true;
                        this.orderItems = JSON.parse(responseData);
                    }
                }
            })
            .catch(error => {
                let errorMsg = error.body.message;
                if(errorMsg.includes('You do not have access to the Apex class')){
                    this.statusMessage = 'Action Required: IT Ticket needed.Please reach out to Support Team on this email Prodopsapps@rubrik.com to generate Phantom Order';
                }
                else{
                    this.showToast('Error fetching order info', errorMsg, 'error');
                }
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}