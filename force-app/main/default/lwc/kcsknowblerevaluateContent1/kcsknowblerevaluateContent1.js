import { LightningElement, track, api,wire } from 'lwc';
import knowblerPubsub from 'c/knowblerPubsub';
import getsettingsuid from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getsettingsuid';
import getUserEmail from '@salesforce/apex/SU_Knowbler.KcsKnowblerClass.getUserEmail';
import { CurrentPageReference } from 'lightning/navigation';

export default class KcsknowblerevaluateContent1 extends LightningElement {
        @api listOfRec = [];
        @api evaluatedata;
        @api owneremail;
        @api predicteddatafromcard;
        @api disableflag;
        @api contenthealthdata;
        @api articlenumber;
        @track predictedscores;
        @track evaluateBox;
        @api parameters;
        @track radioselected;
        @track useremail;
        @api largescreen;
        @api newnumber;
        @api totalevaluationpoints;
        @api evaluationscore;
        @api languagechanged;

        @track unique;
        @track complete;
        @track contentClear;
        @track accurateTitle;
        @track linksValid;
        @track metadataCorrect;
        @track smallScreen;

        @track senddata={"uid":"","reviewerEmail":null,"uniqueness":null,"complete":null,"contentClear":null,"accurateTitle":null,"linkValid":null,"metadataCorrect":null,};

        @wire (CurrentPageReference) objpageref;

