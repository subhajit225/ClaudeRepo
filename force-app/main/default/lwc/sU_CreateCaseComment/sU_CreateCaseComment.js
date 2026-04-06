import { LightningElement,api,track } from 'lwc';
import { getFocusedTabInfo, closeTab, focusTab } from 'lightning/platformWorkspaceApi';
import createCaseComment from '@salesforce/apex/su_vf_console.SUVFConsoleController.createCaseComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class SU_CreateCaseComment extends LightningElement {
   
    @api caseId;
    _caseComm;
    @api eventCode;
    @api focusedTabId;
    @api tabId;
    @track parent;
    @track checkBoxVal = false;
    @api
    get caseComm() {
        return this._caseComm;
    }

    set caseComm(value) {
        this._caseComm = value;
    }
  
    errorCallback(error, stack) {
        console.log("-----------error-----------stack-----------", error, stack);
    }

    handleIndChange(event) {
        this._caseComm = event.target.value;
    }
    headerCheckoxChanged(event){
        this.checkBoxVal = event.target.checked;
    }
   
    handleClick() {
        createCaseComment({ caseId : this.caseId,comment:this.caseComm,isPublic: this.checkBoxVal})
            .then(result => {
                this.message = result;
                this.error = undefined;
                this.result = this.message;
                if(this.message !== undefined) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Case Comment created',
                            variant: 'success',
                        }),
                    );
                    getFocusedTabInfo().then((tabInfo) => {
                        closeTab(tabInfo.tabId);
                        focusTab(this.tabId);
                    }).catch(function(error) {
                        console.log(error);
                    });
                }

                // fireEvent(null, 'trackAnalytics'+this.eventCode, {type:'linkSharingViaCaseComment', objToSend: {
                //     caseId: caseId,
                //     id: result._id,
                //     caseNumber: $scope.caseNumber,
                //     subject: $scope.caseSubject,
                //     searchString: $scope.searchString || $scope.caseSubject,
                //     object: result.objName,
                //     url: result.href,
                //     title: result.highlight.TitleToDisplayString.length ? result.highlight.TitleToDisplayString[0] : '',
                //     author: window.user 
                // }});
            })
            .catch(error => {
                console.log(error);
                this.error = error;
                var mssg = ''
                if(error!== '' && error.body != null && error.body.message !== undefined && error.body.message !== '' && error.body.message != null){
                    mssg = error.body.message;
                }else{
                    mssg = this.error;
                }
                if(this.message === undefined){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error creating record',
                            message: mssg,
                            variant: 'error',
                        }),
                    );
                }
                this.message = undefined;
            });
    }
}