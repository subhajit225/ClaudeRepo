@RestResource(urlMapping='/cdm/upgrade/listDownloadableReleases/*')
global class CdmUpgradeController{
	 global static Integer defaultExpTime = 7200;

     /**
     * @description processListDownloadableReleasesRequest Method to get Release Version records
    */
    @HttpGet
    global static void processListDownloadableReleasesRequest() {
        List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
        try{
        RestRequest req = RestContext.request;
        RestResponse resp =  RestContext.response;

        Boolean showAll = (req.params.get('show_all') == 'true');
        System.debug(LoggingLevel.DEBUG, 'Show all versions: ' + showAll);

        Boolean fetchLinks = req.params.get('fetch_links') == 'true';
        System.debug(LoggingLevel.DEBUG, 'Fetch links: ' + fetchLinks);

        String filterVersionName = req.params.get('filter_version');
        System.debug(LoggingLevel.DEBUG, 'Version: ' + filterVersionName);

        String AccountID='';
        AccountID  = req.params.get('AccountID');
        System.debug(LoggingLevel.DEBUG, 'AccountID: ' + AccountID);
		
        Boolean shouldFilterUpgradeable = false;
        String sourceVersion = null;
        if(req.params.containsKey('expiry') && req.params.get('expiry') != null && Integer.valueOf(req.params.get('expiry')) < 900){
            defaultExpTime = Integer.valueOf(req.params.get('expiry')) * 60;
        }
        if(req.params.containsKey('filter_upgradable_versions') && req.params.containsKey('source_version')) {
            shouldFilterUpgradeable = (req.params.get('filter_upgradable_versions') == 'true');
            sourceVersion = req.params.get('source_version');
        }
        System.debug(LoggingLevel.DEBUG, 'Should filter upgradeable versions: ' + shouldFilterUpgradeable);
        System.debug(LoggingLevel.DEBUG, 'Source Version: ' + sourceVersion);
        
        Boolean show814Packages = false;
        if(req.params.containsKey('show_814') && req.params.get('show_814') == 'true') {
            show814Packages = true;
        }
        System.debug(LoggingLevel.DEBUG, 'show_814: ' + show814Packages);
        
        String jsGen=getCdm(AccountID,filterVersionName,sourceVersion,fetchLinks,showAll,shouldFilterUpgradeable,show814Packages);
        
        resp.responseBody = Blob.valueOf(jsGen);
        resp.addHeader('Content-Type', 'application/json');
        resp.statusCode = 200;

        }catch(exception e){
            System.debug(LoggingLevel.DEBUG, 'Encountered exception while fetching release notes ' + e);
            Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
            exceptionErrorLog.Class__c = 'CdmUpgradeController';
            exceptionErrorLog.Exception_Message__c = e.getMessage();
            exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
            errorLogList.add(exceptionErrorLog);
        }
        // Finally block
        finally{
            System.debug(LoggingLevel.DEBUG, 'errorLogList: '+errorLogList);
            if(!errorLogList.isEmpty()){
                INSERT errorLogList;
            }
        }
        System.debug(LoggingLevel.DEBUG, 'SOQL Queries allowed: ' +  Limits.getLimitQueries());
        System.debug(LoggingLevel.DEBUG, 'SOQL Queries issued: ' +  Limits.getQueries());
    }
	
    /**
  * @author Ashish Thakur
  * @description getCdm
  * @param AccountID
  * @param filterVersionName
  * @param sourceVersion
  * @param fetchLinks
  * @param showAll
  * @param shouldFilterUpgradeable
  * @param show814Packages
  * @return String
  */
     public Static String getCdm(String AccountID,String filterVersionName,String sourceVersion,Boolean fetchLinks,Boolean showAll,Boolean shouldFilterUpgradeable,Boolean show814Packages){
        List<Custom_Error_Log__c> errorLogList = new List<Custom_Error_Log__c>();
         try{
             String releaseMatrix = getReleaseMatrix();
             List<String> allowedUpgrades = new List<String>();
             if(sourceVersion != null && shouldFilterUpgradeable) {
                 allowedUpgrades = parseReleaseMatrix(releaseMatrix, sourceVersion);
             }
             Integer minReleaseVersion = getLeastReleaseFamilyFromMatrix(releaseMatrix);
             
             // This is needed for entitlement checks
             List<Release_Version__c> versions = new List<Release_Version__c>();
             if(showAll) {
                 versions = DocumentationController.getAllReleaseVersions(True); 
             } else {
                 versions = DocumentationController.getReleaseVersions(True);
             }
             Set<String> allowedVersions = new Set<String>();
             for (Release_Version__c v: versions) {
                 allowedVersions.add(v.Version__c);
             }
             
             System.debug(LoggingLevel.DEBUG, 'Allowed upgrades: ' + string.join(allowedUpgrades,','));
             
             //------------------------------- Process Release Versions -------------------------------
             
             String responseJson = '';
             JSONGenerator jsGen = JSON.createGenerator(false);
             jsGen.writeStartObject();
             
             jsGen.writeFieldName('versions');
             jsGen.writeStartArray();
             
             Set<String> processedVersions = new Set<String>();
             Set<ID> releaseversionIDs=new Set<ID>();
             Map<ID,List<Attachment>> rvIdToReleaseAttachments=new Map<ID,List<Attachment>>();
             Set<String> ProdTypes = new Set<String>();
             List<Release_Software__c> wrapper = new List<Release_Software__c>();
             
             if(AccountID!=null && AccountID!=''){
                 ProdTypes=getUserEntitledProductType(AccountID);
                 
                 if(ProdTypes==NULL || ProdTypes.size()==0){
                     return null;
                 }
                 wrapper =getAllReleasesInternal(ProdTypes);
                 
                 for(Release_Software__c  rs_Object: wrapper){
                     releaseversionIDs.add(rs_Object.Release__r.Release_Version__c);
                 }
                 
                 if(releaseversionIDs!=NULL && releaseversionIDs.size()>0){
                     rvIdToReleaseAttachments=getReleaseVDocs(releaseversionIDs,ProdTypes);
                 }
                 
             }else{
                 wrapper = getAllReleasesInternal(ProdTypes);
             }
             
             for (Release_Software__c software: wrapper) {
                 
                 String rvVersion = software.Release__r.Release_Version__r.Version__c;
                 Boolean rvVisibility = software.Release__r.Release_Version__r.Visible__c;
                 String rvName = software.Release__r.Release_Version__r.Name;
                 String rName = software.Release__r.Name;
                 String rVersion = software.Release__r.Version__c;
                 
                 if(rName.startsWith('8.1.4') && !show814Packages) {
                     System.debug(LoggingLevel.DEBUG, 'Skipping ' + rvVersion + ' since show_814 is false');
                     continue;
                 }
                 
                 // Entitlement checks
                 if(rName!='Virtual Edition Deployment Tool' || AccountId==NULL || AccountId==''){
                     if (!allowedVersions.contains(rvVersion)) {
                         System.debug(LoggingLevel.DEBUG, 'Not allowed to use version ' + rvVersion);
                         continue;
                     }
                     
                     
                     if (rvVersion == null || rvVersion.indexOf('.') == -1) {
                         System.debug(LoggingLevel.DEBUG, 'Not a valid version ' + rvVersion);
                         continue;
                     }
                     
                     String majorRelease = rvVersion.substring(0, rvVersion.indexOf('.'));
                     if (!majorRelease.isNumeric() || integer.valueof(majorRelease) < minReleaseVersion) {
                         System.debug(LoggingLevel.DEBUG, 'Skipping for old version ' + rvVersion);
                         continue;
                     }
                     
                     if (rvName.contains('Edge Trial') || rvName.contains('Virtual Cluster') || !rvName.contains('Rubrik CDM') ) {
                         System.debug(LoggingLevel.DEBUG, 'Skipping for non CDM versions ' + rvVersion);
                         continue;
                     }
                 }
                 
                 String releaseLink = null;
                 if (software.S3_Bucket_Name__c != null) {
                     AWS_S3_Creds__c aws = AWS_S3_Creds__c.getInstance();
                     String secretKey = aws.secretKey__c;
                     String AccessKey = aws.AccessKey__c;
                     releaseLink = DocumentationController.getSignedUrlFromS3(software.S3_Bucket_Name__c, software.S3_File_URL__c, secretKey, AccessKey, defaultExpTime);
                 } else if (software.Link__c != null) {
                     releaseLink = software.Link__c;
                 }
                 
                 // Filter out azure-cloud zip images and non disk image tarballs
                 if(AccountID=='' && ((releaseLink != null && !releaseLink.contains(rName + '.zip')) || rName.contains('r528'))) {
                     System.debug(LoggingLevel.DEBUG, 'Skipping for invalid release ' + releaseLink + ' version ' + rName);
                     continue;
                 }
                 
                 // If we have a filterVersionName set then all reported outputs must be as the same release family as the filter
                 if (filterVersionName != null && filterVersionName != '') {
                     if(!rName.startsWith(filterVersionName)) {
                         continue;
                     }
                 }
                 
                 if(shouldFilterUpgradeable) {
                     Boolean isAllowed = false;
                     if(!isAllowed) {
                         for(String allowedVersion : allowedUpgrades) {
                             if(isMatrixVersionMatched(allowedVersion, rName)) {
                                 isAllowed = true;
                                 break;
                             }
                         }
                     }
                     if(!isAllowed) {
                         continue;
                     }
                 }
                 
                 //Skip this logic also if accountID!=NULL
                 if (!showAll  && (AccountID==null || AccountID=='')) {
                     if (rvVisibility == false || processedVersions.contains(rvVersion)) {
                         System.debug(LoggingLevel.DEBUG, 'Skipping for release under showAll ' + rVersion + ' version ' + rName);
                         continue;
                     }
                     processedVersions.add(rvVersion);
                 }
                 
                 
                 
                 //------------------------------- WRITE FIELDS -------------------------------
                 
                 jsGen.writeStartObject();
                 jsGen.writeStringField('name', rName);
                 jsGen.writeStringField('description',  rvName);
                 if (software.Release__r.Release_Version__r.End_Of_Support_Date__c != null) {
                     jsGen.writeDateField('end_of_support_date', software.Release__r.Release_Version__r.End_Of_Support_Date__c);
                 }
                 
                 if(fetchLinks) {
                     if (releaseLink != null) {
                         jsGen.writeStringField('link', releaseLink);
                     }
                     
                     if (software.MD5__c != null) {
                         jsGen.writeStringField('md5sum', software.MD5__c);
                     }
                     if (software.Bytes__c != null) {
                         jsGen.writeStringField('size', software.Bytes__c);
                     }
                     
                     if (software.Release__r.Release_Version__r.Release_Date__c != null) {
                         jsGen.writeDateField('generalAvailabilityReleaseDateForReleaseFamily', software.Release__r.Release_Version__r.Release_Date__c);
                     }
                     
                     if (software.Release__r.Release_Date__c != null) {
                         jsGen.writeDateField('releaseDate', software.Release__r.Release_Date__c);
                     }
                     
                     try{
                         if(AccountID!=NULL && AccountID!=''){
                             if( rvIdToReleaseAttachments.containsKey(software.Release__r.Release_Version__c)){
                                 for(Attachment attch : rvIdToReleaseAttachments.get(software.Release__r.Release_Version__c)) {
                                     if(attch.Name.contains('Release Notes')){
                                         AWS_Release_Notes_s3_creds__c aws = AWS_Release_Notes_s3_creds__c.getInstance();
                                         String secretKey = aws.secretKey__c;
                                         String AccessKey = aws.AccessKey__c;
                                         String url = DocumentationController.getSignedUrlFromS3('rubrik-polaris-upgrades','Release_Notes/' + attch.Name, secretKey, AccessKey, 7200);
                                         jsGen.writeStringField('releaseNotes', url);
                                     }
                                 }
                             }
                         }else{
                             for(Attachment attch : DocumentationController.getReleaseVDocs(software.Release__r.Release_Version__c,false)) {
                                 if(attch.Name.contains('Release Notes')){
                                     AWS_Release_Notes_s3_creds__c aws = AWS_Release_Notes_s3_creds__c.getInstance();
                                     String secretKey = aws.secretKey__c;
                                     String AccessKey = aws.AccessKey__c;
                                     String url = DocumentationController.getSignedUrlFromS3('rubrik-polaris-upgrades','Release_Notes/' + attch.Name, secretKey, AccessKey, 7200);
                                     
                                     jsGen.writeStringField('releaseNotes', url);
                                 }
                             }
                         }
                     } catch(exception e){
                         System.debug(LoggingLevel.DEBUG, 'Encountered exception while fetching release notes ' + e);
                         Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
                         exceptionErrorLog.Class__c = 'CdmUpgradeController';
                         exceptionErrorLog.Exception_Message__c = e.getMessage();
                         exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
                         errorLogList.add(exceptionErrorLog);
                     }
                 }
                 
                 jsGen.writeEndObject();
                 
                 if(Limits.getLimitQueries() < Limits.getQueries() + 10) {
                     break;
                 }
             }
             
             jsGen.writeEndArray();
             
             if(fetchLinks) {
                 AWS_Release_Notes_s3_creds__c aws = AWS_Release_Notes_s3_creds__c.getInstance();
                 String secretKey = aws.secretKey__c;
                 String AccessKey = aws.AccessKey__c;
                 String url = DocumentationController.getSignedUrlFromS3('rubrik-polaris-upgrades','SoftwareSupport/Rubrik CDM Software Support Lifecycle.pdf', secretKey, AccessKey, 7200);
                 
                 jsGen.writeStringField('softwareSupport', url);
                 
                 String url2 = DocumentationController.getSignedUrlFromS3('rubrik-polaris-upgrades','SoftwareSupport/Rubrik Compatibility Matrix.pdf', secretKey, AccessKey, 7200);
                 
                 jsGen.writeStringField('compatibilityMatrix', url2);
             }
             
             jsGen.writeEndObject();
             
             return jsGen.getAsString();
        }
         catch (Exception e) {
             System.debug(LoggingLevel.DEBUG, 'Exception>>>>> ' + e.getMessage());
             Custom_Error_Log__c exceptionErrorLog = new Custom_Error_Log__c();
             exceptionErrorLog.Class__c = 'CdmUpgradeController';
             exceptionErrorLog.Exception_Message__c = e.getMessage();
             exceptionErrorLog.ErrorTrace__c = e.getStackTraceString();
             errorLogList.add(exceptionErrorLog);
             
            return e.getMessage(); // Return null on exception or you can choose some default JSON if needed
        }
        // Finally block
        finally{
            System.debug(LoggingLevel.DEBUG, 'errorLogList: '+errorLogList);
            if(!errorLogList.isEmpty()){
                INSERT errorLogList;
            }
         }
    }
    
    /**
    * @description This method find the Product types that the customer entitles and then based on these product types the Software releases are retrunred in response.
    * @param AccountID
    * @return Set<String>
    */
    public static Set<String> getUserEntitledProductType(String AccountID){
        string acctId=AccountID;
        list<Entitlement> entList=new list<Entitlement>();
        Set<String> ProdTypes = new Set<String>();
        Set<String> EntProdTypes = new Set<String>();
        List<String> pickListValuesList= new List<String>();
        
        Schema.DescribeFieldResult fieldResult = Releases__c.Product_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }
      
        string q = 'SELECT Id, Product__r.Family, Product__r.Release_Product_Types__c, Product__c, EndDate FROM Entitlement';
        q += ' WHERE EndDate >= TODAY and AccountId = :acctId';
        
        entList = Database.query(q);
        
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
        return ProdTypes;
    }   
    
    /**
    * @description Get the documents fo the Release Softwares
    * @param releaseversionIDs
    * @param ProdTypes
    * @return Map<ID,List<Attachment>> 
    */
    public static Map<ID,List<Attachment>> getReleaseVDocs(Set<ID> releaseversionIDs,Set<String> ProdTypes){
        Map<ID,List<Attachment>> rvIdToReleaseAttachments=new Map<ID,List<Attachment>>();
        List<Attachment> relDocsList = new List<Attachment>();
        string rq = 'SELECT Id, Name,Release_Version__c, Product_Type__c, LastModifiedDate FROM Releases__c';
        rq += ' WHERE Release_Version__c IN :releaseversionIDs AND BlockedForDownloads__c = false AND Product_Type__c  in : ProdTypes';
        
      
        list<Releases__c> releasesList = Database.query(rq);
        set<string>SetReleaseId= new Set<string>();
        Map<ID,ID> releaseIDToReleaseVersionID=new Map<ID,ID>();
        for(Releases__c rls : releasesList){
            SetReleaseId.add(rls.id);
            releaseIDToReleaseVersionID.put(rls.id,rls.Release_Version__c);
        }
        String StringReleaseId = DocumentationController.quoteKeySet(SetReleaseId);
        if (string.isNotBlank(StringReleaseId)) { //added if check - CS21-830
            string q = 'SELECT Description,Id,Name,OwnerId,ParentId,LastModifiedDate FROM Attachment ';
            q += ' where ParentId in '+StringReleaseId +'';
            q += ' order by Name desc';
            relDocsList = Database.query(q);
        }
        for(Attachment ObjectAttachment : relDocsList){
            if(releaseIDToReleaseVersionID.containskey(ObjectAttachment.ParentID)){
                ID releaseVersionID=releaseIDToReleaseVersionID.get(ObjectAttachment.ParentID);
                if(rvIdToReleaseAttachments.containsKey(releaseVersionID)){
                        rvIdToReleaseAttachments.get(releaseVersionID).add(ObjectAttachment);
                }else{
                    rvIdToReleaseAttachments.put(releaseVersionID, new List<Attachment>{ObjectAttachment});
                }
            }
        }
        return rvIdToReleaseAttachments;
    }

    /**
    * @description getAllReleasesInternal
    * @param ProdType
    * @return List<Release_Software__c> 
    */
    public static List<Release_Software__c> getAllReleasesInternal(Set<String> ProdType) {
        List<Release_Software__c> relDocList = new List<Release_Software__c>();
        //Return the release softwares as per the Product types to which customer is entitled to
        if(ProdType!=NULL && ProdType.size()>0){
            string query = ' SELECT Release__r.Release_Version__r.Name, Release__r.Release_Version__r.Version__c, Release__r.Release_Version__r.Visible__c, Release__r.Release_Version__r.Release_Date__c, Release__r.Name, Release__r.Version__c, Release__r.Release_Date__c, Bytes__c,Id,Link__c,MD5__c,Name,Release__c, LastModifiedDate, Release_Type__c, Product_Type__c,S3_File_URL__c,S3_Bucket_Name__c, Release__r.Release_Version__r.End_Of_Support_Date__c FROM Release_Software__c ';
            query += ' WHERE Product_Type__c  IN:ProdType AND (Release__r.BlockedForDownloads__c = false)';
            query += ' order by Release__r.Release_Date__c Desc';
            
            relDocList = Database.query(query);
            return relDocList;
        }else{
            string query = ' SELECT Release__r.Release_Version__r.Name, Release__r.Release_Version__r.Version__c, Release__r.Release_Version__r.Visible__c, Release__r.Release_Version__r.Release_Date__c, Release__r.Name, Release__r.Version__c, Release__r.Release_Date__c, Bytes__c,Id,Link__c,MD5__c,Name,Release__c, LastModifiedDate, Release_Type__c, Product_Type__c,S3_File_URL__c,S3_Bucket_Name__c, Release__r.Release_Version__r.End_Of_Support_Date__c FROM Release_Software__c ';
            query += ' where Release__r.Release_Version__r.Name like \'%Rubrik CDM%\' and (not Release__r.Name like \'%(%)%\') and (not Release__r.Name like \'%WinPE%\') and (Release__r.BlockedForDownloads__c  = false)';
            query += ' order by Release__r.Release_Date__c Desc';
            
            relDocList = Database.query(query);
            return relDocList;
        }
    }

    /**
    * @description getReleaseMatrix
    * @return String 
    */
    public static String getReleaseMatrix() {
        AWS_Release_Notes_s3_creds__c aws = AWS_Release_Notes_s3_creds__c.getInstance();
        String secretKey = aws.secretKey__c;
        String AccessKey = aws.AccessKey__c;
        String url = DocumentationController.getSignedUrlFromS3('rubrik-polaris-upgrades','CDM_Upgradability_matrix/Upgradability_matrix.csv', secretKey, AccessKey, 3600);
        System.debug(LoggingLevel.DEBUG, url);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(url);
        req.setMethod('GET');
        HttpResponse res = h.send(req);
        return res.getBody();
    }

    /**
    * @description isMatrixVersionMatched
    * @param matrixTarballVersion
    * @param releaseVersion
    * @return Boolean
    */
    public static Boolean isMatrixVersionMatched(String matrixTarballVersion, String releaseVersion) {

        String parsedString = releaseVersion;
        // Remove the build number and replace all - with . for safer comparison
        if (releaseVersion.lastIndexOf('-') != -1) {
            parsedString = releaseVersion.substring(0, releaseVersion.lastIndexOf('-')).replaceAll('-', '.');
        }
        String matrixString = matrixTarballVersion.replaceAll('-', '.');
        return (parsedString == matrixString);
    }

    /**
    * @description Get cleanedMatrixEntry
    * @param str
    * @return String 
    */
    public static String cleanedMatrixEntry(String str) {
        return str.replaceAll(' ', '');
    }

    /**
    * @description parseReleaseMatrix
    * @param releaseMatrix
    * @param versionName
    * @return List<String>
    */
    public static List<String> parseReleaseMatrix(String releaseMatrix, String versionName) {
        List<String> matrix = releaseMatrix.split('\n');
        List<String> availableReleases = matrix[0].split('\t');

        List<string> allowedUpgrades = new List<String>();

        for(Integer i=1; i<matrix.size(); i++) {
            List<String> row = matrix[i].split('\t');
            if(isMatrixVersionMatched(cleanedMatrixEntry(row[0]), versionName)) {
                for(Integer j=1; j<row.size(); j++) {
                    if(cleanedMatrixEntry(row[j]).equalsIgnoreCase('t') || cleanedMatrixEntry(row[j]).equalsIgnoreCase('true')) {
                        allowedUpgrades.add(cleanedMatrixEntry(availableReleases[j]));
                    }
                }
                return allowedUpgrades;
            }
        }
        return new List<String>();
    }


    /**
    * @description getLeastReleaseFamilyFromMatrix
    * @param releaseMatrix
    * @return Integer 
    */
    public static Integer getLeastReleaseFamilyFromMatrix(String releaseMatrix) {
        List<String> matrix = releaseMatrix.split('\n');
        List<String> availableReleases = matrix[0].split('\t');

        Integer minVersion = 100;

        for (String release: availableReleases) {
            release = cleanedMatrixEntry(release);
            if (release.indexOf('.') > 0) {
                minVersion = math.min(minVersion, integer.valueof(release.substring(0, release.indexOf('.'))));
            }
        }

        return minVersion;
    }
}