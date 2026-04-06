import { LightningElement,api,track } from 'lwc';

export default class DealDeskUserCommentTile extends LightningElement {

    @api userComment;
    userIds = [];
    userNames = [];
    @track mapData= [];
    //Recipient_Ids__c
    //Recipient_Names__c
     rIds(){
        this.userIds = [];
        if(this.userComment.Recipient_Ids__c!=null)
        this.userIds = this.userComment.Recipient_Ids__c.split(',');
        return this.userIds;
     }
    rNames(){
        this.userNames = [];
        if(this.userComment.Recipient_Names__c!=null)
        this.userNames = this.userComment.Recipient_Names__c.split(',');
        return this.userNames;
    }

     get recipients(){
       var ids = this.rIds();
       var names = this.rNames();
       this.mapData = [];
       if(ids!=null && names!=null){
        for(var key in ids){
            this.mapData.push({value:names[key],key:window.location.origin+"/"+ids[key]});
           }
       }
       console.log(' JSON.stringify map data: '+JSON.stringify(this.mapData))
       return this.mapData;
     }
    
    get createdDate() {
        return new Date(this.userComment.CreatedDate);
    }

    handleClick(event) {
        event.preventDefault();
        const selectEvent = new CustomEvent('select', {
            detail: this.userComment.Id
        });
        this.dispatchEvent(selectEvent);
    }
}