global class OpportunityRenewalStatusBatch implements Database.Batchable<sObject>, Database.stateful{
    
    public Set<Opportunity> processedOpptys = new Set<Opportunity>();
    global Database.QueryLocator start(Database.BatchableContext BC){ //and OpportunityId = \'006S0000009yFdQ\' ,Order_Service_Item__r.Product2Id
    /* FOR TEST PURPOSE ONLY
        string entl='5500q00000005G7';
        string whereClause = ' id = \'' + entl + '\' ';
        return Database.getQueryLocator('select id ,Account.name,AccountID  from Entitlement where '+whereClause);
    */
        date triggerDate = System.Today().addMonths(4);
        String StageName = '7 Closed Won';
        String StageNameLost = '7 Closed Lost';
        String StageNameLostAdmin = '7 Closed Admin';
        String OpportunitySubType = 'Renewal';
        String whereclause = 'Opportunity_Sub_Type__c' + ' '  + '=' + ' \'' + OpportunitySubType + '\'' +' AND ('+'StageName' + ' '  + '=' + ' \'' + StageName + '\''+' OR ' +'StageName' + ' '  + '=' + ' \'' + StageNameLost + '\''+' OR ' +'StageName' + ' '  + '=' + ' \'' + StageNameLostAdmin + '\''+')';
        system.debug('String =='+whereclause);
        String OppId= '0064000000oquiz';
        //whereclause +=' AND  id = \'' + OppId + '\' ';
        whereclause +=' AND  Opportunity_Renewal_Status__c = \'\' ';
        system.debug('String =='+whereclause);
        String query = 'select id ,Name, StageName, Opportunity_Renewal_Status__c,CloseDate,Ops_Fiscal_Quarter__c,Renewed_Fiscal_Quarter__c from opportunity where ' + whereclause + (Test.isRunningTest()?' LIMIT 20':'');
        system.debug('String query  =='+query );
        return Database.getQueryLocator(query);
    }
    // Execute Metjod to perform Logic on Batch
    global void execute(Database.BatchableContext BC, List<Opportunity> scope){
        List<Opportunity> UpdatedOppList = new List<Opportunity>();
        try{
      for(Opportunity Opp : Scope){
          String CloseQtr =opp.Ops_Fiscal_Quarter__c.split('-')[0];
          Integer CloseQtrVal = Integer.ValueOf(CloseQtr.substring(1,2));
          Integer CloseYearVal = Integer.ValueOf(opp.Ops_Fiscal_Quarter__c.split('-')[1]);
          
          String RenewalQtr =opp.Renewed_Fiscal_Quarter__c.split('-')[0];
          Integer RenewalQtrVal = Integer.ValueOf(RenewalQtr.substring(1,2));
          Integer RenewalYearVal = Integer.ValueOf(opp.Renewed_Fiscal_Quarter__c.split('-')[1]);
          
          System.debug('CloseQtrVal =='+CloseQtrVal);
          System.debug('CloseYearVal =='+CloseYearVal);
          System.debug('RenewalQtrVal =='+RenewalQtrVal);
          System.debug('RenewalYearVal =='+RenewalYearVal);
          
          if(RenewalYearVal ==CloseYearVal){
            if( RenewalQtrVal ==  CloseQtrVal)
                Opp.Opportunity_Renewal_Status__c = 'On-Time';
            else if( RenewalQtrVal >  CloseQtrVal)
                Opp.Opportunity_Renewal_Status__c = 'Early';
            else
                Opp.Opportunity_Renewal_Status__c = 'Late';
          }
          else if(RenewalYearVal > CloseYearVal){
              Opp.Opportunity_Renewal_Status__c = 'Early';
          }
          else
              Opp.Opportunity_Renewal_Status__c = 'Late';
          
          UpdatedOppList.add(opp);
          system.debug('UpdatedOppList=='+UpdatedOppList);
          
      }
       Database.update(UpdatedOppList,false);
      }
          catch(Exception ex){
           system.debug('Exception occured=='+ex);
          }
    }
      global void finish(Database.BatchableContext processedrecords) {
        /*Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {System.Label.RenewalOpptyAlertRecieversEmail});
        email.setSaveAsActivity(false);
        system.debug('processedOpptys '+processedOpptys);
        String subject = 'Renewal Opportunity Creation';
        email.setSubject(subject);

        String allOpptys='';
        
        for(Opportunity opp : processedOpptys){
            allOpptys += '<tr><td style="text-align:center; vertical-align:middle;">'+opp.Name+'</td><td style="text-align:center; vertical-align:middle;"><a href='+system.URL.getSalesforceBaseUrl().toExternalForm()+'/'+opp.Id+' target="_Blank">Link</a></td></tr>';
        }
        if(allOpptys != ''){
            String tableBody ='<table border="1"><tbody><th>Name</th><th>Detail Link</th>'+allOpptys+'</tbody></table>';
            email.setHTMLBody(System.Label.RenewalOpptyAlertMessage +'<br/><br/>'+ tableBody+'<br/><br/><br/> Thanks');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
        }*/
         AsyncApexJob a = [SELECT Id,Status,JobType,NumberOfErrors,JobItemsProcessed,TotalJobItems,CompletedDate,ExtendedStatus
          FROM AsyncApexJob WHERE Id =:processedrecords.getJobId()];
          List<String> toAddresses = new List<String>();
          toAddresses.add('shadab.hussain@rubrik.com');//toAddresses.add('mudit.agarwal@rubrik.com');
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
           mail.setToAddresses(toAddresses);
           //mail.setTargetObjectId(u.Id);
           mail.setSubject('Renewal Status Batch - ' + a.Status);
           mail.setSaveAsActivity(false);
           mail.setPlainTextBody
           ('The batch Apex job completed on  ' + a.CompletedDate + ',\n\n' +
           'Job Status : ' + a.Status + '\n'+
           'Total Job Items processed : ' + a.TotalJobItems + '\n'+
           'Number of Job Items processed : ' + a.JobItemsProcessed + '\n' +
           'Number of Failures : '+ a.NumberOfErrors);
           Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}