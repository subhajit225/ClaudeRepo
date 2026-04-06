public class createRenewalCaseController {
    @auraEnabled
    public static mainWrapper checkStatus(String accId){
        CaseTriggerHandler.isRepeat = false;
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
        Id queueId = [select Id from Group where  Type = 'Queue' AND developername= 'Renewal_Queue' LIMIT 1].Id;
        List<Id> scIDList = new List<Id>();
        List<ServiceContract> scWrapperList = new List<ServiceContract>();
        for(ServiceContract sc:[select Id,Name,ContractNumber,Status,StartDate,EndDate,AccountId,Account.Name,SBQQSC__Opportunity__c from ServiceContract where AccountId =:accId]){
            scIDList.add(sc.Id);
            scWrapperList.add(sc);
        }
        mainWrapper scWrapperMap;
        List<scWrapper> resList = new List<scWrapper>();
        Map<Id,Case> oldCase = new Map<Id,Case>();
        if(scWrapperList.size() > 0 && scWrapperList.size() == 1){
            String caseId = '';
            List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id,Partner_Lookup__r.Name,Account.Name,Initial_Contacts_Name__c,Partner_SE_Phone__c,Partner_SE_Email__c,Partner_SE_Name__c, Partner_Lookup__c,Distributor_Rep_Phone_Number__c,Distributor_Rep_Name__c,Distributor_Rep_Email__c, Distributor_Lookup__c FROM Opportunity where Id =: scWrapperList[0].SBQQSC__Opportunity__c]);
            for(Case cs:[select ServiceContractId,CaseNumber from Case where ServiceContractId =:scWrapperList[0].Id ]){
                oldCase.put(cs.ServiceContractId,cs);
                caseId = cs.id;
            }
            if(oldCase.size() == 0){
                case cs;
                String descVal = System.label.Renewal_Case_Desc;
               cs = new Case(
                    RecordTypeId = recordTypeId, 
                    OwnerId = queueId,
                    Priority = 'P4',
                    Status = 'New',
                    Description = descVal.replace('[[Account]]',scWrapperList[0].Account.Name)   ,
                    AccountId = accId,
                    ServiceContractId= scWrapperList[0].Id
                );
                if(!opportunityList.isEmpty()){
                    Opportunity opp =opportunityList[0];
                    cs.Distributer_Account_Name__c =  opp.Distributor_Lookup__c;
                    cs.Distributer_Contact_Phone__c =  opp.Distributor_Rep_Phone_Number__c;
                    cs.Distributer_Contact_Name__c = opp.Distributor_Rep_Name__c;
                    cs.Distributer_Contact_Email__c = opp.Distributor_Rep_Email__c;
                    cs.Partner_Contact_Email__c =  opp.Partner_SE_Email__c;
                    cs.Partner_Contact_Name__c = opp.Partner_SE_Name__c;
                    cs.Partner_Contact_Phone__c = opp.Partner_SE_Phone__c;
                    cs.Partner_Account_Name__c = opp.Partner_Lookup__c;
                    cs.Subject = 'Renewal Case - '+opp.Account.Name;
                    cs.Subject += opp.Partner_Lookup__r.Name == null ? '' :' - '+opp.Partner_Lookup__r.Name;
                    cs.Description = cs.Description.replace('00:00:00','');
                }
                insert cs;
                String num = [Select CaseNumber from Case where Id=:cs.Id].CaseNumber;
                scWrapper srvc = new scWrapper(scWrapperList[0].Id,scWrapperList[0].Name,scWrapperList[0].ContractNumber,scWrapperList[0].Status,scWrapperList[0].Account.Name,scWrapperList[0].AccountId,scWrapperList[0].StartDate,scWrapperList[0].EndDate,num,scWrapperList[0].SBQQSC__Opportunity__c);
                
                resList.add(srvc);
                scWrapperMap = new mainWrapper(cs.Id,resList);   
            }
            else{
                scWrapper srvc = new scWrapper(scWrapperList[0].Id,scWrapperList[0].Name,scWrapperList[0].ContractNumber,scWrapperList[0].Status,scWrapperList[0].Account.Name,scWrapperList[0].AccountId,scWrapperList[0].StartDate,scWrapperList[0].EndDate,oldCase.get(scWrapperList[0].Id).CaseNumber,scWrapperList[0].SBQQSC__Opportunity__c);
                resList.add(srvc);
                scWrapperMap = new mainWrapper(caseId,resList);
            }
        }else if(scWrapperList.size()>1){
            for(Case cs:[select ServiceContractId,CaseNumber from Case where ServiceContractId IN :scIDList]){
                oldCase.put(cs.ServiceContractId,cs);
            }
            for(ServiceContract srvcCont:scWrapperList){
                scWrapper srvc;
                if(oldCase.containsKey(srvcCont.Id)){
                    srvc = new scWrapper(srvcCont.Id,
                                         srvcCont.Name,
                                         srvcCont.ContractNumber,
                                         srvcCont.Status,
                                         srvcCont.Account.Name,
                                         srvcCont.AccountId,
                                         srvcCont.StartDate,
                                         srvcCont.EndDate,
                                         oldCase.get(srvcCont.Id).CaseNumber,srvcCont.SBQQSC__Opportunity__c);
                }else{
                    srvc = new scWrapper(srvcCont.Id,
                                         srvcCont.Name,
                                         srvcCont.ContractNumber,
                                         srvcCont.Status,
                                         srvcCont.Account.Name,
                                         srvcCont.AccountId,
                                         srvcCont.StartDate,
                                         srvcCont.EndDate,
                                         null,srvcCont.SBQQSC__Opportunity__c);
                }
                
                resList.add(srvc);
            }
            scWrapperMap = new mainWrapper(null,resList);
        }
        system.debug(scWrapperMap);
        return scWrapperMap;
    }
    @AuraEnabled
    public static csNumWrapper createCase(String sc){
        scWrapper srvcContrct = (scWrapper)System.JSON.deserialize(sc, scWrapper.class);
        List<Opportunity> opportunityList = new List<Opportunity>([SELECT Id,Account.Name,Partner_Lookup__r.Name,Partner_SE_Phone__c,Initial_Contacts_Name__c,Partner_SE_Email__c,Partner_SE_Name__c, Partner_Lookup__c,Distributor_Rep_Phone_Number__c,Distributor_Rep_Name__c,Distributor_Rep_Email__c, Distributor_Lookup__c FROM Opportunity where Id =: srvcContrct.Opp]);
        CaseTriggerHandler.isRepeat = false;
        Id queueId = [select Id from Group where  Type = 'Queue' AND developername= 'Renewal_Queue' LIMIT 1].Id;
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Renewal Case').getRecordTypeId();
        List<Case> oldCase = [select id,Case.CaseNumber from Case where ServiceContractId =:srvcContrct.scId ];
        csNumWrapper res;
        String descVal = System.label.Renewal_Case_Desc;

        if(oldCase.size() == 0){
            case cs = new Case(
                RecordTypeId = recordTypeId, 
                OwnerId = queueId,
                Priority = 'P4',
                Status = 'New',
                Description = descVal.replace('[[Account]]',srvcContrct.AccountName) ,
                AccountId = srvcContrct.AccountId,
                ServiceContractId= srvcContrct.scId
            );
            if(!opportunityList.isEmpty()){
                Opportunity opp =opportunityList[0];
                cs.Distributer_Account_Name__c =  opp.Distributor_Lookup__c;
                cs.Distributer_Contact_Phone__c =  opp.Distributor_Rep_Phone_Number__c;
                cs.Distributer_Contact_Name__c = opp.Distributor_Rep_Name__c;
                cs.Distributer_Contact_Email__c = opp.Distributor_Rep_Email__c;
                cs.Partner_Contact_Email__c =  opp.Partner_SE_Email__c;
                cs.Partner_Contact_Name__c = opp.Partner_SE_Name__c;
                cs.Partner_Contact_Phone__c = opp.Partner_SE_Phone__c;
                cs.Partner_Account_Name__c = opp.Partner_Lookup__c;
                cs.Subject = 'Renewal Case - '+opp.Account.Name;
                cs.Subject += opp.Partner_Lookup__r.Name == null ? '' :' - '+opp.Partner_Lookup__r.Name;
                cs.Description = cs.Description.replace('00:00:00','');
            }
            insert cs;
            CaseTriggerHandler.createSupportLogicRecords(new Set<Id>{cs.Id});
            String num = [Select CaseNumber from Case where Id=:cs.Id].CaseNumber;
            res = new csNumWrapper(cs.Id,num);
        }else{
            res = new csNumWrapper(oldCase[0].id,oldCase[0].CaseNumber);
        }
        
        return res;
    }
    
    public class mainWrapper{
        @auraEnabled
        public string csId{get; set;}
        @auraEnabled
        public List<scWrapper> serviceContrList{get; set;}
        
        public mainWrapper(string csId,List<scWrapper> serviceContrList){
            this.csId = csId;
            this.serviceContrList = serviceContrList;
        }
    }
    public class csNumWrapper{
        @auraEnabled
        public string csId{get; set;}
        @auraEnabled
        public string caseId{get; set;}
        @auraEnabled
        public string csNum{get; set;}
        
        public csNumWrapper(String csId,String csNum){
            this.csId = csId;
            this.csNum = csNum;
        }
    }
    public class scWrapper{
        @auraEnabled
        public string scId{get; set;}
        @auraEnabled
        public string Name{get; set;}
        @auraEnabled
        public string ContractNumber{get;set;}
        @auraEnabled
        public string Status{get;set;}
        @auraEnabled
        public string AccountId{get;set;}
        @auraEnabled
        public string AccountName{get;set;}
        @auraEnabled
        public Date StartDate{get;set;}
        @auraEnabled
        public Date EndDate{get;set;}
        @auraEnabled
        public string CaseNumber{get;set;}
        @auraEnabled
        public string Opp{get;set;}
        
        public scWrapper(string scId,string Name,string ContractNumber,string Status,string AccountName,string AccountId,Date StartDate,Date EndDate,string CaseNumber,string Opp){
            this.scId = scId;
            this.Name = Name;
            this.ContractNumber = ContractNumber;
            this.Status = Status;
            this.AccountId = AccountId;
            this.AccountName = AccountName;
            this.StartDate = StartDate;
            this.EndDate = EndDate;
            this.CaseNumber = CaseNumber;
            this.Opp = Opp;
        }
    }
}