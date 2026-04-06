/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 09-17-2025
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public with sharing class PocFormControllerCls {
  public PocFormControllerCls() {

  }



  public class response_Wrapper{
      @AuraEnabled
      public Opportunity opportunityObj {get;set;}
      @AuraEnabled
      public POC__c pocRequestObj{get;set;}
      @AuraEnabled
      public RscInstance__c selectedRscInstance{get;set;}
      @AuraEnabled
      public Boolean isValidation {get;set;}
      @AuraEnabled
      public map<String,String> returnMessage {get;set;}
      @AuraEnabled
      public Boolean isSuccess {get;set;}
      @AuraEnabled
      public String errorMessage {get;set;}
      @AuraEnabled
      public Boolean PartnerDistributorSignedPOCAddendum {get;set;}
      @AuraEnabled
      public Boolean setOnlineAgreementSigned {get;set;}
      @AuraEnabled
      public Boolean setAgreementWaivedOff {get;set;}
      @AuraEnabled
      public String returnObjectName {get;set;}
      @AuraEnabled
      public Boolean isPOCApproverPresent {get;set;}
      
      @AuraEnabled
      public Boolean isconditionalpocallowed {get;set;}
      @AuraEnabled
      public String uclEdition {get;set;}

      @AuraEnabled
      public String RCVType {get;set;}

      @AuraEnabled
      public Integer numberOfRCVTB {get;set;}

      @AuraEnabled
      public String storageRegion {get;set;}

      @AuraEnabled
      public Integer selected_UCL_RCVBackup {get;set;}

      @AuraEnabled
      public String selectedUCLRCVBackupZone {get;set;}

      /* OrderItem List*/
      @AuraEnabled 
	    public List<OrderItem> orderRecords{get;set;} 
      /* POC List*/
      @AuraEnabled 
	    public List<POC__c> pocRecords{get;set;}
      /* Asset List*/
      @AuraEnabled 
	    public List<Asset> assetRecords{get;set;}
      
     

      public response_Wrapper(){
          this.opportunityObj = new Opportunity();
          this.pocRequestObj = new POC__c();
          this.selectedRscInstance = new RscInstance__c();
          this.isValidation= false;
          this.returnMessage = new map<String,String>();
          this.isSuccess=false;
          this.errorMessage='';
          this.PartnerDistributorSignedPOCAddendum=false;
          this.setOnlineAgreementSigned=false;
          this.setAgreementWaivedOff=false;
          this.returnObjectName='';
          this.isPOCApproverPresent=false;
          this.isconditionalpocallowed=false;
          this.uclEdition='';
          this.orderRecords = new List<OrderItem>();
          this.assetRecords =  new List<Asset>();
          this.pocRecords = new List<POC__c>();
      }




  }
  /**
 * @description Inner class representing a file with its associated metadata.
 * This class contains properties for the record ID, the file content encoded in Base64,
 * and the filename. It is designed for data transfer, especially in Aura/LWC contexts.
 */
  public class FileInnerClass{
    /**
     * @description The Salesforce record ID associated with the file.
     */
      @AuraEnabled
      public String recordId {get;set;}
      /**
     * @description The content of the file encoded as a Base64 string.
     */
      @AuraEnabled
      public String base64 {get;set;}
      /**
     * @description The name of the file including extension.
     */
      @AuraEnabled
      public  String filename {get;set;}
      
    /**
     * @description Default constructor initializing properties to empty strings.
     */
      public FileInnerClass(){
          this.recordId = '';
          this.base64 = '';
          this.filename= '';
      }
  }
  /**
 * @description Retrieves the default values for a given record to populate the form.
 * This method fetches and returns default data related to the specified record ID,
 * encapsulated within a response_Wrapper object that includes the relevant information
 * and status details.
 *
 * @param recordId The ID of the record for which default form values are to be retrieved.
 * @return response_Wrapper An object containing the default values and associated response details.
 */
  @AuraEnabled(cacheable=true)
  public static response_Wrapper retrunDefaultValuetoFrom (String recordId){

      response_Wrapper pocFrom = new response_Wrapper();
      POC__c pocInstance = new POC__c();
      Opportunity opportuntiyObj = new Opportunity();
      RscInstance__c rscInstance = new RscInstance__c();
      map<String,String> validateCheckMap = new map<String,String>();
      boolean isPOCApproverPresent=false;
      Boolean isconditionalpocallowed=false;
      String returnObjectName ='';
      if(recordId !='') {
      returnObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
      if('Opportunity'==returnObjectName ) {

        opportuntiyObj =getOpportuntiyDetails(recordId);
        validateCheckMap = validateCheck(opportuntiyObj.Id);
        isPOCApproverPresent= checkCurrentUserApprover();
        isconditionalpocallowed= checkConditionalPOCUser();

      } else {
        pocInstance = getPOCRequestDetails(recordId);
        if(pocInstance !=null){
          if(pocInstance.Opportunity__c!=null){
            opportuntiyObj =getOpportuntiyDetails(pocInstance.Opportunity__c);
          }
          
          validateCheckMap = validateCheck(opportuntiyObj.Id);

        }



      }
      
      //if(validateCheckMap.size()>0 && validateCheckMap.get('Status') =='Success') {
     //if(opportuntiyObj.Distributor_Lookup__c ==null){
      //opportuntiyObj.Distributor_Lookup__c='';
     //}

     if(opportuntiyObj !=null) {
              pocFrom.opportunityObj=opportuntiyObj;
            // pocInstance.Opportunity__c=opportuntiyObj.Id;
                if(opportuntiyObj.Partner_Lookup__r.Agreed_To_POC_terms__c == true
                        && ('Signed - Active' == opportuntiyObj.Partner_Lookup__r.Partner_Agreement_Status__c
                        || 'Signed - Active' == opportuntiyObj.Distributor_Lookup__r.Partner_Agreement_Status__c)) {
                          pocFrom.PartnerDistributorSignedPOCAddendum=true;
                        
                } 
                  if('Signed - Active' == opportuntiyObj.Partner_Lookup__r.Partner_Agreement_Status__c) {
                  pocInstance.Disty_with_Signed_POC_Addendum__c = opportuntiyObj.Partner_Lookup__c;
                }
              if('Signed - Active' == opportuntiyObj.Distributor_Lookup__r.Partner_Agreement_Status__c) {
                pocInstance.Disty_with_Signed_POC_Addendum__c = opportuntiyObj.Distributor_Lookup__c;
              }
              pocFrom.setOnlineAgreementSigned =setOnlineAgreementSigned(opportuntiyObj);
              pocInstance.Online_Agreement_Signed__c=setOnlineAgreementSigned(opportuntiyObj);
              pocInstance.Shipping_Company_Name__c=opportuntiyObj.AccountId;
              pocInstance.POC_Agreement_Waived_Customer__c = opportuntiyObj.Account.Type == 'Customer' ? true : false;
              pocFrom.setAgreementWaivedOff = pocInstance.POC_Agreement_Waived_Customer__c;
      }
      pocFrom.pocRequestObj=pocInstance;
      pocFrom.returnObjectName=returnObjectName;
      pocFrom.isPOCApproverPresent=isPOCApproverPresent;
      pocFrom.isconditionalpocallowed=isconditionalpocallowed;
      if(validateCheckMap.size()>0 && validateCheckMap.get('Status') =='Error') {
      pocFrom.isValidation=true;
      pocFrom.errorMessage=validateCheckMap.get('Message');
      }
    }
      return pocFrom;
  }

  /**
   * @description Submits a Proof of Concept (POC) request based on the provided request object.
   * This method validates various conditions related to the POC request, including data redundancy,
   * product categories, and storage region selections .
   *
   * The method also ensures that the provided tier sizes fall within the valid range and that
   * the appropriate fields are populated based on the request type (RCV Backup or RCV Archive).
   *
   * @param requestArrayObj The wrapper object containing the POC request details, including the associated Opportunity.
   * @param fileListInsert A list of files to be associated with the POC request.
   * @param editmode A string indicating the current mode of operation (e.g., edit or new submission).
   *
   * @return response_Wrapper An object containing the POC request response, including validation errors, if any.
  */
  @AuraEnabled
  public static response_Wrapper submitPOCRequest (response_Wrapper requestArrayObj,List<FileInnerClass> fileListInsert,String editmode ){
      response_Wrapper response = new response_Wrapper();
      if(requestArrayObj !=null){
      try {
          POC__c pocRequestRS = new POC__c();
          Opportunity oppObj = new Opportunity();
          List<FileInnerClass> fileList = new List<FileInnerClass>();
          
          pocRequestRS= requestArrayObj.pocRequestObj;
          response.pocRequestObj = pocRequestRS;
          pocRequestRS.Opportunity__c=requestArrayObj.opportunityObj.Id;
          oppObj = requestArrayObj.opportunityObj;
           RscInstance__c selectedRscInstance = requestArrayObj.selectedRscInstance;
         
          //Start - Added for MKT26-490
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Codebase Recovery')){
            if(pocRequestRS.Number_of_repositories_to_back_up_1_500__c == null || pocRequestRS.Number_of_repositories_to_back_up_1_500__c > 500 || pocRequestRS.Number_of_repositories_to_back_up_1_500__c < 1 ){
              response.isSuccess = false;
              response.errorMessage = 'Codebase Recovery range must be 1 - 500';
              return response;
            }    
          }
          //End - Added for MKT26-490
           
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('NAS Cloud Direct')){
            if(pocRequestRS.NCD_Editions__c == 'Bundled with Cloud Unstructured' && !pocRequestRS.Product_Categories__c.contains('Cloud Unstructured (S3, Azure Blob, and Cloud Files)')){
              response.isSuccess = false;
              response.errorMessage = 'The \'Bundled with Cloud Unstructured\' edition can only be selected when \'Cloud Unstructured\' is part of the request. Please add \'Cloud Unstructured\' to your POC or select a different NCD Edition.';
              return response;
            }
            if((pocRequestRS.NCD_Editions__c == 'Business Edition Rubrik Hosted (w/RCV + Ransomware Monitoring)' || pocRequestRS.NCD_Editions__c == 'Enterprise Edition (w/RCV + Ransomware Monitoring + Sensitive Data Discovery)') && (!pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault'))){
              response.isSuccess = false;
              response.errorMessage = 'Please Select Rubik Cloud Vault';
              return response;
            } else if(pocRequestRS.NCD_Editions__c == null || pocRequestRS.NCD_Editions__c == ''){
              response.isSuccess = false;
              response.errorMessage = 'Please Select NCD Editions';
              return response;
            }
            if(pocRequestRS.Number_Of_NCD_FETB__c < 1 ||  pocRequestRS.Number_Of_NCD_FETB__c >10){
              response.isSuccess = false;
              response.errorMessage = 'NCD TB range must be 1 - 10';
              return response;
            }
            }
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('UCL (Cloud Cluster, Cloud Native & Entra ID)')){
            pocRequestRS.UCL_Edition__c = requestArrayObj.uclEdition;
            }
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('UCL (Cloud Cluster, Cloud Native & Entra ID)')){
            pocRequestRS.UCL_Edition__c = requestArrayObj.uclEdition;
          }
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('NAS Cloud Direct') && pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault') && (((pocRequestRS.Archive_TB__c) > 10) || (pocRequestRS.Archive_TB__c > 10))){
              response.isSuccess = false;
              response.errorMessage = 'Archive Tier TB range must be 1 - 10';
              return response;
            }
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('NAS Cloud Direct') && pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault') && ((( pocRequestRS.Backup_TB__c) > 10 ) || ( pocRequestRS.Backup_TB__c) > 10)){
            response.isSuccess = false;
            response.errorMessage = 'Backup Tier TB range must be 1 - 10';
            return response;
          }
          if(pocRequestRS.POC_Type__c == 'Standard POC : RSC-G' && oppObj.Rubrik_Security_Cloud_Gov_t_Owner__c != pocRequestRS.RSC_G_Contact__c){
            response.isSuccess = false;
            response.errorMessage = 'RSC G Contact should be same as Opportunity\'s Rubrik Security Cloud Govt Owner. ';
            return response;
          }
          if(pocRequestRS.POC_Type__c == 'Standard POC : RSC-G' && pocRequestRS.Product_Categories__c.contains('SaaS (Salesforce)') && pocRequestRS.Salesforce_plus_DevOps_Add_on__c == 'No'){
            response.isSuccess = false;
            response.errorMessage = 'Please remove SaaS (Salesforce) from the POC.';
            return response;
          }
          if(pocRequestRS.POC_Type__c == 'Standard POC : RSC-G' && pocRequestRS.Product_Categories__c.contains('SaaS (Salesforce)') && pocRequestRS.Salesforce_plus_DevOps_Add_on__c == 'Yes' && (pocRequestRS.Number_of_Users_Saas__c == null || pocRequestRS.Number_of_Users_Saas__c < 200)){
            response.isSuccess = false;
            response.errorMessage = 'Salesforce requires a minimum of 200 user licenses to quote.';
            return response;
          }
          
          if(pocRequestRS.Product_Categories__c!= null && pocRequestRS.Product_Categories__c.contains('Identity Cyber Recovery for Okta') && pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == 'Yes' && (pocRequestRS.How_many_users_are_there_in_the_Okta_IdP__c == null || pocRequestRS.How_many_users_are_there_in_the_Okta_IdP__c <= 0)){
            response.isSuccess = false;
            response.errorMessage = 'Number of Users must be greater then 0';
            return response;
          }

          //added below if condition for - MKT26-1427 
          if(pocRequestRS.Product_Categories__c!= null && pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == 'No' && pocRequestRS.How_many_users_are_there_in_the_Okta_IdP__c != null ){
            pocRequestRS.How_many_users_are_there_in_the_Okta_IdP__c = null;
          }
        
          if(pocRequestRS.POC_Type__c == 'Standard POC : RSC-G' && !oppObj.Account.RSC_G_Eligible__c){
            response.isSuccess = false;
            response.errorMessage = 'This account does not currently have RSC-G eligibility, and as a result, the creation of a POC is not possible. To enable RSC-G on this account, please submit a request to RSCGeligibility@rubrik.com.';
            return response;
          }else if(pocRequestRS.POC_Type__c == 'Standard POC : RSC-G' && oppObj.Account.RSC_G_Eligible__c && oppObj.Rubrik_Security_Cloud_Gov_t_Owner__c == null){
            response.isSuccess = false;
            response.errorMessage = 'To create the RSC-G , Opportunity Rubrik Service Cloud owner should be populated';
            return response;
          }
          
          if( pocRequestRS.Number_of_Users__c != null && ( pocRequestRS.Number_of_Users__c < 1 || pocRequestRS.Number_of_Users__c > 500 ) ) {
            response.isSuccess = false;
            response.errorMessage = 'Number of Users must be between 1 - 500';
            return response;
          }
          if( pocRequestRS.Number_of_Users_RSCG__c != null && ( pocRequestRS.Number_of_Users_RSCG__c < 1 || pocRequestRS.Number_of_Users_RSCG__c > 500 ) ) {
            response.isSuccess = false;
            response.errorMessage = 'Number of Users must be between 1 - 500';
            return response;
          }
    
          if(pocRequestRS.POC_Type__c == 'Web Try and Buy'  && pocRequestRS.M365_Hosting_environment__c == 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience' ){
              response.isSuccess = false;
              response.errorMessage = 'Selected option is unavailable for Web Try and Buy POC Type';
              return response;
            }
          if(pocRequestRS.POC_Type__c != 'Web Try and Buy'  && pocRequestRS.M365_Hosting_environment__c == 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience' && pocRequestRS.Product_Categories__c != null  && ( !pocRequestRS.Product_Categories__c.contains('Data Security Posture Management') || !pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') || ( pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') &&(pocRequestRS.Add_Identity_Resilience__c == 'No' || pocRequestRS.Add_Identity_Resilience__c == null) ))){
              if(pocRequestRS.Product_Categories__c.contains('M365 and Google Workspace')){
                  if((pocRequestRS.M365_Option__c == null || pocRequestRS.M365_Option__c == '' || pocRequestRS.M365_Option__c == 'No') && (pocRequestRS.Google_Workspace__c == null || pocRequestRS.Google_Workspace__c == '' || pocRequestRS.Google_Workspace__c == 'No')){
                      response.isSuccess = false;
                      response.errorMessage = 'M365 Option or Google Workspace must be selected.';
                      return response;
                  }
                  if(pocRequestRS.M365_Option__c == 'Yes' && pocRequestRS.M365_Hosting_environment__c == 'Rubrik Hosted EE, DSPM, Identity Recovery & Resilience'){
            response.isSuccess = false;
            response.errorMessage = 'Please select DSPM and Identity Resilience from the product category.';
            return response;
          }
              }
          }
          
          if( pocRequestRS.Product_Categories__c!= null && (pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault - Government') ||  pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault'))) {
              if(pocRequestRS.Product_Categories__c != null &&  pocRequestRS.Product_Categories__c.trim() == 'Rubrik Cloud Vault' ){
                if(pocRequestRS.Data_Redundancy_Archive__c != 'Single Zone (LRS)'){
                  pocRequestRS.Storage_Region_Bundle_RCV_Archive__c = '';
                }
                if(pocRequestRS.Data_Redundancy_Backup__c  != 'Single Zone (LRS)'){
                    pocRequestRS.Storage_Region_Bundle_RCV_Backup__c = '';
                }
              }
              if(pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault - Government') && pocRequestRS.RCV_Archive_Tier__c == 'No'){
                pocRequestRS.Storage_Region_Bundle_RCV_Archive__c ='';
                  pocRequestRS.Data_Redundancy_Archive__c='';
              }
              if(pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault - Government') && pocRequestRS.RCV_Backup_Tier__c == 'No'){
                pocRequestRS.Storage_Region_Bundle_RCV_Backup__c ='';
                  pocRequestRS.Data_Redundancy_Backup__c='';
              }

              if( pocRequestRS.RCV_Archive_Tier__c == 'No' && pocRequestRS.RCV_Backup_Tier__c == 'No' ) {
                  response.isSuccess = false;
                  response.errorMessage = 'Backup Or Archive must be selected';
                  return response;
              }
              
              if( pocRequestRS.RCV_Archive_Tier__c == 'Yes' && (pocRequestRS.Archive_TB__c == null || pocRequestRS.Archive_TB__c < 1 || pocRequestRS.Archive_TB__c > 10) ) {
                  response.isSuccess = false;
                  response.errorMessage = 'Archive Tier TB range must be 1 - 10';
                  return response;
              }
              if( pocRequestRS.RCV_Backup_Tier__c == 'Yes' && (pocRequestRS.Backup_TB__c == null || pocRequestRS.Backup_TB__c < 1 || pocRequestRS.Backup_TB__c > 10)) {
                  response.isSuccess = false;
                  response.errorMessage = 'Backup Tier TB range must be 1 - 10';
                  return response;
              }
              if( pocRequestRS.RCV_Backup_Tier__c == 'Yes' && (pocRequestRS.Backup_TB__c == null || pocRequestRS.Backup_TB__c < 1 || pocRequestRS.Backup_TB__c > 10) && (!pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault - Government') )) {
                  response.isSuccess = false;
                  response.errorMessage = 'Backup Tier Capacity should be set to 0';
                  return response;
              }
              if( pocRequestRS.RCV_Backup_Tier__c ==  'No' && (pocRequestRS.Backup_TB__c != null && pocRequestRS.Backup_TB__c > 0 )) {
                  response.isSuccess =  false;
                  response.errorMessage =  'Backup Tier Capacity should be set to 0';
                  return response ;
              }
              
              if( pocRequestRS.RCV_Archive_Tier__c == 'No' && (pocRequestRS.Archive_TB__c != null && pocRequestRS.Archive_TB__c > 0)) {
                  response.isSuccess = false;
                  response.errorMessage = 'Archive Tier Capacity should be set to 0';
                  return response;
              }
              if((pocRequestRS.RCV_Archive_Tier__c == 'Yes' && ( (pocRequestRS.Data_Redundancy_Archive__c == null || pocRequestRS.Data_Redundancy_Archive__c == '') && pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault - Government') ) && requestArrayObj.RCVType != 'RCV Archive')){ 
                response.isSuccess = false;
                response.errorMessage = 'Please select Data Redundancy Archive';
                return response;
              } else if(pocRequestRS.RCV_Backup_Tier__c == 'Yes' && ( (pocRequestRS.Data_Redundancy_Backup__c == null || pocRequestRS.Data_Redundancy_Backup__c == '') && pocRequestRS.Product_Categories__c.contains('Rubrik Cloud Vault - Government') )  && requestArrayObj.RCVType != 'RCV Backup'){ 
                response.isSuccess = false;
                response.errorMessage = 'Please select Data Redundancy Backup';
                return response;
              }
              
		          if(pocRequestRS.RCV_Archive_Tier__c == 'No' && pocRequestRS.Data_Redundancy_Archive__c != null){
                pocRequestRS.Data_Redundancy_Archive__c = '';
              }
              if(pocRequestRS.RCV_Backup_Tier__c == 'No' && pocRequestRS.Data_Redundancy_Backup__c != null){
                pocRequestRS.Data_Redundancy_Backup__c = '';
              }
            }
            if (requestArrayObj.uclEdition != null && pocRequestRS.Product_Categories__c != null  && pocRequestRS.Product_Categories__c.contains('UCL (Cloud Cluster, Cloud Native & Entra ID)') ){
            pocRequestRS.UCL_Edition__c = requestArrayObj.uclEdition;
            
          }

          /*Added as part of MKT25-673 */
          if(pocRequestRS.Product_Categories__c != null  && pocRequestRS.Product_Categories__c.contains('Data Security Posture Management') && !pocRequestRS.Product_Categories__c.contains(';') ){
            pocRequestRS.Has_only_DSPM_SKU__c = true;
          }

          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c == 'SaaS (Jira Cloud, Salesforce, Dynamics)' && pocRequestRS.Salesforce__c != 'Yes' && pocRequestRS.Jira_Cloud__c != 'Yes' && pocRequestRS.Dynamics__c != 'Yes'){
            response.isSuccess = false;
            response.errorMessage = 'Jira Cloud or Salesforce or Dynamics must be selected';
            return response;
          }

          if( pocRequestRS.Salesforce__c == 'Yes' && ( pocRequestRS.Number_of_Users_Salesforce__c == null || pocRequestRS.Number_of_Users_Salesforce__c < 200  )) {
            response.isSuccess = false;
            response.errorMessage = 'Salesforce requires a minimum of 200 user licenses to quote';
            return response;
          }

          if( pocRequestRS.Jira_Cloud__c == 'Yes' &&  (pocRequestRS.Number_of_Users_Atlassian__c == null || pocRequestRS.Number_of_Users_Atlassian__c < 200  )) {
            response.isSuccess = false;
            response.errorMessage = 'Jira Cloud requires a minimum of 200 user licenses to quote';
            return response;
          }
          
          if( pocRequestRS.Dynamics__c == 'Yes' &&  (pocRequestRS.Number_of_Users_Dynamics__c == null || pocRequestRS.Number_of_Users_Dynamics__c < 200  )) {
            response.isSuccess = false;
            response.errorMessage = 'Dynamics requires a minimum of 200 user licenses to quote.';
            return response;
          } 

          // if(( pocRequestRS.Salesforce__c == 'Yes' && ( pocRequestRS.Hosting_Environment_Salesforce__c == null || pocRequestRS.Hosting_Environment_Salesforce__c == '')) ){
          //   response.isSuccess = false;
          //   response.errorMessage = 'Please select Hosting Environment (Salesforce)';
          //   return response;
          // } 

          // if((pocRequestRS.Jira_Cloud__c == 'Yes' && (pocRequestRS.Hosting_Environment__c == null || pocRequestRS.Hosting_Environment__c == ''))){
          //   response.isSuccess = false;
          //   response.errorMessage = 'Please select Hosting Environment (Jira)';
          //   return response;
          // } 
         
          if(pocRequestRS.Jira_Cloud__c == 'NO' && (pocRequestRS.Number_of_Users_Atlassian__c != null && pocRequestRS.Number_of_Users_Atlassian__c != 0)){
            response.isSuccess = false;
            response.errorMessage = 'Number of Users(Jira) must be 0.';
            return response;
          } 
         
          if(pocRequestRS.Salesforce__c == 'No' && (pocRequestRS.Number_of_Users_Salesforce__c != null && pocRequestRS.Number_of_Users_Salesforce__c != 0)){
            response.isSuccess = false;
            response.errorMessage = 'Number of Users (Salesforce) must be 0.';
            return response;
          } 

          if(pocRequestRS.Dynamics__c == 'No' && (pocRequestRS.Number_of_Users_Dynamics__c != null && pocRequestRS.Number_of_Users_Dynamics__c != 0)){
            response.isSuccess = false;
            response.errorMessage = 'Number of Users (Dynamics) must be 0.';
            return response;
          }
 
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') && pocRequestRS.Add_Identity_Resilience__c == 'Yes' && (pocRequestRS.How_many_identity_users_are_there__c == null || pocRequestRS.How_many_identity_users_are_there__c <= 0)){//
            response.isSuccess = false;
            response.errorMessage = 'Users must be greater than 0';
            return response;
          }
          
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') && pocRequestRS.Add_Identity_Recovery__c == 'Yes' && (pocRequestRS.How_many_Identity_UsersAreThere__c == null || pocRequestRS.How_many_Identity_UsersAreThere__c <= 0)){//
                  response.isSuccess = false;
                  response.errorMessage = 'Users must be greater than 0';
                  return response;
          }
          
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') && pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == 'Yes' && (pocRequestRS.How_many_users_are_there_in_the_Okta_IdP__c == null || pocRequestRS.How_many_users_are_there_in_the_Okta_IdP__c <= 0)){//
            response.isSuccess = false;
            response.errorMessage = 'Users must be greater than 0';
            return response;
          }
          
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') && 
          ((pocRequestRS.Add_Identity_Recovery__c == 'No' && pocRequestRS.Add_Identity_Resilience__c == 'No' && pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == 'No') || 
            ((pocRequestRS.Add_Identity_Recovery__c == null || pocRequestRS.Add_Identity_Recovery__c == '') && (pocRequestRS.Add_Identity_Resilience__c == null || pocRequestRS.Add_Identity_Resilience__c == '') && (pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == null || pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == '')) || 
            ((pocRequestRS.Add_Identity_Recovery__c == null || pocRequestRS.Add_Identity_Recovery__c == '') && pocRequestRS.Add_Identity_Resilience__c == 'No' && (pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == null || pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == '')) || 
            (pocRequestRS.Add_Identity_Recovery__c == 'No' && (pocRequestRS.Add_Identity_Resilience__c == null || pocRequestRS.Add_Identity_Resilience__c == '') && (pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == null || pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == '')) || 
            ((pocRequestRS.Add_Identity_Recovery__c == null || pocRequestRS.Add_Identity_Recovery__c == '') && (pocRequestRS.Add_Identity_Resilience__c == null || pocRequestRS.Add_Identity_Resilience__c == '') && (pocRequestRS.Identity_Cyber_Recovery_for_Okta__c == 'No'))
          )){
                  response.isSuccess = false;
                  response.errorMessage = 'Identity Resilience, Identity Recovery or Cyber Recovery for Okta must be selected';
                  return response;
          }
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Identity Recovery') && !pocRequestRS.Product_Categories__c.contains('Identity Recovery and Resilience - AD, Entra ID, Okta') && ( pocRequestRS.How_many_identity_users_areThere__c == null || pocRequestRS.How_many_identity_users_areThere__c <= 0)){
            response.isSuccess = false;
            response.errorMessage = 'Identity Users must be greater than 0';
            return response;
          }
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Cloud Unstructured (S3, Azure Blob, and Cloud Files)') && !pocRequestRS.Product_Categories__c.contains('NAS Cloud Direct')){
            response.isSuccess = false;
            response.errorMessage = 'To provision Cloud Unstructured, NAS Cloud Direct is required. Please include NAS Cloud Direct in your request whether you need it or not. For edition, select bundled with Cloud Unstructured.';
            return response;
          }

          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Cloud Unstructured (S3, Azure Blob, and Cloud Files)') && ( pocRequestRS.How_much_FETB_do_you_need__c == null || pocRequestRS.How_much_FETB_do_you_need__c < 1 || pocRequestRS.How_much_FETB_do_you_need__c > 10)){
            response.isSuccess = false;
            response.errorMessage = 'FETB range must be 1 - 10';
            return response;
          }
          if(pocRequestRS.RSCAccountType__c != null && selectedRscInstance != null){
            pocRequestRS.RSCInstance__c = selectedRscInstance.Id;
          }

          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('M365 and Google Workspace') && 
             ((pocRequestRS.M365_Option__c == 'No' && pocRequestRS.Google_Workspace__c == 'No') || 
              ((pocRequestRS.M365_Option__c == null || pocRequestRS.M365_Option__c == '')&& (pocRequestRS.Google_Workspace__c == null || pocRequestRS.Google_Workspace__c == '')) || 
              ((pocRequestRS.M365_Option__c == null || pocRequestRS.M365_Option__c == '') && pocRequestRS.Google_Workspace__c == 'No') || 
              (pocRequestRS.M365_Option__c == 'No' && (pocRequestRS.Google_Workspace__c == null || pocRequestRS.Google_Workspace__c == ''))
             )){
                 response.isSuccess = false;
                 response.errorMessage = 'M365 Option or Google Workspace must be selected';
                 return response;
             }
          
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('M365 and Google Workspace') && (pocRequestRS.M365_Option__c == 'Yes') && ( pocRequestRS.Number_of_Users__c == null || pocRequestRS.Number_of_Users__c <= 0 || pocRequestRS.Number_of_Users__c > 500)){
              response.isSuccess = false;
              response.errorMessage = 'Number of Users must be between 1 to 500.';
            return response;
          }
          
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('M365 and Google Workspace') && (pocRequestRS.Google_Workspace__c == 'Yes') && ( pocRequestRS.Number_of_Users_Google_Workspace__c == null || pocRequestRS.Number_of_Users_Google_Workspace__c <= 0 || pocRequestRS.Number_of_Users_Google_Workspace__c > 500)){
              response.isSuccess = false;
              response.errorMessage = 'Number of Users must be between 1 to 500.';
              return response;
          }
        
        //added for MKT-38
          if(pocRequestRS.Product_Categories__c != null && pocRequestRS.Product_Categories__c.contains('Rubrik Agent Cloud') && (pocRequestRS.Agent_Cloud_Acknowledgement__c == '' || pocRequestRS.Agent_Cloud_Acknowledgement__c == null || pocRequestRS.Agent_Cloud_Acknowledgement__c == 'No')){
              response.isSuccess = false;
              response.errorMessage = 'Please follow the approval instructions for Rubrik Agent Cloud then check the acknowledgment.';
              return response;
          }

          List<String> allCategories = new List<String>();
          if(pocRequestRS.Product_Categories__c != null){
                List<String> categories = pocRequestRS.Product_Categories__c.split(';');
                allCategories.addAll(categories);
          }
          List<POC_Product_Picker_Type__mdt> pocProductPickerTypeList = [SELECT Id FROM POC_Product_Picker_Type__mdt WHERE PLS_Product__c = true AND Custom_Master_Label__c IN : allCategories];
          Integer plsCategoriesSize = pocProductPickerTypeList.size();
          Integer stampedCategoriesSize = allCategories.size();
          if(plsCategoriesSize > 0 && plsCategoriesSize == stampedCategoriesSize){
            pocRequestRS.POC_Bundle_Type__c = 'PLS Only SKUs';
          }else if(plsCategoriesSize != 0 && plsCategoriesSize < stampedCategoriesSize){
            pocRequestRS.POC_Bundle_Type__c = 'Mixed SKUs';
          }else{
            pocRequestRS.POC_Bundle_Type__c = 'No PLS SKUs';
          }
         // pocRequestRS.Support_Awareness_needed__c='Yes';
          //pocRequestRS.Planned_Installation_Date__c=system.today().addDays(7);
          if(editmode=='true') {
            update  pocRequestRS;
          }
       
          else {
            insert  pocRequestRS;

          }

         
          if(fileListInsert.size()>0){
            List<String> documentIDS = uploadFile(fileListInsert,pocRequestRS.id);
            if(documentIDS.size()==fileListInsert.size())
             response.isSuccess = true;
             else {
             response.isSuccess = false;
             response.errorMessage ='Error in File Upload';
             }

          } else{

            response.isSuccess = true;
          }
         
          if(response.isSuccess){
            submitforPOCRequestApprovalProcress(pocRequestRS.id);
           }


      } catch (Exception  e) {
          
        Boolean resultApprovalLocak= e.getMessage().contains('first error: ENTITY_IS_LOCKED');
        response.isSuccess = false;
        if(resultApprovalLocak){
          response.errorMessage = 'Record Lock as It is Pending in Approval Procress';
          } else {
            response.errorMessage = e.getMessage();
          }
        
         

      }

      }

      return response;
  }

  /**
 * @description Retrieves a Pricebook2 record based on the provided Pricebook2 Id.
 * This method performs a SOQL query to fetch the Pricebook2 record and returns the first result.
 *
 *
 * @param Pricebook2Id The Id of the Pricebook2 record to retrieve.
 *
 * @return Pricebook2 The Pricebook2 record matching the provided Id.
 */
  public static Pricebook2 getPriceBook (String Pricebook2Id){

      List<Pricebook2> PricebookRS = [Select id,Name from Pricebook2 where id =:Pricebook2Id];

      return PricebookRS[0];

  }
  /**
 * @description Determines whether the current user has the role or permission to act as an approver.
 * This method typically checks the user's profile, role, or other criteria to validate if they are authorized
 * to approve records or requests within the system.
 *
 * @return boolean Returns true if the current user is an approver, otherwise returns false.
 */
  
  /**
 * @description Determines whether the current user has the role or permission to act as an approver.
 * This method typically checks the user's profile, role, or other criteria to validate if they are authorized
 * to approve records or requests within the system.
 *
 * @return boolean Returns true if the current user is an approver, otherwise returns false.
 */
  
  /**
 * @description Determines whether the current user has the role or permission to act as an approver.
 * This method typically checks the user's profile, role, or other criteria to validate if they are authorized
 * to approve records or requests within the system.
 *
 * @return boolean Returns true if the current user is an approver, otherwise returns false.
 */
  
  /**
 * @description Determines whether the current user has the role or permission to act as an approver.
 * This method typically checks the user's profile, role, or other criteria to validate if they are authorized
 * to approve records or requests within the system.
 *
 * @return boolean Returns true if the current user is an approver, otherwise returns false.
 */
  
  /**
 * @description Determines whether the current user has the role or permission to act as an approver.
 * This method typically checks the user's profile, role, or other criteria to validate if they are authorized
 * to approve records or requests within the system.
 *
 * @return boolean Returns true if the current user is an approver, otherwise returns false.
 */
  
  public static boolean checkCurrentUserApprover(){
    boolean isApprovePresent=false;
    User currUser =[Select id,name,POC_Approver__c from User where id=:UserInfo.getUserId()];
    if(currUser.POC_Approver__c ==null) {
       isApprovePresent=true;
    }
    
    return isApprovePresent;
  }

  /**
 * @description Checks whether the current user is allowed to initiate or access a Conditional POC (Proof of Concept) flow.
 * This method verifies the user's Id against a list of allowed user Ids stored in a custom label (ConditionalPOCAllowedUser).
 * *
 * @return boolean Returns true if the current user's Id is present in the allowed list; otherwise, returns false.
 */

  public static boolean checkConditionalPOCUser(){
    boolean isconditionalpocallowed=false;
    String alloweduserIDs = Label.ConditionalPOCAllowedUser;
    if(alloweduserIDs.contains(UserInfo.getUserId())) {
      isconditionalpocallowed=true;
    }
    return isconditionalpocallowed;
  }
  
  /**
 * @description getOpportuntiyDetails getting opportunity details.
 * *
 * * @param OpportuntiyID The Id of the opportunity record to retrieve.
 * @return Opportunity Returns opportunity data.
 */
  public static Opportunity getOpportuntiyDetails (String OpportuntiyID){
      Opportunity opportuntiyObj = new Opportunity();
      
        
         opportuntiyObj=[Select id,Opportunity_Type__c,Name,OwnerId,Owner.Name, AccountId, PartnerAccount.Name,Rubrik_Security_Cloud_Gov_t_Owner__c, Rubrik_Security_Cloud_Gov_t_Owner__r.Name,
         Partner_Lookup__r.Name,Account.name,Distributor_Rep_Name__c,StageName,Partner_Lookup__c
         ,Partner_Lookup__r.Partner_Agreement_Status__c,Distributor_Lookup__c,Distributor_Lookup__r.Name,
         Distributor_Lookup__r.Partner_Agreement_Status__c,Partner_Lookup__r.Agreed_To_POC_terms__c
        ,Account.ShippingCountry,Account.ShippingStreet,Account.ShippingCity,
        Account.ShippingStateCode,Pricebook2Id,Account.BillingCountry,Account.BillingStreet,Account.BillingCity,
        Account.BillingStateCode,Account.BillingPostalCode,Account.RSC_G_Eligible__c, Account.Type,Account.Website
         from Opportunity where Id =:OpportuntiyID];

         
         return opportuntiyObj;
  }

  /**
 * @description Performs validation checks related to the specified Opportunity ID.
 * This method executes business logic validations and returns a map containing
 * validation status messages or error details keyed by validation types.
 *
 * @param oppId The ID of the Opportunity record to be validated.
 * @return Map<String, String> A map where keys represent validation identifiers and values
 *         contain corresponding validation messages or statuses.
 */
  @AuraEnabled
 public static map<String,String>  validateCheck(String oppId) {
      map<String,String> validationMap = new map<String,String>();
       Boolean isApproverPresent = checkCurrentUserApprover();
    if(oppID !='' && oppId != null){
        List<Opportunity> opp =[select id,Pricebook2Id,Economic_Buyer__c,Metric__c,Decision_Process__c,Decision_Criteria__c,
                                Partner_Lookup__c,Distributor_Lookup__c,Initial_Contacts_Name__c,Identified_Pain__c,Champion__c,StageName from Opportunity where id=:oppId];
        if(opp != null){
            
            if (opp[0].Partner_Lookup__c ==null || opp[0].Distributor_Lookup__c==null){
                  validationMap.put('Status','Error');
                  validationMap.put('Message','Please select Partner, Distributor and Primary Contact to proceed !');
                
              }  
             
            if(opp[0].StageName != null && opp[0].StageName.Contains(system.label.Closed)){
               validationMap.put('Status','Error');
               validationMap.put('Message',Label.POCFORM_OppCloseMessage);
                
                }
            else if(opp[0].Economic_Buyer__c == null || opp[0].Champion__c == null)
                {
                
                validationMap.put('Status','Error');
                validationMap.put('Message',Label.POCFORM_OppValidationMessage);
                }
            
                
              else if(isApproverPresent) {
                  
                      validationMap.put('Status','Error');
                      validationMap.put('Message','You’re missing a POC Approver. Please reach out to POChelp@rubrik.com');
                 }
             	else if (opp[0].Pricebook2Id == null){
                 validationMap.put('Status','Error');
                  validationMap.put('Message','Please select CPQ Price book on Opportunity. Go to Products Related List on Opportunity, select Choose Price book, and select CPQ Price Book.');
                
                  } 

                
            else if(opp[0].Pricebook2Id !=null) {

                Pricebook2 priceBookRecord = getPriceBook(opp[0].Pricebook2Id);
                if(priceBookRecord.Name!='CPQ PriceBook') {
                  validationMap.put('Status','Error');
                  validationMap.put('Message','Please select CPQ Price book on Opportunity. Go to Products Related List on Opportunity, select Choose Price book, and select CPQ Price Book.');
                }
              }
           
            

            
            else {
                
               validationMap.put('Status','Success');
               validationMap.put('Message','');
            }
                
          }   
        }
      
    return validationMap;
}
/**
 * @description Retrieves the POC__c (Proof of Concept) record details based on the provided POC request Id.
 * This method performs a SOQL query to fetch the POC__c record matching the given Id.
 *
 * @param PocRequestID The Id of the POC__c record to retrieve.
 *
 * @return POC__c The POC__c record corresponding to the provided Id.
 */
  public static POC__c getPOCRequestDetails (String PocRequestID){
    POC__c pocObj = new POC__c();
    pocObj=[Select id,Name,OwnerId,Owner.Name,Opportunity__c,POC_Type__c,POC_Relocation__c,Planned_Installation_Date__c,Planned_Installation_Date_Time__c,New_Expected_End_Date__c,POC_Justification__c,Disty_with_Signed_POC_Addendum__c,Contact__c,Shipping_Company_Name__c,Shipping_Contact__c,Shipping_Contact_Email__c,Shipping_Contact_Phone__c,Shipping_Street__c,Shipping_City__c,Shipping_Zip_Postal_Code__c,Shipping_State__c,Ship_To_Country__c,POC_Shipping_Information_Comments__c,POC_Relocation_Asset__c from POC__c where Id =:PocRequestID];
    return pocObj;
}

