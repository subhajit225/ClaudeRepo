/**
 * @author Shiva Sharma
 * @created 05-03-2020
 * @description This Controller is used on the Assist Request Record Page.
 *
 * @testclass AssistRequestFormControllerTest
 * @visualforce ProvideNextSteps, ProvideResolution, NotesRelatedList
 * @lightningcomponent LGT_ProvideNextStep
 *
 * ----------------------------- Change Log -----------------------------
 * Modified By      Date         Description
 * Shiva Sharma     21-01-2021   Save draft for GET Team "Provide Next Steps".
 *                               Made resolution field mandatory when any box is
 *                               selected in "Mark Assist Request Resolved" section.
 *                               Added comment number to AR.
 * Shiva Sharma     30-10-2023   Added logic to update timestamp when GET Team provides steps.
 * Raveesh Layal    11-04-2025   (CS21-3147) Support/CustomerSuccess Record Type handling in Assist Request.
 * ----------------------------------------------------------------------
 */
public class UpdateAssistRequestController {
    public Assist_Request__c assistRequest {get; set;}
    public Note noteRec{get;set;}
    public boolean read{get;set;}
    public List<notesWrapper> notes {get; set;}
    public string recId{get;set;}
    public String isReopen {get; set;}
    public String brownbagCom{get; set;}
    public String improvementCom{get; set;}
    public String troubleShootingCom{get; set;}
    public String existingToolCom{get; set;}
    public String searchUnifyCom{get; set;}
    public String othersCom{get; set;}
    public String reopenText{get; set;}
    public boolean isShow {get; set;}
    public boolean isOveride {get; set;}
    public string oldNextStepVal{get;set;}
    public String callJS{get; set;}
    public String jstext{get; set;}
    public String overideReason{get; set;}
    /**
     * @description Sets True when the record type is Support and false when it is Customer Success.
     * @return Boolean
     */
    public Boolean supporRecordType{get; set;}
    public UpdateAssistRequestController(ApexPages.StandardController controller) {
        String pageName = ApexPages.currentPage().getUrl().split('apex/')[1];
        if(pageName.contains('ViewAndEdit')){
            read = false;
            recId = ApexPages.currentPage().getParameters().get('id');
            noteRec = [Select Id,body,ParentId,Title,OwnerId from Note where Id=:recId];
            assistRequest = [Select Name,Case__c,Status__c from Assist_Request__c where Id =: noteRec.ParentId];
        }else{
            isOveride = false;
            if(!Test.isRunningTest()){
                controller.addFields(new List<String>{'InsightId__c','Case_Owner__c','Summary_of_the_Issue_Problem_Statement__c','Assist_Request_Fullfilled__c','Status__c','Case__r.OwnerId','Case__c','Name','Findings_and_Steps_Taken__c',
                    'Brownbag_Candidate__c','Product_Improvement_Needed__c','Issue_Understanding_Troubleshooting__c','Usage_of_Existing_tools__c','Usage_of_Knowledge_base_searchunify__c','Others__c'});
                assistRequest = (Assist_Request__c)controller.getRecord();
            }else{
                assistRequest = [select id,InsightId__c,Case_Owner__c,Summary_of_the_Issue_Problem_Statement__c,Assist_Request_Fullfilled__c,Status__c,Case__r.OwnerId,Case__c,Name,Brownbag_Candidate__c,
                                 Product_Improvement_Needed__c,Issue_Understanding_Troubleshooting__c,Usage_of_Existing_tools__c,Usage_of_Knowledge_base_searchunify__c,Others__c from Assist_Request__c where id=: controller.getId() ];
            }
            assistRequest.Summary_of_the_Issue_Problem_Statement__c = '';
            assistRequest.Assist_Request_Fullfilled__c = '';
            assistRequest.Findings_and_Steps_Taken__c = '';
            //Changes CS21-373 start
            List<Note> notesList = [select id,Body,CreatedBy.Name,CreatedDate,isPrivate from Note where ParentId =:assistRequest.Id ORDER BY  CreatedDate desc];
            notes = new List<notesWrapper>();
            for(Integer i=0;i<notesList.size();i++){
                notesWrapper wrap = new notesWrapper(notesList[i],notesList.size()-i);
                System.debug(wrap);
                notes.add(wrap);
            } 
            //Changes CS21-373 end
            isShow = false;
        }
    }
 
