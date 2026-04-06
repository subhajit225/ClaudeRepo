import { LightningElement, api } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';

export default class SU_AuthKnowledgeGraph extends LightningElement {
    @api knowledgeGraph;
    @api knowledgeGraphMetaGraph;
    @api knowledgeGraphRelatedTiles;
    @api metaGraph;
    @api relatedTiles;
    @api translationObject;
    @api knowledgeGraphResponseRecorded;
    @api searchQueryData;

    sendknowledgeGraphFeedback(event) {
        var feedback = event.currentTarget.dataset.feedback;
        fireEvent(null, 'trackAnalytics', {
            type: 'knowledgeGraph', objToSend: {
                "searchString": this.searchQueryData.searchString,
                "url": this.metaGraph.link,
                "t": this.metaGraph.title||this.metaGraph.link,
                "uid": this.searchQueryData.uid,
                "feedback": feedback,
                "referrer": this.searchQueryData.referrer,
            }
        });
        this.knowledgeGraphResponseRecorded = true;
    }

    connectedCallback() {
        this.knowledgeGraphResponseRecorded = false;
        registerListener("knowledgeGraphMetaGraphDatafunc", this.knowledgeGraphMetaGraphDatafun, this);
    }

    disconnectedCallback() {
        unregisterListener("knowledgeGraphMetaGraphDatafunc", this.knowledgeGraphMetaGraphDatafun, this);
    }

    knowledgeGraphMetaGraphDatafun(value) {
        this.knowledgeGraphResponseRecorded = value;
    }

}