import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import saveElapsedTime from '@salesforce/apex/dDCaseOppDetails.saveElapsedTime'
const FIELDS = [
    'Deal_Desk_Case__c.CreatedDate',
    'Deal_Desk_Case__c.Case_Status__c',
    'Deal_Desk_Case__c.LastModifiedDate',
    'Deal_Desk_Case__c.Time_To_First_Response__c'
];

export default class DealTimer extends LightningElement {
   @api recordId;
    createdDate;
    status;
    savedElapsedTime;
    intervalId;
    elapsedTime = 'Loading...';
    isTimerFrozen = false;
    showTimer = false;
    get timerClass() {
        return this.isTimerFrozen ? 'timer-frozen' : 'timer-running';
    }
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    record({ error, data }) {
       if (data) {
            try{
                const fields = data.fields;
                this.createdDate = fields.CreatedDate?.value ? new Date(fields.CreatedDate.value) : null;
                this.status = fields.Case_Status__c?.value || '';
                this.savedElapsedTime = fields.Time_To_First_Response__c?.value || '';

                if (this.savedElapsedTime) {
                    this.elapsedTime = this.savedElapsedTime;
                    this.isTimerFrozen = true;
                    this.showTimer = true;
                    this.clearRunningTimer();
                    //clearInterval(this.intervalId);
                } else if (this.status !== 'Requested') {
                    const frozen = this.calculateElapsed(new Date());
                    this.elapsedTime = frozen;
                    this.isTimerFrozen = true;
                    this.showTimer = true;
                    //clearInterval(this.intervalId);
                    this.clearRunningTimer();
                    saveElapsedTime({ recordId: this.recordId, elapsedTime: frozen })
                        .then(() => {
                            console.log('Elapsed time saved');
                        })
                        .catch(error => {
                            console.error('Error saving elapsed time:', error);
                        });
                } else {
                    this.showTimer = true;
                    this.startTimer();
                }
            }catch (error) {
                console.error('Safe parsing error:', error);
                this.elapsedTime = 'Error parsing fields';
            }
        } else if (error) {
            this.elapsedTime = 'Error loading data';
        }
    }
     startTimer() {
        this.updateElapsedTime();
        this.intervalId = setInterval(() => {
            this.updateElapsedTime();
        }, 5000);
    }
    updateElapsedTime() {
        this.elapsedTime = this.calculateElapsed(new Date());
    }
    calculateElapsed(toTime) {
        if (!this.createdDate || isNaN(this.createdDate)) {
            return '00:00:00';
        }
        let totalMs = 0;
        let current = new Date(this.createdDate);
        while (current < toTime) {
            const day = current.getDay();
            if (day !== 0 && day !== 6) {
                totalMs += 60000;
            }
            current = new Date(current.getTime() + 60000);
        }
        const hours = String(Math.floor(totalMs / (1000 * 60 * 60))).padStart(2, '0');
        const minutes = String(Math.floor((totalMs / (1000 * 60)) % 60)).padStart(2, '0');
        const seconds = String(Math.floor((totalMs / 1000) % 60)).padStart(2, '0');
        console.log(`${hours}:${minutes}:${seconds}`);
        return `${hours}:${minutes}:${seconds}`;
    }
    clearRunningTimer() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = null;
        }
    }
    disconnectedCallback() {
        this.clearRunningTimer();
    }
}