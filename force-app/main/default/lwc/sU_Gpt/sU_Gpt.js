import { LightningElement, api, track } from "lwc";
import { registerListener, unregisterListener,fireEvent, getGptCacheResultFunc,suGPTResultCache,getCache } from "c/supubsub";

export default class Su_Gpt extends LightningElement {
  @track myElement = null;
  @track showArticleLinks = false;
  @track isUserScrolling = false;
  @api endPoint;
  scrollableArea;
  observer;
  showModal;
  @api eventCode;
  showToolTipCopy = false;
  @track articleListPreview = [];
  @track articleList = [];
  @track allArticles = [];
  @track toggleArticleText = 'Show more';
  @api failText;
  @api utilityTop;
  @track bigscreen;
  @api utility;
  @api emptySearchString;
  @api searchString;
  @api pageNum = 1;
  @api uid;
  @api totalResults;
  @api searchStringFromBanner;
  @api translationObject;
  @track isMobileDevice = false;
  @track PRINT_INTERVAL = 0;
  @track STREAM_DELIMITER = "<SU_Separator>HTML BREAK</SU_Separator>";
  @track CACHE_SIZE = 10;
  @track animatorRefs = {};
  @track latestEffectId = null;

  @track gptLoader = false;
  @track gpthasError = false;
  @track gptPrinting = false;

  @track suGPTSays = "";
  @track gptStreaming = true;
  @api bearer;
  @api gptLinks = [];
  @api sid;
  llm_id = "";
  showMore = false;
  feedbackModal = false;
  thumbsUpFeedbackButtonOne = '';
  thumbsUpFeedbackButtonTwo = '';
  thumbsUpImage = false;
  thumbsDownImage = false;
  textCopied = false;
  showFeedbackIcons = false;
  likeButtonClicked = false;
  dislikeButtonClicked = false;
  hideThumbsDownButton = false;
  hideThumbsUpButton = false;
  submitButtonClicked = false;
  feedbackValue = 0;
  @api currentUserEmail = '';
  @track errorResponseArr = [];
  gptWidgetClicked = false;
  showCitationModal = false;
  closeTimeout;
  posXCitationModal;
  posYCitationModal;
  citationUrl = '';
  @track errorObject = {
    show: false,
    statusCode: '',
    showRetry: false,
    message: ''
  };
  @api gptActive;
  @track nogpt = true;
   @api
    set generateAnswerBtn(v){
        this.nogpt = v;
    }
    get generateAnswerBtn(){
        return this.nogpt;
    }
  @api recordId;
  @api caseSubjectVal;


  gptcontext;
  @api
  set gptContext(val) {
    this.gptcontext = val;
    if (val) {
      this.gptRoutine();
    }
  }

  get gptContext() {
    return this.gptcontext;
  }
  
  @api 
    set bigScreenVar(val){
    this.bigscreen = val;
    }
    get bigScreenVar(){
    return this.bigscreen;
    }
  suGPTSaysBoolean = false
  //GPT widget Dynamic classes
  get DeviceInfo() {
    return this.isMobileDevice ? "su__w-100" : "";
  }
  
