public class PC_319InsightWebServiceCallOut {
    public static PC_319InsightWebService.companyData deployToCompany;
    public static PC_319InsightWebService.contactData deployToContact;
    public static PC_319InsightWebService.contactData sponsorContact;
    public static PC_319InsightWebService.additionalField[] dataBuilderField;
    public static string uname = '564$API';
    public static string pwd ='n1kwmsqu';
    public static string contactFirstName = 'Larry';
    public static string contactLastName = 'Guo';
    public static string contactEmail = Label.PC_319CalloutApexEmail;
    public static string DEPLOYED = 'DEPLOYED';
    public static string SUCCESS = 'success';
    public static string FAILED = 'Failed';
    public static boolean stoprecurssion = false;

    public static void mainRequest(List<String> pobIdList){
        String pobId = pobIdList[0];
		sendCallout(pobId);
    }

    @future(callout=true)
    public static void sendCallout(String pobId){
        List<String> tempList = new List<String>();

        Partner_Onboarding_Request__c pobRec = [SELECT Id,Company_Name__c,Country__c,StateProvince__c,City__c,Address_1__c,Address_2__c,Postal_Code__c,
                                                First_Name__c,Last_Name__c,Email__c,Partner_Selling_Countries__c,Employed_by_Gov_Entity__c,Sell_to_Gov_Entities__c,
                                                Violation_of_Anti_Corruption_Laws__c,FCPAPP__c,Rubrik_Relationship__c //PRIT25-129
                                                FROM Partner_Onboarding_Request__c
                                                WHERE Id =: pobId];

        List<Connection_Config__mdt> credsList = new List<Connection_Config__mdt>();
        Map<String,String> countrycodeMap = new Map<String,String>();

        for(Country_Code_319_API__c cc: [SELECT Id,Name,Country_Code__c
                                        FROM Country_Code_319_API__c]){
            countrycodeMap.put(cc.Name,cc.Country_Code__c);
        }

        credsList = [SELECT Id,DeveloperName,User_Name__c,Password__c
                    FROM Connection_Config__mdt
                    WHERE DeveloperName='Insight_319'];

        if(!credsList.isEmpty()){
            uname = credsList[0].User_Name__c;
            pwd = credsList[0].Password__c;
        }

        deployToCompany = new PC_319InsightWebService.companyData();
        deployToCompany.companyName = pobRec.Company_Name__c;
        if(!countrycodeMap.isEmpty() && countrycodeMap.containskey(pobRec.Country__c)){
            deployToCompany.companyCountry = countrycodeMap.get(pobRec.Country__c);
        }else{
        	deployToCompany.companyCountry = pobRec.Country__c;
        }
        deployToCompany.companyState = pobRec.StateProvince__c;
        deployToCompany.companyCity = pobRec.City__c;

        deployToCompany.companyField = new List<PC_319InsightWebService.additionalField>();

        PC_319InsightWebService.additionalField companyAddress1 = new PC_319InsightWebService.additionalField();
        companyAddress1.fieldId = 'companyAddress1';
        companyAddress1.fieldValue = new List<String>{pobRec.Address_1__c};
        deployToCompany.companyField.add(companyAddress1);

        PC_319InsightWebService.additionalField companyAddress2= new PC_319InsightWebService.additionalField();
        companyAddress2.fieldId = 'companyAddress2';
        companyAddress2.fieldValue = new List<String>{pobRec.Address_2__c};
        deployToCompany.companyField.add(companyAddress2);

        PC_319InsightWebService.additionalField companyZIP= new PC_319InsightWebService.additionalField();
        companyZIP.fieldId = 'companyZIP';
        companyZIP.fieldValue = new List<String>{pobRec.Postal_Code__c};
        deployToCompany.companyField.add(companyZIP);

        PC_319InsightWebService.additionalField SalesForceID= new PC_319InsightWebService.additionalField();
        SalesForceID.fieldId = 'SalesForceID';
        SalesForceID.fieldValue = new List<String>{pobId};
        deployToCompany.companyField.add(SalesForceID);

        PC_319InsightWebService.additionalField GovEntity= new PC_319InsightWebService.additionalField();
        GovEntity.fieldId = 'GovEntity';
        GovEntity.fieldValue = new List<String>{pobRec.Employed_by_Gov_Entity__c};
        deployToCompany.companyField.add(GovEntity);

        PC_319InsightWebService.additionalField SelltoGovEntities= new PC_319InsightWebService.additionalField();
        SelltoGovEntities.fieldId = 'SelltoGovEntities';
        SelltoGovEntities.fieldValue = new List<String>{pobRec.Sell_to_Gov_Entities__c};
        deployToCompany.companyField.add(SelltoGovEntities);

        PC_319InsightWebService.additionalField ViolationAC= new PC_319InsightWebService.additionalField();
        ViolationAC.fieldId = 'ViolationAC';
        ViolationAC.fieldValue = new List<String>{pobRec.Violation_of_Anti_Corruption_Laws__c};
        deployToCompany.companyField.add(ViolationAC);

        PC_319InsightWebService.additionalField FCPAPP= new PC_319InsightWebService.additionalField();
        FCPAPP.fieldId = 'FCPAPP';
        FCPAPP.fieldValue = new List<String>{pobRec.FCPAPP__c};
        deployToCompany.companyField.add(FCPAPP);

        //PRIT25-129-start
        PC_319InsightWebService.additionalField RubrikRelationship= new PC_319InsightWebService.additionalField();
        RubrikRelationship.fieldId = 'RubrikRelationship';
        RubrikRelationship.fieldValue = new List<String>{pobRec.Rubrik_Relationship__c};
        deployToCompany.companyField.add(RubrikRelationship);
        //PRIT25-129-end

        deployToContact= new PC_319InsightWebService.contactData();
        PC_319InsightWebService.contactName contactName = new PC_319InsightWebService.contactName();
        contactName.firstName = pobRec.First_Name__c;
        contactName.middleName = '';
        contactName.lastName = pobRec.Last_Name__c;
        deployToContact.contactName  = contactName ;
        deployToContact.contactEmail = pobRec.Email__c;

        sponsorContact= new PC_319InsightWebService.contactData();
        PC_319InsightWebService.contactName contactName1 = new PC_319InsightWebService.contactName();
        contactName1 .firstName = contactFirstName;
        contactName1.middleName = '';
        contactName1.lastName = contactLastName;
        sponsorContact.contactName  = contactName1;
        sponsorContact.contactEmail = contactEmail;

       /* dataBuilderField= new List<PC_319InsightWebService.additionalField>();
        PC_319InsightWebService.additionalField PartnerSellingCountries= new PC_319InsightWebService.additionalField();
        PartnerSellingCountries.fieldId = 'PartnerSellingCountries';
        if(!countrycodeMap.isEmpty() && countrycodeMap.containskey(pobRec.Country__c)){
            PartnerSellingCountries.fieldValue = new List<string>{countrycodeMap.get(pobRec.Country__c)};
        }else{
            PartnerSellingCountries.fieldValue = new List<string>{pobRec.Country__c};
        }
        dataBuilderField.add(PartnerSellingCountries);*/

        PC_319InsightWebService.DataBuilderWebServicePort cons = new PC_319InsightWebService.DataBuilderWebServicePort();
        PC_319InsightWebService.AuthHeader authHeader = new PC_319InsightWebService.AuthHeader();
        authHeader.username = uname;
        authHeader.password = pwd;
        cons.authHeader = authHeader;
        cons.timeout_x = 40000;
        system.debug('****deployToCompany'+ deployToCompany);

        try{
            if(Test.isRunningTest()){
		Test.setMock(WebServiceMock.class, new PC_319InsightWebServiceMock());
	    }
            PC_319InsightWebService.deployDataBuilderResponse response = cons.deployDataBuilder(pobId,76,deployToCompany,deployToContact,sponsorContact,dataBuilderField);
            system.debug('@@ response @@ '+response);

            if(response!= null && response.deployStatus == DEPLOYED && response.status == SUCCESS){
                stoprecurssion = true;
                if(Test.isRunningTest()){
                    Test.setMock(WebServiceMock.class, new PC_319InsightWebServiceMock2());
                }
                sendSecondCallout(pobId);
            }else if(response == null || response.status != SUCCESS){
                Partner_Onboarding_Request__c pob = new Partner_Onboarding_Request__c(Id=pobId,X319_API_Status__c=FAILED);
                stoprecurssion = true;
                update pob;
            }
        }catch(Exception e){
            Partner_Onboarding_Request__c pob = new Partner_Onboarding_Request__c(Id=pobId,X319_API_Status__c=FAILED);
            stoprecurssion = true;
            update pob;
        }
    }

