import { LightningElement } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import basepath from '@salesforce/community/basePath';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getOpportunityDetails from '@salesforce/apex/PC_PartnerOppPipelineApexController.getOpportunityData';
export default class Pc_opportunityHighlightReport_lwc extends LightningElement{
    oppList =[];
    closedOppCount = 0;
    openOppCount = 0;
    url;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityFolder/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
            });

        getOpportunityDetails()
        .then(result=>{
            this.closedOppCount = result.closedOppCount;
            this.openOppCount = result.openOppCount;
            this.oppList = result.oppList;

        })
        .catch(error=>{
            console.log('-->'+error);
        });
        this.url = basepath + '/partner-opportunity-pipeline';
    }
}