/**
 * @description Updates the given Opportunity record to indicate that the online agreement has been signed..
 *
 * @param opportunityObj The Opportunity record to be updated.
 *
 * @return boolean Returns true if the update is successful; otherwise, returns false.
 */
  public static boolean setOnlineAgreementSigned(Opportunity opportunityObj) {
    boolean OnlineAgreementStatus = false;
    List<Contact> signedContacts = [SELECT Id FROM Contact WHERE AccountId = :opportunityObj.AccountId AND Agreed_To_POC_term__c = true LIMIT 1];

    OnlineAgreementStatus = (!signedContacts.isEmpty());

    return OnlineAgreementStatus;
}

/**
 * @description Uploads a list of files to a specified record.
 * `.
 *
 * @param fileList A list of fileInnerClass instances representing the files to be uploaded.
 * @param recordId The Id of the Salesforce record to which the files will be attached.
 *
 * @return List<String> A list of Ids representing the successfully uploaded files.
 */

  public static List<String> uploadFile(List<FileInnerClass> fileList,String recordId) {  //String base64, String filename, String recordId
      List<String> returnDocIDs = new List<String>();
      if(fileList.size()>0) {
       for(FileInnerClass rsFile:fileList) {

       ContentVersion cv = createContentVersion(String.valueof(rsFile.base64),String.valueof(rsFile.filename));
       ContentDocumentLink cdl = createContentLink(cv.Id, recordId);
       if (cv == null || cdl == null) { return null; }
       returnDocIDs.add(cdl.Id);
       

       }
      

      }
      return returnDocIDs;  
}

