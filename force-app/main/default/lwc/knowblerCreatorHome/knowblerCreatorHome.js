import { LightningElement, api, track, wire } from 'lwc';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import { getRecord } from 'lightning/uiRecordApi';
import getConfiguration from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getConfiguration';
import getComments from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getAllComments';
import getCurrentCase from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getCurrentCase';
import getsettings from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getsettings';
import Id from '@salesforce/user/Id';
import jQuery224 from '@salesforce/resourceUrl/SU_Knowbler__jQuery224';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class KnowblerCreatorHome extends LightningElement {
  @api showModal;

  @api recordId;

  @api uniqueNumber;

  @track tabsContent = [];

  @api draftarticlemode;

  @api currentcaseid;

  @api previousMap;

  @api isCasePresent;

  @track activevalue = '0';

  @track author;

  @track caseid;

  @track clientSettings;
  @track contentHealthSettings;
  @api flexipageRegionWidth;

  @api kcsHeight;

  @api kcsknowblerheight;

  @api flexi;

  @api isContentHealthActive;

  next = false;

  @track recordtype;

  @api isTrueCreateArticle = false;

  rtflag = false;

  loadingCard = [];

  @track showList = false;

  @track showDropdown;

  @track knoblerSupport;

  @track noLoading = true;

  @track caseData = {};

  @track language;

  @api createdArticle;

  @track tabcontent = 0;

  @track userLanguage;

  @track TourStatus;

  @track createArtcleMapping;

  @track dataCategories;

  @track destobj = '';

  mappingfields = [];

  @track step;

  @track endpoint = '';

  @track uid;

  @track jwttoken;

  @track apierror;

  @track newnumber;

  @track removeFeedContentList;

  @track casenumber;

  @api newid;

  @track displayTitleLoader = false;

  @track displaySummaryLoader = false;
  @track generateSummaryFields={}

  @wire(CurrentPageReference) pagerf;

  errorimage;

  @track llmStatus;

  errormsg = 'There seems a problem in establishing a connection with knowbler';

  errorsubmsg = `We're doing our best and we'll back soon.`;

  constructor() {
    super();
    Promise.all([loadScript(this, jQuery224)]);
  }

  @wire(getRecord, {
    recordId: Id,
    fields: ['User.Email', 'User.LanguageLocaleKey']
  })
  userDetails({ error, data }) {
    if (data) {
      this.author = data.fields.Email.value;
      this.language = data.fields.LanguageLocaleKey.value;
      this.userLanguage = {
        currentUserEmailId: data.fields.Email.value,
        currentUserLanguage: this.language
          ? this.language
          : data.fields.LanguageLocaleKey.value
      };
    } else if (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  connectedCallback() {
    localStorage.setItem("knowbler_maximize", false)
    this.recordId = this.currentcaseid;
    if (this.kcsknowblerheight && this.flexi) {
      this.kcsHeight = this.kcsknowblerheight;
      this.flexipageRegionWidth = this.flexi;
    } else {
      this.kcsHeight = '500';
    }
    this.range(1, 10);
    this.newnumber = Math.floor(Math.random() * 100000 + 1);
    knowblerPubsub.registerListener(
      `caseCommentEvent${this.newnumber}`,
      this.handlecasecomment,
      this
    );
    knowblerPubsub.registerListener(
      `sendviaemail${this.newnumber}`,
      this.handlesendviaemail,
      this
    );
    knowblerPubsub.registerListener(
      `copytoclipboard${this.newnumber}`,
      this.handlecopytoclipboard,
      this
    );
    knowblerPubsub.registerListener(
      `attachtocase${this.newnumber}`,
      this.handleattachtocase,
      this
    );
    knowblerPubsub.registerListener(
      `createarticle${this.newnumber}`,
      this.handlecreatearticle,
      this
    );
    knowblerPubsub.registerListener(
      `createattach${this.newnumber}`,
      this.handlecreateattach,
      this
    );
    knowblerPubsub.registerListener(
      `publishattacharticle${this.newnumber}`,
      this.handlepublishattacharticle,
      this
    );
    knowblerPubsub.registerListener(
      `publishingarticle${this.newnumber}`,
      this.handlepublisharticle,
      this
    );
    knowblerPubsub.registerListener(
      'apierroroccurs',
      this.handleapierror,
      this
    );

    this.TourStatus = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      Object.keys(this.TourStatus).length &&
      (this.TourStatus[window.btoa(encodeURIComponent(Id))]?.status ==
        'Completed' ||
        this.TourStatus[window.btoa(encodeURIComponent(Id))]?.status ==
          'InProgress')
    ) {
      this.tourCompleted();
    }
    this.getUrl();
    this.getCase();
    this.getcustomsettings();
    window.addEventListener('message', this.handleVFResponse.bind(this));
  }

  async getcustomsettings() {
    await getsettings().then((result) => {
      this.endpoint = result.backendurl;
      this.uid = result.uid;
      this.jwttoken = result.token;
      this.errorimage = `${this.endpoint}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/api.svg`;
    });

    await Promise.all([
      loadScript(
        this,
        `${this.endpoint}/kcs-agent/kcs_custom_agent/${this.uid}/kcs-an.js`
      ),
      loadStyle(
        this,
        `${this.endpoint}/kcs-agent/kcs_custom_agent/${this.uid}/kcs.css`
      ),
      loadStyle(
        this,
        `${this.endpoint}/kcs-agent/kcs_custom_agent/resources/css/suCustom.css`
      )
    ]);
  }

  handleVFResponse(message) {
    if (message?.data?.res) {
      this.dataCategories = JSON.parse(JSON.stringify(message.data.res));
    }
  }

  async getCase() {
    try {
      const response = await getCurrentCase({ recordId: this.recordId });
      if (response.length) {
        this.caseData = { ...response[0] };
        this.caseid = this.caseData.Id;
        this.casenumber = this.caseData.CaseNumber;
      }
    } catch (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  async getUrl() {
    try {
      const data = await getConfiguration();
      if (data == 'error') {
        this.knoblerSupport = [];
        this.noLoading = false;
      } else await this.getKcsConfig(data);
    } catch (error) {
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

  async getKcsConfig(data) {
    fetch(data, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': true,
        Authorization: `Bearer ${this.jwttoken}`
      }
    })
      .then((response) => {
        if (response.status != 200) {
          this.apierror = true;
        }

        return response.json();
      })
      .then((repos) => {
        this.clientSettings = repos.serviceDesk;
        this.removeFeedContentList = repos.removeFeedContentList || [];
        this.contentHealthSettings = (repos && repos.contentHealth && repos.contentHealth.serviceDeskUid) ? repos.contentHealth : '';
        this.llmStatus = repos.llmConfig;
        this.knoblerSupport = [...repos.mapping];
        this.knoblerSupport = this.knoblerSupport.filter(
          (res) => res.active == true
        );
        if (this.knoblerSupport && this.knoblerSupport.length)
          this.destobj = this.knoblerSupport[0].DestinationObject;
        this.noLoading = false;

        return new Promise((resolve) => setTimeout(resolve, 0));
      })
      .catch((error) => (this.apierror = true));
  }

  renderedCallback() {
    const fullheight = screen.height;
    if (this.template.querySelector('.layout-body')) {
      this.template.querySelector('.layout-body').style = `height: 510px`;
    }
    if (this.newid)
      this.template.querySelector('.displayHeader').style.display = 'none';

    const heightcreation = Math.floor(parseInt(this.kcsHeight, 10) - 30);

    if (this.flexipageRegionWidth) {
      if (this.template.querySelector('.layout-body-two'))
        this.template.querySelector('.layout-body-two').style =
          `height:${heightcreation}px`;
    } else {
      const height = `${Math.floor(screen.height / 2)}px`;
      if (this.template.querySelector('.layout-body-two'))
        this.template.querySelector('.layout-body-two').style =
          `height:${height}`;
    }
  }

  checkArticleCreationFormIsOpen() {
    if (this.isTrueCreateArticle === true) {
      knowblerPubsub.fireEvent(
        this.objpageref,
        `actionSwitchShowConfirmationPopup${this.newnumber}`,
        true
      );
    } else if (this.template.querySelector('c-knowbler-article-list')) {
      const articleListComponent = this.template.querySelector(
        'c-knowbler-article-list'
      );
      articleListComponent.checkArticleCreationFormIsOpen();
    } else {
      knowblerPubsub.fireEvent(
        this.pagerf,
        `actionSwitchKnowblerMode${this.uniqueNumber}`,
        true
      );
    }
  }

  changeData() {
    this.showDropdown = { show: true };
  }

  closeModal() {
    this.showModal = false;
    this.dispatchEvent(
      new CustomEvent('changeminmaxview', {
        detail: this.showModal
      })
    );
  }

  tourCompleted() {
    this.next = true;
    this.showList = true;
  }

  maxUtility() {
    this.showModal = !this.showModal;
    this.dispatchEvent(
      new CustomEvent('changeminmaxview', {
        detail: this.showModal
      })
    );
  }

  modalClick() {
    localStorage.setItem("knowbler_maximize", !this.showModal)
    localStorage.setItem("knowbler_window_innerheight", window.innerHeight)
    if (this.showList && !this.showModal) {
      this.template.querySelector('c-knowbler-article-list').checkEditForm();
    } else if (this.isTrueCreateArticle && !this.showModal) {
      this.template
        .querySelector('c-knowbler-article-creation')
        .checkEditForm();
    } else {
      this.showModal = !this.showModal;
      this.dispatchEvent(
        new CustomEvent('changeminmaxview', {
          detail: this.showModal
        })
      );
    }
  }

  @api
  maximizeScreen() {
    this.showModal = !this.showModal;
    this.dispatchEvent(
      new CustomEvent('changeminmaxview', {
        detail: this.showModal
      })
    );
  }

  get isEnableNext() {
    return !!this.next;
  }

  get tourScreen() {
    return !this.next;
  }

  filterCaseComment(content) {
    const filterArray = [
      "Hello(\\w+),",
      "Hi(\\w+),",
      "Hello(\\w+).",
      "Hi(\\w+).",
      "Dear(\\w+),"
    ];
    const finalArray = content.map(element => {
      let thread = element.split('--------------- Original Message ---------------');
      element = thread[0];
      const allElements = element.split("\n");
      for (const x in filterArray) {
        const regexPattern = new RegExp(filterArray[x].replace(/\(\\w\+\)/g, "(.*?)\\"));
        for (const y in allElements) {
          if (regexPattern.test(allElements[y])) {
            const filteredEle = allElements[y].replace(regexPattern, '');
            allElements[y] = filteredEle;
          }
        }
        element = allElements.join("\n");
      }
      element = element.replace(/^\s+|\s+$/g, "");

      return element;
    });
  
    return finalArray;
  }


  async getAutoGenTitle(val, mapping) {
    this.previousMap = mapping;
    await this.getCase();
    function uniqueArticleFields(templateData) {
      const titleGenerationConfig = templateData.autoGenConfig.config.find(
        (config) => config.generateType === 'titleGeneration'
      );
      // const summaryGenerationConfig = templateData.autoGenConfig.config.find(
      //   (config) => config.generateType === 'summaryGeneration'
      // );
      
      const nonTitleGenerationConfig = templateData.autoGenConfig.config.filter(
        (configLLM) => configLLM.generateType != 'titleGeneration'
      );
      let nonTitleCaseFields = [];
      nonTitleGenerationConfig.forEach(i=>nonTitleCaseFields.push(...i.caseFields));

      const titleCaseFields = titleGenerationConfig
        ? titleGenerationConfig.caseFields
        : [];
      // const summaryCaseFields = summaryGenerationConfig
      //   ? summaryGenerationConfig.caseFields
      //   : [];

      const uniqueCaseFields = Array.from(
        new Set([...titleCaseFields, ...nonTitleCaseFields])
      );

      return uniqueCaseFields;
    }

    const templateData = JSON.stringify(mapping);
    const parsedData = JSON.parse(templateData);
    const uniqueFields = uniqueArticleFields(parsedData);
    const fieldsData = {};
    if (uniqueFields.includes('caseObject.Comments')) {
      const commentsList = await getComments({ caseID: this.currentcaseid });
      const comments = JSON.parse(JSON.stringify(commentsList));
      comments.sort(
        (a, b) => new Date(b.CreatedDate) - new Date(a.CreatedDate)
      );
      const caseComments = comments.flatMap((item) =>
        [item.CommentBody, item.Body, item.TextBody].filter(
          (content) => content
        )
      );
      const commentField = caseComments.map((comment) => {
        const doc = new DOMParser().parseFromString(
          comment,
          'text/html'
        );
        const filterArray = this.removeFeedContentList;
        const completeContent = doc.body.textContent || '';
        const thread = completeContent.split(
          '--------------- Original Message ---------------'
        );
        let element = thread[0];
        const allElements = element.split('\n');
        for (const x in filterArray) {
          const regexPattern = new RegExp(
            filterArray[x].replace(/\(\\w\+\)/g, '(.*?)\\')
          );
          for (const y in allElements) {
            if (regexPattern.test(allElements[y])) {
              const filteredEle = allElements[y].replace(regexPattern, '');
              allElements[y] = filteredEle;
            }
          }
          element = allElements.join('\n');
        }
        element = element.replace(/^\s+|\s+$/g, '');

        return element;
      });
      fieldsData['caseObject.Comments'] = commentField || [];
      if (fieldsData['caseObject.Comments'].length) {
        fieldsData['caseObject.Comments'] =  this.filterCaseComment(fieldsData['caseObject.Comments']);
      }

    }
    const self = this;
    uniqueFields.forEach(function (field) {
      if (field !== 'caseObject.Comments') {
        const fieldName = field.replace('caseObject.', '');
        fieldsData[field] = self.caseData[fieldName]
          ? self.caseData[fieldName]
          : '';
      }
    });

    const rawdata = {
      data: fieldsData,
      uid: this.uid,
      caseNumber: val,
      selector: mapping.RecordType,
      language: 'english',
      author: this.author,
      regenerateFields: {
        titleGeneration: this.displayTitleLoader
        // summaryGeneration: this.displaySummaryLoader
      }
    };
    Object.keys(this.generateSummaryFields).forEach((field)=>{
      rawdata.regenerateFields[field]=this.generateSummaryFields[field]
    })
    const url = `${this.endpoint}/kcs-anlytics/rest/anlytics/autoGeneratedTitle/getSuggestedTitle`;
    await fetch(url, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        accept: '/',
        'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
        'ngrok-skip-browser-warning': true,
        Authorization: `Bearer ${this.jwttoken}`
      },
      body: JSON.stringify(rawdata)
    })
      .then((response) => response.json())
      .then(async (result) => {
        const titleGenerationPacket = parsedData.autoGenConfig.config.find(
          (item) => item.generateType === 'titleGeneration'
        );
        const titleField = titleGenerationPacket
          ? titleGenerationPacket.field
          : null;

        // const summaryGenerationPacket = parsedData.autoGenConfig.config.find(
        //   (item) => item.generateType === 'summaryGeneration'
        // );
        // const summaryField = summaryGenerationPacket
        //   ? summaryGenerationPacket.field
        //   : null;

        const fieldGenerationPacket = parsedData.autoGenConfig.config.find(
          (item) => item.generateType != 'titleGeneration'
        );
        let generatedFields = []
        Object.keys(fieldGenerationPacket).forEach((packet=>{
          generatedFields.push({[packet]:fieldGenerationPacket[packet].field})
        }))

        const titleValue = parsedData.autoGenConfig.config.find(item => item.field === "Title");

        if (result && result.data && result.data.status && result.data.status !== 200 && (this.llmStatus.type === 0 || this.llmStatus.type === 1)) {
          let autoGeneratedTitle = ( result.data.status === 401 || result.data.message.toLowerCase().includes("authentication") || result.data.message.toLowerCase().includes("incorrect") ) ? "":'API Error';
          
          // let autoGeneratedSummary = ( result.data.status === 401 || result.data.message.toLowerCase().includes("authentication") || result.data.message.toLowerCase().includes("incorrect") ) ? "":'API Error';

          let autogeneratedFields = ( result.data.status === 401 || result.data.message.toLowerCase().includes("authentication") || result.data.message.toLowerCase().includes("incorrect") ) ? "":'API Error';
          let retryPopup =  result.data.status === 429 || result.data.message.toLowerCase().includes("timeout");
          if (this.template.querySelector('c-knowbler-article-creation')) {
            this.template.querySelector('c-knowbler-article-creation').autoGenTitle(autoGeneratedTitle,autogeneratedFields,retryPopup); //need to handel in component KameshR
          }
          if (this.template.querySelector('c-knowbler-article-list')) {
            this.template
              .querySelector('c-knowbler-article-list')
              .autoGenTitle(
                autoGeneratedTitle,
                autogeneratedFields,
                retryPopup
              );
          }
          if (this.template.querySelector('c-knowbler-article-list')) {
            this.template
              .querySelector('c-knowbler-article-list')
              .autoGenTitle(
                autoGeneratedTitle,
                autogeneratedFields,
                retryPopup
              );
          }
          this.displayTitleLoader = false;
          this.displaySummaryLoader = false;
          // Object.keys(this.generateSummaryFields).forEach((field)=>{
          //   this.generateSummaryFields[field]=false;
          // })
          let tempGenerateSummary = { ...this.generateSummaryFields };
          Object.keys(tempGenerateSummary).forEach((field) => {
            tempGenerateSummary[field] = false;
          })
          this.generateSummaryFields = { ...tempGenerateSummary};
        } else if (
          result &&
          result.data &&
          result.data.status &&
          result.data.status !== 200 &&
          (this.llmStatus.type === 4 || this.llmStatus.type === 5)
        ) {
          const autoGeneratedTitle =
            result.data.status === 401 ||
            result.data.message.toLowerCase().includes('authentication') ||
            result.data.message.toLowerCase().includes('incorrect')
              ? ''
              : 'API Error';
          // const autoGeneratedSummary =
          //   result.data.status === 401 ||
          //   result.data.message.toLowerCase().includes('authentication') ||
          //   result.data.message.toLowerCase().includes('incorrect')
          //     ? ''
          //     : 'API Error';
          let autoGeneratedFields = result.data.status === 401 ||
            result.data.message.toLowerCase().includes('authentication') ||
            result.data.message.toLowerCase().includes('incorrect')
              ? ''
              : 'API Error';
              autoGeneratedFields =
                result.data.status === 750
                  ? 'contextLimitReached'
                  : autoGeneratedFields;
          const retryPopup =
            result.data.status === 429 ||
            result.data.status === 500 ||
            result.data.status === 529 ||
            result.data.message.toLowerCase().includes('timeout');
          if (this.template.querySelector('c-knowbler-article-creation')) {
            this.template.querySelector('c-knowbler-article-creation').autoGenTitle(autoGeneratedTitle,autoGeneratedFields,retryPopup);
          }
          if (this.template.querySelector('c-knowbler-article-list')) {
            this.template
              .querySelector('c-knowbler-article-list')
              .autoGenTitle(
                autoGeneratedTitle,
                autoGeneratedFields,
                retryPopup
              );
          }
          if (this.template.querySelector('c-knowbler-article-list')) {
            this.template
              .querySelector('c-knowbler-article-list')
              .autoGenTitle(
                autoGeneratedTitle,
                autoGeneratedFields,
                retryPopup
              );
          }
          this.displayTitleLoader = false;
          this.displaySummaryLoader = false;
          retryPopup
        } else if (
          result.data.suggestions &&
          generatedFields.length == 0
          // !result.data.suggestions[summaryField]
        ) {
          const autoGeneratedTitle =
            result &&
            result.data &&
            result.data.suggestions &&
            result.data.suggestions[titleField]
              ? result.data.suggestions[titleField]
              : '';
          const autoGeneratedFields = '';
          if (this.template.querySelector('c-knowbler-article-creation')) {
            this.template.querySelector('c-knowbler-article-creation').autoGenTitle(autoGeneratedTitle,autoGeneratedFields);
          }
          if (this.template.querySelector('c-knowbler-article-list')) {
            this.template
              .querySelector('c-knowbler-article-list')
              .autoGenTitle(autoGeneratedTitle, autoGeneratedFields);
          }
          this.displayTitleLoader = false;
          this.displaySummaryLoader = false;
          // Object.keys(this.generateSummaryFields).forEach((field)=>{
          //   this.generateSummaryFields[field]=false;
          // })
          let tempGenerateSummary={...this.generateSummaryFields};
        Object.keys(tempGenerateSummary).forEach((field)=>{
          tempGenerateSummary[field]=false;
        })
        this.generateSummaryFields={...tempGenerateSummary};
        } else {
          if (!result.data.suggestions) {
            const autoGeneratedTitle = '';
            const autoGeneratedFields = '';
            const retryPopup = false;
            if (this.template.querySelector('c-knowbler-article-creation')) {
              this.template
                .querySelector('c-knowbler-article-creation')
                .autoGenTitle(
                  autoGeneratedTitle,
                  autoGeneratedFields,
                  retryPopup
                );
            }
            if (this.template.querySelector('c-knowbler-article-list')) {
              this.template
                .querySelector('c-knowbler-article-list')
                .autoGenTitle(
                  autoGeneratedTitle,
                  autoGeneratedFields,
                  retryPopup
                );
            }
            this.displaySummaryLoader = false;
            // Object.keys(this.generateSummaryFields).forEach((field)=>{
            //   this.generateSummaryFields[field]=false;
            // })
            let tempGenerateSummary={...this.generateSummaryFields};
        Object.keys(tempGenerateSummary).forEach((field)=>{
          tempGenerateSummary[field]=false;
        })
        this.generateSummaryFields={...tempGenerateSummary};
            this.displayTitleLoader = false;
          }
          // const summarySuggestions = result.data.suggestions[summaryField];

          
          let fieldsSuggestions = {}; 
          Object.keys(result.data.suggestions).map((i) => { 
            if (i != 'Title') 
              fieldsSuggestions[i]=result.data.suggestions[i]
          })
          // if (typeof summarySuggestions === 'string') {
            const autoGeneratedTitle =
              result &&
              result.data &&
              result.data.suggestions &&
              result.data.suggestions[titleField]
                ? result.data.suggestions[titleField]
                : '';
            // const autoGeneratedSummary =
            //   result &&
            //   result.data &&
            //   result.data.suggestions &&
            //   summarySuggestions
            //     ? summarySuggestions
            //     : '';

            const fieldsGenerated =

              result &&
              result.data &&
              result.data.suggestions &&
              Object.keys(fieldsSuggestions).length >0
                ? fieldsSuggestions
                : '';


            if (this.template.querySelector('c-knowbler-article-creation')) {
              this.template.querySelector('c-knowbler-article-creation').autoGenTitle(autoGeneratedTitle,fieldsGenerated);
            }
            if (this.template.querySelector('c-knowbler-article-list')) {
              this.template
                .querySelector('c-knowbler-article-list')
                .autoGenTitle(autoGeneratedTitle, fieldsGenerated);
            }
            this.displayTitleLoader = false;
            this.displaySummaryLoader = false;
          // Object.keys(this.generateSummaryFields).forEach((field)=>{
            //   this.generateSummaryFields[field]=false;
            // })
            let tempGenerateSummary={...this.generateSummaryFields};
        Object.keys(tempGenerateSummary).forEach((field)=>{
          tempGenerateSummary[field]=false;
        })
        this.generateSummaryFields={...tempGenerateSummary};
          // } else if (typeof summarySuggestions === 'object') {
          //   const problemStatement = summarySuggestions.problem_statement || '';
          //   const resolution = summarySuggestions.resolution || '';
          //   const autoGeneratedTitle =
          //     result &&
          //     result.data &&
          //     result.data.suggestions &&
          //     result.data.suggestions[titleField]
          //       ? result.data.suggestions[titleField]
          //       : '';
          //   const autoGeneratedSummary = `Problem Statement:\n${problemStatement}\n\nResolution:\n${resolution}`;
          //   if (this.template.querySelector('c-knowbler-article-creation')) {
          //     this.template.querySelector('c-knowbler-article-creation').autoGenTitle(autoGeneratedTitle,autoGeneratedSummary);
          //   }
          //   if (this.template.querySelector('c-knowbler-article-list')) {
          //     this.template
          //       .querySelector('c-knowbler-article-list')
          //       .autoGenTitle(autoGeneratedTitle, autoGeneratedSummary);
          //   }
          //   this.displayTitleLoader = false;
          //   Object.keys(this.displaySummaryLoader).forEach((field)=>{
          //     this.displaySummaryLoader=false;
          //   })
          //   // this.displaySummaryLoader = false;
          // }

        }
      })
      .catch((error) => {
        const autoGeneratedTitle = 'API Error';
        let autoGeneratedSummary = 'API Error';
        const retryPopup = false;
        if (error.message === 'Failed to fetch') {
          autoGeneratedSummary = 'contextLimitReached';
        }
        if (this.template.querySelector('c-knowbler-article-creation')) {
          this.template
            .querySelector('c-knowbler-article-creation')
            .autoGenTitle(autoGeneratedTitle, autoGeneratedSummary, retryPopup);
        }
        if (this.template.querySelector('c-knowbler-article-list')) {
          this.template
            .querySelector('c-knowbler-article-list')
            .autoGenTitle(autoGeneratedTitle, autoGeneratedSummary, retryPopup);
        }
        this.displayTitleLoader = false;
        this.displaySummaryLoader = false;
        // Object.keys(this.generateSummaryFields).forEach((field)=>{
          //   this.generateSummaryFields[field]=false;
          // })
          let tempGenerateSummary={...this.generateSummaryFields};
        Object.keys(tempGenerateSummary).forEach((field)=>{
          tempGenerateSummary[field]=false;
        })
        this.generateSummaryFields={...tempGenerateSummary};
      });
  }

  handleRecTypeClick(event) {
    this.displayTitleLoader = false;
    this.displaySummaryLoader = false;
    // Object.keys(this.generateSummaryFields).forEach((field)=>{
          //   this.generateSummaryFields[field]=false;
          // })
          let tempGenerateSummary={...this.generateSummaryFields};
          Object.keys(tempGenerateSummary).forEach((field)=>{
            tempGenerateSummary[field]=false;
          })
          this.generateSummaryFields={...tempGenerateSummary};
    this.createArtcleMapping = {};
    if (event.detail.type) {
      this.rtflag = event.detail.flag;
      this.isTrueCreateArticle = true;
    }
    if (event.detail.rec) {
      this.recordtype = event.detail.rec;
      this.rtflag = event.detail.flag;
      this.isTrueCreateArticle = true;
    }
    if (event.detail.showArticleList) {
      this.rtflag = false;
      this.showList = true;
    }
    if (event.detail.isAutoGenerateTitle) {
      event.detail.mappingObj.autoGenConfig.config.forEach(item => {
        if (item.generateType != "titleGeneration") {
          this.generateSummaryFields[item.generateType] = true;
          this.displaySummaryLoader=true;
        }
        if (item.generateType === "titleGeneration") this.displayTitleLoader = true;
      });
      this.getAutoGenTitle(this.casenumber, event.detail.mappingObj);
    }
  }

  @api handleAutoGenTitle(event) {
    this.displayTitleLoader = event?.detail?.displayTitleLoader || false;
    this.displaySummaryLoader = event?.detail?.displaySummaryLoader || false;//need to look KameshR
    this.generateSummaryFields= event?.detail?.displaySummaryLoader || {};
    if (!event || !event.detail || !event.detail.mappingObj) {
      event = {
        detail: {
          mappingObj: this.previousMap
        }
      };
    }
    const { mappingObj } = event.detail;
    this.getAutoGenTitle(this.casenumber, mappingObj);
  }

  handleCreateArticleLeave(event) {
    this.createArtcleMapping = {};
    this.createdArticle = event?.detail?.mapping;
    this.activevalue = event?.detail?.activevalue;
    this.isTrueCreateArticle = false;
    this.showList = true;
  }

  handleapierror() {
    this.apierror = true;
  }

  handleBackCreateArticle(event) {
    this.createArtcleMapping = {};
    this.isTrueCreateArticle = false;
    if (this.knoblerSupport?.length > 1) this.rtflag = true;
    else this.showList = true;
  }

  range(start, end) {
    this.loadingCard = Array(end - start + 1)
      .fill()
      .map((_, idx) => start + idx);
  }

  createArticleHome(event) {
    if (event.detail?.language) {
      this.rtflag = true;
      this.showList = false;
      this.language = event.detail?.language;
      this.tabcontent = event.detail?.query?.tabcontent;
    } else if (event.detail?.allArticleData) {
      this.articleScreenData = event.detail?.allArticleData;
      this.tabcontent = event.detail?.allArticleData?.query.tabcontent;
      this.activevalue = event.detail?.allArticleData?.query.tabcontent;
      this.language =
        event.detail?.allArticleData?.userLanguage?.currentUserLanguage;
      if (!event.detail?.flag) {
        this.showModal = !this.showModal;
        this.dispatchEvent(
          new CustomEvent('changeminmaxview', {
            detail: this.showModal
          })
        );
      }
    }
  }

  getArticleData(data) {
    this.createArtcleMapping = {};
    this.createArtcleMapping = data.detail;
    if (!data.detail.flag) {
      this.showModal = !this.showModal;
      this.dispatchEvent(
        new CustomEvent('changeminmaxview', {
          detail: this.showModal
        })
      );
    }
  }

  stepChange(event) {
    this.step = event.detail;
  }

  async gotohome() {
    this.showList = false;
    await this.sleep(1000);
    this.showList = true;
  }

  sleep(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  handlecasecomment(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('linkSharingViaCaseComment', {
      caseId: this.recordId,
      id: data.articleid,
      caseNumber: this.caseData.CaseNumber,
      subject: this.caseData.Subject,
      searchString: this.caseData.Subject,
      object: this.destobj,
      url: data.url,
      title: data.title,
      t: data.title,
      author: this.author,
      reference: data.reference,
      resolution: data.resolution
    });
  }

  handlesendviaemail(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('linkSharingViaEmail', {
      caseId: this.recordId,
      id: data.articleid,
      caseNumber: this.caseData.CaseNumber,
      subject: this.caseData.Subject,
      searchString: this.caseData.Subject,
      object: this.destobj,
      url: data.url,
      title: data.title,
      author: this.author,
      reference: data.reference,
      resolution: data.resolution,
      t: data.title
    });
  }

  handlecopytoclipboard(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('copyToClipboard', {
      caseId: this.recordId,
      id: data.articleid,
      subject: this.caseData.Subject,
      caseNumber: this.caseData.CaseNumber,
      searchString: this.caseData.Subject,
      url: data.url,
      title: data.title,
      t: data.title,
      author: this.author
    });
  }

  handleattachtocase(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('attachToCaseComment', {
      searchString: this.caseData.Subject,
      caseId: this.recordId,
      id: data.articleid,
      articleId: data.articlenumber,
      url: data.url,
      t: data.title,
      subject: this.caseData.Subject,
      caseNumber: this.caseData.CaseNumber,
      index: data.index,
      type: this.destobj,
      author: this.author,
      reference: data.reference,
      resolution: data.resolution
    });
  }

  handlecreatearticle(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('kcsSupportArticles', {
      articleId: data.articlenumber,
      id: data.articleid,
      url: data.url,
      caseId: this.recordId,
      subject: this.caseData.Subject,
      caseNumber: this.caseData.CaseNumber,
      articleTitle: data.title,
      articleUrl: data.url,
      author: this.author,
      articleStatus: data.articleStatus,
      t: data.title,
      templateId: data.recordTypeId
    });
  }

  handlecreateattach(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('kcsSupportArticles', {
      articleId: data.articlenumber,
      id: data.articleid,
      url: data.url,
      caseId: this.recordId,
      subject: this.caseData.Subject,
      caseNumber: this.caseData.CaseNumber,
      articleTitle: data.title,
      articleUrl: data.url,
      author: this.author,
      articleStatus: data.articleStatus,
      t: data.title,
      templateId: data.recordTypeId
    });
  }

  handlepublisharticle(data) {
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('kcsSupportArticles', {
      articleId: data.articlenumber,
      id: data.articleid,
      url: `${window.location.origin}/${this.recordId}`,
      caseId: this.recordId,
      subject: this.caseData.Subject,
      caseNumber: this.caseData.CaseNumber,
      articleTitle: data.title,
      articleUrl: data.url,
      author: this.author,
      articleStatus: data.articleStatus,
      t: data.title,
      templateId: data.recordTypeId
    });
  }

  handlepublishattacharticle(data) {
    const mydata = data;
    this.handlepublisharticle(mydata);
    let gza;
    let localGza = typeof gza === 'undefined' ? undefined : gza;
    if (typeof gza === 'undefined') {
      localGza =
        window && window.Sfdc && window.Sfdc.gza
          ? window.Sfdc.gza
          : window && window.gza
            ? window.gza
            : undefined;
    }
    gza = localGza;
    gza('attachToCaseComment', {
      searchString: this.caseData.Subject,
      caseId: this.recordId,
      id: data.articleid,
      articleId: data.articlenumber,
      url: data.url,
      t: data.title,
      subject: this.caseData.Subject,
      caseNumber: this.caseData.CaseNumber,
      type: this.destobj,
      author: this.author,
      reference: data.reference,
      resolution: data.resolution
    });
  }


}