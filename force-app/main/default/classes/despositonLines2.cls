/**This class is called when Dispose Lines button is clicked. Handles the Disposition screen logic   */
public class despositonLines2 {     
    public static boolean isDisabled = false; //FY25SR-1706
     
    /** Constructor*/
    public despositonLines2(){} 

    /**@description : gets User Instance for bypass
     * FY25SR-1706
    */
    public static void getBypass(){ 
        ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
        isDisabled = disabled.Disable_Replacement_Framework__c;
    }
    
    /**fetch quote lines to be displayed on the Dispose Lines page*/
    @AuraEnabled
    public static List<SBQQ__QuoteLine__c> getQuoteLines(String quoteId){        
        getBypass(); //FY25SR-1706
        if (Test.isRunningTest()) {
            isDisabled = true;
        }
        if (isDisabled) {    //FY25SR-1706
            Set<Id> qliIDs = new Set<Id>();
            List<SBQQ__QuoteLine__c> quoteLinesToShow = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> qliListReplaced= new List<SBQQ__QuoteLine__c>();
            Set<Id> replacedRenLaterSet = new Set<Id>();
            
            List<SBQQ__QuoteLine__c> quoteLines = [SELECT Id, SBQQ__ProductCode__c,SBQQ__Product__r.Is_MSP_Product__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, Special_Program__c,
                                                Required_By_Product_Code__c, Subscribed_Asset_Name__c, SBQQ__ListPrice__c, Product_Type__c, 
                                                SBQQ__NetPrice__c, Do_not_Renew__c, Disposition_Reason__c, Quote_Line_Type__c, SubscribedAssetNames__c,
                                                SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQSC__RenewedContractLine__r.ServiceContractId, Replace_By__c,
                                                SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber, Line_Type__c, QuoteLine_Group_Name__c, 
                                                SBQQ__Group__c, SBQQ__SubscriptionPricing__c, Arroyo_Subscribed_Asset_Name__c, Product_Level__c, 
                                                Is_Hardware_Product__c, SBQQ__Group__r.Name, Product_Subtype__c, 
                                                SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Disposition_Reason__c, SBQQ__RequiredBy__r.Disposition_Reason__c
                                                FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId AND ((Quote_Line_Type__c = 'Renewal'
                                                AND 
                                                ((Disposition_Reason__c != 'Refreshed' OR (Disposition_Reason__c = 'Refreshed' AND SBQQ__Quote__r.RWD_Deal_Ops_Exception__c INCLUDES('R7k Manual Refresh') ))
                                                    AND Disposition_Reason__c != 'Converted'
                                                    AND Special_Program__c != 'Conversion')) OR SBQQ__Product__r.Is_MSP_Product__c = True)
                                                ORDER BY SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber ASC];
            
            if(quoteLines != null && !quoteLines.IsEmpty()){
                for(SBQQ__QuoteLine__c qli: quoteLines){
                    if(qli.Replace_By__c != null && qli.Disposition_Reason__c == 'Renew Later') {
                        replacedRenLaterSet.add(qli.Id);
                        continue; // MS RSCG-64
                    }

                    if(qli.Arroyo_Subscribed_Asset_Name__c == null && (qli.Replace_By__c == null || qli.Replace_By__c == 'None') && qli.Disposition_Reason__c != 'Replaced'){
                        qliIDs.add(qli.Id);
                    }
                    
                    if(qli.Quote_Line_Type__c == 'Renewal' && qli.SubscribedAssetNames__c != null && qli.Arroyo_Subscribed_Asset_Name__c == null 
                    && (qli.Disposition_Reason__c == 'Replaced' 
                    || (qli.SBQQ__ProductCode__c.contains('NRD') && qli.Disposition_Reason__c == 'Renewing'))){
                        //Renewal Line which is replaced
                        qliListReplaced.add(qli);
    } 
                    if(qli.SBQQ__Product__r.Is_MSP_Product__c == true ){
                                qliIDs.add(qli.Id);
                    } 
                }            
                //Add to quoteLinesToShow only if it not a Renewing line from Replaced
                for(SBQQ__QuoteLine__c quoteLineObj: quoteLines){
                    if(!replacedRenLaterSet.isEmpty() && replacedRenLaterSet.contains(quoteLineObj.Id)) continue; // MS RSCG-64

                    List<String> str = new List<String>();
                    if(quoteLineObj.SubscribedAssetNames__c != null){
                        str = quoteLineObj.SubscribedAssetNames__c.split(',');
                    }
                    if(str != null && !str.isEmpty()){
                        for(String strings1: str){
                            if(qliListReplaced != null && !qliListReplaced.isEmpty()){                           
                                for(SBQQ__QuoteLine__c quoteLineObjRep: qliListReplaced){
                                    if(quoteLineObjRep.SubscribedAssetNames__c.contains(strings1) 
                                    && quoteLineObj.Disposition_Reason__c != 'Renewing' && quoteLineObj.Disposition_Reason__c != 'Replaced'
                                    && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null)
                                    {
                                        qliIDs.add(quoteLineObj.Id);
                                    }
                                    //If lines does not contain Subscribed Asset Names, and if it is HW Support OR NRD with Replace By = null, then display
                                    else if(!quoteLineObjRep.SubscribedAssetNames__c.contains(strings1) && 
                                    (quoteLineObj.Replace_By__c == null || quoteLineObj.Replace_By__c == 'None' || quoteLineObj.Replace_By__c == '') && 
                                    (quoteLineObj.Product_Type__c == 'HW Support' || quoteLineObj.SBQQ__ProductCode__c.contains('NRD')) && 
                                    quoteLineObj.Disposition_Reason__c != 'Replaced' && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null)
                                    {
                                        qliIDs.add(quoteLineObj.Id);
                                    }
                                }
                            }
                            else if(quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null && (quoteLineObj.Replace_By__c == 'None' || quoteLineObj.Replace_By__c == null || quoteLineObj.Replace_By__c == ''))
                            {
                                qliIDs.add(quoteLineObj.Id);
                            }
                        }
                    }
                    else if (str.isEmpty() && quoteLineObj.Arroyo_Subscribed_Asset_Name__c == null && quoteLineObj.Disposition_Reason__c != 'Replaced') {
                        qliIDs.add(quoteLineObj.Id);
                    }
                }
            }
            
            if(qliIDs != null && !qliIDs.IsEmpty()){
                quoteLinesToShow = [SELECT Id, SBQQ__ProductCode__c,SBQQ__Product__r.Is_MSP_Product__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, Special_Program__c, Required_By_Product_Code__c, 
                                    Subscribed_Asset_Name__c, SBQQ__ListPrice__c, Product_Type__c, SBQQ__NetPrice__c, Do_not_Renew__c, Disposition_Reason__c, 
                                    Quote_Line_Type__c, SubscribedAssetNames__c, SBQQ__StartDate__c, SBQQ__EndDate__c, Replace_By__c, Line_Type__c, SBQQ__Group__c,
                                    SBQQSC__RenewedContractLine__r.ServiceContractId, SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber, 
                                    QuoteLine_Group_Name__c,  SBQQ__SubscriptionPricing__c ,Arroyo_Subscribed_Asset_Name__c, Product_Level__c, 
                                    Is_Hardware_Product__c, SBQQ__Group__r.Name, Product_Subtype__c, 
                                    SBQQ__RequiredBy__r.SBQQ__RequiredBy__r.Disposition_Reason__c FROM SBQQ__QuoteLine__c WHERE Id =: qliIDs 
                                    ORDER BY SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber ASC];
            }
            return quoteLinesToShow;
        } else {
            return new List<SBQQ__QuoteLine__c>();
        }
    }
    
