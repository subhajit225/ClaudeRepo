import { LightningElement, track, api } from 'lwc';

export default class CeMultiSelectPickList extends LightningElement {

    @api options;
    @api selectedValue;
    @api selectedValues;
    @api label;
    @api disabled = false;
    @api multiSelect = false;
    @api name;
    @track value;
    @track values = [];
    @track optionData = [];
    @api searchString = '';

    @track noResultMessage;
    @track showDropdown = false;
    @api eventOnSearch = false;

    @api refresh(name, showOptions) {
        this.connectedCallback();
        if (this.name == name) {
            this._showOptions({ showOptions: showOptions }, false);
        }
    }
    oneTimeCall = false
    connectedCallback() {

        if (this.options) {
            if (!this.oneTimeCall) {
                this.oneTimeCall = true
            } else {
                this.searchString = this.searchString.endsWith('Option(s) Selected') ? '' : this.searchString;
            }

            var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
            var value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
            var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : null;
            if (value || values) {
                var searchString = this.searchString;
                var count = 0;
                for (var i = 0; i < optionData.length; i++) {
                    if (this.multiSelect) {
                        if (values.includes(optionData[i].value)) {
                            optionData[i].selected = true;
                            count++;
                        }
                    } else {
                        if (optionData[i].value == value) {
                            searchString = optionData[i].label;
                        }
                    }
                }
                if (this.multiSelect && !this.searchString && !this.showDropdown)
                    this.searchString = count + ' Option(s) Selected';
                else
                    this.searchString = searchString;
            }

            this.value = value;
            this.values = values;
            this.optionData = optionData;
            this.optionData.sort(this.selectionsAndLabel);
        }
    }

    filterOptions(event) {
        this.searchString = event.target.value;
        if (this.eventOnSearch) {
            this.dispatchEvent(new CustomEvent('search', { detail: { value: this.searchString, name: this.name, keyCode: event.keyCode, showOptions: true } }));
        } else {
            if (this.searchString && this.searchString.length > 0) {
                this.noResultMessage = '';
                if (this.searchString.length >= 2) {
                    var flag = true;
                    for (var i = 0; i < this.optionData.length; i++) {
                        if (this.optionData[i].label.toLowerCase().trim().startsWith(this.searchString.toLowerCase().trim())) {
                            this.optionData[i].isVisible = true;
                            flag = false;
                        } else {
                            this.optionData[i].isVisible = false;
                        }
                    }
                    if (flag) {
                        this.noResultMessage = "No results found for '" + this.searchString + "'";
                    }
                }
                this.showDropdown = true;
            } else {
                this.showDropdown = false;
            }
        }
    }

    selectionsAndLabel(a, b) {
        if (a.selected && !b.selected) {
            return -1;
        } else if (!a.selected && b.selected) {
            return 1;
        }
        const labelA = a.label.toLowerCase();
        const labelB = b.label.toLowerCase();

        if (a.selected && b.selected) {
            // If both selected are true, sort by label
            if (labelA < labelB) {
                return -1;
            } else if (labelA > labelB) {
                return 1;
            }
        }
        return 0;
    }

    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;
        if (selectedVal) {
            var count = 0;
            var options = JSON.parse(JSON.stringify(this.optionData));
            for (var i = 0; i < options.length; i++) {
                if (options[i].value === selectedVal) {
                    if (this.multiSelect) {
                        if (this.values.includes(options[i].value)) {
                            this.values.splice(this.values.indexOf(options[i].value), 1);
                        } else {
                            this.values.push(options[i].value);
                        }
                        options[i].selected = options[i].selected ? false : true;
                    } else {
                        this.value = options[i].value;
                        this.searchString = options[i].label;
                    }
                }
                if (options[i].selected) {
                    count++;
                }
            }
            this.optionData = options;
            this.optionData.sort(this.selectionsAndLabel);

            if (this.multiSelect) {
                let ev = new CustomEvent('selectoption', { detail: { value: this.values, name: this.name } });
                this.dispatchEvent(ev);
            }

            if (!this.multiSelect) {
                let ev = new CustomEvent('selectoption', { detail: { value: this.value, name: this.name } });
                this.dispatchEvent(ev);
            }

            if (this.multiSelect)
                event.preventDefault();
            else
                this.showDropdown = false;
        }
    }
    _showOptions(event, fromOnclick) {

        if (this.disabled == false && this.options) {
            this.noResultMessage = '';
            if(fromOnclick){
                this.searchString = '';
            }
            var options = JSON.parse(JSON.stringify(this.optionData));
            for (var i = 0; i < options.length; i++) {
                options[i].isVisible = true;
            }

            if (options.length > 0 && (event.showOptions == null || event.showOptions == true)) {
                this.showDropdown = true;
            }
            this.optionData = options;
        }

    }
    showOptions(event) {
        this._showOptions(event, true);
    }

    @api clearAll() {
        this.values = [];
        var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
        for (var i = 0; i < optionData.length; i++) {
            if (this.multiSelect) {
                optionData[i].selected = false;
            }
        }
        this.searchString = 0 + ' Option(s) Selected';
        this.selectedValues = [];
        this.optionData = optionData;
    }

    handleBlur() {
        if ( this._cancelBlur) {
            return;
        }
        var previousLabel;
        var count = 0;

        for (var i = 0; i < this.optionData.length; i++) {
            if (this.optionData[i].value === this.value) {
                previousLabel = this.optionData[i].label;
            }
            if (this.optionData[i].selected) {
                count++;
            }
        }

        if (this.multiSelect) {
            this.searchString = count + ' Option(s) Selected';
        } else {
            this.searchString = previousLabel;
        }
        this.showDropdown = false;
        this.dispatchEvent(new CustomEvent('search', { detail: { type:'search', value: '', name: this.name, keyCode: '', showOptions: false } }));
    }
    _cancelBlur = false;

    handleMouseDown(event) {
        this._cancelBlur = true;
    }
    handleMouseUp() {
        this._cancelBlur = false;
        // re-focus to text input for the next blur event 
        this.template.querySelector('lightning-input').focus();
    }
}