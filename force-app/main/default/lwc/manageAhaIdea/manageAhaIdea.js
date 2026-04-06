import { LightningElement, track, wire, api} from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import createIdeaInAha from '@salesforce/apex/ManageAhaIdeaController.createIdeaInAha';
import getAhaRecords from '@salesforce/apex/ManageAhaIdeaController.getAhaRecords';
import getLinkedAhaIdeaRecords  from '@salesforce/apex/ManageAhaIdeaController.getLinkedAhaIdeaRecords';
import getAhaIdeaSelectedRows  from '@salesforce/apex/ManageAhaIdeaController.getAhaIdeaSelectedRows';
import performActionOnAhaIdeaRecord from '@salesforce/apex/ManageAhaIdeaController.performActionOnAhaIdeaRecord';
import AhaIdea from '@salesforce/schema/Aha_Ideas__c';
import Aha_Idea_Name from '@salesforce/schema/Aha_Ideas__c.Name';
import Business_Case_Value from '@salesforce/schema/Aha_Ideas__c.Business_Case_Value__c';
import Create_Proposed_Solution from '@salesforce/schema/Aha_Ideas__c.Creator_Proposed_Solution__c';
import Escalation from '@salesforce/schema/Aha_Ideas__c.Escalation__c';
import For_Workspace from '@salesforce/schema/Aha_Ideas__c.For_Workspace__c';
import Problem_Statement from '@salesforce/schema/Aha_Ideas__c.Problem_Statement__c';
import Product_Area from '@salesforce/schema/Aha_Ideas__c.Product_Area__c';
import Prio_rity from '@salesforce/schema/Aha_Ideas__c.Priority__c';
// import Product_Component from '@salesforce/schema/Aha_Ideas__c.Product_Component_For_Idea_Form__c';
import Strategic_Major_Account from '@salesforce/schema/Aha_Ideas__c.Strategic_Major_Account__c';
import Idea_Description from '@salesforce/schema/Aha_Ideas__c.Idea_Description__c';
import Idea_Category from '@salesforce/schema/Aha_Ideas__c.Idea_Category__c';


const columns = [
  { label: 'Idea_Number', fieldName: 'Aha_Unique_ID__c', type: 'text' },
  { label: 'Title', fieldName: 'Name', type: 'text' },
  { label: 'Description', fieldName: 'Idea_Description__c', type: 'text' },
  {
    type: "button", label: 'View', initialWidth: 100, typeAttributes: {
        label: '',
        name: 'View',
        title: 'View',
        disabled: false,
        value: 'View',
        iconPosition: 'center',
        iconName:'utility:preview',
        variant:'Brand'
    }
  }
];

export default class SearchAhaIdeasComponent extends NavigationMixin(LightningElement) {
  objectApiName = AhaIdea;
  name = Aha_Idea_Name;
  businessfield = Business_Case_Value;
  Proposed_Solution = Create_Proposed_Solution;
  EscalationIdea = Escalation;
  ForWorkspace = For_Workspace;
  ProblemStatement = Problem_Statement;
  ProductArea = Product_Area;
  Priority = Prio_rity;
  // ProductComponent = Product_Component;
  StrategicMajorAccount = Strategic_Major_Account;
  IdeaDescription = Idea_Description;
  IdeaCategory = Idea_Category;

  @api recordId;
  @track isLoading = false;
  @track columns = columns;
  @track tableData = [];
  @track linkedIdeas = [];
  @track inputValue;
  @track  tableDatarefresh = [];
  @track showdiv = false;
  @track showIdeaDataTableForLinkedAhaIdea = false;
  @track showIdeaDataTableForEscalateAhaIdea = false;
  @track loadspinner = false;
  @track opencreateform = false;
  @track showModal = true;
  @track nameval = '';
  @track businessfieldval = '';
  @track Proposed_Solutionval = '';
  @track EscalationIdeaval = '';
  @track ForWorkspaceval = '';
  @track ProblemStatementval = '';
  @track ProductAreaval = '';
  @track Priorityval = '';
  // @track ProductComponentval = '';
  @track StrategicMajorAccountval = '';
  @track IdeaDescriptionval = '';
  @track IdeaCategoryval = '';
  @track IdeaTagsval = '';
  @track showtabset = true;
  @track accountList= [];
  @track showNoResultModal = false;
  @track objrecordId = '';
  myMap = new Map();
  columnsDataTableSession = [];
  linkedAhaIdeatable = [];
  activeTab = '1';
  datarecord =  [];

