import { LightningElement, track, api } from 'lwc';

export default class MultiselectComboboxLwc extends LightningElement {
  // @api options;

  @api
  get options() {
    return this._options;
  }

  set options(value) {
    this._options = value;
    this.initData();
  }

  @track _options;

  @api selectedValue;
  @api selectedValues = [];
  @track selectedMultiAdd = [];
  @api label;
  @api disabled = false;
  @api multiSelect = false;
  @api multiAdd = false;
  @api placeholder = 'Select an Option';

  @api get filterAttrs() {
    return this._filterAttrs;
  };
  set filterAttrs(value){
    this._filterAttrs = value;
    this.filterOptions();
  }
  _filterAttrs;

  @api enableSelectAll;

  @track value;
  @track values = [];
  @track optionData;
  @track searchString;
  @track noResultMessage;
  @track showDropdown = false;
  connectedCallback() {
    this.initData();
  }
  
  initData() {
    this.showDropdown = false;
    var optionData = this._options ? JSON.parse(JSON.stringify(this._options)) : null;
    var value = this.selectedValue ? JSON.parse(JSON.stringify(this.selectedValue)) : null;
    var values = this.selectedValues ? JSON.parse(JSON.stringify(this.selectedValues)) : null;

    for (var i = 0; i < optionData.length; i++) { 
        if(optionData[i].disabled ) {
          optionData[i].isVisible = false;
        } else {
        optionData[i].isVisible = true;
    }
    }
    
    if (value || values) {
      for (var i = 0; i < optionData.length; i++) { 
        if (values.includes(optionData[i].value)) {
          if (this.multiAdd){
            for (let value of values){
              if (optionData[i].value == value){
                //FY25SR-2244 start
                let optionExisting = this.selectedMultiAdd.find((option) => {if (option.value === value) return option});
                if (optionExisting){
                  optionExisting.quantity = optionExisting.quantity + 1;
                }
                else {
                  let selectedOption = Object.assign({}, optionData[i]);
                  selectedOption.key = this.selectedMultiAdd.reduce((max, option) => {return option.key >= max ? option.key + 1 : max}, 0);
                  selectedOption.quantity = 1;
                  this.selectedMultiAdd.push(selectedOption);
                }
                //FY25SR-2244 end
              }
            }
          }
          else {
            optionData[i].selected = true;
          }
        }
      }
    }
    this.value = value;
    this.values = values;
    this.optionData = optionData;
  }

  filterOptionsHandler(event) {
    this.searchString = event.target.value;
    if (!this.searchString || this.searchString == '' || (this.searchString && this.searchString.length >=2 )){
      this.filterOptions();
    }
  }

  filterOptions(){
    console.log('filterOptions() ', JSON.stringify(this.searchString),' | ', JSON.stringify(this.filterAttrs));
    let searchString = this.searchString;
    let filterAttrs = this.filterAttrs;
    this.noResultMessage = '';

    for (var i = 0; i < this.optionData.length; i++) {
      let option = this.optionData[i];
      option.isVisible = true;

      if (searchString && searchString.length >= 2 && !option.label.toLowerCase().trim().startsWith(searchString.toLowerCase().trim())) {
        option.isVisible = false;
      }
      
      if (option.isVisible && filterAttrs && filterAttrs.length > 0){
        for (let filterAttr of filterAttrs){
          if (option[filterAttr.key] != filterAttr.value){
            option.isVisible = false;
          }
        }
      }
    }
  }

  selectItem(event) {
    var selectedVal = event.currentTarget.dataset.id;
    var options = JSON.parse(JSON.stringify(this.optionData));

    if (selectedVal && selectedVal == 'select_all'){
      this.values = [];
      for (let option of options){
        option.selected = true;
        this.values.push(option.value);
      }

      let eventDetails = {
            values : this.values,
            action : 'select all'
      };
      let ev = new CustomEvent('selectoption', { detail: eventDetails });
      this.dispatchEvent(ev);

      this.optionData = options;
    }
    else if (selectedVal) {
      var count = 0;
      let action;
      for (var i = 0; i < options.length; i++) {
        if (options[i].value === selectedVal) {
          if (this.multiSelect) {
            if (this.values.includes(options[i].value)) {
              this.values.splice(this.values.indexOf(options[i].value), 1);
              action = 'remove';
            } else {
              this.values.push(options[i].value);
              action = 'add';
            }
            options[i].selected = options[i].selected ? false : true;
          } 
          else if (this.multiAdd){
            this.values.push(selectedVal);
            //FY25SR-2244 start
            
            let optionExisting = this.selectedMultiAdd.find((option) => {if (option.value === selectedVal) return option});
            if (optionExisting){
              optionExisting.quantity = optionExisting.quantity + 1;
            }
            else {
              let selectedOption = Object.assign({}, options[i]);
              selectedOption.key = this.selectedMultiAdd.reduce((max, option) => {return option.key >= max ? option.key + 1 : max}, 0);
              selectedOption.quantity = 1;
              this.selectedMultiAdd.push(selectedOption);
            }
            //FY25SR-2244 end
            
            action = 'add';
          }
          else {
            this.values = [options[i].value];
            this.value = options[i].value;
            options[i].selected = true;
            action = 'add';
          }
        }
        else if (!this.multiAdd && !this.multiSelect){
          options[i].selected = false;
        }
        if (options[i].selected) {
          count++;
        }
      }
      this.optionData = options;
      let eventDetails = {
        values : this.values,
        value : selectedVal,
        action : action
      };

      if (this.multiSelect || this.multiAdd) {

        let ev = new CustomEvent('selectoption', { detail: eventDetails});
        this.dispatchEvent(ev);

        this.sendAllData(this.optionData);

        //FY25SR-2244 start
        if (this.multiAdd){
          this.showDropdown = false;
        }
        //FY25SR-2244 end
      }
      else {
       // console.log('inside else close pill');
        let eventDetails = {
            values : this.values,
            value : this.value,
            action : action
        };
        let ev = new CustomEvent('selectoption', { detail: eventDetails });
        this.dispatchEvent(ev);
        console.log('event fired');
        this.sendAllData(this.optionData);
        this.showDropdown = false;
      }
    }

    event.preventDefault();
  }

