@isTest
private class MissingEntitlementsController_Test {
	
	@isTest static void testConstructor() {
		MissingEntitlementsController cont = new MissingEntitlementsController();
		System.assertEquals(0, cont.orderItems.size());
		System.assertEquals(0, cont.missingContractOrderItems.size());
	}
}