import { LightningElement } from 'lwc';
export default class ProdOpsConsoleLWC extends LightningElement {
    activeTab = '1';
    handleActive(event) {
     this.activeTab = event.target.value; 
    } 
}