    handleInputChange(event){
      this.inputValue = event.target.value;
      this.inputvalueforrefresh = event.target.value;
      this.tableData = [];
      this.columnsDataTableSession = [];
      this.objrecordId = this.recordId;
      this.tableDatarefresh = [];
    }

    reCalledSearchMethod(){
      this.tableData =  this.tableDatarefresh;
    }

    @wire(getAhaRecords,{searchTerm:'$inputValue',rcId:'$objrecordId'})
    fetchaharecords({data,error}){
      if(data){
        this.tableData = data;
        this.tableDatarefresh = data;
        if(this.tableData.length>0){
           this.showdiv = true;
           this.showNoResultModal = false;
        }
        else{
            this.showdiv = false;
            this.showNoResultModal = true;
        }
      }
      else if(error){
        this.showToast('Error', error.body.message, 'error');
        this.showdiv = false;
         this.showNoResultModal = false;
      }
    }

    linkIdea(){
      this.loadspinner = true;
      const mapData = new Map();
      var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
      if(selectedRecords.length > 0){
          selectedRecords.forEach(currentItem => {
              mapData.set(currentItem.Aha_Unique_ID__c, this.recordId);
           });
          getAhaIdeaSelectedRows({selectedAhaIdeaRecord : Object.fromEntries(mapData.entries())})
          .then(result => {
            this.showToast('Success', 'Aha Records Linked Successfully', 'success');
            this.loadspinner = false;
            this.dispatchEvent(new CloseActionScreenEvent());
            var recordId = this.recordId;
            if(recordId.startsWith("006")){
                window.location = '/lightning/r/opportunity/' + this.recordId + '/view';
            }
            else if(recordId.startsWith("500")){
              window.location = '/lightning/r/case/' + this.recordId + '/view';
            }

         })
         .catch(error => {
               // Handle error
               this.showToast('Error', error.body.message, 'error');
               this.loadspinner = false;
         });
      }
      else{
          this.showToast('Error', 'Please select the Idea to Link with the Opportunity or Case', 'error');
          this.loadspinner = false;
      }
    }

    openUnlinkAhaIdeaForm(){

      getLinkedAhaIdeaRecords({objectRecordId : this.recordId})
      .then((result) => {
        this.tableData = [];
          if(result.length>0){
              this.tableData =  result;
              this.showIdeaDataTableForLinkedAhaIdea = true;
                this.loadspinner = false;
          }
        else{
          this.showIdeaDataTableForLinkedAhaIdea = false;
          this.loadspinner = false;
        }
      })
      .catch(error => {
            // Handle error
            this.showIdeaDataTableForLinkedAhaIdea = false;
            this.loadspinner = false;
      });

    }// End of method openUnlinkAhaIdeaForm

    // Below code is used to Unlink the Idea Record from Salesforce and Aha
    unlinkedAhaIdeaRecord(){
      this.loadspinner = true;
        const mapData = new Map();
        var selectedRecords =  this.template.querySelector("lightning-datatable").getSelectedRows();
      if(selectedRecords.length > 0){
            selectedRecords.forEach(currentItem => {
                mapData.set(currentItem.Aha_Unique_ID__c, this.recordId);
            });
            performActionOnAhaIdeaRecord({selectedAhaIdeaRecord:Object.fromEntries(mapData.entries()), action : 'Unlink'})
            .then(result => {
              this.showToast('Success', 'Aha Idea Records Unlinked Successfully', 'success');
              this.loadspinner = false;
              this.dispatchEvent(new CloseActionScreenEvent());
          })
          .catch(error => {
                // Handle error
                this.showToast('Error', error.body.message, 'error');
                this.loadspinner = false;
          });
        }
    } // end  of method unlinkedAhaIdeaRecord

  handleActive(event) {
      this.activeTab = event.target.value;
      if(this.activeTab == 1){
         this.reCalledSearchMethod();

      }
       if(this.activeTab == 2){
         this.loadspinner = true;
         this.openUnlinkAhaIdeaForm();
      }
  }

  showToast(title, message, variant){
      const toastEvent = new ShowToastEvent({
          title: title,
          message: message,
          variant: variant
      });
      this.dispatchEvent(toastEvent);
  }

