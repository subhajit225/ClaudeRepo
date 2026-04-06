import { LightningElement, api, wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getRelatedQuickLinks from '@salesforce/apex/CxRelatedQuickLinksController.getRelatedQuickLinks';

export default class CxRelatedQuickLinks extends NavigationMixin(LightningElement) {
  @api recordId;
  @track relatedRecordLinks;
  @track error;

  get noData(){
    return !(this.relatedRecordLinks && this.relatedRecordLinks.length);
  }
  @wire(getRelatedQuickLinks, { recordId: '$recordId' })
  wiredRelatedCounts({ error, data }) {
      if (data) {
          this.relatedRecordLinks = JSON.parse(JSON.stringify(data));
          this.relatedRecordLinks =  this.relatedRecordLinks.map(link => ({
            ...link,
            title: `${link.label} (${link.count})`
          }));
          this.relatedRecordLinks.sort(this.sortAscending);
          this.error = undefined;
      } else if (error) {
          this.relatedRecordLinks = undefined;
          this.error = error.body.message;
      }
  }

  sortAscending(a, b) {
      if (a.sortOrder === null && b.sortOrder === null) {
          return 0;
      } else if (a.sortOrder === null) {
          return 1;
      } else if (b.sortOrder === null) {
          return -1;
      } else {
          return a.sortOrder - b.sortOrder;
      }
  }

  handleLinkClick(event) {
    event.preventDefault();
    const relationshipApiName = event.target.dataset.relationshipApiName;
    if (relationshipApiName) {
      this.navigateToRelatedList(relationshipApiName);
    }
  }

  navigateToRelatedList(relationshipName) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordRelationshipPage',
      attributes: {
        recordId: this.recordId,
        relationshipApiName: relationshipName,
        actionName: 'view',
      },
    });
  }

  showRelatedListPanel = false;

    showRelatedList() {
        this.showRelatedListPanel = true;
    }

    handleMouseLeave() {
        this.showRelatedListPanel = false;
    }
    

}