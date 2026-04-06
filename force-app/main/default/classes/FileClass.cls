public without sharing class FileClass {
    
    public static ContentVersion insertCV(string filename, string body){
        Blob file = Blob.valueOf(body);
        ContentVersion cv = new ContentVersion(); 
        cv.VersionData = file; 
        cv.Title = fileName; 
        cv.PathOnClient = filename; 
        system.debug('@@ cv '+cv);
		return cv;
    }
    public static ContentVersion insertCVBlob(string filename, Blob file, Id netId){
        ContentVersion cv = new ContentVersion(); 
        cv.VersionData = file; 
        cv.Title = fileName; 
        cv.PathOnClient = filename;
        if(netId != null){
            cv.NetworkId = netId;
        }
        system.debug('@@ cv '+cv);
		return cv;
    }
    public static ContentDocumentLink insertCDL(string cdId, string parentId){
        ContentDocumentLink cdl = new ContentDocumentLink(); 
        cdl.ContentDocumentId = cdId; 
        cdl.LinkedEntityId = parentId; 
        cdl.ShareType = 'I'; 
        Cdl.Visibility = 'AllUsers'; 
        return cdl;
    }

}