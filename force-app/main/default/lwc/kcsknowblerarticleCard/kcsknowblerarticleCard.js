import { LightningElement,api,track,wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
//import My_Resource from '@salesforce/resourceUrl/kcsResources';
import Id from '@salesforce/user/Id';
import TIME_ZONE from '@salesforce/i18n/timeZone';
// import AttachArticleToCase from '@salesforce/apex/KCSPublishController.attachArticleToCase';
// import UpdateArticle from '@salesforce/apex/KCSPublishController.updateArticle';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import knowblerPubsub from 'c/knowblerPubsub';
// import { registerListener, unregisterListener } from 'c/knowblerPubsub';
import { CurrentPageReference } from 'lightning/navigation';
import getBackendUrl from '@salesforce/apex/SU_Knowbler.knowledgeSearchController.getBackendUrl';
 export default class KcsknowblerarticleCard extends LightningElement {
    @api item;
    @api cardindex;
    @api parameters;
    @api languagechanged;
    @api query;
    @track count;
    @api contentstandard;
    @api flexipageregionwidth;
    @api currentuserlanguage;
    @api ispublisharticletab = false;
    @api casedata;
    @api contenthealthdata;
    @api contenthealthdatamap;
    @api progressbar;
    @api circularbar;
    @track evaluatedata;
    @wire(CurrentPageReference) datapageReference;
    @track alreadyevaluatedflag;
    @track progressclass;
    @track progressvalueclass;
    @track articleno;
    @track largescreen;
    editArticle;
    calander;
    edit;
    manage;
    starimg;

    showFistTime = false;
    @api cardindexs;
    @track Imglink;
    @track TourStatus;
    @track userId;
    @track items = {};
    offsetLeft;
    offsetTop;
    @track owneremail;
    postion = 'right';
    cardtitle
    @api cardlength;
    @api destobj;
    @track progress ;
    @track articlepredictiondata;
    @track predictedscore = 0;
    @track alreadyevaluated;
    @track noprediction;
    @track waiting;
    @track timezone;
    @api newnumber;
    @track totalevaluationpoints =0;
    @track evaluationscore;
    recordtype;

    connectedCallback() {
        this.timezone = TIME_ZONE;
         if(!this.flexipageregionwidth) {
            this.largescreen="LARGE";
        }
        this.items = {
            ...this.item
        }
        this.owneremail = this.item?.Owner.Email;
        this.articleno = this.item.ArticleNumber;
        this.contenthealthdata = this.contenthealthdatamap.get(this.item.ArticleNumber);
        this.predication(this.contenthealthdata);
        this.TourStatus = localStorage.getItem('TourStatus') ? JSON.parse(localStorage.getItem('TourStatus')) : {};
        if (Object.keys(this.TourStatus).length && this.TourStatus[window.btoa(encodeURIComponent(Id))]?.status == 'InProgress' && this.cardindex == 0 && this.cardindexs == 0) {
            this.showFistTime = true;
        }
        this.cardtitle = 'cardtitle' + this.cardindex + '_' + this.cardindexs;


    }

    @wire(getBackendUrl)
    wiredData({ error, data }) {
        if (data) {
            this.editArticle = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/edit_article.svg';
            this.calander = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/calander.svg';
            this.edit = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/edit.svg';
            this.manage = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/manage.svg';
            this.starimg = data + '/kcs-agent/kcs_custom_agent/resources/Assets/lwc-images/star.svg';
        } else if (error) {
            console.error('Error:', error);
        }
    }

    predication(response){
        this.articlepredictiondata = response;
        this.totalIncludeParameters();
        if (this.articlepredictiondata) {
            this.count = 0;
            if (this.articlepredictiondata.uniqueness_prediction != null && this.parameters && this.parameters.unique == "1")
                this.count += 1;
            if (this.articlepredictiondata.accurate_title_prediction != null && this.parameters && this.parameters.accurateTitle == "1")
                this.count += 1;
            if (this.articlepredictiondata.link_valid_prediction != null && this.parameters && this.parameters.linksValid == "1")
                this.count += 1;
            if (this.articlepredictiondata.metadata_correct_prediction != null && this.parameters && this.parameters.metadataCorrect == "1")
                this.count += 1;

            this.checkresponse();
        } else {
            this.waiting = true;
            this.articlepredictiondata = {
                "article_id_prediction": null, "uniqueness_prediction": null,
                "complete_prediction": null, "content_clear_prediction": null, "accurate_title_prediction": null, "link_valid_prediction": null, "metadata_correct_prediction": null,
                "article_id": null, "uniqueness": 0, "complete": 0, "content_clear": 0, "accurate_title": 0, "link_valid": 0, "metadata_correct": 0
            }
            this.predictedscore = 0;
            this.contenthealthdata = {
                "article_id_prediction": null, "uniqueness_prediction": null,
                "complete_prediction": null, "content_clear_prediction": null, "accurate_title_prediction": null, "link_valid_prediction": null, "metadata_correct_prediction": null,
                "article_id": null, "uniqueness": 0, "complete": 0, "content_clear": 0, "accurate_title": 0, "link_valid": 0, "metadata_correct": 0
            }
        }
    }

  totalIncludeParameters() {
    let points = 0;
    if (this.parameters) {
      Object.keys(this.parameters).forEach((key) => {
        if (this.parameters[key] == '1' || this.parameters[key] == 1)
          points += 1;
      });
    }
    this.totalevaluationpoints = points;
  }

  checkresponse() {
if(this.articlepredictiondata.article_id) {
    this.alreadyevaluated = true;
    var totalpoints = 0;
    if (
      this.articlepredictiondata.uniqueness == 1 ||
      this.articlepredictiondata.uniqueness == '1'
    ) {
      totalpoints += 1;
    }
    if (
      this.articlepredictiondata.complete == 1 ||
      this.articlepredictiondata.complete == '1'
    ) {
      totalpoints += 1;
    }
    if (
      this.articlepredictiondata.content_clear == 1 ||
      this.articlepredictiondata.content_clear == '1'
    ) {
      totalpoints += 1;
    }
    if (
      this.articlepredictiondata.accurate_title == 1 ||
      this.articlepredictiondata.accurate_title == '1'
    ) {
      totalpoints += 1;
    }
    if (
      this.articlepredictiondata.link_valid == 1 ||
      this.articlepredictiondata.link_valid == '1'
    ) {
      totalpoints += 1;
    }
    if (
      this.articlepredictiondata.metadata_correct == 1 ||
      this.articlepredictiondata.metadata_correct == '1'
    ) {
      totalpoints += 1;
    }
    if (this.totalevaluationpoints == 0) {
      this.evaluationscore = 0;
    } else {
      this.evaluationscore = parseInt(
        (totalpoints / this.totalevaluationpoints) * 100,
        10
      );
    }
    this.calculateprediction();
}
  }

  calculateprediction() {
    this.progress = this.evaluationscore;

        //for different color of progress bar
        if (this.progress == 100) {
            this.progressvalueclass = 'progressvaluegreen';
            this.progressclass = 'progressbargreen';
        }
        else if (this.progress >= 71 && this.progress < 99) {
            this.progressvalueclass = 'progressvalueblue';
            this.progressclass = 'progressbarblue';
        }
        else if (this.progress >= 41 && this.progress <= 70) {
            this.progressvalueclass = 'progressvalueyellow';
            this.progressclass = 'progressbaryellow';
        }
        else if (this.progress >= 0 && this.progress <= 40) {
            this.progressvalueclass = 'progressvaluered';
            this.progressclass = 'progressbarred';
        }
    }

    previewClose() {

        let str = "." + this.cardtitle + '_box';

        $(this.template.querySelector(str)).hide();

    }

    get getCardTitle() {
        return this.cardtitle + " article_title";
    }

    get getCardBox() {
        return this.cardtitle + '_box';
    }

    renderedCallback() {
        let str = "." + this.cardtitle + '_box';
        $(this.template.querySelector(str)).hide();
        if(this.flexipageregionwidth && this.alreadyevaluated){
        this.changeprogress(this.progress);
        }

        if(!this.flexipageregionwidth)
        {
            this.template.querySelector('.detailbox').style.setProperty('margin','10px');


        }
    }

    mouseEnter(evt) {
        // $(this.template.querySelector("a")).hover(function () {
        if (this.items?.open == true)
            return;
        this.items.open = true;
        var elems = evt;
        var curClass = this.cardtitle;

        var str = "." + curClass + '_box';
        var windowHeight = $(window).height();
        var windowWidth = $(window).width();
        // var left = evt.currentTarget.offsetLeft;
        // var top = evt.currentTarget.offsetTop;
        var left = evt.clientX;
        var top = evt.clientY;

        var offsetLeft = $(this.template.querySelector("." + curClass)).offset().left;
        // this.offsetTop=$(this.template.querySelector("."+curClass)).offset().top;
        this.offsetTop = top;
        var linkHeight = $(this.template.querySelector("." + curClass)).height();
        var linkWidth = $(this.template.querySelector("." + curClass)).width();
        var bottom = windowHeight - top - linkHeight;
        var right = windowWidth - left - linkWidth;
        var topbottom = (top < bottom) ? bottom : top;
        var leftright = (left < right) ? right : left;

        var tooltiph = $(this.template.querySelector("." + curClass + '_box')).height();
        var tooltipw = $(this.template.querySelector("." + curClass + '_box')).width();

        if (topbottom == bottom && leftright == right) //done
        {
            var yPos = top;
            var xPos = offsetLeft + linkWidth + 14;
            this.postion = 'right';
            this.offsetLeft = offsetLeft + linkWidth;
            // $(this.template.querySelector("."+curClass+'_box')).css("right", "");
            $(this.template.querySelector("." + curClass + '_box')).css("left", xPos + "px");
            $(this.template.querySelector("." + this.cardtitle + '_box')).css("right", "unset");

        } else if (topbottom == top && leftright == right) //done
        {
            var xPos = offsetLeft + linkWidth + 14;
            this.postion = 'right';
            this.offsetLeft = offsetLeft + linkWidth;
            var yPos = top - tooltiph - (linkHeight / 2);
            $(this.template.querySelector("." + curClass + '_box')).css("left", xPos + "px");
            $(this.template.querySelector("." + this.cardtitle + '_box')).css("right", "unset");
        } else if (leftright == left && (this.cardindex + 1) == this.cardlength) {
            var yPos = top - tooltiph - (linkHeight / 2);
            var xPos = offsetLeft - tooltipw - 16;
            this.postion = 'left';
            this.offsetLeft = offsetLeft;
            //$(this.template.querySelector("."+curClass+'_box')).css("right","");
            if (xPos > 0) {
                $(this.template.querySelector("." + curClass + '_box')).css("left", xPos + "px");
                $(this.template.querySelector("." + this.cardtitle + '_box')).css("right", "unset");
            } else {
                var xPos = offsetLeft + linkWidth + 14;
                this.postion = 'right';
                this.offsetLeft = offsetLeft + linkWidth;
                var yPos = top - tooltiph - (linkHeight / 2);
                // $(this.template.querySelector("."+curClass+'_box')).css("right","");
                $(this.template.querySelector("." + curClass + '_box')).css("left", xPos + "px");
                $(this.template.querySelector("." + this.cardtitle + '_box')).css("right", "unset");

            }
        } else if ((this.cardindex + 1) != this.cardlength) {
            var xPos = offsetLeft + linkWidth + 14;
            this.postion = 'right';
            this.offsetLeft = offsetLeft + linkWidth;
            var yPos = top - tooltiph - (linkHeight / 2);

            // $(this.template.querySelector("."+curClass+'_box')).css("right","");
            $(this.template.querySelector("." + curClass + '_box')).css("left", xPos + "px");
            $(this.template.querySelector("." + this.cardtitle + '_box')).css("right", "unset");

        }
        // let timer;
        // clearTimeout(timer);
        // timer = setTimeout(() => { func.apply(this, args); }, timeout);

        setTimeout(() => {
            if (this.items.open) {
                $(this.template.querySelector(str)).fadeIn('fast');
                this.template.querySelector("c-knowbler-parent-preview").setDiamand();
            }
        }, 400)

        //Dispatched and handled at "articleCards"
        this.dispatchEvent(new CustomEvent('previewopen', {
            detail: this.items
        }));
    }

    mouseOut(evt) {
        this.items.open = false;
        var str = "." + this.cardtitle + '_box';
        //  $(this.template.querySelector(str)).fadeOut('fast');
        $(this.template.querySelector(str)).hide();
    }

    openCloseDropdown(event) {
        event.stopPropagation();
        //Dispatched and handled at "articleCards"
        this.dispatchEvent(new CustomEvent('dotclick', {
            detail: this.item
        }));
    }

    hidePopup() {
        this.showFistTime = false;
        this.TourStatus[window.btoa(encodeURIComponent(Id))].status = 'Completed'
        localStorage.setItem('TourStatus', JSON.stringify(this.TourStatus));
    }

    openSubTab(event) {
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.item.Id,
                objectApiName: this.destobj,
                actionName: 'view'
            },
        });
        this.item.showDropdown = false;
    }

    get showEdit() {
        return this.currentuserlanguage?.currentUserEmailId == this.item?.Owner.Email;
    }

    openManageScreen = false;
    openManageArticle() {
        //Dispatched and handled at "articleCards"
        this.dispatchEvent(new CustomEvent('openmanagescreen', {
            detail: {
                item: this.item,
                showManage: 1
            }
        }));
    }

    openEdit() {
        //Dispatched and handled at "articleCards"
        this.dispatchEvent(new CustomEvent('openmanagescreen', {
            detail: {
                item: this.item
            }
        }));
    }
    attachreference()
    {
        this.attachToCase();
    }
    attachresolution()
    {
        this.attachToCase();
    }

     changeprogress(value)
    {
        let height = 100-(value) + '%';
        this.template.querySelector('.bar').style.height=height;
    }

    predictedscoreevent()
    {
        this.evaluatedata = true;
    }

    alreadyevaluatedevent()
    {
        //knowblerPubsub.fireEvent(this.datapageReference,'alreadyevaluated',this.articlepredictiondata);
        this.evaluatedata = true;
        this.alreadyevaluatedflag = true;

    }
    closeevaluate()
    {
        this.evaluatedata = false;
    }

    opendetails()
    {
        var senddata = {
            predictedscore:this.progress,
            articleid:this.item.Id,
            alreadyevaluted:this.alreadyevaluated,
            ownername:this.item?.Owner.Name,
            articlenumber:this.item.ArticleNumber,
            articlepredictiondata: this.articlepredictiondata,
            contenthealthdata:this.contenthealthdata,
            languagechanged:this.languagechanged,
            waiting:this.waiting,
            item: this.item
        }

        knowblerPubsub.fireEvent(this.datapageReference,'opendetails'+this.newnumber,senddata);
    }
}