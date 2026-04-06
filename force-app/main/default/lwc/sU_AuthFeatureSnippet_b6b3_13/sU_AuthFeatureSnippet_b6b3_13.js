import { LightningElement, api, track } from 'lwc';
import { registerListener, unregisterListener, fireEvent } from 'c/authsupubsub_b6b3_13';
export default class SU_AuthFeatureSnippet extends LightningElement {
    @api featureSnippet;
    @api featureSnippetData;
    @track featuredResponseRecorded;
    @track timeoutResponse = false;
    isSnippetCollapsed = true;
    isSnippetExpanded = false;
    maxSnippetSteps = 3;
    @api searchQueryData;
    @api translationObject;
    @api multiMediaData
    @track hideIcon = false;
    @track congratsTextHide = false;
    @track firstTimeRatingIcon = true;

    get featureSnippetClass() {
        return `su__FeaturedSnippet su__bg-white su__sm-shadow su__radius-1 su__position-relative su__mb-3 su__mt-2 su__p-3 su__d-md-flex su__overflow-hide su__w-100 su__md-none`;
    }

    get featureSnippetLeftClass() {
        return this.featureSnippetData && this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length ? 'su__featureSnippet-left su__d-flex su__flex-column su__overflow-hide su__mr-4 su__w-75' : 'su__featureSnippet-left su__d-flex su__flex-1 su__flex-column su__overflow-hide su__mr-4';
    }

    get featureSnippetMetadataExists() {
        return this.featureSnippetData && this.featureSnippetData.metadata && this.featureSnippetData.metadata.length > 0;
    }

    get featureSnippetMetaData() {
        var arrayOfObjects1 = [];
        if (this.featureSnippetData && this.featureSnippetData.metadata) {
            var fsMetaDataObj = this.featureSnippetData.metadata
            for (var key in fsMetaDataObj) {
                var metdataMediaVal = {
                    key: fsMetaDataObj[key].key,
                    value: fsMetaDataObj[key].value
                };
                arrayOfObjects1.push(metdataMediaVal);
            }
            arrayOfObjects1.forEach(meta => {
                if (meta) {
                    meta.showMetaNotTag = meta.value.length > 0 && meta.key != 'Tag' ? true : false;
                    meta.showMetaKey = meta.key == 'post_time' ? 'Created Date' : meta.key;
                    meta.metaKeyPost_time = meta.key == 'post_time' ? true : false;
                    if (meta.key != 'Tag' && meta.key != 'post_time') {
                        meta.value.forEach((ele, index) => {
                            if (index == 0) {
                                meta.singleVal = true
                            }
                        })
                    }
                    meta.showMetaTag = meta.value.length > 0 && meta.key == 'Tag' ? true : false;
                    if (meta.key == 'Tag') {
                        meta.showMetaDataTagKey = meta.key
                        meta.showMetaDataTagValueString = meta.valueString;
                    }

                }
            });
        }
        return arrayOfObjects1;
    }

    hideRatingIcons(featuredSnippetIndex) {
        let updatedMultiMediaData1 = [...this.multiMediaData]
        updatedMultiMediaData1[featuredSnippetIndex].response = true;
        updatedMultiMediaData1[featuredSnippetIndex].timeoutResponse = true;
        this.hideIcon = true;
        this.multiMediaData = updatedMultiMediaData1;
        this.featureSnippetMultiMediaDataManipulation;
    }

    hideCongratsText(featuredSnippetIndex) {
        let updatedMultiMediaData2 = [...this.multiMediaData]
        updatedMultiMediaData2[featuredSnippetIndex].timeoutResponse = false;
        this.congratsTextHide = true;
        this.multiMediaData = updatedMultiMediaData2;
        this.featureSnippetMultiMediaDataManipulation;
    }

    get featureSnippetMultiMediaDataManipulation() {
        if (this.firstTimeRatingIcon) {
            this.multiMediaData = JSON.parse(JSON.stringify(this.featureSnippetData.multiMedia));
            this.multiMediaData.forEach(ele => {
                if (ele) {
                    ele.response = false;
                    ele.timeoutResponse = false;
                    ele.multiMediaHrfVideo_url = (ele.href || ele.video_url) ? (ele.href || ele.video_url) : '';
                    ele.titletoDisplay = ele.title ? ele.title[0] : '';
                    ele.thumbnailExists = ele.thumbnail ? true : false;
                    ele.showThumbnailUrl = (ele.image_urls || ele.thumbnail) ? (ele.image_urls || ele.thumbnail) : '';
                    ele.thumbnailAltAttribute = ele.alt_attributes ? ele.alt_attributes : '';
                }
            });
            this.firstTimeRatingIcon = false;
        }

        if (this.featureSnippetData && this.featureSnippetData.multiMedia && !this.hideIcon && !this.congratsTextHide) {
            this.multiMediaData = JSON.parse(JSON.stringify(this.featureSnippetData.multiMedia));
            this.multiMediaData.forEach(ele => {
                if (ele) {
                    ele.response = false;
                    ele.timeoutResponse = false;
                    ele.multiMediaHrfVideo_url = (ele.href || ele.video_url) ? (ele.href || ele.video_url) : '';
                    ele.titletoDisplay = ele.title ? ele.title[0] : '';
                    ele.thumbnailExists = ele.thumbnail ? true : false;
                    ele.showThumbnailUrl = (ele.image_urls || ele.thumbnail) ? (ele.image_urls || ele.thumbnail) : '';
                    ele.thumbnailAltAttribute = ele.alt_attributes ? ele.alt_attributes : '';
                }
            });
        }
        return this.multiMediaData;
    }

