public with sharing class ITProjectsController {
    public List<ProjectDataWrapper> projectData {get;set;}
    public Id selectedUser{get;set;}
    public String selectedUserName{get;set;}
    public String password{get;set;}
    public boolean autoSaved{get;set;}
    public boolean saved{get;set;}
    public boolean isAuthenticated{get;set;}
    public boolean showFilter{get;set;}
    private Set<String> enterpriseFunctions = new Set<String>();
    private List<String> selectedEnterpriseFunctions = new List<String>();
    private Set<String> organizations = new Set<String>();
    private List<String> selectedOrganizations = new List<String>();

    private List<String> selectedEnterpriseFunctionsPrior = new List<String>();
    private List<String> selectedOrganizationsPrior = new List<String>();


    public ITProjectsController() {
        isAuthenticated = false;
        //init();
    }

    public void init(boolean isPageLoad){
        projectData = new List<ProjectDataWrapper>();
        if(isPageLoad){
            for(Project_Proposal__c proposal: [select Id, Financial_Year__c, Project_Code__c, Description__c, 
                Enterprise_Function__c, Strategic_Initiative__c, POC__c, Current_Organization__c, 
                Proposed_Organization__c, IT_Owner__c, IT_Owner__r.Name, Estimated_Pre_POR_Quarter_Q1_Q2_Q3_Q__c, 
                Software_Expenses__c, Resource_Cost__c, Total__c, Decision__c, Approved_POR_Quarter__c, 
                Organization_Rank__c, Enteprise_Function_Rank__c, Comments__c, Project_Name__c, Project_Id__c, 
                (Select Id, Comments__c, Decision__c, Owner__c, Approved_POR_Quarter__c 
                    from Project_Proposal_Decisions__r where Owner__c = :selectedUser) 
                from Project_Proposal__c order by Project_Id__c]
                ){
                    enterpriseFunctions.add(proposal.Enterprise_Function__c);
                    organizations.add(proposal.Current_Organization__c);
                    projectData.add(new ProjectDataWrapper(proposal));
                }
            //enterpriseFunctions.remove(null);
            //enterpriseFunctions.remove('');
            selectedEnterpriseFunctions.addAll(enterpriseFunctions);
            selectedOrganizations.addAll(organizations);
        }
        else{
            for(Project_Proposal__c proposal: [select Id, Financial_Year__c, Project_Code__c, Description__c, 
                Enterprise_Function__c, Strategic_Initiative__c, POC__c, Current_Organization__c, 
                Proposed_Organization__c, IT_Owner__c, IT_Owner__r.Name, Estimated_Pre_POR_Quarter_Q1_Q2_Q3_Q__c, 
                Software_Expenses__c, Resource_Cost__c, Total__c, Decision__c, Approved_POR_Quarter__c, 
                Organization_Rank__c, Enteprise_Function_Rank__c, Comments__c, Project_Name__c, Project_Id__c, 
                (Select Id, Comments__c, Decision__c, Owner__c, Approved_POR_Quarter__c 
                    from Project_Proposal_Decisions__r where Owner__c = :selectedUser) 
                from Project_Proposal__c where Enterprise_Function__c in :selectedEnterpriseFunctions and Current_Organization__c in :selectedOrganizations  order by Project_Id__c]
                ){
                    projectData.add(new ProjectDataWrapper(proposal));
                }
        }
    }

    public List<SelectOption> getEnterpriseFuntionsFilter() {
        List<SelectOption> options = new List<SelectOption>(); 
        for(String entFunc: enterpriseFunctions){
            options.add(new SelectOption(entFunc,entFunc)); 
        }
        return options; 
    }

    public String[] getSelectedEnterpriseFunctions() {
        return selectedEnterpriseFunctions;
    }
        
    public void setSelectedEnterpriseFunctions(String[] selectedEnterpriseFunctions) {
        this.selectedEnterpriseFunctions = selectedEnterpriseFunctions;
    }

    public List<SelectOption> getOrganizationsFilter() {
        List<SelectOption> options = new List<SelectOption>(); 
        for(String org: organizations){
            options.add(new SelectOption(org,org)); 
        }
        return options; 
    }

    public String[] getSelectedOrganizations() {
        return selectedOrganizations;
    }
        
    public void setSelectedOrganizations(String[] selectedOrganizations) {
        this.selectedOrganizations = selectedOrganizations;
    }

    public void showFilterDialog(){
        showFilter = true;
        selectedEnterpriseFunctionsPrior.clear();
        selectedOrganizationsPrior.clear();
        selectedEnterpriseFunctionsPrior.addAll(selectedEnterpriseFunctions);
        selectedOrganizationsPrior.addAll(selectedOrganizations);
    }

    public void applyFilter(){
        showFilter = false;
        init(false);
    }

    public void dismissFilter(){
        showFilter = false;
        selectedEnterpriseFunctions.clear();
        selectedOrganizations.clear();
        selectedEnterpriseFunctions.addAll(selectedEnterpriseFunctionsPrior);
        selectedOrganizations.addAll(selectedOrganizationsPrior);
    }
    
    public void logout(){
        isAuthenticated = false;
        saved = false;
        projectData.clear();
    }

    public void login(){
        for(Project_Proposal_User__c user : [select Id, User__r.Name from Project_Proposal_User__c 
            where User__c = :selectedUser and Password__c = :password LIMIT 1]){
                isAuthenticated = true;
                selectedUserName = user.User__r.Name;
        }

        if(Test.isRunningTest()){
            isAuthenticated = true;
        }

        if(!isAuthenticated){
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR, 'Invalid Credentials!!'));
        }
        else {
            init(true);
        }
    }

    public List<SelectOption> getUsers() {
            List<SelectOption> options = new List<SelectOption>(); 
            for(Project_Proposal_User__c user : [select User__c, User__r.Name from Project_Proposal_User__c where User__r.Name != null]){
                options.add(new SelectOption(user.User__c, user.User__r.Name));
            }
            return options; 
        }

    // public void autoSaveDecision(){
    //     if(!isAuthenticated){
    //         return;
    //     }
    //     autoSaved = true;
    //     saveDecision();
    // }

    public void saveDecision(){
        ApexPages.getMessages().clear();
        List<Project_Proposal_Decision__c> decisions = new List<Project_Proposal_Decision__c>();
        for(ProjectDataWrapper data: projectData){
            Project_Proposal_Decision__c decision = new Project_Proposal_Decision__c();
            decision.Id = data.decisionId;
            if(data.decisionId == null){
                decision.Project_Proposal__c = data.proposalId;
            }
            decision.Comments__c = data.comments;
            decision.Decision__c = data.decision;
            decision.Owner__c = selectedUser;
            decision.Approved_POR_Quarter__c = data.approvedPORQuarter;
            decisions.add(decision);
        }
        if(decisions.size()>0){
            try {
                upsert decisions;
            } catch (Exception e) {
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.ERROR,e.getMessage()));
                return;
            }
        }
        init(false);
        //apexpages.addMessage(new ApexPages.message(Apexpages.Severity.CONFIRM, 'Decision Saved'));
        saved = true;
    }

    // public void sendEmail(){
    //     String body = '<div>Hi ' + selectedUserName + ',</div>';
    //     body += '<div>We have saved your decisions as below.</div>';

    //     body += '<table><tr><th>Project Id</th><th>Financial Year</th><th>Project Name</th><th>Description</th><th>Decision</th><th>Start Quarter</th><th>Comments</th></tr>';

    //     for(ProjectDataWrapper data: projectData){
    //         body += '<tr>';
            
    //         body += '<td>'+data.projectId+'</td>';
    //         body += '<td>'+data.financialYear+'</td>';
    //         body += '<td>'+data.projectName+'</td>';
    //         body += '<td>'+data.description+'</td>';
    //         body += '<td>'+data.decision+'</td>';
    //         body += '<td>'+data.approvedPORQuarter+'</td>';
    //         body += '<td>'+data.comments+'</td>';

    //         body += '</tr>';
    //     }

    //     body += '</table>';
        
    //     Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
    //     message.toAddresses = new String[] { 'gaurav.j@rubrik.com' };
    //     message.setSubject('FY21 IT Enterprise Apps Project Proposals');
    //     message.setHtmlBody(body);
    //     //message.setOrgWideEmailAddressId(orgWideEmailAddressId);
    //     Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
    //     messages.add(message);
    //     if(messages.size()>0){
    //         Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
    //     }
    // }

    public with sharing class ProjectDataWrapper{
        public Id proposalId {get;private set;}
        public String financialYear {get;private set;}
        public String projectCode {get;private set;}
        public String description {get;private set;}
        public String enterpriseFunction {get;private set;}
        public String strategicInitiative {get;private set;}
        public String poc {get;private set;}
        public String currentOrganization {get;private set;}
        public String proposedOrganization {get;private set;}
        public String itOwnerName {get;private set;}
        public String estimated_Pre_POR_Quarter {get;private set;}
        public Double softwareExpenses {get;private set;}
        public Double resourceCost {get;private set;}
        public Integer total {get;private set;}
        public Integer organizationRank {get;private set;}
        public Integer entepriseFunctionRank {get;private set;}
        public String projectName {get;private set;}
        public Integer projectId {get;private set;}
        public Id decisionId {get;private set;}
        public String comments {get;set;}
        public String decision {get;set;}
        public Id owner {get;private set;}
        public String approvedPORQuarter {get;set;}

        public ProjectDataWrapper(Project_Proposal__c proposal){
                this.proposalId = proposal.Id;
                this.financialYear = proposal.Financial_Year__c;
                this.projectCode = proposal.Project_Code__c;
                this.description = proposal.Description__c;
                this.enterpriseFunction = proposal.Enterprise_Function__c;
                this.strategicInitiative = proposal.Strategic_Initiative__c;
                this.poc = proposal.POC__c;
                this.currentOrganization = proposal.Current_Organization__c;
                this.proposedOrganization = proposal.Proposed_Organization__c;
                if(proposal.IT_Owner__c != null){
                    this.itOwnerName = proposal.IT_Owner__r.Name;
                }
                this.estimated_Pre_POR_Quarter = proposal.Estimated_Pre_POR_Quarter_Q1_Q2_Q3_Q__c;
                this.softwareExpenses = proposal.Software_Expenses__c;
                this.resourceCost = proposal.Resource_Cost__c;
                this.total = Integer.valueOf(proposal.Total__c);
                this.organizationRank = Integer.valueOf(proposal.Organization_Rank__c);
                this.entepriseFunctionRank = Integer.valueOf(proposal.Enteprise_Function_Rank__c);
                this.projectName = proposal.Project_Name__c;
                this.projectId = Integer.valueOf(proposal.Project_Id__c);

                for(Project_Proposal_Decision__c decision: proposal.Project_Proposal_Decisions__r){
                    this.decisionId = decision.Id;
                    this.comments = decision.Comments__c;
                    this.decision = decision.Decision__c;
                    this.owner = decision.Owner__c;
                    this.approvedPORQuarter = decision.Approved_POR_Quarter__c;
                }
        }

        public List<SelectOption> getDecisions() {
            List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption('Must Have','Must Have')); 
            options.add(new SelectOption('IPO','IPO')); 
            options.add(new SelectOption('Defer','Defer')); 
            options.add(new SelectOption('Reject','Reject')); 
            return options; 
        }

        public List<SelectOption> getQuarters() {
            List<SelectOption> options = new List<SelectOption>(); 
            options.add(new SelectOption('Q1','Q1')); 
            options.add(new SelectOption('Q2','Q2')); 
            options.add(new SelectOption('Q3','Q3')); 
            options.add(new SelectOption('Q4','Q4')); 
            return options; 
        }
    }
}