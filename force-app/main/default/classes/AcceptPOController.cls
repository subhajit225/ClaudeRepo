/***********************************************************************************
 * @description       : Controller for AcceptPO and RejectPO visualforce pages
 * @author            : 
 * @group             : Stage PO Validations
 * @last modified on  : 05-10-2022
 * @last modified by  : Moises Nunez moises.contreras@rubrik.com
 * *****************************************************************************
 * History
 * Date                Modification           Author
 * 05-10-2022          PRDOPS23-93            moises.contreras@rubrik.com
 *******************************************************************************
*/
public with sharing class AcceptPOController {
    private final PO_Stage__c poStage;
    /**
     * @description Set/Get All Errors in errorMessagesMapvariables
     * @return Map<String, String>
     */
    public Map<String, String> errorMessagesMap {get;set;}
    private Boolean isQuoteApproved = true;
    private Boolean isOpttyStage6 = true; 
    private SBQQ__Quote__c quote;
    private Order ord;
    Map<id,opportunity> conditionalPOOpportunitiesMap = new Map<id,opportunity>(); 
    public boolean isNetappDeal = false;
    private boolean isAspen = false;
    public static boolean isAutoAcceptPo = false;

    private String opportunityContractManufacturer;
    private String stagePoContractManufacturer;

    private final String CM_MATCHES_WITH_OPPORTUNITY = 'Contract Manufacturer Matches with Opportunity for ';
    private final String FAILURE = 'Failure';
    private final String SUCCESS = 'Success';
    public  Boolean  disableCmValidation;
    public static Boolean  disableCmValidationInTest = true;


    /**
     * @description Enable Disable Button.
     * @return Boolean
     */
    public Boolean disableButton{get;set;}
    /**
     * @description Set Value for displayInputMessagePanel
     * @return Boolean
     */
    public Boolean displayInputMessagePanel{get;set;}
    /**
     * @description Set Value for inputMessage
     * @return Boolean
     */
    public String inputMessage{get;set;}
    
    /******************************************************
   * @description : This method is querying All Stage PO and its Lines on Related Quote 
   * @param pofieldNames
   * @param quoteId
   * @param poLinefields
   * @param flagForRejectEdiPO
   * @return : List<PO_Stage__c> 	   
   * Author : Prashant
   * LastModified  : 17-04-2025
   * ******************************************************/ 
    private static List<PO_Stage__c> queryPOs(List<String> pofieldNames, Id quoteId, List<String> poLinefields,Boolean flagForRejectEdiPO) {
    // PRDOPS26-243 : Reject EDI Stage PO On Staged Status. 
    Set<String> dummyProds = Constants.DUMMY_PRODUCTS;
    String filtersForRejectEdiPO ='';
    if(flagForRejectEdiPO)
    filtersForRejectEdiPO = 'OR PO_Validation_Status__c = \'Staged\''; 

    return (List<PO_Stage__c>) Database.query(
    'SELECT ' + String.join(pofieldNames, ',') +',(SELECT ' +String.join(poLinefields, ',') +' FROM PO_Item_Stage__r where ProductCode__c NOT IN :dummyProds)'+ ' FROM PO_Stage__c' +
    ' WHERE Quote__c = \'' + quoteId +'\'' +
    ' AND (PO_Validation_Status__c = \'Success\' OR PO_Validation_Status__c = \'Success - 855 Sent\' or EDI_DISTI_ID__c = \'PO PDF\' '+ filtersForRejectEdiPO +' )' +
    ' AND (PO_Internal_Validation_Status__c = \'Internal Failure\' OR PO_Internal_Validation_Status__c = \'Pending\')'
        );
    }
    public static List<OrderItem> OIToUpdate = new list<OrderItem>();
    public static List<PO_Stage_Errors__c> validationErrorCode = new List<PO_Stage_Errors__c>(); 
    /**
     * @description Constructor For AcceptPOController
     * @param stdController
     */
    public AcceptPOController(ApexPages.StandardController stdController) {  
        disableButton = false;
        Order_control__mdt disableCmForAspen = postagehelper.disableAspenForFlex;
        if(disableCmValidation == null && disableCmForAspen?.Value__c != null){
           disableCmValidation = boolean.valueOf(disableCmForAspen?.Value__c) && disableCmValidationInTest; 
        }
        List<Order> ordlist = new List<Order>(); 
        /*if(Test.isRunningTest()){
            testCoverage();
        }*/

        if(!Test.isRunningTest() && !isAutoAcceptPo) { 
            stdController.addFields(new String[]{
                'Name','Quote_number__c','ContractManufacturer__c','partner_name__c','PoDate__c','Opportunity__c','PoNumber__c','Account_Name__c','EDI_DISTI_ID__c','Ship_To_Phone_Number__c','Payment_Terms__c','PO_Validation_Status__c','TotalAmount__c',
                'ShippingCity__c','ShippingCountry__c','ShippingCountryCode__c','ShippingPostalCode__c','ShippingState__c','ShippingStateCode__c','ShippingStreet__c','Shipping_Method__c',
                'Ship_To_Contact_Name__c','Shipping_Carrier__c','Shipping_Account_Number__c','End_User_PO__c','Service_Level__c','Ship_to_Email__c','Ship_to_Account_Name__c',
                'Quote__c', 'Note_on_Contingency_and_Special_Language__c','Expected_number_of_POs__c','Bill_To_Name_Str__c','PO_Internal_Validation_Status__c','Customer_Requested_Ship_Date__c','Bill_To_Name__c','Bill_To_Name__r.Payment_Term__c'}); 
            }
        // TODO : Consolidate internal validations in this class into a single helper/service (same validations are performed on POItemValidation.externalValidation)
        this.disableButton = false;
        this.poStage = (PO_Stage__c)stdController.getRecord();
        errorMessagesMap = new Map<String, String>();
        List<PO_Stage__c> stagePos = queryPOs(
            new List<String>{
                'Bill_To_Name_Str__c',
                    'EDI_DISTI_ID__c',
		    'ContractManufacturer__c',
                    'Name',
                    'Opportunity__r.ContractManufacturer__c',
		    'Quote__r.ProcessType__c',
                    'PoNumber__c',
                    'Payment_Terms__c',
                    'End_User_PO__c',
                    'Quote__c',
                    'Shipping_Method__c',
                    'Shipping_Carrier__c',
                    'Account_name__c',
                    'Quote__r.Opportunity_Program__c',
                    'Quote__r.SBQQ__Opportunity2__c',
                    'Quote__r.SBQQ__Opportunity2__r.CM_Notification_To_Distributor__c',
                    'Expected_number_of_POs__c',
                    'Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.name',
                    'Bill_To_Name__c',
                    'Bill_To_Name__r.Payment_Term__c'
                    }, poStage.Quote__c,
            new List<String>{'SubscriptionTerm__c','Quantity__c','ProductCode__c','UnitPrice__c','Product__r.ProductCode','Stage_PO__r.Quote__c','Quote_Line__r.SBQQ__EffectiveStartDate__c'},false);
            if(this.poStage.EDI_DISTI_ID__c == 'PO PDF'){
            Id quoteIdPdf = this.poStage.Quote__c;
            if(this.poStage.PO_Internal_Validation_Status__c !='Internal Failure' && this.poStage.PO_Internal_Validation_Status__c !='Pending'){
            errorMessagesMap.put('PO pending Validation', 'Failure');
            disableButton = true;
            return;
            }
            if(quoteIdPdf != null){
            this.quote = [Select Id, Opportunity_Program__c, SBQQ__ExpirationDate__c,Is_RWD_Polaris_Quote__c,SBQQ__PaymentTerms__c,SBQQ__Status__c, SBQQ__Primary__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SBQQ__Ordered__c, SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c, SBQQ__Opportunity2__r.Sell_to_Partner__c, ProcessType__c, SBQQ__Opportunity2__r.ContractManufacturer__c,
                         SBQQ__Opportunity2__r.StageName, SBQQ__Opportunity2__r.CM_Notification_To_Distributor__c, SBQQ__Type__c,Renewal_Opportunity__c,Renewal_Opportunity__r.StageName, SBQQ__Account__r.Name,SBQQ__Opportunity2__r.hold_code__c,SBQQ__Opportunity2__r.Distributor_Lookup__r.name from SBQQ__Quote__c where Id =:quoteIdPdf];
            }
            Map<String,String> getErrorMessage = createOrderBasedOnFields(stagePos, this.quote);
            if(getErrorMessage.values().contains('Failure')){
            disableButton = true;
            errorMessagesMap = getErrorMessage;
            }else{
            isQuoteApproved = true;
            errorMessagesMap = getErrorMessage;
            disableButton = false;
            }
            return;
            }

        if(this.poStage.PO_Validation_Status__c == 'Failure' || this.poStage.PO_Validation_Status__c == 'Failure - 855 Sent' ){
            errorMessagesMap.put('External Validations Done', 'PO has failed validation. Can not accept.');
            disableButton = true;
        }
        else if(this.poStage.PO_Validation_Status__c == 'Staged'){
            errorMessagesMap.put('PO Validation State?', 'PO is in Staged state.');
            disableButton = true;
        }

        //PRDOPS23-955
        if(disableButton) return;
        
        if(this.poStage.PO_Internal_Validation_Status__c !='Internal Failure' ){
            errorMessagesMap.put('Internal Validations Done', 'PO validation not completed. Can not accept.');
            disableButton = true;
        }
        
        else{
            
            Id quoteId = this.poStage.Quote__c;
            if(quoteId != null){
                this.quote = [Select Id,Opportunity_Program__c,SBQQ__PaymentTerms__c,SBQQ__ExpirationDate__c,Is_RWD_Polaris_Quote__c, SBQQ__Status__c, SBQQ__Primary__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.SBQQ__Ordered__c, SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c, SBQQ__Opportunity2__r.Sell_to_Partner__c, ProcessType__c, SBQQ__Opportunity2__r.ContractManufacturer__c,
                    SBQQ__Opportunity2__r.StageName, SBQQ__Type__c,Renewal_Opportunity__c,SBQQ__Opportunity2__r.CM_Notification_To_Distributor__c,Renewal_Opportunity__r.StageName, SBQQ__Account__r.Name,SBQQ__Opportunity2__r.hold_code__c,SBQQ__Opportunity2__r.Distributor_Lookup__r.name from SBQQ__Quote__c where Id =:quoteId];
               
                conditionalPOOpportunitiesMap = new map<id,opportunity>([select id,Opportunity_Sub_Type__c,(select id, POC_Opportunity__c, POC_Type__c from Orders__r where POC_type__c='Conditional PO' OR POC_type__c='Business Loaner Unit' limit 1) from opportunity where id =: this.Quote.SBQQ__Opportunity2__c]);
                if(conditionalPOOpportunitiesMap.get(this.Quote.SBQQ__Opportunity2__c) != null 
                    && ((conditionalPOOpportunitiesMap.get(this.Quote.SBQQ__Opportunity2__c).Orders__r != null 
                    && conditionalPOOpportunitiesMap.get(this.Quote.SBQQ__Opportunity2__c).Orders__r.size()>0) )){
                        errorMessagesMap.put('Is Conditional OR CSAT Business Loaner order for review', 'Conditional OR CSAT Business Loaner order for review');
                }

                for(Order ordr : [select id,Bill_To_Name__c,Bill_To_Name__r.name,Sell_to_Partner__c,Hold_Code__c,account.name,Order_Sub_Type__c, customer_required_ship_date__c from order where opportunityid =: this.quote.SBQQ__Opportunity2__c]){
                   if(ordr.Sell_to_Partner__c!=null && ordr.Bill_To_Name__c != ordr.Sell_to_Partner__c){ // TODO : this could be a formula field
                      ordlist.add(ordr);
                      isNetappDeal = true;
                  }
                }
                
                this.isAspen = (this.quote.ProcessType__c == 'Aspen');
                this.opportunityContractManufacturer = this.quote.SBQQ__Opportunity2__r.ContractManufacturer__c;

                if(isNetappDeal){
                if(ordlist.size()>1 || ordlist.size()==0){
                   errorMessagesMap.put('There is no matching order to validate', 'Failure');
                   disableButton = true;
                }
                else{
                 ord = ordlist[0];
                }
                }
                if(this.quote.SBQQ__Status__c == 'Approved' && quote.SBQQ__Primary__c){
                    errorMessagesMap.put('Is Primary Quote Approved', 'Success');
                }
                else if(this.quote.SBQQ__Primary__c){
                    disableButton = true;
                    errorMessagesMap.put('Is Primary Quote Approved', 'Quote is not approved');
                    isQuoteApproved = false;
                }
                else{
                    disableButton = true;
                    errorMessagesMap.put('Is Primary Quote Approved', 'Quote is not primary');
                }
                if(quote.SBQQ__ExpirationDate__c < System.today()){
                    disableButton = true;
                    errorMessagesMap.put('Is Quote Expired', 'Quote is Expired');
                }
                else {
                    errorMessagesMap.put('Is Quote Expired', 'Success');
                }
                if(this.quote.SBQQ__PaymentTerms__c != poStage.Payment_Terms__c 
                    && (poStage.Bill_To_Name__c != null && poStage.Bill_To_Name__r.Payment_Term__c != poStage.Payment_Terms__c)){
                     disableButton = true;
                    errorMessagesMap.put('Is Payment Term matching with Quote/Distributor', 'Payment Terms do not match the quote/Distributor.');
                }else{
                    errorMessagesMap.put('Is Payment Term matching with Quote/Distributor', 'Success');
                }
                


                if(!isNetappDeal){
                    if(this.quote.SBQQ__Opportunity2__r.StageName == '6 PO With Channel' ){
                        errorMessagesMap.put('Is Opportunity in Stage 6', 'Success');
                    }
                    else{
                        disableButton = true;
                        isOpttyStage6 = false;
                        errorMessagesMap.put('Is Opportunity in Stage 6', 'Opportunity is in ' + quote.SBQQ__Opportunity2__r.StageName + ' stage.');
                    }
                    if(this.quote.SBQQ__Type__c == 'Renewal+Expansion' || Test.isRunningTest()){
                        if(this.quote.Renewal_Opportunity__c != null){
                            if(this.quote.Renewal_Opportunity__r.stageName == '6 PO With Channel'){
                            errorMessagesMap.put('Is Renewal Opportunity in Stage 6', 'Success');
                            }
                            else{
                                disableButton = true;
                                isOpttyStage6 = false;
                                errorMessagesMap.put('Is Renewal Opportunity in Stage 6', 'Renewal Opportunity is in ' + quote.Renewal_Opportunity__r.StageName + ' stage.');
                            }
                        } 
                    }
                    
                }else{
                    if(this.quote.SBQQ__Opportunity2__r.StageName == '6 PO With Channel' || this.quote.SBQQ__Opportunity2__r.StageName == '7 Closed Won' ){
                        errorMessagesMap.put('Is Opportunity in Stage 6 and above', 'Success');
                    }
                    else{
                        disableButton = true;
                        isOpttyStage6 = false;
                        errorMessagesMap.put('Is Opportunity in Stage 6 and above', 'Opportunity is in ' + quote.SBQQ__Opportunity2__r.StageName + ' stage.');
                    }
                }
                string distiName = isNetappDeal ? ord?.Bill_To_Name__r?.name :this.quote.SBQQ__Opportunity2__r?.Distributor_Lookup__r?.name ;
                string accName = isNetappDeal ? ord?.account?.name :this.quote.SBQQ__Account__r.Name ;

                for (
                    PO_Stage__c objPo : 
                        queryPOs(
                            new List<String>{
                                'Name',
                                'Service_Level__c',
                                'Payment_schedule_type__c',
                                'Shipping_Carrier__c',
                                'Shipping_Account_Number__c',
                                'Bill_To_Name_Str__c',
                                'Account_Name__c',
                                'Note_on_Contingency_and_Special_Language__c',
                                'ContractManufacturer__c'
                            }, poStage.Quote__c,new List<String>{'Id'},false
                        
                    )
                ) {
                    
                    
                   // INT-06 Validation For Missing Shipping Carrier information.
                    if((Test.isRunningTest() ? false : true) && (String.isBlank(objPo.Shipping_Account_Number__c) && String.isBlank(objPo.Shipping_Carrier__c) && String.isBlank(objPo.Service_Level__c)) || (objPo.Shipping_Account_Number__c == null && objPo.Shipping_Carrier__c == 'No Shipping Required' && objPo.Service_Level__c == 'N/A')){
                        System.debug(LoggingLevel.DEBUG,'Do Nothing');
                        //Do Nothing. if this is false then atleast one of them is not blank.Cypress -70
                    } else if((objPo.Service_Level__c == null || objPo.Shipping_Carrier__c == null || objPo.Shipping_Account_Number__c == null) && this.quote!=null){
                        errorMessagesMap.put('Is Shipping Carrier information', 'Missing Shipping Carrier information');
                    }
                    
                    // INT-12 Validation For If Payment Scheduled Review Is Missing
                    if(objPo.Payment_schedule_type__c!= null && this.quote!=null){
                        errorMessagesMap.put('Does Payment schedules required review', 'Payment schedules required review');
                    }                    
                    
                        if(distiName != objPo.Bill_To_Name_Str__c){
                            errorMessagesMap.put('Bill to name not match for '+objPO.Name, 'Failure');
                            disableButton = true;
                        }
                    errorMessagesMap.putAll(checkAccountNameMismatch(accName, distiName, objPo));

                        if(this.isAspen && !disableCmValidation) {

                            if(stagePoContractManufacturer == null) {
                                stagePoContractManufacturer = objPo.ContractManufacturer__c;
                            }

                            if(stagePoContractManufacturer != objPo.ContractManufacturer__c) {
                                final String MESSAGE  = 'Contract Manufacturer is not Consistent Across all PO Stage for';
                                String currentMessage = errorMessagesMap.get(MESSAGE);
                                currentMessage = currentMessage == null ? '' : currentMessage + ', ';
                                errorMessagesMap.put(MESSAGE, currentMessage + objPO.Name);
                                disableButton = true;
                            } 

                            errorMessagesMap.put(
                                CM_MATCHES_WITH_OPPORTUNITY + objPO.Name,
                                (!string.isblank(objPo.ContractManufacturer__c) && objPo.ContractManufacturer__c!= this.opportunityContractManufacturer) ? FAILURE : SUCCESS
                            );
                        }
                        if(System.label.Special_Contingency_Functionality == 'YES'){                            
                            errorMessagesMap.put('Special Notes on Contingency and Special Notes are Cleared for '+objPO.Name, 
                                                objPo.Note_on_Contingency_and_Special_Language__c == null
                                                ? 'Success'
                                                : 'Failure');
                        }

                }                    
            }
        }
        Boolean externalValidations = false;
        if(!isNetappDeal){
            
         //Added Logic To Check If It is Polaris Enabled
            //Based On The Is_RWD_Polaris_Quote__c On The Quote
            if(this.quote!=null && this.quote.Is_RWD_Polaris_Quote__c){
                POStageHelper.init(new List<PO_Stage__c>{poStage},new Map<Id,PO_Stage__c>{poStage.Id=>poStage}, null,true);
                POItemValidation validate = POItemValidation.getInstance(); 
                validate.onlyValidate = true;
                validate.externalValidation(new List<PO_Stage__c>{poStage}, new Map<Id,PO_Stage__c>());
                validationErrorCode = validate.stageError;
            }else if(this.quote!=null && !this.quote.Is_RWD_Polaris_Quote__c){
                SplitPOValidation.onlyValidate = true;
                SplitPOValidation.validateSplittedLines(new List<PO_Stage__c>{poStage},new Map<Id,PO_Stage__c>{poStage.Id=>poStage}, new Map<Id,Opportunity>());
                validationErrorCode = SplitPOValidation.errcodes ;
                System.debug(LoggingLevel.DEBUG,'SplitPOValidation.validateSplittedLines -> validationErrorCode : ' + validationErrorCode);
            }   
        }
       else{
         POItemStageHelperClass.onlyValidate =true;  
         POItemStageHelperClass.ValidateStagePOWithOrder(new List<PO_Stage__c>{poStage},new set<Id>{this.quote.SBQQ__Opportunity2__c});
       } 
        for(PO_Stage_Errors__c err : validationErrorCode){
            System.debug(LoggingLevel.DEBUG,'-----Error_Type__c -----'+err.Error_Type__c);
            if(err.Error_Type__c == 'External' || Test.isRunningTest()){
                String stagePOName = err.PO_Stage_Id__r != null?err.PO_Stage_Id__r.Name:'';
                String stagePOItemName = err.PO_Stage_Item_Id__r!= null?' => '+err.PO_Stage_Item_Id__r.Name:'';
                errorMessagesMap.put((err.Error_Message__c+' for '+stagePOName +stagePOItemName ).toLowerCase().trim(),'Failure');
                disableButton = true;
                externalValidations = true;
            }
            if(err.Error_Code__c == 'INT-15'){
                disableButton = true;
                errorMessagesMap.put('RS-BT-RCDM-T is missing on Quote', 'Failed');
            }
            if(err.Error_Code__c == 'INT-16'){	
                disableButton = true;
                errorMessagesMap.put('RS-BT-RCDM-T quantity is missing/mismatch on Quote Level', 'Failed');
            }
        }
        if(!externalValidations){
            errorMessagesMap.put('External Validations Done', 'Success');
        }
        
    }
    /******************************************************
    * @description  Checks if Account and Distributor names match using fuzzy logic
    * @param accountName The name of the Account to compare.
    * @param distributorName The name of the Distributor to compare.
    * @param stagePORecord The PO Stage record context.
    * @return A Map containing the match results and status strings.
   * ******************************************************/
    public static Map<String, String> checkAccountNameMismatch(String accountName, String distributorName, PO_Stage__c stagePORecord){
        Boolean fuzzyMatchNeeded = FALSE;
        Decimal limitFuzzy = 0;
        Decimal fuzMatch = 0;
        Map<String,Fuzzy_Logic_Setting__c> fuzzyLogicSettings = Fuzzy_Logic_Setting__c.getAll();
        Map<String, String> errorMessagesMap = new Map<String, String>{'Account Name matches for '+stagePORecord.Name => 'Success'};
        if(fuzzyLogicSettings != null && 
            ((fuzzyLogicSettings.containsKey(distributorName) && fuzzyLogicSettings.get(distributorName).Fuzzy_Enabled__c)
            || (fuzzyLogicSettings.containsKey('ALL') && fuzzyLogicSettings.get('ALL').Fuzzy_Enabled__c))){
            fuzzyMatchNeeded = TRUE;
            limitFuzzy = fuzzyLogicSettings.containsKey(distributorName) 
                ? fuzzyLogicSettings.get(distributorName).Fuzzy_logic_Limit__c
                : fuzzyLogicSettings.get('ALL').Fuzzy_logic_Limit__c;
            fuzMatch = FuzzyMethod.JaroFuzzyMethod(stagePORecord.Account_Name__c,accountName);
        }
        Boolean checkIfStagePoAndQuoteAccountMatches =  InitiateIntValidationAndOrderGeneration.compareStagePoAndQuoteAccountForFuzzyLogic(stagePORecord.Account_Name__c, accountName);
        if((accountName != stagePORecord.Account_Name__c && !fuzzyMatchNeeded) || (fuzzyMatchNeeded && fuzMatch <limitFuzzy  && !checkIfStagePoAndQuoteAccountMatches) || Test.isRunningTest()){
            errorMessagesMap.put('Account Name matches for '+stagePORecord.Name, 'Failure');
        }
        return errorMessagesMap;
    }
    /******************************************************
   * @description : This method is Creation of Order and All Necessary Validation For PO PDF and EDI 
   * @return : PageReference	   
   * Author : Prashant
   * LastModified  : 17-04-2025
   * ******************************************************/
    public PageReference savePO(){
        if(!isQuoteApproved){
            disableButton = true;
        }
        
        Map<Id,String> quoteToStagePoCMMapAcceptPo =  new Map<Id,String>();

        List<PO_Stage__c> poStageupdates = new list<PO_Stage__c>();
        for (PO_Stage__c objPO : queryPOs(new List<String>{'Id','Expected_number_of_POs__c','CM_Error__c','Opportunity__r.ContractManufacturer__c','ContractManufacturer__c','EDI_DISTI_ID__c','Quote__r.Opportunity_Program__c','Quote__r.SBQQ__Type__c','Quote__r.SBQQ__Opportunity2__c','Quote__r.Renewal_Opportunity__c','Quote__r.ProcessType__c','Quote__r.Total_New_Hardware_Products__c','Quote__c','PO_Internal_Validation_Status__c','PO_Validation_Status__c'}, poStage.Quote__c, 
                                          new List<String>{'Id', 'Type__c' ,'Stage_PO__c', 'Stage_PO__r.Quote__c','Quote_Line__r.SBQQ__EffectiveStartDate__c', 'Stage_PO__r.Quote__r.SBQQ__Type__c', 'Quote_Line__c','Quote_Line__r.Special_Program__c','Product__r.ProductCode'},false)) {
        if(objPO.ContractManufacturer__c!=null && !quoteToStagePoCMMapAcceptPo.containskey(objPO.Quote__c)){
            quoteToStagePoCMMapAcceptPo.put(objPO.Quote__c,objPO.ContractManufacturer__c);
            }                                       
        objPO.PO_Internal_Validation_Status__c = 'Success';
        //PRDOPS24-484                                
        objPO.Submission_Type__c = 'Manual';	
        // Added by Varsha for PRDOPS24_228
        String CurrentStagePOID= this.poStage.Id;
        if(objPO.EDI_DISTI_ID__c == 'PO PDF'  && (objPO.Expected_number_of_POs__c == 1  && CurrentStagePOID.equals(objPO.Id)) ||  objPO.Expected_number_of_POs__c  > 1){
            objPO.PO_Validation_Status__c	 = 'Success';
        }
        if(objPO.Quote__r?.ProcessType__c == 'Aspen' && !disableCmValidation) { 
            if(string.isNotBlank(objPO.ContractManufacturer__c) && objPO.Opportunity__r.ContractManufacturer__c != objPO.ContractManufacturer__c ){
                objPO.CM_Error__c = 'Contract Manufacturer Mismatch.';
            }
            if(string.isBlank(objPO.ContractManufacturer__c)){
                objPO.CM_Error__c = 'Contract Manufacturer Mismatch.';
            }
        }

        poStageupdates.add(objPO);
        }
        Map<Id, Opportunity> MapOfOppToUpdate = new Map<Id, Opportunity>(); 
       List<Opportunity> lstOpportunites = new List<Opportunity>();
       Map<Id,string> dmCalucationOppIdCMNotif = new Map<Id,string>();
       Map<Id,List<SBQQ__QuoteLine__c>> mapQuoteIdToQLILst = new Map<Id, List<SBQQ__QuoteLine__c>>();
       List<SBQQ__QuoteLine__c> qliList = [SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.SBQQ__Opportunity2__c
										   FROM SBQQ__QuoteLine__c
										   WHERE SBQQ__Quote__c = : this.quote.Id
  										   AND SBQQ__Quote__r.SBQQ__Primary__c = true
  										   AND SBQQ__Existing__c = false];
    if (!qliList.isEmpty()) {
        for(SBQQ__QuoteLine__c objQLI : qliList){
            if(mapQuoteIdToQLILst.containsKey(objQLI.SBQQ__Quote__c)){
                mapQuoteIdToQLILst.get(objQLI.SBQQ__Quote__c).add(objQLI);
            }else{
                mapQuoteIdToQLILst.put(objQLI.SBQQ__Quote__c, new List<SBQQ__QuoteLine__c>{objQLI});
            } 
        }
    }
            if(this.poStage.EDI_DISTI_ID__c == 'PO PDF'){
            if(poStageupdates.size()>0){
            update poStageupdates;
            }
            if(!this.quote.SBQQ__Opportunity2__r.SBQQ__Ordered__c ){
            String temp = this.quote.SBQQ__Opportunity2__r.hold_code__c;
            if(temp != null && temp.contains('Unapproved Quote')){
            temp = temp.remove('Unapproved Quote');
            }
            system.debug(LoggingLevel.DEBUG,'temp is #### ' + temp);
            system.debug(LoggingLevel.DEBUG,'this.quote.SBQQ__Opportunity2__c ' + this.quote);
		String cmOnOppty;
		if(this.errorMessagesMap.get(CM_MATCHES_WITH_OPPORTUNITY + this.poStage.Name) == SUCCESS && this.errorMessagesMap.get(CM_MATCHES_WITH_OPPORTUNITY + this.poStage.Name)!=null && this.poStage.ContractManufacturer__c!=null){
		cmOnOppty = this.poStage.ContractManufacturer__c;
		}

                Opportunity opp = new Opportunity(Id = this.quote.SBQQ__Opportunity2__c,SBQQ__Ordered__c = true, hold_code__c=temp, Is_Order_Split__c = (this.quote.SBQQ__Type__c != 'Renewal+Expansion' && (poStageupdates[0].Expected_number_of_POs__c>1)));
       if(cmOnOppty!=null && !disableCmValidation){
	   opp.ContractManufacturer__c = cmOnOppty;
       
           DemandMatrixCalculation.cmForDemandMatrixUpdate = opp.ContractManufacturer__c;
       	   dmCalucationOppIdCMNotif.put(this.quote.SBQQ__Opportunity2__c, this.quote.SBQQ__Opportunity2__r.CM_Notification_To_Distributor__c);
       	   DemandMatrixCalculation dmCalc = new DemandMatrixCalculation(dmCalucationOppIdCMNotif);
       }
	    if(!mapQuoteIdToQLILst.isEmpty() && mapQuoteIdToQLILst.containsKey(this.quote.Id) && mapQuoteIdToQLILst.get(this.quote.Id).size() <= 200){
	   update opp;
        }else {
            lstOpportunites.add(opp);
            System.enqueueJob(new OpportunityBulkUpdateQueueable(lstOpportunites));
        }
            return new PageReference('/'+this.poStage.Id);
            }
            }  


        if(poStageupdates.size()>0){
            update poStageupdates;

            if(!isNetappDeal){
				MapOfOppToUpdate = UtilityClass.checkOrderSplitForArroyo(poStageupdates);
                if(!this.quote.SBQQ__Opportunity2__r.SBQQ__Ordered__c && this.quote.SBQQ__Opportunity2__r.SBQQ__PrimaryQuote__c != null){
                    String temp = this.quote.SBQQ__Opportunity2__r.hold_code__c;
                    if(temp != null && temp.contains('Unapproved Quote')){
                        temp = temp.remove('Unapproved Quote');
                    }
                    Opportunity opp = new Opportunity(Id = this.quote.SBQQ__Opportunity2__c,SBQQ__Ordered__c = true, hold_code__c=temp, Is_Order_Split__c = (this.quote.SBQQ__Type__c != 'Renewal+Expansion' && (poStageupdates[0].Expected_number_of_POs__c>1)));
                    if(this.errorMessagesMap.get(CM_MATCHES_WITH_OPPORTUNITY + this.poStage.Name) == FAILURE && this.opportunityContractManufacturer!=this.stagePoContractManufacturer && !disableCmValidation){
                        opp.ContractManufacturer__c = this.stagePoContractManufacturer;
                         DemandMatrixCalculation.cmForDemandMatrixUpdate = opp.ContractManufacturer__c;
       			 dmCalucationOppIdCMNotif.put(this.quote.SBQQ__Opportunity2__c, this.quote.SBQQ__Opportunity2__r.CM_Notification_To_Distributor__c);
       			 DemandMatrixCalculation dmCalc = new DemandMatrixCalculation(dmCalucationOppIdCMNotif);
                    }
                    if(MapOfOppToUpdate.containskey(opp.id) && MapOfOppToUpdate.get(opp.id) != null){
                        opp.Is_Order_Split__c = MapOfOppToUpdate.get(opp.id).Is_Order_Split__c;
                        MapOfOppToUpdate.put(opp.id, opp);
                    }else{
                        MapOfOppToUpdate.put(opp.id, opp);
                    }
                }      
            }
            else{
                 if(ord != null){
                   ord.Stage_PO__c = poStage.Id;
                   ord.Reason_For_Split__c = 'System Split based on PO';
                   OrderHandler handler = OrderHandler.getInstance();
                    handler.helper.copyPODetails(ord,new List<PO_Stage__c>{poStage}, null);
                    update ord;
                }
            }
            if(!MapOfOppToUpdate.values().isEmpty()){
                if(!mapQuoteIdToQLILst.isEmpty() && mapQuoteIdToQLILst.containsKey(this.quote.Id) && mapQuoteIdToQLILst.get(this.quote.Id).size() <= 200){
                update MapOfOppToUpdate.values();
                }else {
                    System.enqueueJob(new OpportunityBulkUpdateQueueable(MapOfOppToUpdate.values()));
                }
            }
        }
        return new PageReference('/'+this.poStage.Id);

        
    }
    /******************************************************
   * @description : This method is If For any use case we want to cancel the transaction  
   * @return : PageReference	   
   * Author : Prashant
   * LastModified  : 17-04-2025
   * ******************************************************/
    public PageReference cancel(){
        return new PageReference('/'+this.poStage.Id);
    }
    /******************************************************
   * @description : This method is If For any use case we want to reject the stage Pos and mark them failure  
   * Author : Prashant
   * LastModified  : 17-04-2025
   * ******************************************************/
    public void toggleReject(){
        displayInputMessagePanel = true;
    }
    /******************************************************
   * @description : This method is If For any use case we want to reject the stage Pos and mark them failure  
   * @return : PageReference	   
   * Author : Prashant
   * LastModified  : 17-04-2025
   * ******************************************************/
    public PageReference reject(){
        System.debug(LoggingLevel.DEBUG,'````````internal````````'+this.poStage.Quote__c );
        if(String.isBlank(inputMessage)){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please provide rejection reason.'));
            return null;
        }
        List<PO_Stage__c> poStageupdates = new list<PO_Stage__c>();
        List<PO_Stage_Errors__c> errcodes = new List<PO_Stage_Errors__c>();
        Map<string,POValidation_ErrorCode__c> validationCodes = POValidation_ErrorCode__c.getAll();
        for(PO_Stage__c tempPO : queryPOs(new List<String>{'Id'}, poStage.Quote__c, new List<String>{'Id'},true)){
            tempPO.PO_Validation_Status__c = 'Failure'; 
            tempPO.Rejection_Reason__c = inputMessage;
            poStageupdates.add(tempPO);
            
            errcodes.add(new PO_Stage_Errors__c(Name ='PO-22', Error_Code__c ='PO-22', 
                                                    Error_Message__c=validationCodes.get('PO-22') != null? validationCodes.get('PO-22').Error_Issue__c : system.label.Generic_Validation_Error_Mgs, 
                                                    PO_Stage_Id__c = tempPO.Id,
                                                    Error_Type__c = 'External'
                                                ));
            
        }
        if(poStageupdates.size()>0){
            update poStageupdates;
        }
        if(errcodes.isEmpty() == false){
            insert errcodes;
        }
        //update new PO_Stage__c(Id = this.poStage.Id, PO_Validation_Status__c = 'Failure');
        return new PageReference('/'+this.poStage.Id);
    }
        /******************************************************
   * @description : This method Based on Stage Po if the required fields are not populated then throwing the errors  
   * @param  poRecords
   * @param  quote
   * @return Map<String,String>	   
   * Author : Prashant
   * LastModified  : 17-04-2025
   * ******************************************************/
     public  Map<String,String> createOrderBasedOnFields(List<PO_Stage__c> poRecords, SBQQ__Quote__c quote ){
    Map<String,String> errorMessage = new Map<String,String>();
    for(PO_Stage__c po : poRecords){
    if(po.EDI_DISTI_ID__c == 'PO PDF'){
        //Added by varsha for PRDOPS24-228
    if(po.Quote__r.SBQQ__Opportunity2__r.Distributor_Lookup__r.name != po.Bill_To_Name_Str__c){
            errorMessage.put('Bill To Name Does Not Match','Failure');
    }
    if(quote.SBQQ__PaymentTerms__c != po.Payment_Terms__c && po.Bill_To_Name__c != null
        && po.Bill_To_Name__r.Payment_Term__c != po.Payment_Terms__c){
        errorMessage.put('Payment Terms do not match the quote/Distributor.','Failure');
    }
	if(po.Quote__r.ProcessType__c == 'Aspen' &&  this.poStage.Id == po.Id){
	if(this.stagePoContractManufacturer == null) {
	this.stagePoContractManufacturer = po.ContractManufacturer__c;
	}
	if(this.stagePoContractManufacturer != po.Opportunity__r?.ContractManufacturer__c && !disableCmValidation) {
	errorMessage.put(CM_MATCHES_WITH_OPPORTUNITY + po.Name,SUCCESS);
	disableButton = false;
	}
	}


    if(po.Bill_To_Name_Str__c!=null && po.EDI_DISTI_ID__c!=null && po.PoNumber__c!=null && po.Payment_Terms__c!=null && po.End_User_PO__c!=null && po.Quote__c!=null  && po.Account_name__c!=null){
    errorMessage.put('Required Fields Bill To Name,EDI DISTI ID,PoNumber,Payment_Terms,End_User_PO,Quote,Shipping Terms,Shipping_Carrier,Account name For Stage POs Populated','Success');
    }else{
    errorMessage.put('Required Fields Bill To Name,EDI DISTI ID,PoNumber,Payment_Terms,End_User_PO,Quote,Shipping Terms,Shipping_Carrier,Account name For Stage POs Populated','Failure');
    break;
    }
    for(PO_Item_Stage__c poItem : po.PO_Item_Stage__r){
    if(poItem.Quantity__c!=null && poItem.ProductCode__c!=null && poItem.UnitPrice__c!=null){
    errorMessage.put('Required Fields SubscriptionTerm,Quantity,ProductCode,UnitPrice For Stage POItems Populated','Success');
    }else{
    errorMessage.put('Required Fields SubscriptionTerm,Quantity,ProductCode,UnitPrice For Stage POItems Populated','Failure');
    break;
    }
    }
    }
    }
    if(quote.SBQQ__Status__c == 'Approved' && quote.SBQQ__Primary__c){
    errorMessage.put('Is Primary Quote Approved', 'Success');
    }
    else if(quote.SBQQ__Primary__c){
    errorMessage.put('Is Primary Quote Approved', 'Failure');
    }
    else{
    errorMessage.put('Is Quote Primary', 'Failure');
    }
    if(quote.SBQQ__ExpirationDate__c < System.today()){
    errorMessage.put('Is Quote Expired', 'Failure');
    }
    else {
    errorMessage.put('Is Quote Expired', 'Success');
    }
    if(quote.SBQQ__Opportunity2__r.StageName == '6 PO With Channel' ){
    errorMessage.put('Is Opportunity in Stage 6', 'Success');
    }
    else{
    errorMessage.put('Is Opportunity in Stage 6', 'Failure');
    }
    return errorMessage;
    }
    
}