import { LightningElement, api , track} from 'lwc';
import { fireEvent } from "c/authsupubsub_b6b3_13";
export default class SU_AuthCitationModal extends LightningElement {
    @api posXCitationModal;
    @api posYCitationModal;
    @api mergeResultHits;
    @api citationUrl;
    @api visibility;
    @api buttonHover;
    articleLinkObject;
    invisibleHeight;
    @track citationHref = '';
    @track citationTitle = '';
    @track citationDescription = '';
    articleLinkObjectIndex;
    @api diamondPositionX;
    @api diamondPositionY;
    _showCitationModal;
    modalRef;
    @api isDeviceMobile;
    @api showViewedResults;

    @api get showCitationModal() {
        return this._showCitationModal;
    }
    /**
     * Checks if modal is opened and then dynamically added the class to show the smooth transition of modal
     */
    set showCitationModal(val) {
        this._showCitationModal = val;
    }
    /**
     * Checks and give the css as per mobile view or web view
     */
    get positionCitationModal() {
        if (!this.isDeviceMobile) {
                return `position:fixed;top:${this.posYCitationModal}px; left:${this.posXCitationModal}px; min-width: 454px;max-width: 454px; height : ${this.invisibleHeight}px;
                display: flex;align-items: center;justify-content: center;border-radius: 5px; opacity: 0;transform: translateY(-20px);animation: ${this.diamondPositionY == "bottom"?'fadeOutTooltip':'fadeIntooltip'} 0.5s ease forwards;z-index:35`;
        }
        return `position:fixed;bottom:${this.posYCitationModal}px `;
    }
    /**
     * Once modal is rendered and then it took the reference of modal and fires and event.
     */
    get invisibleBorder() { 
         if (this.isDeviceMobile && this._showCitationModal && this.template.querySelector('.su__citation_preview')) {
            this.modalRef = this.template.querySelector('.su__citation_preview');
            let animationFrameId;
            const timeoutId = setTimeout(() => {
                animationFrameId = requestAnimationFrame(() => {
                    this.modalRef.classList.add('su__transition_in');
                });
            }, 100);
            fireEvent(null, 'modalRef', this.modalRef);
            return "su__fadeIn_animation_mobile su__fix_preview_bottom su__transition_citation"
        }
        return "su__invisible_div su__citation_preview ";
    }

  get handleGptPreview() {
    let baseClass = `${this.showViewedResults} su__gpt-preview-article-link`;
    if (this.isDeviceMobile) {
        baseClass += ' su__fix_preview_bottom su__article_links_mobile_view su__unset_width su__visible';
    } else {
        baseClass += this.visibility === 1 ? ' su__visible' : ' su__invisible';
    }

    return baseClass;
}


    get citaionContainer() {
        return "su__citation_modal_container su__position-relative"
    }

    get articleTitle() {
        if (!this.isDeviceMobile) {
            return "su__article_title_container su__margin_5 su__position-relative su__z-index-2 "
        }
        return "su__article_title_container su__margin_top_15"
    }

    get titleDimension() {
        if (!this.isDeviceMobile) {
            return "su__article_title_dimension su__cursor_pointer"
        }
        return "su__href_mobile su__cursor_pointer"

    }
    
    get articleDescContainer() {
        const descElement = this.template.querySelector('[data-id="citationDesc"]');
        if (descElement) {

            descElement.innerHTML = this.citationDescription && this.citationDescription.join('#<span><br>').split('#');
        }
        return `su__article_desc_dimensions su__line_clamp_2 su__position-relative su__z-index-2 ${this.isDeviceMobile ? 'su__margin_bottom_7':''}`
    }
    
  
    get diamondClass() {
        if(!this.isDeviceMobile){
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
    }
    /**
     * In this we are getting the search result item that matches with the href coming in citations
     * @param null
     */
    renderedCallback() {
        if (this.mergeResultHits.length) {
            this.articleLinkObject = this.mergeResultHits.find((element, index) => {
                if (element.href.includes(this.citationUrl)) {
                    this.articleLinkObjectIndex = index;
                    return true
                }
                return false;
            })
            this.citationHref = this.articleLinkObject && this.articleLinkObject.href;
            this.citationTitle = this.articleLinkObject && this.articleLinkObject.highlight && this.articleLinkObject.highlight.TitleToDisplayString[0].trim().length >= 1 ? this.articleLinkObject.highlight.TitleToDisplayString[0] : this.articleLinkObject && this.articleLinkObject.href;
            this.citationDescription = this.articleLinkObject && this.articleLinkObject.highlight.SummaryToDisplay;
            if( this.citationHref || this.citationTitle ||this.citationDescription ){
                this.setCitationsDivHeight();
            }
        }
    }

    /**
     * Fire event to notify parent to close the modal
     * @param null;
     * 
     */
    closeCitationModal() {
        fireEvent(null, 'closeCitationModal');
    }
     /**
     * Function to handle closing modal on outside click
     * @param null;
     * 
     */
    closeCitationModalOnOutsideClick(event) {
        fireEvent(null, 'closeCitationModalOnOutsideClick', { target: event.target });
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
                this.invisibleHeight = citationsDiv.offsetHeight + 43;
                fireEvent(null, 'setPosition', objToSend);
            }
        }, 0);
    }
     /**
     * Function to run script method and track analytics
     * @param null
     * 
     */
    
    showCitation(){
     fireEvent(null, 'showCitation');
     }
    closeCitationModal() {
      fireEvent(null, 'closeCitationModal')
     }
    runScriptMethod() {
        // Fire event to track analytics, sending relevant data
        fireEvent(null, 'trackAnalytics', {
            type: 'conversion',
            objToSend: {
                // Data to be tracked for analytics
                index: this.articleLinkObject && this.articleLinkObject.index,
                type: (this.articleLinkObject && this.articleLinkObject.type),
                id: (this.articleLinkObject && this.articleLinkObject.recordid),
                rank: parseInt(this.articleLinkObject && this.articleLinkObjectIndex) + 1,
                convUrl: (this.articleLinkObject && this.articleLinkObject.href),
                convSub: this.citationTitle || this.citationHref,
                autoTuned: (this.articleLinkObject && this.articleLinkObject.autotuned) ? this.articleLinkObject.autotuned : false,
                sc_analytics_fields: (this.articleLinkObject && this.articleLinkObject.track) ? this.articleLinkObject.track : []
            }
        });
    }
}