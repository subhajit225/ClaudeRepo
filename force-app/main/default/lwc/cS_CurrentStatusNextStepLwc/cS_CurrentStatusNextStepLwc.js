import { LightningElement, wire , api, track } from 'lwc';
import getUserInfo from '@salesforce/apex/CaseDetailLightningController.getUserInfo';
import profilesWithEditAccess from '@salesforce/label/c.Profiles_with_edit_access';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CS_CurrentStatusNextStepLwc extends LightningElement {
    @api recordId;
    @track isCollapsed = false;
    @track isModalOpen = false;
    @track error = '';
    @track isEditable = false;
    @track isLoadingComplete = false;
    @track isButtonDisabled = false;

    @wire(getUserInfo)
    wiredUserInfo({error, data}) {
        if(data){
            if(profilesWithEditAccess.includes(data.Profile.Name)) {
                this.isEditable = true;
            }

        } else if(error){
            this.error = error;
            this.isEditable = false;
        }
    }

    toggleSectionHeader(){
        this.isCollapsed = !this.isCollapsed;
    }

    openEditModal(){
        this.isModalOpen = true;
        this.isLoadingComplete = false;
    }

    handleLoad(){
        this.isLoadingComplete = true;
    }

    closeModal(){
        this.isModalOpen = false;
        this.isLoadingComplete = true;
    }

    handleSuccess(){
        this.isButtonDisabled = false;
        this.isModalOpen = false;
        this.isLoadingComplete = true;
    }

    submitRecord(){
        this.isLoadingComplete = false;
        this.isButtonDisabled = true;
    }

    handleError(event){
        this.showErrorMessage(event.detail.detail);
        this.isButtonDisabled = false;
        this.isLoadingComplete = true;
    }

    showErrorMessage(errorMessage) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: errorMessage,
            variant: 'error',
            mode: 'dismissable'
        });
        this.dispatchEvent(evt);
    }
}