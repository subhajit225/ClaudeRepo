import { LightningElement,wire,api } from 'lwc';
import getAccountHierarchy from '@salesforce/apex/PC_PortalNavigationApexController.getAccountHierarchy';
export default class PC_accountHierarchy extends LightningElement {
    isAdminOrExec = false;
    selectedLabel;
    selectedValue;
    options= [];
    allValues=[];
    optionsMaster=[];

    @wire(getAccountHierarchy)
    wiredData({ error, data }) {
      if (data) {
        if(data.accList != undefined && data.accList.length > 0){
            for(let i=0; i<data.accList.length; i++){
                this.optionsMaster.push({
                    label: data.accList[i].Name,
                    value: data.accList[i].Id
                });
            }

            this.isAdminOrExec = (data.userRec.Contact.Primary_Role__c == 'Admin' || data.userRec.Contact.Primary_Role__c == 'Executive') ? true : false;
        }
        
        this.options = this.optionsMaster;
      } else if (error) {
        console.error('Error account:', error);
      }
    }

    @api
    reset() {
        if(this.optionsMaster){
            console.log('reset');
            this.allValues =[];
            this.selectedLabel = '';
            this.selectedValue = '';
            this.options = this.optionsMaster;
        }
        this.modifyOptions();
    }

    handleChange(event){
        this.selectedValue=event.target.value;
        this.selectedLabel = event.target.options.find(opt => opt.value === this.selectedValue).label;
        if(!this.allValues.some(e=>e.value === this.selectedValue)){
            this.allValues.push({
                label: this.selectedLabel,
                value: this.selectedValue
            });
        }
        this.modifyOptions();
    }

    handleRemove(event){
        this.selectedValue='';
        this.selectedLabel='';
        const valueRemoved=event.target.name;
        this.allValues.splice(this.allValues.findIndex(elem => {return elem.value === valueRemoved}),1);
        this.modifyOptions();
    }

    modifyOptions(){
        this.options=this.optionsMaster.filter(elem=>{
            return !this.allValues.find(e=>{
                return e.value == elem.value;
            });
        })
        this.sendEvent();
    }

    sendEvent(){
        const selectedIds = this.allValues.map(e => e.value);
        console.log(selectedIds);
        const csEvt = new CustomEvent('accountfilter', {
            message: 'Selected Account Ids',
            detail: selectedIds
        });
       this.dispatchEvent(csEvt);
    }

}