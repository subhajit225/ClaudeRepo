public class SearchPatchManagerVFC {
    public transient list<PatchManager__c> listPatchManager{get;set;}
    // Instance fields
    public String searchTerm {get; set;}
    public String selectedItemId {get; set;}
    public String selectedItem {set;get;}
    public String itemFieldId {set;get;}
    public String city {set;get;}
    public String state {set;get;}
    public String county {set;get;}
    public String zipcode {set;get;}
    public String country {set;get;}
    public String sic {set;get;}
    public String smbOwner {get;set;}
    public String smbOwnerId {get;set;}
    public String sdr {set;get;}
    public String account {set;get;}
    public String accountId{get;set;}
    public String sdrId{get;set;}
    public String leadsource{get;set;}
    public String industry{get;set;}
    public String pleadsource{get;set;}
    public String pindustry{get;set;}
    public String pobjecttype{get;set;}
    public String lsd{get;set;}
    public String objectType{get;set;}
    public String updateStateHidden{get;set;}
    public String updateCountryHidden{get;set;}
    Public Integer size{get;set;} 
    Public Integer noOfRecords{get; set;} 
    public List<SelectOption> paginationSizeOptions{get;set;}
    public String query{get;set;}
    public String srchCity{get;set;}
    public String srchStateGlobal{get;set;}
    public String srchCounty{get;set;}
    public String srchCountryGlobal{get;set;}
    public String srchZipCode{get;set;}
    public String srchSDR{get;set;}
    public String srchSIC{get;set;}
    public String srchSMBOwner{get;set;}
    public String srchOwner{get;set;}
    public String srchAccount{get;set;}
    public String srchIndustry{get;set;}
    public String srchLeadSource{get;set;}
    public String srchLeadSourceDetail{get;set;}
    public String srchObjectType{get;set;}
    public Boolean isOutOfBound{get;set;}
    public String selectedAllValue {get;set;}
    public boolean selectAll{get; set;}
    public PatchManager__c patchForOwner {get;set;}
    public transient list<list<PatchManager__c>> mainList{get;set;}
   
    Public string selectedName{get;set;}
    public Boolean descSort{get;set;}
    Public List<Selectoption> getselectedNameFields(){
        List<Selectoption> lstnamesel = new List<selectoption>();
        lstnamesel.add(new selectOption('', '- None -'));
        lstnamesel.add(new SelectOption('City__c','City'));
        lstnamesel.add(new SelectOption( 'State__c' ,'State'));
        lstnamesel.add(new SelectOption( 'StateGlobal__c' ,'StateGlobal'));
        lstnamesel.add(new SelectOption( 'County__c' ,'County'));
        lstnamesel.add(new SelectOption( 'Country__c' ,'Country'));
        lstnamesel.add(new SelectOption( 'CountryGlobal__c' ,'CountryGlobal'));
        lstnamesel.add(new SelectOption( 'Zip_code__c' ,'Zip Code'));
        lstnamesel.add(new SelectOption( 'SDR__r.Name' ,'SDR'));
        lstnamesel.add(new SelectOption( 'SMB_Owner__c','SMB Owner'));
        lstnamesel.add(new SelectOption( 'Owner.Name' ,'Owner'));
        lstnamesel.add(new SelectOption( 'Account__r.Name' ,'Account'));
        lstnamesel.add(new SelectOption( 'Industry_Category__c' ,'Industry Category'));
        lstnamesel.add(new SelectOption( 'LeadSource__c' ,'Lead Source'));
        lstnamesel.add(new SelectOption( 'Lead_Source_Detail__c' ,'Lead Source Detail'));
        lstnamesel.add(new SelectOption( 'Object_Type__c' ,'Object Type'));
        return lstnamesel; 
    }

    private String insertedRecordId;
    public List<SelectOption> getpicklistValue(){
        //getting picklist value for search list option
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = PatchManager__c.Object_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        //options.insert(0, new SelectOption('','-None-'));
        return options;
    }
    
    public SearchPatchManagerVFC() {
        isOutOfBound=true;
        
        size=10;
        paginationSizeOptions = new List<SelectOption>();
        paginationSizeOptions.add(new SelectOption('5','5'));
        paginationSizeOptions.add(new SelectOption('10','10'));
        paginationSizeOptions.add(new SelectOption('20','20'));
        paginationSizeOptions.add(new SelectOption('50','50'));
        paginationSizeOptions.add(new SelectOption('100','100'));
        
        String oType = ApexPages.currentPage().getParameters().get('objectType');
        objectType = (oType != null) ? oType : null;
        patchForOwner = new PatchManager__c();
        patchForOwner.OwnerId = UserInfo.getUserId();
        selectedItem ='City';
        itemFieldId='';
        selectedItemId='';
        listPatchManager=new list<PatchManager__c>();
        listPatchManager = [SELECT Id, Name, Account__r.Name,County__c,StateGlobal__c,CountryGlobal__c,City__c,State__c,Zip_code__c,SIC__c,SMB_Owner__r.name,Owner.Name,SDR__c,SDR__r.Name,Country__c,Industry_Category__c,LeadSource__c,Lead_Source_Detail__c,Object_Type__c, SMB_Owner__c, SearchCity__c, SearchState__c,SearchCountry__c FROM PatchManager__c limit 100];
        mainList = new List<List<PatchManager__c>>();
        List<PatchManager__c> innerList = null;
        Integer idx = 0;
        for(PatchManager__c obj:listPatchManager){
            if (Math.mod(idx++, 1000) == 0 ) {
                innerList = new List<PatchManager__c>();
                mainList.add(innerList);
            }
            innerList.add(obj);            
        }
    }
    
    public ApexPages.StandardSetController setMan {
        get {
            if(setMan == null) {   
                query='SELECT Id, Name, Account__r.Name,County__c,StateGlobal__c,CountryGlobal__c,City__c,State__c,Zip_code__c,SIC__c,SMB_Owner__r.name,Owner.Name,SDR__c,SDR__r.Name,Country__c,Industry_Category__c,LeadSource__c,Lead_Source_Detail__c,Object_Type__c, SMB_Owner__c,SearchCity__c, SearchState__c,SearchCountry__c,CDM__r.Name FROM PatchManager__c limit 10000';
                setMan = new ApexPages.StandardSetController(Database.getQueryLocator(query));
                setMan.setPageSize(size);  
                noOfRecords = 0;
            }     
            
            return setMan;
        }
        set;
    }
    
    public PageReference refreshPageSize() {
        system.debug('refreshPageSize called');
        setMan.setPageSize(size);
        return null;
    }
    
    public List<PatchManager__c> getPatchManagers() {
        if(noOfRecords>0){
            return (List<PatchManager__c>) setMan.getRecords();
        }else{
            return null;
        }
        
    }
    
    public void searchManagers(){
        query='SELECT Id, Name, Account__r.Name,County__c,StateGlobal__c,CountryGlobal__c,City__c,State__c,Zip_code__c,SIC__c,SMB_Owner__r.name,Owner.Name,SDR__c,SDR__r.Name,Country__c,Industry_Category__c,LeadSource__c,Lead_Source_Detail__c,Object_Type__c, SMB_Owner__c,SearchCity__c, SearchState__c, SearchCountry__c, CDM__r.Name FROM PatchManager__c ';
        String conditions='WHERE ';
        if(insertedRecordId != null){
            system.debug('@@@ '+insertedRecordId);
            conditions+= 'Id =\'' + insertedRecordId + '\' AND ';
        }
        else {
            if(srchCity=='!'){
                conditions+= 'city__c = NULL AND ';
            } else if (srchCity!=''){
                conditions+= 'city__c like \'%'+srchCity+'%\' AND ';
            }
            if(srchStateGlobal=='!'){
                conditions+= 'StateGlobal__c = NULL AND ';
            } else if(srchStateGlobal!=''){
                conditions+= 'StateGlobal__c like \'%'+srchStateGlobal+'%\' AND ';
            }
            if(srchCountryGlobal=='!'){
                conditions+= 'CountryGlobal__c NULL AND ';
            }else if(srchCountryGlobal!=''){
                conditions+= 'CountryGlobal__c like \'%'+srchCountryGlobal+'%\' AND ';
            }
            if(srchZipCode == '!'){
                conditions+= 'Zip_code__c = NULL AND ';
            } else if(srchZipCode!=''){
                conditions+= 'Zip_code__c like \''+srchZipCode+'%\' AND ';
            }
            if(srchSDR!=''){
                conditions+= 'SDR__r.Name like \'%'+srchSDR+'%\' AND ';
            }
            if(srchSMBOwner!=''){
                conditions+= 'SMB_Owner__r.Name like \'%'+srchSMBOwner+'%\' AND ';
            }
            if(srchOwner!=''){
                conditions+= 'Owner.Name like \'%'+srchOwner+'%\' AND ';
            }
            if(srchAccount!=''){
                conditions+= 'Account__r.Name like \'%'+srchAccount+'%\' AND ';
            }
            if(srchIndustry!=''){
                conditions+= 'Industry_Category__c like \'%'+srchIndustry+'%\' AND ';
            }
            if(srchLeadSource!=''){
                conditions+= 'LeadSource__c like \'%'+srchLeadSource+'%\' AND ';
            }
            if(srchLeadSourceDetail=='!'){
                conditions+= 'Lead_Source_Detail__c = NULL AND ';
            } else if(srchLeadSourceDetail!=''){
                conditions+= 'Lead_Source_Detail__c like \'%'+srchLeadSourceDetail+'%\' AND ';
            }
            if(srchObjectType!='' && srchObjectType!='All'){
                conditions+= 'Object_Type__c like \'%'+srchObjectType+'%\' AND ';
            }
        }
        
                
        conditions=conditions.removeEnd(' AND ');
        conditions=(conditions=='WHERE '?'':conditions);
        system.debug('@@Final Condition=> '+conditions);
        query+=conditions;
        System.debug('selectedName:'+selectedName);
        query+=(selectedName!=null && selectedName!='- None -')?' order by '+selectedName+' '+(descSort==true?'desc':'asc')+' limit 10000':' limit 10000';
        System.debug('Query:'+query);
        Integer count= database.countQuery('select count() from PatchManager__c '+conditions);
        isOutOfBound=(count>=10000?true:false);
        setMan = new ApexPages.StandardSetController(Database.getQueryLocator(query));
        setMan.setPageSize(size);  
        if(conditions==''){
            noOfRecords = 0;
        }else{
            noOfRecords = setMan.getResultSize();
        }
        
        insertedRecordId = null;
    }
    
    //This var hold List of user
    public List<SelectOption> getListItems()
    {
        List<SelectOption> ListItems = new List<SelectOption>();
        //ListItems.add(new SelectOption( 'None' ,'None'));
        //ListItems.add(new SelectOption( 'Name' ,'Name'));
        ListItems.add(new SelectOption( 'City' ,'City'));
        //    ListItems.add(new SelectOption( 'State' ,'State'));
        ListItems.add(new SelectOption( 'StateGlobal' ,'StateGlobal'));
        ListItems.add(new SelectOption( 'County' ,'County'));
        //  ListItems.add(new SelectOption( 'Country' ,'Country'));
        ListItems.add(new SelectOption( 'CountryGlobal' ,'CountryGlobal'));
        ListItems.add(new SelectOption( 'Zip Code' ,'Zip Code'));
        ListItems.add(new SelectOption( 'SIC' ,'SIC'));
        ListItems.add(new SelectOption( 'SDR' ,'SDR'));
        ListItems.add(new selectOption( 'SMB Owner','SMB Owner'));
        ListItems.add(new SelectOption( 'Owner' ,'Owner'));
        ListItems.add(new SelectOption( 'Account' ,'Account'));
        ListItems.add(new SelectOption( 'Industry' ,'Industry'));
        ListItems.add(new SelectOption( 'Lead Source' ,'Lead Source'));
        ListItems.add(new SelectOption( 'Lead Source Detail' ,'Lead Source Detail'));
        ListItems.add(new SelectOption( 'Object Type' ,'Object Type'));
        return ListItems;
    }
    public List<SelectOption> getLeadSorces()
    {
        List<SelectOption> options = new List<SelectOption>();
        
        Schema.DescribeFieldResult fieldResult =
            PatchManager__c.LeadSource__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }    
        options.sort();
        options.add(0,new SelectOption('','-Select-'));
        return options;
    }
    public List<SelectOption> getIndustries()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =
            PatchManager__c.Industry_Category__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }   
        options.sort();
        options.add(0,new SelectOption('','-Select-'));
        return options;
    }
    public List<SelectOption> getObjectTypes()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =
            PatchManager__c.Object_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }  
        options.sort();
        options.add(0,new SelectOption('','-Select-'));
        return options;
    }
    public void updateRecordsPatchManager() {
        
        PageReference redirect = new PageReference('/apex/SearchPatchManagers');
        List<Object> objectIds = (List<Object>)JSON.deserializeUntyped(selectedItemId);
        List<PatchManager__c> updateListPatchManager=new List<PatchManager__c>();
        
        for(Object o:objectIds){
            PatchManager__c objP=new PatchManager__c();
            objP.Id=(Id)o;
            if(selectedItem=='City'){
                objP.City__c=searchTerm;
            }
            /*else if(selectedItem=='State'){
objP.State__c=searchTerm;
}
*/
            else if(selectedItem=='StateGlobal'){
                system.debug('@@>'+updateStateHidden);
                objP.StateGlobal__c=updateStateHidden;
            }
            else if(selectedItem=='County'){
                objP.County__c=searchTerm;
            }
            /*  else if(selectedItem=='Country'){
objP.Country__c=searchTerm;
}
*/
            else if(selectedItem=='CountryGlobal'){
                objP.CountryGlobal__c=updateCountryHidden;
            }
            else if(selectedItem=='Zip Code'){
                objP.Zip_code__c=searchTerm;
            }else if(selectedItem=='SIC'){
                objP.SIC__c=searchTerm;
            }else if(selectedItem=='SDR'){
                objP.SDR__c= (Id)itemFieldId;
            }else if(selectedItem=='SMB Owner'){
                objP.SMB_Owner__c= (Id)itemFieldId;
            }else if(selectedItem=='Owner'){
                objP.OwnerId= (Id)itemFieldId;
            }else if(selectedItem=='Account'){
                objP.Account__c=  (Id)itemFieldId;
            }else if(selectedItem=='Lead Source'){
                objP.LeadSource__c=  pleadsource;
            }else if(selectedItem=='Industry'){
                objP.Industry_Category__c=  pindustry;
            }else if(selectedItem=='Object Type'){
                objP.Object_Type__c=  pobjecttype;
            }
            else if(selectedItem=='Lead Source Detail'){
                objP.Lead_Source_Detail__c=  searchTerm;
            }
            updateListPatchManager.add(objP);
        }
        if(updateListPatchManager.size()>0){
            update updateListPatchManager;
        }
        redirect.setRedirect(true);
        searchManagers();
        //return redirect;
    }
    public PageReference cancel() {
        return null;
    }
    public PageReference getRedir() {
        PageReference newPage;
        newPage = new PageReference('/a00/e');
        newPage.getParameters().put('nooverride', '1');
        newPage.getParameters().put('retURL', '/apex/SearchPatchManagers');
        return newPage.setRedirect(true);
    }
    public PageReference addNewPM() {
        PatchManager__c objPM=new PatchManager__c();
        objPM.City__c=city;
        //objPM.State__c=state;
        objPM.StateGlobal__c = patchForOwner.StateGlobal__c;
        objPM.County__c=county;
        //objPM.Country__c=country;
        objPM.CountryGlobal__c = patchForOwner.CountryGlobal__c; 
        objPM.Zip_code__c=zipcode;
        objPM.SIC__c=sic;
        objPM.SDR__c=sdrId!=''?sdrId:null;
        objPM.SMB_Owner__c=smbOwnerId!=''?smbOwnerId:null;
        objPM.Account__c=accountId!=''?accountId:null; 
        objPM.LeadSource__c = leadsource!=''?leadsource:null;
        objPM.Industry_Category__c = industry!=''?industry:null;
        objPM.Lead_Source_Detail__c = lsd;
        objPM.OwnerId = patchForOwner.OwnerId;
        objPM.Object_Type__c = objectType;
        insert objPM;
        insertedRecordId = objPM.Id;
        searchManagers();
        PageReference newPage;
        //newPage = new PageReference('/apex/SearchPatchManagers');
        //return newPage.setRedirect(false);
        return null;
    }
    @RemoteAction
    public static String validation(String item) {
        system.debug('@@item '+item);
        List<String> oo = item.split('#');
        String objectType = (oo.size()==1) ? null : oo.get(1);
        system.debug('@@objectType '+objectType);
        List<String> objectIds = oo[0].split(',');
        system.debug('@@'+objectIds);
        String city		=(objectIds.size() == 1) ? (String)objectIds.get(0) : '';
        String state	=(objectIds.size() == 2) ? (String)objectIds.get(1) : '';
        String sic		=(objectIds.size() == 3) ? (String)objectIds.get(2) : '';
        String zip		=(objectIds.size() == 4) ?(String)objectIds.get(3) : '';
        system.debug('@@error->'+city+'-'+state+'-'+zip+'-'+sic);
        String query='Select  Id,City__c,State__c,Zip_code__c,Sic__c from PatchManager__c where ';Boolean isfilterApplied=false;
        if(sic!=''){
            query+=' Sic__c=:sic or';
            isfilterApplied=true;
        }
        if(city!=''){
            query+=' City__c=:city or';
            isfilterApplied=true;
        }
        if(state!=''){
            query+=' State__c =:state or';
            isfilterApplied=true;
        }
        if(zip!=''){
            if(objectType == null)
                query+=' Zip_code__c=:zip or';
            else
                query+=' Zip_code__c=:zip AND Object_Type__c =:objectType or';
            isfilterApplied=true;
        }
        
        
        
        if(isfilterApplied==true){
            map<String,PatchManager__c> mapPM=new map<String,PatchManager__c>();
            query=query.removeEnd('or');
            
            system.debug('query= '+query);
            
            List<PatchManager__c> listPM = Database.query(query);
            system.debug('ListPM is : '+listPM);
            for (PatchManager__c pm : listPM) {
                String cityStateZip='';
                if(pm.City__c!='' && pm.City__c!=null){
                    cityStateZip +=pm.City__c;
                }
                if(pm.State__c!='' && pm.State__c!=null){
                    cityStateZip +=pm.State__c;
                }
                if(pm.Zip_code__c!='' && pm.Zip_code__c!=null){
                    cityStateZip +=pm.Zip_code__c;
                    mapPM.put('zip@'+pm.Zip_code__c,pm);
                }
                if(pm.Sic__c!='' && pm.Sic__c!=null){
                    mapPM.put('sic@'+pm.Sic__c,pm);
                }
                
                mapPM.put(cityStateZip,pm);
            }
            system.debug('@@mapPM'+mapPM);
            set<String> msg=new set<String>();
            if(sic!=''){
                PatchManager__c pm=mapPM.get('sic@'+sic);
                if(pm!=null){
                    msg.add('Sic code');
                }
            }
            if(zip!=''){
                PatchManager__c pm=mapPM.get('zip@'+zip);
                if(pm!=null){
                    msg.add('Zip code');
                }
            }
            String cityStateZip=(city!=''?city:'')+(state!=''?state:'')+(zip!=''?zip:'');
            if(city!='' && state!='' && zip==''){
                PatchManager__c pm=mapPM.get(cityStateZip);
                if(pm!=null){
                    msg.add('City and State');
                }
            }else {
                if(city!='' && city!=null){
                    system.debug('~~ city'+city);
                    system.debug('!!cityStateZip '+cityStateZip);
                    PatchManager__c pm=mapPM.get(cityStateZip);
                    system.debug('mapPM '+mapPM);
                    if(pm!=null){
                        msg.add('City');
                    }
                }
                if(state!='' && state!=null){
                    PatchManager__c pm=mapPM.get(cityStateZip);
                    if(pm!=null){
                        msg.add('State');
                    }
                }
            }
            if(msg.size()>0){
                String retMsg='';
                for (String str : msg) {
                    retMsg+=Str+', ';
                }
                retMsg='Patch manager record with '+retMsg.removeEnd(', ') + ' already exist.';
                system.debug('retMsg '+retMsg);
                return retMsg;
            }else{
                return '';
            }
            
        }else{
            return '';
        }
    }
    @RemoteAction
    public static List<Account> searchAccount(String searchTerm) {
        List<Account> listAccount = Database.query('Select Id, Name from Account where name like \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
        return listAccount;
    }
    @RemoteAction
    public static List<User> searchUser(String searchTerm) {
        List<User> listUser = Database.query('Select Id, Name from User where name like \'%' + String.escapeSingleQuotes(searchTerm) + '%\'');
        return listUser;
    }
    @RemoteAction
    public static String deleteUser(String item) {
        List<Object> objectIds = (List<Object>)JSON.deserializeUntyped(item);
        List<Id> ids=new List<Id>();
        for(Object o : objectIds){
            Id pmId=(Id)o;
            ids.add(pmId);
        }
        List<PatchManager__c> deletelistPM = [select Id from PatchManager__c where Id in :ids];
        if(deletelistPM.size()>0){
            delete deletelistPM;
        }
        return 'Success';
    }
}