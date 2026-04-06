import { LightningElement, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getTwoColumnDetails from '@salesforce/apex/PC_PortalNavigationApexController.getTwoColumnDetails';
import { NavigationMixin } from "lightning/navigation";
import basepath from '@salesforce/community/basePath';
export default class Pc_twoColumnImage_lwc extends LightningElement {

    @api isImageRightAligned = false;
    @api imageURL = null;
    headerValue = null;
    titleValue = null;
    imageText = null;
    buttonValue = null;
    navLink = null;
    isData = true;
    urlType;
    basepath = basepath;
    
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
        getTwoColumnDetails({pageName : pName})
        .then(result=>{
            console.log('-->'+JSON.stringify(result));
            if(result.length > 0){
                this.headerValue = result[0].Headline__c;
                this.titleValue = result[0].Card_Title__c;
                this.imageText = result[0].Image_Text__c;
                this.buttonValue = result[0].Navigate_Text__c;
                this.imageURL = result[0].Image_Url__c;
                if(result[0].Link_Type__c == 'External URL'){
                    this.urlType = '_blank';
                    this.navLink = result[0].Navigate_Url__c;
                }else if(result[0].Link_Type__c == 'Community Page'){
                    this.urlType = '_self';
                    this.navLink = this.basepath + result[0].Navigate_Url__c;
                }
                if(result[0].Image_Alignment__c == 'Left'){
                    this.isImageRightAligned = false;
                }
                else{
                    this.isImageRightAligned = true;
                }
            }else{
                this.isData = false;
            }
        })
        .catch(error=>{
            console.log('-->'+JSON.stringify(error));
        });
    }

    handleButtonClick(event){
        if(this.navLink != null){
            window.open(this.navLink,this.urlType);
        }
    }

    get showHeader(){
        if(this.headerValue != null){
            return true;
        }else{
            return false;
        }
    }

    get showTitle(){
        if(this.titleValue != null){
            return true;
        }else{
            return false;
        }
    }

    get showImgText(){
        if(this.imageText != null){
            return true;
        }else{
            return false;
        }
    }

    get showButton() {
        if(this.buttonValue != null){
            return true;
        }else{
            return false;
        }
    }
}