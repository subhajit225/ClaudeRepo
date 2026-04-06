public class RMASparePartsMappingHelper{
    
    /*public static string returmspareString(String prodFamily,String nicType, String applianceType ){
        string matchString = '';
        System.debug('prodFamily==='+prodFamily);
        System.debug('nicType==='+nicType);
        System.debug('applianceType==='+applianceType);
        
        if(prodFamily.contains('R300')){
            matchString = 'R300/R300S';
        }
        if(prodFamily.contains('R300') && nicType.contains('SFP+')){
            matchString = 'R300-01';
        }
        else if(prodFamily.contains('R300') && nicType.contains('10GBase-T')){
            matchString = 'R300-02';
        }
        else if(prodFamily.contains('R300') && applianceType.contains('R3410')){
            matchString = 'R3410';
        }
        else if(prodFamily.contains('R300') && applianceType.contains('R348')){
            matchString = 'R348';
        }
        else if(applianceType.contains('R334') || applianceType.contains('R344') || applianceType.contains('R3x4')){
            matchString = 'R334/R344';
        }
        if(prodFamily.contains('R500')){
            matchString = 'R500';
        }
        if(prodFamily.contains('R500') && nicType.contains('SFP+')){
            matchString = 'R500-NIC-01';
        }
        else if(prodFamily.contains('R500') && nicType.contains('10GBase-T')){
            matchString = 'R500-NIC-02';
        }
        else if(prodFamily.contains('R528E')){
            matchString = 'R528E';
        }
        if(prodFamily.contains('R6000')){
            matchString = 'R6000/R6000S/R6000F';
        }
        if(prodFamily.contains('R6000') && nicType.contains('SFP+')){
            matchString = 'R6000/R6000S-NIC-01';
        }
        else if(prodFamily.contains('R6000') && nicType.contains('10GBase-T')){
            matchString = 'R6000/R6000S-NIC-02';
        }
        else if(prodFamily.contains('R6000') && applianceType.contains('R6408F')){
            matchString = 'R6408F-HDD/SSD';
        }
        else if(prodFamily.contains('R6000') && applianceType.contains('R6410F')){
            matchString = 'R6410F-HDD/SSD';
        }
        else if(prodFamily.contains('R6000') && !applianceType.endsWith('F')){
            matchString = 'R6x04/R6408/R6410-SSD';
        }
        else if((applianceType.contains('R6304') || applianceType.contains('R6304')  || applianceType.contains('R6x04')) && nicType.contains('SFP+')){
            matchString = 'R6x04/R6x04S-Node-01';
        }
        else if((applianceType.contains('R6304') || applianceType.contains('R6304')  || applianceType.contains('R6x04')) && nicType.contains('10GBase-T')){
            matchString = 'R6x04/R6x04S-Node-02';
        }
        else if((applianceType.contains('R6304') || applianceType.contains('R6304')  || applianceType.contains('R6x04')) && !applianceType.endsWith('F')){
            matchString = 'R6x04-HDD';
        }
        else if(applianceType.contains('R6408') && !applianceType.endsWith('F')){
            matchString = 'R6408/R6408S-HDD';
        }
        else if((applianceType.contains('R6408') || applianceType.contains('R6410') ) && nicType.contains('SFP+')  && !applianceType.endsWith('F') ){
            matchString = 'R6408/R6408S/R6410/6410S-01';
        }
        else if((applianceType.contains('R6408') || applianceType.contains('R6410') ) && nicType.contains('10GBase-T')  && !applianceType.endsWith('F') ){
            matchString = 'R6408/R6408S/R6410/6410S-02';
        }
        else if((applianceType.contains('R6408F') || applianceType.contains('R6410F') ) && nicType.contains('SFP+') ){
            matchString = 'R64xxF-Node-01';
        }
        else if((applianceType.contains('R6408F') || applianceType.contains('R6410F') ) && nicType.contains('10GBase-T') ){
            matchString = 'R64xxF-Node-02';
        }
        else if(applianceType.contains('R6410') && !applianceType.endsWith('F') ){
            matchString = 'R6410/R6410S-HDD';
        }

        System.debug('matchString==='+matchString);
        
        return matchString;
    }*/
    /* <--START--> SF-91 
        Method for provided the correct mapping record based on Appliance Model, Product Nic Type and Product Family
    */
    public static Spares_Mapping__c returnSparePartCode(String prodFamily,String nicType, String applianceModel ){
        //Creating dynamic query string 
         String query = 'select id, HDD__c , SSD__c , Memory__c, Chassis__c, Node__c, PSU__c, NIC__c, CMOS_Battery__c from Spares_Mapping__c ';
         query += 'where ';
         
         // First priority goes to Appliance model so added Filter based on Product Appliance Model
         if(String.isNotBlank(applianceModel) ){
             query += 'Appliance_Model__c = \'' + String.escapeSingleQuotes(applianceModel) + '\' ';
         }
         // IF Product have a NIC Type, Added extra filer for that to get the exact record
         if(String.isNotBlank(nicType) ){
             if(query.endsWith('where ')){
                 query += 'NIC_Type__c = \'' + String.escapeSingleQuotes(nicType) + '\' ';
                 query += ' AND Appliance_Model__c = NULL';
             }
             else {
                 query += ' AND NIC_Type__c = \'' + String.escapeSingleQuotes(nicType) + '\' ';
             }
         }
        // In last case, If Product Family is not Balnk and other filtr are added, Add Family Filter on top that else,just put Family Filter
         if(String.isNotBlank(prodFamily) ){
             if(query.endsWith('where ')){
                 query += 'Product_Family__c = \'' + String.escapeSingleQuotes(prodFamily) + '\' ';
                 query += ' AND NIC_Type__c = NULL AND Appliance_Model__c = NULL';
             }
             else {
                 query += ' AND Product_Family__c = \'' + String.escapeSingleQuotes(prodFamily) + '\' ';
             }
         }
         // If no filter is added, then replacing Where clause for adding LIMIT
         if(query.endsWith('where ')){
                 query = query.replace('where ', 'LIMIT 1');
         }
         else {
                 query += ' LIMIT 1 ';
         }
         
        System.debug('query==='+query);
        List<Spares_Mapping__c> spares  = Database.query(query);
        if(!spares.isEmpty()) {
            return spares[0];
        }
        else {
            return null;
        }
    }
    /* < END ---- SF-91> */
    public static List<Spares_Mapping__c> returnSparePartCodeQueryAll(){
        String query = 'select id, HDD__c , SSD__c , Memory__c, Chassis__c, Node__c, PSU__c, NIC__c, CMOS_Battery__c,Appliance_Model__c,NIC_Type__c,Product_Family__c from Spares_Mapping__c ';
      List<Spares_Mapping__c> sparesList  = Database.query(query);
        return sparesList;
    }
    public static Spares_Mapping__c returnSparePartRecord(List<Spares_Mapping__c> sparesList,String prodFamily,String nicType, String applianceModel ){
        Spares_Mapping__c spareRec = new Spares_Mapping__c();
        Boolean flag = false;
        for(Spares_Mapping__c spare : sparesList){
            if(!flag && !string.isBlank(prodFamily) && !string.isBlank(spare.Product_Family__c) && prodFamily.contains(spare.Product_Family__c) 
               && !string.isBlank(nicType) && !string.isBlank(spare.NIC_Type__c)  && nicType.contains(spare.NIC_Type__c)  
               && !string.isBlank(applianceModel) && !string.isBlank(spare.Appliance_Model__c)  && applianceModel==spare.Appliance_Model__c){
                   flag = true;
                   spareRec = spare;
               }
            if(!flag && string.isBlank(prodFamily) && string.isBlank(spare.Product_Family__c)
               && !string.isBlank(nicType) && !string.isBlank(spare.NIC_Type__c)  && nicType.contains(spare.NIC_Type__c)   
               && !string.isBlank(applianceModel) && !string.isBlank(spare.Appliance_Model__c)  && applianceModel==spare.Appliance_Model__c ){
                   flag = true;
                   spareRec = spare;
               }
            
            if(!flag && !string.isBlank(prodFamily) && !string.isBlank(spare.Product_Family__c) && prodFamily.contains(spare.Product_Family__c) 
               && string.isBlank(nicType) && string.isBlank(spare.NIC_Type__c)
               && !string.isBlank(applianceModel) && !string.isBlank(spare.Appliance_Model__c)  && applianceModel==spare.Appliance_Model__c){
                   flag = true;
                   spareRec = spare;
               }
            
            if(!flag && string.isBlank(prodFamily) && string.isBlank(spare.Product_Family__c)
               && string.isBlank(nicType) && string.isBlank(spare.NIC_Type__c)
               && !string.isBlank(applianceModel) && !string.isBlank(spare.Appliance_Model__c)  && applianceModel==spare.Appliance_Model__c){
                   flag = true;
                   spareRec = spare;
               }
            if(!flag && !string.isBlank(prodFamily) && !string.isBlank(spare.Product_Family__c) && prodFamily.contains(spare.Product_Family__c) 
               && !string.isBlank(nicType) && !string.isBlank(spare.NIC_Type__c)  && nicType.contains(spare.NIC_Type__c)  
               && string.isBlank(applianceModel) && string.isBlank(spare.Appliance_Model__c)){
                   flag = true;
                   spareRec = spare;
               }
      if(flag)
                break;
        }
        if(flag){
            return spareRec;
        }else{
            return null;
        }
    }
}