  openCitationModal(){
    this.showCitationModal = true;
}

/**
 * Set the showCitationModal property to false to hide the modal
 * @param null
 */
closeCitationModal(){
    this.showModal = false
    this.showCitationModal = false;
    let objToSend = {};
    objToSend.posX = 0; 
    objToSend.posY = 0; 
    objToSend.visibility = 0;
    objToSend.showCitationModal = this.showCitationModal; 
    
    fireEvent(null, "openCitation"+this.eventCode, { objToSend: objToSend });
}
/**
 * It calculates the x and y of the modal where modal to be opened
 * @param null
 */

calculatePosForCitationModal(buttonElement, modalWidth, modalHeight, posX, posY, diamondPosX,diamondPosY ,heightModal) {
let buttonElementRect = buttonElement && buttonElement.getBoundingClientRect();
const buttonElementleft = buttonElementRect && buttonElementRect.left;
let buttonElementBottom = buttonElementRect && buttonElementRect.bottom;
let diamondHeight = 26
const buttonElementTop = buttonElementRect && buttonElementRect.top
const spaceRight = window.innerWidth - buttonElementleft;
if(this.utility && !this.bigscreen ){
  posX = spaceRight > modalWidth ? buttonElementleft - 42 : buttonElementleft - modalWidth  + 60;
  posY = buttonElementBottom - (this.utilityTop  + heightModal - 5 )
}else{
  if(buttonElementTop > (heightModal + diamondHeight) ){
    posX = spaceRight > modalWidth ? buttonElementleft - 25 : buttonElementleft - modalWidth + 55;
    posY = buttonElementTop - (heightModal + 40) 
  }else{
    posX = spaceRight > modalWidth ? buttonElementleft - 23 : buttonElementleft - modalWidth + 56;
    posY = buttonElementBottom + 32
  }

}
diamondPosX = spaceRight > modalWidth ? 'right' : 'left';
diamondPosY = buttonElementTop > (heightModal + diamondHeight)? 'top' : 'bottom'

return { posX, posY, diamondPosX,diamondPosY};
}


/**
 * This funtion excutes when user hovers over citation article links and it will open the modal.
 * @param {*} event event contains all info related to citation svg element
 */
setPreviewCitations(event , setPosition , heightModal) {
this.showCitationModal = true;
let modalWidth = 340;
let modalHeight = 75;
let buttonElement = event && event.target;
const href = buttonElement && buttonElement.getAttribute('data-url');
let posX = 0;
let posY = 0;
let diamondPositionX = '';
let diamondPositionY = '';
let  objToSend = {};
if(!setPosition){
 objToSend;
  objToSend = {
  posX,
  posY,
  href,
  showCitationModal: true,
  diamondPositionX,
  diamondPositionY ,
  visibility : 0,
  event : event
  
};
}
else{
  const { posX: newX, posY: newY, diamondPosX: newdiamondPosX , diamondPosY: newdiamondPosY} = this.calculatePosForCitationModal(buttonElement, modalWidth, modalHeight, posX, posY,diamondPositionX,diamondPositionY,heightModal);
  objToSend = {
    posX: newX,
    posY: newY,
    href: buttonElement && buttonElement.getAttribute('data-url'),
    showCitationModal: true,
    diamondPositionX: newdiamondPosX,
    diamondPositionY : newdiamondPosY,
    visibility: 1,
    event:event
  };

}
fireEvent(null, "openCitation"+this.eventCode, {objToSend });
}
/**
 * This function closes modal after below mentioned timeout.
 * @param null
 */
 scheduleClose(){
  this.clearCloseTimeOut();
  this.closeTimeout = setTimeout(() => {
    this.closeCitationModal();
  }, 100);
}

 /**
 * This function clears setTimeOut that is currently running if user pointer moves over modal
 */
clearCloseTimeOut(){
  if (this.closeTimeout) {
        clearTimeout(this.closeTimeout);
        this.closeTimeout = null;
    }
}
/**
 * handleHoverStates - It opens citation preview modal if user hovers on citation svg
 * @param {void}
 * @returns {void}
 */
handleHoverStates = (event) => {
      if (
        !this.showMore &&
        event.target.tagName === 'BUTTON' &&
        event.target.classList.contains('su_citation') &&
        event.target.hasAttribute('data-url')
      ) {
        this.setPreviewCitations(event);
       
        event.stopPropagation();
      } else if(!this.showModal) {
        this.closeCitationModal();
      }
     
}
  get mlErrorResponse(){
    let errorResponseData = this.errorResponseArr.some(e => e === this.suGPTSays);
    return errorResponseData;
  }
 get suSnippet() {
    return this.isMobileDevice
      ? "su__snippets_mobile"
      : !this.gptLoader &&
        !this.gptPrinting &&
        !this.mlErrorResponse &&  !this.gpthasError &&  !this.errorObject.show

      ? "su__show-more-height-min su__snippets_container"
      : (this.mlErrorResponse && !this.gpthasError &&  !this.errorObject.show) ? 'su__padding_10 su__snippets_container' : 'su__snippets_container'
  }
  get gptContent() {
    return !!this.suGPTSays && !this.gptLoader;
  }
  get showGptWidget() {
    return this.pageNum === 1;
  }
  get getErrorClass() {
    if (this.gpthasError) {
      return "su__noResult_container";
    }
    if (!this.showMore && this.gptPrinting && !this.mlErrorResponse) {
      return "su__hide_show_more su__padding_8";
    }
    if ((this.showMore && this.gptPrinting)) {
      return "su__typing_annimation su__show-all su__padding";
    }
     if ((this.showMore && !this.gptPrinting)) {
      return "su__show-all su__padding su__position-relative";
    }
    if (!this.showMore && !this.gptPrinting && !this.mlErrorResponse) {
      return "su__hide_show_more su__padding_8";
    }
    return "";
  }
  get isError() {
    if (this.gpthasError) {
      return "scrollable-content su__noresult_text_color";
    }
    if (!this.gpthasError && this.showMore) {
      return "scrollable-content su__remove_space su__show-more-opacity";
    }
    if (!this.gptPrinting && !this.showMore) {
      return "scrollable-content su__remove_space";
    }
    return "";
  }

