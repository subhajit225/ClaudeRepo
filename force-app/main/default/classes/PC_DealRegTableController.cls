public with sharing class PC_DealRegTableController {
    private static String conditions='';
    private static String engagementRecId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByDeveloperName().get('Engagement').getRecordTypeId();
	/** Description :  This is a generic method is used for records of any sobject. 
					   Fields are queried dynamically based on paramter passed to this method. 
					   It includes Pagination and Sorting logic as well. Currently used for fetching Deal Registration.
		Retrun type :  List<Sobject> - It returns List of records of a particular sobject. Currently used for Deal Registration.
		Parameters  :  searchText - used for searching records which contains this value.
					   returnFields - contains comma separated Fields API names of an sobject.
					   objType - contains Sobject Name.
					   pageSize - Used for Pagination to determines page size.
					   fieldapiName - this paramter determines sorting is based on which field.
					   sortedDirection - determines the direction of sorting.
					   sortedByValue - used in sorting. This value determines records which needs to be queried next.
					   IdSet - contains Set of Id's of sobject records which are already queried and shown on Page.
					   startDate - based on fiscal year selected
					   endDate - based on fiscal year selected
					   accIds - based on account selected from account hierarchy filter
	**/				   
    @AuraEnabled
    public static List<sobject> getRecords(string searchText,string returnFields,string objType, Integer pageSize,string fieldapiName,string sortedDirection,String sortedByValue, List<string> IdSet, String startDate, String endDate, List<String> accIds) {
        List<sobject> finalList = new List<sobject>();
        try{
            system.debug('@@ sortedByValue '+sortedByValue);
            String searchQuery = '';
            Schema.DisplayType fieldType;
            if(pageSize == null){
                pageSize = 10;
            }	
            if(string.isBlank(sortedDirection)){
                sortedDirection = 'desc';
            }
            if(string.isBlank(fieldapiName)){
                sortedDirection = 'Name';
            }
			Map<string,Schema.DisplayType> fieldTypeMap = new Map<string,Schema.DisplayType>();
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Schema.SObjectType ctype = gd.get(objType); 
            Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();   
            
            User loggedInUser = [select Id,name,contact.account.Type,accountId,userrole.Name,Profile.Name,Contact.Primary_Role__c from User where Id =: userinfo.getUserId()];
	    Id usrId = loggedInUser.Id;
	    Boolean communityManager = loggedInUser.Profile.Name == 'Rubrik Partner Community Manager' ? true : false;
            
            searchQuery = 'SELECT '+ String.escapeSingleQuotes(returnFields) +' FROM '+ String.escapeSingleQuotes(objType) +' WHERE RecordTypeId !=: engagementRecId ';
            if(String.isNotBlank(sortedByValue) && String.isNotBlank(fieldapiName) && fmap != null && !fmap.isEmpty() && fmap.containskey(fieldapiName) && (Schema.DisplayType.Date == fmap.get(fieldapiName).getDescribe().getType() || Schema.DisplayType.DATETIME == fmap.get(fieldapiName).getDescribe().getType() || Schema.DisplayType.INTEGER == fmap.get(fieldapiName).getDescribe().getType())) {
                searchQuery += ' WHERE ' + String.escapeSingleQuotes(fieldapiName) + (sortedDirection == 'desc' ? ' <= ' : ' >= ' ) + String.escapeSingleQuotes(sortedByValue);
            }else if(String.isNotBlank(sortedByValue) && String.isNotBlank(fieldapiName) && fmap != null && !fmap.isEmpty() && fmap.containskey(fieldapiName) && (Schema.DisplayType.String == fmap.get(fieldapiName).getDescribe().getType() || fmap.get(fieldapiName).getDescribe().getType() == null || fmap.get(fieldapiName).getDescribe().getType() == Schema.DisplayType.PICKLIST)){
                searchQuery += ' WHERE ' + String.escapeSingleQuotes(fieldapiName) + (sortedDirection == 'desc' ? ' <= ' : ' >= ' ) +'\''+ String.escapeSingleQuotes(sortedByValue) +'\''; 
            }
            if(IdSet != null && !IdSet.isEmpty()){   
                searchQuery += (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + ' Id NOT IN : IdSet';
            }
             String userId = UserInfo.getUserID();
         
            if(!string.isBlank(searchText) && searchText.length() >= 1){
                String searchStr1 = '*'+searchText+'*';
                searchManagers(searchText,returnFields,fmap);
               	searchQuery = searchQuery+ (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') +conditions;
            }
            //PRIT-489-start
            if(!string.isBlank(startDate) && startDate.length() > 0){
                Date startDateConv = Date.valueOf(startDate);
                searchQuery = searchQuery + (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + 'Deal_Reg_Submitted_Date__c >=: startDateConv';
            }
            if(!string.isBlank(endDate) && endDate.length() > 0){
                Date endDateConv = Date.valueOf(endDate);
                searchQuery = searchQuery + (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + 'Deal_Reg_Submitted_Date__c <=: endDateConv';
            }
            if(accIds != null && accIds.size() > 0){
                searchQuery = searchQuery + (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + 'Partner_Lookup__c IN : accIds';
            }
	    if(!communityManager){
		searchQuery += (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + ' CreatedById = :usrId';
	    }
			
            searchQuery = searchQuery+' ORDER BY '+ String.escapeSingleQuotes(fieldapiName) +' '+ String.escapeSingleQuotes(sortedDirection) +' NULLS ' + ((sortedDirection == 'desc') ? 'LAST' : 'FIRST') + ' LIMIT '+ pageSize;
            
            system.debug('@@ searchQuery '+searchQuery);
            finalList = database.query(searchQuery);
            system.debug('@@ finalList '+finalList); 
        }catch(Exception e){
            system.debug('Exception occurred '+e.getMessage()+' at line '+e.getLineNumber());
        }
        return finalList;
    }
	
	/** Description :  This is method is used for searching records. It is used to build dynamic query for by 
					   considering fields on which search has be done.				   
		Retrun type :  List<SelectOption> - It returns List of selectoptions on which search is performed
		Parameters  :  returnFields - returnFields - contains comma separated Fields API names of an sobject.
					   fmap - contains schema of a sobject using which we determine type of a field
	**/	
    public static List<SelectOption> getsearchByList(string returnFields, Map<String, Schema.SobjectField> fmap){
        List<SelectOption> selOp = new List<SelectOption>();
        List<string> tempList = new List<string>();
        if(returnFields != null && returnFields != '' && returnFields.contains(',')){
            tempList = returnFields.split(',');
        }
        for(string op : tempList){
            if(op != 'Id' && fmap != null && !fmap.isEmpty() && fmap.containskey(op) && (fmap.get(op).getDescribe().getType()  == Schema.DisplayType.String || fmap.get(op).getDescribe().getType() == Schema.DisplayType.PICKLIST)){
                selOp.add(new SelectOption(op,op));
            }
        }
        return selOp;
    }
	
	/** Description :  This is method is used for searching records. It is used for 
					   forming where clause of dynamic soql.				   
		Retrun type :  void
		Parameters  :  searchText - used for searching records which contains this value.
					   returnFields - returnFields - contains comma separated Fields API names of an sobject.
					   fmap - contains schema of a sobject using which we determine type of a field
	**/
    public static void searchManagers(string searchText,string returnFields, Map<String, Schema.SobjectField> fmap){
        conditions='';     
			
        for(SelectOption so : getsearchByList(returnFields,fmap)){
            String item = so.getValue();
            String searchItem = searchText.trim();
            searchItem = String.escapeSingleQuotes(searchItem);
            conditions +=' OR '+ String.escapeSingleQuotes(item) + ' like \'%' + String.escapeSingleQuotes(searchItem) + '%\'';
        }
        
        conditions = conditions.removeStart(' OR ');
        conditions = '(' + conditions + ')'; 
        system.debug('conditions=> '+conditions);
    }
	
	/** Description :  This is method is used for getting total size of records in an sobject.
		Retrun type :  Integer - contains size of records
		Parameters  :  objType - contains Sobject Name.
	**/
    @AuraEnabled
    public static Integer getTotalRecords(string objType){
        Integer totalrecs = 0;
        String searchQuery = '';
        searchQuery = 'SELECT COUNT(Id) total FROM '+ String.escapeSingleQuotes(objType);
        for(AggregateResult result : database.query(searchQuery)){
            totalrecs+=(Integer)result.get('total');
        }
        return totalrecs;
    }
    
    @AuraEnabled
    public static boolean checkAccess(string recId){
        system.debug('@@ recId '+recId);
        boolean showDetails = true;
        User loggedInUser = [select Id,name,contact.account.Type,accountId,Profile.Name,Contact.Account.Focused_Partner__c from User where Id =: userinfo.getUserId()];
        List<Deal_Registration__c> record  = [select Id,CreatedById,Distributor__c,Partner_Lookup__c from Deal_Registration__c where Id =: recId];
        
        if(loggedInUser.contact.account.Type == 'Distributor' && loggedInUser.Profile.Name.contains('Manager') && record != null && record.size() > 0 && record[0].Distributor__c == loggedInUser.accountId && !loggedInUser.Contact.Account.Focused_Partner__c){
            showDetails = true;
        }else if(loggedInUser.contact.account.Type != 'Distributor' && loggedInUser.Profile.Name.contains('Manager') && record != null && record.size() > 0 && record[0].Partner_Lookup__c == loggedInUser.accountId){
           showDetails = true;
        }else if(record != null && record.size() > 0 && record[0].CreatedById == loggedInUser.Id){
            showDetails = true;
        }else{
            showDetails = false;
        }
       
        return showDetails;
    }

    @AuraEnabled
    public static User getPartnerType(){
        User loggedInUser = [SELECT Id,Name,Contact.Account.Type,AccountId,Profile.Name,Contact.Account.Focused_Partner__c FROM User WHERE Id =: userinfo.getUserId() LIMIT 1];
        return loggedInUser;
    }

    /** Description :  This method is used for showing records on deal reg highlight report
		Return type :  DealRegWrapper - wrapper of list, integer, integer
		Parameters  :  None
	**/
    @AuraEnabled
    public static DealRegWrapper getDealRegData(){
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        DealRegWrapper dealRegWrap = new DealRegWrapper();
        Integer submittedDRCount = 0;
        Integer approvedDRCount = 0;

        try{
            User partnerUser = [SELECT Id, Name, Contact.AccountId, Contact.Primary_Role__c, Contact.Account.Type, Profile.name
                                FROM User
                                WHERE Id=:UserInfo.getUserId()];
            Id partnerAccountId = partnerUser != null ? partnerUser.Contact.AccountId : null;
            Id partnerUserId = partnerUser.Id;
            //JIRA PRIT24-255
            Boolean communityManager = partnerUser.Profile.name == 'Rubrik Partner Community Manager' ? true : false;

            if(partnerAccountId != null){
                List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
                String queryDR = 'SELECT Id, Name, Company__c, Registration_Type__c, Opportunity__c, Deal_Registration_Status__c, Deal_Registration_Expiration__c, Deal_Reg_Submitted_Date__c FROM Deal_Registration__c WHERE Deal_Reg_Submitted_Date__c = THIS_FISCAL_YEAR AND RecordTypeId !=: engagementRecId ';
                if(partnerUser.Contact.Account.Type == 'Distributor' && !communityManager){
                    queryDR = queryDR + 'AND Distributor__c =:partnerAccountId AND CreatedById =:partnerUserId';
                }else if(partnerUser.Contact.Account.Type != 'Distributor' && !communityManager){
                    queryDR = queryDR + 'AND Partner_Lookup__c =:partnerAccountId AND CreatedById =:partnerUserId';
                }else if(partnerUser.Contact.Account.Type == 'Distributor' && communityManager){
                    queryDR = queryDR + 'AND Distributor__c =:partnerAccountId';
                }else{
                    queryDR = queryDR + 'AND Partner_Lookup__c =:partnerAccountId';
                }
                queryDR = queryDR + ' ORDER BY Deal_Registration_Expiration__c ASC';
                
                system.debug('@@ searchQuery '+queryDR);
                deals = database.query(queryDR);
                for(Deal_Registration__c deal : deals){
                    if(deal.Deal_Registration_Status__c == 'Approved'){
                        approvedDRCount++;
                    }
					if(deal.Deal_Registration_Status__c == 'Submitted'){
						submittedDRCount++;
                    }
                    if((deal.Deal_Registration_Status__c == 'Approved' || deal.Deal_Registration_Status__c == 'Submitted') && dealRegList.size() < 6){
                        dealRegList.add(deal);
                    }
                }
            }
        }
        catch(Exception e){
            system.debug('error'+ e.getMessage());
        }
        dealRegWrap.dealRegList = dealRegList;
        dealRegWrap.submittedDRCount = submittedDRCount;
        dealRegWrap.approvedDRCount = approvedDRCount;
        return dealRegWrap;
    }
    
    @AuraEnabled
    public static List<FiscalYearSettings> getFiscalYearData(){
        List<FiscalYearSettings> fiscalYearList = PC_PortalNavigationApexController.getFiscalYear();
        return fiscalYearList;
    }
    
    /**
    * @description This method is used for showing records on DR Managed Service Engagements.
    * @param searchText Any search text for filtering the records.
    * @return List of Deal_Registration__c records based on search and DR engagement criteria.
    * @throws Exception if any unexpected error occurs.
    * @jira PRIT26-214
    */
    @AuraEnabled(cacheable=true)
    public static List<Deal_Registration__c> getDealRegEngagementRecords(String searchText) {
        List<Deal_Registration__c> dealRegList = new List<Deal_Registration__c>();
        try{
            String query = 'SELECT Id, Name, Company_Name__c,Company_Name__r.Name, FirstName__c ,LastName__c ,Email__c ,Engaged_with_Rubrik__c ,Account__c, Account__r.Name ,Partner_Lookup__c, Partner_Lookup__r.Name ,Deal_Registration_Status__c ,Deal_Reg_Submitted_Date__c ,Approval_Timestamp__c ,Deal_Registration_Expiration__c ,Rejection_Reason__c ,Rejection_Other_Reason__c ,Source_of_the_Opportunity__c ,Number_of_protected_machines__c ,Budget__c ,Purchase_Timeframe__c ,Customer_Needs__c ,Scope_of_Opportunity__c ,Scope_of_Opportunity_Additional_Details__c ,Utility_Shared_Licensing__c, Utility_Shared_Licensing_Why__c, PO_Number__c FROM Deal_Registration__c WHERE RecordTypeId =: engagementRecId';
            if(!String.isBlank(searchText)){
                String stringToSearch = '%' + searchText + '%';
                query += ' AND (Company_Name__r.Name LIKE :stringToSearch OR Name LIKE :stringToSearch OR Owner.Name LIKE :stringToSearch)';
            }
            query = query + ' Order By CreatedDate DESC LIMIT 1000 ';
            dealRegList = Database.query(query);
        }
        catch(Exception ex){
            System.debug(system.logginglevel.DEBUG, 'Exception Ex :: '+ex.getMessage()+', LineNumber :: '+ex.getLineNumber()+', Cause :: '+ex.getCause());
        }
        return dealRegList;
    }

    public class DealRegWrapper{
        @AuraEnabled
        public List<Deal_Registration__c> dealRegList;
        @AuraEnabled
        public Integer submittedDRCount;
        @AuraEnabled
        public Integer approvedDRCount;
    }
}