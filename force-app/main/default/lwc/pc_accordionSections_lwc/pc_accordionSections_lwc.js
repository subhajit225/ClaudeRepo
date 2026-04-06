import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import accordionDetails from '@salesforce/apex/PC_PortalNavigationApexController.getAccordionDetails';
export default class Pc_accordionSections_lwc extends LightningElement {

    @track accordionDetails;
    @track accordionHeadline;
    isData = true;
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
        let pName = window.document.title;
        accordionDetails({ pageName : pName })
        .then(result=>{
            console.log('result-->'+JSON.stringify(result));
            if(result.length > 0){
                this.accordionDetails = result;
                this.accordionHeadline = result[0].Card_Title__c;
            }else{
                this.isData = false;
            }
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
    }
}