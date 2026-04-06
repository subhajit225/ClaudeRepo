import { LightningElement,api,track } from 'lwc';
export default class HeatMapAccountFilters extends LightningElement {

    
    @api headerOfFilter = '';
    @api filterOptionsInitial = [];
    @api sectionStyle='';
    @track selectedValue = [];
    @track filterOptions = [];
    @track userSelectedRecord = {};
    @api keyName = '';
    @track keyState = ''
    
    connectedCallback(){
        this.filterOptions = [...this.filterOptionsInitial][0].value;

        this.keyState = this.keyName;
    }

    handleCheckbox(event){
        let selectedOptionId = event.currentTarget.dataset.id;
        this.filterOptions = this.filterOptions.map(item =>{
            if (item.id === selectedOptionId){
                const updatedItem = {...item, isChecked: !item.isChecked};
                this.userSelectedRecord = updatedItem;
                this.userSelectedRecord.key = this.keyState;
                return updatedItem;
            }
            return item;
        });

        const selectedEvent = new CustomEvent('selectedfilteraccounts' , {
            bubbles : true,
            composed : true,
            detail : {optionSelected : this.userSelectedRecord}
        });
        this.dispatchEvent(selectedEvent);
    }

    handleInputChange(event){
        if (event.target.value != undefined){
            this.filterSearch(event.target.value);
        }
    }

    filterSearch(filterValue){
        this.filterOptions = [...this.filterOptionsInitial][0]?.value?.filter((option) => option.label.toLowerCase().includes(filterValue.toLowerCase()));
    }

    handleClearAll(){
        this.filterOptions = this.filterOptions.map(item => {
            return { ...item, isChecked: false };
        });

        const selectedEvent = new CustomEvent('selectorclearalloptions' , {
            bubbles : true,
            composed : true,
            detail : {
                "filterName":"account",
                "buttonClicked":"Clear All"
            }
        });
        this.dispatchEvent(selectedEvent);

    }
    
    handleSelectAll(){
        this.filterOptions = this.filterOptions.map(item => {
            return { ...item, isChecked: true };
        });
        const selectedEvent = new CustomEvent('selectorclearalloptions' , {
            bubbles : true,
            composed : true,
            detail : {
                "filterName":"account",
                "buttonClicked":"Select All"
            }
        });
        this.dispatchEvent(selectedEvent);
    }
    
}