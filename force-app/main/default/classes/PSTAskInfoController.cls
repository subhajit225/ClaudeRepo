public class PSTAskInfoController {
    public PS_Task__c pstask{get;set;}
    public string callfunc{get;set;}
    public PSTAskInfoController(ApexPages.StandardController sc){
        Id psTaskId = sc.getId();
        pstask = [SELECT Id, Contact__c, Special_Handling_Instructions__c FROM PS_Task__c WHERE Id =: psTaskId];
        /*if(!Test.isRunningTest()){
            sc.addFields(new List<String>{'Contact__c','Special_Handling_Instructions__c'});
        }
        this.pstask = (PS_Task__c)sc.getRecord(); */
        if(pstask.Special_Handling_Instructions__c == null)
            pstask.Special_Handling_Instructions__c = 'An automated case will be created for Support to perform the data migration. Please supply the following required information. Be concise and provide any much information as possible to ensure the success of the data migration.<br/><br/> PSO contact details (name/email/phone):<br/><br/> Cluster UUID(s):<br/><br/> Specific instructions for the data migration:<br/> Customer desired maintenance window (day/time):';
    }
    
    public void saveandClose(){
        if(this.pstask.Special_Handling_Instructions__c == 'An automated case will be created for Support to perform the data migration. Please supply the following required information. Be concise and provide any much information as possible to ensure the success of the data migration.<br/><br/> PSO contact details (name/email/phone):<br/><br/> Cluster UUID(s):<br/><br/> Specific instructions for the data migration:<br/> Customer desired maintenance window (day/time):'){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Please enter value in the sandbox'));
        }
        update pstask;
        Case cs = [select id from case where PS_Task__c =: pstask.Id];
        String body = System.label.PS_Task_Comment_Body;
        body = body.replace('[[specialhandling]]', pstask.Special_Handling_Instructions__c+'<br/><br/>').replace('[[psId]]', pstask.Id).replace('[[Confluence]]','<br/><br/>Confluence');
        body = body.stripHtmlTags();
        insert new CaseComment(
            ParentId = cs.Id,
            isPublished = false,
            CommentBody = body
        );
        callfunc='<script> func(); </script>';
    }

}