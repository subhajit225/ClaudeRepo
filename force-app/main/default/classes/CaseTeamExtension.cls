global class CaseTeamExtension {
    
    /* 
    Allows portal users to add contacts from within their company to get copied on Case updates.
    */
    
    public Case caseRec;
    
    public CaseTeamExtension(ApexPages.StandardController stdController) {
        try {
            this.caseRec = (Case) stdController.getRecord();
            caseRec = [select Id, AccountId from Case where Id = :caseRec.Id];

        } catch (Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ex.getMessage()));         
        }
    }
    
    public map<Id, CaseTeamMember> CaseTeamMembers {
        get {
            if (CaseTeamMembers == null) {
                CaseTeamMembers = new map <Id, CaseTeamMember>();

                for(CaseTeamMember ctm : [Select c.TeamTemplateMemberId, c.TeamRoleId, c.ParentId, c.MemberId, c.Id From CaseTeamMember c Where ParentId =: caseRec.Id]) {
                    if (AccountContacts.containsKey(ctm.MemberId)) {
                        CaseTeamMembers.put(ctm.MemberId, ctm);
                    }
                }
                system.debug('\n ### CaseTeamMember.size ' + CaseTeamMembers.size() + ' => ' + CaseTeamMembers);
            }
            
            return CaseTeamMembers;
        }
        
        private set;
    }
    
    public Integer CaseTeamMembersCount {
        get {
            system.debug('\n ### CaseTeamMembersCount ' + CaseTeamMembers.size());
            return CaseTeamMembers.size();
        }
        private set;
    }
    
    public boolean selectAll {
        get {
            system.debug('\n ### selectAll ' + (CaseTeamMembersCount == CaseTeamMembersAllCount));
            return (CaseTeamMembersCount == CaseTeamMembersAllCount); 
        }
        
        public set;
    }
    
    public map<Id, Contact> AccountContacts {
        get {
            if (AccountContacts == null) {
                AccountContacts = new map<Id, Contact>([Select c.Id, c.FirstName, c.LastName, c.Email, c.Name, c.AccountId From Contact c where c.Email!=null and c.AccountId =: caseRec.AccountId]);
            }
            return AccountContacts;
        }
        private set;        
    }
   
   public list<CaseTeamMemberWrapper> CaseTeamMembersAll {
        get {
            if (CaseTeamMembersAll == null) {
                CaseTeamMembersAll = new list<CaseTeamMemberWrapper>();
                
                for (Contact c : AccountContacts.values()) {
                    CaseTeamMembersAll.add(new CaseTeamMemberWrapper(c, CaseTeamMembers.get(c.id), CaseTeamMembers.containskey(c.id)));
                }
                system.debug('\n ### CaseTeamMembersAll.size ' + CaseTeamMembersAll.size() + ' => ' + CaseTeamMembersAll);
            }
            
            return CaseTeamMembersAll;
        }
        
        private set;
    }
    
    public Integer CaseTeamMembersAllCount {
        get {
            system.debug('\n ### CaseTeamMembersAllCount ' + CaseTeamMembersAll.size());
            return CaseTeamMembersAll.size();
        }
        private set;
    }
    
    //public string RoleId;
    public String EmailCCRoleId {
        get {
            if (EmailCCRoleId == null) {
                try {
                    EmailCCRoleId = [select Id from CaseTeamRole where Name = 'Email CC'].Id;
                } catch (Exception ex) {}   
            }
            
            return EmailCCRoleId;
        }
        
        private set;
    }
    
    public PageReference saveRec() {
        
        try {
            
            set<Id> ctm_To_Insert = new set<Id>(); 
            set<Id> ctm_To_Delete = new set<Id>();
            
            for(CaseTeamMemberWrapper ctmw : CaseTeamMembersAll) {

                if (ctmw.checked && !CaseTeamMembers.containsKey(ctmw.contact.Id)) {
                    ctm_To_Insert.add(ctmw.contact.Id);
                }
    
                if (!ctmw.checked && CaseTeamMembers.containsKey(ctmw.contact.Id)) {
                    ctm_To_Delete.add(ctmw.teamMember.Id);
                }
            }

            system.debug('\n ### ctm_To_Insert.size ' + ctm_To_Insert.size() + ' => ' + ctm_To_Insert);
            if (!ctm_To_Insert.isEmpty()) AddCaseTeamMember_future(caseRec.id, EmailCCRoleId, ctm_To_Insert);
            if (Test.isRunningTest()) AddCaseTeamMember(caseRec.id, EmailCCRoleId, ctm_To_Insert);
            
            system.debug('\n ### ctm_To_Delete.size ' + ctm_To_Delete.size() + ' => ' + ctm_To_Delete);
            if (!ctm_To_Delete.isEmpty()) DeleteCaseTeamMember_future(ctm_To_Delete);
            if (Test.isRunningTest()) DeleteCaseTeamMember(ctm_To_Delete); 
                        
        } catch (System.Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.SEVERITY.ERROR, e.getMessage()));
            return null;
        }
        
        return cancel();
    }
    

    @future
    public static void AddCaseTeamMember_future(Id caseId, Id roleId, set<Id> memberIds) {
        AddCaseTeamMember(caseId, roleId, memberIds);
    }
    
    public static void AddCaseTeamMember(Id caseId, Id roleId, set<Id> memberIds) {
        try {
            
            if (caseId == null || roleId == null || memberIds == null || memberIds.isEmpty()) return;
            
            system.debug('\n ### caseId ' + caseId + ' roleId ' + roleId);
            system.debug('\n ### memberIds to Insert ' + memberIds.size() + ' => ' + memberIds);
            list<CaseTeamMember> ctm_To_Insert = new list<CaseTeamMember>();
            
            for (Id cid : memberIds) {
                ctm_To_Insert.add(new CaseTeamMember(ParentId=caseId, MemberId=cid, TeamRoleId=roleId));
            }
            insert ctm_To_Insert;
            
        } catch (System.Exception e) {
            system.debug('\n ### error in AddCaseTeamMember_future ' + e.getMessage());
        }
    }   
    
    @future
    public static void DeleteCaseTeamMember_future(set<Id> ctmIds) {
        DeleteCaseTeamMember(ctmIds);
    }
    
    public static void DeleteCaseTeamMember(set<Id> ctmIds) {
        try {
            
            if (ctmIds == null || ctmIds.isEmpty()) return;
            
            system.debug('\n ### ctmIds to Delete ' + ctmIds.size() + ' => ' + ctmIds);
            list<CaseTeamMember> ctm_To_Delete = new list<CaseTeamMember>();
            
            for (Id cid : ctmIds) {
                ctm_To_Delete.add(new CaseTeamMember(Id=cid));
            }
            delete ctm_To_Delete;
            
        } catch (System.Exception e) {
            system.debug('\n ### error in DeleteCaseTeamMember_future ' + e.getMessage());
        }
    }   

    public PageReference cancel() {

        Pagereference pageRef = new Pagereference ('/' + caseRec.Id); 
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    // inner class
    public class CaseTeamMemberWrapper {
        public Boolean checked                      { get; set; }               
        public Contact contact                      { get; set; }
        public CaseTeamMember teamMember            { get; set; }       

        public CaseTeamMemberWrapper(Contact con, CaseTeamMember ctm, boolean selected) {
            contact = con;
            TeamMember = ctm;
            checked = selected;
        }
    }
    
       
    
    
    
    /////Create Contact
    
     @RemoteAction
    global static string createContact(String firstName, String lastName, String email, String title, String phone) {
    

        String retVal = '';

        try {

            Contact con = new Contact();
            con.FirstName = firstName;
            con.lastName = lastName;
            con.Email = email;
            con.Title = title;
            con.Phone = phone;          
            con.AccountId = Util.CurrentUser.Contact.AccountId;

            insert con;


        } catch (exception ex) {
            system.debug(' ### exception ' + ex);
            retVal = ex.getMessage();
        }

        return retVal;

    }


       //Create the Contact
      public Contact contact {
        get {
          if (contact == null)
            contact = new Contact(AccountId = Util.CurrentUser.Contact.AccountId);
          return contact;
        }
        set;
      }
    
      // save button is clicked
      public PageReference saveCon() {
    
        try {
          insert contact; 
        } catch (DMLException e) {
          ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,'Error creating new contact. ' + e));
          return null;
        }
    
        // if successfully inserted new contact, redirect to the last page. Parameter is added to force a full refresh of the page so the new contact shows up
        PageReference MUPage = new PageReference('/AddColleagues?id='+caseRec.Id+'&msg=newcon');
        MUPage.setRedirect(true);
        return MUPage;
      
      }
    

}