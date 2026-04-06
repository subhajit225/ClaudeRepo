//Created by : PALAK
// UserStory : SF 1059
// TEST Class : POCRequestFormControllerTest
public class POCConverted{
    
    public POC__c poc;
    
    public POCConverted(ApexPages.StandardController stdController){
        poc = (POC__c)stdController.getRecord();
    }
    
    public pageReference markAsConvertedNonConverted() {
        
        List<Profile> prof = [select id from profile where name ='Order Manager' or name ='System Administrator'];
        
        if(prof != null && prof.size()>0){
            
            if(userinfo.getProfileId() == prof[0].id || (prof.size() >1 && userinfo.getProfileId() == prof[1].id)){
                
                list<POC__c> po = [select id,POC_Converted__c, POC_Type__c from POC__c where id=: poc.id];
                if(po != null && po.size()>0){
                    //if(!po[0].POC_Converted__c){
                        if(po[0].POC_Type__c != 'Conditional PO'){
                            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'POC Request can be marked converted/deConverted only for Conditional PO');
                            ApexPages.addMessage(myMsg);
                            return null;
                        }else{
                            
                            po[0].POC_Converted__c = !po[0].POC_Converted__c;
                            update po[0];
                            PageReference pocPage = new PageReference('/' + poc.id);
                            pocPage.setRedirect(true);
                            return pocPage;
                        }
                    /*}else{
                        
                        
                        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'POC Request is already converted');
                        ApexPages.addMessage(myMsg);
                        return null;
                    }*/
                }else return null;
                
                
            }else{
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'POC Request can be marked converted/deConverted only by Order Manager');
                ApexPages.addMessage(myMsg);
                return null;
            }
            
        }else{
             ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'POC Request can be marked converted/deConverted only by Order Manager');
             ApexPages.addMessage(myMsg);
             return null;
        }
        
    
    }
    
    public pageReference cancelPOC(){
        PageReference pocPage = new PageReference('/' + poc.id);
        pocPage.setRedirect(true);
        return pocPage;
    }

}