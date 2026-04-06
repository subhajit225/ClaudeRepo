import { LightningElement, api, track, wire } from 'lwc';
import RelatedCaseDetails from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseDetails';

export default class SU_CaseOverview extends LightningElement {
    @api endPoint;
    @api uid;
    @api token;
    @api caseId;
    @api maincontainerwidth;
    sentimentScore;
    sentimentType;
    sentimentSentences;
    pointerClass = 'bubble';

    connectedCallback() {
        RelatedCaseDetails({'sCaseId':this.caseId}).then(result => {
            this.getCaseSentiments(result);
            this.sectionName = 'Overview';
        }).catch(error => {
            console.log(error);
        });
    }

    renderedCallback() {
        const allRanges = this.template.querySelectorAll(".range-wrap") || [];
        console.log("allRanges ",allRanges);
        allRanges.forEach(wrap => {
            const range = wrap.querySelector(".range");
            const bubble = wrap.querySelector(".bubble");
        
            range.addEventListener("input", () => {
                this.setBubble(range, bubble);
            });
            this.setBubble(range, bubble);
        });
    }

    setBubble(range, bubble) {
        const val = range.value;
        const min = range.min ? range.min : -1;
        const max = range.max ? range.max : 1;
        const newVal = Number((100 * (val - min)) / (max - min)).toFixed(2);
        console.log("newVal: ", newVal);
        console.log("val: ", val);
        bubble.innerHTML = val; 
        bubble.style.left = `calc(${newVal}% + (${8 - newVal * 0.15}px))`;
    } 

    getCaseSentiments(relatedCase) {
        let caseComments = [];
        if (relatedCase.Comments) {
            let c = JSON.parse(relatedCase.Comments || '[]');
            caseComments = c.map(f => f.CommentBody);
        }
        var data = JSON.stringify({
            "uid": this.uid,
            'case': {
                'Id': this.caseId,
                'description': relatedCase.Description ?? '',
                'title': relatedCase.Subject ?? '',
                'comments': caseComments
            }
        });

        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/agentHelper/case-sentiments";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    this.sentimentScore = result.overall_sentiment;
                    this.sentimentType = result.sentiment_name;
                    this.sentimentSentences = result.metadata_sentiment;
                    this.sentimentSentences.forEach(f => {

                        let start = 0;
                        let end = 0;
                        f.sentenceHtml = `<span class='sentiment-sentence'>`;
                        f.sentiment_keywords.forEach((r, i) => {
                            r.start_index = end > r.start_index ? end : r.start_index;
                            f.sentenceHtml = f.sentenceHtml + f.sentence.slice(end,r.start_index) 
                                + `<span class='sentiment-${r.token_sentiment.toString().toLowerCase()}'>${f.sentence.slice(r.start_index, r.end_index)}</span>`;
                            start = r.start_index;
                            end = r.end_index;
                        });
                        f.sentenceHtml += f.sentence.slice(end) + `</span>`;
                    });
                    this.pointerClass = (this.sentimentScore || 0) > 0.25 
                        ? 'bubble positive-bubble' 
                        : ( (this.sentimentScore || 0) < -0.25 
                            ? 'bubble negative-bubble'
                            : 'bubble' );
                    var myDiv = this.template.querySelector('ul.sentiment-list');
                    myDiv.scrollTop = 0;

                }
            }
        }
        xmlHttp.send(data);
    }

    refreshCaseSentiment(){
        RelatedCaseDetails({'sCaseId':this.caseId}).then(result => {
            this.getCaseSentiments(result);
        }).catch(error => {
            console.log(error);
        });
    }
}