public with sharing class ServiceConsoleCommentExtension {
    private final Case caseRec;
    public CaseComment comment {get; set;}
    //public Case theCase {get; set;}
    //public string StatusChange {get; set;}

    public ServiceConsoleCommentExtension(ApexPages.StandardController controller) {
        caseRec = (Case)controller.getRecord();
        comment = new CaseComment();
        comment.parentid = caseRec.id;
    }

    public PageReference addComment() {
        insert comment;
        comment = new CaseComment();
        comment.parentid = caseRec.id;
        
        
        update caseRec;
        
        return null;
    }   
    
    
    // Get the Statuses
    public list<selectOption> getStatuses() {
      list<SelectOption> options = new list<SelectOption>();

          Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
            for (Schema.PicklistEntry pe : fieldResult.getPicklistValues()) {
                if(pe.getLabel()!='Closed' && !pe.getLabel().contains('Resolved') && pe.getLabel()!='New')
                {
                options.add(new SelectOption(pe.getValue(), pe.getLabel()));
                }
            }

          return options;
    }
    
}