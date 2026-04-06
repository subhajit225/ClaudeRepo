public with sharing class RoutingUtil {
    
    public static List<GroupMember> getMMQueueMemeberList() {
        return getMMQueueMemeberList('AMERMM');
    }

    public static List<GroupMember> getMMQueueMemeberList(String Queuename){
        List<GroupMember> MemeberList = new List<GroupMember>();
        MemeberList = [SELECT id,UserOrGroupId,GroupId,Group.DeveloperName FROM GroupMember 
                       WHERE Group.DeveloperName =:Queuename AND Group.Type='Queue'];
        
        return MemeberList;
    }
//MKT23-665: Data Merge Data
     public static List<Group> getFedralQueueMemeberList(){
        List<Group> GroupRecord = new List<Group>();
        GroupRecord = [SELECT id,DeveloperName FROM Group 
                       WHERE DeveloperName ='Federal_Queue' AND Type='Queue'];
        
        return GroupRecord;
    }
    public static Id generateRandomOwner(Set<Id> availableUsers){
        Id recordOwnerId; 
        List<Id> MemeberList = new List<Id>(availableUsers);
        if(MemeberList.size()>0){
            Integer random = Integer.valueof(Math.random() * MemeberList.size());
            System.debug('random>>>'+random);
            //ContactOwnerId = MemeberList[random].UserOrGroupId;
            recordOwnerId = MemeberList[random];
        }
        system.debug('ContactOwnerId>>'+recordOwnerId);
        return recordOwnerId;  
    }
    
    public static DateTime getUTCDateTime(DateTime dt){
        Datetime GMTDate = Datetime.newInstanceGmt(
                                dt.year(),
                                dt.month(),
                                dt.day(),
                                dt.hour(),
                                dt.minute(),
                                dt.second());
        return GMTDate;
    }
    
     public static Set<Id> getAvailableUsers(List<GroupMember> memeberList){ 
        Set<Id> usersAvailable = new Set<Id>();
        Set<Id> usersAvailableOriginal = new Set<Id>();
        if(MemeberList.size()>0){
            for(GroupMember rsMember:MemeberList){
                usersAvailableOriginal.add(rsMember.UserOrGroupId);
            }
            if(usersAvailableOriginal.size()>0) {
                List<User> userRSList = [Select id from user where id IN :usersAvailableOriginal and isActive=true];
                for(User rsus:userRSList){
                   usersAvailable.add(rsus.Id); 
                }
            }
            DateTime myDate = getUTCDateTime(system.now());
            system.debug('myDate--> GMT'+myDate);
            
            Date myDateFinalUTC = date.newinstance(myDate.year(), myDate.month(), myDate.day());
            system.debug('myDateFinalUTC--> '+myDateFinalUTC);
            
            Date myDateFinal = date.today();//.newinstance(myDate.year(), myDate.month(), myDate.day());
            system.debug('myDateFinal--> '+myDateFinal);
            for(PTOCalendar__c ptoCalendar : [SELECT Id,User__c,StartDate__c,EndDate__c 
                                                FROM PTOCalendar__c 
                                                WHERE  User__c IN :usersAvailable 
                                                AND StartDate__c <=: myDateFinal 
                                                AND EndDate__c >=:  myDateFinal 
                                                ORDER BY CreatedDate DESC]){
                usersAvailable.remove(ptoCalendar.User__c);
            } 
        } 
        
        system.debug('usersAvailable>>'+usersAvailable);
        return usersAvailable;
    }
    //MKT24-112 Updates
    public static Map<String,BDMRoutingConfiguration__mdt> getBDMDefaultUserDetails() {
        Map<String,BDMRoutingConfiguration__mdt> resultMap = new Map<String,BDMRoutingConfiguration__mdt>(); 
        List<BDMRoutingConfiguration__mdt> conFigRecord = new List<BDMRoutingConfiguration__mdt>();
        conFigRecord =[Select id,MasterLabel,Federal_BMD_User__c, SLG_BDM_User__c, Default_BDM_User__c  from BDMRoutingConfiguration__mdt];
        for(BDMRoutingConfiguration__mdt rsRecord: conFigRecord) {
           resultMap.put(rsRecord.MasterLabel,rsRecord);  
        }
       return resultMap; 
    }
    
    public static map<String,map<String,Id>> getBDMUserMap(map<String,BDMRoutingConfiguration__mdt> resultMap) {
        map<String,String> resultMapData = new map<String,String>();
        map<String,map<String,Id>> resultMapDataFinal = new map<String,map<String,Id>>();
        map<String,String> userIDS = new map<String,String>();
        map<String,String> defaultUser = new map<String,String>();
        for(String rsKey:resultMap.keyset()) {
            Id eighteenDigitFederalID = resultMap.get(rsKey).Federal_BMD_User__c;
            Id eighteenDigitSLGID = resultMap.get(rsKey).SLG_BDM_User__c; 
            Id eighteenDigitDefaultID = resultMap.get(rsKey).Default_BDM_User__c;
            system.debug('eighteenDigitFederalID>'+eighteenDigitFederalID);
            system.debug('eighteenDigitSLGID>'+eighteenDigitSLGID);
            system.debug('eighteenDigitDefaultID>'+eighteenDigitDefaultID);
            userIDS.put(eighteenDigitFederalID,'FederalBDMUser');
            userIDS.put(eighteenDigitSLGID,'SLGBDMUser');
            defaultUser.put('DefaultUser',eighteenDigitDefaultID);
        }
           system.debug('userIDS>>'+userIDS);
        List<User> checkActiveUser = [Select id,IsActive from User where id IN:userIDS.keyset()];
           system.debug('checkActiveUser>>'+checkActiveUser);
        for(String rsKey:resultMap.keyset()) {
        for(User rs:checkActiveUser){
            String IDval = rs.Id;
            if(userIDS.containsKey(rs.Id) && rs.isActive==true) {
                    resultMapData.put(userIDS.get(rs.Id),rs.Id);  
            } else {
                resultMapData.put(userIDS.get(IDval),defaultUser.get('DefaultUser')); 
                
            }
              resultMapData.put('DefaultUser',defaultUser.get('DefaultUser')); 
        }
            resultMapDataFinal.put(rsKey,resultMapData);    
        } 
        return resultMapDataFinal;
    }
    
}