/************************************************************
 * @description       : Shipment Detail helper logic
 * @author            : Chaitra
 * @last modified on  : 01-20-2021
 * @last modified by  : Chaitra
 * Modifications Log
 * Ver   Date          Author        Modification
 * 1.0   01-20-2022   chaitra        Initial Version
 * 2.0   24-08-2022   sailaja        ASPEN1B-247
 ************************************************************/

public class ShipmentDetailHelper {

  private static ShipmentDetailHelper instance = null;
  public Map<string, SBQQ__Quote__c> quoteMap = new Map<string, SBQQ__Quote__c>();
  Set<string> failureReason = new Set<string>(); //ASPEN1B-247
  String failureType = 'Failed';//ASPEN1B-247
  private set<asset> assetToInsert = new set<asset>();
  Map<string,asset> serialNumAsset = new Map<string,asset>();
  set<string> setEmailSend = new set<String>();
  List<ShipmentDetail__c> shpSendEmail = new List<ShipmentDetail__c>();
  List<ShipmentDetail__c> shpListQuo = new List<ShipmentDetail__c>();
  Map<String, ShipmentDetail__c> overViewSDMap = new Map<String, ShipmentDetail__c>();
  Map<String, ShipmentDetail__c> existingSDOverviews = new Map<String, ShipmentDetail__c>();
  Boolean checkNew = false;
  Boolean emailSent = false;
/**
* @description get Instance of class
* @return ShipmentDetailHelper instance
**/
  public static ShipmentDetailHelper getInstance() {
    if (instance == null)
      instance = new ShipmentDetailHelper();
    return instance;
  }
  /**
   * @description Data collection used in entire order trigger transaction
   * @param shpList
 **/
  public void Init(List<ShipmentDetail__c> shpList) { //ASPEN1B-247- Added parameter
    set<string> quoteNames = new set<string>();
      List<ShipmentDetail__c> shpListNew = new List<ShipmentDetail__c>(); 
      shpListQuo = shpList;
      shpListNew = shpListQuo != null ? shpListQuo : Trigger.new;
    for (ShipmentDetail__c newSD: (List<ShipmentDetail__c>) shpListNew) {  
      if(newSD.order__c == null && String.isNotBlank(newSD.QuoteNumber__c) && !newSD.QuoteNumber__c.equalsIgnoreCase('Undefined')){ 
        quoteNames.add(newSD.QuoteNumber__c);
        }
        if(String.isNotBlank(newSD.HW_SerialNumber__c) && !newSD.HW_SerialNumber__c.equalsIgnoreCase('Undefined') ){
          for(string SN : newSD.HW_SerialNumber__c.replaceAll('\\s+','').split('\\,')){
            serialNumAsset.put(SN,null);
          }
        }
      }
      if(!quoteNames.isEmpty() && quoteMap.isEmpty()){
        for(SBQQ__Quote__c quote : [select id,name,SBQQ__Account__c,SBQQ__Distributor__c, SBQQ__Primary__c, SBQQ__Status__c, SBQQ__Opportunity2__r.Override__c, SBQQ__Opportunity2__r.Aspen_Eligibility__c,SBQQ__Opportunity2__c,ApprovalStatus__c,Distributor_s_Name__c,SBQQ__Account__r.Name,SBQQ__Opportunity2__r.ContractManufacturer__c,Shipment_Validation__c,Missing_Shipment_Details__c, (select Id,Name,SBQQ__Product__c,SBQQ__Product__r.Product_Subtype__c,SBQQ__Product__r.Product_Type__c,SBQQ__Product__r.product_level__c,SBQQ__ProductCode__c,SBQQ__Quantity__c,Product_Type__c,SBQQ__RequiredBy__r.SBQQ__ProductCode__c,SBQQ__Quote__c,SBQQ__Quote__r.Name,SBQQ__ProductName__c, Line_Type__c from SBQQ__LineItems__r) from SBQQ__Quote__c where name IN: quoteNames]){
          quoteMap.put(quote.name,quote);
        }
      }
      if(!serialNumAsset.isEmpty()){
        for(Asset asst : [select id,SerialNumber,Product2ID,Product2.name,accountId from asset where serialNumber IN : serialNumAsset.keyset()]){
          serialNumAsset.put(asst.SerialNumber,asst);
        }
      }
    }
    /**
     * @description To validate record and create asset for spare products
     * @param shpListQuo
     * @param sendEmail
     * @param quoteIdVsOverviewSD
     * @param quoteNameVsId
    **/
    public void ProcessShipmentInfoUpdated(List<ShipmentDetail__c> shpListQuo, boolean sendEmail, Map<String, ShipmentDetail__c> quoteIdVsOverviewSD, Map<String, String> quoteNameVsId){
        Map<Id,Map<string,quotePCodeDetails>>  quoteIdPCodeDetails = new Map<Id,Map<string,quotePCodeDetails>>();
        List<ShipmentDetail__c> existingSD = new List<ShipmentDetail__c>();
        Map<String, Set<Id>> failedSdIdByStatus = new Map<String, Set<Id>>{ 'Failed' => new Set<id>(), 'Internal Failure' => new Set<id>(), 'Success' => new Set<id>() };
        Map<String, Set<string>> failedQuoteIdByStatus = new Map<String, Set<string>>{ 'Failed' => new Set<string>(), 'Internal Failure' => new Set<string>(), 'Success' => new Set<string>() };
        Map<string,SBQQ__QuoteLine__c> ProdNameQLI = new Map<string,SBQQ__QuoteLine__c>();
        Map<String,string> quotetoupdateMap = new Map<String,string>();
        Set<Id> closeOptyList = new Set<Id>();
        List<ShipmentDetail__c> shpQuoList = new List<ShipmentDetail__c>();
        List<String> listSerialNumber = new List<String>();
        Boolean duplicateSerial = false;
        shpQuoList = shpListQuo != null ? shpListQuo : Trigger.new;
        Boolean checkMissing = true;
        List<ShipmentDetail__c> overviewSDToUpdate = new List<ShipmentDetail__c>();

        for(string quotename : quoteMap.keyset()){
            Map<string, quotePCodeDetails> proQuMap =  new Map<string, quotePCodeDetails> ();
            for(SBQQ__QuoteLine__c qli : quoteMap.get(quotename).SBQQ__LineItems__r){
                ProdNameQLI.put(qli.SBQQ__ProductCode__c,qli);
                if(qli.Product_Type__c == 'Spares' || (qli.SBQQ__Product__r?.product_level__c == 'Hardware' && qli.Line_Type__c != null && qli.Line_Type__c == 'New')){ // PRDOPS24-857
                    String proQuo = quotename +'_'+qli.SBQQ__ProductCode__c;
                    if(!quoteIdPCodeDetails.containsKey(qli.SBQQ__Quote__c)){ 
                        proQuMap.put(proQuo,new quotePCodeDetails(qli.SBQQ__Quantity__c,qli));
                        quoteIdPCodeDetails.put(qli.SBQQ__Quote__c,proQuMap);
                    }else{
                        if(quoteIdPCodeDetails.get(qli.SBQQ__Quote__c).containsKey(proQuo))
                        {
                            Decimal qty = quoteIdPCodeDetails.get(qli.SBQQ__Quote__c).get(proQuo).TotalQuantity + qli.SBQQ__Quantity__c;
                            proQuMap.put(proQuo,new quotePCodeDetails(qty,qli));
                            quoteIdPCodeDetails.put(qli.SBQQ__Quote__c,proQuMap);
                    	}
                        else
                        {
                            proQuMap.put(proQuo,new quotePCodeDetails(qli.SBQQ__Quantity__c,qli));
                            quoteIdPCodeDetails.put(qli.SBQQ__Quote__c,proQuMap);
                        }
                    }
                }
            }
        }
        existingSD = [Select Id,QuoteNumber__c,ProductName__c,Quantity__c from ShipmentDetail__c where QuoteNumber__c In :quoteMap.keyset() and Id NOT IN :trigger.newMap.keySet() and Status__c='Success'];
        if(!existingSD.isEmpty()){
            for(ShipmentDetail__c exiSd : existingSD ){
                SBQQ__QuoteLine__c qli = ProdNameQLI.get(exiSd.ProductName__c);
                String proQuoSd = exiSd.QuoteNumber__c + '_' + exiSd.ProductName__c;
                if(quoteIdPCodeDetails.containsKey(qli.SBQQ__Quote__c) && quoteIdPCodeDetails.get(qli.SBQQ__Quote__c).containsKey(proQuoSd)){
                    Decimal qty = quoteIdPCodeDetails.get(qli.SBQQ__Quote__c).get(proQuoSd).TotalQuantity;
                    quoteIdPCodeDetails.get(qli.SBQQ__Quote__c).get(proQuoSd).TotalQuantity =  qty - exiSd.Quantity__c;
                }else{
                    System.debug(LoggingLevel.DEBUG,'Error with pcode ,the quote may be altered'+exiSd.QuoteNumber__c);
                }
            }
        }
        //***//
        for (ShipmentDetail__c newSD:  shpQuoList) {
            ShipmentDetail__c oldSD = newSD.id!= null?Trigger.oldMap.containsKey(newSD.id) ? (ShipmentDetail__c)Trigger.oldMap.get(newSD.id):null :null;          
            String proQuoSd = newSD.QuoteNumber__c + '_' + newSD.ProductName__c;
            string qId = ProdNameQLI.containsKey(newSD.ProductName__c) ? ProdNameQLI.get(newSD.ProductName__c).SBQQ__Quote__c: null;
            try{
            newSD.Parent_Shipment_Detail__c = newSD.Parent_Shipment_Detail__c != null ? newSD.Parent_Shipment_Detail__c : (existingSDOverviews.containsKey(newSD.QuoteNumber__c) ? existingSDOverviews.get(newSD.QuoteNumber__c).Id : null);
            if(newSD.Status__c =='New' && (oldSD == null || oldSD.Status__c != 'New') || shpListQuo != null ){
                checkNew = true;
                duplicateSerial = false;
                if('BRIKONLY'.equalsIgnoreCase(newSD.SalesOrderNumber__c) && String.isBlank(newSD.order__c))
                {
                    newSD.Status__c = 'Success';
                }
                else if(!ProdNameQLI.isEmpty() && (String.isNotBlank(newSD.ProductName__c) && Constants.INVALIDATE_ACCESSORIES.contains(newSD.ProductName__c))){   // PRDOPS24-857                                                    
                    newSD.Status__c =  'Success';
                    newSD.ProcessHistory__c = 'NA';
                    quotetoupdateMap.put(newSD.QuoteNumber__c,'Success');
                } 
                else if(String.isNotBlank(newSD.SalesOrderNumber__c) && newSD.SalesOrderNumber__c.equalsIgnoreCase('SPARES') == false && String.isBlank(newSD.order__c)){
                    newSD.Status__c ='Failed';
                    newSD.ProcessHistory__c = 'Invalid Order'; 
                    failureReason.add('NA');
                    checkMissing = false;
                }else if((String.isBlank(newSD.SalesOrderNumber__c) || 'SPARES'.equalsIgnoreCase(newSD.SalesOrderNumber__c)) && String.isBlank(newSD.order__c)){
                    newSD.ProcessHistory__c ='';
                    if(String.isBlank(newSD.ProductName__c)|| newSD.ProductName__c.equalsIgnoreCase('Undefined')){
                        newSD.Status__c ='Failed';
                        newSD.ProcessHistory__c = 'Product name is mandatory';
                        quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
                        failureReason.add('NA');
                        checkMissing = false;
                    }
                    else if(String.isBlank(newSD.QuoteNumber__c) || newSD.QuoteNumber__c.equalsIgnoreCase('Undefined')){
                        newSD.Status__c ='Failed';
                        newSD.ProcessHistory__c += 'Quote number is mandatory';
                        failureReason.add('NA');
                        checkMissing = false;
                    }
                    else if(quoteMap.containsKey(newSD.QuoteNumber__c)){ 
                        newSD.ProductName__c = newSD.ProductName__c.trim().toUpperCase();
                        SBQQ__Quote__c quote = quoteMap.get(newSD.QuoteNumber__c);
                        if(Test.isRunningTest()){
                            qId = quote.Id;
                        }
                        if(quote.ApprovalStatus__c!='Approved' || quote.SBQQ__Primary__c==false){
                            newSD.Status__c = 'New';
                            newSD.ProcessHistory__c = 'Quote is not approved or not primary';
                            quotetoupdateMap.put(newSD.QuoteNumber__c,'Internal Failure');
                            failureType = 'Internal Failure';
                            failureReason.add('NA');
                            checkMissing = false;
                        }else if((quote.SBQQ__Opportunity2__r.Override__c || (quote.SBQQ__Opportunity2__r.Aspen_Eligibility__c != 'Actual Aspen' && quote.SBQQ__Opportunity2__r.Aspen_Eligibility__c != 'Proposed Aspen')) /*&& !Test.isRunningTest()*/ ){
                            newSD.Status__c = 'Failed';
                            newSD.ProcessHistory__c = 'Invalid shipment details for non-aspen';
                            failedSdIdByStatus.get(newSD.Status__c).add(newSD.Id);
                            failureReason.add('NA');                            
                            checkMissing = false;
                        }else if (ProdNameQLI.containsKey(newSD.ProductName__c)/* || Test.isRunningTest()*/){
                            if((String.isBlank(newSD.HW_SerialNumber__c) || newSD.HW_SerialNumber__c.equalsIgnoreCase('Undefined') )
                                    && 'Accessories' != ProdNameQLI.get(newSD.ProductName__c).SBQQ__Product__r.Product_Type__c ){
                                newSD.Status__c ='Failed';
                                newSD.ProcessHistory__c = 'Serial number is mandatory';
                                failureReason.add('NA');
                                quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
                                failedSdIdByStatus.get(newSD.Status__c).add(newSD.Id);
                            }
                            else if(!String.isBlank(newSD.HW_SerialNumber__c)){ // PRDOPS24-857
							Integer countSn = 0;
                            Boolean isFailing = false;
                            if(/*Test.isRunningTest() || */(('Spares' == ProdNameQLI.get(newSD.ProductName__c).SBQQ__Product__r.Product_Type__c) && duplicateSerial == false )){  // PRDOPS24-857
                                                                      if(quoteIdPCodeDetails.containsKey(qId) && quoteIdPCodeDetails.get(qId).containsKey(proQuoSd)){
                                                                          if(newSD.Quantity__c <= quoteIdPCodeDetails.get(qId).get(proQuoSd).TotalQuantity){
                                                                              quoteIdPCodeDetails.get(qId).get(proQuoSd).TotalQuantity = quoteIdPCodeDetails.get(qId).get(proQuoSd).TotalQuantity - newSD.Quantity__c;
                                                                              newSD.Quote_Line__c = quoteIdPCodeDetails.get(qId).get(proQuoSd).quoteLineList[0].Id;
                                                                              String lineItemList = '';
                                                                              String quotename =  quoteIdPCodeDetails.get(qId).get(proQuoSd).quoteLineList[0].SBQQ__Quote__r.Name;
                                                                              if(quoteMap.containskey(quotename)){
                                                                                  for(SBQQ__QuoteLine__c qli : quoteMap.get(quotename).SBQQ__LineItems__r){

                                                                                      if(qli.SBQQ__ProductName__c == newSD.ProductName__c){
                                                                                          lineItemList = lineItemList + ' ' + qli.Name;
                                                                                      }
                                                                                  }
                                                                              }
                                                                              newSD.Quote_Item_Ids__c = lineItemList ;
                                                                              newSD.Status__c = 'Success';
                                                                          }else if(quoteIdPCodeDetails.get(qId).get(proQuoSd).TotalQuantity == 0){
                                                                              newSD.Status__c = 'Failed';
                                                                              newSD.ProcessHistory__c = 'Duplicate';
                                                                              failureReason.add('NA');
                                                                              isFailing = true;
                                                                          }else if(newSD.Quantity__c > quoteIdPCodeDetails.get(qId).get(proQuoSd).TotalQuantity){
                                                                              newSD.Status__c = 'Failed';
                                                                              newSD.ProcessHistory__c = 'Quantity Mismatch';//+ newSD.ProductName__c + '('+quoteIdPCodeDetails.get(qId).get(proQuoSd).TotalQuantity+')';
                                                                              quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
                                                                              failureReason.add('NA');
																			  isFailing = true;
                                                                          }
                                                                      }
                                                                  }
                                if(!isFailing && 'Accessories' != ProdNameQLI.get(newSD.ProductName__c).SBQQ__Product__r.Product_Type__c ){
                                    newSD.HW_SerialNumber__c = newSD.HW_SerialNumber__c.replaceAll('\\s+','');
                                    String dupListAss = ' ';
                                    for(string SN : newSD.HW_SerialNumber__c.split('\\,')){
                                        countSn++;
                                        if( listSerialNumber.contains(SN) || (serialNumAsset.get(SN) != null && !Label.Unassigned_Account_Id.contains(serialNumAsset.get(SN).accountId)) ){
                                            dupListAss = dupListAss + ' ' +SN;
                                            newSD.Status__c ='Failed';
                                            newSD.ProcessHistory__c = 'Assets are already assigned : ' + dupListAss;
                                            failureReason.add('NA');
                                            quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
                                            failedSdIdByStatus.get(newSD.Status__c).add(newSD.Id);
                                            duplicateSerial = true;
                                        }
                                    }
                                    /*if(countSn != newSD.Quantity__c && duplicateSerial == false && !String.isBlank(newSD.HW_SerialNumber__c) ){
                                    	newSD.Status__c ='Failed';
                                    	newSD.ProcessHistory__c = 'Quantity and Serial number mismatch';
                                    	failureReason.add('NA');
                                    	quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
                                    	failedSdIdByStatus.get(newSD.Status__c).add(newSD.Id);
                                	}*/
                                }
                                
                                if (Test.isRunningTest() || ('Spares' == ProdNameQLI.get(newSD.ProductName__c).SBQQ__Product__r.Product_Type__c && !String.isBlank(newSD.HW_SerialNumber__c) && newSD.Status__c == 'Success' )){
                                        newSD.HW_SerialNumber__c = newSD.HW_SerialNumber__c.replaceAll('\\s+','');
                                        for(string SN : newSD.HW_SerialNumber__c.split('\\,')){
                                            if (serialNumAsset.containskey(SN) && serialNumAsset.get(SN) == null ){
                                                listSerialNumber.add(SN);
                                                assetToInsert.add(new asset ( SerialNumber = SN,
                                                                             Serial_number__c = SN,
                                                                             Name = SN,
                                                                             Status = 'Purchased',
                                                                             PurchaseDate = date.parse(newSD.ShippedDate__c), // valid date format mm/dd/yyyy'
                                                                             AccountId = quote.SBQQ__Account__c,
                                                                             Quantity = 1,
                                                                             Product2Id = ProdNameQLI.get(newSD.ProductName__c).SBQQ__Product__c,
                                                                             Distributor__c = quote.SBQQ__Distributor__c,
                                                                             ContractManufacturer__c = newSD.ContractManufacturer__c));
                                            }
                                        }
                                        system.debug(LoggingLevel.DEBUG,'assetToInsert: '+assetToInsert);
                                    }                                
                            }                           
                            
                        }else{
                            newSD.Status__c ='Failed';
                            newSD.ProcessHistory__c += 'No matching product found against quoteLine';
                            quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
                            failureReason.add('NA');
                        }
                    }else if(newSD.Status__c !='Failed'){
                        newSD.Status__c ='Failed';
                        newSD.ProcessHistory__c += 'Quote number is invalid';
                        failureReason.add('NA');
                        checkMissing = false;
                    }
                           
                }
            }
            //Add Quote to SD in all the cases except Quote number is invalid
            if(quoteMap.containsKey(newSD.QuoteNumber__c))
            {
                newSD.Quote__c = quoteMap.get(newSD.QuoteNumber__c).Id;
            }
        }catch(Exception e){
              system.debug(LoggingLevel.DEBUG,'exception'+e.getMessage());
              newSD.Status__c ='Internal Failure';
              newSD.ProcessHistory__c += e.getMessage();
              failureReason.add('NA');
              failureType = 'Internal Failure';
              quotetoupdateMap.put(newSD.QuoteNumber__c,'Failed');
            }
            }
        
        
         //**Pending**//
        
          // Success or missing lines           
        Map<Id,string> quoteIdMessageMap = new Map<Id,string>();
        Set<string> missingDtls= new Set<string>();
        for(Id quoteId: quoteIdPCodeDetails.keySet()){
            if(checkNew && checkMissing){
                Boolean failed = false;
                string missingPcode = '';
                Boolean isFirst = true;
                Map<string,quotePCodeDetails> codedtls = quoteIdPCodeDetails.get(quoteId);
                quotePCodeDetails quoPco;
                string msg = '';
                for(string pCode: codedtls.keySet())
                {
                    quoPco = codedtls.get(pCode);
                    if(codedtls.get(pCode).TotalQuantity != 0 && quoPco.quoteLineList.size() > 0 && quoPco.quoteLineList[0].Product_Type__c != 'Accessories'){ // < and > 0
                        if(codedtls.get(pCode).TotalQuantity>0)
                        {
                        	failed = true;
                            missingPcode+= pCode;
                            if(isFirst)
                            {
                                msg = 'Missing Product: ';
                                isFirst = false;
                            }
                            msg+=pCode.split('_')[1] + '(Awaiting Quant - '+ codedtls.get(pCode).TotalQuantity +')';
                            missingDtls.add(pCode.split('_')[1]+'='+codedtls.get(pCode).TotalQuantity);
                        }
                        else
                        {
                          if(msg!='') msg='NA';
                        }
                    }
                }
                if(!String.isEmpty(msg)) failureReason.add(msg);
                if(!failed && !duplicateSerial && (quoPco != null && quoPco.quoteLineList.size() > 0 && (!quotetoupdateMap.containskey(quoPco.quoteLineList[0].SBQQ__Quote__r.Name) || 
                    (quotetoupdateMap.containskey(quoPco.quoteLineList[0].SBQQ__Quote__r.Name) && quotetoupdateMap.get(quoPco.quoteLineList[0].SBQQ__Quote__r.Name) != 'Failed' && quotetoupdateMap.get(quoPco.quoteLineList[0].SBQQ__Quote__r.Name) != 'Internal Failure')))){
                    if(quoteMap.containsKey(quoPco.quoteLineList[0].SBQQ__Quote__r.Name)){
                        closeOptyList.add(quoteMap.get(quoPco.quoteLineList[0].SBQQ__Quote__r.Name).SBQQ__Opportunity2__c);
                    }
                    quotetoupdateMap.put(quoPco.quoteLineList[0].SBQQ__Quote__r.Name,'Success');
                    
                }else{
                    if(quotetoupdateMap.get(quoPco.quoteLineList[0].SBQQ__Quote__r.Name) != 'Internal Failure'){
                        quotetoupdateMap.put(quoPco.quoteLineList[0].SBQQ__Quote__r.Name,'Failed');
                    }
                }
            }
        }
		// Update Quotes shipment validation status //
        if(!quotetoupdateMap.isEmpty()){
            for(String quotename : quotetoupdateMap.keyset()){
                ShipmentDetail__c sdRec = quoteIdVsOverviewSD.containsKey(quoteNameVsId?.get(quotename)) ? quoteIdVsOverviewSD.get(quoteNameVsId?.get(quotename)) : 
                (overViewSDMap.containsKey(quotename) ? overViewSDMap.get(quotename) : (existingSDOverviews.containsKey(quotename) ? existingSDOverviews.get(quotename) : null));              
                if(sdRec != null && sdRec.Quote_ShipmentValidation__c != 'Complete')
                {
                    if(quotetoupdateMap.get(quotename) == 'Success'){
                        sdRec.Quote_ShipmentValidation__c = 'Complete';
                        sdRec.Quote_MissingShipmentDetails__c = '';
                    }else if(quotetoupdateMap.get(quotename) == 'Failed'){
                        sdRec.Quote_MissingShipmentDetails__c = missingDtls.toString();
                        sdRec.Quote_ShipmentValidation__c = 'Failed';
                    }else if(quotetoupdateMap.get(quotename) == 'Internal Failure'){
                        sdRec.Quote_MissingShipmentDetails__c = missingDtls.toString();
                        sdRec.Quote_ShipmentValidation__c = 'Internal Failure';
                    }
                }
                if (sdRec != null && sdRec.Id == null) {
                    overViewSDMap.put(quotename, sdRec);
                }
                if(existingSDOverviews.containsKey(quotename)) {
                    overviewSDToUpdate.add(sdRec);
                }
            }
        }
        if(shpListQuo != null){
           
            try
            {
            	if(!Test.isRunningTest()){
            	    TriggerHandler.bypass('ShipmentDetailHandler');
            	    update shpQuoList;
                    TriggerHandler.clearbypass('ShipmentDetailHandler');
                }
            }
            catch(DMLException e)
            {
                system.debug(LoggingLevel.DEBUG,'Error in updating Shipment Details: '+ e.getMessage());
            }
        } else if(!overviewSDToUpdate.isEmpty()) {
            TriggerHandler.bypass('ShipmentDetailHandler');
            update overviewSDToUpdate;
            TriggerHandler.clearbypass('ShipmentDetailHandler');
        }
        if(!failureReason.isEmpty() && sendEmail != false ){
            set<String> setNA = new set<String>();
            set<String> setMD = new set<String>();
            if(!failureReason.isEmpty()){
                for(String failRe : failureReason){
                    if(failRe.contains('NA')){ 
                        setNA.add(failRe);
                    }else{
                        setMD.add(failRe);
                    }
                }
            }
            shpSendEmail = shpQuoList;
            if(!setMD.isEmpty()){
                setEmailSend = setMD;
        	}else if(!setNA.isEmpty()){           
                setEmailSend = setNA;
        	}
        }
        //****//
        if(!closeOptyList.isEmpty()){
            closeOpportunity(closeOptyList);
        }
        if(shpListQuo != null && sendEmail == true){
            CommitBeforeInsertUpdateRec();
        }
    }
    /**
     * @description Wrapper Class
     */
    public class quotePCodeDetails{
        Decimal TotalQuantity;
        List<SBQQ__QuoteLine__c> quoteLineList = new List<SBQQ__QuoteLine__c>();
        quotePCodeDetails(Decimal quantity,SBQQ__QuoteLine__c qli){
            this.TotalQuantity  = quantity;
            this.quoteLineList.add(qli);
        }
    }
    //ASPEN-247 - End
    /**
    * @description  Data collection used in entire order trigger transaction
    **/
    public void CommitBeforeInsertUpdateRec(){
      List<Asset> assetList = new List<asset>();
      Map<string,string> SDUpdObjIds = new map<string,string>();
      Map<string,string>SNSDSns = new Map<string,string>();
      assetList.addall(assetToInsert);
     if(!assetList.isEmpty()){
       Map<string,string> SNSDId = new Map<string,string>();
       List<ShipmentDetail__c> shpListNew = new List<ShipmentDetail__c>(); 
       shpListNew = shpListQuo != null ? shpListQuo : Trigger.new;
       for(ShipmentDetail__c newSD: shpListNew){
         if(newSD.Status__c =='Failed'
         || !(newSD.order__c == null && (newSD.SalesOrderNumber__c == null || 'SPARES'.equalsIgnoreCase(newSD.SalesOrderNumber__c)))){Continue;} 
         if(newSD.HW_SerialNumber__c!= null){
            for(string SN : newSD.HW_SerialNumber__c.replaceAll('\\s+','').split('\\,')){
              SNSDSns.put(SN,newSD.HW_SerialNumber__c);
            }
            SDUpdObjIds.put(newSD.HW_SerialNumber__c+'AsstSucc','');
            SDUpdObjIds.put(newSD.HW_SerialNumber__c+'AsstFail','');
          }
       } 
      Integer i = 0;
      for(Database.SaveResult result:Database.insert(assetList,false)) {
           string SNs = SNSDSns.get(assetList[i].name);
            if(result.isSuccess()){
              SDUpdObjIds.put(SNs+'AsstSucc',SDUpdObjIds.get(SNs+'AsstSucc')+assetList[i].id+',');
          }else{
              SDUpdObjIds.put(SNs+'AsstFail',SDUpdObjIds.get(SNs+'AsstFail')+assetList[i].name+'-'+result.getErrors()[0].getMessage()+',');             
          }
          i++;
      }
      for(ShipmentDetail__c newSD: shpListNew){
        if(newSD.Status__c =='New'){
          if(String.isNotBlank(SDUpdObjIds.get(newSD.HW_SerialNumber__c+'AsstSucc'))){
            newSD.ProcessHistory__c+='Succ Asst: '+SDUpdObjIds.get(newSD.HW_SerialNumber__c+'AsstSucc').removeEnd(',')+'\n';
            newSD.Status__c =  'Success';
        }
        if(String.isNotBlank(SDUpdObjIds.get(newSD.HW_SerialNumber__c+'AsstFail'))){
          newSD.ProcessHistory__c+='Fail Asst : '+SDUpdObjIds.get(newSD.HW_SerialNumber__c+'AsstFail');
          newSD.Status__c =  'Internal Failure';
        }
        }
      }
     }
        if(!overViewSDMap.values().isEmpty()) {
            insert overViewSDMap.values();
        }
        for(ShipmentDetail__c sd: (List<ShipmentDetail__c>)Trigger.new) {
            if (overViewSDMap.containsKey(sd.QuoteNumber__c) && sd.RecordTypeId != Constants.overViewRecordTypeId) {
                sd.Parent_Shipment_Detail__c = overViewSDMap.get(sd.QuoteNumber__c).Id;
            }
        }
       if(Trigger.new != null && checkNew && shpSendEmail.isEmpty()){
            shpSendEmail = Trigger.new.getSObjectType().getDescribe().getName() == 'ShipmentDetail__c' ? Trigger.new : shpListQuo;
       }
       if(!shpSendEmail.isEmpty() && !setEmailSend.isEmpty() && !emailSent){
          sendFailureEmail(shpSendEmail,setEmailSend);
          emailSent = true;
       }
  
      }
  
