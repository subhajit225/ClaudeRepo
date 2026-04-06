import { LightningElement, track, api } from 'lwc';
import getPlaybookTemplates from '@salesforce/apex/PlaybookTemplatesController.getPlaybookTemplates';
import createPlayBookRecords from '@salesforce/apex/PlaybookTemplatesController.createPlayBookRecords'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
        { label: '', type: 'checkbox', fieldName: 'isSelected', sortable: false },
        { label: 'Playbook Template Name', fieldName: 'Name', sortable: true },
    ];

const Screen = {
  TEMPLATE: 0,
  TITLE: 1
}
export default class PlayBookTemplates extends LightningElement {
    @api recordId;
    @track selectedTemplate;
    templateOptions = [];    
    columns = COLUMNS;
    isModalOpen = false;
    isLoading = true;
    @track searchTerm = '';
    title = '';
    currentScreen = Screen.TEMPLATE;

    get isTemplateScreen(){
        return this.currentScreen == Screen.TEMPLATE;
    }

    get isTitleScreen(){
        return this.currentScreen == Screen.TITLE;
    }

    get filteredTemplateOptions() {
        if (this.searchTerm === '') {
            return this.templateOptions;
        } else {
            return this.templateOptions.filter(item => item.Name.toLowerCase().includes(this.searchTerm.toLowerCase()));
        }
    }

    get isLoadingArray(){
        const itemCount = this.templateOptions.length || 5;
        return Array.from({ length: itemCount }, (_, index) => ({
            id: index + 1,
            label: `Item ${index + 1}`
        }));

    }

    get selectedTemplateName(){
        if(this.selectedTemplate){
            return this.templateOptions.find(item => item.Id == this.selectedTemplate).Name
        }
        else {
            return '';
        }
    }

    get isNextDisabled() {
        return !Boolean(this.selectedTemplate);
    }
    
    get isSaveDisabled() {
        return !Boolean(this.selectedTemplate && this.title);
    }
    
    connectedCallback() {
        this.fetchData();
    }

    openModal() {
        this.fetchData();
        this.isModalOpen = true;
    }
    
    closeModal() {
        this.reset();
        this.isModalOpen = false;
    }
    reset(){
        this.templateOptions = [];
        this.selectedTemplate = '';
        this.searchTerm='';
        this.title='';
        this.currentScreen = Screen.TEMPLATE;
    }
    handleAction(event) {
        const value = event.target.value;
        switch (event.target.dataset.action) {
            case 'search':
                this.searchTerm = value;
                break;
            case 'previous':
                this.currentScreen = Screen.TEMPLATE
                break;
            case 'next':
                this.currentScreen = Screen.TITLE;
                this.isLoading = true;
                break;
            case 'save':
                if (this.selectedTemplate) {
                    this.isLoading = true;
                    this.handleCreate();
                }
                break;
            case 'cancel':
                this.closeModal();
                break;
            case 'titlechange':
                this.title = value;
            break;
            default:
                break;
        }
    }
    
    fetchData() {
        this.isLoading = true;

        getPlaybookTemplates()
            .then(data => {
                this.isLoading = false;
                this.templateOptions = data.map(template => ({
                    isSelected: false,
                    Name: template.Name,
                    Id: template.Id
                }));
            })
            .catch(error => {
                this.isLoading = false;
                this.error = error;
                console.error('Error fetching playbook templates:', error);
            });
    }

    handleTemplateChange(event) {
        this.selectedTemplate = event.target.getAttribute('data-id');
        this.templateOptions = this.templateOptions.map(item => 
            item.Id === this.selectedTemplate
            ? { ...item, isSelected: event.target.checked } 
            : { ...item, isSelected: !event.target.checked }
        );
    }

    handleLoad(event) {
        this.isLoading = false;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    handleCreate() {
        createPlayBookRecords({ templateId: this.selectedTemplate, title:this.title, accountId: this.recordId })
            .then(() => {
                this.isLoading = false;
                this.showToast('Success', 'Playbook records created successfully.', 'success');
                this.closeModal();  
                eval("$A.get('e.force:refreshView').fire();");
                this.requestDataRefresh();              
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'An error occurred while creating playbook records.', 'error');
                console.error('Error creating playbook records:', error);
            });
    }
    requestDataRefresh() {
        this.dispatchEvent(new CustomEvent('refreshview'));
    }
}