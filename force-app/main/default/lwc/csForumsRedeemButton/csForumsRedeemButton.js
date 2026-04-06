import { LightningElement, wire, api, track } from 'lwc';
import getCurrentUserInfo from '@salesforce/apex/CS_ForumsCatalogController.getCurrentUserDetails';
import COINS_ICON from '@salesforce/resourceUrl/CoinsIcon';

export default class CsForumsRedeemButton extends LightningElement {
    @api recordId;
    @track currentUser = '';
    //@track isCurrentUserProfile = false;
    coinsIcon = COINS_ICON;

    @wire(getCurrentUserInfo)
    wiredUserInfo({error, data}) {
        if(data){
            if(data.Id === this.recordId){
                this.currentUser = data;
                //this.isCurrentUserProfile = true;
            }
        } else if(error){

        }
    }

    get displayButton(){
        return ((this.currentUser.Id == this.recordId) && (!this.currentUser.Is_Rubrik_Employee__c));
    }

    //Navigate to visualforce page
    navigateToStore() {
        window.open('rewards', '_blank');
    }
}