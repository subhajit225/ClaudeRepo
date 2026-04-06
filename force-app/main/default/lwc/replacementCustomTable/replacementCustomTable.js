import { LightningElement, api, wire, track } from 'lwc';
import MyModal from 'c/sKUNewReplacement';
import { assignEntDataToSku, handleSkuAssignment , quantityCalculation} from './skuUtilityCustomTable'; 
export default class ReplacementCustomTable extends LightningElement {
    @api
    get displayeddata() {
        return this._displayeddata;
    }
    set displayeddata(value) {
        this._displayeddata = value;
        this._computeDisplayProps();
    }
    @api modifieddata;  //FY25SR-1084 
    @api mainIndex;
    @api quotedetails; 
    @api errorscustometadata = new Map();
    @api replaceanytoany;
    @api disableValidations; //FY25SR-1875
    @api modalResult;
    @api ismismatchqty; /*CPQ22-6157*/
    _displayeddata;
    @track indentClass = '';
    @track arrowShow = '';

  // Compute hierarchical serial and indent class from customIndex (e.g. "1.0.1" -> "1.1")
    _computeDisplayProps() {
        const d = this._displayeddata;
        if (!d || !d.customIndex) {
            this.indentClass = '';
            return;
        }
        let level = d.rootId ? 1 : 0;
        this.indentClass = `indent-${level}`;
        this.arrowShow = d.rootId ? '↳ ' : '';
        try {
            this._displayeddata.indentClass = this.indentClass;
        } catch(e) { /* silent */ }
    }
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
        console.log('disp data inside table is ', JSON.stringify(this.displayeddata));
        console.log('quoteDetails are is ',this.quotedetails);
        console.log('data modified from parent is ', JSON.stringify(this.modifieddata));
        console.log('errors from parent is ', JSON.stringify(this.errorscustometadata));
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
        const selectEvent = new CustomEvent('addrows', {
            detail: {
                    'customIndex':customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    deleteRows(event){
        event.preventDefault();
        
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('deleterows', {
            detail: {
                    'customIndex':customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleQuanChange(event){
        event.preventDefault();
        
        let quantity = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('quantitychange', {
            detail: {
                    'quantity':quantity,
                    'customIndex':customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleselectoptionparent(event){
        event.preventDefault();
        
        let parentOptionSelection = event.detail;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('assetchange', {
            detail: {
                    'parentOptionSelection' : parentOptionSelection,
                    'customIndex' : customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleselectexceptionparent(event){
        event.preventDefault();
        
        let parentExceptionSelection = event.detail;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('exceptionchange', {
            detail: {
                    'parentExceptionSelection' : parentExceptionSelection,
                    'customIndex' : customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    async handleSKUClick(event) {   //FY25SR-1084 START
        let customIndex = event.currentTarget.dataset.customIndex;
        let entdata = this.displayeddata;
        let quantitySum = quantityCalculation(customIndex, this.modifieddata);
        console.log('quantitySum is ', quantitySum);
            console.log('entdata is ',JSON.stringify(entdata), ' customIndex is ',customIndex);
        const result = await MyModal.open({
          size: 'large',
          description: "Accessible description of modal's purpose",
          label: 'test',      
          entdata: entdata,
          entsDataAll : this.modifieddata,
          isMismatchQTY: this.ismismatchqty, /*CPQ22-6157*/
          customErrorMessages : this.errorscustometadata,
          replacementanytoany : this.replaceanytoany,
          quoteDetails :this.quotedetails,
          quantitySum : quantitySum,
          customIndex: customIndex,
          disableValidations : this.disableValidations //FY25SR-1875
        //   onskuselect: (event) => {
        //     event.stopPropagation();
        //    const selectEvent = new CustomEvent('skuclick', {
        //     detail: {
        //                     'skuSelected':event.detail,
        //                     'customIndex':customIndex
        //                 }
        //         });
        //     this.dispatchEvent(selectEvent);
        //   }
        });
        if (result) {
                this.modalResult = result;
                console.log('result from modalPopup is ', JSON.stringify(this.modalResult));
                const selectEvent = new CustomEvent('skuclick', {
                detail: {
                                'skuSelected':this.modalResult,
                            'customIndex':customIndex
                        }
                });
            this.dispatchEvent(selectEvent);
          }
    }//FY25SR-1084 END
    
    handleSKUchange(event){
        event.preventDefault();        
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('skuchange', {
            detail: {
                    'customIndex':customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }
    
    handleTermChange(event){
        event.preventDefault();
        let termHandle = event.target.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('termchange', {
            detail: {
                    'termvalue':termHandle,
                    'customIndex':customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    handleDisposition(event){
        event.preventDefault();
        let selectedDisposition = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('dispositionchange', {
            detail: {
                    'selectedDisposition': selectedDisposition,
                    'customIndex': customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

    // Added this method as part of FY25SR-1215 which runs after the renewal end date is changed by the user
    handleRenewalDateChange(event){
        event.preventDefault();
        let selectedRenewalDate = event.detail.value;
        let customIndex = event.currentTarget.dataset.customIndex;
        const selectEvent = new CustomEvent('renewaldatechange', {
            detail: {
                    'selectedRenewalDate': selectedRenewalDate,
                    'customIndex': customIndex
                }
        });
       this.dispatchEvent(selectEvent);
    }

}