  get getFeedbackIcons(){
    if((!this.gptPrinting && !this.mlErrorResponse && (this.suGPTSays === "Run a query to generate a response" || this.suGPTSays === "Unable to generate")) || this.gptPrinting){
      this.showFeedbackIcons = false;
      return this.showFeedbackIcons;
    }else if(!this.gptPrinting && this.mlErrorResponse){
        this.showFeedbackIcons = false;
        return this.showFeedbackIcons;
    }
      this.showFeedbackIcons = true;
      return this.showFeedbackIcons;
}
  get feedbackIconsCss(){
    if(this.showMore && !this.mlErrorResponse){
        
        return "su__feedback_icons_container su__position-relative"
      } 
      else if(!this.showMore && !this.gptPrinting && !this.mlErrorResponse){
        return "su__feedback_icons_container_without_showMore su__position-relative"
      }
      return null;
  }
  get isthumbsUpActive(){
   return  this.likeButtonClicked ? 'su__align_thumbs_up su-cursor-pointer su__highlight_thumbs_up' : 'su__align_thumbs_up su-cursor-pointer';
  }
  get isthumbsUpActiveSvgFill(){
    return this.likeButtonClicked ? '#FFFFFF' : '#b7b7b7';
  }
   get isthumbsDownActiveSvgFill(){
    return this.dislikeButtonClicked ? '#FFFFFF' : '#b7b7b7';
  }
  get isthumbsDownActive(){
    return this.dislikeButtonClicked ? 'su__align_thumbs_down su-cursor-pointer su__highlight_thumbs_up' : 'su__align_thumbs_down su-cursor-pointer';
  }
  get getSnippetHeadingStyles() {
    return this.isMobileDevice
      ? "su__snippet_heading su__text-right"
      : "su__snippet_heading";
  }

  get getSnippetHeadingColor() {
    return this.isMobileDevice
      ? "su__snippet_heading_color su__font-10"
      : "su__snippet_heading_color su__font-14";
  }

  get scrollableAreaStyles() {
    const a =
      this.suGPTSays && !this.gpthasError && !this.gptLoader
        ? "typing-text su__typed_text"
        : "";
    const b = this.isMobileDevice ? "su__padding_8" : " ";
    const c = this.gpthasError || !this.gptPrinting ? "removeCursor" : "";
    const d = "scrollableArea";
    let e = a + " " + b + " " + c + " " + d;
    return e;
  }

  get getArticlesStyles(){
    const articlesClass = "gpt_articles";
    const conditionalShowHideClass = this.showArticleLinks ? " show" : " hide";
    return articlesClass + conditionalShowHideClass;
  }

  get showTogglerButton(){
    return this.allArticles.length > 3 ? true: false;
  }
  
  getTrimmedTitle(title) {
    const maxLength = 52;
    return title.length > maxLength ? title.slice(0, maxLength) + '...' : title;
  }