private static ContentVersion createContentVersion(String base64, String filename) {
 ContentVersion cv = new ContentVersion();
 cv.VersionData = EncodingUtil.base64Decode(base64);
 cv.Title = filename;
 cv.PathOnClient = filename;
 try {
   insert cv;
   return cv;
 } catch(DMLException e) {
   return null;
 }
}


private static ContentDocumentLink createContentLink(String contentVersionId, String recordId) {
           if (contentVersionId == null || recordId == null) { return null; }
 ContentDocumentLink cdl = new ContentDocumentLink();
 cdl.ContentDocumentId = [
   SELECT ContentDocumentId 
   FROM ContentVersion 
   WHERE Id =: contentVersionId
 ].ContentDocumentId;
 cdl.LinkedEntityId = recordId;
 // ShareType is either 'V', 'C', or 'I'
 // V = Viewer, C = Collaborator, I = Inferred
 cdl.ShareType = 'V';
 try {
   insert cdl;
   return cdl;
 } catch(DMLException e) {
   return null;
 }
}

/**
 * @description Retrieves dependent picklist options based on the controlling field's value.
 * This method fetches the available picklist values for a dependent field (theField) 
 *
 *
 * @param theField The dependent picklist field for which options are being retrieved.
 * @param ctrlField The controlling picklist field that determines the dependency.
 *
 * @return Map<String, List<String>> A map of controlling field values to their respective dependent picklist options.
 */

