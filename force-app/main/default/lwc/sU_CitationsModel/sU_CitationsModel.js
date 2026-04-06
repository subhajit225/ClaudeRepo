import { LightningElement, api,track } from 'lwc';
import { registerListener, unregisterListener,fireEvent } from "c/supubsub";
export default class SU_CitationsModal extends LightningElement {
    @api posXCitationModal;
    @api posYCitationModal;
    @api eventCode;
    @api citationUrl;
    articleLinkObject;
    @api visibility;
    @api buttonHover;
    invisibleHeight;
    citationHref = '';
    citationTitle = '';
    citationDescription = '';
    articleLinkObjectIndex;
    @api diamondPositionX;
    @api diamondPositionY;
    _showCitationModal;
    modalRef;
    @api isDeviceMobile;
  
    @api get showCitationModal() {
        return this._showCitationModal;
    }
    
    resulthits = []
    @api 
    set mergeResultHits(val){
        if(val){
            this.resulthits = val
        }
    }
    
    get mergeResultHits(){
        return this.resulthits;
    }
    
    @track responselistdata = [];
    @api
    set responseListData(value) {
        if (value) {
            try{
                this.responselistdata = JSON.parse(JSON.stringify(value));
            } catch(error){
                console.log(error);
            }
            
        }
    }
    
    get responseListData() {
        return this.responselistdata;
    }
    
    handleScroll(){
       this._showCitationModal = false;
       this.posXCitationModal = 0;
       this.posYCitationModal = 0;
    }

    /**
     * Checks if modal is opened and then dynamically added the class to show the smooth transition of modal
     */
    set showCitationModal(val) {
        this._showCitationModal = val;
        if(val){
            window.addEventListener('scroll', this.handleScroll.bind(this));
        }
    }
    /**
     * Checks and give the css as per mobile view or web view
     */
    get positionCitationModal() {
            return `position:fixed;top:${this.posYCitationModal}px; left:${this.posXCitationModal}px; min-width: 340px;max-width:340px;height : ${this.invisibleHeight}px;
              display: flex;align-items: center;justify-content: center;border-radius: 5px; opacity: 0; transform: translateY(-20px);;animation: ${this.diamondPositionY == "bottom"?'fadeOutTooltip':'fadeIntooltip'} 0.5s ease forwards;z-index:1000`;
    }
    /**
     * Once modal is rendered and then it took the reference of modal and fires and event.
     */
    get invisibleBorder() {
        return "su__invisible_div su__citation_preview ";
    }

    get handleGptPreview() {
        let baseClass = "su__gpt-preview-article-link"
         baseClass += this.visibility === 1 ? ' su__visible' : ' su__invisible';
         return baseClass ; 
    }

    get citaionContainer() {
        return "su__citation_modal_container su__position-relative"
    }

    get articleTitle() {
     return "su__article_title_container su__margin_5 su__position-relative su__z-index-2"
    }

    get titleDimension() {
      return "su__article_title_dimension su__cursor_pointer"
    }
    
    get articleDescContainer() {
        
        const descElement = this.template.querySelector('[data-id="citationDesc"]');
        if (descElement) {
            descElement.innerHTML = this.citationDescription  && this.citationDescription.join('#<span><br>').split('#');
        }
        return "su__article_desc_dimensions su__line_clamp_2 su__position-relative su__z-index-2"
    }
    
    get diamondClass() {
        let classes = 'su__diamond';
    
        if (this.diamondPositionX === 'left') {
            classes += ' su__left_pos_diamond';
        } else {
            classes += ' su__right_pos_diamond';
        }
    
        if (this.diamondPositionY === 'bottom') {
            classes += ' su__top_pos_diamond';
        }
    
        return classes.trim(); 
    }
    
    /**
     * In this we are getting the search result item that matches with the href coming in citations
     * @param null
     */
    renderedCallback() {
        if (this.responselistdata ) {
            this.articleLinkObject = this.responselistdata.find((element, index) => {
                if (element.record.href.includes(this.citationUrl)) {
                    this.articleLinkObjectIndex = index;
                    return true
                }
                return false;
            })
            this.citationHref = this.articleLinkObject && this.articleLinkObject.record &&  this.articleLinkObject.record.href;
            
            this.citationTitle = (this.articleLinkObject 
                && this.articleLinkObject.record 
                && this.articleLinkObject.record.highlight 
                && this.articleLinkObject.record.highlight.TitleToDisplayString 
                && this.articleLinkObject.record.highlight.TitleToDisplayString[0] === '')
                ? this.articleLinkObject.record.href
                : this.articleLinkObject.record.highlight.TitleToDisplayString[0]
            
            
            this.citationDescription = this.articleLinkObject && this.articleLinkObject.record && this.articleLinkObject.record.highlight.SummaryToDisplay;
        }
        
        if( this.citationHref || this.citationTitle ||this.citationDescription ){
            this.setCitationsDivHeight();
        }
    }

    closeCitationModal() {
        window.removeEventListener('scroll', this.handleScroll.bind(this)) 
        fireEvent(null, 'closeCitationModal'+this.eventCode);
    }
    
    setCitationsDivHeight() {
        setTimeout(() => {
            const citationsDiv = this.template.querySelector('div[data-id="citations"]');
            if (citationsDiv) {
                let objToSend = {
                    event: this.buttonHover,
                    setPosition: true,
                    heightModal: citationsDiv.offsetHeight
                };
                this.invisibleHeight = citationsDiv.offsetHeight + 35
                fireEvent(null, 'setPosition'+this.eventCode, objToSend);
            }
        }, 0);
    }
    
    showCitation(){
        fireEvent(null, 'showCitation'+this.eventCode);
        }
        
    runScriptMethod() {
        fireEvent(null, 'trackAnalytics'+this.eventCode, {
            type: 'conversion',
            objToSend: {
                index: this.articleLinkObject && this.articleLinkObject.record.sourceName,
                type: (this.articleLinkObject && this.articleLinkObject.record.objName),
                id: (this.articleLinkObject && this.articleLinkObject.record._id),
                rank: parseInt(this.articleLinkObject && this.articleLinkObjectIndex) + 1,
                convUrl: (this.articleLinkObject && this.articleLinkObject.record.href),
                convSub: this.citationTitle || this.citationHref,
                autoTuned: (this.articleLinkObject && this.articleLinkObject.record.autotuned) ? this.articleLinkObject.record.autotuned : false,
                sc_analytics_fields: (this.articleLinkObject && this.articleLinkObject.record.trackAnalytics) ? this.articleLinkObject.record.trackAnalytics : []
            }
        });
        this.closeCitationModal()
    }
}