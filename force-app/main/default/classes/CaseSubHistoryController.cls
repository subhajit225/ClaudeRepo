public class CaseSubHistoryController {

    /* this drives the email templates for the cases */
    public String cseID {get;set;}
    public Boolean isPrivate {get; set;}

     //Get the most recent Email
        public List<EmailMessage> getLastEmail() {
          if (cseID != null) {
            List<EmailMessage> cseEm = [Select ActivityId,CcAddress,CreatedById,CreatedDate,FromAddress,FromName,HasAttachment,Headers,HtmlBody,Id,Incoming,IsDeleted,IsExternallyVisible,LastModifiedDate,MessageDate,ParentId,RelatedToId,ReplyToEmailMessageId,Status,Subject,SystemModstamp,TextBody,ToAddress FROM EmailMessage where ParentId = :cseID order by SystemModstamp desc limit 1];
            return cseEm;
          }
          return new List<EmailMessage> ();
        }

     // As part of CS-306 --> to get case escalation details
         public case getcaseDetail() {
          if (cseID != null) {
            Case cseEm = [Select Id,Createddate,priority,contact.name,Product_Area__c,last_case_status__c,owner.name,contact.phone,contact.email,account.name,type,status,origin,contact_method__c,software_version__c from case where Id= :cseID order by SystemModstamp desc limit 1];
            return cseEm;
          }
          return new Case ();
        }


     //Get the most recent CaseComment
        public List<CaseComment> getLastComment() {
          if (cseID != null) {
             string querystring='Select CommentBody,CreatedById,CreatedBy.Name,CreatedDate,Id,IsDeleted,IsPublished,LastModifiedById,LastModifiedDate,ParentId,SystemModstamp FROM CaseComment where ParentId = :cseID and isPublished=true';
             querystring+=' order by SystemModstamp desc limit 1 ';
             List<CaseComment> cseCC = Database.query(querystring);
             return cseCC;
           }
          return new List<CaseComment> ();
        }

     //Get the most recent CaseComment regardless of published or not
        public List<CaseComment> getAnyComment() {
          if (cseID != null) {
             string querystring='Select CommentBody,CreatedById,CreatedBy.Name,CreatedDate,Id,IsDeleted,IsPublished,LastModifiedById,LastModifiedDate,ParentId,SystemModstamp FROM CaseComment where ParentId = :cseID';
             querystring+=' order by SystemModstamp desc limit 1 ';
             List<CaseComment> cseCC = Database.query(querystring);
             return cseCC;
           }
          return new List<CaseComment> ();
        }

     //Get the resolution details
        public string getResolutionText() {
          if (cseID != null) {
            string cseEm = [Select Resolution_Details__c from Case where Id = :cseID limit 1].Resolution_Details__c;
            string resStrip = cseEm.stripHtmlTags();
            return resStrip;
          }
          return null;
        }
      //Get History
      public String getE2CPHistory() {
        String Slink;
        if (cseID != null) {
            Case lcase = [Select Id FROM Case where Id = :cseID limit 1];
        }
        return Slink;
      //Get History
      }
      public String getResolutionDetails() {
        String Slink;
        if (cseID != null) {
            Case lcase = [Select Id, Resolution_Details__c FROM Case where Id = :cseID limit 1];
            Slink = lcase.Resolution_Details__c;
        }
        return Slink;
      }
      public String getDescription() {
        String Slink;
        if (cseID != null) {
            Case lcase = [Select Id, Description FROM Case where Id = :cseID limit 1];
            Slink = lcase.Description;
        }
        return Slink;
      }
}