    public void updateViewAndEditNotes(){
        update noteRec;
        String body = noteRec.body;
        if(body.length() > 4000){
            body = body.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
        }
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = 'AR Comment Updated('+assistRequest.Name+'): '+ body.substringAfter('):'));
    	read = true;
    }
    
    public void onEdit(){
        read = false;
    }
    
    public void onCancel(){
        read = true;
    }
    public void actionIt(){
        String selectedVal = Apexpages.currentPage().getParameters().get('selectedValue');
        isShow = selectedVal == 'Unresolved/Request Reopen' ? true : false;
    }
    public void updateOveride(){
        isOveride = true;
        
    }
    
    public void callJSMethod(){
        callJS = '<script>callJSScript();</script>';
    }
    
    public pagereference updateClose(){
        if(assistRequest.Assist_Request_Fullfilled__c != 'Response Update Assist Request')
            assistRequest.Status__c = 'Closed';
        if(isReopen == 'Yes'){
            assistRequest.Status__c = 'Open';
            assistRequest.OwnerId = [SELECT Id, Name, DeveloperName, Type FROM Group where type = 'Queue' and DeveloperName = 'Assistance_Request'].Id;
        }
        if((assistRequest.Assist_Request_Fullfilled__c == 'Unresolved/Request Reopen') || Test.isRunningTest()){
           reopenText = 'Assist Request Comments('+assistRequest.Name+'): '+reopenText;
            insert new Note(ParentId = assistRequest.Id,Body  = reopenText,title='Recommendation/Next Steps Provide');
            if(reopenText.length() > 4000){
                reopenText = reopenText.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
            }
            insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = reopenText);
        }
        insert new Note(ParentId = assistRequest.Id,Body  = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.Summary_of_the_Issue_Problem_Statement__c,title='Recommendation/Next Steps Provide');
        insert new Note(ParentId = assistRequest.Id,Body  = 'Assist Request Overide Reason('+assistRequest.Name+'): '+overideReason,title='Recommendation/Next Steps Provide');
        String summaryText = assistRequest.Summary_of_the_Issue_Problem_Statement__c;
        if(!String.isEmpty(summaryText) && summaryText.length() > 4000){
            summaryText = summaryText.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
        }
        if(!String.isEmpty(overideReason) && overideReason.length() > 4000){
            overideReason = overideReason.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
        }
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = 'Assist Request Overide Reason('+assistRequest.Name+'): '+overideReason);
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = 'Assist Request Comments('+assistRequest.Name+'): '+summaryText);
        
        if(assistRequest.Status__c == 'Closed')assistRequest.Closed_Date__c = System.now();
        update assistRequest;
        update new Case(id = assistRequest.Case__c,Open_Assist_request__c = [select id from Assist_Request__c where status__c != 'Closed' AND Case__c =: assistRequest.Case__c].size());
        Pagereference pref = new PageReference('/'+assistRequest.Id);
        pref.setRedirect(true);
        return pref;
    }
    
    public pagereference copyMe(){
        try{
            CaseTeamMember ctm = new CaseTeamMember();
            ctm.ParentId = assistRequest.Case__c;
            ctm.MemberId = Userinfo.getUserId();
            ctm.TeamRoleId = [select id from CaseTeamRole where name ='Case Accelerator'].Id;
            insert ctm;
        }catch(exception e){
            
        }
        Pagereference pref = new PageReference('/'+assistRequest.Id); 
        pref.setRedirect(true);
        return pref;
    }
    
    public pagereference assignToMe(){
        assistRequest.OwnerId = UserInfo.getUserId();
        update assistRequest;
        Pagereference pref = new PageReference('/'+assistRequest.Id); 
        pref.setRedirect(true);
        return pref;
    }
    
    @AuraEnabled
    public static void assignToMe(String recordId){
        Assist_Request__c assistRequest = new Assist_Request__c(id=recordId);
        assistRequest.OwnerId = UserInfo.getUserId();
        update assistRequest;
    }
    
    
    @InvocableMethod(label='CaseComment and Notes' description='Add case comment and notes under the .')
    public static List<ID> getAssistRequest(List<ID> ids) {
        List<CaseComment> caseComments = new list<CaseComment>();
        List<Note> assistNotes = new list<Note>();
        List<Assist_Request__c> assistRequests = [SELECT id,Findings_and_Steps_Taken__c,Case__c,Name FROM Assist_Request__c WHERE Id in :ids];
        for (Assist_Request__c request : assistRequests) {
            request.Findings_and_Steps_Taken__c = 'Assist Request Comments('+request.Name+'): '+request.Findings_and_Steps_Taken__c;
            String findingStep = request.Findings_and_Steps_Taken__c;
            if(findingStep.length() > 4000){
                findingStep = findingStep.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
            }
            caseComments.add(new CaseComment(ParentId = request.Case__c,isPublished = false,CommentBody = findingStep));
            assistNotes.add(new Note(ParentId = request.Id,Body  = request.Findings_and_Steps_Taken__c,title='Recommendation/Next Steps Provide'));
        }
        if(!test.isRunningTest())
            insert caseComments;
        insert assistNotes;
        return ids;
    }
    public Pagereference addNextSteps(){
        Assist_Request__c newAssist =[select id,AR_Update__c,Case_Owner__c,Summary_of_the_Issue_Problem_Statement__c,Assist_Request_Fullfilled__c,Status__c,Case__r.OwnerId,Case__c,Name from Assist_Request__c where id=: assistRequest.Id ];
        newAssist.Findings_and_Steps_Taken__c = assistRequest.Findings_and_Steps_Taken__c;
        newAssist.AR_Update__c = assistRequest.Findings_and_Steps_Taken__c;
        newAssist.Next_Step_Datestamp__c = system.now();
        update newAssist;
        //Changes CS21-373 start
        List<Note> notesList = [Select Id from Note where parentId = :assistRequest.Id AND isPrivate = true];
        if(!notesList.isEmpty()){
            delete notesList;
        }
        //Changes CS21-373 end
        Pagereference pref = new PageReference('/'+assistRequest.Id);
        pref.setRedirect(true);
        return pref;
    }
    //Changes CS21-373 start
    public  void deleteARNote(){
        List<Note> notesList = [Select Id from Note where parentId = :assistRequest.Id AND isPrivate = true];
        System.debug('notes'+notes);
        delete notesList;
        notes = new List<notesWrapper>();
        List<Note> noteList = [select id,Body,CreatedBy.Name,CreatedDate,isPrivate from Note where ParentId =:assistRequest.Id ORDER BY  CreatedDate desc];
        notes = new List<notesWrapper>();
        for(Integer i=0;i<noteList.size();i++){
            notesWrapper wrap = new notesWrapper(noteList[i],noteList.size()-i);
            notes.add(wrap);
        }  
    }
    /**
        * @description Loads comments and related information from the Assist Request record into controller variables.
        * @return void
    */
    public void resolutionDraft(){
       Assist_Request__c ar = [Select Id,Brownbag_Candidate_Comment__c,Product_Improvement_Needed_Comment__c,Issue_Troubleshooting_Comment__c,Usage_of_Existing_tools_Comment__c,Usage_of_Knowledge_base_Comment__c,Others_Comment__c,RecordType.DeveloperName from Assist_Request__c where Id=:assistRequest.Id WITH SECURITY_ENFORCED];
        brownbagCom = ar.Brownbag_Candidate_Comment__c;
        improvementCom = ar.Product_Improvement_Needed_Comment__c;
        troubleShootingCom = ar.Issue_Troubleshooting_Comment__c;
        existingToolCom = ar.Usage_of_Existing_tools_Comment__c;
        searchUnifyCom = ar.Usage_of_Knowledge_base_Comment__c;   
        othersCom = ar.Others_Comment__c;        
        supporRecordType= ar.RecordType.DeveloperName == 'Support'? true:false;              
    }
    
    public void autosave()
    {
        List<Note> nt = new List<Note>();
        String returnVal = '';
        nt = [Select Id,body from Note where ParentId = :assistRequest.Id AND isPrivate = true];
        if(assistRequest.Findings_and_Steps_Taken__c != '' && assistRequest.Findings_and_Steps_Taken__c != null){
            if(nt.isEmpty()){
                Note newnt = new Note(ParentId = assistRequest.Id, body = assistRequest.Findings_and_Steps_Taken__c, isPrivate = true,Title = 'AR Note - '+assistRequest.Id);
                nt.add(newnt);
            }else{
                nt[0].Body = assistRequest.Findings_and_Steps_Taken__c;
            }
            upsert nt;
        }else{
            if(!nt.isEmpty()){
                if(oldNextStepVal != '' && oldNextStepVal != Null){
                    delete nt;    
                }
            }
        }
        if(!nt.isEmpty()){
            assistRequest.Findings_and_Steps_Taken__c = nt[0].Body;
            oldNextStepVal = nt[0].Body;
        }
    }
    
    @AuraEnabled
    public static string autoSaveNote(String parentId,String note,String oldNextSteps){
        List<Note> nt = new List<Note>();
        String returnVal = '';
        nt = [Select Id,body from Note where ParentId = :parentId AND isPrivate = true];
        if(note != '' && note != null){
            if(nt.isEmpty()){
                Note newnt = new Note(ParentId = parentId, body = note, isPrivate = true,Title = 'AR Note - '+parentId);
                nt.add(newnt);
            }else{
                nt[0].Body = note;
            }
            upsert nt;
        }else{
            if(!nt.isEmpty()){
                if(oldNextSteps != '' && oldNextSteps != null){
                    delete nt;
                }
            }
        }
        if(!nt.isEmpty()){
            returnVal = nt[0].Body;
        }
        return returnVal;
    }
    //Changes CS21-373 end
    @AuraEnabled 
    public static void addResponse(String recordId,String response){
        Assist_Request__c newAssist =[select id,Case_Owner__c,Summary_of_the_Issue_Problem_Statement__c,Assist_Request_Fullfilled__c,Status__c,Case__r.OwnerId,Case__c,Name from Assist_Request__c where id=: recordId ];
        newAssist.Assist_Request_Fullfilled__c = 'Response Update Assist Request';
        newAssist.AR_Update__c = response;
        newAssist.Status__c = newAssist.Status__c == 'Waiting On Support Engineer' ? 'In Progress' : newAssist.Status__c;
        insert new Note(ParentId = newAssist.Id,Body  = 'Assist Request Comments('+newAssist.Name+'): '+response,title='Recommendation/Next Steps Provide');
        if(response.length() > 3700){
            response = response.substring(0, 3700)+'[Comment truncated - Please open Assist Request to view full message]';
        }
        insert new CaseComment(ParentId = newAssist.Case__c,isPublished = false,CommentBody = 'Assist Request Comments('+newAssist.Name+'): '+response);
        update newAssist;
    }
    
    public Pagereference addResponse(){
        Assist_Request__c newAssist =[select id,Case_Owner__c,Summary_of_the_Issue_Problem_Statement__c,Assist_Request_Fullfilled__c,Status__c,Case__r.OwnerId,Case__c,Name from Assist_Request__c where id=: assistRequest.Id ];
        newAssist.Assist_Request_Fullfilled__c = 'Response Update Assist Request';
        newAssist.AR_Update__c = assistRequest.Summary_of_the_Issue_Problem_Statement__c;
        newAssist.Status__c = newAssist.Status__c == 'Waiting On Support Engineer' ? 'In Progress' : newAssist.Status__c;
        insert new Note(ParentId = assistRequest.Id,Body  = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.Summary_of_the_Issue_Problem_Statement__c,title='Recommendation/Next Steps Provide');
        String summary = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.Summary_of_the_Issue_Problem_Statement__c;
        if(summary.length() > 4000){
            summary = summary.substring(0, 3900)+'[Comment truncated - Please open Assist Request to view full message]';
        }
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = summary);
        update newAssist;
        Pagereference pref = new PageReference('/'+assistRequest.Id);
        pref.setRedirect(true);
        return pref;
    }
  
    public  Pagereference resolveRequest(){
        Pagereference pref;
        //Changes CS21-373 start
        if(assistRequest.Brownbag_Candidate__c || assistRequest.Product_Improvement_Needed__c || assistRequest.Issue_Understanding_Troubleshooting__c || assistRequest.Usage_of_Existing_tools__c || assistRequest.Usage_of_Knowledge_base_searchunify__c || assistRequest.Others__c){
            if(brownbagCom != null){
                assistRequest.Brownbag_Candidate_Comment__c = brownbagCom;
            }
            if(improvementCom != null){
                assistRequest.Product_Improvement_Needed_Comment__c = improvementCom;
            }
            if(troubleShootingCom != null){
                assistRequest.Issue_Troubleshooting_Comment__c = troubleShootingCom;
            }
            if(existingToolCom != null){
                assistRequest.Usage_of_Existing_tools_Comment__c = existingToolCom;
            }
            if(searchUnifyCom != null){
                assistRequest.Usage_of_Knowledge_base_Comment__c = searchUnifyCom;     
            }
            if(othersCom != null){
                assistRequest.Others_Comment__c = othersCom;
            }
            if(assistRequest.Status__c != 'Closed')
                assistRequest.Status__c = 'Resolved';
            update assistRequest;
            pref = new PageReference('/'+assistRequest.Id);
            pref.setRedirect(true);
            
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Error: Selection Required'));
            pref =  null;
        }
        return pref;
        //Changes CS21-373 end
    }
    
    @AuraEnabled
    public static AssistWrapper  getRecord(String recordId){
        return new AssistWrapper([Select id,Case_Owner__c,Summary_of_the_Issue_Problem_Statement__c,Assist_Request_Fullfilled__c,Status__c,Case__r.OwnerId,Case__c,Name from Assist_Request__c where id = :recordId]);
    }
    public static List<String> getEnvironmentList(String selectedObject,String selectedField){
        List<String> pickListValuesList= new List<String>();
        // Get the field dynamically
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(selectedObject).getDescribe().fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getValue());
        }     
        return pickListValuesList;
    }
    @AuraEnabled
    public static void updateNextSteps(String recordId,String nextSteps){
        update new Assist_Request__c(id=recordId,Findings_and_Steps_Taken__c=nextSteps,AR_Update__c = nextSteps, Next_Step_Datestamp__c = system.now());
        //Changes CS21-373 start
        List<Note> notesList = [Select Id from Note where parentId = :recordId AND isPrivate = true];
        delete notesList;
        //Changes CS21-373 end
    }
    
    @AuraEnabled
    public static void updateClose(Assist_Request__c assistRequest,String isReopen,String reopenText,String overideReason){
        if(assistRequest.Assist_Request_Fullfilled__c != 'Response Update Assist Request')
            assistRequest.Status__c = 'Closed';
        if(isReopen == 'Yes'){
            assistRequest.Status__c = 'Open';
            assistRequest.OwnerId = [SELECT Id, Name, DeveloperName, Type FROM Group where type = 'Queue' and DeveloperName = 'Assistance_Request'].Id;
        }
        if(assistRequest.Assist_Request_Fullfilled__c == 'Unresolved/Request Reopen'){
            reopenText = 'Assist Request Comments('+assistRequest.Name+'): '+reopenText;
            insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = reopenText);
            insert new Note(ParentId = assistRequest.Id,Body  = reopenText,title='Recommendation/Next Steps Provide');
        }
        if(assistRequest.Status__c == 'Closed')assistRequest.Closed_Date__c = System.now();
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.Summary_of_the_Issue_Problem_Statement__c);
        insert new Note(ParentId = assistRequest.Id,Body  = 'Assist Request Comments('+assistRequest.Name+'): '+assistRequest.Summary_of_the_Issue_Problem_Statement__c,title='Recommendation/Next Steps Provide');
        insert new CaseComment(ParentId = assistRequest.Case__c,isPublished = false,CommentBody = 'Assist Request Overide Reason('+assistRequest.Name+'): '+overideReason);
        insert new Note(ParentId = assistRequest.Id,Body  = 'Assist Request Overide Reason('+assistRequest.Name+'): '+overideReason,title='Recommendation/Next Steps Provide');
        
        update assistRequest;
        update new Case(id = assistRequest.Case__c,Open_Assist_request__c = [select id from Assist_Request__c where status__c != 'Closed' AND Case__c =: assistRequest.Case__c].size());
       
    }
    
    public class AssistWrapper{
        @AuraEnabled public Assist_Request__c assitRecord{get;set;}
        @AuraEnabled public List<String> fulfilledOptions{get;set;}
        public AssistWrapper(Assist_Request__c assitRecord){
            this.assitRecord =assitRecord;
            this.fulfilledOptions = getEnvironmentList('Assist_Request__c','Assist_Request_Fullfilled__c');
        }
    }
    //Changes CS21-373 start
    public class notesWrapper{
        @AuraEnabled public Note nt{get;set;}
        @AuraEnabled public Integer num{get;set;}
        public notesWrapper(Note nt,Integer num){
            this.nt = nt;
            this.num = num;
        }
    }
    //Changes CS21-373 end
}