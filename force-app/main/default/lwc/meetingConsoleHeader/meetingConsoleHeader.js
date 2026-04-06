import { LightningElement, track, api } from 'lwc';
export default class MeetingConsoleHeader extends LightningElement {

    @api
    get recordList(){
        return this._recordList;
    }
    @api headertitles;
    @api dashboard;
    
    @track _recordList;
    @track clonedHeaderTitles;

    set recordList(value){
        if(this.headertitles !== undefined){
            this.clonedHeaderTitles = JSON.parse(JSON.stringify(this.headertitles));
            let lengthOfHeader = this.clonedHeaderTitles.length;
            for(let i = 0; i < lengthOfHeader; i++){
                this.clonedHeaderTitles[i].count = 0; 
            }
            this._recordList = value;
            this._recordList.forEach(item =>{
                for(let i = 0; i < this.clonedHeaderTitles.length; i++){
                    if(this.dashboard === 'Disposition'){
                        if(this.clonedHeaderTitles[i].id == 'total'){
                            this.clonedHeaderTitles[i].count++;
                        }
                        if(item.outcome != undefined && item.outcome.includes('Opportunity Sourced') && !item.outcome.includes('No Opportunity Sourced')){
                            if(this.clonedHeaderTitles[i].id == 'opportunitySourced'){
                                this.clonedHeaderTitles[i].count++;
                            }
                        }
                        if(item.outcome != undefined && item.outcome.includes('No Opportunity Sourced')){
                            if(this.clonedHeaderTitles[i].id == 'noOpportunitySourced'){
                                this.clonedHeaderTitles[i].count++;
                            }
                        }
                        if(item.outcome != undefined && item.outcome.includes('Meeting Cancelled')){
                            if(this.clonedHeaderTitles[i].id == 'cancelled'){
                                this.clonedHeaderTitles[i].count++;
                            }
                        }
                        let activity_Date = new Date(item.activityDateClr);
                        if(activity_Date.toJSON().slice(0, 10) >= new Date().toJSON().slice(0, 10)){
                            if(this.clonedHeaderTitles[i].id == 'upcoming'){
                                this.clonedHeaderTitles[i].count++;
                            }
                        }
                        if(activity_Date.toJSON().slice(0, 10) < new Date().toJSON().slice(0, 10) && 
                            (item.outcome == undefined || (item.outcome != undefined && !item.outcome.includes('Opportunity Sourced') && !item.outcome.includes('No Opportunity Sourced') && !item.outcome.includes('Meeting Cancelled')))){
                                if(this.clonedHeaderTitles[i].id == 'pastDue'){
                                    this.clonedHeaderTitles[i].count++;
                                }
                        }
                    }
                    if(this.dashboard === 'Categorization'){
                        if(this.clonedHeaderTitles[i].id == 'total'){
                            this.clonedHeaderTitles[i].count++;
                        }
                        if(item.meetingCategory != undefined){
                            if(this.clonedHeaderTitles[i].id == 'tagged'){
                                this.clonedHeaderTitles[i].count++;
                            }
                        }else{
                            if(this.clonedHeaderTitles[i].id == 'untagged'){
                                this.clonedHeaderTitles[i].count++;
                            }
                        }
                    }
                }
            })        
        }   
    }     
}