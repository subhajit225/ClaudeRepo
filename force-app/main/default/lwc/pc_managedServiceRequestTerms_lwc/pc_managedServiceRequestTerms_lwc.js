import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin} from "lightning/navigation";
export default class Pc_managedServiceRequestTerms_lwc extends NavigationMixin(LightningElement){

    connectedCallback()
    {
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });
    }

    handleClick(event){
        let pageApiName = '';
        if(event.target.value == 'Deal_Reg_List__c'){
            pageApiName = event.target.value;
            this.showToast('Notification','You must accept the Terms and Conditions to proceed.','warning','dismissable');
        }else if(event.target.value == 'Managed_Service_New__c'){
            pageApiName = event.target.value;
        }
        
        setTimeout(() => {
            this.handleRedirect(pageApiName);
        }, 3000);
    }

    handleRedirect(pageAPIName){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: pageAPIName
            }
        });
    }

    showToast(title, message, variant, mode){
       const evt = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
        });
        this.dispatchEvent(evt);
    }
}