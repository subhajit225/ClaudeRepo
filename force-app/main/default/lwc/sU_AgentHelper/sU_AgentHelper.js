import { LightningElement, api, track, wire } from 'lwc';
import RelatedCaseDetails from '@salesforce/apex/su_vf_console.SUVFConsoleController.getCaseDetails';

export default class SU_AgentHelper extends LightningElement {
    @api endPoint;
    @api uid;
    @api token;
    @api caseId;
    @api height;
    @api maincontainerwidth;
    @api eventCode;
    relatedCaseIds;
    
    @track agentHelperClickFlag = true; // used to toggle Agent Helper component display
    @track sectionName = 'Top Articles';// used to set section name in case toolbar is displayed
    @track clickFlag = false; // used to check whether tab is selected or not
    @track articleTabActive = false; // used to display Knowledge articles component 
    @track relatedCaseTabActive = false// used to display related cases component 
    @track expertsTabActive = false;// used to display experts details component
    @track caseOverview = false;
    //next three variables value is used in case any one tab is selected 
    checkedDiv = false;    
    checkedDivCase = false;
    checkedDivExpert = false;
    checkedDivOverview = false;
    firstLoad = false;
    get agentHelperWidth(){
        return this.maincontainerwidth;
    }
    get agentHelperWidthCss() {
        return 'su__h-100p su__'+this.eventCode;
    }

    //connectedCallback is called on component load to fetch related case ids for the current case
    connectedCallback() {
        this.firstLoad = false;
        RelatedCaseDetails({'sCaseId':this.caseId}).then(result => {
            this.allRelatedCases(result);
            this.checkedDivCase = true;
            // var listSection = this.template.querySelector("section[data-id='tabSection']");
            // listSection.className = 'hideSection';
            var caseSection = this.template.querySelector("section[data-id='cases']");
            caseSection.className = 'showSection su__h-100p';
            this.sectionName = 'Top Related Cases';
        }).catch(error => {
            console.log(error);
        });
    }
    //Method to select a tab and open the selected tab 
    updateOpenTab(event) {
        var flg = event.currentTarget.dataset.flag;
        var tab = event.currentTarget.dataset.tab;
        var secName = event.currentTarget.dataset.section;
        this.checkedDiv = (tab == 'Articles') ? true : false;
        this.checkedDivCase = (tab == 'Cases') ? true : false;
        this.checkedDivExpert = (tab == 'Experts') ? true : false;
        this.checkedDivOverview = (tab == 'Overview') ? true : false;


        var listSection = this.template.querySelector("section[data-id='tabSection']");

        var articleSection = this.template.querySelector("section[data-id='articles']");
        var caseSection = this.template.querySelector("section[data-id='cases']");
        var expertsSection = this.template.querySelector("section[data-id='experts']");
        var overviewSection = this.template.querySelector("section[data-id='case-overview']");

        listSection.className = '';
        listSection.className = 'hideSection';

        articleSection.className = '';
        articleSection.className = (tab == 'Articles') ? 'showSection su__h-100p' : 'hideSection';
        caseSection.className = '';
        caseSection.className = (tab == 'Cases') ? 'showSection su__h-100p' : 'hideSection';

        expertsSection.className = '';
        expertsSection.className = (tab == 'Experts') ? 'showSection su__h-100p' : 'hideSection';

        overviewSection.className = '';
        overviewSection.className = (tab == 'Overview') ? 'showSection su__h-100p' : 'hideSection';
        this.clickFlag = flg;
        this.sectionName = secName;
    }
    //Method used to display initial links that help to open any tab : experts,related cases or Knowledge articles
    setDisplaySectionTab() {
        var listSection = this.template.querySelector("section[data-id='tabSection']");
        var articleSection = this.template.querySelector("section[data-id='articles']");
        var caseSection = this.template.querySelector("section[data-id='cases']");
        var expertsSection = this.template.querySelector("section[data-id='experts']");
        var overviewSection = this.template.querySelector("section[data-id='case-overview']");

        articleSection.className = '';
        articleSection.className = 'hideSection';

        caseSection.className = '';
        caseSection.className = 'hideSection';

        expertsSection.className = '';
        expertsSection.className = 'hideSection';

        overviewSection.className = '';
        overviewSection.className = 'hideSection';

        listSection.className = '';
        listSection.className = 'showSection su__h-100p';
        this.clickFlag = false;
        // this.sectionName = 'Top Articles';

    }
    //Method to fetch related case ids for the current case and set variables to true so that child components can be displayed
    allRelatedCases(relatedCase) {
        var data = JSON.stringify({
            "uid": this.uid,
            'doc': {
                'contactemail': relatedCase.ContactEmail ?? '',
                'createdDate': relatedCase.CreatedDate ?? '',
                'su_vf_console__SearchUnifySessionId__c': relatedCase.su_vf_console__SearchUnify_Session_Id__c ?? '',
                'Id': this.caseId,
                'Description': relatedCase.Description ?? '',
                'Subject': relatedCase.Subject ?? '',
            }
        });

        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/agentHelper/query";
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Authorization', 'bearer ' + this.token);
        xmlHttp.setRequestHeader('Content-Type', 'application/json');

        xmlHttp.onload = () => {

            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    this.relatedCaseIds = result.hits.hits
                        .filter(x => x._source.Id != this.caseId)
                        .map(x => x._source.Id);
                    this.articleTabActive = true;
                    this.relatedCaseTabActive = true;
                    this.expertsTabActive = true;
                    this.caseOverview = true;
                }
            }
        }
        xmlHttp.send(data);
    }
}