    get featureSnippetMultiMediaGreatorOne() {
        return this.featureSnippetData && !this.featureSnippetData.steps &&
            this.featureSnippetData.questionAnswer && this.featureSnippetData.questionAnswer.answer == null &&
            this.featureSnippetData.questionAnswer.short_summary == null &&
            this.featureSnippetData.multiMedia &&
            this.featureSnippetData.multiMedia.length > 1 ? true : false;
    }

    get featureSnippetMultiMediaEqualToOne() {
        return this.featureSnippetData && !this.featureSnippetData.steps &&
            this.featureSnippetData.questionAnswer && this.featureSnippetData.questionAnswer.answer == null &&
            this.featureSnippetData.questionAnswer.short_summary == null &&
            this.featureSnippetData.multiMedia &&
            this.featureSnippetData.multiMedia.length == 1 ? true : false;
    }

    get featureSnippetQuestionAnswer() {
        return this.featureSnippetData && !this.featureSnippetData.steps &&
            this.featureSnippetData.questionAnswer && this.featureSnippetData.questionAnswer &&
            this.featureSnippetData.questionAnswer.answer &&
            this.featureSnippetData.questionAnswer.short_summary ? true : false;
    }


    get featureSnippetSteps() {
        return this.featureSnippetData && this.featureSnippetData.steps;
    }

    get featureSnippetStepsDataExist() {
        return this.featureSnippetData && this.featureSnippetData.steps && this.featureSnippetData.steps.length != 0 ? true : false;
    }


    get featureThreeSnippetSteps() {
        return this.featureSnippetData && this.featureSnippetData.steps && this.featureSnippetData.steps.slice(0, 3);
    }

    get isSnippetMore() {
        return this.featureSnippetData && this.featureSnippetData.steps.length > 3;
    }

    get featureSnippetTitleToDisplay() {
        return this.featureSnippetData && this.featureSnippetData.highlight && this.featureSnippetData.highlight.TitleToDisplay[0];
    }

    get featureSnippetTitleToDisplayString() {
        return this.featureSnippetData && this.featureSnippetData.highlight && this.featureSnippetData.highlight.TitleToDisplayString[0];
    }
    get featureSnippet_alt_attributes() {
        return this.featureSnippetData && this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia[0].alt_attributes;
    }

    get featureSnippetMultiMediaTitle() {
        return this.featureSnippetData && this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia[0].title[0];
    }

    get featureSnippetMediaImgUrl() {
        return this.featureSnippetData && this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia[0].image_urls || this.featureSnippetData.multiMedia[0].thumbnail
    }

    get featureSnippetMultiMediaHrf() {
        return this.featureSnippetData && this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia[0].href ? this.featureSnippetData.multiMedia[0].href : '';
    }

    get featureSnippetMultiMediaHrf_Or_Video_url() {
        return this.featureSnippetData && this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia[0].href ? this.featureSnippetData.multiMedia[0].href : this.featureSnippetData.multiMedia[0].video_url;
    }



    get showMoreClass() {
        return this.isSnippetCollapsed
            ? 'su__cursor su__position-relative su__mb-1 su__font-12 su__color-blue su__f-regular su__showmore-text su__d-inline-block su__loading-view'
            : 'su__d-none';
    }

    get showLessClass() {
        return this.isSnippetCollapsed === false
            ? 'su__cursor su__position-relative su__mb-1 su__font-12 su__color-blue su__f-regular su__showmore-text su__d-inline-block su__loading-view'
            : 'su__d-none';
    }

