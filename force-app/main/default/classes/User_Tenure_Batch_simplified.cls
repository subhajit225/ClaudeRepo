global class User_Tenure_Batch_simplified implements Database.Batchable<sObject> , Database.stateful{
     global Database.QueryLocator start(Database.BatchableContext BC){
        string whereClause = ' Start_Date__C != null ';
    
        string query= 'Select id, Start_Date__c, User_Tenure__c, User_Prior_Tenure__c from User where'+whereClause +(Test.isRunningTest()?' LIMIT 20':'');
        return Database.getQueryLocator(query);
     }

   global void execute(Database.BatchableContext BC, List<User> scope){
       system.debug('scope=='+scope);
       List<User> updateUserList = new List<USer>();
       for(User user : scope){
            if(user.Start_Date__c != null){
               //get the first Quarter
               Integer totalMonthsWorked = User.Start_Date__c.monthsbetween(system.today())+1;
               
               Integer userStartMonth=User.Start_Date__c.Month();
               Set<Integer> startOfQuarter = new Set<Integer>{2,5,8,11};
               Set<Integer> secondMonthOfQuarter = new Set<Integer>{3,6,9,12};
               Set<Integer> thirdMonthOfQuarter = new Set<Integer>{4,7,10,1};
               Integer todaysMonth = system.today().Month();
               Integer tenure=0;
               Integer mod;
               if(startOfQuarter.contains(userStartMonth)){
                   tenure=totalMonthsWorked/3;
                   mod=Math.mod(totalMonthsWorked,3);
               } else if(secondMonthOfQuarter.contains(userStartMonth)){
                   tenure=(totalMonthsWorked-2)/3;
                   mod=Math.mod(totalMonthsWorked-2,3);
               } else if(thirdMonthOfQuarter.contains(userStartMonth)){
                   tenure=(totalMonthsWorked-1)/3;
                   mod=Math.mod(totalMonthsWorked-1,3);
               }
               system.debug('totalMonthsWorked=='+totalMonthsWorked+ ', userStartMonth='+userStartMonth+' tenure='+tenure+' Mod='+mod);
               if(mod>0){
                   User.User_tenure__c=tenure+1;
               } else {
                   User.User_tenure__c=tenure;
               }
          }
           system.debug('User.User_tenure__c=='+User.User_tenure__c);
           updateUserList.add(User);
       }
       if(!updateUserList.isEmpty()){
           database.update(updateUserList,false);
       }
   }

   global void finish(Database.BatchableContext BC){
   }
}