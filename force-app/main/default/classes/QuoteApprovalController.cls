public with sharing class QuoteApprovalController {
    
    private SBQQ__Quote__c sbQuote;
    
    ApexPages.StandardController qtController;
    public SBAA__Approval__c[] approvals {
        get {
            integer count=0;
            count=[select count() from SBQQ__quoteline__c where SBQQ__Quote__c=:sbQuote.Id];

            //RSCG-59 Starts 
            Boolean approveQuote = false;
            Boolean reqApproval = false;
            if(count > 0){
                for(SBQQ__Quoteline__c quoteLine : [Select Id, Target_NetTotal__c, SBQQ__NetTotal__c, RWD_Sales_Rep_Exception__c, RWD_Deal_Ops_Exception__c from SBQQ__quoteline__c where SBQQ__Quote__c=:sbQuote.Id AND SBQQ__Quote__r.Is_RSCG_Excp__c = true AND Product_Subtype__c = 'FEDRAMP' AND Special_Program__c = 'Replaced'] ){

                    if(((quoteLine.RWD_Sales_Rep_Exception__c != null && quoteLine.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement')) && (Math.round(quoteLine.SBQQ__NetTotal__c) < Math.round(quoteLine.Target_NetTotal__c)))){
                        reqApproval = true;
                    }
                    if(((quoteLine.RWD_Deal_Ops_Exception__c != null && quoteLine.RWD_Deal_Ops_Exception__c.contains('$0 RSC-G Replacement')) && quoteLine.SBQQ__NetTotal__c == 0) || 
                    ((quoteLine.RWD_Sales_Rep_Exception__c != null && quoteLine.RWD_Sales_Rep_Exception__c.contains('25% Premium RSC-G Replacement'))  && (Math.round(quoteLine.SBQQ__NetTotal__c) >= Math.round(quoteLine.Target_NetTotal__c)))
                    ){
                        approveQuote =true; //RSCG-59
                    }
                  }

                  approveQuote = reqApproval ? false : approveQuote;
                }
                //RSCG-59 Ends
            
            if (approvals == null && count > 0 && !approveQuote) {
                approvals = SBAA.ApprovalAPI.preview(sbQuote.Id, SBAA__Approval__c.Quote__c);
            }else{
                approvals =new list<SBAA__Approval__c>();
            }
            return approvals;
        } 
        set;
    }

    public Boolean isReadyForApproval {get; set;}

    public QuoteApprovalController(ApexPages.StandardController stdController) {
        /*this.qtController = stdController;
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String> {'SBQQ__Opportunity2__c'});
        }*/
        this.sbQuote = (SBQQ__Quote__c)stdController.getRecord();


    }
  
}