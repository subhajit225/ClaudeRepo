import { LightningElement, track, api, wire } from 'lwc'
import {
  subscribe,
  unsubscribe,
  onError,
  setDebugFlag,
  isEmpEnabled
} from 'lightning/empApi'
import { CurrentPageReference } from 'lightning/navigation'
import updateOpportunity from '@salesforce/apex/OpportunityStageMovingController.updateOpportunity'
import loginUserId from '@salesforce/user/Id'
import labels from './labels'

export default class OpportunityStageMovingConfirmation extends LightningElement {
  @api recordId
  @track modal = false
  @track disableSave = false
  @track subscription = {}
  @track channelName = '/event/Opportunity_Notification__e'
  @api inactivateStdPopup = false

  msgType = ''
  stagemoving = false
  isAspen = false
  isRubrik_TBD = false //SAL24-651
  isMarketplace = false //SAL24-652
  isStageSkippedTo6 = false //SAL26-314
  isStage4to5 = false //SAL26-314
  labels = labels

  connectedCallback () {
    this.handleSubscribe()
  }
  handleSubscribe () {
    const thisReference = this
    const messageCallback = function (response) {
    if (!this.inactivateStdPopup) {
        let styleSheet = document.createElement('style')
        styleSheet.type = 'text/css'
        styleSheet.innerText = '.DESKTOP.uiContainerManager { DISPLAY: NONE; }'
        styleSheet.id = 'HideOpportunityStandardEditPopup'
        document.head.appendChild(styleSheet)
      }
      var result = JSON.parse(response.data.payload.Payload__c)
      this.stagemoving = false
      this.isAspen = false
      this.isRubrik_TBD = false
      this.isMarketplace = false
      this.isStage4to5 = false
      this.isStageSkippedTo6 = false
      if (
        loginUserId == result.loginUserId &&
        this.recordId == result.recordId
      ) {
        console.log(this.msgType);
        console.log(this.msgType);
        this.modal = true
        this.msgType = result?.ErrorType
        if (this.msgType == 'StageMoving') {
          this.stagemoving = true
        } else if (this.msgType == 'ASPENChange') {
          this.isAspen = true
        } else if (this.msgType == 'RubrikTBD') {
          this.isRubrik_TBD = true
        } else if (this.msgType == 'DistriMarketplace') {
          this.isMarketplace = true
        } else if (this.msgType == 'Stage4to5') {
          this.isStage4to5 = true
        } else if (this.msgType == 'StageSkippedTo6') {
          this.isStageSkippedTo6 = true
        } else {
          this.modal = false
        }
      }
    }

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback.bind(this)).then(
      response => {
        // Response contains the subscription information on subscribe call
        console.log(
          'Subscription request sent to: ',
          JSON.stringify(response.channel)
        )
        this.subscription = response
      }
    )
  }
  hideModal (event) {
    let styleSheet = document.getElementById('HideOpportunityStandardEditPopup')
    styleSheet?.remove()
    this.modal = false
  }
  save (event) {
    let styleSheet = document.getElementById('HideOpportunityStandardEditPopup')
    styleSheet?.remove()
    var type = this.msgType
    this.disableSave = true
    updateOpportunity({
      recordId: this.recordId,
      type: type
    })
      .then(result => {
        this.modal = false
        this.disableSave = false
        this.stagemoving = false
        this.isAspen = false
        this.isRubrik_TBD = false
        this.isMarketplace = false
        this.isStage4to5 = false
        this.isStageSkippedTo6 = false
      })
      .catch(error => {
        console.log('error..!', error)
        this.disableSave = false
        alert(error.body.message)
      })
  }
}