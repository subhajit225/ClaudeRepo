import { LightningElement, wire } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { NavigationMixin } from "lightning/navigation";
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import globalResourceConfigs from '@salesforce/apex/PC_PortalNavigationApexController.getGlobalResourceConfigs';
import PC_FeaturedItemCard1 from '@salesforce/resourceUrl/PC_FeaturedItemCard1';
import PC_FeaturedItemCard2 from '@salesforce/resourceUrl/PC_FeaturedItemCard2';
import PC_FeaturedItemCard3 from '@salesforce/resourceUrl/PC_FeaturedItemCard3';

export default class Pc_globalResourceSection_lwc extends NavigationMixin(LightningElement) {
    pageName = '';
    showComponentSection = false;
    resourceHeader;
    resourceButtonLabel;
    resourceButtonURL;
    featureCardBig = {};
    featureCardsList = [];

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                //console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });

        this.pageName = window.document.title;
        console.log('pageName'+this.pageName);
        console.log('PC_FeaturedItemCard1' + PC_FeaturedItemCard1);
        console.log('PC_FeaturedItemCard2' + PC_FeaturedItemCard2);
        console.log('PC_FeaturedItemCard3' + PC_FeaturedItemCard3);
    }

    @wire(globalResourceConfigs, {portalPageName: '$pageName'})
    wiredConfigs(wireResult){
        const { data, error } = wireResult;
        if(data){
            console.log(JSON.stringify(data));
            for(let ele of data){
                console.log(JSON.stringify(ele));
                if(ele.Image_Type__c == 'Global Resource Card'){
                    this.showComponentSection = true;
                    this.resourceHeader = ele.Headline__c;
                    this.resourceButtonLabel = ele.Navigate_Text__c;
                    this.resourceButtonURL = ele.Navigate_Url__c;
                }
                console.log('imga url->'+ele.Image_Url__c);
                if(ele.Image_Type__c == 'Featured Item Card' && ele.Order__c == 1){
                    this.featureCardBig = ele;
                }else if (ele.Image_Type__c == 'Featured Item Card'){
                    this.featureCardsList.push(ele);
                }
            }
        }
        if(error) {
            console.error(error);
        }
    };

    handleExploreClick(){
        this[NavigationMixin.Navigate]({
            "type": "standard__webPage",
            "attributes": {
                "url": this.resourceButtonURL
            }
        },true);
    }
}