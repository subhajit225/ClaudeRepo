trigger Jun10LeadAssignment on Lead (before insert) {
    Lead[] leads = Trigger.new;
    List<User> users = [Select User.id FROM USER where User.Alias = 'Mktosync'];
    String marketoUserId = '';
    if (users.size() != 0) {
        marketoUserId = users.get(0).id;
    }
    for (Lead l : leads) {
        if (l.ownerId != marketoUserId && l.Deal_Registration__c == false) {
            continue;
        }
       List<Territory__c> zips = null;
       String postalCode= l.PostalCode;
       if (l.State != null && l.Country != null) { 
           zips = [Select Territory__c.SDR__c, Territory__c.Postal_Code__c, Territory__c.Account_Executive__c FROM Territory__c WHERE Territory__c.State__c = :l.State and Territory__c.City__c = : l.City and Territory__c.Country__c = :l.Country];
       } else {
           postalCode = l.mkto2__Inferred_Postal_Code__c;
           zips = [Select Territory__c.SDR__c, Territory__c.Postal_Code__c, Territory__c.Account_Executive__c FROM Territory__c WHERE Territory__c.State__c = :l.mkto2__Inferred_State_Region__c and Territory__c.City__c = : l.mkto2__Inferred_City__c and Territory__c.Country__c = :l.mkto2__Inferred_Country__c];
       }
       if (zips.size() == 0) {
           continue;
       }
       
       Territory__c leadZip = zips.get(0);
       for (Territory__c zip : zips) {
           if(postalCode == zip.Postal_Code__c) {
               leadZip = zip;
               break;
           }
       }

       if (l.Deal_Registration__c == true && leadZip.Account_Executive__c != null) {
           l.ownerId = leadZip.Account_Executive__c;
       } else if (l.Deal_Registration__c == false && leadZip.SDR__c != null) {
           l.ownerId = leadZip.SDR__c;
       }
    }
 }