public class CustomOppTeamMemberCntrl{
    public opportunityteammember OppTeamMember{get;set;}
    public boolean issaved{get;set;}
    public String oppName{get;set;}
    
    public CustomOppTeamMemberCntrl(){
        OppTeamMember = new opportunityteammember();
        OppTeamMember.userid = Userinfo.getuserid();
        issaved = true;
        if(ApexPages.currentPage().getParameters().get('oppId')!=null){
            String oppId = ApexPages.currentPage().getParameters().get('oppId');
            List<Opportunity> selectedOppLst;
            if(oppId!=null || oppId!=''){
                selectedOppLst = [select name from Opportunity where id = :oppId];
                if(selectedOppLst !=null && selectedOppLst.size()>0){
                    oppName = selectedOppLst[0].name;
                }
            }
        }
    }
    
    public pageReference addOppTeamMember(){    
        if(ApexPages.currentPage().getParameters().get('oppId')!=null){
            String oppId = ApexPages.currentPage().getParameters().get('oppId');
            String oppId1 = String.isBlank(oppId) ? null : String.escapeSingleQuotes(oppId.escapeHtml4());
            OppTeamMember.opportunityId = oppId1;
        }
        insert OppTeamMember;
        issaved = false;
        return null;
    }
    
     public pageReference close(){  
        String oppId = ApexPages.currentPage().getParameters().get('oppId');
        PageReference ref= new PageReference('/'+oppId);
        ref.setredirect(true);
        return ref;
    }
}