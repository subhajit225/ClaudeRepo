import { LightningElement, api, track, wire } from 'lwc';

export default class MeetingCategoryMutliSelect extends LightningElement {
    @api meetingoptions;
    @api label;
    
    @track values = [];
    @track optionData;
    @track searchString;
    @track noResultMessage;
    @track showDropdown = false;
    @track showMeetingOptions = false;
    @track placeHolderAfterSelect = 'Select more options';

    connectedCallback() {
        this.showDropdown = false;
        var setOptionData = this.meetingoptions[0] ? (JSON.parse(JSON.stringify(this.meetingoptions[0]))) : null;
        this.optionData = setOptionData;
        this.searchString = 'Select an Option'
    }
    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;
        if(selectedVal) {
            var options = JSON.parse(JSON.stringify(this.optionData));
            for(var i = 0; i < options.length; i++) {
                if(options[i].value === selectedVal) {
                  if(this.values.includes(options[i].value)) {
                      this.values.splice(this.values.indexOf(options[i].value), 1);
                  } else {
                      this.values.push(options[i].value);
                  }
                  options[i].selected = options[i].selected ? false : true;   
                   
                }
            }
            this.optionData = options;
            event.preventDefault();
            this.searchString = this.placeHolderAfterSelect;
        }
    }
    showOptions() {
        this.showDropdown = true;
    }
    handleBlur() {
        this.showDropdown = false;
        this.searchString = this.placeHolderAfterSelect;
        let ev = new CustomEvent('selectoption', {detail:this.values});
        this.dispatchEvent(ev);
    }
    closePill(event) {
        var value = event.currentTarget.name;
        var options = JSON.parse(JSON.stringify(this.optionData));
        for(var i = 0; i < options.length; i++) {
            if(options[i].value === value) {
                options[i].selected = false;
                this.values.splice(this.values.indexOf(options[i].value), 1);
            }
        }
        this.optionData = options;
        this.searchString = this.placeHolderAfterSelect;
        let ev = new CustomEvent('selectoption', {detail:this.values});
        this.dispatchEvent(ev); 
    }
    @api resetCategory(){
        this.values = [];
        this.searchString = 'Select an Option';
        for(var i = 0; i < this.optionData.length; i++) {
            if(this.optionData[i].selected) {
                this.optionData[i].selected = false;
            }
        }
        let ev = new CustomEvent('selectoption', {detail:this.values});
        this.dispatchEvent(ev);
    }
}