import { LightningElement, api, track, wire } from 'lwc';
import { createRecord } from 'lightning/uiRecordApi';
import { graphql, gql } from 'lightning/uiGraphQLApi';

import GOOGLE_PRIVACY_POLICY from '@salesforce/label/c.Google_privacy_policy_link';
import CALENDLY_PRIVACY_POLICY from '@salesforce/label/c.Calendly_privacy_policy_link';

import CASE_COMMENT_OBJECT from '@salesforce/schema/CaseComment';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';


const TOAST = {
    VARIANT: {
        SUCCESS: 'success',
        ERROR: 'error'
    }
}


export default class ActionCaseSendCalendarLink extends LightningElement {
    @api recordId;
    caseRecord;

    get graphVariables() {
        return {
            recordId: this.recordId,
        };
    }

    @wire(CurrentPageReference)
    getPageRef(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.attributes?.recordId;
        }
    }

    @wire(graphql, {
        query: gql`query getCase($recordId: ID) {
                    uiapi {
                        query {
                            Case(where: { Id: { eq: $recordId } }){
                                edges {
                                    node {
                                        Id
                                        Owner {
                                            ... on User {
                                                Id
                                                Calendar_booking_URL__c {
                                                    value
                                                }
                                            }
                                            ... on Group {
                                                Id
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }`,
        variables: '$graphVariables'
    })
    graphqlResult

    @api async invoke() {
        setTimeout(() => {
            console.log('Invoked with Record ID:', this.recordId);
            console.log('GraphQL Response:', JSON.stringify(this.graphqlResult));

            const data = this.graphqlResult?.data;
            const errors = this.graphqlResult?.errors;

            if (!data || errors) {
                console.error('GraphQL Error:', JSON.stringify(errors));
                this.showToast(TOAST.VARIANT.ERROR, 'An unexpected error occurred. Please contact the Administrator.');
                return;
            }

            // Extract Case and Owner details
            const caseRecords = data.uiapi.query?.Case?.edges?.map((item) => {
                const owner = item.node.Owner;
                return {
                    Id: item.node.Id,
                    ownerId: owner?.Id,
                    isOwnerGroup: owner?.Id?.startsWith('00G'),
                    calendarBookingURL: owner?.Calendar_booking_URL__c?.value
                };
            }).filter(Boolean);

            if (!caseRecords.length) {
                this.showToast(TOAST.VARIANT.ERROR, 'No Case records found.');
                return;
            }

            const caseRecord = caseRecords[0]; // Assuming only one case record is returned

            try {
                if (!caseRecord.ownerId) {
                    this.showToast(TOAST.VARIANT.ERROR, 'Case owner information is missing.');
                    return;
                }

                if (caseRecord.isOwnerGroup) {
                    this.showToast(TOAST.VARIANT.ERROR, 'Case owner is a Queue. Please assign it to user before sending Calendar Booking URL.');
                    return;
                }

                if (!caseRecord.calendarBookingURL) {
                    this.showToast(TOAST.VARIANT.ERROR, 'No link indicated in the CALENDAR BOOKING URL field')
                    return;
                }

                const commentText = `To best assess the reported issue, I would like to schedule an online, one-on-one session with you to gather more information as well as answer any questions you may have. I look forward to connecting with you soon.\n\n`
                    + `Schedule a session with Rubrik Support: ${caseRecord.calendarBookingURL}\n\n`
                    + `Note: Rubrik uses Google Calendar or Calendly to schedule meetings. Please reference the Google privacy policy ( ${GOOGLE_PRIVACY_POLICY} ) and Calendly privacy policy ( ${CALENDLY_PRIVACY_POLICY} ).`;

                const caseComment = {
                    apiName: CASE_COMMENT_OBJECT.objectApiName,
                    fields: {
                        ParentId: caseRecord.Id,
                        CommentBody: commentText,
                        IsPublished: true,
                    },
                };
                this.createComment(caseComment);
                // const recordResult = await createRecord(caseComment);

                // if (recordResult && recordResult.id) {
                //     this.showToast(TOAST.VARIANT.SUCCESS, 'Public comment added successfully.');
                // } else {
                //     this.showToast(TOAST.VARIANT.ERROR, 'Failed to create Case Comment.');
                // }
            } catch (error) {
                console.error('Error Creating Case Comment:', error);
                this.showToast(TOAST.VARIANT.ERROR, `An unexpected error occurred: ${error.body?.message || error.message}`);
            }
        }, 2000);

    }

    async createComment(caseComment) {
        const recordResult = await createRecord(caseComment);
        if (recordResult && recordResult.id) {
            this.showToast(TOAST.VARIANT.SUCCESS, 'Public comment added successfully.');
        } else {
            this.showToast(TOAST.VARIANT.ERROR, 'Failed to create Case Comment.');
        }
    }

    @track type = 'success';
    @track message;
    @track showToastBar = false;

    @api
    showToast(type, message) {
        const event = new ShowToastEvent({
            title: '',
            message: message,
            variant: type
        });
        this.dispatchEvent(event);
        this.closeModel();
    }

    closeModel() {
        this.showToastBar = false;
        this.type = '';
        this.message = '';
    }
}