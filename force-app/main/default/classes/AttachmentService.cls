/**
* @description Attachment service class for business functionality
*
* @CreatedDate 16th Jan 2024
* @Created By Shiva Sharma
* 
* @Test Class AttachmentServiceTest  
*/
public class AttachmentService {

      /**
    * @description Create Case comment when attachment is uploaded on Case
    * @param  newList - trigger context variable
    * @return void
    */
                
    public static void createCommentOnAttachmentUpload(List<Attachment> newAttachment) {
        Map<Id,User> userMap = new Map<Id,User>(); 
        Set<Id> caseRelatedAttachment = new Set<Id>();
        for(Attachment attachment : newAttachment){
            if(attachment.ParentId != null && attachment.ParentId.getSObjectType().getDescribe().getName() == 'Case'){
                userMap.put(attachment.OwnerId, new User());
                caseRelatedAttachment.add(attachment.ParentId);
            }
        }
        if(!caseRelatedAttachment.isEmpty()){
            userMap = new Map<Id,User>([SELECT Id, Email, FirstName, LastName FROM User WHERE Id IN: userMap.keySet()]);
            List<CaseComment> caseCommentList = new List<CaseComment>();
            for(Attachment attachment : newAttachment){
                if(caseRelatedAttachment.contains(attachment.ParentId)){
                    if (userMap.containsKey(attachment.OwnerId) && userMap.get(attachment.OwnerId)?.FirstName != 'Support'
                        && userMap.get(attachment.OwnerId)?.LastName != 'Bot'){
                            caseCommentList.add(new CaseComment(
                                ParentId = attachment.ParentId,
                                CommentBody = 'Attachment name : '+attachment.Name+'\n'
                            ));
                        }
                }
            }
            if(!caseCommentList.isEmpty()){
                insert caseCommentList;
            }
        }
    }
}