public static Map<String, List<String>> getDependentOptionsImpl(Schema.SObjectField theField, Schema.SObjectField ctrlField) {
// validFor property cannot be accessed via a method or a property,
// so we need to serialize the PicklistEntry object and then deserialize into a wrapper.
List<Schema.PicklistEntry> contrEntries = ctrlField.getDescribe().getPicklistValues();
List<PicklistEntryWrapper> depEntries = wrapPicklistEntries(theField.getDescribe().getPicklistValues());

// Set up the return container - Map<ControllingValue, List<DependentValues>>
Map<String, List<String>> objResults = new Map<String, List<String>>();
List<String> controllingValues = new List<String>();

for (Schema.PicklistEntry ple : contrEntries) {
    String label = ple.getLabel();
    objResults.put(label, new List<String>());
    controllingValues.add(label);
}



for (PicklistEntryWrapper plew : depEntries) {
    String label = plew.label;
    String value = plew.value;
    String validForBits = base64ToBits(plew.validFor);
    for (Integer i = 0; i < validForBits.length(); i++) {
        // For each bit, in order: if it's a 1, add this label to the dependent list for the corresponding controlling value
        String bit = validForBits.mid(i, 1);
        if (bit == '1') {
            objResults.get(controllingValues.get(i)).add(label+';'+value);
        }
    }
}

return objResults;
}
/**
 * @description Wrapper class to represent a picklist entry with its metadata.
 * This class encapsulates details such as whether the entry is active, its label,
 * default value status, actual value, and any validity conditions.
 */
