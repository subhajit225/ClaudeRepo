import { LightningElement,wire } from 'lwc';
import getUserAccessToThePage from '@salesforce/apex/MeetingCategorizationController.getUserAccessToThePage';


export default class MeetingConsoleTabset extends LightningElement {
    
    _isUserCanAccess = false;
    _isUserCanNotAccess = false;
    connectedCallback(){
        getUserAccessToThePage()
        .then(result =>{
            if(result){
                this._isUserCanAccess = result;
            }else{
                this._isUserCanNotAccess = true;
            }
        })
        .catch(error =>{
            this._isUserCanNotAccess = true;
        })
    }

}