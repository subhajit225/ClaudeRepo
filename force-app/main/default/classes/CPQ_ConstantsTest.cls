/*******************************************************************************************************************
* @description       : Test Class for CPQ_Constants
* @last modified on  : 02-06-2026
* @last modified by  : Mishika
********************************************************************************************************************/
@isTest
private class CPQ_ConstantsTest {
    @isTest
    static void testConstantAccess() {
        System.runAs(new user(ID = UserInfo.getUserID())){
            // Accessing the constants in an assertion provides coverage
            System.assertEquals('Diposition Quote', CPQ_Constants.DISPOSITION_QUOTE, 'DISPOSITION_QUOTE constant should match expected value');
            System.assertEquals('Renewal Quote', CPQ_Constants.RENEWAL_QUOTE, 'RENEWAL_QUOTE constant should match expected value');
            System.assertEquals('New', CPQ_Constants.LINE_TYPE_NEW, 'LINE_TYPE_NEW constant should match expected value');
            System.assertEquals('DO NOT DELETE LINES FROM DISPOSITION QUOTE GROUP', CPQ_Constants.DISPOSE_QUOTE_DESCRIPTION, 'DISPOSE_QUOTE_DESCRIPTION constant should match expected value');
            System.assertEquals(false, CPQ_Constants.chatterNotification, 'chatterNotification constant should match expected value');
            System.assertEquals(false, CPQ_Constants.recusriveSendNotification, 'recusriveSendNotification constant should match expected value');
            System.assertEquals('PAYGO', CPQ_Constants.PAYGO, 'PAYGO constant should match expected value');
        }
    }
}