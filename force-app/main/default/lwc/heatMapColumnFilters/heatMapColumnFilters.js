import { LightningElement,track ,api,wire} from 'lwc';
import updateSelectedColumnFilters from '@salesforce/apex/HeatMapController.updateSelectedColumnFilters';

export default class HeatMapColumnFilters extends LightningElement {
    @track isCollapsed = false;
    @track columnFiters = [];
    @track allColumnNames = [];
    @track filterNameAndValues = [];
    @api columnFilterOptions;
    showColumnData = false;

    get sidebarClass() {
        return this.isCollapsed ? 'sidebar collapsed' : 'sidebar';
    }

    get buttonIcon() {
        return this.isCollapsed ? 'utility:chevronright' : 'utility:chevronleft';
    }

    connectedCallback() {
        this.isLoading=true;
        this.isLoading = false;
        this.columnFiters =  JSON.parse(JSON.stringify(this.columnFilterOptions));
        this.showColumnData = true;
    }

    toggleSidebar() {
        this.isCollapsed = !this.isCollapsed;
    }

    handlerfilter(event){
        const columnName = event.target.name;
        const columnItem = this.columnFiters.find(item => item.ColumnName === columnName);
        if (columnItem) {
            columnItem.State = event.target.checked;
            this.publishLMSData(event);
            this.updateSelectedColumnFiltersMethod();
        }
    }

    publishLMSData(input){
        let checkedColumns = [];
        let unCheckedColumns = null;
        if(input === 'preselected'){
            checkedColumns = this.columnFiters.filter(item => item.State)?.map(item => item.ColumnName);
        }else{
            this.template.querySelectorAll('input[type="checkbox"]:checked').forEach(element =>{
                checkedColumns.push(element.name);
            });
            console.log('checkedColumns[] ' , checkedColumns);
            if(!input.target.checked){
                unCheckedColumns = input.target.name;
            }
        }
        const payload ={
            selectedColumnFilter : JSON.stringify(checkedColumns),
            unSelectedColumns : unCheckedColumns
        };

        console.log('payload',JSON.stringify(payload));
        const customEvent = new CustomEvent("columnfiltersetunset", {
            detail : payload
        });
        this.dispatchEvent(customEvent);
    }
    
    updateSelectedColumnFiltersMethod(){
        let updatedValues = '';
        this.template.querySelectorAll('input[type="checkbox"]:checked').forEach(element =>{
            updatedValues += element.name + ';';
        });
        if(updatedValues && updatedValues.endsWith(";")){
            updatedValues = updatedValues.replace(/;$/, '');
        }
        let filterValue = {"key":"Column_Filters", "value":updatedValues};
        this.filterNameAndValues.push(filterValue);
        updateSelectedColumnFilters({ updatedValues: JSON.stringify(this.filterNameAndValues) })
        .then((result) => {
            console.log(result);
            if(result !== 'Success'){
                console.log('@@@@@@@@@@@@ Error occurred');
            }
         })
         .catch((error) => {
             console.log(error);
         });
    }
}