import { LightningElement } from 'lwc';
import getCardDetails from '@salesforce/apex/PC_PortalNavigationApexController.gethomePageCardDetails';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import basepath from '@salesforce/community/basePath';
export default class Pc_homePageCards_lwc extends LightningElement {
    cardList = [];
    basepath = basepath;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {

            })
            .catch(error => {
                console.log( error.body.message );
        });
        let pName = window.document.title;
        getCardDetails({ pageName : pName})
        .then(result=>{
            console.log('20->'+ JSON.stringify(result));
            for(let i=0; i<result.length ; i++){
                if(result[i].Link_Type__c == 'External URL'){
                    result[i].URLType = '_blank';
                }else if(result[i].Link_Type__c == 'Community Page'){
                    result[i].Navigate_Url__c = this.basepath + result[i].Navigate_Url__c;
                    result[i].URLType = '_self';
                }
            }
            this.cardList = result;
            console.log('34->'+ JSON.stringify(this.cardList));
        })
        .catch(error=>{
            console.log('-->'+JSON.stringify(error));
        });
    }
}