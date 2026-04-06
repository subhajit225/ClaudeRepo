import { LightningElement, api, track } from 'lwc';

export default class CustomDataTableRow extends LightningElement {
    // Parant cmp params
    @api fld;
    // 2011: picklst values
    @api llStatus = {}

    allowedFormats = [
        'font',
        'size',
        'bold',
        'italic',
        'underline',
        'strike',
        'list',
        'indent',
        'align',
        'link',
        'image',
        'clean',
        'table',
        'header',
        'color',
        'background',
        'code',
        'code-block',
        'script',
        'blockquote',
        'direction',
    ];

    // avoid method call on blur
    isValChange = false

    // render child html on change row value
    _row;
    @api 
    get row(){
        return this._row;
    }
    set row(value){
        this._row = value;
        this.getValue();
    }
    // UI param based on row field type
    value

    @track updateRows = []

    connectedCallback(){
        this.getValue();
    }

    getValue(){
        if(this.fld.fldType == 'REFERENCE'){
            let fldApiName = this.fld.fldApi;
            if(fldApiName.includes('__c')){
                fldApiName = fldApiName.split('__c')[0]+'__r';
            }else if(fldApiName.split('Id')[0]){
                fldApiName = fldApiName.split('Id')[0];
            }
            this.value =  this.row[fldApiName] ? this.row[fldApiName].Name : '';
        }else{
            this.value =  this.row[this.fld.fldApi];
        }
    }

    get isEmail(){
        return this.fld.fldType === 'EMAIL';
    }

    get isString(){
        return this.fld.fldType === 'STRING';
    }

    get isLongTextArea(){
        return this.fld.fldType === 'plaintextarea';
    }

    get isRichTextArea(){
        return this.fld.fldType === 'richtextarea';
    }

    get isReference(){
        return this.fld.fldType === 'REFERENCE';
    }

    get isDate(){
        return this.fld.fldType === 'DATE';
    }

    get isDateTime(){
        return this.fld.fldType === 'DATETIME';
    }

    get isBoolean(){
        return this.fld.fldType === 'BOOLEAN';
    }

    get isPicklist(){
        return this.fld.fldType === 'PICKLIST';
    }

    get isEdit(){
        return (this.row.editable && this.fld.isFldUpdateable);
    }

    @track changeVal
    handleChange(event){
        this.changeVal = event.detail.value;
        console.log('changeVal: ', this.changeVal);
        // console.log('row: ', this.row);
        this.isValChange = true;
    }
    
    handleBlur(){
        if(this.changeVal && this.isValChange){
            this.isValChange = false;
            const editViewEvent = new CustomEvent('changerow', { 
                detail: {
                    val: this.changeVal,
                    row: this.row,
                    fldApi: this.fld.fldApi
                }
            });
            this.dispatchEvent(editViewEvent);
        }
    }
}