public class PicklistEntryWrapper {
  /**
     * @description Indicates if the picklist entry is active ("true" or "false").
     */
public String active {get; set;}
/**
     * @description Indicates if this picklist entry is the default selection ("true" or "false").
     */
public String defaultValue {get; set;}
 /**
     * @description The display label of the picklist entry.
     */
public String label {get; set;}
/**
     * @description The API or internal value of the picklist entry.
     */
public String value {get; set;}
/**
     * @description Encodes the validity of the picklist entry for controlling dependent picklists.
     */
public String validFor {get; set;}
}
private static List<PicklistEntryWrapper> wrapPicklistEntries(List<Schema.PicklistEntry> PLEs) {
return (List<PicklistEntryWrapper>)
    JSON.deserialize(JSON.serialize(PLEs), List<PicklistEntryWrapper>.class);
}

/**
 * @description Converts a Base64-encoded string into its corresponding bit representation.
 *
 * @param validFor The Base64-encoded string to be converted.
 *
 * @return String A string representing the bit sequence decoded from the Base64 input.
 */

public static String base64ToBits(String validFor) {
if (String.isEmpty(validFor)) return '';

String validForBits = '';

for (Integer i = 0; i < validFor.length(); i++) {
    String thisChar = validFor.mid(i, 1);
    Integer val = base64Chars.indexOf(thisChar);
    String bits = decimalToBinary(val).leftPad(6, '0');
    validForBits += bits;
}

return validForBits;
}

