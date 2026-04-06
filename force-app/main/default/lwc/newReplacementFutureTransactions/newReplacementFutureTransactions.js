import { LightningElement, api, track} from 'lwc';
import MyModal from 'c/sKUNewReplacement';

export default class newReplacementFutureTransactions extends LightningElement {
    @api displayeddatawrapper;
    @api mainIndex;
    @api quotedetails;
    @api disableValidations; //FY25SR-1875
    @api replaceanytoany;
    @api errorscustometadata = new Map();
    wrapperData;

    handleCheckBoxSelectionChange(event){
        event.preventDefault();
        
        let checkBoxSelection = event.detail.checked;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('checkoxselection', {
            detail: {
                    'checkBoxSelection':checkBoxSelection,
                    'customIndex':customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    connectedCallback() {
        debugger;
        this.wrapperData = JSON.parse(JSON.stringify(this.displayeddatawrapper));
        // JSON.parse(JSON.stringify(this.displayeddatawrapper)).forEach(currentItem => {
            console.log('currentItem ::::::: 25 ::',this.displayeddatawrapper.customIndex);
        // });
    }

    handleServiceContract(event) {
        let cIndex = event.currentTarget.dataset.customIndex;
        this.baseURL = window.location.origin;
        let url = this.baseURL + '/' + event.currentTarget.dataset.serviceId;
        window.open(url, '_blank');
    }

    addRows(event){
        event.preventDefault();
        let customIndex = event.currentTarget.dataset.customIndex;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        let entitlementId = event.currentTarget.dataset.entid;

        const selectEvent = new CustomEvent('addrows', {
            detail: {
                    'customIndex':customIndex,
                    'entitlementId' : entitlementId,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }

    deleteRows(event){
        event.preventDefault();
        
        let customIndex = event.currentTarget.dataset.customIndex;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        const selectEvent = new CustomEvent('deleterows', {
            detail: {
                    'customIndex':customIndex,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleQuanChange(event){
        event.preventDefault();
        
        let quantity = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        let entitlementId = event.currentTarget.dataset.entid;
        const selectEvent = new CustomEvent('quantitychange', {
            detail: {
                    'quantity':quantity,
                    'customIndex':customIndex,
                    'entitlementId' : entitlementId,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleselectoptionparent(event){
        event.preventDefault();
        
        let parentOptionSelection = event.detail;
        let customIndex = event.currentTarget.dataset.customIndex;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        let entitlementId = event.currentTarget.dataset.entid;
        const selectEvent = new CustomEvent('assetchange', {
            detail: {
                    'parentOptionSelection' : parentOptionSelection,
                    'customIndex' : customIndex,
                    'entitlementId' : entitlementId,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }

    async handleSKUClick(event) {
        let customIndex = event.currentTarget.dataset.customIndex;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        let entdata = this.displayeddatawrapper.mapAssetEntitlements.futureValues[0];
        const result = await MyModal.open({
          size: 'large',
          description: "Accessible description of modal's purpose",
          label: 'test',      
          entdata: entdata,
          quoteDetails :this.quotedetails,
          customIndex: customIndex,
          disableValidations : this.disableValidations, //FY25SR-1875
          replacementanytoany : this.replaceanytoany, //FY25SR-1875
          customErrorMessages : this.errorscustometadata
        //   onskuselect: (event) => {
        //     event.stopPropagation();
        //    const selectEvent = new CustomEvent('skuclick', {
        //     detail: {
        //                     'skuSelected':event.detail,
        //                     'customIndex':customIndex,
        //                     'keyIdentifier' : keyIdentifier
        //                 }
        //         });
        //     this.dispatchEvent(selectEvent);
        //   }
        });
        if (result) {
            this.modalResult = result;
            const selectEvent = new CustomEvent('skuclick', {
            detail: {
                            'skuSelected':this.modalResult,
                            'customIndex':customIndex,
                            'keyIdentifier' : keyIdentifier
                        }
                });
            this.dispatchEvent(selectEvent);
          }
    }
    
    handleSKUchange(event){
        event.preventDefault();        
        let customIndex = event.currentTarget.dataset.customIndex;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        const selectEvent = new CustomEvent('skuchange', {
            detail: {
                    'customIndex':customIndex,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }
    
    handleTermChange(event){
        event.preventDefault();
        let termHandle = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        let entitlementId = event.currentTarget.dataset.entid;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        const selectEvent = new CustomEvent('termchange', {
            detail: {
                    'termvalue':termHandle,
                    'customIndex':customIndex,
                    'entitlementId' : entitlementId,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleDisposition(event){
        event.preventDefault();
        let selectedDisposition = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        let entitlementId = event.currentTarget.dataset.entid;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        const selectEvent = new CustomEvent('dispositionchange', {
            detail: {
                    'selectedDisposition': selectedDisposition,
                    'customIndex': customIndex,
                    'entitlementId' : entitlementId,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }

    // Added this method as part of FY25SR-1215 which runs after the renewal end date is changed by the user
    handleRenewalDateChange(event){
        event.preventDefault();
        let selectedRenewalDate = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        let entitlementId = event.currentTarget.dataset.entid;
        let keyIdentifier = event.currentTarget.dataset.keyidentifier;
        const selectEvent = new CustomEvent('renewaldatechange', {
            detail: {
                    'selectedRenewalDate': selectedRenewalDate,
                    'customIndex': customIndex,
                    'entitlementId' : entitlementId,
                    'keyIdentifier' : keyIdentifier
                }
        });
       this.dispatchEvent(selectEvent);
    }
}