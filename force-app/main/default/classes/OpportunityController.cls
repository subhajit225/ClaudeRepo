public class OpportunityController {
    
    private String opportunityID = '';
    public Opportunity primaryOpportunity { get; set; }
    public Double optyTotalValue { get; set; }
    public Decimal staticAmount { get; set; }
    
    public Opportunity user2Opty {
        get {
            if(user2Opty == null){
                user2Opty = new Opportunity();
            }
            return user2Opty;
        }
        set { }
    }
    
    public Opportunity user3Opty {
        get {
            if(user3Opty == null){
                user3Opty = new Opportunity();
            }
            return user3Opty;
        }
        set { }
    }
    
    public Opportunity user4Opty {
        get {
            if(user4Opty == null){
                user4Opty = new Opportunity();
            }
            return user4Opty;
        }
        set { }
    }

    public ID emailTemplateId{
        get {
            if(emailTemplateId == null) {
                EmailTemplate vEmailTemplate = [SELECT Id, Name, DeveloperName FROM EmailTemplate WHERE DeveloperName ='Notify_Opty_Split_Owners'];
                return vEmailTemplate.Id;
            }
            return emailTemplateId;
        }
        set { }
    }
    
  //Constructor
    public OpportunityController(ApexPages.StandardController controller){
        //Constructor 
        try {
            opportunityID = System.currentPageReference().getParameters().get('oId');
            //opportunityID = controller.getId();
            //opportunityID = '0061W00000rvYzv';
            /*
            primaryOpportunity = [Select ID, Name, Amount, OwnerId, Owner.Name, StageName,Probability,CDM_Owner__c,
            AccountId,CloseDate,Partner_Level_Of_Involvement__c,Valooto_Quote_Stage__c, 
            split_percentage__c, split_amount__c, 
            Partner_Lookup__c, Distributor_Lookup__c, Pricebook2Id,Opportunity_Sub_Type__c, Alliance_Partner_Name__c,
            Alliance_Source_Type__c,Incumbent__c,Other_Incumbent__c,Primary_Competitor__c,
            Compelling_Bus_Driver__c,Key_Feature_Needs__c, Win_Alert_Sent__c,Installation_Assigned_To__c, LeadSource,Deal_Registration_Type__c,
            Deal_Registration__c, Deal_Reg_Approval_Status__c, Deal_Reg_Submitted_Date__c, Deal_Reg_Approval_Timestamp__c, Deal_Reg_Expiration_Date__c, Deal_Registration_Number__c,
            Partner_Representative__c, Partner_Rep_Email_Address__c, Partner_SE_Name__c, Partner_SE_Email__c, Partner_SE_Phone__c, Distributor_Rep_Name__c, Distributor_Rep_Email__c, Distributor_Rep_Phone_Number__c,
            Deal_Registration_Link__c,Current_State__c,Initial_Contacts_Name__c,Cloud_Type__c,Alliance_HW_Partner__c,Alliance_Source_Type_SW__c,
            Alliance_Source_Type_HW__c,Rubrik_Sales_Engineer__c,Negative_Consequences__c,Future_State__c,Other_Primary_Competitor__c,
            Positive_Business_Outcomes__c,SBQQ__PrimaryQuote__c,Deal_Impact__c,Other_Key_Feature_Need__c,Win_Loss_Comments__c,Lost_To__c,
            Lost_Reason__c,Metric__c,Economic_Buyer__c,Decision_Criteria__c,Decision_Process__c,Identified_Pain__c,Champion__c,
            (Select Id, Product2Id, ProductCode, Name, TotalPrice From OpportunityLineItems), 
            (Select Id, OwnerId, Owner.Name, Owner.Email, Split_percentage__c, Split_Amount__c, split__c From Split_Opportunities__r) 
            From Opportunity Where ID =: OpportunityID];
            */
            ShGl_QueryConstants__mdt [] opptySplitQuery = [SELECT Query_String__c FROM ShGl_QueryConstants__mdt WHERE DeveloperName = 'OpportunitySplit_CopyQuery'];
            
            primaryOpportunity = Database.query(opptySplitQuery.get(0).Query_String__c +  ' WHERE Id = \'' +opportunityID+ '\'');
            
            //populate other splits
            for(Integer i = 0; i < primaryOpportunity.Split_Opportunities__r.size(); i++) {
                if(i == 0) {
                    user2Opty.OwnerId = primaryOpportunity.Split_Opportunities__r.get(i).OwnerId;
                    user2Opty.Id = primaryOpportunity.Split_Opportunities__r.get(i).Id;
                    user2Opty.split_percentage__c = primaryOpportunity.Split_Opportunities__r.get(i).split_percentage__c;
                    user2Opty.split_amount__c = primaryOpportunity.Split_Opportunities__r.get(i).split_amount__c;
                } else if(i == 1) {
                    user3Opty.OwnerId = primaryOpportunity.Split_Opportunities__r.get(i).OwnerId;
                    user3Opty.Id = primaryOpportunity.Split_Opportunities__r.get(i).Id;
                    user3Opty.split_amount__c = primaryOpportunity.Split_Opportunities__r.get(i).split_amount__c;
                    user3Opty.split_percentage__c = primaryOpportunity.Split_Opportunities__r.get(i).split_percentage__c;
                } else if(i == 2) {
                    user4Opty.OwnerId = primaryOpportunity.Split_Opportunities__r.get(i).OwnerId;
                    user4Opty.Id = primaryOpportunity.Split_Opportunities__r.get(i).Id;
                    user4Opty.split_amount__c = primaryOpportunity.Split_Opportunities__r.get(i).split_amount__c;
                    user4Opty.split_percentage__c = primaryOpportunity.Split_Opportunities__r.get(i).split_percentage__c;
                }
                
            }
            
            optyTotalValue = 0.00;
            staticAmount = 0.00;
            for(OpportunityLineItem vLineItem : primaryOpportunity.OpportunityLineItems){
                System.debug('@@vLineItem: '+vLineItem+'\n\n\n');
                if(vLineItem.ProductCode == 'OPTY-SPLIT'){
                    if(vLineItem.TotalPrice > 0){
                        optyTotalValue = optyTotalValue+vLineItem.TotalPrice;
                        staticAmount = vLineItem.TotalPrice;
                    } 
                } else {
                    optyTotalValue = optyTotalValue+vLineItem.TotalPrice;
                }
            }
            if(optyTotalValue == 0.00){
                optyTotalValue = primaryOpportunity.Amount;
            }
            
        } catch (exception e) {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occured while splitted Opportunity. Please contact System Administrator.');
            ApexPages.addMessage(msg);
        }
        System.debug('@@optyTotalValue: '+optyTotalValue);
        if(optyTotalValue == null){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Parent Opportunty Must have an Amount.');
            ApexPages.addMessage(msg);
        }
    }
    public OpportunityController() {
        
    }

    //Cancel button
    public pageReference cancelAction() {
        return returnToOrigination();
    }

    //Primary Method
    public pageReference saveItem() {
        System.debug('@@BEGIN SAVE ITEM: '+staticAmount+'\n\n\n');
        Id[] emailAddresses = new Id[]{};
            
        flowControll.OpportunityTriggerHandler = false;
        
        system.debug('@@Processing Start');
        
        if(staticAmount>0){
            OpportunitySplitHelper.createAmountProduct(primaryOpportunity, staticAmount);
            optyTotalValue=staticAmount;
        }
        List<Opportunity> updateList = new List<Opportunity>();
        
        //calculate the number of users that have an amount defined
        Double splitAmounts=0.00;
        system.debug('User2Opty :: '+User2Opty);
        system.debug('User3Opty :: '+User3Opty);
        system.debug('User4Opty :: '+User4Opty);
        splitAmounts=User2Opty.split_amount__c + User3Opty.split_amount__c + User4Opty.split_amount__c;  
        optyTotalValue=optyTotalValue-splitAmounts;
        
        List<OpportunitySplitMapping__c> oppSplitMapping = [SELECT Skip_Update_if_child_has_value__c,Default_Value__c,Field__c,From_Field__c,Id,Name,Prefix__c,Suffix__c FROM OpportunitySplitMapping__c];
        
        if(user2Opty.OwnerId != null) {
            user2Opty = OpportunitySplitHelper.copyOpportunityFieldToSplit(user2Opty, primaryOpportunity, oppSplitMapping);
            if(user2Opty.split_amount__c > 0) {
                user2Opty.Amount = user2Opty.split_amount__c;
            } else {
                user2Opty.Amount = optyTotalValue * (user2Opty.split_percentage__c / 100);
            }
            user2Opty.split__c = true;
            updateList.add(user2Opty);
            emailAddresses.add(user2Opty.OwnerId);
        }
        
        if(user3Opty.OwnerId != null) {
            OpportunitySplitHelper.copyOpportunityFieldToSplit(User3Opty, primaryOpportunity, oppSplitMapping);
            if(user3Opty.split_amount__c > 0) {
                user3Opty.Amount = User3Opty.split_amount__c;
            } else {
                user3Opty.Amount = optyTotalValue * (User3Opty.split_percentage__c / 100);
            }
            user3Opty.split__c = true;
            updateList.add(user3Opty);
            emailAddresses.add(user3Opty.OwnerId);
        }
        
        if(user4Opty.OwnerId != null) {
            OpportunitySplitHelper.copyOpportunityFieldToSplit(user4Opty, primaryOpportunity, oppSplitMapping);
            if(user4Opty.split_amount__c > 0) {
                user4Opty.Amount = user4Opty.split_amount__c;
            } else {
                user4Opty.Amount = optyTotalValue * (user4Opty.split_percentage__c / 100);
            }
            user4Opty.split__c = true;
            updateList.add(user4Opty);
            emailAddresses.add(user4Opty.OwnerId);
        }
        
        if(updateList.size() > 0) {
            /*upsert child split opportunities*/
            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.allowSave = true;
            dml.DuplicateRuleHeader.runAsCurrentUser = true; 
            
            System.debug('@@updateList: '+updateList);
            //sort the updates and insert - upsert won't work with the DML options
            List<Opportunity> insertOpt = new List<Opportunity>();
            List<Opportunity> updateOpt = new List<Opportunity>();
            for(Opportunity vOpt : updateList) {
                System.debug('@@vOpt: '+vOpt.Id);
                if(vOpt.Id != null) {
                    updateOpt.add(vOpt);      
                } else {
                    insertOpt.add(vOpt);
                }
            }
            
            System.debug('@@insertOpt: '+insertOpt);
            List<Database.SaveResult> saveResult;
            if(!insertOpt.isEmpty()) {
                saveResult = Database.insert(insertOpt, dml);
            }
            
            System.debug('@@updateOpt: '+updateOpt);
            if(!updateOpt.isEmpty()) {
                saveResult = Database.update(updateOpt, dml);
            }
            if (saveResult.size() > 0 && saveResult.get(0).getErrors().size() > 0) {
                system.debug('saveResult :: '+saveResult);
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, saveResult.get(0).getErrors().get(0).getMessage()));
                return null;
            }
            System.debug('@@saveResult: '+saveResult);
            //upsert updateList;
            
            //Insert Opportunity Line Item
            OpportunityLineItem optySplitProduct = OpportunitySplitHelper.createOptySplitLineItem(primaryOpportunity, (optyTotalValue + splitAmounts)-((optyTotalValue * primaryOpportunity.split_percentage__c) / 100));
            
            //System.debug('@@optyTotalValue: '+optyTotalValue+' -> '+splitAmounts+' -> '+primaryOpportunity.split_percentage__c+' -> '+optySplitProduct+'\n\n\n');
            primaryOpportunity.split__c = true;
            flowControll.opportunityTriggerHandler = false;
            update primaryOpportunity;
            upsert optySplitProduct;
        }
        
        emailAddresses.add(primaryOpportunity.OwnerId);
        EmailHelper.sendEmail(emailTemplateId, emailAddresses, primaryOpportunity.Id);
        
        System.debug('@@END SAVE ITEM:\n\n\n');
        
        return returnToOrigination();
    }
    
  //page Reference
    private pageReference returnToOrigination() {
        PageReference page = new PageReference('/' + OpportunityID);
        page.setRedirect(true);
        return page;
    }
    
}