        @wire(getsettingsuid)
        getsettings({ error, data }) {
        if (data) {
            this.senddata['uid']=data;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
        }
       

    
   radio1(event){
        var rad1 = event.target.value;
        this.senddata["uniqueness"]= rad1 == 'Yes' ?1:0;
        if((this.senddata["uniqueness"] !=null || this.parameters.unique !="1")
            && (this.senddata["complete"] !=null || this.parameters.complete !="1" )
            && (this.senddata["contentClear"] !=null || this.parameters.contentClear !="1")
            && (this.senddata["accurateTitle"] !=null  || this.parameters.accurateTitle !="1")
            && (this.senddata["linkValid"] !=null  || this.parameters.linksValid !="1")
            && (this.senddata["metadataCorrect"] !=null || this.parameters.metadataCorrect != "1")){
        this.radioselected = false;
        this.template.querySelector('.buttonCenter').style.setProperty('background','#7E34EC');
        this.template.querySelector('.buttonCenter').style.setProperty('opacity','1');}

    }

    radio2(event){
        var rad2 = event.target.value;
        this.senddata["complete"]= rad2 == 'Yes' ?1:0;
        if((this.senddata["uniqueness"] !=null || this.parameters.unique !="1")
            && (this.senddata["complete"] !=null || this.parameters.complete !="1" )
            && (this.senddata["contentClear"] !=null || this.parameters.contentClear !="1")
            && (this.senddata["accurateTitle"] !=null  || this.parameters.accurateTitle !="1")
            && (this.senddata["linkValid"] !=null  || this.parameters.linksValid !="1")
            && (this.senddata["metadataCorrect"] !=null || this.parameters.metadataCorrect != "1"))
            {
        this.radioselected = false;
        this.template.querySelector('.buttonCenter').style.setProperty('background','#7E34EC');
        this.template.querySelector('.buttonCenter').style.setProperty('opacity','1');
    }
        
    }

    radio3(event){
        var rad3 = event.target.value;
        this.senddata["contentClear"]= rad3 == 'Yes' ?1:0;
         if((this.senddata["uniqueness"] !=null || this.parameters.unique !="1")
            && (this.senddata["complete"] !=null || this.parameters.complete !="1" )
            && (this.senddata["contentClear"] !=null || this.parameters.contentClear !="1")
            && (this.senddata["accurateTitle"] !=null  || this.parameters.accurateTitle !="1")
            && (this.senddata["linkValid"] !=null  || this.parameters.linksValid !="1")
            && (this.senddata["metadataCorrect"] !=null || this.parameters.metadataCorrect != "1")){
        this.radioselected = false;
        this.template.querySelector('.buttonCenter').style.setProperty('background','#7E34EC');
        this.template.querySelector('.buttonCenter').style.setProperty('opacity','1');
    }
    }

    radio4(event){
        var rad4 = event.target.value;
        this.senddata["accurateTitle"]= rad4 == 'Yes' ?1:0;
        if((this.senddata["uniqueness"] !=null || this.parameters.unique !="1")
            && (this.senddata["complete"] !=null || this.parameters.complete !="1" )
            && (this.senddata["contentClear"] !=null || this.parameters.contentClear !="1")
            && (this.senddata["accurateTitle"] !=null  || this.parameters.accurateTitle !="1")
            && (this.senddata["linkValid"] !=null  || this.parameters.linksValid !="1")
            && (this.senddata["metadataCorrect"] !=null || this.parameters.metadataCorrect != "1")){
        this.radioselected = false;
        this.template.querySelector('.buttonCenter').style.setProperty('background','#7E34EC');
        this.template.querySelector('.buttonCenter').style.setProperty('opacity','1');}
    }

    radio5(event){
        var rad5 = event.target.value;
        this.senddata["linkValid"]= rad5 == 'Yes' ?1:0;
       if((this.senddata["uniqueness"] !=null || this.parameters.unique !="1")
            && (this.senddata["complete"] !=null || this.parameters.complete !="1" )
            && (this.senddata["contentClear"] !=null || this.parameters.contentClear !="1")
            && (this.senddata["accurateTitle"] !=null  || this.parameters.accurateTitle !="1")
            && (this.senddata["linkValid"] !=null  || this.parameters.linksValid !="1")
            && (this.senddata["metadataCorrect"] !=null || this.parameters.metadataCorrect != "1")){
        this.radioselected = false;
        this.template.querySelector('.buttonCenter').style.setProperty('background','#7E34EC');
        this.template.querySelector('.buttonCenter').style.setProperty('opacity','1');}
    }

    radio6(event){
        var rad6 = event.target.value;
        this.senddata["metadataCorrect"]= rad6 == 'Yes' ?1:0;
        if((this.senddata["uniqueness"] !=null || this.parameters.unique !="1")
            && (this.senddata["complete"] !=null || this.parameters.complete !="1" )
            && (this.senddata["contentClear"] !=null || this.parameters.contentClear !="1")
            && (this.senddata["accurateTitle"] !=null  || this.parameters.accurateTitle !="1")
            && (this.senddata["linkValid"] !=null  || this.parameters.linksValid !="1")
            && (this.senddata["metadataCorrect"] !=null || this.parameters.metadataCorrect != "1")){
        this.radioselected = false;
        this.template.querySelector('.buttonCenter').style.setProperty('background','#7E34EC');
        this.template.querySelector('.buttonCenter').style.setProperty('opacity','1');}
    }

    handleClick(){
    
        knowblerPubsub.fireEvent(this.objpageref,'agentevaluteddata'+this.newnumber,this.senddata);
    }


    connectedCallback()
    {
       

        this.radioselected = true;
        this.senddata['reviewerEmail']=this.owneremail;
        
       if(this.predicteddatafromcard){
        if((this.predicteddatafromcard.article_id_prediction == 0 || this.predicteddatafromcard.article_id_prediction == "null")&& !this.disableflag){
            this.evaluateBox = true;
        }
                this.calculatedata(this.predicteddatafromcard);
                this.makesenddata(this.predicteddatafromcard);

                this.visibleparameter(this.contenthealthdata);
        }


   
    }

   renderedCallback()
    {   
        
        
        if(this.languagechanged == true)
        {
            if(this.template.querySelector('.commonDiv2'))
            {
                let divdata = this.template.querySelectorAll(".commonDiv2");
                for (var i = 0; i<divdata.length; i++)
                {
                    divdata[i].style.setProperty('width','90%');
                }
            }
        }
    
          this.template.querySelector('.notsmallscreen').style.display="none";
          this.template.querySelector('.smallscreen').style.display="block";
          var screenWidth = this.template.querySelector(".mainbox").offsetWidth;
          if(!this.evaluateBox)
          {
              if(screenWidth>500)
              {
                  this.template.querySelector('.notsmallscreen').style.display="block";
                  this.template.querySelector('.smallscreen').style.display="none";
              }
              else
              {
                  this.template.querySelector('.notsmallscreen').style.display="none";
                  this.template.querySelector('.smallscreen').style.display="block";
              }
          }
          if(screenWidth>700)
          {
              this.template.querySelector('.my-icon').style.setProperty('margin-top', '0px');
              if(this.template.querySelector(".prediction"))
              this.template.querySelector(".prediction").style.setProperty('padding-left', '30px');
          }
        if(!this.disableflag){
        
            var screenWidth = this.template.querySelector(".mainbox").offsetWidth;
            if(screenWidth>500){
                
                let data = this.template.querySelectorAll(".commonDiv1");
                for (var i = 0; i<data.length; i++)
                {
                    data[i].style.setProperty('margin-bottom', '7px');
                }

                 
            this.template.querySelector(".contentHealthSection").style.setProperty('padding-left','1rem');
            this.template.querySelector('.contentHealthSection').style.setProperty('padding-right','1rem');
            }


            if(screenWidth>500 && screenWidth<700){this.template.querySelector(".buttonCenter").style.setProperty('width', '15%');}
            if(screenWidth>700)
            {
                 this.template.querySelector(".buttonCenter").style.setProperty('margin-top', '30px');
                 this.template.querySelector(".buttonCenter").style.setProperty('width', '10%');
            }
        }

        if(this.disableflag)
        {
            let radiodatayes = this.template.querySelectorAll(".radioyes");
                for (var i = 0; i<radiodatayes.length; i++)
                {
                    radiodatayes[i].classList.add('evaluated');
                    radiodatayes[i].style.setProperty('pointer-events','none');
                }

                let radiodatano = this.template.querySelectorAll(".radiono");
                for (var i = 0; i<radiodatano.length; i++)
                {
                    radiodatano[i].classList.add('evaluated');
                    radiodatano[i].style.setProperty('pointer-events','none');
                }
        }
        var screenWidth = this.template.querySelector(".mainbox").offsetWidth;
        if(screenWidth>500){
            
            if(this.template.querySelector(".newDiv")){
                let bardata = this.template.querySelectorAll(".progressBarClass");
                for (var i = 0; i<bardata.length; i++)
                {
                    bardata[i].style.setProperty('width', '33%');
                }
                let radiodata = this.template.querySelectorAll(".radioalignment");
                for (var i = 0; i<radiodata.length; i++)
                {
                    radiodata[i].style.setProperty('padding-right', '2px');
                }
            }
            
            else if((screenWidth>340 && screenWidth<700)){
                let newradio = this.template.querySelector(".yes");
                newradio.style.setProperty('padding-left','8px');
            
            }else{
                let newradio = this.template.querySelector(".yes");
                newradio.style.setProperty('padding-left','20px');
            }  
        }
        if(screenWidth>1000){
            let bardata = this.template.querySelectorAll(".progressBarClass");
            for (var i = 0; i<bardata.length; i++)
            {
                bardata[i].style.setProperty('width', '20%');
            }
        }

        if(screenWidth>500 && screenWidth<700)
        {
           
            if(this.template.querySelector(".prediction")){
                this.template.querySelector('.prediction').style.setProperty('padding-left','47px');
                this.template.querySelector('.prediction').style.setProperty('margin-right','28px');
            }
          
        }
         if(this.template.querySelectorAll('.progressBarClass'))
        {
          var screenWidth = this.template.querySelector(".mainbox").offsetWidth;
        //   if(screenWidth>700){
        //        this.template.querySelector(".newDiv").style.setProperty('padding-left', '140px');
               
        //   }
          
          if(screenWidth<500){
                if(this.template.querySelector(".newDiv"))
                this.template.querySelector(".newDiv").style.setProperty('padding-left', '8px');


        }
        }

        if(screenWidth<500){
            this.smallScreen = true;
            
        }
            
    }
    

    visibleparameter(data)
    {
        if(data.article_id !=null && data.article_id !="null")
        {   
            this.unique = (data.uniqueness !=null) ?true:false;
            this.complete = (data.complete !=null) ?true:false;
            this.contentClear = (data.content_clear !=null) ?true:false;
            this.accurateTitle = (data.accurate_title !=null) ?true:false;
            this.linksValid = (data.link_valid !=null) ?true:false;
            this.metadataCorrect = (data.metadata_correct !=null) ?true:false;
        }
        else
        {
            this.unique = (this.parameters.unique == 1 || this.parameters.unique == "1" ) ?true:false;
            this.complete = (this.parameters.complete == 1 || this.parameters.complete == "1" ) ?true:false;
            this.contentClear = (this.parameters.contentClear == 1 || this.parameters.contentClear == "1" ) ?true:false;
            this.accurateTitle = (this.parameters.accurateTitle == 1 || this.parameters.accurateTitle == "1" ) ?true:false;
            this.linksValid = (this.parameters.linksValid == 1 || this.parameters.linksValid == "1" ) ?true:false;
            this.metadataCorrect = (this.parameters.metadataCorrect == 1 || this.parameters.metadataCorrect == "1" ) ?true:false;
        }
    }



    makesenddata(data)
    {
        this.predictedscores = {
        "predictedArticleId":data.article_id_prediction == null ?null:data.article_id_prediction,
        "predictedUniqueness":data.uniqueness_prediction ==null?null:data.uniqueness_prediction ,
        "predictedComplete":data.complete_prediction ==null?null:data.complete_prediction,
        "predictedContentClear":data.content_clear_prediction ==null?null:data.content_clear_prediction,
        "predictedAccurateTitle":data.accurate_title_prediction ==null?null:data.accurate_title_prediction,
        "predictedLinkValid":data.link_valid_prediction ==null?null:data.link_valid_prediction,
        "predictedMetaDataCorrect":data.metadata_correct_prediction ==null?null:data.metadata_correct_prediction
    };
            


        this.senddata["predictedScoreObj"] = this.predictedscores;
        this.senddata["articleId"] = this.articlenumber;
        this.senddata["evaluatedArticleId"] = this.articlenumber;
    }
    
     @track uniqueno=false;
     @track uniqueyes = false;
     @track completeno=false;
     @track completeyes = false;
     @track contentno=false;
     @track contentyes = false;
     @track accurateno=false;
     @track accurateyes = false;
     @track linkno=false;
     @track linkyes = false;
     @track metano=false;
     @track metayes = false;

     @track uniqueprediction;
     @track completeprediction;
     @track contentprediction;
     @track accurateprediction;
     @track linksprediction;
     @track metaprediction;

     predictionExist;


    calculatedata(data)
    {   
        if (data.article_id_prediction == null) {
            this.predictionExist = false;
        } else {
            this.predictionExist = true;
            this.uniqueprediction = data.uniqueness_prediction == null ? false:true;
            this.completeprediction = data.complete_prediction == null ? false:true;
            this.contentprediction = data.content_clear_prediction == null ? false:true;
            this.accurateprediction = data.accurate_title_prediction == null ? false:true;
            this.linksprediction = data.link_valid_prediction == null ? false:true;
            this.metaprediction = data.metadata_correct_prediction == null ? false:true;
        }
        
        // for prediction

        // For radio button popluation
        if(this.disableflag){
            
        if(data.uniqueness == 0){
            this.uniqueyes=false;
            this.uniqueno=true;
        }
        else{
            this.uniqueno=false;
            this.uniqueyes=true;
        }
        if(data.complete == 0){
            this.completeyes=false;
            this.completeno=true;
        }
        else{
            this.completeno=false;
            this.completeyes=true;
        }
        if(data.content_clear == 0){
            this.contentyes=false;
            this.contentno=true;
        }
        else{
            this.contentno=false;
            this.contentyes=true;
        }
        if(data.accurate_title == 0){
            this.accurateyes=false;
            this.accurateno=true;
        }
        else{
            this.accurateno=false;
            this.accurateyes=true;
        }
        if(data.link_valid == 0){
            this.linkyes=false;
            this.linkno=true;
        }
        else{
            this.linkno=false;
            this.linkyes=true;
        }
        if(data.metadata_correct == 0){
            this.metayes=false;
            this.metano=true;
        }
        else{
            this.metano=false;
            this.metayes=true;
        }
    }
    }
    closeevaluate()
    {
        this.dispatchEvent(new CustomEvent('closeevaluate'));
    }

    
}