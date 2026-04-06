import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import basepath from '@salesforce/community/basePath';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getPartnerFundRequestsData from '@salesforce/apex/PC_PortalNavigationApexController.getPartnerFundRequestsData';
export default class Pc_mdfHighlightReport_lwc extends LightningElement {
    basepath = basepath;
    @track mdfList = [];
    @track mdfRequestsMade = 0;
    @track mdfClaimsOutstanding = 0;
    url;

    connectedCallback() {
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
            //console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body.message );
        });

        getPartnerFundRequestsData()
        .then(result=>{
            console.log('result->'+JSON.stringify(result));
            console.log('mdfRequestsMade->'+result.mdfRequestsMade);
            console.log('mdfClaimsOutstanding->'+result.mdfClaimsOutstanding);
            console.log('mdfList->'+result.mdfList);
            this.mdfRequestsMade = result.mdfRequestsMade;
            this.mdfClaimsOutstanding = result.mdfClaimsOutstanding;
            this.mdfList = result.mdfList.slice(0,6);
            
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
        this.url = this.basepath + '/marketingfunds';
    }

    handleClick(event){
        let mdfFormUrl = this.basepath + '/marketingfundsnew';
        window.open(mdfFormUrl,'_self');
    }
}