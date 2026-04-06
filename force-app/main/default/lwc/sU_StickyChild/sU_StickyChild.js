import { LightningElement, api, track } from 'lwc';
import { fireEvent } from 'c/supubsub';

export default class SU_StickyChild extends LightningElement {
    @api filterType;
    @track seeMore ;
    @api eventCode;
    @track seeLess ;
    @track firstLoad = true;
    @track filterTypeToShowCopy ;
    
    
    get filter(){
         try {
            this.filterTypeToShowCopy = JSON.parse(JSON.stringify(this.filterType));
        } catch (error) { 
            console.error("An error occurred while creating a deep copy:", error)
        }
        const hasMoreThanThreeValues = this.filterTypeToShowCopy.values.length > 3;
        this.seeMore = (this.firstLoad && hasMoreThanThreeValues) ? true : this.seeMore;
        this.seeLess = this.firstLoad ? false : this.seeLess;
        if (!hasMoreThanThreeValues) {
            this.seeMore = false;
            this.seeLess = false;
            this.firstLoad = true;
        }
        else{
            this.firstLoad = false;
        }
        if (hasMoreThanThreeValues && this.seeMore) {
            this.filterTypeToShowCopy.values = this.filterTypeToShowCopy.values.slice(0, 3);
        } 
          return this.filterTypeToShowCopy;
    }
    seeMoreIconHandler() {
        if (this.template.querySelector('.seeMoreIcon')) {
            const seeMoreIcon = this.template.querySelector('.seeMoreIcon');
            let seeMoreIcon1 = seeMoreIcon.getAttribute('data-val');
            this.seeMoreHandler(seeMoreIcon1);
        }
    }
    seeLessIconHandler() {
        if (this.template.querySelector('.seeLessIcon')) {
            const seeLessIcon = this.template.querySelector('.seeLessIcon');
            let seeLessIcon1 = seeLessIcon.getAttribute('data-val');
            this.seeMoreHandler(seeLessIcon1);
        }
    }
    seeMoreHandler(e) {
        if (e.target) {
            var clickedLessMore = e.target.dataset.val;
        }
        if (clickedLessMore === 'less' || e === 'less') {
            this.seeMore = false;
              this.seeLess = true;
              
        } else if (clickedLessMore === 'more' || e === 'more') {
            this.seeMore = true;
              this.seeLess = false;
            }
      }
    removeStickyFilter(event) { 
        let objToSend = {
            contentname: event.target.getAttribute("data-Contentname"),
            label: event.target.getAttribute("data-label"),
            level: event.target.getAttribute("data-level"),
            type: event.target.getAttribute("data-type"),
            immediateParent: event.target.getAttribute("data-immediateParent"),
            path: event.target.getAttribute("data-path") ? JSON.parse(event.target.getAttribute("data-path")) : [],
        }

        fireEvent(this.pageRef, 'removeStickyFacetEvent' + this.eventCode, objToSend);
    
    }
    
}