  createNewIdea(){
    this.opencreateform = true;
    this.loadspinner = false;
    this.showtabset = false;
  }

  ideaRecordChangeVal(event) {
    if(event.target.fieldName=='Name'){
       this.nameval = event.target.value;
    }
    if(event.target.fieldName=='Idea_Description__c'){
       this.IdeaDescriptionval = event.target.value;
    }
    if(event.target.fieldName=='Business_Case_Value__c'){
        this.businessfieldval = event.target.value;
    }
    if(event.target.fieldName=='Creator_Proposed_Solution__c'){
        this.Proposed_Solutionval = event.target.value;
    }
    if(event.target.fieldName=='Escalation__c'){
        this.EscalationIdeaval = event.target.value;
    }
    if(event.target.fieldName=='For_Workspace__c'){
        this.ForWorkspaceval = event.target.value;
    }
    if(event.target.fieldName=='Problem_Statement__c'){
        this.ProblemStatementval = event.target.value;
    }
    if(event.target.fieldName=='Product_Area__c'){
        this.ProductAreaval = event.target.value;
    }
    // CS21-3692
    if(event.target.fieldName=='Priority__c'){
        this.Priorityval = event.target.value;
    }
    // if(event.target.fieldName=='Product_Component_For_Idea_Form__c'){
    //     this.ProductComponentval = event.target.value;
    // }
    if(event.target.fieldName=='Strategic_Major_Account__c'){
        this.StrategicMajorAccountval = event.target.value;
    }
    if(event.target.fieldName=='Idea_Category__c'){
       this.IdeaCategoryval = event.target.value;
   }
  }

    handleCreateAhaIdea(){
        if(!this.nameval||!this.ProductAreaval  || !this.IdeaDescriptionval || !this.ProblemStatementval || !this.businessfieldval){
        this.showToast('Error', 'Please fill all the required fields:- Name, Idea Description, Product Area, Product Component, Problem Statement and Business Case/Value', 'error');
        }
        else{
          this.loadspinner = true;
          this.myMap.set("nameval", this.nameval);
          this.myMap.set("BusinessCaseValue", this.businessfieldval);
          this.myMap.set("CreatorProposedSolution", this.Proposed_Solutionval);
          this.myMap.set("Escalation",this.EscalationIdeaval);
          this.myMap.set("ForWorkspace",this.ForWorkspaceval);
          this.myMap.set("ProblemStatement",this.ProblemStatementval);
          this.myMap.set("ProductArea",this.ProductAreaval);
          this.myMap.set("Priority",this.Priorityval);
          // this.myMap.set("ProductComponent",this.ProductComponentval);
          this.myMap.set("StrategicMajorAccount",this.StrategicMajorAccountval);
          this.myMap.set("IdeaDescription",this.IdeaDescriptionval);
          this.myMap.set("Ideaorigin",this.recordId);
          this.myMap.set("IdeaCategory", this.IdeaCategoryval);
          this.myMap.set("ImpactedCustomers", this.ImpactedCustomersval);
          createIdeaInAha({formInputFieldNameAndValues : Object.fromEntries(this.myMap)})
          .then(result => {
              this.showToast('Success', 'Aha Record is Created Successfully', 'success');
              this.loadspinner = false;
              this.dispatchEvent(new CloseActionScreenEvent());
          })
          .catch(error => {
              // Handle error
              this.showToast('Error', error.body.message, 'error');
              this.loadspinner = false;
          });
        }
    }
    handleSuccess(){
        const events = new ShowToastEvent({
        title: 'Success',
        message: 'New Aha Record is Created',
        variant: 'success',
        mode: 'dismissable'
        });
        this.dispatchEvent(events);
        this.isLoading = false;
        // Emptythe input fields
        this.template.querySelectorAll('lightning-input-field').forEach(element => {
        if(element.type === 'checkbox' || element.type === 'checkbox-button'){
            element.checked = false;
        }else{
            element.value = null;
        }
        });
    }

    getSelectedRowDetail(event){
        const row = event.detail.row;
        var ideano = JSON.stringify(row.Aha_Unique_ID__c);
        var newideano = ideano.replace("&0.source=alohaHeader","");
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'Aha_Idea'
            },
            state: {
                    c__recordId: ideano
                }
        }).then(url => {
              window.open(url, "_blank");
          });
    }
}