   /* public static void secondRequest(List<string> pobIdList){
         string pobId = pobIdList[0];
         stoprecurssion = true;
		 sendSecondCallout(pobId);
    }*/

    //@future(callout=true)
    public static void sendSecondCallout(string pobId){
        List<Connection_Config__mdt> credsList = new List<Connection_Config__mdt>();
        Boolean updatePOB = false;
        credsList = [SELECT Id,DeveloperName,User_Name__c,Password__c from Connection_Config__mdt
                        WHERE DeveloperName='Insight_319'];

        if(!credsList.isEmpty()){
            uname = credsList[0].User_Name__c;
            pwd = credsList[0].Password__c;
        }

        PC_319InsightWebService.DataBuilderWebServicePort cons = new PC_319InsightWebService.DataBuilderWebServicePort();
        PC_319InsightWebService.AuthHeader authHeader = new PC_319InsightWebService.AuthHeader();
        authHeader.username = uname;
        authHeader.password = pwd;
        cons.authHeader = authHeader;
        Partner_Onboarding_Request__c pob;

        try{
            PC_319InsightWebService.requestDataBuilderResponse response = cons.requestDataBuilder(pobId,null);
            //PC_319InsightWebService.deployDataBuilderResponse response = cons.lastDeployDataBuilderResult(pobId);
            system.debug('@@ response @@ '+response);
            if(response != null && response.status == SUCCESS && !string.isBlank(response.fileStatus)){
                pob = new Partner_Onboarding_Request__c(Id=pobId,X319_API_Status__c=response.fileStatus,Trade_Compliance_Screened__c=true);
                stoprecurssion = true;
                update pob;
            }else{
                pob = new Partner_Onboarding_Request__c(Id=pobId,X319_API_Status__c=FAILED);
                stoprecurssion = true;
                update pob;
            }
    	}catch(Exception e){
            pob = new Partner_Onboarding_Request__c(Id=pobId,X319_API_Status__c=FAILED);
            stoprecurssion = true;
            update pob;
        }
        List<Group> queueList = [SELECT Id,developername
                                FROM Group
                                WHERE developername='X319_waiting_queue'];

        if(!queueList.isEmpty()){
            Set<Id> pIds = (new Map<Id, ProcessInstance>([SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId = :pobId])).keySet();
            Set<Id> pInstanceWorkitems = (new Map<Id, ProcessInstanceWorkitem>([SELECT Id,ProcessInstanceId
                                                                                FROM ProcessInstanceWorkitem
                                                                                WHERE ProcessInstanceId in :pIds AND OriginalActorId =:queueList[0].Id])).keySet();
            for(Id networkId :pInstanceWorkitems){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setComments('319 API Status: ' + pob.X319_API_Status__c);
                req.setAction('Approve');
                req.setNextApproverIds(new Id[] {UserInfo.getUserId()});//queueList[0].Id
                req.setWorkitemId(networkId);
                // Submit the request for approval
                Approval.ProcessResult result =  Approval.process(req);
            }
        }
    }
}