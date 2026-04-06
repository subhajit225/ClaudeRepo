/**
 * @Description        : Web Service class which gets called from QCP to calculate custom POT
 * @Author             : Shreejita Basu
 * Ver       Date            Author                   Modification
 * 1.0      05-05-2022       Shreejita Basu           Intial Draft
**/

@RestResource(urlMapping='/CalculateCustomPOT')
global class CalculateCustomPOT{

    /**
     * Ticket No : CPQ22-874
     * Method : calculateCustomPOT
     * Parameters : quote Id
     * Description :  This method is used to calculate custom POT override
    **/


    @httppost
    global static Map<String, Decimal> calculateCustomPOT(List<String> strPrList) {

        Map<String, Decimal> mapPotProdPrice = new Map<String, Decimal>();
        system.debug('>>> Inside Method <<');        
        system.debug('>>> strProductDetailsList:'+strPrList);
        if(!strPrList.isEmpty()) {
             try {
                
                List<PriceBookEntry> lstPBE = new List<PriceBookEntry>();
                lstPBE = [SELECT Id, UnitPrice, Product2Id, Pricebook2.name, isactive, ProductCode from PricebookEntry where IsActive = true and Pricebook2.name = 'CPQ PriceBook' and Product2Id IN: strPrList];
                for(PriceBookEntry objPBE : lstPBE) {
                    mapPotProdPrice.put(objPBE.Product2Id, objPBE.UnitPrice);
                }
                System.debug('>>> mapPotProdPrice: '+mapPotProdPrice);
            } catch(Exception exceptionMessage){
            
            }
        }
        return mapPotProdPrice;
    }
    
}