  toggleArticles(){
    if(this.articleListPreview.length === 3) {
       this.toggleArticleText = 'Show less';
       this.articleListPreview = this.allArticles
    }else{
       this.toggleArticleText = 'Show More';
       this.articleListPreview = this.articleList; 
    } 
  }
  /**
   * openFeedbackModalThumbsUp - it executes when user clicks on thumbs up button
   */
  openFeedbackModalThumbsUp(){
    this.feedbackModal = false;
    this.feedbackValue = 0;
    this.thumbsUpFeedbackButtonOne = this.translationObject.Accurate;
    this.thumbsUpFeedbackButtonTwo = this.translationObject.Comprehensive;
    this.thumbsUpImage = true;
    this.thumbsDownImage = false;
    this.feedbackModal = true;
  }
  /**
   * openFeedbackModalThumbsDown - When user clicks on thumbs down button
   */
  openFeedbackModalThumbsDown(){
    this.feedbackModal = false;
    this.feedbackValue = 1;
    this.thumbsUpFeedbackButtonOne = this.translationObject.Offensive;
    this.thumbsUpFeedbackButtonTwo = this.translationObject.Incorrect;
    this.thumbsUpImage = false;
    this.thumbsDownImage = true;
    this.feedbackModal = true;
  }
  /**
   * closeFeedbackModal - when user clicks on outside the modal
   */
  closeFeedbackModal() {
     this.thumbsDownImage = false;
     this.thumbsUpImage = false;
     this.feedbackModal = false; 
     if(!this.submitButtonClicked){
       this.likeButtonClicked = false;
       this.dislikeButtonClicked = false;
       this.hideThumbsUpButton = false;
       this.hideThumbsDownButton = false;
     }
     if(this.thumbsDownImage){
       this.dislikeButtonClicked = false;
       this.hideThumbsUpButton = false;
       this.likeButtonClicked = false;
       this.dislikeButtonClicked = false;
     } 
     this.submitButtonClicked = false;
    }
    /**
     * copyFeedbackContent - It executes when user clicks on copy to clipboard button
     * @param {*} event - event executes when user clicks on button
     */

  
    copyFeedbackContent(event) {
      try {
        let copiedContent = event && event.currentTarget && event.currentTarget.dataset && event.currentTarget.dataset.sub;
        if (!copiedContent) {
          throw new Error('No content to copy');
        }
        const regex = /<sup[^>]*>.*?<\/sup>/g;
        let sanitisedContent = copiedContent.replace(regex, '');
          let tag = document.createElement('textarea');
          tag.setAttribute('id', 'input_test_id');
        tag.value = sanitisedContent;
          document.body.appendChild(tag);
          tag.select();
        let successful = document.execCommand('copy');
        if (!successful) {
          throw new Error('Failed to copy content');
        }
          tag.remove();

        this.textCopied = true;
        setTimeout(() => {
          this.textCopied = false;
        }, 2000);
  
      } catch (error) {
        console.error('Error copying content:', error);
      }
      }




  // handler functions dealing with the caching the response and animating it
  clearCache = () => {
    const keys = Object.keys(suGPTResultCache);
    while (keys.length >= this.CACHE_SIZE) {
        const keyToDelete = keys.reduce((minKey, currentKey) => {
            const minValue = parseInt(minKey.split("-").pop(), 10);
            const currentValue = parseInt(currentKey.split("-").pop(), 10);
            return currentValue < minValue ? currentKey : minKey;
        });

        const newCache = { ...suGPTResultCache };
        delete newCache[keyToDelete];
        getGptCacheResultFunc(newCache);
        keys.splice(keys.indexOf(keyToDelete), 1);
    }
  };

  getNextCacheOrder = () => {
    const keys = Object.keys(suGPTResultCache);
    const maxNumber = keys.reduce((max, currentKey) => {
      const currentValue = parseInt(currentKey.split("-").pop(), 10);
      return currentValue > max ? currentValue : max;
    }, 0);
    return maxNumber + 1;
  };


