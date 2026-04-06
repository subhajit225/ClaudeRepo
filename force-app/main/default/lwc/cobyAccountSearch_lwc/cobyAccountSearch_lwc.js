import { LightningElement, track, api } from 'lwc';
import AccountResearch_coby_Dev from "@salesforce/label/c.AccountResearch_coby_Dev";
import AccountResearch_coby_Prod from "@salesforce/label/c.AccountResearch_coby_Prod";

export default class CobyAccountSearch_lwc extends LightningElement {

@track isSandbox = false;

label = {
    AccountResearch_coby_Dev,
    AccountResearch_coby_Prod
  };
  constructor() {
        super(); // Always call super() first
        const baseUrl = window.location.origin;
        if(baseUrl.search('sandbox') >= 0){
          this.isSandbox = true;
        }
    }
  
}