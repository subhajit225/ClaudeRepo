public without sharing class PC_PartnerFundReqTableController{
    private static String conditions = '';
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
     **/
    @AuraEnabled
    public static List<sobject> getRecords(string searchText, string returnFields, string objType, Integer pageSize, string fieldapiName, string sortedDirection, String sortedByValue, List<string> IdSet, String startDate, String endDate, List<String> accIds){
        List<sobject> finalList = new List<sobject>();
        try{
            system.debug('@@ sortedByValue ' + sortedByValue);
            system.debug('@@ fieldapiName ' + fieldapiName);
            system.debug('accIds'+accIds);
            String searchQuery = '';
            Schema.DisplayType fieldType;
            if (pageSize == null){
                pageSize = 10;
            }
            if (string.isBlank(sortedDirection)){
                sortedDirection = 'desc';
            }
            if (string.isBlank(fieldapiName)){
                sortedDirection = 'Title';
            }
            Map<string, Schema.DisplayType> fieldTypeMap = new Map<string, Schema.DisplayType>();
            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType ctype = gd.get(objType);
            Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();

            User loggedInUser = [SELECT Id, name, contact.account.Type, accountId, userrole.Name, Profile.Name
                                 FROM User
                                 WHERE Id = :userinfo.getUserId()];

            searchQuery = 'SELECT ' + returnFields + ' FROM ' + objType + ' ';
            if (loggedInUser.Profile.Name.contains('Community Manager') && accIds.isEmpty()){
                searchQuery += ' WHERE ChannelPartnerId= ' + '\'' + loggedInUser.AccountId + '\'';
            } else if(!loggedInUser.Profile.Name.contains('Community Manager') && accIds.isEmpty()){
                searchQuery += ' WHERE createdById= ' + '\'' + loggedInUser.Id + '\'';
            }

            if (String.isNotBlank(sortedByValue) && String.isNotBlank(fieldapiName) && fmap != null && !fmap.isEmpty() && fmap.containskey(fieldapiName) && (Schema.DisplayType.Date == fmap.get(fieldapiName).getDescribe().getType() || Schema.DisplayType.DATETIME == fmap.get(fieldapiName).getDescribe().getType() || Schema.DisplayType.INTEGER == fmap.get(fieldapiName).getDescribe().getType())){
                searchQuery += ' AND ';
                if (sortedDirection == 'desc'){
                    searchQuery += fieldapiName + ' <=' + sortedByValue;
                } else{
                    searchQuery += fieldapiName + ' >=' + sortedByValue;
                }
            } else if (String.isNotBlank(sortedByValue) && String.isNotBlank(fieldapiName) && fmap != null && !fmap.isEmpty() && fmap.containskey(fieldapiName) && (Schema.DisplayType.String == fmap.get(fieldapiName).getDescribe().getType() || fmap.get(fieldapiName).getDescribe().getType() == null || fmap.get(fieldapiName).getDescribe().getType() == Schema.DisplayType.PICKLIST)){
                searchQuery += ' AND ';
                if (sortedDirection == 'desc'){
                    searchQuery += fieldapiName + ' <=' + '\'' + sortedByValue + '\'';
                } else{
                    searchQuery += fieldapiName + ' >=' + '\'' + sortedByValue + '\'';
                }
            }
            if (IdSet != null && !IdSet.isEmpty()){
                String newSetStr = '';
                for (String str : IdSet)
                    newSetStr += '\'' + str + '\',';
                    newSetStr = newSetStr.lastIndexOf(',') > 0 ? '(' + newSetStr.substring(0, newSetStr.lastIndexOf(',')) + ')' : newSetStr;
                    if (searchQuery.contains('WHERE')){
                        searchQuery = searchQuery + ' AND Id NOT IN ' + newSetStr;
                    } else{
                        searchQuery = searchQuery + ' WHERE Id NOT IN ' + newSetStr;
                    }
            }
            String userId = UserInfo.getUserID();

            if (!string.isBlank(searchText) && searchText.length() >= 1){
                String searchStr1 = '*' + searchText + '*';
                searchManagers(searchText, returnFields, fmap);
                if (searchQuery.contains('WHERE')){
                    searchQuery = searchQuery + ' AND ' + conditions;
                } else{
                    searchQuery = searchQuery + ' WHERE ' + conditions;
                }
            }

            if(!string.isBlank(startDate) && startDate.length() > 0){
                Date startDateConv = Date.valueOf(startDate);
                searchQuery = searchQuery + (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + 'Activity_Start_Date__c >=: startDateConv';
            }
            if(!string.isBlank(endDate) && endDate.length() > 0){
                Date endDateConv = Date.valueOf(endDate);
                searchQuery = searchQuery + (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + 'Activity_End_Date__c <=: endDateConv';
            }
            if(!accIds.isEmpty()){
                searchQuery = searchQuery + (searchQuery.contains(' WHERE ') ? ' AND ' : ' WHERE ') + 'ChannelPartnerId IN : accIds';
            }

            if (sortedDirection == 'desc'){
                searchQuery = searchQuery + ' ORDER BY ' + fieldapiName + ' ' + sortedDirection + ' NULLS LAST LIMIT ' + pageSize;
            } else{
                searchQuery = searchQuery + ' ORDER BY ' + fieldapiName + ' ' + sortedDirection + ' NULLS FIRST LIMIT ' + pageSize;
            }

            system.debug('@@ searchQuery ' + searchQuery);
            finalList = database.query(searchQuery);
            system.debug('@@ finalList ' + finalList);
        } catch (Exception e){
            system.debug('Exception occurred ' + e.getMessage() + ' at line ' + e.getLineNumber());
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
        if (returnFields != null && returnFields != '' && returnFields.contains(',')){
            tempList = returnFields.split(',');
        }
        for (string op : tempList){
            if (op != 'Id' && fmap != null && !fmap.isEmpty() && fmap.containskey(op) && (fmap.get(op).getDescribe().getType() == Schema.DisplayType.String || fmap.get(op).getDescribe().getType() == Schema.DisplayType.PICKLIST)){
                selOp.add(new SelectOption(op, op));
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
    public static void searchManagers(string searchText, string returnFields, Map<String, Schema.SobjectField> fmap){
        conditions = '';

        for (SelectOption so : getsearchByList(returnFields, fmap)){
            String item = so.getValue();
            String searchItem = searchText.trim();
            searchItem = String.escapeSingleQuotes(searchItem);
            conditions += ' OR ' + item + ' like \'%' + searchItem + '%\'';
        }

        conditions = conditions.removeStart(' OR ');
        conditions = '(' + conditions + ')';
        system.debug('conditions=> ' + conditions);
    }

    /** Description :  This is method is used for getting total size of records in an sobject.
     Retrun type :  Integer - contains size of records
     Parameters  :  objType - contains Sobject Name.
     **/
    @AuraEnabled
    public static Integer getTotalRecords(string objType){
        Integer totalrecs = 0;
        String searchQuery = '';
        searchQuery = 'SELECT COUNT(Id) total FROM ' + objType;
        for (AggregateResult result : database.query(searchQuery)){
            totalrecs += (Integer) result.get('total');
        }
        return totalrecs;
    }

    @AuraEnabled
    public static boolean getStatus(String mdfId){
        Boolean flag = false;
        Boolean skipActivityEndDateCheck = false;
        List<PartnerFundRequest> pfrList = new List<PartnerFundRequest>();
        pfrList = [SELECT Id, status, Activity, Activity_Start_Date__c, Activity_End_Date__c, RequestedAmount, TotalApprovedFcs, MDF_Request_Closed__c, PO_Number__c
                   FROM PartnerFundRequest
                   WHERE Id = :mdfId];

        //PRIT24-394
        //Allow MDF Claims for 'Sales Incentives', 'Training and Readiness', and 'Dedicated Resources' activity types to be submitted without needing the Activity End Date to be in the past
        if (pfrList[0].Activity == 'Sales Incentives' || pfrList[0].Activity == 'Training and Readiness' || pfrList[0].Activity == 'Dedicated Resource'){
            skipActivityEndDateCheck = true;
        }
        if (!pfrList.IsEmpty() && pfrList[0].status == 'Approved' && (pfrList[0].Activity_End_Date__c.addDays(31) > system.today() || skipActivityEndDateCheck) && pfrList[0].MDF_Request_Closed__c == false){
            flag = true;
        } else if (pfrList[0].MDF_Request_Closed__c){
            flag = false;
        }
        
        return flag;
    }

    @AuraEnabled
    public static List<FiscalYearSettings> getFiscalYearData(){
        List<FiscalYearSettings> fiscalYearList = PC_PortalNavigationApexController.getFiscalYear();
        return fiscalYearList;
    }

}