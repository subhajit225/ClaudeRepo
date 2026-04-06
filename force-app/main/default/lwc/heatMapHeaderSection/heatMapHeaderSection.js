import { LightningElement, api, track } from 'lwc';
export default class HeatMapHeaderSection extends LightningElement {
    @api accountDetails = [];
    @track totalAccounts = 0;

    @track showAccordianSection = false;
    @track calculationAreaItems;

    get accordianIcon() {
        if (this.showAccordianSection) {
            return 'utility:chevronup';
        } else {
            return 'utility:chevrondown';
        }
    }

    @api recalculateHeaderData(accountDetails){
        this.accountDetails = [...accountDetails];
        this.handleCalculation(this.accountDetails);
    }

    connectedCallback(){
        console.log('account details  ',this.accountDetails);
    }

    handleAccordian(){
        this.showAccordianSection = !this.showAccordianSection;
        console.log('account details in method  ',this.accountDetails);
        if(this.showAccordianSection){
            this.handleCalculation(this.accountDetails);
        }
    }
    handleCalculation(accounts){
        console.log('account details in handlemethod ',accounts);
        console.log('account details size  ',accounts.length);
        if(accounts.length){
            console.log("iside if block");
            this.totalAccounts = accounts.length;
        }else{
            this.totalAccounts = 0;
        }

     
        this.calculationAreaItems = [{label:"Accounts" ,id:"1" ,containerClass:"accountsSection ",elementClass:"account" ,value:this.totalAccounts ,isAccount:true},
                                        {label:"Estimated Potential Acv" ,id:"2" ,containerClass:"calculationItems ",elementClass:"estimatedPotentil" ,value:0+'m' ,isAccount:false},
                                        {label:"Capacity Alerts" ,id:"3" ,containerClass:"calculationItems ",elementClass:"capacityAlerts" ,value:0 ,isAccount:false},
                                        {label:"Entitlement Lands" ,id:"4" ,containerClass:"calculationItems ",elementClass:"entitlementLand" ,value:0 ,isAccount:false},
                                        {label:"Entitlement Upgrades" ,id:"5" ,containerClass:"calculationItems ",elementClass:"entitlementUpgrades" ,value:0 ,isAccount:false}
                                    ];
    }
}