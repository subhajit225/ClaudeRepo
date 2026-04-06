import { LightningElement, track, api, wire } from 'lwc'; 
    import Id from '@salesforce/user/Id';
    import { refreshApex } from '@salesforce/apex';
    // import My_Resource from '@salesforce/resourceUrl/kcsResources';
    import { getRecord , getRecordNotifyChange } from 'lightning/uiRecordApi';
    import KnowledgeArticles from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getKnowledgeArticlesKCSKnowbler';
    import getKnowledgeArticlesCount from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getKnowledgeArticlesCountKCS';
    import getPickListValues from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getPickListValues';
    import getImage from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getImage';
    import getAllUsers from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getUsers';
    import { registerListener, unregisterListener } from 'c/knowblerPubsub';
    import knowblerPubsub from 'c/knowblerPubsub';
    import { CurrentPageReference } from 'lightning/navigation';
    import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

    // import { CurrentPageReference } from 'lightning/navigation';

    export default class KcsknowblerarticleList extends LightningElement {
    // @wire(CurrentPageReference) datapageReference;
    @track articles = [];
    users=[];
    @api flexipageregionwidth;
    @api newid;
    @api uid;
    @api endpoint;
    @api jwttoken;
    @api loadingcard;
    @api parameters;
    @api kcsheight;
    @api kcssupport;
    @api language;
    @api tabcontent; 
    @api casedata
    @api languagechanged;
    @api uniqueNumber;
    //@track flagForm;
    @api tabcontentcreate;
    @api alldatacategories;
    @api noarticles;
    @api contentstandard;
    //@api evaluatedatasuccessfully;
    // @api isedit=false;
   // @track value = 'inProgress';
    
    // currentId;
    // @track detailArticle = {};
    @track createArtcleMapping={};
    @track ispublisharticletab;
    @api queryobj; 
    agentList;
    cardHeight = 350;
    tabsContent = [
        { "label": "All articles", "value": 0, "count": 0 },
        { "label": "My articles", "value": 1, "count": 0 },
        { "label": "Published articles", "value": 2, "count": 0 }
    ];
    tabsContents;
    firstTime = true;
    firstTimeHit=false;
    contentHealthApiBreak=false;
    options=[]
    // showArticlesScreen = true;
    userId = Id;
    @track tabs = [];
    @track pickListValues;
    // @track userLanguage;
    currentUserEmailId;
    currentUserLanguage;
    @track noLoading = true;
    @track showLoader = false;
    @api contenthealthdata;
    // rendderflag;
    @track agentid='All';
    @track value = 'All';
    @track selectedUserEmail = '';
    @api newnumber;
    dropDown;
    contentHealthBreakImg;
    @wire(getBackendUrl)
    wiredData({ error, data }) {
        if (data) {
          this.dropDown = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/arrow_down.svg';
          this.contentHealthBreakImg = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/content-health-break-img.svg';
        } else if (error) {
            console.error('Error:', error);
        }
    }

  @wire(getRecord, { recordId: '$agentid', fields: ['User.Email'] })
  wiredUser({ error, data }) {
    if (data) {
      const email = data.fields.Email.value;
      console.log('email:', email);
      this.selectedUserEmail = email;
      this.getCount();
    }
    if (error) {
      console.log('Error in get user Email:', error);
    }
  }

  @track recordt;

  doneTypingInterval = 600;

  typingTimer;

  firstTimeAfterCreate = true;

  refreshData;

  fromSearch = false;

  @track fromTab = {
    change: false
  };

    @wire(CurrentPageReference) pagerf;

    @api showdropdown;
    @api createdarticle;
    @track checkShow;
    @track articleListData={
        showEditPage:false,
        showDetailPage:false,
        showEditDetailPage:false,
        showConfiguration:false,
        searchText:'',
        showArticlesScreen:true,
        detailArticle:{},
        currentId:'',
        configRecord:[],
        mappingFields:[],
        query:{
            numPerPage: 10,
            offset: 0,
            currentPage: 1,
            tabcontent: 0,
            count: 0,
            fromTab:false
        },
        isedit:false,
        userLanguage:'',
        hitIndex:2,
        flagForm:'',
        createArtcleMapping:{}
    }
    fromMaxTab=false;
    @api destobj;
    
    @api 
    get articlescreendata(){}
    set articlescreendata(data)
    {
        if(data)
        {
        this.articleListData={};
        this.articleListData=JSON.parse(JSON.stringify(data));
        this.articleListData.hitIndex++;
        this.fromSearch=true;

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

    @api
    get userlanguage(){}
    set userlanguage(data)
    {
        if (data) {
            this.articleListData.userLanguage=JSON.parse(JSON.stringify(data));
            this.articleListData.userLanguage.currentUserLanguage=this.language?this.language:this.articleListData.userLanguage.currentUserLanguage;
        }
        if(this.kcssupport && this.kcssupport.length)
        {
        this.getFields();
        this.getCount();
        }
        
    }
    getArticleData(data)
    {
    this.articleListData.createArtcleMapping={}
    this.articleListData.createArtcleMapping=data.detail;
    if(!data.detail.flag)
    this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{allArticleData:this.articleListData}}));

    

    }


    kcsheightfun() {
        if (!this.kcsheight)
            return;
        let layoutHeight = parseInt(this.kcsheight, 10);
        this.cardHeight = layoutHeight - 154;
        this.cardHeight = this.cardHeight + 'px';


    }
    showmenu() {
        this.template.querySelector(".menuitems").style.display="block";
        this.template.querySelector(".upicon").style.display="block";
        this.template.querySelector(".downicon").style.display="none";
        }
        hidemenu()
        {
        this.template.querySelector(".menuitems").style.display="none";
        this.template.querySelector(".upicon").style.display="none";
        this.template.querySelector(".downicon").style.display="block";
        }
    get usersArray(){
        let returnOptions = [{label:'All',value:'All'}];
        if(this.users){
            this.users.forEach(ele =>{
                returnOptions.push({label:ele.Name , value:ele.Id});
            }); 
        }

    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    if (
      localStorageValue[window.btoa(encodeURIComponent(Id))]?.reviewerSettings
        ?.filters?.agentFilter &&
      localStorageValue[window.btoa(encodeURIComponent(Id))]?.reviewerSettings
        ?.filters?.agentFilter != this.agentid
    ) {
      const localStorageAgentFilterValue =
        localStorageValue[window.btoa(encodeURIComponent(Id))]?.reviewerSettings
          ?.filters?.agentFilter;
      const selectedAgent = returnOptions.filter(
        (item) => item.value === localStorageAgentFilterValue
      );
      this.value = selectedAgent[0].value;
      this.agentid = selectedAgent[0].value;
      this.getCount();
    }
    this.agentList = returnOptions;

    return returnOptions;
  }

  connectedCallback() {
    registerListener('evaluatepopup', this.evaluatedatasuccessfully, this);
    knowblerPubsub.registerListener(
      `agentevaluteddata${this.newnumber}`,
      this.senddatatocontenthealth,
      this
    );
    this.articleListData.showConfiguration = !(
      this.kcssupport && this.kcssupport.length
    );
    if (this.articleListData.showConfiguration) {
      this.noLoading = false;
      this.showLoader = false;
    }
  }

  @wire(getAllUsers) userData({ data, error }) {
    if (data) {
      this.users = data;
    } else if (error) {
    }
  }

  handleChange(event) {
    const agentName = this.agentList.filter(
      (item) => item.value === event.detail.value
    )[0].label;
    this.value = event.detail.value;
    this.agentid = this.value;
    this.articleListData.query.currentPage = 1;
    this.articleListData.query.offset = 0;
    this.firstTime = true;
    this.fromSearch = true;
    this.showLoader = true;
    this.getCount();
    if (this.agentid == 'All') {
      this.getCount();
    }
    const localStorageValue = localStorage.getItem('TourStatus')
      ? JSON.parse(localStorage.getItem('TourStatus'))
      : {};
    localStorageValue[
      window.btoa(encodeURIComponent(Id))
    ].reviewerSettings.filters.agentFilter = this.agentid;
    localStorage.setItem('TourStatus', JSON.stringify(localStorageValue));
  }

  disconnectedCallback() {
    this.dispatchEvent(
      new CustomEvent('createarticlehome', {
        detail: { allArticleData: this.articleListData, flag: true }
      })
    );
  }

  senddatatocontenthealth(data) {
    const rawdata = data;
    const url = `${this.endpoint}/kcs-anlytics/rest/anlytics/content-health/save-article-evaluation`;
    fetch(url, {
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
      .then((res) => {
        if (res && res.status === 401) {
          this.contentHealthApiBreak = true;
          this.noLoading = true;
        } else {
          const temp = 'yes';
          knowblerPubsub.fireEvent(this.pagerf, 'evaluatepopup', temp);
        }
      })
      .catch((error) => {});
  }

  renderedCallback() {
    if (
      this.template.querySelector('.knowbler__content-health-api-break-screen')
    ) {
      this.template.querySelector(
        '.knowbler__content-health-api-break-screen'
      ).style = `height: ${parseInt(this.kcsheight, 10)}px`;
    }
    if (this.newid) {
      $(window).on('resize', function (event) {
        const windowSize = $(window).width();
      });
    }
    if (this.flexipageregionwidth) {
      this.kcsheightfun();
      if (this.template.querySelector('.article_card'))
        this.template.querySelector('.article_card').style =
          `height:${this.cardHeight}`;
    } else {
      const height = `${Math.floor(window.innerHeight / 2)}px`;
      if (this.template.querySelector('.article_card'))
        this.template.querySelector('.article_card').style = `height:${height}`;
    }
    window.addEventListener('resize', this.changeHeight.bind(this));
    if (this.template.querySelector('.slds-input_faux')) {
      this.template
        .querySelector('.slds-input_faux')
        .style.setProperty('border', `${0}px`);
    }
    if (this.flexipageregionwidth == 'MEDIUM') {
      if (this.template.querySelector('.agentdivsmall'))
        this.template.querySelector('.agentdivsmall').style.display = 'none';
      if (this.template.querySelector('.agentdiv'))
        this.template
          .querySelector('.agentdiv')
          .style.setProperty('margin-right', '6px');
    }
    if (this.flexipageregionwidth == 'LARGE') {
      if (this.template.querySelector('.agentdivsmall'))
        this.template.querySelector('.agentdivsmall').style.display = 'none';
      if (this.template.querySelector('.agentdiv'))
        this.template
          .querySelector('.agentdiv')
          .style.setProperty('margin-right', '6px');
    }
  }

  changeHeight() {
    if (
      this.template.querySelector('.article_card') &&
      !this.flexipageregionwidth
    ) {
      const height = `${Math.floor(window.innerHeight / 2) + 50}px`;

      this.template.querySelector('.article_card').style = `height:${height}`;
    }
    if (window.innerHeight <= 500 && !this.flexipageregionwidth) {
      const height = `${Math.floor(window.innerHeight / 2) - 50}px`;

      this.template.querySelector('.article_card').style = `height:${height}`;
    }
  }

  onChange(event) {
    if (
      event.target.scrollTop ===
        event.target.scrollHeight - event.target.offsetHeight ||
      event.target.scrollTop ===
        event.target.scrollHeight - event.target.offsetHeight + 1
    ) {
    }
  }

  getCount = async () => {
    this.tabsContents = JSON.parse(JSON.stringify(this.tabsContent));

    for (const res of this.tabsContents) {
      await this.getDataCount(res);
    }
    this.getData();
  };

  async getDataCount(res) {
    try {
      const dataQuery = {
        ...this.articleListData.query,
        ...this.articleListData.userLanguage
      };

      dataQuery.tabcontent = res.value;

      const self = this;
      if (
        dataQuery &&
        dataQuery.currentUserEmailId &&
        dataQuery.currentUserLanguage
      ) {
        const result = await getKnowledgeArticlesCount({
          searchText: this.articleListData.searchText,
          queryi: JSON.stringify(dataQuery),
          type: this.firstTime
            ? Math.floor(Math.random() * 100 + 1)
            : this.articleListData.hitIndex,
          objName: this.destobj,
          agentid:
            self && self.agentid && self.agentid == 'All'
              ? self.agentid
              : this.selectedUserEmail
        });
        if (result.length) {
          const data = result[0];
          if (this.firstTime) {
            this.tabsContents[data.tabcontent].count = data.count;
            this.tabsContents[data.tabcontent].label =
              `${this.tabsContent[data.tabcontent].label} (${data.count})`;

            if (data.tabcontent == 0 && !this.fromSearch) {
              this.changeQuery({ page: data });
            }
            if (data.tabcontent == this.tabsContents.length - 1) {
              this.tabs = [];
              this.tabs = [...this.tabsContents];
              this.firstTime = false;
            }
          } else {
            this.changeQuery({ page: data });
          }
        }
      }
    } catch (error) {
      this.template
        .querySelector('c-kcs_knowblermodal-Component')
        .showError(error);
    }
  }

      async getcontenthealthdata(dataList) {
      var rawdata = {
          "uid": this.uid,
          "articleList": dataList
      };
      var url = this.endpoint+'/kcs-anlytics/rest/anlytics/content-health/get-article-health-scores';
      await fetch(url, {
              method: 'POST',
              headers: {
                  'content-type': 'application/json',
                  'accept': '/',
                  'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
                  'ngrok-skip-browser-warning':true,
                  'Authorization': `Bearer ${this.jwttoken}`
              },
              body: JSON.stringify(rawdata),
          }).then((response) => response.json())
          .then((data) => {
            this.contenthealthdata = JSON.parse(JSON.stringify(data));
            if (this.contenthealthdata.status === 401) {
                this.contentHealthApiBreak = true;
            }
          })
          .catch((error) => {
              console.error('Error:in api ', error);
          });
  }

  getData() {
    if (this.articleListData.query.tabcontent == 2) {
      this.ispublisharticletab = true;
    } else {
      this.ispublisharticletab = false;
    }
    if (this.fromSearch) {
      this.changeQuery({ search: 1 });
    }

    const self = this;
    if (
      this.articleListData &&
      this.articleListData.userLanguage &&
      this.articleListData.userLanguage.currentUserEmailId &&
      this.articleListData.userLanguage.currentUserLanguage
    ) {
      KnowledgeArticles({
        searchText: this.articleListData.searchText,
        queryi: JSON.stringify({
          ...this.articleListData.query,
          ...this.articleListData.userLanguage
        }),
        type:
          this.createdarticle && this.firstTimeAfterCreate
            ? Math.floor(Math.random() * 100 + 1)
            : this.articleListData.hitIndex,
        objName: this.destobj,
        agentid:
          self.agentid && self.agentid == 'All'
            ? self.agentid
            : this.selectedUserEmail
      })
        .then(async (result) => {
          this.refreshData = result.knowledgeArticlesList;
          if (result.articleNumberList && result.articleNumberList.length) {
            this.allarticles = result.articleNumberList;
            await this.getcontenthealthdata(this.allarticles);
          }
          result = JSON.parse(JSON.stringify(result.knowledgeArticlesList));
          this.articleListData.showArticlesScreen = !!result.length;
          const newSet = [];
          result.forEach((ele) => {
            newSet.push(ele.Owner.Id);
          });
          try {
            const allImages = await getImage({
              newSet: JSON.stringify(newSet)
            });
            if (allImages) {
              const mapData = [];
              for (const key in allImages) {
                mapData.push({
                  FullPhotoUrl: allImages[key].FullPhotoUrl,
                  key
                });
              }
              result.map((res) => {
                const indexPhoto = mapData.findIndex(
                  (elm) => elm.key == res?.Owner?.Id
                );
                if (indexPhoto > -1) {
                  res.FullPhotoUrl = mapData[indexPhoto].FullPhotoUrl;
                  const event = new CustomEvent('sendfullphotourl', {
                    detail: {
                      fullPhotoUrl: res.FullPhotoUrl
                    }
                  });
                  this.dispatchEvent(event);
                }
              });
            }
          } catch (error) {
            this.template
              .querySelector('c-kcs_knowblermodal-Component')
              .showError(error);
          }
          this.articles = [...result];
          if (this.contentHealthApiBreak) {
            this.noLoading = true;
          } else {
            this.noLoading = false;
          }
          this.showLoader = false;
          this.fromSearch = false;
          this.fromMaxTab = false;
          this.firstTimeAfterCreate = false;
        })
        .catch((error) => {
          this.template
            .querySelector('c-kcs_knowblermodal-Component')
            .showError(error);
        });
    }
        
            
    }
    clickBreakApiOkButton() {
        knowblerPubsub.fireEvent(this.pagerf, 'actionSwitchKnowblerMode'+this.uniqueNumber, true);
    }

    hanldevaluechange(event) 
    {
    // if (!this.firstTimeHit)
    //  {
            let querystr={...this.articleListData}
            if(!this.firstTimeHit)
            {
                this.articleListData.query.currentPage = 1;
                this.articleListData.query.offset = 0;
                
            }
            this.changeQuery({ page: (this.firstTimeHit && this.articleListData?.query?.tabcontent!='0')?({tabcontent:this.articleListData?.query?.tabcontent,count:this.tabs[this.articleListData?.query?.tabcontent].count}):event.detail });
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
            // if(this.searchText.length)
            this.fromSearch=true;
                this.firstTime=true;
            this.getCount();
                // this.getDataCount(this.tabs[this.query.tabcontent]);       
                // this.getData();
            
        
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
        
        this.dispatchEvent(new CustomEvent('changelanguage',{
            detail:{
                languagechanged: event?.detail?.languagechanged
                }
            }))
        this.showLoader=true;
        this.articleListData.userLanguage.currentUserLanguage = event?.detail?.records?.value;
        this.articleListData.userLanguage={...this.articleListData.userLanguage};
        this.articleListData.query.currentPage = 1;
        this.articleListData.query.offset = 0;
        this.firstTime = true;
        this.fromSearch=true;
        this.languagechanged = event?.detail?.languagechanged;
        this.getCount();        
    }
    getFields() {
        getPickListValues({
            objectName: this.destobj,
            fieldName: 'Language'
        }).then(result => {
            this.pickListValues = JSON.parse(JSON.stringify(result));
            
        }).catch(error => {
            this.template.querySelector('c-kcs_knowblermodal-Component').showError(error);

        });
    }

    managearticle(event) {
        this.articleListData.showEditDetailPage=true
        this.articleListData.currentId = event.detail?.item?.Id;
        this.articleListData.detailArticle = { ...event.detail.item }
        
        this.articleListData.configRecord = this.kcssupport.filter(res => ((res.RecordType == this.articleListData.detailArticle.RecordType.Name) && res.active));
        if (this.articleListData.configRecord.length)
        {
            
        this.articleListData.flagForm=false;
            this.articleListData.configRecord[0].mapping.map(res =>{
                if(res.type=='file')
                {
                    this.articleListData.mappingFields.push(this.articleListData.configRecord[0].DestinationObject + '.' + res.name.replace('__c','')+'__Name__s');
                    this.articleListData.mappingFields.push(this.articleListData.configRecord[0].DestinationObject + '.' + res.name.replace('__c','')+'__Length__s');
                    this.articleListData.mappingFields.push(this.articleListData.configRecord[0].DestinationObject + '.' + res.name.replace('__c','')+'__Body__s');
                    this.articleListData.mappingFields.push(this.articleListData.configRecord[0].DestinationObject + '.' + res.name.replace('__c','')+'__ContentType__s');
                }
            else
                this.articleListData.mappingFields.push(this.articleListData.configRecord[0].DestinationObject + '.' + res.name);
        
            });
        }
        else{
            this.recordt = this.articleListData.detailArticle.RecordType.Name;
            this.articleListData.flagForm = true;
        }
        if(event.detail?.isEdit)
        {
            this.articleListData.isedit=true;
        this.showDetailPage = false;
        }
        else{
        this.articleListData.isedit=false;
        
    }
        if(event.detail?.showManage){
        this.articleListData.showDetailPage = true;
        }
        else
        {
            this.articleListData.showEditPage = true;
            this.articleListData.showDetailPage = false;
        }
            
        // this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{allArticleData:this.articleListData,flag:true}}));

        
    }

    hideScreen() {
        // this.firstTimeHit=true;
        this.articleListData.showEditDetailPage=false;
        this.articleListData.showDetailPage = false;
        this.articleListData.showEditPage=false;
        this.firstTimeHit=true;
        this.articleListData.createArtcleMapping={}
    //  this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{allArticleData:this.articleListData,flag:true}}));

    }
    handleCreateArticleBack(event)
    {
        this.firstTimeHit=true;
        if(this.articleListData.isedit)
        {
        this.articleListData.showDetailPage=true;
        }
        else
        {
            this.articleListData.showEditDetailPage=false;
        }
        this.articleListData.showEditPage=false;
    //  this.dispatchEvent(new CustomEvent('createarticlehome',{detail:{allArticleData:this.articleListData,flag:true}}));
    this.articleListData.createArtcleMapping={};

    }
    
    handleCreateArticleLeave(event){

            this.articleListData.showEditDetailPage=false;
            this.articleListData.showDetailPage=false;
            this.articleListData.showEditPage=false;
            this.firstTimeHit=true;
            
            if(event.detail)
            {
            let mapp=event.detail.mapping;
        
            let allArticles=JSON.parse(JSON.stringify(this.articles));
            let index=allArticles.findIndex(res=>res.Id==event.detail?.Id);
            if(index>-1)
            {
            let ob= mapp.find(ele=>ele.name=='Title')
            allArticles[index].Title=ob?.value;
            let obb= mapp.find(ele=>ele.name=='lastModifiedDate')
            allArticles[index].LastModifiedDate=obb.value;
            }
            allArticles.sort((a,b)=>b.LastModifiedDate.localeCompare(a.LastModifiedDate));
            
            this.articles = [...[]];
            this.articles=[...allArticles];
            this.articleListData.hitIndex++;
            refreshApex(this.articles);
            getRecordNotifyChange([{recordId: event.detail?.Id}]);
            this.articleListData.createArtcleMapping={};
        
        }
    }

    evaluatedatasuccessfully(data)
    {
        this.template.querySelector("c-kcs_knowblermodal-component").evaluatedsuccessmethod();
    }

    refreshlist()
    {
        this.firstTime = true;
        this.fromSearch=true;
        this.showLoader = true;
        this.getCount(); 
    }
}