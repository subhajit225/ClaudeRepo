@isTest
public class RoutingUtilTest{


  @isTest
  public static void Routingtest(){ 
        
		
      List<GroupMember> MemeberList = RoutingUtil.getMMQueueMemeberList();
      
      system.debug('MemeberList>>'+MemeberList);
      
      set<ID> UserList = RoutingUtil.getAvailableUsers(MemeberList);
      
      system.debug('UserList>>'+UserList);
      
      Id recordOwnerId = RoutingUtil.generateRandomOwner(UserList);
      
      system.debug('recordOwnerId>>'+recordOwnerId);
       System.assertNotEquals(recordOwnerId, null,'');

  }

}