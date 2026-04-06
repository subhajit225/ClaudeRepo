import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import Subject_FIELD from "@salesforce/schema/Case.Subject";
import Desc_FIELD from "@salesforce/schema/Case.Description";
import { registerListener } from 'c/supubsub';

const fields = [Desc_FIELD, Subject_FIELD];
export default class SU_SlackChannels extends LightningElement {
    token;
    @api endPoint;
    @api uid;
    showSlackChannels = false;//flag variable used to toggle display of slack window instead of experts data that is in its parent component
    slackOptions;//variable used to store the slack channels that are being retrieved and is also used for iteration to display the data to user
    // slackCheckboxSelected = false;
    selectedChannelValue = [];//used to store the value of the slack channel being selected 
    @api eventCode;
    @api recordId;
    @api height = 0;

    @wire(getRecord, {
        recordId: "$recordId",
        fields
    })
    case;
    slackConnectionRetries = 0;
    noSlackChannelsExist = true;
    scrollChannelsCss = 'height: '+this.height ? this.height - 130 : 10+'px;';
    //method called to register on slack if not done earlier and fetch all the slack channels into a variable
    getSlackChannels() {
        this.token = localStorage.getItem('slackTokenLWC_'+this.uid);
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/slackApis/getSlackChannels?uid="+this.uid;
        if (this.token) url += '&token='+ encodeURIComponent(this.token);
        xmlHttp.withCredentials = true;
        xmlHttp.open("GET", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Content-Type', 'application/json');

        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.clientId && result.error === 'Not Authenticated' && !this.slackConnectionRetries) {
                        this.openWindowSlack(result.clientId);
                    } else if (result.ok && result.channels) {
                        this.showSlackChannels = true;
                        this.slackOptions = result.channels.map(x => {
                            x.name = '# '+x.name;
                            return { label: x.name, value: x.id }
                        });
                        this.noSlackChannelsExist = result.channels && result.channels.length ? false : true;
                        if (!this.noSlackChannelsExist) {
                            this.selectedChannelValue = this.slackOptions[0].value;
                        }
                        this.showChannels(false);
                        this.slackConnectionRetries = 0;
                    } else if (result.error === 'Not Authenticated') {
                        this.showNotification('Error', result.error, 'error');
                        this.slackConnectionRetries = 0;
                    } else if (result.error === 'Slack Disabled')
                        this.showNotification('Slack Disabled', 'Share on slack is currently disabled.' , 'error');
                }
            }
        }
        xmlHttp.send();
    }
    //method used to toggle display of parent component data(experts data) instead of child component data(slack channels)
    showCaseExperts() {
        this.showSlackChannels = false;
        this.showChannels(true);
    }
    //Method used to register slack channel that has been selected
    shareToSlack(event) {
        event.currentTarget.blur();
        if (this.selectedChannelValue === '' || this.selectedChannelValue === undefined) {
            this.showNotification('Error', 'Select Slack Channel First', 'error');
            return;
        }

        let data = {
            uid: this.uid,
            channelId: this.selectedChannelValue,
            message: {
                'pretext': getFieldValue(this.case.data, Subject_FIELD),
                'text': getFieldValue(this.case.data, Desc_FIELD)
            },
            token: localStorage.getItem('slackTokenLWC_'+this.uid)
        }
        var xmlHttp = new XMLHttpRequest();
        var url = this.endPoint + "/slackApis/postMessageOnSlack";
        xmlHttp.withCredentials = true;
        xmlHttp.open("POST", url, true);
        xmlHttp.setRequestHeader("Accept", "application/json");
        xmlHttp.setRequestHeader('Content-Type', 'application/json');
        xmlHttp.onload = () => {
            if (xmlHttp.readyState === 4) {
                if (xmlHttp.status === 200) {
                    var result = JSON.parse(xmlHttp.response);
                    if (result.message === 'Message posted') {
                        this.showNotification('Success!!!', 'Message has been Posted On Slack', 'success');
                    }
                    else this.showNotification('Error', 'Unable to share case details.', 'error');
                }
            }
        }
        xmlHttp.send(JSON.stringify(data));
    }


    //method used to set the value of the slack channel that is to be registered
    updateChannelValue(event) {
        this.selectedChannelValue = event.detail.value.filter(d => !this.selectedChannelValue.includes(d));
        event.currentTarget.blur();
    }
    //method used to fire event that toggles the display of parent component data(experts window) or child component data(slack window)
    showChannels(data) {
        var hideCaseExperts = new CustomEvent('hidecaseexperts', { detail: data });
        this.dispatchEvent(hideCaseExperts);
    }
    //method used to open a new window that can be used to register for slack if not done earlier
    openWindowSlack(clientId) {
        if (this.slackConnectionRetries) {
            this.slackConnectionRetries = 0;
            return this.slackConnectionRetries;
        }
        let self = this;
        var newWindow = window.open(`https://slack.com/oauth/authorize?client_id=${clientId}&scope=channels:read,groups:read,mpim:read,im:read,chat:write:user&redirect_uri=https://oauthsfdc.searchunify.com&state=${this.endPoint}/slackApis/slackAuthsu_csid${this.uid}url=${window.location.origin}`, 'name', 'height=400,width=400');
        (function afterCloseChild() {
            if (newWindow.closed) {
                //this.shareToSlack();
                self.slackConnectionRetries++;
                self.getSlackChannels();
            } else {
                setTimeout(afterCloseChild, 500);
            }
        })();
       return null;
    }
    //connectedCallback called on component load that stores token to local storage after we register to slack
    connectedCallback() {
        let self = this;
        window.addEventListener('message', function (event) {
            if (self.endPoint === event.origin) {
                self.token = event.data;
                localStorage.setItem('slackTokenLWC_'+self.uid, event.data);
            } 
        });
        registerListener('getSlackChannels'+this.eventCode, this.getSlackChannels, this);
    }

    //method that displays toast message (error or success message) based on whether slack channel has been registered or not
    showNotification(notificationTitle, notificationMessage, notificationVariant) {
        const evt = new ShowToastEvent({
            title: notificationTitle,
            message: notificationMessage,
            variant: notificationVariant,
        });
        this.dispatchEvent(evt);
    }
}