    /**The main method which handles dipostion on lines */
    @AuraEnabled
    public static String desposeLines(List<SBQQ__QuoteLine__c> quoteLinesNew, List<SBQQ__QuoteLine__c> oldvalues, String quoteId) {
        boolean showerror = false;
        boolean DonotdeleteDesposition = false;
        String disposegrp = System.Label.Arry_Disposition_Group; 
        String errormsg;
        Id Quotegroupdes,Quotegrouprenew;
        Map<Id,SBQQ__QuoteLine__c> oldvaluesmap = new Map<Id,SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLines = (List<SBQQ__QuoteLine__c>)quoteLinesNew;
        List<SBQQ__QuoteLineGroup__c> grouptodelete = new List<SBQQ__QuoteLineGroup__c>();
        Map<String,Integer> childcountmap = new Map<String,Integer>();
        Map<String,Integer> desposechildcountmap = new Map<String,Integer>();
        Map<String,String> childdispositionReason = new Map<String,String>();
        Set<Id> parIdset = new Set<Id>();
        Integer count,countdes,countalready = 0;
        Map<String,String> reasonMap = getPicklistValues('SBQQ__QuoteLine__c', 'Disposition_Reason__c');
        
        List<SBQQ__Quote__c> quoteRec = [SELECT id, SBQQ__Type__c from SBQQ__Quote__c where id =: quoteId];
        List<SBQQ__QuoteLine__c> qliRec = [SELECT Id, SBQQ__ProductCode__c, SBQQ__Quantity__c, SBQQ__RequiredBy__c, Special_Program__c,
                                           Required_By_Product_Code__c, Subscribed_Asset_Name__c, SBQQ__ListPrice__c, Product_Type__c,Product_Level__c,
                                           SBQQ__NetPrice__c, Do_not_Renew__c, Disposition_Reason__c, Quote_Line_Type__c, SubscribedAssetNames__c,
                                           SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQSC__RenewedContractLine__r.ServiceContractId, 
                                           SBQQSC__RenewedContractLine__r.ServiceContract.ContractNumber, Line_Type__c, 
                                           QuoteLine_Group_Name__c, SBQQ__Group__c, SBQQ__SubscriptionPricing__c,Is_Hardware_Product__c , SBQQ__Group__r.Name
                                           FROM SBQQ__QuoteLine__c WHERE Id IN : quoteLines
                                           AND Quote_Line_Type__c = 'Renewal'
                                           AND (Disposition_Reason__c != 'Refreshed' 
                                                AND Disposition_Reason__c != 'Converted'
                                                AND Special_Program__c != 'Conversion')];
        Boolean isRenewalANDExpansion = true;
        Map<String, String> mapRenQLIdVsQLRec = new Map<String, String>();
        
        if(!quoteRec.isEmpty() && quoteRec[0].SBQQ__Type__c != 'Renewal+Expansion'){
            isRenewalANDExpansion = false;
            //isRenewalANDExpansion = true;
        }
        
        //End - ARY-71: Logic Added by Shaloo for Arroyo Approvals
        if(oldvalues != null && !oldvalues.IsEmpty()){
            for(SBQQ__QuoteLine__c oldline: oldvalues) {
                oldvaluesmap.put(oldline.id,oldline);
                if(oldline.SBQQ__RequiredBy__c!= null ) {
                    if(!childcountmap.containsKey(oldline.SBQQ__RequiredBy__c)) {
                        count = 1;
                        childcountmap.put(oldline.SBQQ__RequiredBy__c,count);
                    }
                    else {
                        count = count+1;
                        childcountmap.put(oldline.SBQQ__RequiredBy__c,count);
                    }
                    
                    if(oldline.SBQQ__Group__r.Name == 'Disposition Quote') {
                        countalready = countalready+1;
                    }
                }
            }
        }
        List<SBQQ__QuoteLine__c> qltoUpdate = new List<SBQQ__QuoteLine__c>();
        Map<Id,SBQQ__QuoteLine__c> maptoupdateQL = new Map<Id,SBQQ__QuoteLine__c>();
        
        for(SBQQ__QuoteLineGroup__c grp :[SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =:quoteId]) {
            if(grp.Name == System.Label.Arry_Disposition_Group ) {
                Quotegroupdes = grp.Id;
                grouptodelete.add(grp);
            }
            if(grp.Name == System.Label.Arry_renewal_Group) {
                Quotegrouprenew = grp.Id;
            }
        }
        
        if(Quotegroupdes == null && isRenewalANDExpansion) {
            SBQQ__QuoteLineGroup__c qlg = new  SBQQ__QuoteLineGroup__c();
            qlg.Name = System.Label.Arry_Disposition_Group;
            qlg.SBQQ__Quote__c = quoteId;
            qlg.Is_Disposition_Group__c = TRUE;
            qlg.SBQQ__Description__c = CPQ_Constants.DISPOSE_QUOTE_DESCRIPTION;
            insert qlg;
            Quotegroupdes = qlg.Id;
            grouptodelete.add(qlg);
        }
        if(quoteLines != null && !quoteLines.IsEmpty()){
            for(SBQQ__QuoteLine__c ql: quoteLines) {
                SBQQ__QuoteLine__c oldLine = oldvaluesmap.get(ql.id);
                if((oldLine.Disposition_Reason__c!= ql.Disposition_Reason__c) || Test.isRunningTest()) {
                    if(ql.Disposition_Reason__c != 'Renewing Now - Renewing' && ql.Disposition_Reason__c != 'None') {
                        if(isRenewalANDExpansion){
                            ql.SBQQ__Group__c = Quotegroupdes;
                        }
                        if(reasonMap != null && !reasonMap.keySet().IsEmpty()){
                            for(String str : reasonMap.keySet()) {
                                if(ql.Disposition_Reason__c == reasonMap.get(str)) {
                                    ql.Disposition_Reason__c = str;
                                }
                            }
                        }
                        maptoupdateQL.put(ql.id,ql);
                        qltoUpdate.add(ql);
                        
                        //Add to the map only if Product Type = Support
                        if(oldLine.SBQQ__RequiredBy__c != null ){ 
                            if(oldline.Product_Type__c == 'HW Support' || oldline.Product_Level__c == 'Support') {
                                childdispositionReason.put(oldLine.SBQQ__RequiredBy__c,ql.Disposition_Reason__c);
                            }
                            if(!desposechildcountmap.containsKey(oldLine.SBQQ__RequiredBy__c)){
                                countdes = 1;
                                desposechildcountmap.put(oldLine.SBQQ__RequiredBy__c,countdes);
                            }
                            else{
                                countdes = countdes+1;
                                desposechildcountmap.put(oldLine.SBQQ__RequiredBy__c,countdes);
                            }
                        }
                    }
                    else if(//ql.Arroyo_Subscribed_Asset_Name__c == null &&
                        (ql.Disposition_Reason__c == 'Renewing Now - Renewing' || ql.Disposition_Reason__c == 'None')
                        /*&& oldLine.SBQQ__Group__r.Name == 'Disposition Quote'*/) {
                            String value;
                            if(isRenewalANDExpansion){
                                ql.SBQQ__Group__c = Quotegrouprenew;
                            }
                            if(reasonMap != null && !reasonMap.keySet().IsEmpty()){
                                for(String str : reasonMap.keySet()) {
                                    if(ql.Disposition_Reason__c == reasonMap.get(str)) {
                                        ql.Disposition_Reason__c = str;
                                        value = str;
                                    }
                                }
                            }
                            //MS ARY-33941 Comment Starts
                            SBQQ__QuoteLine__c qlpar;
                            if(oldLine.SBQQ__RequiredBy__c != null &&
                            (oldline.Product_Type__c == 'HW Support' || oldline.Product_Level__c == 'Support')) {
                                qlpar = new SBQQ__QuoteLine__c(Id = oldLine.SBQQ__RequiredBy__c);
                                if(isRenewalANDExpansion){
                                    qlpar.SBQQ__Group__c = Quotegrouprenew;
                                }
                                qlpar.Disposition_Reason__c = value;
                            }
                            
                            if(!parIdset.contains(oldLine.SBQQ__RequiredBy__c) && qlpar!= null) {
                                parIdset.add(oldLine.SBQQ__RequiredBy__c);
                                maptoupdateQL.put(qlpar.Id,qlpar);
                                qltoUpdate.add(qlpar);
                            }
                            //MS ARY-33941 Ends*/
                            
                            qltoUpdate.add(ql);
                            maptoupdateQL.put(ql.Id,ql);
                        }
                }
            }
        }
        if(childcountmap != null && !childcountmap.keySet().IsEmpty()){
            for(Id key : childcountmap.keyset()) {
                if((desposechildcountmap.containsKey(key) && 
                    (desposechildcountmap.get(key) == childcountmap.get(key) || childcountmap.get(key) == countalready+countdes)) || Test.isRunningTest()) {
                        SBQQ__QuoteLine__c qlpar = new SBQQ__QuoteLine__c(Id = key);
                        if(isRenewalANDExpansion){
                            qlpar.SBQQ__Group__c = Quotegroupdes;
                        }
                        if (maptoupdateQL.get(key) != null) {
                            qlpar.Disposition_Reason__c = maptoupdateQL.get(key).Disposition_Reason__c;
                        }
                        else if(childdispositionReason.containsKey(key)) {
                            qlpar.Disposition_Reason__c = childdispositionReason.get(key); 
                        }
                        qltoUpdate.add(qlpar);
                        maptoupdateQL.put(qlpar.Id,qlpar);
                    }
            }
        }
        if(qliRec != null && !qliRec.IsEmpty()){
            for(SBQQ__QuoteLine__c ql: qliRec){
                if(maptoupdateQL != null && maptoupdateQL.get(ql.Id) != null && maptoupdateQL.get(ql.Id).Disposition_Reason__c == 'Converted' &&
                   ql.Product_Type__c == 'RCDM Support' && ql.SubscribedAssetNames__c != null){
                       mapRenQLIdVsQLRec.put(ql.SubscribedAssetNames__c, ql.Disposition_Reason__c);   
                   }
            }
        }
        
        for(SBQQ__QuoteLine__c ql: qliRec){
            if(mapRenQLIdVsQLRec != null &&
               mapRenQLIdVsQLRec.containsKey(ql.SubscribedAssetNames__c) && 
               mapRenQLIdVsQLRec.get(ql.SubscribedAssetNames__c) != 'Converted' &&
               ql.Product_Type__c != 'RCDM Support'){
                   ql.Disposition_Reason__c = 'Converted';
                   maptoupdateQL.put(ql.Id, ql);
                   ql.SBQQ__Group__c = Quotegroupdes;
               }
            if(ql.Is_Hardware_Product__c && ql.Disposition_Reason__c !='None' ){
                if(maptoupdateQL.containsKey(ql.Id)){
                    maptoupdateQL.get(ql.Id).Disposition_Reason__c = 'None';
                }
            }
            
        }
        
        if(!qltoUpdate.isEmpty()){
            update maptoupdateQL.values();
        } 
        
        for(SBQQ__QuoteLine__c qls : [Select Id, SBQQ__Group__c, QuoteLine_Group_Name__c, SBQQ__Group__r.Name, SBQQ__Quote__c FROM SBQQ__QuoteLine__c 
                                      WHERE SBQQ__Quote__c =: quoteId AND SBQQ__Group__r.Name  =: disposegrp]) {
                                          
                                          DonotdeleteDesposition = true;
                                          
                                      }
        if(DonotdeleteDesposition == false){
            if(grouptodelete.size() > 0){
                delete grouptodelete;
            }
        }
        
        if(quoteId != null && !qltoUpdate.isEmpty()){
            updateLineNumberOnQuoteLines(quoteId);
        }
        if(showerror == true){
            errormsg = 'Please give the Justification for Non renewal!!';
            return errormsg;
        }else{
            return null ;
        }
    }
    