  showOptions() {
    if (this.disabled == false && this._options) {
      this.noResultMessage = '';
      var options = JSON.parse(JSON.stringify(this.optionData));
      this.optionData = options;
      if (options.length > 0) {
        this.showDropdown = true;
      }
    }
  }

  @api clearAll() {
    this.values = [];
    var optionData = this._options ? JSON.parse(JSON.stringify(this._options)) : null;
    for (var i = 0; i < optionData.length; i++) {
      if (this.multiSelect) {
        optionData[i].selected = false;
      }
    }
    this.selectedValues = [];
    this.optionData = optionData;
  }

  closePill(event) {
    var value = event.currentTarget.name;
    var options = JSON.parse(JSON.stringify(this.optionData));

    if (this.multiAdd){
      this.values = this.values.filter(selectedValue => selectedValue != value); //FY25SR-2244
      let index = event.currentTarget.dataset.index;
      this.selectedMultiAdd.splice(index, 1);
    }
    else {
      for (var i = 0; i < options.length; i++) {
        if (options[i].value === value) {
          options[i].selected = false;
          this.values.splice(this.values.indexOf(options[i].value), 1);
        }
      }
      this.optionData = options;
    }
    
    let eventDetails = {
      values : this.values,
      value : value,
      action : 'remove'
    };

    if (this.multiSelect || this.multiAdd) {

      let ev = new CustomEvent('selectoption', { detail: eventDetails });
      this.dispatchEvent(ev);

      this.sendAllData(this.optionData);
    }else {
        let eventDetails = {
            values : this.values,
            value : this.value,
            action : 'remove'
        };
        let ev = new CustomEvent('selectoption', { detail: eventDetails });
        this.dispatchEvent(ev);
        this.sendAllData(this.optionData);
        //this.showDropdown = false;
      }
    /*
    console.log('inside second child pilll'+JSON.parse(JSON.stringify(event.data)));
    var selectedEvent = new CustomEvent('pickchange', { detail:        
                                        JSON.parse(JSON.stringify(this.optionData))});
       // Dispatches the event.
       this.dispatchEvent(selectedEvent);
  */
  }

  handleBlur(event) {
    this.showDropdown = false;
  }

  handleMouseOut() {
    this.showDropdown = false;
  }

  handleMouseIn() {
    this.showDropdown = true;
  }

  sendAllData(optionData) {
    let ev = new CustomEvent('selectoptionall', { detail: optionData });
    this.dispatchEvent(ev);
  }

  handleDropdownClick(event){
    event.preventDefault();
  }

  //FY25SR-2244 added
  handleIncrement(event){
    let index = event.currentTarget.dataset.index;
    let option = this.selectedMultiAdd[index];

    if (!option) return;
    option.quantity ++;
    this.values.push(option.value);

    let eventDetails = {
      values : this.values,
      value : option.value,
      action : 'add'
    };
    this.dispatchEvent(new CustomEvent('selectoption', { detail: eventDetails }));
  }

  //FY25SR-2244 added
  handleDecrement(event){
    let index = event.currentTarget.dataset.index;
    let option = this.selectedMultiAdd[index];

    if (!option) return;
    option.quantity --;

    this.values.splice(this.values.indexOf(option.value), 1);
    
    let eventDetails = {
      values : this.values,
      value : option.value,
      action : 'remove'
    };
    this.dispatchEvent(new CustomEvent('selectoption', { detail: eventDetails }));

    if (option.quantity == 0){
      this.selectedMultiAdd.splice(index, 1);
    }
  }
}