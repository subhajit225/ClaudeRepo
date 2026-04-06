public class ContentController{
    public Opportunity Opp;
    public FileNameMapper FM1 { get; set;}
    public FileNameMapper FM2 { get; set;}
   
    public ContentController(ApexPages.StandardController controller) {
        this.Opp = (Opportunity)controller.getRecord();
        FM1 = new FileNameMapper();
        FM2 = new FileNameMapper();
       
    }
    
    public PageReference upload() {
    
     if(FM1.file == null && FM1.fileName != null){
          if(FM2.fileName != null){
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please upload '+FM2.fileName +' & '+FM1.fileName+' to proceed further or if you want to continue with single file upload please remove surplus file option from the dropdown'));
          }else{
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please upload '+ FM1.fileName +' to proceed further'));
          }
            return ApexPages.currentPage();
      }  
      
      if(FM2.file == null && FM2.fileName != null){
          if(FM1.fileName != null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please upload '+FM2.fileName +' & '+FM1.fileName+' to proceed further or if you want to continue with single file upload please remove surplus file option from the dropdown'));
          }else{
              ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please upload '+ FM2.fileName +' to proceed further'));
          }
            return ApexPages.currentPage();
        }        
  
       system.debug('FM1.file'+FM1.file);
       system.debug('FM1.file'+FM1.contentType);
       system.debug('FM2.file'+FM2.file);
       list<Attachment> CVS = new list<Attachment>();
       if(FM1.fileName != null || FM1.file != null){
            CVS.add(new Attachment(ParentId = Opp.id,
            Name  = 'Attachment - '+FM1.fileName+FM1.ContentfileName,
            Body = FM1.file));     
       }
       if(FM2.fileName != null || FM2.file != null){     
            CVS.add(new Attachment(ParentId = Opp.id,
            Name  = 'Attachment - '+FM2.fileName+FM2.ContentfileName,
            ContentType = FM2.contentType,
            Body = FM2.file));
       }   
       system.debug('Debug CVS ='+CVS);
       PageReference pg;
       Boolean customSettingUpdated = false;
       ShGl_DisableBusinessLogic__c objcustomSetting = ShGl_DisableBusinessLogic__c.getInstance(UserInfo.getProfileId());
       
       try{
           system.debug('objcustomSetting---'+objcustomSetting);
           if(objcustomSetting.Disable_Opportunity_Validation_Rules__c == false){
               objcustomSetting.Disable_Opportunity_Validation_Rules__c = true;
               system.debug('objcustomSetting.Name--'+objcustomSetting.Name);
               objcustomSetting.Id = objcustomSetting.Name;
               customSettingUpdated = true;
               update objcustomSetting; 
               
           }
           system.debug('CVS ='+CVS);
           insert CVS;
           system.debug('CVS ='+CVS); 
           for(integer Count=0;CVS.size()>Count;Count++){      
              if(CVS[Count].Name.contains('Attachment - Sizing Presentation')){
                   Opp.Attachment_Sizing_Presentation__c = CVS[Count].id;
               }
               if(CVS[Count].Name.contains('Attachment - Sizing Response')){
                   Opp.Attachment_Sizing_Response__c = CVS[Count].id;
               }
               pg = new PageReference('/'+Opp.id);
           }
           update Opp; 
           if(customSettingUpdated){
               objcustomSetting.Disable_Opportunity_Validation_Rules__c = false;
               update objcustomSetting;
           }    
        }catch(Exception e){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));   
           pg = ApexPages.currentPage(); 
        }
        try{
            if(customSettingUpdated){
               objcustomSetting.Disable_Opportunity_Validation_Rules__c = false;
               update objcustomSetting;
           }
        }catch(Exception e){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,e.getMessage()));   
           pg = ApexPages.currentPage();
        }
        return pg;
    }
    
    public pageReference back(){
      return new PageReference('/'+Opp.id);
    }
    
    public class FileNameMapper{
        public string fileName{ get; set;}
        public string ContentfileName{ get; set;}
        public blob file{ get; set;}   
        public string contentType{ get; set;}
    }
}//End of class