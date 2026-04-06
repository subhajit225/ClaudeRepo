import { LightningElement, wire, api, track } from 'lwc';
import getCurrentUserInfo from '@salesforce/apex/CS_ForumsCatalogController.getCurrentUserDetails';
import getCatalogItems from '@salesforce/apex/CS_ForumsCatalogController.getCatalogItems';
import COINS_ICON from '@salesforce/resourceUrl/CoinsIcon';
import PHONE_NUMBER_PATTERN from '@salesforce/label/c.Phone_Number_Pattern';

export default class CsForumsCatalog extends LightningElement {
    @track currentUser = '';
    @track catalogItems = [];
    @track showRedeemModal = false;
    @track showModal = false;
    @track showSuccessMessageModal = false;
    @track showItemModal = false;
    @track selectedItem = '';
    @track phoneNumber = '';
    @track phoneNumberPattern = PHONE_NUMBER_PATTERN;
    coinsIcon = COINS_ICON;

    @wire(getCurrentUserInfo)
    wiredUserInfo({error, data}) {
        if(data){
            this.currentUser = data;
            if(!data.Is_Rubrik_Employee__c){
                getCatalogItems().then(result => {

                    for(let item in result){
                        this.catalogItems.push({
                            Id: result[item].Id,
                            Name: result[item].Name,
                            Description__c: result[item].Description__c,
                            Amount__c: result[item].Amount__c,
                            Name__c: result[item].Name__c,
                            URL__c: this.generateImageUrl(result[item].Image__c),
                            Current_user_eligible_to_redeem__c: result[item].Current_user_eligible_to_redeem__c,
                            disabledPanelStyle: result[item].Current_user_eligible_to_redeem__c ? `` : `opacity:0.3`,
                            panelClass: result[item].Current_user_eligible_to_redeem__c ? `tileBox` : `tileBoxForDisabled`,
                        });
                    }
                });
            }
        } else if(error){

        }
    }

    get backgroundStyle() {
        //return `height:190px;background-image:url(${BACKGROUND_IMAGE})`;
        return `height:250px;background-color:black`;
    }

    generateImageUrl(fetchedImageUrl){
        let startIndex = (fetchedImageUrl.indexOf("src=")) + 5;
        let endIndex;
        if(fetchedImageUrl.indexOf("style=") > 0){
            endIndex = (fetchedImageUrl.indexOf("style=")) - 2;
        }
        else {
            endIndex = (fetchedImageUrl.length) - 8;
        }

        let imageUrl = fetchedImageUrl.slice(startIndex, endIndex);
        imageUrl = imageUrl.replace(/amp;/g, "");
        return imageUrl;
    }

    openItemViewModal(event){
        this.selectedItem = event.target.name;
        this.showItemModal = true;
    }

    openRedeemModal(){
        this.showRedeemModal = true;
        this.showModal = true;
        this.showItemModal = false;
    }

    closeModal(){
        this.showRedeemModal = false;
        this.showModal = false;
        this.showSuccessMessageModal = false;
        this.showItemModal = false;
    }

    handlePhoneChange(event){
        this.phoneNumber = event.target.value;
    }

    handleSubmit(event) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.detail.fields;
        fields.User__c = this.currentUser.Id;
        fields.Catalog_Item__c = this.selectedItem.Id;
        fields.Quantity__c = 1;
        fields.Amount__c = fields.Quantity__c * this.selectedItem.Amount__c;
        const d = new Date();
        fields.Submitted_Date__c = d.toISOString();
        fields.Status__c = 'New';
        fields.Phone_Number__c = this.phoneNumber;
        let userCoins = this.currentUser.Coins__c;
        fields.Coins_After_Transaction__c = userCoins - this.selectedItem.Amount__c;
        fields.Coins_Before_Transaction__c = userCoins;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }
    handleSuccess(){
        this.showRedeemModal = false;
        this.showSuccessMessageModal = true;
        this.showItemModal = false;
    }

    refreshPage(){
        this.showSuccessMessageModal = false;
        window.location.reload();
    }
}