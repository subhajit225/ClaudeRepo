import { LightningElement, api, track } from 'lwc';

export default class KcsknowblerCircularbar extends LightningElement {
  @track circumference;

  @api predictedscore;

  @api evaluationscore;

  @track progressBackground;

  @track progress;

  @track container;

  @track score;

  connectedCallback() {
    if (!this.evaluationscore) {
      this.score = parseInt(this.predictedscore, 10);
    } else if (this.evaluationscore) {
      this.score = parseInt(this.evaluationscore, 10);
    }
  }

  renderedCallback() {
    const r = this.template
      .querySelector('[data-id="progressid"]')
      .getAttribute('r');
    this.circumference = Math.PI * 2 * r;
    this.template.querySelector(
      '[data-id="progressid"]'
    ).style.strokeDasharray = this.circumference;
    let percent = 0;
    if (!this.evaluationscore) {
      percent = parseInt(this.predictedscore, 10);
    } else if (this.evaluationscore) {
      percent = parseInt(this.evaluationscore, 10);
    }

    this.template.querySelector(
      '[data-id="progressid"]'
    ).style.strokeDashoffset =
      this.circumference - (percent / 100) * this.circumference;
    this.template
      .querySelector('[data-id="containerid"]')
      .setAttribute('data-pct', percent);

    if (this.score == 100) {
      this.progress = 'progressvaluegreen';
      this.progressBackground = 'progressbargreen';
      this.container = 'containergreen';
    } else if (this.score >= 71 && this.score < 99) {
      this.progress = 'progressvalueblue';
      this.progressBackground = 'progressbarblue';
      this.container = 'containerblue';
    } else if (this.score >= 41 && this.score <= 70) {
      this.progress = 'progressvalueyellow';
      this.progressBackground = 'progressbaryellow';
      this.container = 'containeryellow';
    } else if (this.score >= 0 && this.score <= 40) {
      this.progress = 'progressvaluered';
      this.progressBackground = 'progressbarred';
      this.container = 'containerred';
    }
  }
}