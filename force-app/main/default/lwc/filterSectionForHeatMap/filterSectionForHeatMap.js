import { LightningElement, api, track } from 'lwc';

export default class FilterSectionForHeatMap extends LightningElement {
    @api headerOfFilter = '';
    @api filterOptionsInitial = [];
    @api sectionStyle='';
    @track selectedValue = [];
    @track filterOptions = [];
    @track salesEngineer = [];
    @track userSelectedRecord = {};
    @api keyName = '';
    @track keyState = ''
    
    connectedCallback(){
        this.filterOptions = [...this.filterOptionsInitial];
        console.log('filter option' , this.filterOptions);
        this.keyState = this.keyName; // sales Engineer , Account Executive , ....
        console.log('@@@@@ this.keyState');
        
    }

    handleCheckbox(event){
        let selectedOptionId = event.currentTarget.dataset.id; // 0058Y00000DHsNvQAL
        this.filterOptions = this.filterOptions.map(item =>{
            if (item.id === selectedOptionId){
                const updatedItem = {...item, isChecked: !item.isChecked};
                this.userSelectedRecord = updatedItem;
                this.userSelectedRecord.key = this.keyState; // sales Engineer , Account Executive , ....
                console.log('user selected record id => ' , this.userSelectedRecord);
                return updatedItem;
            }
            return item;
        });

        const selectedEvent = new CustomEvent('selectedfilteroptions' , {
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
        let option = [];
        option = this.filterOptionsInitial.filter((option) => option.label.toLowerCase().includes(filterValue.toLowerCase()));
        this.filterOptions = [...option]
        console.log('options ', option);
    }
    
    handleSelectAll(){
        this.filterOptions = this.filterOptions.map(item => {
            return { ...item, isChecked: true };
        });
        const selectedEvent = new CustomEvent('selectorclearalloptions' , {
            bubbles : true,
            composed : true,
            detail : {
                "filterName":this.keyState,
                "buttonClicked":"Select All"
            }
        });
        this.dispatchEvent(selectedEvent);
    }

    handleClearAll(){
        this.filterOptions = this.filterOptions.map(item => {
            return { ...item, isChecked: false };
        });

        const selectedEvent = new CustomEvent('selectorclearalloptions' , {
            bubbles : true,
            composed : true,
            detail : {
                "filterName":this.keyState,
                "buttonClicked":"Clear All"
            }
        });
        this.dispatchEvent(selectedEvent);
    }

}