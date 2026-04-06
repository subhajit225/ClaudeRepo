import {LightningElement, track} from 'lwc';
import processCsvData from '@salesforce/apex/JiraCSVUploadController.processCsvData';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class CsvToDatatable extends LightningElement {
 parsedData = [];

  @track loadspinner = false;
  @track filename = '';
  @track showfilename = false;
 @track disablebutton = true;
    handleFileUpload(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = this.handleFileLoad.bind(this);
            reader.readAsText(file);
            this.filename = file.name;
            this.showfilename = true;
            this.disablebutton = false;
        }
    }

    handleFileLoad(event) {
        console.log('handleFileLoad');
        const csvData = event.target.result;
        this.parseCsvData(csvData);
    }

     parseCsvData(csvData) {
        // Implement your CSV parsing logic here
        const lines = csvData.split('\n');
        this.parsedData = lines;
        for (let line of lines) {
            const columns = line.split(',');
            console.log('columns___',columns);
            // Process columns or perform desired actions
        }
    }

    sendDataToApex(){
        if (this.parsedData.length > 0) {
            this.loadspinner = true;
            processCsvData({ csvLines: this.parsedData })
                .then(result => {
                    console.log('File Uploaded please check');
                    const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'File Uploaded. Once the Process is Complete we will send you the update over the Email.',
                    variant: 'Success',
                    mode: 'dismissable'
                    });
                    this.dispatchEvent(event);
                    this.loadspinner = false;
                    eval("$A.get('e.force:refreshView').fire();");
                    })

                .catch(error => {
                    this.loadspinner = false;
                });

        }
        else{
                const event = new ShowToastEvent({
                title: 'Toast message',
                message: 'Please Upload the Migration File.',
                variant: 'error',
                mode: 'dismissable'
                });
                this.dispatchEvent(event);
        }
    }
}