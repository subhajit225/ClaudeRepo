import { LightningElement, api, track, wire } from 'lwc';
import createCaseComment from '@salesforce/apex/SU_Knowbler.KCSPublishController.createCaseComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';

export default class KnowblerLinkViaCaseComment extends NavigationMixin(
  LightningElement
) {
  @api caseId;

  @api caseComm;

  @api eventCode;

  @track parent;

  @track checkBoxVal = false;

  @wire(CurrentPageReference) objpageReference;

  handleIndChange(event) {
    this.caseComm = event.target.value;
  }

  headerCheckoxChanged(event) {
    this.checkBoxVal = event.target.checked;
  }

  invokeWorkspaceAPI(methodName, methodArgs) {
    return new Promise((resolve, reject) => {
      const apiEvent = new CustomEvent('internalapievent', {
        bubbles: true,
        composed: true,
        cancelable: false,
        detail: {
          category: 'workspaceAPI',
          methodName,
          methodArgs,
          callback: (err, response) => {
            if (err) {
              return reject(err);
            }

            return resolve(response);
          }
        }
      });

      window.dispatchEvent(apiEvent);
    });
  }

  handleClick() {
    createCaseComment({ caseId: this.caseId, comment: this.caseComm })
      .then((result) => {
        this.message = result;
        this.error = undefined;
        this.result = this.message;

        if (this.message !== undefined) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Success',
              message: 'Case Comment created',
              variant: 'success'
            })
          );
        }
        this.invokeWorkspaceAPI('isConsoleNavigation').then((isConsole) => {
          if (isConsole) {
            this.invokeWorkspaceAPI('getFocusedTabInfo').then((focusedTab) => {
              this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                  recordId: this.caseId,
                  actionName: 'view'
                }
              });
              this.invokeWorkspaceAPI('closeTab', {
                tabId: focusedTab.tabId
              }).then((tabId) => {
                console.log('Solution #2 - SubTab ID: ', tabId);
              });
            });
          }
        });
      })
      .catch((error) => {
        this.error = error;
        let mssg = '';
        if (
          error != '' &&
          error.body != null &&
          error.body.message != undefined &&
          error.body.message != '' &&
          error.body.message != null
        ) {
          mssg = error.body.message;
        } else {
          mssg = this.error;
        }

        if (this.message == undefined) {
          this.dispatchEvent(
            new ShowToastEvent({
              title: 'Error creating record',
              message: mssg,
              variant: 'error'
            })
          );
        }
        this.message = undefined;
      });
  }

  redirection() {
    const url = `${window.location.origin}/lightning/r/Case/${this.caseId}/view`;

    window.open(url, '_self');
  }
}