import { LightningElement, api, wire } from 'lwc';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
import knowblerPubsub from 'c/knowblerPubsub';

export default class KnowblerCreateArticleButton extends LightningElement {
  @api flexipageregionwidth;

  createArticle;

  connectedCallback() {
    knowblerPubsub.registerListener(
      'disableArticleButton',
      this.articleButton,
      this
    );
    knowblerPubsub.registerListener(
      'enableArticleButton',
      this.enablearticleButton,
      this
    );
  }

  @wire(getBackendUrl)
  wiredData({ error, data }) {
    if (data) {
      this.createArticle = `${data}/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/create_article.svg`;
    } else if (error) {
      console.error('Error:', error);
    }
  }

  openArticleCreate() {
    this.dispatchEvent(new CustomEvent('createarticle'));
  }

  articleButton() {
    const list = this.template.querySelector(
      '.create_article_desktop'
    ).classList;
    list.add('disableButton');
  }

  enablearticleButton() {
    const select = this.template.querySelector(
      '.create_article_desktop'
    ).classList;
    select.remove('disableButton');
  }
}