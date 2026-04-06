import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/supubsub';

export default class SU_NestedFilter extends LightningElement {  
    aggregationsData 
    @track filters;

    @api eventCode;
    @api
    set value(value){
        try {
            this.filters = JSON.parse(JSON.stringify(value));
        } catch (error) {
            console.error("An error occurred while creating a deep copy:", error);
        }
        
        this.setFilters(this.filters);
    }
    @api
    set parent(value){
        this.parentFilter = value;
    }
    get value(){
        return this.filters;
    }
    get parent(){
        return this.parentFilter;
    }
    get defaultFilterCollapseCheckUp_Arrow() {
        return 'arrow-position su__d-block su__cursor'
    }
    get defaultFilterCollapseCheckDown_Arrow() {
        return 'arrow-position su__d-none su__cursor'
    }

    connectedCallback() {
        this.setFilters(this.filters)
    }
    renderedCallback() {
        this.filters.forEach(f => {
            const currentId = f.collapseExampleID;
            const childId = currentId && currentId.split('_icon')[0];
            if (childId) {
                const divTocollapse = this.template.querySelector(`[data-id="${childId}"]`);
                const closeIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOn'}"]`);
                const openIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOff'}"]`);
                if (f.open && closeIcon && openIcon && divTocollapse) {
                    closeIcon.classList.remove('su__d-block');
                    closeIcon.classList.add('su__d-none');
                    openIcon.classList.remove('su__d-none');
                    openIcon.classList.add('su__d-block');
                    divTocollapse.classList.add('child-filters-block');
                    divTocollapse.classList.remove('su__d-none');
                    divTocollapse.classList.add('in');
                }
                else if (divTocollapse && divTocollapse.classList && openIcon && closeIcon) {
                    openIcon.classList.remove('su__d-block');
                    openIcon.classList.add('su__d-none');
                    closeIcon.classList.remove('su__d-none');
                    closeIcon.classList.add('su__d-block');
                    divTocollapse.classList.remove('child-filters-block');
                    divTocollapse.classList.add('su__d-none');
                    divTocollapse.classList.remove('in');
                }
            }
            if (!this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]')) return;
            this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]').checked = f.selected;
            if (f.indeterminate)
                this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]').classList.add('indeterminate');
            else
                this.template.querySelector('[data-econtentname="' + f.encodedContentname + '"]').classList.remove('indeterminate');
        })
    }

    checkCheckbox(event) {
        var sr = {};
        sr.Contentname= event.currentTarget.name;
        sr.immediateParent= event.currentTarget.dataset.min;
        sr.parent= event.currentTarget.dataset.step;
        sr.level= event.currentTarget.dataset.max;
        sr.path = event.currentTarget.dataset.string ? JSON.parse(event.currentTarget.dataset.string) : "";
        sr.checkedProp= event.currentTarget.checked;
        sr.checked= event.currentTarget.checked;
        fireEvent(this.pageRef, 'nestedFilter'+this.eventCode, {filter : sr});
        event.currentTarget.blur();
    }

    setFilters(setArray) {
        this.aggregationsData = setArray;
        for (var i = 0; i < this.aggregationsData.length; i++) { 
            let enName = encodeURIComponent(this.aggregationsData[i].immediateParent + '_' + this.aggregationsData[i].Contentname);
            let stringifiedPathParent =this.aggregationsData[i].path &&  JSON.stringify(this.aggregationsData[i].path)
            Object.assign(this.aggregationsData[i], { 'collapseExampleID': 'collapseExample-' + enName + '_icon' });
            Object.assign(this.aggregationsData[i], { 'collapseExampletoggleIconID': 'collapseExample-' + enName + '_toggleIconOn' });
            Object.assign(this.aggregationsData[i], { 'collapseExampletoggleIconOffID': 'collapseExample-' + enName + '_toggleIconOff' });
            Object.assign(this.aggregationsData[i], { 'collapseExampleEmptyID': 'collapseExample-' + enName });
            Object.assign(this.aggregationsData[i], { 'stringifiedPath': stringifiedPathParent });

            this.aggregationsData[i].childArrayLength = false;
            if (this.aggregationsData[i].childArray && this.aggregationsData[i].childArray.length)
                this.aggregationsData[i].childArrayLength = true;
                this.aggregationsData[i].encodedContentname = enName;
            for (var j = 0; j < this.aggregationsData[i].childArray && this.aggregationsData[i].childArray.length; j++) {
                let stringifiedPath = this.aggregationsData[i] && this.aggregationsData[i].childArray[j] && this.aggregationsData[i].childArray[j].path && JSON.stringify(this.aggregationsData[i].childArray[j].path)
                let enNameChild = encodeURIComponent(this.aggregationsData[i].childArray[j].immediateParent + '_' + this.aggregationsData[i].childArray[j].Contentname);
                Object.assign(this.aggregationsData[i].childArray[j], { 'stringifiedPath': stringifiedPath });
                Object.assign(this.aggregationsData[i].childArray[j], { 'collapseExampleID': 'collapseExample-' + enNameChild + '_icon' });
                Object.assign(this.aggregationsData[i].childArray[j], { 'collapseExampletoggleIconID': 'collapseExample-' + enNameChild + '_toggleIconOn' });
                Object.assign(this.aggregationsData[i].childArray[j], { 'collapseExampletoggleIconOffID': 'collapseExample-' + enNameChild + '_toggleIconOff' });
                Object.assign(this.aggregationsData[i].childArray[j], { 'collapseExampleEmptyID': 'collapseExample-' + enNameChild });
            }
        }
        this.filters = this.aggregationsData;
    }
    collapseFilters(event) {
        var currentId = event.currentTarget.dataset.id;
        var childId = currentId.split('_icon')[0];
        var divTocollapse = this.template.querySelector(`[data-id="${childId}"]`);
        var closeIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOn'}"]`);
        var openIcon = this.template.querySelector(`[data-id="${childId + '_toggleIconOff'}"]`);

        if (divTocollapse.classList.contains('in') && openIcon && closeIcon && divTocollapse) {
            openIcon.classList.remove('su__d-block');
            openIcon.classList.add('su__d-none');
            closeIcon.classList.remove('su__d-none');
            closeIcon.classList.add('su__d-block');
            divTocollapse.classList.remove('child-filters-block');
            divTocollapse.classList.remove('in');
            divTocollapse.classList.add('su__d-none');
        } else if(openIcon && closeIcon && divTocollapse) {
            closeIcon.classList.remove('su__d-block');
            closeIcon.classList.add('su__d-none');
            openIcon.classList.remove('su__d-none');
            openIcon.classList.add('su__d-block');
            divTocollapse.classList.add('child-filters-block');
            divTocollapse.classList.add('in');
            divTocollapse.classList.remove('su__d-none');
        }
    }
}