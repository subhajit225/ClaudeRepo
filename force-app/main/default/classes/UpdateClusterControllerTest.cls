@isTest
public class UpdateClusterControllerTest {

       private static testMethod void Test_Method1() {
           Account ac = new account(name='test');
           insert ac; 
           
           Case cs = new Case();
           cs.AccountId = String.ValueOf(ac.id);
           cs.Status='New';
           cs.Origin = 'Pulse';
           cs.Priority = 'P4';
           insert cs;
           
           Cluster__c cl = new Cluster__c();
           cl.Name = '3d04e794-c526-400b-b652-a513a0f07c83';
           cl.tag__c = 'VREC489FBC898';
           cl.software_version__c = '4.0.2-374';
           cl.archived__c = false;
           cl.account__c = cs.AccountId;
           cl.uuid__c = '3d04e794-c526-400b-b652-a513a0f07c83';
           insert cl;   
           
           Cluster_registration__c clus = new Cluster_registration__c(cluster_UUID__c = '3d04e794-c526-400b-b652-a513a0f07c83');
           insert clus;
           ApexPages.StandardController sc = new ApexPages.StandardController(cl);

           UpdateClusterController con = new UpdateClusterController(sc);
           con.updateCluster();
       }
}