  createCache = (query, context, answer, articlesArray,likeButtonClicked,dislikeButtonClicked) => {
    this.clearCache();
    const order = this.getNextCacheOrder();
    const key = `${query}-${context}-${order}`;
    const articles = articlesArray;
    let cachedValue = { ...suGPTResultCache, [key]: {answer, articles, showLike: likeButtonClicked, showdisLike: dislikeButtonClicked}};
    getGptCacheResultFunc(cachedValue);
  };
  /**
   * It updates the cache 
   * @param {*} cacheObj - contains the cached object
   */
  updateCacheforLikeButton(cacheObj){
    cacheObj.showLike = true;
  }
  /**
   * It updates the cache 
   * @param {*} cacheObj - contains the cached object
   */
  updateCachefordisLikeButton(cacheObj){
    cacheObj.showdisLike = true;
  }

  breakCheck = (effectId) => {
    const exit = effectId !== this.latestEffectId;
    if(exit){
      this.animatorRefs[effectId].forEach((ref) => clearTimeout(ref));
      delete this.animatorRefs[effectId];
    }
    return exit;
  };

  //SLEEP FUNCTION
  async sleep(t) {
    await new Promise((res) => setTimeout(() => res(), [t]));
  }

  //TEXT ANIMATION
  animateText = (str, effectId, articles = false) => {
    this.suGPTSays = "";
    this.gptLoader = false;
    if (
      str === this.failText ||
      str === this.emptySearchString ||
      this.mlErrorResponse
    ) {
      this.showMore = false;
      this.textCopied = false;
      this.feedbackModal = false;
    } else {
      this.showMore = true;
      this.textCopied = false;
      this.feedbackModal = false;
    }
    this.gptPrinting = true;
    if(this.suGPTSays && this.suGPTSays.length){
      this.suGPTSaysBoolean = true
    }
    // eslint-disable-next-line
    const printer = async (effectId) => {
      for (const c of str) {
        if(this.suGPTSays && this.suGPTSays.length){
          this.suGPTSaysBoolean = true
        }
        // eslint-disable-next-line
       // await this.sleep(1); // gpt stream is roughly that much faster in printing (4 chars per PRINT_INTERVAL)
        if (this.breakCheck(effectId)) return; //break check
        this.suGPTSays = this.suGPTSays + c;
      }
      this.gptPrinting = false;
      if(articles){
        this.showArticleLinks = true;
        this.articleList = articles;
      }else{
         this.showArticleLinks = false;
      }
    };
    if (this.breakCheck(effectId)) return; //break check
    // clear old animator refs from memory
    if(!this.animatorRefs[effectId]) this.animatorRefs[effectId] = [];
    // add fresh entry of animator ref to memory
    this.animatorRefs[effectId].push(setTimeout(() => printer(effectId)));
  };

