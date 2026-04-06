/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community.
*******************************************************************************************************/
public class PC_ClaimController {
    /*******************************************************************************************************
    * @description Returns document
    * @param incentive id
    * @return documents
    ***********************************************************************************************************/
    @AuraEnabled
    public static List<wrapperClass> getdocs(string incentiveId)
    {
        system.debug('incentiveId----->'+incentiveId);
        List<wrapperClass> lst = new List<wrapperClass>();
        wrapperClass wrp = new wrapperClass();
        List<Attachment>  att = [SELECT Id, Name, ParentId, Parent.Type FROM Attachment where Parent.Type = 'Incentives__c' and ParentId=:incentiveId];
      for(Attachment at:att){
            wrp.name = at.Name;
            wrp.contentId = at.Id;
            lst.add(wrp);
            system.debug('lst value-->'+lst);  
        }
        return lst;
    }
    public class wrapperClass{
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String contentId {get;set;}
    }
}