@isTest
public class ManageDomainsControllerTest {
    static testMethod void testName() {
        ManageDomainsController.getDomains();
        ManageDomainsController.addDomains(new List<ManageDomainsController.domainClass>{new ManageDomainsController.domainClass('test.cm','test.cm')});
        ManageDomainsController.addDomains(new List<ManageDomainsController.domainClass>{new ManageDomainsController.domainClass('test.cm','test.cm')});
        ManageDomainsController.getDomains();
    }
}