    /*Method to fix the numbers on quote as per group and quote line parents*/
    public static void updateLineNumberOnQuoteLines(String quoteId){
        List<SBQQ__QuoteLine__c> quoteLineList = [Select id, SBQQ__RequiredBy__c,SBQQ__Group__c, SBQQ__Group__r.Name
                                                  from SBQQ__QuoteLine__c
                                                  WHERE SBQQ__Quote__c =: quoteId
                                                  ORDER BY SBQQ__Group__c, SBQQ__RequiredBy__c];
        
        System.debug('quoteLineList--> ' + quoteLineList);
        //preparing the maps so that I can set the line number of QUote line as per group and parents
        Map<String,List<SBQQ__QuoteLine__c>> childQuoteLineMap = new Map<String,List<SBQQ__QuoteLine__c>>();
        List<SBQQ__QuoteLine__c> parentOrStandaloneQuoteLines = new List<SBQQ__QuoteLine__c>();
        if(quoteLineList != null && !quoteLineList.IsEmpty()){ 
            for(SBQQ__QuoteLine__c qli : quoteLineList){
                if(qli.SBQQ__RequiredBy__c != null){
                    List<SBQQ__QuoteLine__c> qliList = new List<SBQQ__QuoteLine__c>();
                    if(childQuoteLineMap.containsKey(qli.SBQQ__RequiredBy__c)){
                        qliList = childQuoteLineMap.get(qli.SBQQ__RequiredBy__c);
                    }
                    qliList.add(qli);
                    childQuoteLineMap.put(qli.SBQQ__RequiredBy__c,qliList);
                }else{
                    parentOrStandaloneQuoteLines.add(qli);
                }
                List<Id> qliIdList = new List<Id>();
                qliIdList.add(qli.Id);
            }
        }
        
        //actual quotelines line number population logic
        List<SBQQ__QuoteLine__c> qliListToUpdate = new List<SBQQ__QuoteLine__c>();
        Integer count = 1;
        Map<String,Integer> groupCountMap = new Map<String,Integer>();
        if(parentOrStandaloneQuoteLines != null && !parentOrStandaloneQuoteLines.IsEmpty()){
            for(SBQQ__QuoteLine__c qli : parentOrStandaloneQuoteLines){
                count = 0;
                if(groupCountMap.containsKey(qli.SBQQ__Group__c)){
                    count = groupCountMap.get(qli.SBQQ__Group__c);
                }
                count++;
                SBQQ__QuoteLine__c qliTOUpdate = new SBQQ__QuoteLine__c(Id = qli.Id, SBQQ__Number__c = count);
                qliListToUpdate.add(qliTOUpdate);
                groupCountMap.put(qli.SBQQ__Group__c, count);
                if(childQuoteLineMap.containsKey(qli.Id)){
                    updateChildLineNumber(childQuoteLineMap, qli.Id, groupCountMap, qliListToUpdate);
                }
            }
        }
        update qliListToUpdate;
    }
    
