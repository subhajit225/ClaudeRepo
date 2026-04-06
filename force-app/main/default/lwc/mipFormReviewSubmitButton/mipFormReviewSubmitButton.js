import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport'

export default class MipFormReviewSubmitButton extends LightningElement {
    @api showReviewButton;
    @api reviewClicked = false;

    openReview(){
        console.log('in end');
        this.reviewClicked = true;
        const navigateNextEvent = new FlowNavigationNextEvent();
        this.dispatchEvent(navigateNextEvent);
    }
}