global class MassEmailFieldUpdaterBatch implements Database.Batchable<sObject> , Database.Stateful{
    global list<string> objectNameList = new list<string>();
    global list<string> fieldNameList = new list<string>();
    global Integer counter;
    
    global MassEmailFieldUpdaterBatch(Integer counter){
        this.counter = counter;
    }
    
    global Database.QueryLocator Start(Database.BatchableContext BC){        
        system.debug('==counter=='+counter);
        

        
        for(EmailMasking__mdt maskingObjects : [SELECT EmailMasking_Object__c,EmailMasking_required__c FROM EmailMasking__mdt Where EmailMasking_required__c = True]){
            objectNameList.add(maskingObjects.EmailMasking_Object__c);            
            System.debug('Object List from Meta Data'+objectNameList);
            
        }
        
        String objectName;
        //objectNameList = new list<string>{'Opportunity', 'Contact'};
        if(!objectNameList.isEmpty() && objectNameList.size() > counter){
           objectName = objectNameList[counter]; 
        }
        
        system.debug('==objectName=='+objectName);        
        
        string filterCondition = '';
        String queryString = 'SELECT Id';
        
        for(Schema.SObjectField field : ((SObject)Type.forName(objectName).newInstance()).getSobjectType().getDescribe().fields.getMap().values()){
            if(Schema.DisplayType.EMAIL == field.getDescribe().getType()){
                fieldNameList.add(field.getDescribe().getName());
                queryString += ', ' + field.getDescribe().getName();
            }
        }
        
        System.debug('**Query String** '+queryString);
        queryString = queryString.removeStart(',');
        
        for(string fieldName : fieldNameList){
            if(String.isBlank(filterCondition)){
                filterCondition = fieldName + ' != null';
            }else{
                filterCondition = filterCondition + ' OR ' + fieldName + ' != null';
            }
        }
        
        queryString = queryString + ' from '+ objectName + ' where ' + filterCondition ;
        
        system.debug('======queryString======='+queryString);
        return Database.getQueryLocator(queryString); 
    }
    
    global void execute (Database.BatchableContext BC, list<Sobject>scope){
        for(sObject s : scope) {
            for(string fieldName : fieldNameList){
                if(s.get(fieldName) != null)
                    
                    system.debug(fieldName + '==values=='+'test' + s.get(fieldName));
                    s.put(fieldName, s.get(fieldName)+'.sandbox');
            }               
        } 
        
      List<Database.SaveResult> dsrs = Database.update(scope, false);
        
    }    
    
    global void finish(Database.BatchableContext bc){
        ++counter;
        system.debug('==counterf=='+counter);
        if(!objectNameList.isEmpty() && objectNameList.size() > counter){
            database.executeBatch(new MassEmailFieldUpdaterBatch(counter));
        }        
    }    
}