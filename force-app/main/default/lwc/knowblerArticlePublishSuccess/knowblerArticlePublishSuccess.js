import { LightningElement, api, track, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';

export default class KnowblerArticlePublishSuccess extends LightningElement {
  @api ispublishnow;

  @api articleattach;

  @api publish = false;

  @api attachsuccesfull;

  @api articleattachpublished;

  @api attacharticle;

  @api articledetach;

  @api linkcopied;

  articleSuccessful;

  attachSuccessful;

  detachsuccessful;

  linkcopiedimg;

  wait;

  attachedSuccessMessage = 'Article Published & attached Successfully';

  publishSuccessMessage = 'Article published successfully';

  attachSuccessMessage = 'Done';

  detachSuccessMessage = 'Article detached';

  copymessage = 'Link copied';

  waitmessage = 'Please Wait....';

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.articleSuccessful = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_articlesuccessful.svg`;
      this.attachSuccessful = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/u_articlesuccessful.svg`;
      this.detachsuccessful = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/successfullydetachcase.svg`;
      this.linkcopiedimg = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/linkcopied.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }
}