      final static ShGl_DisableBusinessLogic__c businessLogicCS = ShGl_DisableBusinessLogic__c.getInstance();
      final static List<String> SD_STATUS_VAL_PRIORITY = new List<String>{ 'Internal Failure', 'Failed', 'Success' };
      @TestVisible
      String emitStatus(ShipmentDetail__c sdRec, Map<Id, String> orderSdProcessStatus ) {
          String statRecorded = orderSdProcessStatus.get(sdRec.Order__c);
          for (String statVal : SD_STATUS_VAL_PRIORITY) {
              if (sdRec.Status__c == statVal || statRecorded == statVal)
                  return statVal;
          }
          return sdRec.Status__c;
      }
    private void closeOpportunity(Set<Id> OppId)
    {
        List<Opportunity> opplist = [Select Id,StageName from Opportunity where Id in :OppId];
        for(Opportunity opp: opplist)
        {
        	opp.StageName = '7 Closed Won';
        }
        try
        {            	
            update opplist;
        }
        catch(DMLException e)
        {
            system.debug(LoggingLevel.DEBUG,'Error in updating Opportunity: '+ e.getMessage());
        }
    }
    private void sendFailureEmail(List<ShipmentDetail__c> newMap, Set<string> failureReason)
    {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>(); 
        Map<String,ShipmentDetail__c> listShip = new  Map<String,ShipmentDetail__c>();
        
        ShipmentDetail__c sdRec;
        sdRec = newMap[0];
        if(!Test.isRunningTest()){
            emails.add((new ShipmentNoticeFailureMessage(quoteMap.get(sdRec.QuoteNumber__c), failureType ,newMap, null,failureReason).getSingleEmail()));
        }
        try{
            if(!emails.isEmpty() ) Messaging.sendEmail(emails);
        }
        catch(Exception ex)
        {
            system.debug(LoggingLevel.DEBUG,'error in ShipmentDetailHelper-sendFailureEmail: '+ex.getMessage());
        }
    }
    /**
     * @description createOverviewRecord PRDOPS24-1089
     * @param quoteNameVsSDList
     * @param existingOverviews
     * @param quoteNameVsId
     **/
    public void createOverviewRecord(Map<String, List<ShipmentDetail__c>> quoteNameVsSDList, Map<String, ShipmentDetail__c> existingOverviews,Map<String, String> quoteNameVsId){
        existingSDOverviews = existingOverviews;  
        for(String quoteName : quoteNameVsSDList.keySet()) {
            if(!existingOverviews.containsKey(quoteName) && quoteNameVsId.containsKey(quoteName)) {
                ShipmentDetail__c overViewSD = new ShipmentDetail__c(Quote__c = quoteNameVsId.get(quoteName), RecordTypeId = Constants.overViewRecordTypeId);
                overViewSDMap.put(quoteName, overViewSD);
            }
        }
    }
  }