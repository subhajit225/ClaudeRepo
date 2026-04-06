import { LightningElement, track, api, wire } from 'lwc';
import Id from '@salesforce/user/Id';
import { refreshApex } from '@salesforce/apex';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import isCaseClosed from '@salesforce/apex/SU_Knowbler.KCSPublishController.isCaseClosed';
import KnowledgeArticles from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getKnowledgeArticles';
import getKnowledgeArticlesCount from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getKnowledgeArticlesCount';
import getPickListValues from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getPickListValues';
import getImage from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getImage';
import knowblerPubsub from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';

export default class KnowblerArticleList extends LightningElement {
  @track articles = [];

  @api newnumber;

  @api contentHealthSettings;

  @api removeFeedContentList;

  @api flexipageregionwidth;

  @api draftarticlemode;

  @api author;

  @api loadingcard;

  @api uniqueNumber;

  @api llmStatus;

  @api kcsheight;

  @api kcssupport;

  @api language;

  @api isCasePresent;

  @api tabcontent;

  @api activevalue;

  @api casedata;

  @api caseid;

  @api clientSettings;

  @api casenumber;

  @api jwttoken;

  @api endpoint;

  @track fromedit;

  @api tabcontentcreate;

  @api alldatacategories;

  @track caseclosed;

  @api newid;

  @track createArtcleMapping = {};

  @track ispublisharticletab;

  @track displayTitleLoader = false;

  @track displaySummaryLoader = false;

  @track generateSummaryFields= {};

  @api queryobj;

  cardHeight = 350;

  tabsContents;

  tabsContent = [];

  firstTime = true;

  firstTimeHit = false;

  userId = Id;

  @track tabs = [];

  @track pickListValues;

  currentUserEmailId;

  currentUserLanguage;

  @track noLoading = true;

  @track showLoader = false;

  @track recordt;

  doneTypingInterval = 600;

  typingTimer;

  firstTimeAfterCreate = true;

  refreshData;

  fromSearch = false;

  @track fromTab = {
    change: false
  };

  @api showdropdown;

  @api createdarticle;

  @track checkShow;

  @track articleListData = {
    showEditPage: false,
    showDetailPage: false,
    showEditDetailPage: false,
    showConfiguration: false,
    searchText: '',
    showArticlesScreen: true,
    detailArticle: {},
    currentId: '',
    configRecord: [],
    mappingFields: [],
    query: {
      numPerPage: 10,
      offset: 0,
      currentPage: 1,
      tabcontent: 0,
      count: 0,
      fromTab: false
    },
    isedit: false,
    userLanguage: '',
    hitIndex: 2,
    flagForm: '',
    createArtcleMapping: {}
  };

  fromMaxTab = false;

  @api destobj;

  @api
  get articlescreendata() {}

  set articlescreendata(data) {
    if (data) {
      this.articleListData = {};
      this.articleListData = JSON.parse(JSON.stringify(data));
      this.recordt = this.articleListData?.detailArticle?.RecordType?.Name
        ? this.articleListData.detailArticle?.RecordType?.Name
        : 'master';

      this.articleListData.hitIndex++;
      this.fromSearch = true;

                this.fromMaxTab=true;
                if(!this.flexipageregionwidth)
                    this.firstTimeHit=true

                this.firstTime=true

                if(this.flexipageregionwidth)
                {
                    if((this.kcssupport && this.kcssupport.length))
                    this.getCount();
                }
            }
        }