private static final String base64Chars = '' +
'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
'abcdefghijklmnopqrstuvwxyz' +
'0123456789+/';

/**
 * @description Converts a decimal integer value to its binary string representation.
 *
 * @param val The decimal integer value to be converted.
 *
 * @return String The binary string equivalent of the provided decimal value.
 */

public static String decimalToBinary(Integer val) {
String bits = '';
while (val > 0) {
    Integer remainder = Math.mod(val, 2);
    val = Integer.valueOf(Math.floor(val / 2));
    bits = String.valueOf(remainder) + bits;
}
return bits;
}
/**
 * @description Retrieves a mapping of countries to their respective states or provinces.
 * This method returns a map where each key is a country name (or code),
 * and the corresponding value is a list of state or province names associated with that country.
 *
 * @return Map<String, List<String>> A map containing country names as keys and lists of their states/provinces as values.
 */

public static Map<String, List<String>> getMapCountryState() {
return getDependentOptionsImpl(Contact.MailingStateCode, Contact.MailingCountryCode);
}
/**
 * @description Retrieves a list of states or provinces for the specified country.
 * This method looks up all states/provinces associated with the given country name
 * and returns them as a list of strings.
 *
 * @param Countryname The name of the country for which the states/provinces are to be retrieved.
 * @return List<String> A list containing the names of states or provinces for the specified country.
 */
@AuraEnabled(cacheable=true)
public static List<String> getStatebyCountry(String Countryname) {
Map<String, List<String>> returnResult =getMapCountryState();
List<String> sateList = new List<String>();
   if(returnResult.size()>0){
     if(returnResult.containsKey(Countryname))
      sateList =returnResult.get(Countryname);
     
   }

return  sateList; //JSON.serialize(sateList);
}

/* Validates the Installation date on POC Request Form*/
/**
 * @description Validates the installation date based on various criteria such as validation type, 
 * number of days, POC type, and expected end date. This method ensures that the provided installation date 
 * adheres to business rules like allowable date ranges, dependencies on other dates, or POC-specific constraints.
 *
 * @param inputDate The proposed installation date to be validated.
 * @param typeofValidation The type of validation to perform (e.g., "beforeEndDate", "withinRange").
 * @param days A string representing the number of days used in validation logic (e.g., allowable range).
 * @param poCType The type of POC (Proof of Concept) which may influence the validation logic.
 * @param expectedEndDate The expected end date used for comparison in some validation scenarios.
 * @return Map<String, String> A map containing the result of the validation.
 */
@AuraEnabled
public static map<String,String>  validateInstallationDate(Date inputDate,String typeofValidation,String days,String poCType,Date expectedEndDate) {
  map<String,String> returnResult = new map<String,String>();
 try {
  
 
  
  if(poCType!='Web Try and Buy') {

    if(typeofValidation=='PlanDateLogic') {
      Date currentDate = system.today();
      Date dateAfterXDays = currentDate.addDays(Integer.valueOf(days));
      
    if(poCType!='Ransomware Recovery Software'){
    if((date.newinstance(inputDate.year(), inputDate.month(), inputDate.day())  < date.newinstance(dateAfterXDays.year(), dateAfterXDays.month(), dateAfterXDays.day()))){
      returnResult.put('Status','Error');
      returnResult.put('Message','Plan Installation Date should be '+days+ ' day(s) greater than created date');     //Changed with MKT26-505 - Start
  		}
  }
  if(date.newinstance(inputDate.year(), inputDate.month(), inputDate.day())  <  date.newinstance(currentDate.year(), currentDate.month(), currentDate.day())){
    returnResult.put('Status','Error');
    returnResult.put('Message','Plan Installation Date should be  greater than created date');
  
}
 }
  else if(typeofValidation=='ExpectedDateLogic'){
    Date plantDate = Date.valueOf(inputDate);
    Date dateAfterXDaysExpected = plantDate.addDays(Integer.valueOf(days));
    Date currentSysDate = system.today();
    if(plantDate ==null) {
      returnResult.put('Status','Error');
      returnResult.put('Message','Please enter Plan Instllation Date first');
    }

    
   if( date.newinstance(expectedEndDate.year(), expectedEndDate.month(), expectedEndDate.day())  >date.newinstance(dateAfterXDaysExpected.year(), dateAfterXDaysExpected.month(), dateAfterXDaysExpected.day())) {
    returnResult.put('Status','Error');
    returnResult.put('Message','Expected End  Date should be within '+days+ ' days of plan installation date');
  }

 
  if( date.newinstance(expectedEndDate.year(), expectedEndDate.month(), expectedEndDate.day())  <  date.newinstance(currentSysDate.year(), currentSysDate.month(), currentSysDate.day())) {
    returnResult.put('Status','Error');
    returnResult.put('Message','Expected End  Date should be greater than created date');
  }
  }
  else {
    returnResult.put('Status','Success');
    returnResult.put('Message','');
  }
} else {
  if(typeofValidation=='PlanDateLogic') { 
    
    Date currentDateWeb = system.today();
    
    Date dateAfterXDays = inputDate.addDays(Integer.valueOf(days));

    if(date.newinstance(inputDate.year(), inputDate.month(), inputDate.day()) <= date.newinstance(currentDateWeb.year(), currentDateWeb.month(), currentDateWeb.day()))
    {
      returnResult.put('Status','Error');
      returnResult.put('Message','Plan Installation Date should be  greater than created date');
      
    
  } else {
    returnResult.put('Expected End Date',String.valueOf(dateAfterXDays));
  }
}

}
}

catch(Exception ex){
throw new AuraHandledException(ex.getMessage());
}
return returnResult;
}

/* Autosubmits the POC Reuqest approval*/
/**
 * @description Submits the specified POC request record for the approval process.
 * This method initiates the approval workflow for the given POC__c record ID.
 * It may include setting the appropriate status, updating fields, and invoking
 * standard or custom Salesforce approval processes as defined in the system.
 *
 * @param RecordID The ID of the POC__c record to be submitted for approval.
 */
public static void submitforPOCRequestApprovalProcress(String RecordID){
  POC__c pocRequest = new POC__c();
  pocRequest=[Select id,Name,POC_Type__c,Approval_Status__c from POC__c where id =:RecordID ];
 /* String approvalProcessName = '';
  for( POC_Request_Approval_Process_Mapping__mdt objProcess : [Select Id, MasterLabel, Approval_Process_API_Name__c From POC_Request_Approval_Process_Mapping__mdt Where Masterlabel =: pocRequest.POC_Type__c]) {
    approvalProcessName = objProcess.Approval_Process_API_Name__c;
  }*/
  
  try{
   if(pocRequest !=null) {
      Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();                 
      req.setObjectId(pocRequest.id);
      /*if('Standard POC'==pocRequest.POC_Type__c ) 
          req.setProcessDefinitionNameOrId('POC_Request_Customer_Standard_v2');
      else if('CSAT Loaner' == pocRequest.POC_Type__c)
          req.setProcessDefinitionNameOrId('POC_Request_Loaner_Unit_v5');

      else if('Web Try and Buy' == pocRequest.POC_Type__c)
          req.setProcessDefinitionNameOrId('POCType_Web_Try_and_Buy_AutoApproval');
      */
      //req.setProcessDefinitionNameOrId(approvalProcessName);    
      //else 
         // req.setProcessDefinitionNameOrId('POC_Extension_Customer_Standard_POC');
      //req.setProcessDefinitionNameOrId('POC_Extension_Approval');
      Approval.ProcessResult result = Approval.process(req);
  }
  
}catch(Exception ex) {
      throw new AuraHandledException(ex.getMessage());
  }
}

/* Updates the POC after Extension Requested*/
/**
 * @description Updates an existing POC request record with new or modified information.
 *
 * @param pocRequest The POC__c record containing updated field values to be saved.
 * @return response_Wrapper An object containing the outcome of the update operation, including
 * status, success/failure message, and any relevant data or error details.
 */
