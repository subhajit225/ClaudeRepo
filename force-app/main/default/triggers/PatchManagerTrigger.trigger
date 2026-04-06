trigger PatchManagerTrigger on PatchManager__c (before insert, before update) {
    Map<String, PatchManager__c> pmMap = new Map<String, PatchManager__c>();
    set<String> setZipcode= new set<String>();
    set<String> setCity= new set<String>();
    set<String> setState= new set<String>();
    set<String> setObjType= new set<String>();
    
    for (PatchManager__c pm : System.Trigger.new) {
        String strCSZ='';
        if ((pm.City__c != null) && 
            (System.Trigger.isInsert || (pm.City__c != System.Trigger.oldMap.get(pm.Id).City__c))) {
            setCity.add(pm.City__c);
                strCSZ+=pm.City__c;
        }
        if ((pm.State__c!=null) && 
            (System.Trigger.isInsert || (pm.State__c != System.Trigger.oldMap.get(pm.Id).State__c))) {
            setState.add(pm.State__c);
                strCSZ+=pm.State__c;
        }
        if ((pm.Zip_code__c != null) && 
            (System.Trigger.isInsert || (pm.Zip_code__c != System.Trigger.oldMap.get(pm.Id).Zip_code__c))) {
                String oType = (pm.Object_Type__c == null) ? '' : pm.Object_Type__c;
            if (pmMap.containsKey('zip@'+pm.Zip_code__c+oType)) {
                pm.Zip_code__c.addError('Another new patch manager has the same zip code.');
            } else {
                if(pm.Object_Type__c!=null){
                    pmMap.put('zip@'+pm.Zip_code__c+pm.Object_Type__c, pm);
                }
                else{
                    pmMap.put('zip@'+pm.Zip_code__c, pm);
                }
                    
            }
            setZipcode.add(pm.Zip_code__c);
                strCSZ+=pm.Zip_code__c+oType;
                if(pm.Object_Type__c != null) {
                    setObjType.add(pm.Object_Type__c);
                }
       }
       if(strCSZ!='' && !(setZipcode.contains(strCSZ))){
            pmMap.put(strCSZ, pm);
        }
      
    }
    Boolean isfilterApplied=false;
    String soqlStatment = 'select SIC__c,City__c,Object_Type__c,State__c,Zip_code__c from PatchManager__c where';
        if(!setZipcode.isEmpty()){
            if(!setObjType.isEmpty())
                soqlStatment += ' (Zip_code__c in :setZipcode AND Object_Type__c in :setObjType) OR';
            else
                soqlStatment += ' Zip_code__c in :setZipcode OR';
            isfilterApplied=true;
        }
        if(!setCity.isEmpty()){
            soqlStatment += ' City__c in :setCity OR'; 
            isfilterApplied=true;
        }
        if(!setState.isEmpty()){
            soqlStatment += ' State__c in :setState OR';
            isfilterApplied=true;
        }
        
        if(isfilterApplied==true){
            soqlStatment=soqlStatment.removeEnd('OR');
            List<PatchManager__c> listPManager = Database.query(soqlStatment);
            for (PatchManager__c pm : listPManager) {
                if (pm.Zip_code__c != null) {
                        if (pmMap.containsKey('zip@'+pm.Zip_code__c)) {
                            PatchManager__c newPm = pmMap.get('zip@'+pm.Zip_code__c);
                            newPm.Zip_code__c.addError('A patch manager with this zip code already exists.');
                        } 
                }
                if(pm.City__c != null && pm.State__c!=null  && pm.Zip_code__c==null){
                    if (pmMap.containsKey(pm.City__c+pm.State__c)) {
                        PatchManager__c newPm = pmMap.get(pm.City__c+pm.State__c);
                        newPm.addError('A patch manager with city and state already exists.');
                    } 
                }else{
                    if(pm.City__c != null && pm.State__c==null){
                        if (pmMap.containsKey(pm.City__c)) {
                            PatchManager__c newPm = pmMap.get(pm.City__c);
                            newPm.addError('A patch manager with city already exists.');
                        } 
                    }
                }
            }
        }
}