        @api
        checkEditForm(){
            if(this.articleListData.showEditPage)
            {
                this.template.querySelector('c-knowbler-article-creation').checkEditForm();
            }else
            this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{allArticleData:this.articleListData}}));
        }

  @api userlanguage;

  getArticleData(data) {
    this.articleListData.createArtcleMapping = {};
    this.articleListData.createArtcleMapping = data.detail;
    if (!data.detail.flag)
      this.dispatchEvent(
        new CustomEvent('createarticlehome', {
          detail: { allArticleData: this.articleListData }
        })
      );
  }

  @api
  checkArticleCreationFormIsOpen() {
    if (this.articleListData && this.articleListData.showEditPage) {
      knowblerPubsub.fireEvent(
        this.objpageref,
        `actionSwitchShowConfirmationPopup${this.newnumber}`,
        true
      );
    } else {
      knowblerPubsub.fireEvent(
        this.objpageref,
        `actionSwitchKnowblerMode${this.uniqueNumber}`,
        true
      );
    }
  }

  kcsheightfun() {
    if (!this.kcsheight) return;
    const layoutHeight = parseInt(this.kcsheight, 10);
    this.cardHeight = layoutHeight - 154;
    this.cardHeight += 'px';
  }

  @wire(CurrentPageReference) objpageref;

  connectedCallback() {
    this.articleListData.userLanguage = JSON.parse(
      JSON.stringify(this.userlanguage)
    );
    this.articleListData.userLanguage.currentUserLanguage = this.language
      ? this.language
      : this.articleListData.userLanguage.currentUserLanguage;
    if (this.draftarticlemode) {
      this.tabsContent = [
        { label: 'My draft articles', value: 0, count: 0 },
        { label: 'Published articles', value: 1, count: 0 }
      ];
    } else {
      this.tabsContent = [
        { label: 'All draft articles', value: 0, count: 0 },
        { label: 'My draft articles', value: 1, count: 0 },
        { label: 'Published articles', value: 2, count: 0 }
      ];
    }
    if (this.kcssupport && this.kcssupport.length) {
      this.getFields();
      this.getCount();
    }
    if(this.clientSettings && this.clientSettings.attach_to_close_cases === true) {
      this.iscaseclosed();
    }
    knowblerPubsub.registerListener('getmapping', this.sendmapping, this);
    this.articleListData.showConfiguration = !(
      this.kcssupport && this.kcssupport.length
    );
    if (this.articleListData.showConfiguration) {
      this.noLoading = false;
      this.showLoader = false;
    }
  }

  iscaseclosed() {
    isCaseClosed({ caseid: this.caseid })
      .then((result) => {
        this.caseclosed = result;
      })
      .catch((error) => {
        this.error = error;
      });
  }

  sendmapping() {
    this.articleListData.configRecord = this.kcssupport.filter(
      (res) =>
        res?.RecordType ==
          this.articleListData?.detailArticle?.RecordType?.Name && res.active
    );
    if (this.articleListData.configRecord.length) {
      this.articleListData.flagForm = false;
      this.articleListData.configRecord[0].mapping.map((res) => {
        if (res.type == 'file') {
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__Name__s`
          );
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__Length__s`
          );
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__Body__s`
          );
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__ContentType__s`
          );
        } else
          this.articleListData.mappingFields.push(
            `${this.articleListData.configRecord[0].DestinationObject}.${res.name}`
          );
      });
    }

            knowblerPubsub.fireEvent(this.objpageref,'mappingsent',this.articleListData.mappingFields);
        }
        disconnectedCallback()
        {
            this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{allArticleData:this.articleListData,flag:true}}));
        }

        renderedCallback() {

        if(this.newid){
        $(window).on('resize', function(event) {
         var windowSize = $(window).width();
//          if (windowSize) {

//         window.location.reload();

//   }
  });
        }

            if(this.flexipageregionwidth)
            {
            this.kcsheightfun()
            if (this.template.querySelector(".article_card"))
                this.template.querySelector(".article_card").style = `height:${this.cardHeight}`;
            }
            else{
                let height=Math.floor(window.innerHeight/2)+ 'px';
                if (this.template.querySelector(".article_card"))
                this.template.querySelector(".article_card").style = `height:${height}`;
            }
            window.addEventListener('resize',this.changeHeight.bind(this));
        }
        changeHeight()
        {
            if(this.template.querySelector(".article_card") && (!this.flexipageregionwidth))
            {
                let height=Math.floor((window.innerHeight)/2) + 50 + 'px';

            this.template.querySelector(".article_card").style = `height:${height}`;
            }
            if(this.template.querySelector(".article_card") && window.innerHeight <= 500 && (!this.flexipageregionwidth)){
                let height=Math.floor((window.innerHeight)/2) - 50 + 'px';
                this.template.querySelector(".article_card").style = `height:${height}`;
            }

        }

        onChange(event) {
            if (event.target.scrollTop === (event.target.scrollHeight - event.target.offsetHeight) || event.target.scrollTop === (event.target.scrollHeight - event.target.offsetHeight) + 1) {

            }
        }
        async getCount() {

            this.tabsContents = JSON.parse(JSON.stringify(this.tabsContent))
            let dataQuery = { ...this.articleListData.query, ...this.articleListData.userLanguage }

            const promises = this.tabsContents.map(res => {
                dataQuery.tabcontent = res.value;

      return getKnowledgeArticlesCount({
        searchText: this.articleListData.searchText,
        queryi: JSON.stringify(dataQuery),
        type: this.firstTime
          ? Math.floor(Math.random() * 100 + 1)
          : this.articleListData.hitIndex,
        objName: this.destobj,
        draftarticlemode: this.draftarticlemode
      });
    });

    try {
      const results = await Promise.all(promises);
      results.forEach((res) => this.getDataCount(res));
      this.getData();
    } catch (error) {
      console.error('Error:', error);
      this.template
        .querySelector('c-knowbler-modal-component')
        .showError(error);
    }
  }

        getDataCount(result) {
            try {
                if (result.length) {
                    let data = result[0];
                    if (this.firstTime) {
                        this.tabsContents[data.tabcontent].count = data.count;

                        this.tabsContents[data.tabcontent].label = this.tabsContent[data.tabcontent].label + ' (' + data.count + ')';
                        if (data.tabcontent == 0 && !this.fromSearch) {
                            this.changeQuery({ page: data });
                        }
                        if (data.tabcontent == this.tabsContents.length - 1) {
                            this.tabs = [];
                        this.tabs = [...this.tabsContents];

                            this.firstTime = false

                        }
                    } else {
                        this.changeQuery({ page: data });
                    }
                }
            } catch (error) {
                this.template.querySelector('c-knowbler-modal-component').showError(error);

            }

        }


        getData() {

            if(!this.draftarticlemode){
            if(this.articleListData.query.tabcontent == 2) {
                this.ispublisharticletab=true;
            }
            else {
                this.ispublisharticletab=false;
            }
        }
            if(this.draftarticlemode){
                if(this.articleListData.query.tabcontent == 1) {
                    this.ispublisharticletab=true;
                }
                else {
                    this.ispublisharticletab=false;
                }
            }

    if (this.fromSearch) {
      this.changeQuery({ search: 1 });
    }

            KnowledgeArticles({
                searchText: this.articleListData.searchText,
                queryi: JSON.stringify({ ...this.articleListData.query, ...this.articleListData.userLanguage }),
                type:(this.createdarticle && this.firstTimeAfterCreate)?(Math.floor((Math.random() * 100) + 1)):this.articleListData.hitIndex,
                objName:this.destobj,
                exp:this.kcssupport[0].salesforceExperience,
                draftarticlemode:this.draftarticlemode
            }).then(async result => {

                    this.refreshData=result;
                    result=JSON.parse(JSON.stringify(result));
                    this.articleListData.showArticlesScreen = result.length ? true : false;
                    let localStorageValue = localStorage.getItem('TourStatus') ? JSON.parse(localStorage.getItem('TourStatus')) : {};
                    if (!this.articleListData.showArticlesScreen && localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings && localStorageValue[window.btoa(encodeURIComponent(Id))]?.creatorSettings.showSwitchInstructionTooltip !== false) {
                        knowblerPubsub.fireEvent(this.objpageref, "showSwitchTooltip" + this.newnumber, true);
                    }
                let newSet=[];
                result.forEach(ele => {
                    newSet.push(ele.Owner.Id)
                });

                try {
                    const allImages=await getImage({newSet:JSON.stringify(newSet)});
                    if(allImages) {
                        let mapData=[];
                        for (let key in allImages) {
                            mapData.push({SmallPhotoUrl:allImages[key].SmallPhotoUrl, key:key});
                        }
                        result.map(res=>{
                            let indexPhoto=mapData.findIndex(elm=>elm.key==res?.Owner?.Id)
                            if(indexPhoto>-1)
                            res.SmallPhotoUrl=mapData[indexPhoto].SmallPhotoUrl;
                        })
                    }




                } catch(error) {

                    this.template.querySelector('c-knowbler-modal-component').showError(error);
                }
                this.articles = [...result];

                this.noLoading = false;
                this.showLoader=false;

                this.fromSearch=false;
                this.fromMaxTab=false;
                this.firstTimeAfterCreate=false


            }).catch(error => {

                this.template.querySelector('c-knowbler-modal-component').showError(error);
            });

        }

        hanldevaluechange(event) {
            if(this.clientSettings && this.clientSettings.attach_to_close_cases === true) {
                this.iscaseclosed();
            }
            this.activevalue = event.detail.tabcontent;
            // let querystr={...this.articleListData}
            if(!this.firstTimeHit) {
                this.articleListData.query.currentPage = 1;
                this.articleListData.query.offset = 0;
            }
            this.changeQuery({ page: event.detail });
            this.showLoader=true;
            if(this.kcssupport && this.kcssupport.length)
                this.getData();
            this.firstTimeHit = false;
        }

        searchvaluechange(event) {
            if(event.detail && event.detail.length <= 1) {
                return;
            }
            clearTimeout(this.typingTimer);
            this.articleListData.searchText = event.detail;

            this.typingTimer = setTimeout(() => {
                this.showLoader=true;
                this.articleListData.query.currentPage = 1;
                this.articleListData.query.offset = 0;
                this.fromSearch=true;
                this.firstTime=true;
                this.getCount();

            }, this.doneTypingInterval);

        }
        updatePageHandler(event) {
            this.articleListData.query.currentPage = event.detail.records;
            this.articleListData.query.offset = (this.articleListData.query.currentPage - 1) * this.articleListData.query.numPerPage;
            this.showLoader=true;

            if(this.kcssupport && this.kcssupport.length)
                this.getData();
        }

        changeQuery({ page, search } = data) {

            let quertStr = { ...this.articleListData.query }
            if(search){
                quertStr.count = this.tabs[quertStr.tabcontent].count;
                quertStr.tabcontent=quertStr.tabcontent
            }
            if (page) {
                quertStr.count = page.count;
                quertStr.tabcontent =(this.firstTimeAfterCreate)?this.tabcontentcreate:page.tabcontent;
            }
            quertStr.fromTab=false;
            this.articleListData.query = {};
            this.fromTab.change=false;
            this.articleListData.query = { ...quertStr };

        }

        createArticle() {

            this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{language:this.articleListData.userLanguage?.currentUserLanguage,query:this.articleListData.query}}));
        }
        languagevaluechange(event) {
            this.showLoader=true;
            this.articleListData.userLanguage.currentUserLanguage = event?.detail?.records?.value;
            this.articleListData.userLanguage={...this.articleListData.userLanguage};
            this.articleListData.query.currentPage = 1;
            this.articleListData.query.offset = 0;
            this.firstTime = true;
            this.fromSearch=true;

            this.getCount();

        }
        getFields() {

            getPickListValues({
                object_name: this.destobj,
                field_name: 'Language'
            }).then(result => {

                this.pickListValues = JSON.parse(JSON.stringify(result));
            }).catch(error => {

                this.template.querySelector('c-knowbler-modal-component').showError(error);

            });
        }

  managearticle(event) {
    this.articleListData.createArtcleMapping = {};
    this.articleListData.showEditDetailPage = true;
    this.articleListData.currentId = event.detail?.item?.Id;
    this.articleListData.detailArticle = { ...event.detail?.item };
    this.articleListData.mappingFields = [...[]];
    if (
      this.kcssupport.length == 1 &&
      this.kcssupport[0].salesforceExperience == 'Classic'
    ) {
      this.articleListData.configRecord = this.kcssupport;
    } else if (
      this.kcssupport &&
      this.kcssupport.length &&
      this.kcssupport[0].RecordType &&
      this.kcssupport[0].RecordType === 'master' &&
      !this.articleListData.detailArticle?.RecordType?.Name
    ) {
      this.articleListData.configRecord = this.kcssupport;
    } else {
      this.articleListData.configRecord = this.kcssupport.filter(
        (res) =>
          res?.RecordType ==
            this.articleListData.detailArticle?.RecordType?.Name && res.active
      );
    }
    if (this.articleListData.configRecord.length) {
      this.recordt = this.articleListData?.detailArticle?.RecordType?.Name
        ? this.articleListData.detailArticle?.RecordType?.Name
        : 'master';
      this.articleListData.flagForm = false;
      this.articleListData.configRecord[0].mapping.map((res) => {
        if (res.type == 'file') {
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__Name__s`
          );
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__Length__s`
          );
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__Body__s`
          );
          this.articleListData.mappingFields.push(
            `${
              this.articleListData.configRecord[0].DestinationObject
            }.${res.name.replace('__c', '')}__ContentType__s`
          );
        } else
          this.articleListData.mappingFields.push(
            `${this.articleListData.configRecord[0].DestinationObject}.${res.name}`
          );
      });
    } else {
      this.recordt = this.articleListData?.detailArticle?.RecordType?.Name
        ? this.articleListData.detailArticle?.RecordType?.Name
        : 'master';
      this.articleListData.flagForm = true;
    }
    if (event.detail?.isEdit) {
      this.articleListData.isedit = true;
      this.showDetailPage = false;
    } else {
      this.articleListData.isedit = false;
    }
    if (event.detail?.showManage) {
      this.articleListData.showDetailPage = true;
    } else {
      this.articleListData.showEditPage = true;
      this.articleListData.showDetailPage = false;
    }
  }

  hideScreen() {
    this.articleListData.showEditDetailPage = false;
    this.articleListData.showDetailPage = false;
    this.articleListData.showEditPage = false;
    this.firstTimeHit = true;
    this.articleListData.createArtcleMapping = {};
  }

  handleCreateArticleBack(event) {
    this.firstTimeHit = true;
    this.activevalue = '0';
    if (this.articleListData.isedit) {
      this.articleListData.showDetailPage = true;
    } else {
      this.articleListData.showEditDetailPage = false;
    }
    this.articleListData.showEditPage = false;

    this.articleListData.createArtcleMapping = {};
  }

  async handleCreateArticleLeave(event) {
    if (!event.detail) {
      this.articleListData.showEditDetailPage = false;
      this.articleListData.showDetailPage = false;
      this.articleListData.showEditPage = false;
      this.firstTimeHit = true;
    } else {
      this.articleListData.showEditDetailPage = false;
      this.articleListData.showDetailPage = false;
      this.articleListData.showEditPage = false;
      if (event?.detail?.mapping) {
        const mapp = event?.detail?.mapping;
        const allArticles = JSON.parse(JSON.stringify(this.articles));
        const index = allArticles.findIndex(
          (res) => res.Id == event.detail?.Id
        );
        if (index > -1) {
          const ob = mapp.find((ele) => ele.name == 'Title');
          allArticles[index].Title = ob?.value;
          const obb = mapp.find((ele) => ele.name == 'lastModifiedDate');
          allArticles[index].LastModifiedDate = obb.value;
        }
        allArticles.sort((a, b) =>
          b.LastModifiedDate.localeCompare(a.LastModifiedDate)
        );

        this.articles = [...[]];
        this.articles = [...allArticles];
        this.articleListData.hitIndex++;
        refreshApex(this.articles);
        getRecordNotifyChange([{ recordId: event.detail?.Id }]);
        this.articleListData.createArtcleMapping = {};
        this.firstTime = true;
        await this.getCount();
        this.activevalue = event.detail.activevalue;
        this.showLoader = true;
      } else {
        this.showLoader = true;
        this.articleListData.query.currentPage = 1;
        this.articleListData.query.offset = 0;
      }
    }
  }

  gotohome() {
    this.dispatchEvent(new CustomEvent('gotohome'));
  }

  clickRegenrateArticle(event) {
    this.displayTitleLoader = event?.detail?.displayTitleLoader || false;
    this.displaySummaryLoader = event?.detail?.displaySummaryLoader || false;
    this.generateSummaryFields= event?.detail?.generateSummaryFields || {};
    const mappingObjArray = this.kcssupport.filter(
      (res) => res?.RecordType === this.recordt && res.active
    );

    this.dispatchEvent(
      new CustomEvent('createarticle', {
        detail: {
          displayTitleLoader: this.displayTitleLoader,
          displaySummaryLoader: this.displaySummaryLoader,
          generateSummaryFields: this.generateSummaryFields,
          mappingObj: mappingObjArray && mappingObjArray[0]
        }
      })
    );
  }

  @api
  autoGenTitle(data, summaryData, retryPopup) {
    if (this.template.querySelector('c-knowbler-article-creation')) {
      this.template
        .querySelector('c-knowbler-article-creation')
        .autoGenTitle(data, summaryData, retryPopup);
    }
    this.displayTitleLoader = false;
    this.displaySummaryLoader = false;
    Object.keys(this.generateSummaryFields).forEach((field)=>{
      this.generateSummaryFields[field]=false;
    })
  }
}