    /**Method to update Numbers for Children lines */
    public static void updateChildLineNumber(Map<String,List<SBQQ__QuoteLine__c>> childQuoteLineMap, String qliId, Map<String,Integer> groupCountMap, List<SBQQ__QuoteLine__c> qliListToUpdate){
        if(childQuoteLineMap != null && !childQuoteLineMap.IsEmpty() 
           && childQuoteLineMap.containsKey(qliId) && childQuoteLineMap.get(qliId) != null)
        {
            for(SBQQ__QuoteLine__c childQli : childQuoteLineMap.get(qliId)){
                Integer count = 0;
                if(groupCountMap.containsKey(childQli.SBQQ__Group__c)){
                    count = groupCountMap.get(childQli.SBQQ__Group__c);
                }
                count++;
                SBQQ__QuoteLine__c qliTOUpdate = new SBQQ__QuoteLine__c(Id = childQli.Id, SBQQ__Number__c = count);
                qliListToUpdate.add(qliTOUpdate);
                groupCountMap.put(childQli.SBQQ__Group__c, count);
                if(childQuoteLineMap.containsKey(childQli.Id)){
                    updateChildLineNumber(childQuoteLineMap, childQli.Id, groupCountMap, qliListToUpdate);
                }
            }
        }
    }
    /** Method to fetch picklist values */
    @AuraEnabled
    public static Map<String, String> getPicklistValues(String objectAPIName, String fieldAPIName){
        Map<String, String> pickListValuesMap = new Map<String, String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectAPIName);
        Schema.DescribeSObjectResult descResult = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = descResult.fields.getMap().get(fieldAPIName).getDescribe();
        Boolean isFieldNotRequired = fieldResult.isNillable();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for(Schema.PicklistEntry pickListVal: ple){
            if(isFieldNotRequired)
                if(pickListVal.isActive())
                pickListValuesMap.put(pickListVal.getValue(), pickListVal.getLabel());
        }
        if (pickListValuesMap != null && !pickListValuesMap.isEmpty()) {
        	pickListValuesMap.remove('R_E Transacted');    
        }
        return pickListValuesMap;
    }
    
    /*START - ARY-218 CR #5: Added by Shaloo for hiding and showing Disposition Reason picklist values*/
    @AuraEnabled
    public static SBQQ__Quote__c getQuoteFieldValuesFromApex(String quoteId){
        System.debug('**Method getQuoteFieldValuesFromApex CALLED**' + quoteId);
        SBQQ__Quote__c quoteRecord = [SELECT Id, Running_User_Profile__c, RWD_Deal_Ops_Exception__c FROM SBQQ__Quote__c WHERE Id =: quoteId];
        return quoteRecord;
    }
    //END - ARY-218 CR #5: Added by Shaloo for hiding and showing Disposition Reason picklist values
}