@AuraEnabled
    public static response_Wrapper updatePOCRequest(POC__c pocRequest) {
        response_Wrapper response = new response_Wrapper();
        Savepoint sp = Database.setSavepoint();
        boolean skipApproval=false;
        
        try {
            //MKT23661
             pocRequest.Current_POC_Submission_Date__c=system.now();
             pocRequest.Send_Pending_Notification__c=true;
             if(pocRequest.Approval_Status__c=='Extension Requested' && (pocRequest.POC_Type__c=='Web Try and Buy' || pocRequest.POC_Type__c=='Virtual Lab'))
             {
                           POC__c pocExtensionCount=[Select id,Number_of_Extensions__c from POC__c where id =:pocRequest.Id];

                 skipApproval=true;
                 pocRequest.Approval_Status__c='Extension Approved';
                 pocRequest.Most_Recent_End_Date__c=pocRequest.New_Expected_End_Date__c;
                 if(pocExtensionCount.Number_of_Extensions__c>=1)
                 pocRequest.Number_of_Extensions__c=pocExtensionCount.Number_of_Extensions__c+1;
                 else{
                    pocRequest.Number_of_Extensions__c=+1;
                 }
             }
            update pocRequest;
            if(pocRequest !=null){
               response.isSuccess = true;
            }
            if(pocRequest !=null && skipApproval!=true){
                submitforExtensionApprovalProcress(pocRequest.Id);
                response.isSuccess = true;
            }          
            
        } catch (Exception e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
/* Autosubmits the POC for Extension approval*/
/**
 * @description Submits the specified record for the extension approval process.
 *
 * @param RecordID The ID of the record to be submitted for extension approval.
 */
@future
    public static void submitforExtensionApprovalProcress(String RecordID){
      POC__c pocRequest = new POC__c();
      pocRequest=[Select id,Name,POC_Type__c,Approval_Status__c from POC__c where id =:RecordID ];
      
       if(pocRequest !=null) {
          Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();                 
          req.setObjectId(pocRequest.id);
          /*if('Virtual Lab'==pocRequest.POC_Type__c || 'Web Try and Buy' == pocRequest.POC_Type__c)
              req.setProcessDefinitionNameOrId('Web_Try_and_Buy_Extension_Auto_Approval');
          else if('CSAT Loaner' == pocRequest.POC_Type__c)
              req.setProcessDefinitionNameOrId('POC_Extension_Loaner_Unit');
          else 
              req.setProcessDefinitionNameOrId('POC_Extension_Customer_Standard_POC');*/
          //req.setProcessDefinitionNameOrId('POC_Extension_Approval');
          Approval.ProcessResult result = Approval.process(req);
      }
        
        
    }
/* Submits the POC Return request*/
/**
 * @description Submits a POC return request along with its associated return items.
 *
 * @param pocReturn The primary POC return record containing return request details.
 * @param returnItemList A list of POC return item records associated with the return request.
 * @return response_Wrapper An object containing the response status, message, and any relevant data or error information
 * resulting from the submission process.
 */
@AuraEnabled
    public static response_Wrapper submitRequest(POC_Return__c pocReturn, List < POC_Return_Item__c > returnItemList) {
        response_Wrapper response = new response_Wrapper();
        Savepoint sp = Database.setSavepoint();
        try {
            pocReturn.status__c = 'Draft';
            insert pocReturn;
            for (POC_Return_Item__c pocReturnItem: returnItemList) {
                pocReturnItem.POC_Return__c = pocReturn.Id;
            }
            if (!returnItemList.isEmpty())
                insert returnItemList;

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();           
            req.setObjectId(pocReturn.id);
            Approval.ProcessResult result = Approval.process(req);
            response.isSuccess = true;
        } catch (DmlException e) {
            Database.rollback(sp);
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
    }
/* Accepts the POC__c Id and checks for Assets Related and returns the Response*/
/**
 * @description Retrieves order records associated with a given POC request ID.
 * This method fetches and returns order data related to the specified POC request,
 * encapsulated within a response_Wrapper object that includes status and any relevant messages.
 *
 * @param pocRequestId The ID of the POC request for which the orders are to be retrieved.
 * @return response_Wrapper An object containing the list of orders and associated response details.
 */
@AuraEnabled
    public static response_Wrapper getOrders(String pocRequestId) {
        response_Wrapper response = new response_Wrapper();
        
        try {
            list < POC__c > pOCList = [Select id, Name, Approval_Status__c, Ship_To_Country__c, Shipping_City__c, Shipping_Contact_Email__c, Shipping_Contact__c, Shipping_Contact_Phone__c, Shipping_Country__c, Shipping_State__c, Shipping_Street__c, Shipping_Zip_Postal_Code__c,
            (SELECT id, Product2.Name, Product2.Id, SerialNumber FROM Assets__r where SerialNumber != null), (Select id from POC_Returns__r where status__c != 'Rejected') From POC__c where id =: pocRequestId];
            //List < Asset > accetList = [SELECT id, Product2.Name, Product2.Id, SerialNumber FROM Asset where SerialNumber != null Limit 2 ];
            List < Asset > accetList = new List < Asset >();
            accetList = pOCList[0].Assets__r;
            response.pocRecords = pOCList;
            response.assetRecords = accetList;
            response.isSuccess = true;
            if (accetList.isEmpty()) {
                response.isSuccess = false;
                response.errorMessage = 'Can not request a return as there is no asset on this POC Request';
            }else if(!pOCList[0].POC_Returns__r.isEmpty()){
                response.isSuccess = false;
                response.errorMessage = 'Can not request a return as there is already a return requested';
            }else if(pOCList[0].Approval_Status__c == 'Extension Requested'){
                response.isSuccess = false;
                response.errorMessage = 'An extension request is already under process for this POC';
            }
        } catch (DmlException e) {
            
            response.isSuccess = false;
            response.errorMessage = e.getMessage();
        }
        return response;
  }
/* Vaildated the Expected end date on Poc Extension*/
/**
 * @description Validates the expected end date for a given POC record based on the specified validation type.
 * This method performs logic to check if the provided expected end date meets certain criteria
 *
 * @param pocRecordId The ID of the POC record for which the validation is to be performed.
 * @param typeofValidation The type of validation to apply (e.g., "range", "futureDate", "mandatory").
 * @param expectedEndDate The date value that needs to be validated.
 * @return Map<String, String> A map containing the result of the validation.
 */
@AuraEnabled
public static map<String,String>  validateExpectedEndDate(String pocRecordId,String typeofValidation,Date expectedEndDate) {
  map<String,String> returnResult = new map<String,String>();
  try {
   String poCType='';
   Integer days=0;
  
    POC__c pocRecordDate = new POC__c();
    pocRecordDate= [Select Id,POC_Type__c,Name,Most_Recent_End_Date__c from POC__c where id=:pocRecordId];
    poCType=pocRecordDate.POC_Type__c;
    if(pocType == 'Standard POC' || pocType == 'CSAT Loaner') {

       days=180;
   }
   if(pocType == 'Virtual Lab') {

       days=14;
   }
   if(pocType == 'Partner Software Access') {

       days=365; 
   }
   if(pocType == 'Standard POC : RSC-G') {

       days=60; 
   } 
   if(typeofValidation=='ExpectedDateLogic'){

     Date plantDate = pocRecordDate.Most_Recent_End_Date__c;
     Date dateAfterXDaysExpected = plantDate.addDays(Integer.valueOf(days));
     Date currentSysDate = system.today();
   /* if(plantDate ==null) {
       returnResult.put('Status','Error');
       returnResult.put('Message','Please enter Plan Instllation Date first');
     }*/


    if( date.newinstance(expectedEndDate.year(), expectedEndDate.month(), expectedEndDate.day())  >date.newinstance(dateAfterXDaysExpected.year(), dateAfterXDaysExpected.month(), dateAfterXDaysExpected.day())) {
     returnResult.put('Status','Error');
     returnResult.put('Message','Expected End  Date should be within '+days+ ' days of Most Recent Date');
   }



   }
   else {
     returnResult.put('Status','Success');
     returnResult.put('Message','');
   }

 
} catch(Exception ex){
  throw new AuraHandledException(ex.getMessage());
 }

 return returnResult;
}
/* Poplulates emails on POC by invoking POC_Request_Expiration_Notification*/
/**
 * @description Populates email-related fields on POC request records.
 * This method retrieves POC_Request__c records based on the provided list of record IDs
 *
 * @param pocReqId List of POC_Request__c record IDs for which email fields need to be populated.
 */
@InvocableMethod
public static void populateEmailsOnPoc(List<Id> pocReqId){
    POC__c pocRec =  new POC__c( );
    pocRec = [Select id, Opportunity__c, Opportunity__r.Owner.Email,Opportunity__r.Owner.Manager.Email, Opportunity__r.Owner.Manager.Manager.Email,

              Opportunity__r.Rubrik_Sales_Engineer__r.Email,Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Email, Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Manager.Email, Opportunity__r.ETM_Region__c 
              , AE_Email__c , SE_Email__c,RSM_Email__c,SEM_Email__c, RD_Email__c, SED_Email__c, TVP_Email__c, SETL_Email__c,Opportunity__r.ETM_Theatre__c from POC__c where id =:pocReqId[0] Limit 1];

    POC__c clonedRec = pocRec.clone(true, true, false, false);

    VP_Email_For_POC_Extension__c vpEmails = VP_Email_For_POC_Extension__c.getOrgDefaults();
    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.Owner != null && !String.isBlank(pocRec.Opportunity__r.Owner.Email))
        pocRec.AE_Email__c = pocRec.Opportunity__r.Owner.Email;

    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.Rubrik_Sales_Engineer__r != null && !String.isBlank(pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Email))
        pocRec.SE_Email__c = pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Email;

    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.Owner != null && pocRec.Opportunity__r.Owner.Manager != null && !String.isBlank(pocRec.Opportunity__r.Owner.Manager.Email))
        pocRec.RSM_Email__c = pocRec.Opportunity__r.Owner.Manager.Email;

    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.Rubrik_Sales_Engineer__r != null && pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager != null && !String.isBlank(pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Email))
        pocRec.SEM_Email__c = pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Email;

    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.Owner != null && pocRec.Opportunity__r.Owner.Manager != null && pocRec.Opportunity__r.Owner.Manager.Manager != null && !String.isBlank(pocRec.Opportunity__r.Owner.Manager.Manager.Email))
        pocRec.RD_Email__c = pocRec.Opportunity__r.Owner.Manager.Manager.Email;

    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.Rubrik_Sales_Engineer__r != null && pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager != null  && pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Manager != null && !String.isBlank(pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Email))
        pocRec.SED_Email__c = pocRec.Opportunity__r.Rubrik_Sales_Engineer__r.Manager.Manager.Email;

    if(pocRec.Opportunity__c != null && pocRec.Opportunity__r.ETM_Region__c != null){

        if(pocRec.Opportunity__r.ETM_Theatre__c.contains('EMEA')) {
           //  pocRec.TVP_Email__c = vpEmails.SE_Theater_VP_Email__c;
             pocRec.SETL_Email__c = vpEmails.EMEA_SE_VP_Email__c;

        }
        if(pocRec.Opportunity__r.ETM_Theatre__c.contains('APAC')) {
           //  pocRec.TVP_Email__c = vpEmails.SE_Theater_VP_Email__c;
             pocRec.SETL_Email__c = vpEmails.APAC_SE_VP_Email__c;

        }
        if(pocRec.Opportunity__r.ETM_Theatre__c.contains('AMER')) {
            // pocRec.TVP_Email__c = vpEmails.SE_Theater_VP_Email__c;
             pocRec.SETL_Email__c = vpEmails.AMER_SE_VP_Email__c;

        }

    }


    if(clonedRec.AE_Email__c !=pocRec.AE_Email__c || clonedRec.SE_Email__c !=pocRec.SE_Email__c || clonedRec.RSM_Email__c !=pocRec.RSM_Email__c || clonedRec.SEM_Email__c !=pocRec.SEM_Email__c || 
       clonedRec.RD_Email__c !=pocRec.RD_Email__c || clonedRec.SED_Email__c !=pocRec.SED_Email__c || clonedRec.SETL_Email__c !=pocRec.SETL_Email__c )
        update pocRec;

}
/* Returns POC_Product_Picker_Matrix__mdt*/
/**
 * @description Retrieves a list of product picker configuration records from custom metadata.
 * This method queries the custom metadata type.
 *
 * @return List<POCProductPickerConfig> A list of configuration records that define
 * product picker rules and mappings used in the application.
 */
