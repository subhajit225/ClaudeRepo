import { LightningElement, track, api} from 'lwc';
export default class HeatMapHeaderFilter extends LightningElement {
    @track styleSection = '';
    @api filterOptions = [];
    @api columnNameToOptions;
    
    connectedCallback() {
        this.styleSection = 'position: absolute;width: 180px;display: block;margin: 20px 0px 0px -97px;z-index: 30';
    }

    handleCheckbox(event){
       const selectedPickVal = event.target.name;
       const checkedval = event.target.checked;
       const colname = event.target.dataset.colname;
       
       let copyFilterOperations = JSON.parse(JSON.stringify(this.filterOptions));
       
       copyFilterOperations.forEach(currentItem =>{
        if(currentItem.label == selectedPickVal && currentItem.columnName == colname){
                currentItem.isChecked = checkedval;
            }
       });
       this.columnNameToOptions.set(colname, copyFilterOperations);

       this.filterOptions = copyFilterOperations;
       const selectedEvent = new CustomEvent('selectedfilteroptions' , {
            bubbles : true,
            composed : true,
            detail : { filterOptions : this.filterOptions,
                     columnName : colname,
                     columnNameToOptions : this.columnNameToOptions}
        });
        this.dispatchEvent(selectedEvent);        
    }

}