    get featureSnippetRightClass() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length
            ? 'su__featureSnippet-right su__d-flex su__flex-column su__featured-thumbnail su__position-relative'
            : 'su__featureSnippet-right su__d-flex su__flex-column su__w-80px ';
    }


    get fsAnsweredMultiMedia() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length ?
            'su__feedback-row su__d-flex su__pt-2 su__pr-2' : 'su__feedback-row su__d-flex';
    }

    get fsAnsweredMultiMediaFeedabckMsg() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length ?
            'su__feedback-thankyou su__feedback-icon-above su__position-absolute su__zindex-1 su__loading-view' : 'su__feedback-icon-above su__position-absolute su__right-QuestionAnswer su__zindex-1 su__loading-view';
    }

    get hasMultiMedia() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length !== 0 ? true : false;
    }

    get hasThumbnail() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia[0].thumbnail ? true : false;
    }

    get hasMultiMediaForQuestionAnswer() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length != 0 ? 'su__featureSnippet-left su__d-flex su__flex-1 su__flex-column su__overflow-hide su__mr-4 su__w-75' : 'su__featureSnippet-left su__d-flex su__flex-1 su__flex-column su__overflow-hide su__mr-4'
    }

    get featuredThumbnailClass() {
        return this.featureSnippetData.multiMedia && this.featureSnippetData.multiMedia.length
            ? 'su__featureSnippet-right su__featured-thumbnail su__py-sm-2'
            : '';
    }

    get thanksForFeedbackFeatureSnippet() {
        return this.featuredResponseRecorded && this.timeoutResponse ? true : false;
    }

    toggleSnippetCollapse() {
        this.isSnippetCollapsed = !this.isSnippetCollapsed;
        this.isSnippetExpanded = !this.isSnippetExpanded;
    }

    runScriptMethod(e) {
        fireEvent(null, 'trackAnalytics', {
            type: 'conversion', objToSend: {
                searchString: this.searchQueryData.searchString,
                index: e.currentTarget.dataset.index,
                type: e.currentTarget.dataset.type,
                rank: parseInt(e.currentTarget.dataset.rank) + 1,
                convUrl: e.currentTarget.dataset.url,
                convSub: e.currentTarget.dataset.sub || e.currentTarget.dataset.url,
                autoTuned: e.currentTarget.dataset.autotuned ? e.currentTarget.dataset.autotuned : false,
                sc_analytics_fields: e.currentTarget.dataset.track?e.currentTarget.dataset.track:[]
            }
        });
    }

    sendFeaturedSnippetFeedback(event) {
        var feedback = event.currentTarget && event.currentTarget.dataset.feedback;
        var datafeaturedSnippet = event.currentTarget && event.currentTarget.dataset.featuredSnippet;
        this.featuredResponseRecorded = true;
        this.timeoutResponse = true;

        if (datafeaturedSnippet) {
            this.featuredSnippetIndex = event.currentTarget && event.currentTarget.dataset.index;
            var multiMedia = this.multiMediaData;
            this.hideRatingIcons(this.featuredSnippetIndex);
            var url = multiMedia[this.featuredSnippetIndex].href;
            var title = multiMedia[this.featuredSnippetIndex].title[0] || multiMedia[this.featuredSnippetIndex].href;
            fireEvent(null, 'trackAnalytics', {
                type: 'featuredSnippet', objToSend: {
                    "searchString": this.searchQueryData.searchString,
                    "url": this.featureSnippetData.href,
                    "t": title.substring(0, 300),
                    "uid": this.searchQueryData.uid,
                    "feedback": feedback,
                    "referrer": this.searchQueryData.referrer
                }
            });
            this.scheduleTimeout(this.featuredSnippetIndex);

        } else {
            fireEvent(null, 'trackAnalytics', {
                type: 'featuredSnippet', objToSend: {
                    "searchString": this.searchQueryData.searchString,
                    "url": this.featureSnippetData.href,
                    "t": this.featureSnippetTitleToDisplayString.substring(0, 300) || this.featureSnippetData.highlight.href,
                    "uid": this.searchQueryData.uid,
                    "feedback": feedback,
                    "referrer": this.searchQueryData.referrer
                }
            });
            setTimeout(() => {
                this.timeoutResponse = false;
            }, 2000);
        }
    }

    async scheduleTimeout(index) {
        await this.delay(2000);
        this.hideCongratsText(index);
    }

    async delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    } 

    featuredResponseRecordedDatafun(val) {
        this.isSnippetCollapsed = true;
        this.isSnippetExpanded = false;
        this.featuredResponseRecorded = val;
    }
    hideRatingIconsfunc(value) {
        this.firstTimeRatingIcon = value;
    }

    connectedCallback() {
        registerListener("featuredResponseRecordedDatafunc", this.featuredResponseRecordedDatafun, this);
        registerListener("hideRatingIconsfunc", this.hideRatingIconsfunc, this);
    }

    disconnectedCallback() {
        unregisterListener("featuredResponseRecordedDatafunc", this.featuredResponseRecordedDatafun, this);
        unregisterListener("hideRatingIconsfunc", this.hideRatingIconsfunc, this);
    }
}