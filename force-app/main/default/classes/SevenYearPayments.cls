public class SevenYearPayments {

    public SBQQ__Quote__c Quote{get;set;}
    id quoteId ;
    public QuoteWrapper QW{get;set;}
        
    public SevenYearPayments (){
        quoteId = (Id)ApexPages.currentPage().getParameters().get('qid'); 

    }
    
     public PageReference init() {
        Quote = [select id,Payment_year_1__c,Payment_year_2__c,Payment_year_3__c,Payment_year_4__c,Payment_year_5__c,Payment_year_6__c,Payment_year_7__c from SBQQ__Quote__c where id =: quoteId];
        //start();
        QW = new QuoteWrapper();
        QW.Payment_year_1 = ConvertFormat(Quote.Payment_year_1__c);
        QW.Payment_year_2 = ConvertFormat(Quote.Payment_year_2__c);
        QW.Payment_year_3 = ConvertFormat(Quote.Payment_year_3__c);
        QW.Payment_year_4 = ConvertFormat(Quote.Payment_year_4__c);
        QW.Payment_year_5 = ConvertFormat(Quote.Payment_year_5__c);
        QW.Payment_year_6 = ConvertFormat(Quote.Payment_year_6__c);
        QW.Payment_year_7 = ConvertFormat(Quote.Payment_year_7__c);
        
         return null;
         
     }
    
    public Class QuoteWrapper{
        
     public string  Payment_year_1{get;set;}
     public string  Payment_year_2{get;set;}
     public string  Payment_year_3{get;set;}
     public string  Payment_year_4{get;set;}
     public string  Payment_year_5{get;set;}
     public string  Payment_year_6{get;set;}
     public string  Payment_year_7{get;set;}
        
    }
    
    public string ConvertFormat(decimal InputDecimal){
        if(InputDecimal != null){
            string CommaText ='' ;
            string InputText = string.valueof(InputDecimal);
            for(integer i = 0; i < InputText.substringBefore('.').length(); i = i + 3){
                CommaText = CommaText + InputText.substringBefore('.').reverse().mid(i,3) + ',';
            }
        return CommaText.reverse().removeStart(',')+'.'+InputText.substringAfter('.').mid(0,2);
        }else{
            return null;
        }
     
    }
    

}