public without sharing class NetAppQuoteLinesContr { 
    
    public SBQQ__Quote__c Quote {get;set;}
    public Id quoteId;
    public String NetApp = 'NetApp';
    public List<lstQuoteLinesToDisplayWrap> lstQuoteLinesToDisplay {get;set;}
    public string netTotal{get;set;}
    Decimal nTotal = 0;
    public List<coveredAssetDisplayWrap> coveredAssetToDisplay {get;set;}//CPQ22-3890
    
    public NetAppQuoteLinesContr (){
        quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');
        coveredAsset(quoteId);//CPQ22-3890
    }
    
    public void init() {
        //try {
            lstQuoteLinesToDisplay = new List<lstQuoteLinesToDisplayWrap>();
            
            Map<Id, List<SBQQ__QuoteLine__c>> childQLIs = new Map<Id, List<SBQQ__QuoteLine__c>>();
            Map<SBQQ__QuoteLine__c, List<SBQQ__QuoteLine__c>> parentChildQLIs = new Map<SBQQ__QuoteLine__c, List<SBQQ__QuoteLine__c>>();
            Set<String> QuoteLineFields = Schema.SBQQ__QuoteLine__c.SobjectType.getDescribe().fields.getMap().keySet();
            
            //SORTING QUOTE LINES WITHOUT FILTERING NETAPP QUOTE LINES
            //List<SBQQ__QuoteLine__c> allQLIsTemp = (SBQQ__QuoteLine__c[])Database.query('SELECT '+String.join(new List<String>(QuoteLineFields),',')+' FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = \''+quoteId+'\' ORDER BY Template_Sequence__c');
            //commented above line since it was throwing "Query is either selecting too many fields or the filter conditions are too complicated" error
            List<SBQQ__QuoteLine__c> allQLIsTemp = [Select Id, Name, GPL__c, SBQQ__RequiredBy__c, Product_Level__c, Approval_Category__c,
            Category__c, SBQQ__ProductCode__c, SBQQ__Quantity__c, Usable_Capacity__c, Quantity_TB_Template__c, SBQQ__SubscriptionTerm__c,
            Monthly_Unit_Sales_Price__c, SBQQ__ListPrice__c,SBQQ__NetTotal__c, Qty_Unit_of_Measure__c, SBQQ__Description__c,List_Price__c, 
            Approval_Discount__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c =: quoteId  ORDER BY Template_Sequence__c];
            
            List<SBQQ__QuoteLine__c> allQLIs = new List<SBQQ__QuoteLine__c>();
            
            system.debug('allQLIsTemp: ' + allQLIsTemp);
            system.debug('Size allQLIsTemp: ' + allQLIsTemp.size());
            for(SBQQ__QuoteLine__c quoteLine : allQLIsTemp) {
                if(quoteLine.GPL__c == 'NetApp') {
                    allQLIs.add(quoteLine);
                }
            }
            system.debug('allQLIs: ' + allQLIs);
            system.debug('Size allQLIs: ' + allQLIs.size());
            
            Map<Id, List<SBQQ__QuoteLine__c>> bundleToHardwareMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
            Set<Id> addedQuoteLinesSet = new Set<Id>(); 
            
            for (SBQQ__QuoteLine__c qli :allQLIs) {
                
                if (qli.SBQQ__RequiredBy__c != null) {
                    if (childQLIs.containsKey(qli.SBQQ__RequiredBy__c)) {
                        childQLIs.get(qli.SBQQ__RequiredBy__c).add(qli);
                    } else {
                        childQLIs.put(qli.SBQQ__RequiredBy__c, new List<SBQQ__QuoteLine__c>{qli});
                    }
                }
                
                if(qli.Product_Level__c == 'Hardware' && qli.Approval_Category__c == 'Hardware (H)') {
                    if (bundleToHardwareMap.containsKey(qli.SBQQ__RequiredBy__c)) {
                        bundleToHardwareMap.get(qli.SBQQ__RequiredBy__c).add(qli);
                    } else {
                        bundleToHardwareMap.put(qli.SBQQ__RequiredBy__c, new List<SBQQ__QuoteLine__c>{qli});
                    }
                }
            }
            
            for(SBQQ__QuoteLine__c qli :allQLIs) { 
                
                if(qli.GPL__c == 'NetApp' && qli.Category__c == 'Professional Services'){
                  SBQQ__QuoteLine__c psQLI = qli;
            
                  lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(psQLI));
                    system.debug('PS SKU: ' + qli.SBQQ__ProductCode__c);
                }
                
                if(qli.GPL__c == 'NetApp' && qli.SBQQ__RequiredBy__c == null) {
                    
                    List<SBQQ__QuoteLine__c> quoteLineList = bundleToHardwareMap.get(qli.Id);
                    
                    if(quoteLineList != null && quoteLineList.size() > 0) {
                        SBQQ__QuoteLine__c standaloneAddOnQLI = new SBQQ__QuoteLine__c();
                        for(SBQQ__QuoteLine__c quteLine: quoteLineList) {
                            
                            SBQQ__QuoteLine__c clonedParentQLI = qli.clone(true, true, false, false);
                            SBQQ__QuoteLine__c hardwareQuoteLine = quteLine;
                            
                            clonedParentQLI.SBQQ__Quantity__c = hardwareQuoteLine.Usable_Capacity__c * hardwareQuoteLine.SBQQ__Quantity__c;
                            System.debug('QTY1: ' + clonedParentQLI.SBQQ__Quantity__c);
                            System.debug('A1: ' + clonedParentQLI.SBQQ__ProductCode__c);
                            if(clonedParentQLI.SBQQ__ProductCode__c==NULL){
                                system.debug('Line 82');
                    }
                            lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(clonedParentQLI));
                            addedQuoteLinesSet.add(qli.Id); 
                            
                            for(SBQQ__QuoteLine__c quoteLine : childQLIs.get(qli.Id)) {
                                System.debug('quoteLine: ' + quoteLine.SBQQ__ProductCode__c);
                                
                                if(quoteLine.Id == hardwareQuoteLine.Id )
                                {
                                    System.debug('B1: ' + quoteLine.SBQQ__ProductCode__c);
                                    

                                    lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(quoteLine));
                                    if(childQLIs!=null && childQLIs.containsKey(quoteLine.Id) && childQLIs.get(quoteLine.Id)!=null){
                                    for(SBQQ__QuoteLine__c supportQuoteLine : childQLIs.get(quoteLine.Id))
                                    {
                                        System.debug('C1: ' + supportQuoteLine.SBQQ__ProductCode__c);                                        
                                        lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(supportQuoteLine));                               
                                    }
                                    }
                                    
                                }
                                
                                if(quoteLine.Product_Level__c.containsIgnoreCase('Addon'))
                                {
                                    System.debug('Add-On: ' + quoteLine.SBQQ__ProductCode__c);
                                    //SBQQ__QuoteLine__c clonedQLI = quoteLine.clone(true, true, false, false);
                                    
                                    if(quoteLine.Product_Level__c.containsIgnoreCase('Standalone')) {
                                        standaloneAddOnQLI = quoteLine;
                                        standaloneAddOnQLI.SBQQ__Quantity__c = quoteLine.SBQQ__Quantity__c; 
                                        //hardwareQuoteLine.Usable_Capacity__c * hardwareQuoteLine.SBQQ__Quantity__c;
                                        System.debug('D11: ' + standaloneAddOnQLI.Quantity_TB_Template__c + ' ' + standaloneAddOnQLI.SBQQ__Quantity__c + ' ' +  standaloneAddOnQLI.SBQQ__ProductCode__c);
                                    } else {
                                        SBQQ__QuoteLine__c clonedQLI = quoteLine.clone(true, true, false, false);
                                        clonedQLI.SBQQ__Quantity__c = hardwareQuoteLine.SBQQ__Quantity__c;
                                        System.debug('D12: ' + clonedQLI.Quantity_TB_Template__c + ' ' + clonedQLI.SBQQ__Quantity__c + ' ' + clonedQLI.SBQQ__ProductCode__c);
                                        

                                        lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(clonedQLI));
                                    }
                                    //lstQuoteLinesToDisplay.add(clonedQLI);
                                } 
                            }
                        }//for
                        
                        if(standaloneAddOnQLI.Id!=null){
                            lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(standaloneAddOnQLI));
                        }
                    }
                }
                
                if(!addedQuoteLinesSet.contains(qli.Id) && qli.SBQQ__RequiredBy__c == null) {
                    lstQuoteLinesToDisplay.add(new lstQuoteLinesToDisplayWrap(qli));
                }
            }
            
            for(SBQQ__QuoteLine__c qli :allQLIs) {
                if(qli.GPL__c == 'NetApp' && qli.SBQQ__RequiredBy__c == null) {}
            }


            List<String> args1 = new String[]{'0','number','###,###,##0.00'};

            for(lstQuoteLinesToDisplayWrap qli :lstQuoteLinesToDisplay) {
                nTotal+=qli.NetTotalDeci;
            }

            
            
            netTotal = String.format(nTotal.format(), args1);
            if(netTotal.containsNone('.')){
                netTotal+='.00';
            }else if((netTotal.length() - netTotal.IndexOf('.')-1)==1){
                netTotal+='0';
            }


            
            System.debug('lstQuoteLinesToDisplay Size: ' + lstQuoteLinesToDisplay.size());
            System.debug('lstQuoteLinesToDisplay: ' + lstQuoteLinesToDisplay);
            
        /* } catch(Exception ex) {
            System.debug('ex: ' + ex.getLineNumber() + '**' + ex.getStackTraceString() + '**' + ex.getMessage());
        }*/
    }

    //CPQ22-3890 Starts
    public void coveredAsset(Id currentQuoteId){
        coveredAssetToDisplay = new List<coveredAssetDisplayWrap>(); 
        List<SBQQ__QuoteLine__c> lstQuoteLines = [Select Id, Name,SBQQ__ProductCode__c,SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.Disposition_Reason__c, Subscribed_Asset_Name__c,Disposition_Reason__c from SBQQ__QuoteLine__c 
        where Product_Level__c = 'Hardware' AND SBQQ__Quote__c =: currentQuoteId AND SBQQ__Renewal__c = true];
        if (lstQuoteLines != null && !lstQuoteLines.isEmpty()) { 
            for (SBQQ__QuoteLine__c qlRec : lstQuoteLines) {
                if (qlRec.SBQQ__RequiredBy__c != null){
                    if (qlRec.SBQQ__RequiredBy__r.Disposition_Reason__c != null && qlRec.SBQQ__RequiredBy__r.Disposition_Reason__c != 'Renew Later' && qlRec.SBQQ__RequiredBy__r.Disposition_Reason__c != 'At Risk') {
                        coveredAssetToDisplay.add(new coveredAssetDisplayWrap(qlRec));
                    }
                }
                else {
                    if (qlRec.Disposition_Reason__c != null && qlRec.Disposition_Reason__c != 'Renew Later' && qlRec.Disposition_Reason__c != 'At Risk') {
                        coveredAssetToDisplay.add(new coveredAssetDisplayWrap(qlRec));
                    }
                } 
            }
        }
    }

    public class coveredAssetDisplayWrap {
        public SBQQ__QuoteLine__c ql {get; set;}
        public String hwName {get; set;}
        public String assetName {get; set;}

        public coveredAssetDisplayWrap (SBQQ__QuoteLine__c ql){
            hwName = ql.SBQQ__ProductCode__c;
            assetName = ql.Subscribed_Asset_Name__c;
        }
    }
    //CPQ22-3890 Ends

    public class lstQuoteLinesToDisplayWrap {
        public SBQQ__QuoteLine__c ql {get; set;}
        public String NetTotal {get; set;}
        public String ListPrice {get; set;}
        public String MonthlyUnitSalesPrice {get; set;}
        public Decimal NetTotalDeci {get; set;}
 
        public lstQuoteLinesToDisplayWrap(SBQQ__QuoteLine__c qli) {
            List<String> args = new String[]{'0','number','###,###,##0.00'};
            this.ql = qli;

            if(qli.SBQQ__SubscriptionTerm__c!=null){
                decimal netAmt = 0;
                netAmt = qli.SBQQ__Quantity__c * qli.SBQQ__SubscriptionTerm__c * qli.Monthly_Unit_Sales_Price__c;
                Decimal roundedNetAmt = netAmt.setScale(2);
                NetTotal = '$'+String.format(roundedNetAmt.format(), args);
                if(NetTotal.containsNone('.')){
                    NetTotal+='.00';
                }else if((NetTotal.length() - NetTotal.IndexOf('.')-1)==1){
                    NetTotal+='0';
                }
                NetTotalDeci = netAmt;


                decimal ListPriceCal = 0;
                ListPriceCal = qli.SBQQ__Quantity__c * qli.SBQQ__SubscriptionTerm__c * qli.SBQQ__ListPrice__c;
                Decimal roundedListPriceCal = ListPriceCal.setScale(2);
                ListPrice = '$'+String.format(roundedListPriceCal.format(), args);
                if(ListPrice.containsNone('.')){
                    ListPrice+='.00';
                }else if(((ListPrice.length() - ListPrice.IndexOf('.')-1))==1){
                    ListPrice+='0';
                }
            }else{
                Decimal roundedNetTotal = qli.SBQQ__NetTotal__c.setScale(2);

                NetTotal = '$'+String.format(roundedNetTotal.format(), args);
                NetTotalDeci = qli.SBQQ__NetTotal__c;
                if(NetTotal.containsNone('.')){
                    NetTotal+='.00';
                }else if((NetTotal.length() - NetTotal.IndexOf('.')-1)==1){
                    NetTotal+='0';
                }

                Decimal roundedListPriceCal = qli.SBQQ__ListPrice__c.setScale(2);
                ListPrice = '$'+String.format(roundedListPriceCal.format(), args);
                if(ListPrice.containsNone('.')){
                    ListPrice+='.00';
                }else if((ListPrice.length() - ListPrice.IndexOf('.')-1)==1){
                    ListPrice+='0';
                }

            } 
            Decimal roundedMonthlyUnitSalesPrice = qli.Monthly_Unit_Sales_Price__c.setScale(2);
            MonthlyUnitSalesPrice = '$'+String.format(roundedMonthlyUnitSalesPrice.format(), args);
            if(MonthlyUnitSalesPrice.containsNone('.')){
                MonthlyUnitSalesPrice+='.00';
            }else if((MonthlyUnitSalesPrice.length() - MonthlyUnitSalesPrice.IndexOf('.')-1)==1){
                MonthlyUnitSalesPrice+='0';
            }
        }
    }
}