  //Reading stream from the API
  async readStream(effectId) {
    let self = this;
    if (self.breakCheck(effectId)) return; //break check
    this.suGPTSays = "";
    let data = {
      description: this.gptcontext,
      query: this.searchString,
      llm: true,
      streaming: this.gptStreaming,
      articles: this.gptLinks,
      is_test: false
    };

    const response = await fetch(
      `${this.endPoint}/mlService/su-gpt`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "token": "bearer " + this.bearer,
          "search-client-type": 7,
          "uid": this.uid,
          "search-id": window._gza_analytics_id ,
          'taid-device' : window._gr_utility_functions  ? window._gr_utility_functions.getCookie("_gz_taid")  : "",
          'sid-session' : window._gr_utility_functions  ? window._gr_utility_functions.getCookie("_gz_sid")  : "",
        },
        body: JSON.stringify(data)
      }
    );

    if (response.ok) {
      this.gptLoader = false;
      this.gptPrinting = true;
    } else {
      this.gptLoader = false;
      this.gpthasError = true;
      this.showArticleLinks = false;
      this.animateText(this.failText, effectId);
      return;
    }

    const reader = response.body.getReader();
    const textDecoder = new TextDecoder();
    let gptAnswer = "";
    let partialAccumulator = "";
     let errorCodes = {
      '401': {message: 'Unable to fetch a response for the query.', showButton: false},
      '500': {message: 'Response can not be generated at the moment.', showButton: false},
      '400': {message: 'Response can not be generated at the moment.', showButton: false},
      '502': {message: 'Response can not be generated at the moment.', showButton: false},
      '429': {message: 'Response can not be generated at the moment.', showButton: false},
      '503': {message: 'Response can not be generated at the moment.', showButton: false},
      '408': {message: 'Unable to fetch a response for the query.', showButton: true}
    };
    let firstIteration = true;
    let articleList = [];
    this.textCopied = false;
    this.feedbackModal = false;
   // eslint-disable-next-line
    while (true) {
      // eslint-disable-next-line
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = textDecoder.decode(value);
      let firstChunk = false;

      const articlesData =
      chunk
        ?.split(self.STREAM_DELIMITER)
        .filter(Boolean);

      if(firstIteration){
        if(articlesData){
          let sources = JSON.parse(articlesData[0]);
          if(sources.data != null)
          {
            if(sources && sources.data && sources.data.no_answer && sources.data.no_answer.length){
              this.errorResponseArr = sources.data.no_answer;
            }
           articleList = sources?.data?.articles;
           articleList = articleList && articleList.map(item=>{
            return {...item, title: this.getTrimmedTitle(item.title), hoverTitle:item.title}
          })
        }
        firstIteration = false;
      }
      }

      let dataArray =[];
      // eslint-disable-next-line
      chunk?.split(this.STREAM_DELIMITER).forEach((data) => {
            let jsonString = data;
            try {
                let validJson = partialAccumulator + data;
                validJson.split(this.STREAM_DELIMITER).filter(Boolean).forEach((i) => {
                    jsonString = i;
                    const parsedJSON = JSON.parse(i);
                    if (errorCodes && Object.keys(errorCodes).map(Number).includes(parseInt(parsedJSON.status))) {
                      this.errorObject = {
                        ...this.errorObject,
                          show: true,
                          statusCode: parsedJSON.status,
                          message: errorCodes[parsedJSON.status].message,
                          showRetry: errorCodes[parsedJSON.status].showButton
                        };
                    } else {
                      this.errorObject = {
                        ...this.errorObject,
                          show: false,
                          statusCode: '',
                          message: '',
                          showRetry: false
                      };
                    }
                    partialAccumulator = '';
                    if (!firstChunk) {
                    let llmRequestId =
                    parsedJSON && parsedJSON.data && parsedJSON.data.id;
                    this.llm_id = llmRequestId;
                    firstChunk = true;
                    }
                    dataArray.push(
                    parsedJSON?.data?.choices?.[0]?.delta?.content || ""
              );
            });
        } catch (e) {
          partialAccumulator += jsonString || '';
        }
      });
      let i = 0;
      if (this.gptStreaming) {
        while (i < dataArray.length) {
          // eslint-disable-next-line
          await this.sleep(this.PRINT_INTERVAL);
          if (this.breakCheck(effectId)) return; //break check
          if(this.suGPTSays && this.suGPTSays.length){
            this.suGPTSaysBoolean = true
          }
          if (
            this.suGPTSays !== "" &&
            this.suGPTSays.length > 18 &&
            !this.gptWidgetClicked
          ) {
            if (
              this.errorResponseArr.findIndex((element) =>
                element.includes(this.suGPTSays)
              ) === -1
            ) {
              this.showMore = true;
            }
          }          
          gptAnswer += dataArray[i] || "";
          this.suGPTSays = gptAnswer;
              i++;
        }
      } else {
        this.animateText(dataArray[0], effectId);
      } // animate single chunk ( for streaming OFF )
      if (this.breakCheck(effectId)) return; //break check
    }
    if (!gptAnswer) {
      this.gptLoader = false;
      this.gpthasError = true;
      this.animateText(this.failText, effectId);
      return;
    }
    this.gptPrinting = false;
    //cache needs to be created for the particular search string(Already fine), context received from the API(this.gptContext) and the gptAnswer(Can be used as it is written)++
    if (this.mlErrorResponse) {
      self.showArticleLinks = false;
      self.articleList = [];
      this.showMore = false;
      this.textCopied = false;
      this.feedbackModal = false;
    }else{
      self.showArticleLinks = true;
      self.articleListPreview =articleList &&  articleList.slice(0, 3);
      self.articleList = self.articleListPreview
      self.allArticles = articleList;
      this.createCache(data.query, data.description, gptAnswer, self.articleList,self.likeButtonClicked, self.dislikeButtonClicked);
    }
     fireEvent(null,"gptResponse"+this.eventCode, this.suGPTSays);
  }

  async gptRoutine() {
    let self = this;
    if(!this.recordId || !this.caseSubjectVal){
      this.nogpt = false;
    }

    if(this.nogpt || !this.gptActive){
      return;
    }
    self.showArticleLinks = false;
    fireEvent(null,"getGptSandboxVal"+this.eventCode, "enableSandboxGptFeedabck");   
    if(this.emptySearchString === undefined || this.emptySearchString === ''){
        this.emptySearchString = 'Run a query to generate a response';
    }
    if(this.failText === undefined || this.failText === ''){
       this.failText = 'Unable to generate';
    }


    let data = {
      description: self.gptcontext,
      query: self.searchString,
      llm: true,
      streaming: self.gptStreaming
    };

    if (String(self.pageNum) === "1") {
      const effectId = Math.random();
      self.latestEffectId = effectId;
      self.gptLoader = true;
      self.gpthasError = false;
      self.suGPTSays = "";
      // Check if the answer exists in cache (saves API calls)
      // Check to be performed on the search string and the gptContext coming from the API(this.gptContext) ++
      const cachedAnswer = getCache(data.query, data.description);
      // If found render it with animation
      if (cachedAnswer) {
        const result = JSON.parse(JSON.stringify(cachedAnswer));
         
          if(result && result.articles && result.articles.length === 3) {
            this.toggleArticleText = 'Show less';
            this.articleListPreview = this.allArticles
          }else{
            this.toggleArticleText = 'Show More';
            this.articleListPreview = this.articleList; 
          }
          if(result && result.showLike){
            this.likeButtonClicked = true;
            this.hideThumbsDownButton = true;
            this.hideThumbsUpButton = false;
          }else if(result && result.showdisLike){
            this.dislikeButtonClicked = true;
            this.hideThumbsUpButton = true;
            this.hideThumbsDownButton = false;
          }
          else{
            this.hideThumbsDownButton = false;
            this.hideThumbsUpButton = false;
            this.likeButtonClicked = false;
            this.dislikeButtonClicked = false;
          }
        fireEvent(null,"gptResponse"+this.eventCode, result.answer);
        self.animateText(result.answer, effectId, this.articleListPreview);
      } else {
        this.likeButtonClicked = false;
        this.dislikeButtonClicked = false;
        this.hideThumbsDownButton = false;
        this.hideThumbsUpButton = false;
        this.gptWidgetClicked = false;
        try {
          const effectId1 = Math.random();
          self.latestEffectId = effectId1;
          if(!self.animatorRefs[effectId1]) self.animatorRefs[effectId1] = [];
          self.animatorRefs[effectId1].push(setTimeout(() => self.readStream(effectId1)));
        } catch (e) {
          console.log(e);
        }
      }
    }

  }

  searchCallMade(val){
    if(val){
      this.gptRoutine();
    }
  }
  closeToolTip(){
    this.showToolTipCopy = false;
 }
  showToolTip(){
    this.showToolTipCopy = true;
  }

  showHideGpt(value){
    this.nogpt = value;
  }

   connectedCallback() {
    registerListener("searchCallMade"+this.eventCode, this.searchCallMade,this);
    registerListener("closeModal"+this.eventCode, this.closeFeedbackModal, this);
    registerListener("sendFeedback"+ this.eventCode,this.sendFeedbackAnalytics, this)
    registerListener("showCitation"+ this.eventCode,this.showModalCitation,this);
    registerListener("closeCitationModal"+this.eventCode,this.closeCitationModal,this)
    registerListener("setPosition"+this.eventCode,this.setPosition,this)
    registerListener("showHideGpt"+this.eventCode, this.showHideGpt, this);
    this.observer = new MutationObserver(this.handleMutations);
    this.observer.observe(this.template, {
      childList: true, 
      subtree: true   
  });
  window.addEventListener('scroll', () => {
    this.closeCitationModal();
  });
   }

  disconnectedCallback() {
    unregisterListener("searchCallMade" + this.eventCode, this.searchCallMade, this);
    unregisterListener("setPosition"+this.eventCode,this.setPosition,this);
    unregisterListener("closeModal"+this.eventCode, this.closeFeedbackModal, this);
    unregisterListener("closeCitationModal"+this.eventCode,this.closeCitationModal,this)
    unregisterListener("showCitation"+ this.eventCode,this.showModalCitation,this);
    unregisterListener("sendFeedback" + this.eventCode,this.sendFeedbackAnalytics, this)
    unregisterListener("showHideGpt" + this.eventCode,this.showHideGpt, this)
    const spanElement = this.template.querySelector(`[data-id="gptString"]`)
    if (this.observer) {
      this.observer.disconnect();
  }
    spanElement.removeEventListener('mouseover', this.handleHoverStates,false);
    this.template.removeEventListener('click', this.handleClickStates,{ bubbles:false });

  }
  showModalCitation(){
    this.showModal = true
   
  }
  
  renderedCallback(){
    const container = this.template.querySelector('[data-id="gptString"]');
    if (container) {
      container.innerHTML = this.suGPTSays;
    }
  }
  setPosition(data){
    this.setPreviewCitations(data.event , data.setPosition , data.heightModal)
   }
  handleMutations = (mutationsList) => {
    for (let mutation of mutationsList) {
        if (mutation.type === 'childList') {
            const spanElement = this.template.querySelector('[data-id="gptString"]');
            if (spanElement) {
                spanElement.removeEventListener('mouseover', this.handleHoverStates); 
                spanElement.addEventListener('mouseover', this.handleHoverStates);
            }
        }
    }
}
  expandGPTWidget() {
    this.gptWidgetClicked = true;
    this.showMore = false;
    window.gza("llm_show_more", {
      llmRequestId: this.llm_id,
      searchId: window._gza_analytics_id,
      uid: this.uid,
      sid_session: this.sid,
      ts: new Date().getTime()
    });
  }
  /**
   * Specifically executes to handle positive feedback given by user
   * @param null;
   */
  handleLikeButton(){
    let self = this; 
    self.likeButtonClicked = true;
    this.hideThumbsDownButton = true;
     let cacheObject = getCache(self.searchString, self.gptContext);
     this.updateCacheforLikeButton(cacheObject)
  }
   /**
   * Specifically executes to handle negative feedback given by user
   * @param null;
   */
  handledisLikeButton(){
    let self = this; 
    self.dislikeButtonClicked = true;
    this.hideThumbsUpButton = true;
     let cacheObject = getCache(self.searchString, self.gptContext);
     this.updateCachefordisLikeButton(cacheObject)
  }
  /**
   * The function executes when user clicks on submit button of gpt feedback modal
   * @param {*} userFeedbackData - It contains data of feedback given by user
   */
  sendFeedbackAnalytics = (userFeedbackData) => {
      let gptSaysForAnalytics = this.suGPTSays;
      const regex = /<sup[^>]*>.*?<\/sup>/g;
      let sanitisedContent = gptSaysForAnalytics.replace(regex, '');
      window.gza('llm_response_feedback', {
      uid: this.uid,  
      sid_session: this.sid,
      text_entered: this.searchString,
      llm_response: sanitisedContent,
      feedback: userFeedbackData.textFeedback || '',
      reaction: this.feedbackValue,
      feedback_tags: userFeedbackData.feedbackTags || [],
      email: this.currentUserEmail
      });
      if(this.thumbsUpImage){
        this.handleLikeButton()
      }
      if(this.thumbsDownImage){
        this.handledisLikeButton();
      }
      this.submitButtonClicked = true;
    };
  }