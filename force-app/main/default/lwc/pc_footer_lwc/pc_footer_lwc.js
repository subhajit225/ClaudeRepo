import { LightningElement, track } from 'lwc';
import footerLabel from '@salesforce/label/c.PC_Footer_Label';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getFooterDetails from '@salesforce/apex/PC_PortalNavigationApexController.getFooterDetails';
import basepath from '@salesforce/community/basePath';
export default class Pc_footer_lwc extends LightningElement {

    footerLogo;
    footerLabel = footerLabel;
    @track footerItems;
    @track footerIconsList;
    basepath = basepath;

    connectedCallback(){
        Promise.all([
        loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
        ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
        })
        .catch(error => {
            console.log( error.body);
        });

        getFooterDetails()
        .then(result=>{
            console.log('-->'+JSON.stringify(result));
            this.footerLogo = result.footerLogo.Image_Url__c;
            for(let i=0; i<result.iconList.length ; i++){
                if(result.iconList[i].Link_Type__c == 'External URL'){
                    result.iconList[i].URLType = '_blank';
                }else if(result.iconList[i].Link_Type__c == 'Community Page'){
                    result.iconList[i].URLType = '_self';
                    result.iconList[i].Navigate_Url__c = this.basepath + this.Navigate_Url__c;
                }
            }
            for(let i=0; i<result.configList.length ; i++){
                if(result.configList[i].Link_Type__c == 'External URL'){
                    result.configList[i].URLType = '_blank';
                }else if(result.iconList[i].Link_Type__c == 'Community Page'){
                    result.configList[i].URLType = '_self';
                    result.configList[i].Navigate_Url__c = this.basepath + this.Navigate_Url__c;
                }
            }
            this.footerItems = result.configList;
            this.footerIconsList = result.iconList;
        })
        .catch(error=>{
            console.log('--<'+JSON.stringify(error));
        });
    }
}