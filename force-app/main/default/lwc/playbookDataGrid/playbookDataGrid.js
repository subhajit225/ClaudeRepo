import { LightningElement, wire, api, track } from 'lwc';
import getTasksBySubtasks from '@salesforce/apex/PlaybookDataGridController.getTasksBySubtasks';
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class PlaybookDataGrid extends LightningElement {
    @api recordId;
    loaded = false;
    @track taskData;


    connectedCallback() {
        getTasksBySubtasks({ accountId: this.recordId})
        .then((result) => {
            this.loaded = true;
            this.taskData = result;
        })
        .catch((error) => {
            this.loaded = true;
            this.showToast('Error', 'An error occurred while retrieving data', 'error');
        });
    }

    get groupedData() {
        if (!this.taskData) {
            this.notifyDataLoaded(0);
            return [];
        }

        const groupedTasks = new Map();

        this.taskData.forEach(st => {
            if (!groupedTasks.has(st.Playbook__c)) {
                groupedTasks.set(st.Playbook__c, {
                    Id: st.Playbook__r.Id,
                    Name: st.Playbook__r.Name,
                    completion_percentage__c: st.Playbook__r.completion_percentage__c,
                    Total_Sub_Tasks__c: st.Playbook__r.Total_Sub_Tasks__c,
                    Total_Sub_Tasks_Completed__c: st.Playbook__r.Total_Sub_Tasks_Completed__c,
                    hasSubTasks : st.Id ? true : false,
                    subtasks: [],
                });
            }
            groupedTasks.get(st.Playbook__c).subtasks.push(st);
        });
        const data = Array.from(groupedTasks.values());
        this.notifyDataLoaded(data.length);
        return data;
    }
    @api
    handleRefresh(event) {
        this.loaded = false;
        this.connectedCallback();
    }
    
    handleLoading(event){
        this.loaded = event.detail.isLoaded;
    }

    notifyDataLoaded(datalength) {
        this.dispatchEvent(new CustomEvent('dataloaded',{ detail : datalength}));
    }

    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(evt);
    }
}