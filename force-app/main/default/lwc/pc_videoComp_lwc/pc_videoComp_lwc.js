import { LightningElement, api } from 'lwc';
export default class Pc_videoComp_lwc extends LightningElement {
    @api height = 400;
    @api width = 1000;
    @api src;
}