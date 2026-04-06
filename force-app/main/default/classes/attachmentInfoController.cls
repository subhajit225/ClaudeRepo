public without sharing class attachmentInfoController {
    public String caseId {get;set;}
    public Case cs {get;set;}
    
    public wrapper getCaseAndAttachInfo(){
        wrapper wrap = new wrapper();
        
        if(caseId!=null){
            cs = [SELECT Id,CaseNumber,(SELECT Id,ContentDocumentId,ContentDocument.Owner.Name,ContentDocument.Owner.Account.Name,ContentDocument.Title,ContentDocument.ContentSize FROM ContentDocumentLinks ORDER BY ContentDocument.CreatedDate DESC LIMIT 1 ) FROM Case WHERE Id =: caseId];
            System.debug('cs......'+cs);
        }
        
        if(cs!=null){
            wrap.caseId = cs.Id;
            for(ContentDocumentLink each : cs.ContentDocumentLinks){
                Long fileSize = each.ContentDocument.ContentSize;
                String fileSizeString = '';
                
                fileSize = each.ContentDocument.ContentSize;
                    if(fileSize > 0 && fileSize <= 1023){
                        fileSizeString = ''+fileSize.format()+'Byte';
                    }
                    if(fileSize >= 1024 && fileSize <= 1047552){
                        fileSizeString = ''+(fileSize/1024).format()+'KB';
                    }
                    if(fileSize >= 1048576 && fileSize <= 1072693248){
                        fileSizeString = ''+(fileSize/1048576).format()+'MB';
                    }
                    if(fileSize >= 1073741824L && fileSize <= 2147483648L){
                        fileSizeString = ''+(fileSize/1073741824).format()+'GB';
                    }
                
                wrap.fileSize1 = fileSizeString;
                wrap.accName = each.ContentDocument.Owner.Account.Name;
                wrap.contentDocId = each.ContentDocumentId;
                wrap.title = each.ContentDocument.Title;
            }
            wrap.caseNumber = cs.CaseNumber;
        }
        
        System.debug('wrap----'+wrap);
        return wrap;
    }
    
    public class wrapper{
        public String caseId{get;set;}
        public String fileSize1{get;set;}
        public String caseNumber{get;set;}
        public String title{get;set;}
        public String accName{get;set;}
        public Id contentDocId{get;set;}
    }
}