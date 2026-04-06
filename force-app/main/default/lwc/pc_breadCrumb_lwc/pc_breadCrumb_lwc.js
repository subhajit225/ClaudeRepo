import { LightningElement, track } from 'lwc';
import getPageConfigs from '@salesforce/apex/PC_PortalNavigationApexController.getPartnerPageConfigurations';
export default class Pc_breadCrumb_lwc extends LightningElement {
    pageTitle;
    @track pageNameArray = [];
    pageLinkClass ='page-link';

    connectedCallback(){
        this.pageTitle = window.document.title;

        getPageConfigs({ title : this.pageTitle})
        .then(result=>{
            console.log('pp+'+JSON.stringify(result));
            console.log('length->'+result.length);
            let arrlength = result.length;
            for(let i=0; i<result.length; i++){
                console.log('i++'+i);
                let classNames;
                if((arrlength-1) == i){
                    classNames = this.pageLinkClass + ' active-page-link';
                }else{
                    classNames = this.pageLinkClass;
                }
                if(result[i].Menu_Label__c == 'Home'){
                    this.pageNameArray.push({label : result[i].Menu_Label__c , url : result[i].Navigate_Url__c, key : i, showCarrot : false, class :classNames});
                }else{
                    this.pageNameArray.push({label : result[i].Menu_Label__c , url : result[i].Navigate_Url__c, key : i, showCarrot : true, class : classNames});
                }
                
            }
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });    
    }
        
}