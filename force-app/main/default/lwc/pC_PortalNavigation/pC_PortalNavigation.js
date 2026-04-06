import { LightningElement,api,wire,track } from 'lwc';
import getMenuConfigs from '@salesforce/apex/PC_PortalNavigationApexController.getMenuConfigs';
import currentUserId from '@salesforce/user/Id';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';

export default class PC_PortalNavigation extends LightningElement {
    currUserID = currentUserId;

    @track menuAllRec = [];
    @track menuMap = [];
    @track subMenuMap = [];
    @track hasSubMenu;

    connectedCallback(){
        Promise.all([
            loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')
            ]).then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
        });
        this.loadMenuConfigs();
    }

    loadMenuConfigs(){
        getMenuConfigs({userId : this.currUserID})
        .then(result => {
            //console.log('result'+JSON.stringify(result));
            var menuMapTemp = [];
            if (typeof result === 'object' && result !== null) {
                this.menuAllRec = result;
                Object.keys(result).forEach(key => {
                    if(result[key].Image_Type__c === "Menu"){
                        let valEle = [];
                        valEle = result[key];
                        if(result[key].Link_Type__c == "External URL"){
                            valEle['externalLinkClassName'] = 'externalNavLink';
                            valEle['targetWin'] = '_blank';
                        }else{
                            valEle['externalLinkClassName'] = '';
                            valEle['targetWin'] = '';
                        }
                        if(result[key].Has_Sub_Menu__c){
                            valEle['dropdownClassName'] = 'dropdownNavLink';
                        }else{
                            valEle['dropdownClassName'] = '';
                        }

                        menuMapTemp.push({key:result[key].Menu_Label__c,value:valEle});
                    }
                });
            }
            menuMapTemp.sort((a, b) => (a.Order__c) - (b.Order__c));
            this.menuMap = menuMapTemp;
            //console.log('menuMap'+JSON.stringify(this.menuMap));
        })
        .catch(error => {
             //exception handling
            this.error = error;
        })
    }

    handleMenuMouseOver(event){
        var menuLabel = event.target.getAttribute('data-id');
        if(menuLabel != null){
            var subMenuMapTemp = [];
            Object.keys(this.menuAllRec).forEach(key => {
                if(this.menuAllRec[key].Menu_Group__c === menuLabel && this.menuAllRec[key].Image_Type__c === "Menu Item"){
                    let subMenuEle = [];
                    subMenuEle = this.menuAllRec[key];
                    if(this.menuAllRec[key].Link_Type__c == "External URL"){
                        subMenuEle['externalLinkClassName'] = 'externalNavLink';
                        subMenuEle['targetWin'] = '_blank';
                    }else{
                        subMenuEle['externalLinkClassName'] = '';
                        subMenuEle['targetWin'] = '';
                    }
                    if(this.menuAllRec[key].Has_Sub_Menu__c){
                        subMenuEle['dropdownClassName'] = 'dropdownNavLink';
                    }else{
                        subMenuEle['dropdownClassName'] = '';
                    }
                    subMenuMapTemp.push({key:this.menuAllRec[key].Menu_Label__c,value:subMenuEle});
                }
            });
            subMenuMapTemp.sort((a, b) => (a.Order__c) - (b.Order__c));
            this.subMenuMap = subMenuMapTemp;
            //console.log('subMenuMapTemp'+JSON.stringify(subMenuMapTemp));
        }

        if(this.subMenuMap != null || this.subMenuMap != undefined){
            this.hasSubMenu = true;
        }
    }
}