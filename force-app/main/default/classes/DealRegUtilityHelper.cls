/**
 * @description : this class is a utility for opp and deal classes
 */
public class DealRegUtilityHelper {
    
    public static String PID = 'Partner Sourced New Logo (PSNL)';
    public static String RID = 'Rubrik Sourced';
    public static String JID = 'Partner Sourced Expand';
    public static String CONVERT_STATUS ='Pending';
    public static String APPROVED = 'Approved';
    public static String SUBMITTED = 'Submitted';
    //PRIT24-754- START
    public static String PS = 'Partner Sourced';
    public static String PSNL = 'Partner Sourced New Logo (PSNL)';
    //PRIT24-754- END
    
    
    /**
     * @description This method to set Deal_Registration_Type__c on Opportunity
     * @return void
     */
    public static void setDealRegistrationType(Opportunity vOpportunity, Lead regLink)
    {
        if(regLink==null && vOpportunity.Converted_From_Lead__c==true && !vOpportunity.Deal_Registration__c){
            vOpportunity.Deal_Registration_Type__c = RID;
        }
    }
    
    /**
     * @description This method to get getPicklistValues based on object name and field names
     * @return List<String>
     */
	public static List<String> getPicklistValue(String objName, String fieldName){
		List<String> picklistValueToReturnList = new List<String>(); 
        List<Schema.PicklistEntry> picklistValues = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues();               
        
        for(Schema.PicklistEntry picklistVal : picklistValues){
            picklistValueToReturnList.add(String.valueof(picklistVal.getLabel()));
        }
        return picklistValueToReturnList;
	}
	
    /**
     * @description This method to get getAlliancePartnerMapping 
     * @return Map<String,Alliance_Partner_Account_Mapping__mdt>
     */
	public static Map<String,Alliance_Partner_Account_Mapping__mdt> getAlliancePartnerMapping(){
		Map<String,Alliance_Partner_Account_Mapping__mdt> alliancePartnerMap = new Map<String,Alliance_Partner_Account_Mapping__mdt>();
		for(Alliance_Partner_Account_Mapping__mdt allMeta : [SELECT ID,MasterLabel,DeveloperName,Account_ID__c,Alliance_Account_Name__c,Account_Name__c,Account_Type__c
															FROM Alliance_Partner_Account_Mapping__mdt]){
			alliancePartnerMap.put(allMeta.Account_ID__c,allMeta);
		}
		return alliancePartnerMap;
	}
}