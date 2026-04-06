import { LightningElement, api, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { getCommunitySettings, registerListener, unregisterListener,fireEvent } from "c/authsupubsub_b6b3_13";

export default class Su_AuthGpt extends NavigationMixin(LightningElement) {
  @track myElement = null;
  // @track showArticleLinks = false;
  @track isUserScrolling = false;
  @track endPoint = '';
  scrollableArea;
  showModal;

  @track articleListPreview = [];
  @track articleList = [];
  @track allArticles = [];
  @track  showMoreBtn;
  @track toggleArticleText = 'Show more';
  @api failText;
  @api emptySearchString;
  @track errorObject = {
    show: false,
    statusCode: '',
    showRetry: false,
    message: ''
  };
  @api searchString;
  @api pageNum;
  @api uid;
  @api totalResults;
  @api translationObject;

  @track isMobileDevice = false;
  @track PRINT_INTERVAL = 20;
  @track STREAM_DELIMITER = "<SU_Separator>HTML BREAK</SU_Separator>";
  @track CACHE_SIZE = 10;
  @track cache = {};
  @track animatorRefs = { };
  @track latestEffectId = null;

  @track gptLoader = false;
  @track gpthasError = false;
  @track gptPrinting = false;

  @track suGPTSays = "";
  @track gptStreaming = true;
  @track bearer = "";
  @api gptLinks = [];
  @track llm_id = '';
  showToolTipCopy = false;
  @api loading;
  @track feedbackSelectedBtn1 = false;
  @track feedbackSelectedBtn2 = false;
  @track characterCount = 0;
  @track showFeedbackIcons = false;
  @track gptPositiveFeedback = false;
  @track gptNegativeFeedback = false;
  @track showGptFeedbackPopup = false;
  @track showGptFeedbackThanksPopup = false;
  @track thumbsUpPositiveFeedback = false;
  @track thumbsDownNegativeFeedback = false;
  @track copiedToClipboard = false;
  @api currentUserEmail;
  @track suGptFeedback = ''
  @track feedbackTagValues = [];
  @track errorResponseArr = [];

  gptcontext;
  showCitationModal = false;
  closeTimeout;
  posXCitationModal;
  posYCitationModal;
  citationUrl = '';
  @api isDeviceMobile;
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
  
  //GPT widget Dynamic classes
  get DeviceInfo() {
    return this.isMobileDevice ? "su__w-100" : "";
  }
  get suSnippet() {
    return this.isMobileDevice
      ? "su__snippets_mobile  su__overflow-hide"
      : "su__snippets_container  su__overflow-hide";
  }

  get suLoaderClass(){
    return this.showMoreBtn
    ? "su__w-100 su__typing-animation su__mt-0 su__desktopMin-Heigth su__height-showmore su__overflow-hide su__show-more-not-expanded su__position-relative"
    : "su__w-100 su__typing-animation su__mt-0  su__desktopMin-Heigth"
  }

  get gptContent() {
    return !!this.suGPTSays && !this.gptLoader;
  }
  get showGptWidget() {
    return this.pageNum == 1;
  }

  get gptShowMoreBtn(){
    return this.showMoreBtn && !this.gptLoader && !this.loading && !this.errorObject.show;
  }

  get handleCopyToClipboardIconClass(){
    return this.gptShowMoreBtn ? 'su__gptFeedback_copyIconBorder' : "su__gptFeedback_copyIconBorder su__gptFeedback_copyIcon";
  }



  get getErrorClass() {
    return this.gpthasError
      ? "su__noResult_container"
      : this.gptPrinting
      ? "su__typing_annimation"
      : "";
  }

  get isError() {
    return this.gpthasError
      ? "scrollable-content su__noresult_text_color su__gpt_responseData"
      : "scrollable-content su__remove_space su__gpt_responseData";
  }

  get getSnippetHeadingStyles() {
    return this.isMobileDevice
      ? "su__snippet_heading su__text-right"
      : "su__snippet_heading";
  }

  get getSnippetHeadingColor() {
    return this.isMobileDevice
      ? "su__snippet_heading_color su__font-11"
      : "su__snippet_heading_color su__font-11";
  }

  

  get enableDisableSubmitButton(){
    return this.characterCount == 0 && !this.feedbackSelectedBtn1 && !this.feedbackSelectedBtn2 ;
  }

  get feedbackSelectedBtn1Class() {
    return this.feedbackSelectedBtn1 ? 'feedbackBtnOneSelected feedbackBtnOneSelectedHover' : 'feedbackBtnOneSelectedHover';
  }

  get feedbackSelectedBtn2Class() {
      return this.feedbackSelectedBtn2 ? 'feedbackBtnTwoSelected  feedbackBtnTwoSelectedHover' : 'feedbackBtnTwoSelectedHover';
  }

  get feedbackThumbsUpIconLighlight(){
    return this.thumbsUpPositiveFeedback  ? 'su__gptFeedback_ThumbsUp_highlight' : 'su__gptFeedback_ThumbsUp';
  }

  get feedbackThumbsDownIconLighlight(){
    return this.thumbsDownNegativeFeedback  ? 'su__gptFeedback_ThumbsDown_highlight' : 'su__gptFeedback_ThumbsDown';
  }

  get scrollableAreaStyles() {
    const a =
      this.suGPTSays && !this.gpthasError && !this.gptLoader
        ? "typing-text su__typed_text"
        : "";
    const b = this.isMobileDevice ? "su__padding_7" : "su__padding_5";
    const c = this.gpthasError || !this.gptPrinting ? "removeCursor" : "";
    const d = "scrollableArea";
    let e = a + " " + b + " " + c + " " + d;
    return e;
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

  selectSearchFeedbackFunc(event){
    const buttonId = event && event.target && event.target.dataset && event.target.dataset.id;
        if (buttonId === 'Accurate' || buttonId === 'Offensive') {
          const index = this.feedbackTagValues.indexOf(buttonId);
          if (index !== -1) {
              // If already in the array, remove it
              this.feedbackTagValues.splice(index, 1);
          } else {
              // If not in the array, add it
              this.feedbackTagValues.push(buttonId);
          }
            this.feedbackSelectedBtn1 = !this.feedbackSelectedBtn1;
        } else if (buttonId === 'Comprehensive' || buttonId === 'Incorrect') {
            // Check if buttonId is already in the array
              const index = this.feedbackTagValues.indexOf(buttonId);
              if (index !== -1) {
                  // If already in the array, remove it
                  this.feedbackTagValues.splice(index, 1);
              } else {
                  // If not in the array, add it
                  this.feedbackTagValues.push(buttonId);
              }
            this.feedbackSelectedBtn2 = !this.feedbackSelectedBtn2;
        }
  }

  suGptFeedbackHandleChange(event){
    this.characterCount = event.target.value.length;
    this.suGptFeedback = event.target.value.trim();
  }

  openFeedbackModal(event){
    const gptFeedbackUpDown = event && event.target && event.target.dataset && event.target.dataset.id;
    if(this.thumbsUpPositiveFeedback || this.thumbsDownNegativeFeedback){
      return;
    }
    this.showGptFeedbackPopup = true;
    if(gptFeedbackUpDown === 'thumbsUp'){
        this.gptPositiveFeedback = true;
    }else if(gptFeedbackUpDown === 'thumbsDown'){
        this.gptNegativeFeedback = true;
    }
  }
  closeToolTip(){
     this.showToolTipCopy = false;
  }
  showToolTip(){
     this.showToolTipCopy = true;
  }

  copyToClipboard(event) {
    try {
      // Get the content to be copied
      let copiedContent = event && event.currentTarget && event.currentTarget.dataset && event.currentTarget.dataset.sub;

      // Check if copiedContent is available
      if (!copiedContent) {
        throw new Error('No content to copy');
      }
      // Remove <sup> tags and their content using regex
      const regex = /<sup[^>]*>.*?<\/sup>/g;
      let sanitisedContent = copiedContent.replace(regex, '');

      // Create a textarea element to hold the content
      let tag = document.createElement('textarea');
      tag.setAttribute('id', 'input_test_id');
      tag.value = sanitisedContent;
      document.body.appendChild(tag);
      

      // Select the content of the textarea
      tag.select();

      // Copy the selected content to the clipboard
      let successful = document.execCommand('copy');
      
      // Check if the copy command was successful
      if (!successful) {
        throw new Error('Failed to copy content');
      }

      // Remove the textarea element from the DOM
      tag.remove();

      // Set copiedToClipboard to true to indicate success
      this.copiedToClipboard = true;

      // Reset copiedToClipboard after 2 seconds
      setTimeout(() => {
        this.copiedToClipboard = false;
      }, 2000);

    } catch (error) {
      // Handle any errors that occurred during the copy process
      console.error('Error copying content:', error);
    }
  }



  resetFeedbackModalInputFields(){
    this.gptPositiveFeedback = false;
    this.gptNegativeFeedback = false;
    this.feedbackSelectedBtn1 = false;
    this.feedbackSelectedBtn2 = false;
    this.suGptFeedback = '';
    this.feedbackTagValues = [];
    const feedbackContentTextarea = this.template.querySelector('[data-id="su__gptFeedbackContent"]');
    if(feedbackContentTextarea) {
      feedbackContentTextarea.value = '';
      this.characterCount = 0;
    }
  }

  closeFeedbackModal(event){
    const id = event?.target?.dataset?.id;
    if (id === 'closeThanksModal') {
        this.showGptFeedbackThanksPopup = false;
    }
    this.resetFeedbackModalInputFields();
    this.showGptFeedbackPopup = false;
  }



  submitFeedbackModal(event){
    
      const keys = this.cache &&  Object.keys(this.cache);
      const cacheKey = keys && keys.find((key) => key.includes(`${this.searchString}-${this.gptcontext}`));
      if (cacheKey && this.cache[cacheKey]) {
        if(this.gptPositiveFeedback){
        this.cache[cacheKey].thumbsUpPositiveFeedback = true;
        this.thumbsUpPositiveFeedback = true;
        this.thumbsDownNegativeFeedback = false;
        }else if(this.gptNegativeFeedback){
          this.cache[cacheKey].thumbsDownNegativeFeedback = true;
          this.thumbsDownNegativeFeedback = true;
          this.thumbsUpPositiveFeedback = false;
        }
      }

    const cloaseFeedbackModal = event && event.target && event.target.dataset && event.target.dataset.id;
    if(cloaseFeedbackModal === 'submit'){
      let gptContent = this.suGPTSays;
      let regex = /<sup[^>]*>.*?<\/sup>/g;
      let sanitisedContent = gptContent.replace(regex, '');
      window.gza('llm_response_feedback', {
        uid: this.uid,  
        sid_session: window._gr_utility_functions && window._gr_utility_functions.getCookie("_gz_taid"),
        text_entered: this.searchString,
        llm_response: sanitisedContent,
        feedback: this.suGptFeedback || '',
        reaction  : (this.gptPositiveFeedback ? 0 : (this.gptNegativeFeedback ? 1 : '')),
        feedback_tags: this.feedbackTagValues  || [],
        email: this.currentUserEmail
        });
  
      this.showGptFeedbackThanksPopup = true;
      this.resetFeedbackModalInputFields();
      setTimeout(() => {
        this.showGptFeedbackThanksPopup = false;
      }, 3000);
    }
    this.showGptFeedbackPopup = false;
  }

  //GPT content scrolling handler function
  handleScroll = () => {
    if (this.myElement) {
      const scrollTop = this.myElement.scrollTop;
      const scrollHeight = this.myElement.scrollHeight;
      const clientHeight = this.myElement.clientHeight;

      // If the user is at the bottom of the content, allow automatic scrolling
      if (scrollHeight - scrollTop - clientHeight <= 1) {
        this.isUserScrolling = false;
      } else {
        this.isUserScrolling = true;
      }
    }
  };

  renderedCallback() {
    const container = this.template.querySelector('[data-id="gptString"]');
    if (container) {
      container.innerHTML = this.suGPTSays;
    }
    this.myElement = this.template.querySelector('[data-id="myElement"]');
    if (this.myElement) {
      if (!this.isUserScrolling) {
        this.myElement.scrollTop = this.myElement.scrollHeight; // Scroll to the bottom
      }
      this.myElement.addEventListener("scroll", this.handleScroll);
    }
    
    if(this.errorObject.show){
      this.gpthasError = true;
      this.gptBoxHeightAsPerContent();
      
    }
  }
    /**
     * Set the showCitationModal property to false to hide the modal
     * @param null
     */
    closeCitationModal(){
      this.showModal = false
        this.showCitationModal = false;
        // Prepare object to send in the event
        let objToSend = {};
        objToSend["posX"] = 0; // Reset X position to 0
        objToSend["posY"] = 0; // Reset Y position to 0
        objToSend["visibility"] = 0;
        objToSend["showCitationModal"] = this.showCitationModal; // Include the modal status
        // Fire an event to notify parent about closing modal and send data
        fireEvent(null, "openCitation", { objToSend: objToSend });
    }
    /**
     * It calculates the x and y of the modal where modal to be opened
     * @param null
     */

   calculatePosForCitationModal(buttonElement, modalWidth, modalHeight, posX, posY, diamondPosX, diamondPosY, heightModal) {
    const buttonElementRect = buttonElement.getBoundingClientRect();
    const { left: buttonElementLeft, top: buttonElementTop, bottom: buttonElementBottom } = buttonElementRect;
    const diamondHeight = 26;
    const spaceRight = window.innerWidth - buttonElementLeft;

    if (buttonElementTop > (heightModal + diamondHeight)) {
        posX = spaceRight > modalWidth ? buttonElementLeft - 23 : buttonElementLeft - modalWidth + 55;
        posY = buttonElementTop - (heightModal + 40);
    } else {
        posX = spaceRight > modalWidth ? buttonElementLeft - 23 : buttonElementLeft - modalWidth + 57;
        posY = buttonElementBottom + 15  ;
      }
      
      diamondPosX = spaceRight > modalWidth ? 'right' : 'left';
    diamondPosY = buttonElementTop > (heightModal + diamondHeight) ? 'top' : 'bottom';
    return { posX, posY, diamondPosX, diamondPosY };
    }
  

  /**
     * This funtion excutes when user hovers over citation article links and it will open the modal.
     * @param {*} event event contains all info related to citation svg element
     */
  setPreviewCitations(event, setPosition, heightModal) {
    this.showCitationModal = true;
    const modalWidth = 454;
    const modalHeight = 75;
    const buttonElement = event?.target;
    const href = buttonElement?.getAttribute('data-url');
    let posX = 0;
    let posY = 0;
    let diamondPositionX = '';
    let diamondPositionY = '';
    let objToSend = {};

    if (!setPosition || this.isDeviceMobile) {
        objToSend = {
            posX,
            posY,
            href,
            showCitationModal: true,
            diamondPositionX,
            diamondPositionY,
            visibility: this.isDeviceMobile ? undefined : 0,
            event: this.isDeviceMobile ? undefined : event
        };
    } else {
        if (setPosition && !this.isDeviceMobile) {
            const {
                posX: newX,
                posY: newY,
                diamondPosX: newDiamondPosX,
                diamondPosY: newDiamondPosY
            } = this.calculatePosForCitationModal(buttonElement, modalWidth, modalHeight, posX, posY, diamondPositionX, diamondPositionY, heightModal);

            objToSend = {
                posX: newX,
                posY: newY,
                href,
                showCitationModal: true,
                diamondPositionX: newDiamondPosX,
                diamondPositionY: newDiamondPosY,
                visibility: 1,
                event: event
            };
        }
    }

    fireEvent(null, "openCitation", { objToSend });
}
    /**
     * This function closes modal after below mentioned timeout.
     * @param null
     */
    
       /**
     * handleHoverStates - It opens citation preview modal if user hovers on citation svg
     * @param {void}
     * @returns {void}
     */
    handleHoverStates = (event) => {
      if(!this.isDeviceMobile){
          if (
            event.target.tagName === 'BUTTON' &&
            event.target.classList.contains('su_citation') &&
            event.target.hasAttribute('data-url')
          ) {
      
            this.setPreviewCitations(event,false);
            event.stopPropagation();
            
          } else if(!this.showModal) {
            this.closeCitationModal();
          }
      } 
  }
    /**
     * handleClickStates - It works for mobile view and open citation preview on click
     * @param {void}
     * @returns {void}
     */ 
  handleClickStates = (event) =>{
    if(this.isDeviceMobile){
         if(event.target.tagName === 'BUTTON' && event.target.classList.contains('su_citation') && event.target.hasAttribute('data-url')){
          this.setPreviewCitations(event,false);
         }
      }
  }

  // handler functions dealing with the caching the response and animating it
  clearCache = () => {
    const keys = Object.keys(this.cache);
    if (keys.length < this.CACHE_SIZE) return;
    const keyToDelete = keys.reduce((minKey, currentKey) => {
      const minValue = parseInt(currentKey.split("-").pop(), 10);
      return minValue < parseInt(minKey.split("-").pop(), 10)
        ? currentKey
        : minKey;
    }, keys[0]);

    const newCache = { ...this.cache };
    if (newCache.hasOwnProperty(keyToDelete)) {
      delete newCache[keyToDelete];
      this.cache = newCache;
    }
  };

  getNextCacheOrder = () => {
    const keys = Object.keys(this.cache);
    const maxNumber = keys.reduce((max, currentKey) => {
      const currentValue = parseInt(currentKey.split("-").pop(), 10);
      return currentValue > max ? currentValue : max;
    }, 0);
    return maxNumber + 1;
  };

  getCache = (query, context) => {
    const keys = Object.keys(this.cache);
    const cacheKey = keys.find((key) => key.includes(`${query}-${context}`));
    return cacheKey ? this.cache[cacheKey] : null;
  };

  createCache = (query, context, answer, articlesArray) => {
    this.clearCache();
    const order = this.getNextCacheOrder();
    const key = `${query}-${context}-${order}`;
    const articles = articlesArray;
    this.cache = { ...this.cache, [key]: {answer, articles}};
  };

  breakCheck = (effectId) => {
    const exit = effectId != this.latestEffectId;
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
    this.gptPrinting = true;
    this.gptLoader = false;

    this.suGPTSays = "";
    const printer = async (effectId) => {
      for (const c of str) {
       // await this.sleep(1); // gpt stream is roughly that much faster in printing (4 chars per PRINT_INTERVAL)
        if (this.breakCheck(effectId)) return; //break check
        this.suGPTSays = this.suGPTSays + c;
      }
      this.gptPrinting = false;
      if(articles){
        // this.showArticleLinks = true;
        this.articleList = articles;
      }else{
        //  this.showArticleLinks = false;
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
    let i;
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
          "search-client-type": 8,
          "uid": this.uid,
          "search-id": window._gza_analytics_id ,
          "taid-device":window._gr_utility_functions.getCookie("_gz_taid")|| '',
          "sid-session": window._gr_utility_functions.getCookie("_gz_sid") || ''
        },
        body: JSON.stringify(data)
      }
    );

    if (response.ok) {
      this.gptLoader = false;
      this.gptPrinting = true;
    } else {
      this.showMoreBtn = false;
      if(response.status == '401'){
        this.gptBoxHeightAsPerContent();
      }
      this.gptLoader = false;
      this.gpthasError = true;
      // this.showArticleLinks = false;
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

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const chunk = textDecoder.decode(value);

      const articlesData =
      chunk
        ?.split(self.STREAM_DELIMITER)
        .filter(Boolean);

      if(firstIteration){
        if(articlesData){
          let sources = JSON.parse(articlesData[0]);
          if(sources?.data?.no_answer?.length){
            this.errorResponseArr = sources.data.no_answer;
          }
          if(sources.status == '400'|| this.errorObject.show){
            this.gptBoxHeightAsPerContent();
          }
          if(sources.data != null)
          {
              articleList = sources?.data?.articles || [];
              articleList = articleList.map(item=>{
              return {...item, title: this.getTrimmedTitle(item.title), hoverTitle:item.title}
            })
          }   
        firstIteration = false;
      }
      }

      var dataArray =[];
      chunk?.split(this.STREAM_DELIMITER).forEach((data) => {
            let jsonString = data;
            try {
                let validJson = partialAccumulator + data;
                validJson.split(this.STREAM_DELIMITER).filter(Boolean).forEach((i, j) => {
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
                    this.llm_id = parsedJSON && parsedJSON.data && parsedJSON.data.id;
                    dataArray.push(parsedJSON?.data?.choices?.[0]?.delta?.content || '');
                })
            } catch (e) {
                partialAccumulator += jsonString || '';
            }
      });

      let i = 0;
      if (this.gptStreaming) {
        while (i < dataArray.length) {
        //  await this.sleep(this.PRINT_INTERVAL);
          if (this.breakCheck(effectId)) return; //break check
          gptAnswer += dataArray[i] || "";
          this.suGPTSays = gptAnswer;
          i++;
        }
      } else { this.animateText(dataArray[0], effectId); }// animate single chunk ( for streaming OFF )
      if (this.breakCheck(effectId)) return; //break check
    }
    if (!gptAnswer) {  
      this.gptLoader = false;
      this.gpthasError = true;
      this.showMoreBtn = false;
      this.animateText(this.failText, effectId);
      return;
   }

    this.gptPrinting = false;
    //cache needs to be created for the particular search string(Already fine), context received from the API(this.gptContext) and the gptAnswer(Can be used as it is written)++

    let errorResponseData = this.errorResponseArr.some(e => e === this.suGPTSays);
    if(errorResponseData || this.errorObject.show){
      this.showMoreBtn = false;
      this.gptBoxHeightAsPerContent();
      // self.showArticleLinks = false;
      self.articleList = [];
    }
    else{
      // self.showArticleLinks = true;
      this.showFeedbackIcons = true;
      self.articleListPreview = articleList.slice(0, 3);
      self.articleList = self.articleListPreview
      self.allArticles = articleList;
      this.createCache(data.query, data.description, gptAnswer, articleList);
    }

    fireEvent(null,"gptResponse", this.suGPTSays);

  }

  async gptRoutine() {
    let self = this;
    this.showMoreBtn = false;
    fireEvent(null,"getGptSandboxVal", "enableSandboxGptFeedabck");
    self.errorObject.show = false;
    this.thumbsUpPositiveFeedback = false;
    this.thumbsDownNegativeFeedback = false;
    this.copiedToClipboard = false;
    this.showFeedbackIcons = false


    if(String(self.pageNum) != "1"){
      let errorResponseData = this.errorResponseArr.some(e => e === this.suGPTSays);
      if(!errorResponseData){
        this.showMoreBtn = true;
      }else{
        this.showMoreBtn = false;
        return;
      }
    }

    if (this.template.querySelector(`[data-id="su__gpt-box"]`) && this.template.querySelector(`[data-id="su__gpt-box"]`).classList) {
        this.template.querySelector(`[data-id="su__gpt-box"]`).classList.add('su__desktopMin-Heigth');
      }
    
    // self.showArticleLinks = false;

    if (self.searchString == "") {
      this.showMoreBtn = false;
      this.gptBoxHeightAsPerContent();
      const effectId = Math.random();
      self.latestEffectId = effectId;
      self.gpthasError = true;
      self.animateText(this.emptySearchString, effectId);
      return;
    }

    let data = {
      description: self.gptcontext,
      query: self.searchString,
      llm: true,
      streaming: self.gptStreaming
    };


    if (String(self.pageNum) == "1") {
      const effectId = Math.random();
      self.latestEffectId = effectId;
      self.gptLoader = true;
      self.gpthasError = false;
      self.suGPTSays = "";
      // Check if the answer exists in cache (saves API calls)
      // Check to be performed on the search string and the gptContext coming from the API(this.gptContext) ++
      const cachedAnswer = self.getCache(data.query, data.description);
      // If found render it with animation
      if (cachedAnswer) {
        const result = JSON.parse(JSON.stringify(cachedAnswer));        
          if(result.articles.length === 3) {
            this.toggleArticleText = 'Show less';
            this.articleListPreview = this.allArticles
          }else{
            this.toggleArticleText = 'Show More';
            this.articleListPreview = this.articleList; 
          }
          if(result.thumbsUpPositiveFeedback){
            this.thumbsUpPositiveFeedback = true;
            this.thumbsDownNegativeFeedback= false;
          }else if(result.thumbsDownNegativeFeedback){
            this.thumbsUpPositiveFeedback = false;
            this.thumbsDownNegativeFeedback = true;
          }
          this.showMoreBtn = true;
          fireEvent(null,"gptResponse", result.answer);
         
        self.animateText(result.answer, effectId, this.articleListPreview);
        let errorResponseData = this.errorResponseArr.some(e => e === this.suGPTSays);
        if(!errorResponseData){
          this.showFeedbackIcons = true;
        }
      } else {
        try {
          setTimeout(()=>{
            let errorResponseData = this.errorResponseArr.some(e => e === this.suGPTSays);
            if(!errorResponseData && !this.errorObject.show){
              this.showMoreBtn = true
            }
          },1000)
          const effectId = Math.random();
          self.latestEffectId = effectId;
          if(!self.animatorRefs[effectId]) self.animatorRefs[effectId] = [];
          self.animatorRefs[effectId].push(setTimeout(() => self.readStream(effectId)));
        } catch (e) {
          self.showMoreBtn = false;
          this.gptBoxHeightAsPerContent();
          console.log(e);
        }
      }
    }
  }

    gptBoxHeightAsPerContent(){
      if (this.template.querySelector(`[data-id="su__gpt-box"]`) && this.template.querySelector(`[data-id="su__gpt-box"]`).classList) {
        this.template.querySelector(`[data-id="su__gpt-box"]`).classList.remove('su__desktopMin-Heigth');
      }
    }



  handleShowMoreClick(){
      this.showMoreBtn = false;
      window.gza('llm_show_more', {
         llmRequestId: this.llm_id,
        searchId: window._gza_analytics_id ,
        uid:this.uid ,
        sid_session: window._gr_utility_functions && window._gr_utility_functions.getCookie("_gz_taid"),
        ts : new Date().getTime()

      });
  }

  setCommunityCustomSettings(result) {
    if (result && result.isCustomSettingFilled) {
      this.endPoint = result.endPoint;
      this.bearer = result.token;
    } else {
      this.customSettingsFilled = false;
      this.customSettingErrorMessage =
        "Please configure your SearchUnify and try again.";
    }
  }

  searchCallMade(val){
    if(val){
      this.gptRoutine();
    }
  }
  setPosition(data){
   this.setPreviewCitations(data.event , data.setPosition , data.heightModal)
  }

  async connectedCallback() {
    this.getCommunityCustomSettings = await getCommunitySettings();
    this.setCommunityCustomSettings(this.getCommunityCustomSettings);
    registerListener("searchCallMade",this.searchCallMade,this);
    registerListener("showCitation",this.showModalCitation,this)
    
    registerListener("setPosition",this.setPosition,this)
    registerListener("closeCitationModal",this.closeCitationModal,this)
    //Gpt routine will be called for the very first render
    this.gptRoutine();
    if(!this.isDeviceMobile){
      document.body.addEventListener('mouseover', this.handleHoverStates,false);
      window.addEventListener('scroll', () => {
        this.closeCitationModal();
    });
     }
    else if(this.isDeviceMobile){
      this.template.addEventListener('click', this.handleClickStates,{ bubbles:false });
    }
  }
  showModalCitation(){
    this.showModal = true
  }

  disconnectedCallback() {
    unregisterListener("searchCallMade", this.searchCallMade, this);
    unregisterListener("showCitation",this.showModalCitation,this);
    unregisterListener("setPosition",this.setPosition,this);
    unregisterListener("closeCitationModal",this.closeCitationModal,this)
    document.body.removeEventListener('mouseover', this.handleHoverStates,false);
    window.removeEventListener('scroll', ()=>{setTimeout(this.closeCitationModal, 300)});
    this.template.removeEventListener('click', this.handleClickStates,{ bubbles:false });
  }
}