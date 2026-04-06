import { LightningElement, track, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
import getsettings from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getsettings';

export default class KcsknowblerpredictedScore extends LightningElement {
  circumference;

  @api articlepredictiondata;

  @api alreadyevaluated;

  @api predictedScoreLoading;

  @api predictedscore;

  @api waiting;

  @api noprediction;

  @api languagechanged;

  @api largescreen;

  @api articledata;

  @track endpoint;

  @track jwttoken;

  @track uid;

  @track showEvaluationInProgressAlert = false;


  evaluateimg;

  predictimg;

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.evaluateimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/evaluatetick.svg`;
      this.predictimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/star.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  handlealreadyevaluated() {
    this.dispatchEvent(new CustomEvent('alreadyevaluatedevent'));
  }

   handleProjectedScore() {
    this.dispatchEvent(new CustomEvent('predictedscoreevent'));
  }

  handlehover() {
    if (this.template.querySelector('.evaluatebutton')) {
      this.template
        .querySelector('.evaluatetext')
        .style.setProperty('color', 'white');
    } else {
      this.template
        .querySelector('.predictedScoreText')
        .style.setProperty('color', 'white');
    }
    this.template
      .querySelector('.projectedScore')
      ?.querySelector('span')
      ?.querySelector('img')
      ?.style.setProperty('filter', 'brightness(0%) invert(1)');
  }

  handlehoverout() {
    if (this.template.querySelector('.evaluatebutton')) {
      this.template
        .querySelector('.evaluatetext')
        .style.setProperty('color', '#7E34EC');
    } else {
      this.template
        .querySelector('.predictedScoreText')
        .style.setProperty('color', '#7E34EC');
    }
    this.template
      .querySelector('.projectedScore')
      ?.querySelector('span')
      ?.querySelector('img')
      ?.style.setProperty('filter', 'none');
  }
  async getsettingsdata() {
    getsettings().then((result) => {
      this.endpoint = result.backendurl;
      this.uid = result.uid;
      this.jwttoken = result.token;
    }).catch(err=>{
      this.error = err;
      this.record = undefined;
    });
  }
  connectedCallback() {
    this.getsettingsdata();
  }
  closeEvaluationInProgressPopup(){
    this.showEvaluationInProgressAlert = false;
  }
  async checkEvaluationInProgress (){
    try{
      const articleId = this.articledata.Id;
      const url = `${this.endpoint}/kcs-anlytics/rest/anlytics/content-health/evaluateArticle`;
      const requestOptions = {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          accept: '/',
          'accept-language': 'en-GB,en-US;q=0.9,en;q=0.8',
          'ngrok-skip-browser-warning': true,
          authorization: this.jwttoken
        },
        body: JSON.stringify({
          uid: this.uid,
          articleId
        })
      };
      const result = await fetch(
        url,
        requestOptions
      ).then((response) => response.json());
      const evaluationInProgress = result?.data?.evaluationInProgress ?? false;
      if (!evaluationInProgress) this.dispatchEvent(new CustomEvent('predictedscoreevent'));
      this.showEvaluationInProgressAlert = evaluationInProgress;
    }catch(err){
      console.log("Evaluate article check err------" ,err)
    }
  };
}