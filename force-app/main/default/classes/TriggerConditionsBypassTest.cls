@IsTest
private class TriggerConditionsBypassTest {
    
    /**
* @description Test setting and unsetting the bypass flag
*/
    @IsTest
    static void testUSCitizenBypassFlag() {
        
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Add flag
            TriggerConditionsBypass.addFlag('USCitizenValidationByPass');
            
            // check added flag
            Boolean flagAdded  = TriggerConditionsBypass.isBypassed('USCitizenValidationByPass');
            System.assertEquals(true, flagAdded, 'Flag should be added after setting');
            
            // remove flag
            TriggerConditionsBypass.removeFlag('USCitizenValidationByPass');
            Boolean usCitizenValidationByPass = TriggerConditionsBypass.isBypassed('USCitizenValidationByPass');
            System.assertEquals(false, usCitizenValidationByPass, 'No Flag after reset');
            
            TriggerConditionsBypass.addFlag('USCitizenValidationByPass2');
            Boolean flagAdded2  = TriggerConditionsBypass.isBypassed('USCitizenValidationByPass');
            
            // remove all flags
            TriggerConditionsBypass.clearAllFlags();
            System.assertEquals(true, TriggerConditionsBypass.bypassFlags.isEmpty(), 'No Flag after reset');  
        }
    }
}