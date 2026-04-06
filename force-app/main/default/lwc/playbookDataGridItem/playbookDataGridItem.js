import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import deleteTask from '@salesforce/apex/PlaybookDataGridController.deleteTask';
import { encodeDefaultFieldValues } from 'lightning/pageReferenceUtils';


export default class PlaybookDataGridItem extends NavigationMixin(LightningElement) {
    checklistToDeleteName;
    checklistToDeleteId;
    isChecklistDeletionModalOpen=false;
    @api playbookId;
    @api subtasks;
    @api hasSubTasks;
    get subTaskCompletionPercentage() {
        const compeletionStat = 'N/A';
        if (st.completion_percentage__c) {
            compeletionStat = st.completion_percentage__c + '% Complete'
        }
        return compeletionStat
    }

    handleAction(event) {
        const id = event.target.dataset.id;

        switch (event.target.dataset.action) {
            case 'navigateToRecordDetailPage':
                this.navigateToRecordPage(id, 'view');
                break;
            case 'edit':
                this.navigateToRecordPage(id, 'edit');
                break;
            case 'deleteconfirmation':
                this.isChecklistDeletionModalOpen = true;
                this.checklistToDeleteId = id;
                this.checklistToDeleteName = event.target.dataset.name;
                //this.delete(id);
                break;
            case 'delete':
                this.delete(this.checklistToDeleteId);
                break;
            case 'closeChecklistDeletionModal':
                this.closeCheckListModal();
                break;
            case 'new_checklist':
                let defaultValues = encodeDefaultFieldValues({
                    Sub_Task__c: id,
                });
                this.navigateToNewRecord('Checklist__c', defaultValues);
                break;
            case 'new_subtask':
                let defaultValues2 = encodeDefaultFieldValues({
                    Playbook__c: this.playbookId,
                });
                this.navigateToNewRecord('Sub_Task__c', defaultValues2);
                break;
            default: break;
        }
    }
    closeCheckListModal() {
        this.checklistToDeleteId = undefined;
        this.checklistToDeleteName = undefined;
        this.isChecklistDeletionModalOpen = false;
    }
    delete(recordId) {
        if (!recordId) {
            this.showToast("Error deleting record", "Please contact your Administrator", "error");
        }

        this.requestDataLoading(false);
        deleteTask({ recordId: recordId })
            .then(() => {
                this.showToast("Success", "Record deleted", "success");
                this.requestDataRefresh();
                this.closeCheckListModal();
            })
            .catch((error) => {
                this.showToast("Error deleting record", error.body.message, "error");
                this.requestDataLoading(true);
            });
    }

    navigateToRecordPage(id, actionName) {
        const pageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: id,
                actionName: actionName
            },

        };
        this[NavigationMixin.Navigate](pageRef);
    }

    navigateToNewRecord(objectApiName, defaultValues)
    {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: objectApiName,
                actionName: 'new'
            },
            state: {
                defaultFieldValues: defaultValues
            }
        });
    }

    requestDataRefresh() {
        this.dispatchEvent(new CustomEvent('refreshview'));
    }
    requestDataLoading(isLoaded) {
        this.dispatchEvent(new CustomEvent('requestloading', {
            detail: {
                isLoaded: isLoaded
            }
        }));
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