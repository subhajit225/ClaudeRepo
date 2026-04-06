public without sharing class DocumentationController {
    public static  string acctTypeString;
    public static String mProdTypes ;
    public static Set<String> ProdTypes ;
    public static Set<String> EntProdTypes  ;
    public static List<String> releaseString = new List<String>();
    public static list<Organization> orgDetails;
    public static boolean isTransientUser = false; //added for CS21-830

    @AuraEnabled
    public static list<Release_Version__c> getReleaseVersions(Boolean polaris) {
        return getReleaseVersionsInternal(false,polaris);
    }

    @AuraEnabled
    public static list<Release_Version__c> getAllReleaseVersions(Boolean polaris) {
        return getReleaseVersionsInternal(true,polaris);
    }
	@TestVisible
    private static list<Release_Version__c> getReleaseVersionsInternal(Boolean showAll, boolean polaris) {

        getUserReleases();
        list<Release_Version__c> relvList;
        string q = 'Select Id, Name, Visible__c, Blocked__c, Release_Date__c, Release_Type__c , Version__c, LastModifiedDate from Release_Version__c ';

        if(!polaris){
            q+= ' where Blocked__c = false ';
        }else{
            q+= ' where BlockedForDownloads__c = false ';
        }

        if(Util.UserType == 'Trial'){
            q+= ' and (Release_Type__c = \'Edge Trial\') ';
        }else{
            if(Util.CurrentUser.Contact.Agreed_to_Edge_Trial_Agreement__c){
                if(!releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\' OR Release_Type__c = \'Edge Trial\' OR Release_Type__c=null OR Version__c in:releaseString) ';
                if(releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\'  OR Release_Type__c = \'Edge Trial\' OR Release_Type__c=null) ';
            }else{
                if(!releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\' OR Release_Type__c=null OR Version__c in:releaseString) ';
                if(releaseString.isEmpty()) q+= ' and (Release_Type__c= \'Generally Available (GA)\' OR Release_Type__c=null) ';
            }
        }

        q+= ' order by Release_Date__c desc';
        if (relvList == null)
            relvList = Database.query(q);
        if (relvList.isEmpty()) {
            return null;
        }
        return relvList;
    }

    @AuraEnabled
    public static DocumentWrapper getReleaseSoftware(String releaseId , String Name){
        DocumentWrapper mWrapper = new DocumentWrapper();
        Set<id> allRelease = new Set<id>();

        for(Release_Version__c rv : getReleaseVersionsInternal(false,false)){
            allRelease.add(rv.Id);
        }

        if(!allRelease.contains(releaseId)){
            return mWrapper;
        }

        string acctId;
        list<Entitlement> entList;
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Releases__c.Product_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }

        User userRelease = [SELECT Contact.AccountId, Releases__c
                            FROM User
                            WHERE Id = :UserInfo.getUserId()
                            LIMIT 1];

        if(userRelease.Contact.AccountId != null) {
          acctId = userRelease.Contact.AccountId;
        }

        ProdTypes = new Set<String>();
        EntProdTypes = new Set<String>();

        string q = 'SELECT Id, Product__r.Family, Product__r.Release_Product_Types__c, Product__c, EndDate, Terminated_Date__c FROM Entitlement';
        q += ' WHERE AccountId = :acctId AND ((Terminated_Date__c >= TODAY) OR (Terminated_Date__c = NULL AND EndDate >= TODAY))';
        

        if (entList == null) {
            entList = Database.query(q);
        }

        if(!entList.isEmpty()){
            for(Entitlement ent : entList) {
                if(ent.Product__r.Release_Product_Types__c!=null) {
                    for(String key : ent.Product__r.Release_Product_Types__c.split(';')) {
                        EntProdTypes.add(key);
                    }
                }
            }

            for(String ptypes : pickListValuesList) {
                if(EntProdTypes.contains(ptypes)) {
                    ProdTypes.add(ptypes);
                }
            }
        }

        Set<String> getRelease = new Set<String>();
        getRelease = getUserReleases();

        if(!getRelease.isEmpty()) {
            ProdTypes.addAll(getRelease);
        }

        List<Release_Software__c> relDocList = new List<Release_Software__c>();
        string query = 'SELECT Release__r.Release_Version__c, Release__r.Version__c, Release__r.Release_Date__c,';
        query += 'Bytes__c, Id, Link__c, MD5__c, Name, Release__c, LastModifiedDate, Release_Type__c, Release__r.Name,';
        query += 'Product_Type__c, S3_File_URL__c, S3_Bucket_Name__c FROM Release_Software__c';
        query += ' WHERE Release__r.Release_Version__c =\'' + releaseId + '\' AND Release__r.Blocked__c = false';

        if(!Util.CurrentUser.Contact.Agreed_to_Edge_Trial_Agreement__c) {
            ProdTypes.remove('Edge Trial');
        }

        query += ' and Product_Type__c  IN :ProdTypes';
        query += ' order by Name desc';
        relDocList = Database.query(query);

        mWrapper.relDocList = relDocList;
        mWrapper.docAttachmentList=getReleaseVDocs(releaseId,True);
        mWrapper.docName=getDocName(releaseId);
        // added for CS21-706
        if (!getOrgDetails().isEmpty() && !getOrgDetails()[0].IsSandbox) {
            mWrapper.isProduction = true;
        }

        return mWrapper;
    }

    @AuraEnabled
    public static Release_Software__c getLink(String Id) {
        Id currentUserId = Userinfo.getUserID();
        Release_Software__c rs = [select id, Link__c from Release_Software__c where id =:Id];
        Download_History__c DH = new Download_History__c();
        DH.EULA_Accepted__c = true;
        DH.Date__c = system.now();
        DH.User__c = UserInfo.getUserId();
        DH.Downloaded_Software__c = rs.id;
        String ip = '';
        if(!Test.isRunningTest()){
            Map<String,String> currentSessionAttributes = Auth.SessionManagement.getCurrentSession();
            ip = currentSessionAttributes.get('SourceIp');
        }
        DH.IP_Address__c = ip;
        insert DH;
        return rs;
    }

    @AuraEnabled
    public static String gets3Link(String Id, Boolean isName, String ironcladResponse) {

        Release_Software__c releaseSoftware = [SELECT Id, Link__c, S3_File_URL__c, S3_Bucket_Name__c
                                               FROM Release_Software__c
                                               WHERE Id = :Id];

        /* commented for CS21-706
        Id currentUserId = Userinfo.getUserID();
        Download_History__c DH = new Download_History__c();
        DH.EULA_Accepted__c = true;
        DH.Date__c = system.now();
        DH.User__c = UserInfo.getUserId();
        DH.Downloaded_Software__c = rs.id;
        String ip = '';
        if(!Test.isRunningTest()){
            Map<String,String> currentSessionAttributes = Auth.SessionManagement.getCurrentSession();
            ip = currentSessionAttributes.get('SourceIp');
        }
        DH.IP_Address__c = ip;
        insert DH;*/
        createDownloadHistory(releaseSoftware, ironcladResponse);

        if(isName) {
            return getSignedURL(releaseSoftware.S3_Bucket_Name__c, releaseSoftware.S3_File_URL__c);
        } else {
            return getSignedURLFile(releaseSoftware.S3_Bucket_Name__c, releaseSoftware.S3_File_URL__c);
        }
    }

    /**
    * @description method to capture Download history in SF once the EULA contract is accepted successfully - CS21-706 - Veera
    * return: void
    */
    private static void createDownloadHistory(Release_Software__c releaseSoftware, string ironcladResponse) {
        try {
            Map<String, Object> ironCladContract = (Map<String, Object>)JSON.deserializeUntyped(ironcladResponse);
            List<Object> versions = ironCladContract.containsKey('versions') ? (List<Object>)ironCladContract.get('versions') : new List<Object>();

            Download_History__c downloadhistory = new Download_History__c();
            downloadhistory.EULA_Accepted__c = true;
            downloadhistory.Date__c = system.now();
            downloadhistory.User__c = UserInfo.getUserId();
            downloadhistory.Downloaded_Software__c = releaseSoftware.Id;
            downloadhistory.EULAversion__c = versions.isEmpty() ? '' : string.valueOf(versions[0]);
            downloadhistory.IroncladPayload__c = ironcladResponse.length() < 131072  ? ironcladResponse : ironcladResponse.substring(0,131000);

            String ipAddress = '';
            if(!Test.isRunningTest()){
                Map<String,String> currentSessionAttributes = Auth.SessionManagement.getCurrentSession();
                ipAddress = currentSessionAttributes.get('SourceIp');
            }

            downloadhistory.IP_Address__c = ipAddress;
            insert downloadhistory;

        } catch (exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error Occured :: ' + ex);
        }
    }

    /**
    * @description method to check if contract is accessed from Sandbox or Production - CS21-706 - Veera
    * return: List<Organization>
    */
    public static List<Organization> getOrgDetails() {
        if (orgDetails == null) {
            orgDetails = [SELECT IsSandbox FROM Organization LIMIT 1];
        }

        return orgDetails;
    }

    public static String getSignedURL(String BucketName,String selectedFile) {
        AWS_S3_Creds__c aws = AWS_S3_Creds__c.getInstance();
        String secretKey = aws.secretKey__c;
        String AccessKey = aws.AccessKey__c;
        return getSignedUrlFromS3(BucketName, selectedFile, secretKey, AccessKey, 10);
    }

    public static String getSignedUrlFromS3(String BucketName,String selectedFile, String secretKey, String AccessKey, Integer expiryTime) {
        String filename = EncodingUtil.urlEncode(selectedFile, 'UTF-8');
        Datetime now = DateTime.now();
        Datetime expireson = now.AddSeconds(expiryTime);
        String expiresTimestamp = String.valueOf(expireson.getTime()/1000);
        String stringtosign = 'GET\n\n\n'+expiresTimestamp+'\n/'+BucketName+'/'+filename;
        String signingKey = EncodingUtil.base64Encode(Blob.valueOf('AWS4'+SecretKey));
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(stringtosign),blob.valueof(SecretKey));
        String signed= EncodingUtil.base64Encode(mac);
        signed = signed.replace('+','%2B');
        String codedsigned = EncodingUtil.convertToHex(blob.valueOf(signed));
        return 'https://'+BucketName+'.s3.amazonaws.com/'+filename+'?AWSAccessKeyId='+AccessKey+'&Expires='+expiresTimestamp+'&Signature='+signed;
    }

    public static String getSignedURLFile(String BucketName,String selectedFile) {
        AWS_S3_Creds__c aws = AWS_S3_Creds__c.getInstance();
        String fileDownloadName;
        if(selectedFile.contains('/')){
            String[] splitBy =selectedFile.split('/');
            fileDownloadName = splitBy[splitBy.size()-1];
        }else{
            fileDownloadName = selectedFile;
        }

        String secretKey = aws.secretKey__c; 
        String AccessKey = aws.AccessKey__c; 
        String filename = EncodingUtil.urlEncode(selectedFile, 'UTF-8');
        Datetime now = DateTime.now();
        Datetime expireson = now.AddSeconds(10);
        String expiresTimestamp = String.valueOf(expireson.getTime()/1000);
        String stringtosign = 'GET\n\n\n'+expiresTimestamp+'\n/'+BucketName+'/'+filename+'?response-content-disposition=attachment;filename="'+fileDownloadName+'"';
        String signingKey = EncodingUtil.base64Encode(Blob.valueOf('AWS4'+SecretKey));
        Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(stringtosign),blob.valueof(SecretKey));
        String signed= EncodingUtil.base64Encode(mac);
        signed = signed.replace('+','%2B');
        String codedsigned = EncodingUtil.convertToHex(blob.valueOf(signed));
        return 'https://'+BucketName+'.s3.amazonaws.com/'+filename+'?AWSAccessKeyId='+AccessKey+'&Expires='+expiresTimestamp+'&Signature='+signed+'&response-content-disposition='+EncodingUtil.urlEncode('attachment;filename="'+fileDownloadName+'"', 'UTF-8');
    }

    @AuraEnabled
    public static DocumentWrapper getReleaseAttachments(String releaseId) {
        Releases__c release = [select id,Name from Releases__c where id =: releaseId];
        string q = 'SELECT Description,Id,Name,OwnerId,ParentId,LastModifiedDate FROM Attachment ';
        q += ' where ParentId = \''+releaseId +'\'';
        q += ' order by Name desc';
        List<Attachment> relDocsList = Database.query(q);
        DocumentWrapper docWrap = new DocumentWrapper();
        docWrap.docName = release.Name;
        docWrap.docAttachmentList = relDocsList;

        // added for CS21-706
        if (!getOrgDetails().isEmpty() && !getOrgDetails()[0].IsSandbox) {
            docWrap.isProduction = true;
        }

        return docWrap;
    }

    @AuraEnabled
    public static String getDocName(String releaseId){
        Release_Version__c versions = [Select Id, Name, Visible__c, Release_Date__c, Release_Type__c , Version__c, LastModifiedDate from Release_Version__c where id = : releaseId];
        return versions.Name;
    }
    @AuraEnabled
    public static List<Attachment> getReleaseVDocs(String releaseId,Boolean IsPolaris){
        string versionId = '';
        list<Attachment> relDocsList = new list<Attachment>();
        list<Release_Version__c> versionList = [SELECT Id, LastModifiedDate FROM Release_Version__c WHERE Id = :releaseId];

        if(versionList != null && !versionList.isEmpty()) {
            versionId = versionList[0].id;
        }

        string rq = 'SELECT Id, Name,Release_Version__c, Product_Type__c, LastModifiedDate FROM Releases__c';
        rq += ' WHERE Release_Version__c = :versionId ';
        if(IsPolaris){
            rq +='AND Blocked__c = false';
        }else{
            rq += 'AND BlockedForDownloads__c = false';
            //Below Product Type check is not required while rendernig Documentations on the Support Portal 
            //Changes made per CS21-1365
            if(acctTypeString == 'Customer' && !isTransientUser && ProdTypes!=NULL && ProdTypes.size()>0) {
                rq += ' and Product_Type__c  in : ProdTypes';
            }
        }

        list<Releases__c> releasesList = Database.query(rq);

        set<string>SetReleaseId= new Set<string>();
        for(Releases__c rls : releasesList){
            SetReleaseId.add(rls.id);
        }

        String StringReleaseId = quoteKeySet(SetReleaseId);

        if (string.isNotBlank(StringReleaseId)) { //added if check - CS21-830
            string q = 'SELECT Description,Id,Name,OwnerId,ParentId,LastModifiedDate FROM Attachment ';
            q += ' where ParentId in '+StringReleaseId +'';
            q += ' order by Name desc';
            relDocsList = Database.query(q);
        }
        return relDocsList;
    }


    public static Set<String> getUserReleases(){

        String acctId ;
        // string acctTypeString;
        string docQueryID;
        Set<String> ProdTypes  = new Set<String>();
        boolean isPartner = false ;
        boolean isPartnerType = false ;
        boolean isCustomer = false ;
        boolean isCustomerType = false ;
        List<String> PartnerAccountTypes = new List<String>();
        List<String> CustomerAccountTypes = new List<String>();

        if (System.Label.PartnerTypes != null) {
            PartnerAccountTypes = System.Label.PartnerTypes.split(';');
        }

        if (System.Label.CustomerTypes != null) {
            CustomerAccountTypes = System.Label.CustomerTypes.split(';');
        }

        List<Opportunity> partnerOpps = new List<Opportunity>();
        User userRelease = [SELECT Contact.AccountId, Releases__c FROM User WHERE Id = :UserInfo.getUserId() limit 1];

        if(userRelease.Releases__c != null) {
            if(userRelease.Releases__c.contains(';')){
                releaseString = userRelease.Releases__c.split(';');
            } else {
                releaseString.add(userRelease.Releases__c);
            }
        }

        if(userRelease.Contact.AccountId != null) {
            acctId = userRelease.Contact.AccountId;
        }

        isPartner = false;
        isPartnerType = false;
        isCustomer = false;
        isCustomerType = false;
        acctTypeString = '';
        Integer shipmentDelayByDays=Integer.valueof(System.Label.Days_for_Opportunity_Close_Date);
        if(acctId != null) {
            List<Account> acctType = [SELECT Id, Type, Total_Open_Opportunities__c, Partner_Agreement_Status__c, Total_Closed_Opportunities__c  FROM Account WHERE Id = :acctId];
            String query='select id, Partner_Lookup__c From Opportunity where Partner_Lookup__c =: acctId and  isWon = true AND closedate = LAST_N_DAYS:'+shipmentDelayByDays;
            List<Opportunity> wonOpportunties =Database.query(query);
            List<Opportunity> openOpporunity = [SELECT Id, Partner_Lookup__c FROM Opportunity WHERE Partner_Lookup__c = :acctId AND StageName IN ('3 Technical Validation','4 Business Justification','5 Negotiate & Close','6 PO With Channel')];

            if(!wonOpportunties.isEmpty()) {
                partnerOpps.addAll(wonOpportunties);
            }

            if(!openOpporunity.isEmpty()) {
                partnerOpps.addAll(openOpporunity);
            }

            acctTypeString = acctType[0].Type;

            for(String pts : PartnerAccountTypes){
                if(pts == acctTypeString) {
                    isPartnerType = true;
                }
            }

            for(String cts : CustomerAccountTypes){
                if(cts==acctTypeString)  {
                    isCustomerType = true;
                    isCustomer = true;
                }
            }

            isPartner = isPartnerType && acctType[0].Partner_Agreement_Status__c=='Signed - Active' && (acctType[0].Total_Closed_Opportunities__c>0 || acctType[0].Total_Open_Opportunities__c>0 || partnerOpps.size()>0) ? true : false;

            if(acctType[0].Total_Open_Opportunities__c > 0) {
                ProdTypes.add('CDM');
            }
        }

        if(partnerOpps.size() > 0) {
            ProdTypes.add('CDM');
        }

        isTransientUserValidation(acctId, ProdTypes);

        return ProdTypes;
    }

    //added this method for CS21-830 - Veera
    private static void isTransientUserValidation(String accountId, Set<String> ProdTypes) {
        Integer shipmentDelayByDays=Integer.valueof(System.Label.Days_for_Opportunity_Close_Date);
        String query='SELECT (SELECT Id FROM Entitlements WHERE Status = \'Active\' LIMIT 1), '+
        '(SELECT Id FROM Opportunities WHERE isWon = true AND closedate = LAST_N_DAYS:'+shipmentDelayByDays+' LIMIT 1), '+
        '(SELECT Id FROM Opportunities__r WHERE isWon = true AND closedate = LAST_N_DAYS:'+shipmentDelayByDays+' LIMIT 1) '+
        'FROM Account WHERE Id = :accountId';
        for (Account account : Database.query(query))
        {
            if (account.Entitlements.size() == 0 && (account.Opportunities.size() > 0 || account.Opportunities__r.size() > 0)) {
                ProdTypes.add('CDM');
                isTransientUser = true;
            }
        }
    }

    public Static String quoteKeySet(set<String> mapKeySet) {
        String newSetStr = '' ;
        for(String str : mapKeySet)
            newSetStr += '\'' + str + '\',';
        newSetStr = newSetStr.lastIndexOf(',') > 0 ? '(' + newSetStr.substring(0,newSetStr.lastIndexOf(',')) + ')' : newSetStr ;
        return newSetStr;
    }

    public class DocumentWrapper{

        @AuraEnabled
        public  List<Release_Software__c> relDocList {get;set;}

        @AuraEnabled
        public  List<Attachment> docAttachmentList {get;set;}
        @AuraEnabled
        public String docName {get;set;}
        //added for CS21-706 - Veera
        @AuraEnabled
        public Boolean isProduction = false;
    }
}