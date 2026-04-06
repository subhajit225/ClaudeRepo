import { LightningElement, api } from 'lwc';

export default class KnowblerStepContent extends LightningElement {
  @api title;

  @api summary;

  @api imagesrc;

  @api flexipageregionwidth;
}