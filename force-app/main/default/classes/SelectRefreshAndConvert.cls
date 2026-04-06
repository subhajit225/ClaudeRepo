public class SelectRefreshAndConvert {
 
    public Id quoteId               { get; set; }
    public boolean page1Rendered    { get; set; } // true -> show pb2
    public boolean page2Rendered    { get; set; } // true -> show pb3
    public String selectedRT        { get; set; } // selected value of selectList
    public boolean page3Rendered    { get; set; } // ARY-1079

    //Restrict Convert and Refresh for Amendment
    public SBQQ__Quote__c objQuote     { get; set; }
    public Boolean showAmendValidation { get; set; }
    public Boolean isREQuote { get; set; } // ARY-1079
    /**@description : smsUIDisabled - Brings value from Custom Setting - Disable Business Logic - Bypasses Replacement framework*/
    public Boolean smsUIDisabled { get; set; } //FY25SR-1706

    public SelectRefreshAndConvert(){
        quoteId = (Id)ApexPages.currentPage().getParameters().get('qid');
        page1Rendered = page2Rendered = false;
        selectedRT = '';
        
        showAmendValidation = false;
        
        //Query Quote
        objQuote = [SELECT Id
                         , SBQQ__Type__c
                      FROM SBQQ__Quote__c
                     WHERE Id =: quoteId][0]; 
        
        if(objQuote.SBQQ__Type__c == 'Amendment') {
            showAmendValidation = true;
        }
        //ARY-1079 Starts
        if (objQuote.SBQQ__Type__c == 'Renewal+Expansion') {
            //FY25SR-1706 Starts
            ShGl_DisableBusinessLogic__c disabled = ShGl_DisableBusinessLogic__c.getInstance();
            smsUIDisabled = disabled.Disable_Replacement_Framework__c;
            //isREQuote = true;
            //FY25SR-1706 Ends
        }
        //ARY-1079 Ends
    }

    public void onChangeFnCall() {
        if(selectedRT =='Convert') {
            page1Rendered = true;
            page2Rendered = false;
            page3Rendered = false; // ARY-1079
        } else if(selectedRT=='Refresh') {
            page1Rendered = false;
            page2Rendered = true;
            page3Rendered = false; // ARY-1079
        } else if(selectedRT=='Replace') { //ARY-1079-Starts
            page1Rendered = false;
            page2Rendered = false;
            page3Rendered = true;
        } else{                            //ARY-1079-Ends
            page1Rendered = false;
            page2Rendered = false;
            page3Rendered = false; // ARY-1079
        }
    }
}