import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getTransformAccfClaimData from '@salesforce/apex/PC_PortalNavigationApexController.getTransformAccfClaimData';
import {NavigationMixin} from "lightning/navigation";

export default class Pc_transAccClaimHighlightReport_lwc extends  NavigationMixin(LightningElement) {
    claimList = [];
    approved = 0;
    rejected = 0;
    submitted = 0;

    connectedCallback() {
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            //console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        });

        getTransformAccfClaimData()
        .then(result=>{
            console.log('result->'+JSON.stringify(result));
            this.approved = result.approved;
            this.rejected = result.rejected;
            this.submitted = result.submitted;
            this.claimList = result.claimList;
            
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
    }

    handleClick(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
            attributes: {
                name: 'Transform_Accelerator_Claim__c'
            }
        });
    }
}