@AuraEnabled
    public static List<POC_Product_Picker_Matrix__mdt> getProductSKUs(){
        return [Select Id, DeveloperName, Product_SKU__c, Switch_Type__c From POC_Product_Picker_Matrix__mdt];
    }
/* Returns POCProductPickerConfig by quering POC_Product_Picker_Type__mdt*/
/**
 * @description Retrieves a list of product picker configuration records from custom metadata.
 * This method queries the custom metadata type.
 *
 * @return List<POCProductPickerConfig> A list of configuration records that define
 * product picker rules and mappings used in the application.
 */
@AuraEnabled
    public static List<POCProductPickerConfig> getProductCustomMetadata1(){
        List<POCProductPickerConfig> configs = new List<POCProductPickerConfig>();
        for(POC_Product_Picker_Type__mdt prodPicker : [SELECT MasterLabel, Order__c, Multi_products_Allowed__c,POC_Type__c,Custom_Master_Label__c,
                                                        (SELECT Id, Field_Api_Name__c, Order__c, DeveloperName, FieldLabel__c, Required__c
                                                        FROM POC_Product_Picker_Fields__r ) 
                                                        FROM POC_Product_Picker_Type__mdt 
                                                       WHERE Is_Active__c = TRUE
                                                        ORDER BY Order__c ASC]){
            POCProductPickerConfig  config = new POCProductPickerConfig();
            config.prodCategory = prodPicker.Custom_Master_Label__c;
            config.prodCategoryOrder = prodPicker.Order__c;
            config.pocTypes = prodPicker.POC_Type__c;
            //sort and save
            config.fields = new List<POC_Product_Picker_Field__mdt>();
            List<MdtFields> lstFieldsUnsorted = new List<MdtFields>();      
            Integer lastIndex = 0;
            //for(Integer i=0; i<prodPicker.POC_Product_Picker_Fields__r.length(); i++){
            for(POC_Product_Picker_Field__mdt field : prodPicker.POC_Product_Picker_Fields__r){
                lstFieldsUnsorted.add( new MdtFields(field) );
            }
            lstFieldsUnsorted.sort();
            for( MdtFields objFld : lstFieldsUnsorted ) {
                config.fields.add(objFld.option1);
            } 
            //config.fields = prodPicker.POC_Product_Picker_Fields__r;
            config.multiProduct = prodPicker.Multi_products_Allowed__c;
            configs.add(config);
        } 
        return configs;
    }
/* MdtFields implements the Comparable Interface*/
/**
 * @description Wrapper class for the POC_Product_Picker_Field__mdt custom metadata record.
 * Implements the Comparable interface to allow sorting of instances based on the 
 */
public class MdtFields implements Comparable {
  /**
 * @description Constructor to initialize the MdtFields wrapper with a POC_Product_Picker_Field__mdt record.
 *
 * @param option1 The custom metadata record of type POC_Product_Picker_Field__mdt to be wrapped.
 */
  public POC_Product_Picker_Field__mdt option1 ;
  /**
 * @description Constructor to initialize the MdtFields wrapper with a POC_Product_Picker_Field__mdt record.
 *
 * @param option1 The custom metadata record of type POC_Product_Picker_Field__mdt to be wrapped.
 */
  public MdtFields(POC_Product_Picker_Field__mdt option1) {
      this.option1 = option1;
  }
  
  // Implement the compareTo() method
  /**
 * @description Compares this MdtFields instance with another based on the Order__c field
 * of the underlying custom metadata record for sorting purposes.
 *
 * @param compareTo The other object to compare against; expected to be an instance of MdtFields.
 * @return Integer Returns 0 if orders are equal, 1 if this order is greater, -1 otherwise.
 */
  public Integer compareTo(Object compareTo) {
      MdtFields compareToEmp = (MdtFields)compareTo;
      if (option1.Order__c == compareToEmp.option1.Order__c) return 0;
      if (option1.Order__c > compareToEmp.option1.Order__c) return 1;
      return -1;        
  }        
  
}
/* POCProductPickerConfig Class*/
/**
 * @description Represents configuration settings for the Product Picker.
 * Contains metadata such as category, order, allowed product selections, and applicable POC types.
 */
class POCProductPickerConfig{
    /*ProductPicker MasterLabel*/
    /**
     * @description The master label or category name for the product picker.
     */
    @AuraEnabled public String prodCategory{get;set;}
    /*ProductPicker Order*/
    /**
     * @description The order or priority of the product category for sorting purposes.
     */
    @AuraEnabled public Decimal prodCategoryOrder{get;set;}
    /*ProductPicker MultiProduct Allowed*/
    /**
     * @description Indicates whether multiple products can be selected under this category.
     */
    @AuraEnabled public Boolean multiProduct{get;set;}
    /*ProductPicker Poc Type*/
    /**
     * @description Specifies which POC  types this configuration applies to.
     */
    @AuraEnabled public String pocTypes{get;set;}
    /*ProductPicker*/
    /**
     * @description List of fields related to the product picker, referencing the custom metadata type.
     */
    @AuraEnabled public List<POC_Product_Picker_Field__mdt> fields{get;set;}
}
  /**
 * @description Retrieves all active picklist values for the specified field on a given object.
 * @param objectName The API name of the Salesforce object (e.g., 'Opportunity').
 * @param fieldName The API name of the picklist field (e.g., 'StageName').
 * @note This method is cacheable and can be used directly in LWC or Aura components.
 * @author : Naveen Selvaraj
 * @date   : 12/11/2025 (DD/MM/YYYY)
 */
  @AuraEnabled(cacheable=true)
  public static List<String> getPicklistValues(String objectName, String fieldName) {
        List<String> activeValues = new List<String>();
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fields.getMap()
            .get(fieldName)
            .getDescribe();

        for (Schema.PicklistEntry entry : fieldResult.getPicklistValues()) {
            if (entry.isActive()) {
                activeValues.add(entry.getLabel());
            }
        }
      return activeValues;
  }
  /**
 * @description Fetches RscInstance__c records for a given Account based on the specified Account Type.
 * @param accountId The Id of the Account for which RscInstance__c records need to be retrieved.
 * @param accType The RSC Account Type used to filter the RscInstance__c records.
 * @author : Naveen Selvaraj
 * @date : 12/11/2025 (DD/MM/YYYY)
 */
  @AuraEnabled(cacheable=true)
  public static List<RscInstance__c> getRscInstance(Id accountId){
    Set<String> statusToExclude = new Set<String>{Constants.RSCINSTANCE_STATUS_DELETED, Constants.RSCINSTANCE_STATUS_MARKED_FOR_DELETION};
    return [Select Id,RSCAccountType__c,RSCAccountRelationship__c,RSCUrl__c,RSCSuggestedURL__c,Status__c from RscInstance__c where AccountId__c = :accountId and Status__c NOT IN :statusToExclude];
  }
}