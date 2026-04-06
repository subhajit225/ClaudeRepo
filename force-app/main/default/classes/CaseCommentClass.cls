/**
 * @Author      : 
 * @CreatedDate : 
 * @TstClass    : CaseCommentClassTest
 * -------------------------- @History -------------------------------------
 * Story Number       Modified By              Date           Description
 * CS21-2926          Vijay Kumar K R          Nov 20, 2024    Formatting issue when viewing Support cases from a mobile device
 * -------------------------------------------------------------------------
 */
 public class CaseCommentClass {

    private final List<CaseComment> cComment;
    public Id caseId {get; set;}
    public Boolean isPreview {get; set;}
    Set<Id> userIdSet = new Set<Id>();
    Map<Id,User> usrMap = new Map<Id,User>();
    public List<UserWrap> UserWrapList {get; set;}
    
    
    public CaseCommentClass(){
        isPreview =false;
    }

    public List<UserWrap> getCaseComment(){
        UserWrapList = new List<UserWrap>();
        Map<Id,User> usrmap = new Map<Id,User>([Select id,CompanyName,contactId,contact.Title,contact.Account.Name from User where id in :userIdSet]);

        Set<id> commentIds = new Set<Id>();
        if(caseId != NULL){
            Integer limits = 0;
            if(UserWrapList.isEmpty() ||  UserWrapList.size() < 3){
                //CS21-100 change
                if(isPreview != null && isPreview){
                    User u = [SELECT id,Name,Title,CompanyName FROM User WHERE id=: Userinfo.getUserId()];
                    UserWrap wrapPreview = new UserWrap();
                    wrapPreview.Name        = u.Name;
                    wrapPreview.Title       = u.Title;
                    wrapPreview.UserId = u.Id;
                    wrapPreview.CompanyName = u.CompanyName;
                    wrapPreview.LastModifiedDate = System.now();
                    wrapPreview.CommentBody = 'E2CA_Preview  E2CA_Preview';                    //-end
                    wrapPreview.ParentId         = caseId;   
                    wrapPreview.cc = new CaseComment();
                    UserWrapList.add(wrapPreview);
                }
                limits = UserWrapList.isEmpty() ? 3 : 3 - UserWrapList.size();
                Set<Id> CaseommentIds = new Set<id>(); //e2ca - 23 Jan 2023 - code added

                for(CaseComment cc : [SELECT id,CommentBody,CreatedById,CreatedBy.name,CreatedBy.title,ParentId FROM CaseComment  WHERE id Not IN :commentIds and parentid = :caseId and IsPublished = true  ORDER BY Createddate DESC LIMIT :limits]){
                    userIdSet.add(cc.CreatedById);
                    CaseommentIds.add(cc.id); //e2ca - 23 Jan 2023 - code added

                }
                
                //e2ca - 23 Jan 2023 - code added
                Map<Id,E2CAdv__CommentSourceControllers__c> CaseCommentIdtoCSC= new Map<id,E2CAdv__CommentSourceControllers__c>();
                for(E2CAdv__CommentSourceControllers__c CSC :[SELECT Id, Name, E2CAdv__Entity_Id__c, E2CAdv__Long_Comments_Id__c,E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body_Text__c ,
                                                              E2CAdv__Long_Comments_Id__r.E2CAdv__Parent__c,E2CAdv__Long_Comments_Id__r.E2CAdv__IsCommentTrimmed__c , E2CAdv__CaseCommentId__c
                                                              FROM E2CAdv__CommentSourceControllers__c where  E2CAdv__CaseCommentId__c in :CaseommentIds]){
                                                                  CaseCommentIdtoCSC.put(csc.E2CAdv__CaseCommentId__c,CSC);
                 }
                 
                //--end
                usrmap = new Map<Id,User>([Select id,CompanyName,contactId,contact.Title,contact.Account.Name from User where id in :userIdSet]);

                for(CaseComment cc : [SELECT id,CommentBody,CreatedById,CreatedBy.name,CreatedBy.title,LastModifiedDate ,ParentId FROM CaseComment  WHERE id Not IN :commentIds and parentid = :caseId and IsPublished = true ORDER BY Createddate DESC LIMIT :limits]){
                    
                    UserWrap uWrap = new UserWrap();
                    uWrap.Name        = cc .CreatedBy.Name;
                    uWrap.Title       = cc .CreatedBy.Title;
                    uWrap.CompanyName = usrmap.containskey(cc .CreatedById ) ? usrmap.get(cc .CreatedById ).CompanyName : '';
                    uWrap.cc = cc;
                    if(usrmap.containskey(cc.CreatedById) && usrmap.get(cc .CreatedById).contactId != null){
                        uWrap.Title = uWrap.Title == null ? usrmap.get(cc.CreatedById).Contact.Title : uWrap.Title;
                        uWrap.CompanyName = uWrap.CompanyName == null  ? usrmap.get(cc.CreatedById).Contact.Account.Name : uWrap.CompanyName ;
                        uWrap.UserId      = cc.CreatedById;
                    }
                    uWrap.LastModifiedDate = cc.LastModifiedDate ;
                    boolean hasbreak = false;
                    if(!String.isEmpty(cc.CommentBody) && (cc.CommentBody.contains('<br>') || cc.CommentBody.contains('<div>')))
                        hasbreak = true;
                    uWrap.hasBreak = hasBreak;
                    //e2ca - 23 Jan 2023 - modified
                    uWrap.CommentBody = (CaseCommentIdtoCSC.containsKey(cc.id) && CaseCommentIdtoCSC.get(cc.id).E2CAdv__Long_Comments_Id__r.E2CAdv__IsCommentTrimmed__c)?CaseCommentIdtoCSC.get(cc.id).E2CAdv__Long_Comments_Id__r.E2CAdv__Comment_Body_Text__c:cc.CommentBody;
                    try{
                        if(uWrap.CommentBody == null){uWrap.CommentBody = cc.CommentBody;}
                        uWrap.CommentBody = uWrap.CommentBody.replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('\n', '<br/>');
                    }catch(Exception e){
                        System.debug('e==>');
                    }

                    try {
                        // CS21-2926: Formatting issue when viewing Support cases from a mobile device
                        String commentBdy = uWrap.CommentBody;
                        if(String.isNotBlank(commentBdy)  
                            && commentBdy.containsIgnoreCase('Cc:')){
                                uWrap.CommentBody = extractEmailsFromCC(commentBdy);
                        }
                    } catch (Exception e) {
                        System.debug('extractEmailsFromCC expt==>'+e.getMessage());
                    }
                    
                    //-end
                    uWrap.ParentId = cc.ParentId;
                    UserWrapList.add(uWrap);

                }
            }
            if(UserWrapList!=NULL && UserWrapList.size()>0)
                return UserWrapList;
        }
        return NULL;
    }

    public static String extractEmailsFromCC(String commentBdy) {
        Pattern p = Pattern.compile('(?<=Cc: |CC: )(.*)');
        Matcher mtchr = p.matcher(commentBdy);
        if (mtchr.find()) {
            String ccText = mtchr.group(1).trim();
            String mailsWithSpaces;
            String finalCommentText;
            if(ccText.contains(' ')){
                String ccEmails = ccText.substring(0, ccText.indexOf(' '));
                mailsWithSpaces = ccEmails.replace(';','; ');
                finalCommentText = commentBdy.replace(ccEmails, mailsWithSpaces);
            }else{
                mailsWithSpaces = ccText.replace(';', '; ');
                finalCommentText = commentBdy.replace(mtchr.group(1), mailsWithSpaces);
            }
            return finalCommentText;
        } else {
            return commentBdy;
        }
    }

    public class UserWrap{
        public boolean hasBreak{get;set;}
        public string Name{get; set;}
        public string Title{get; set;}
        public string CompanyName{get; set;}
        public string CommentBody{get; set;}
        public Datetime LastModifiedDate{get; set;}
        public Id UserId{get;set;}
        public Id ParentId{get;set;}
        public caseComment cc{get;set;}
    }


}