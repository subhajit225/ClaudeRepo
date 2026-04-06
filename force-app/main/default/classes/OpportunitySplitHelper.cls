public class OpportunitySplitHelper {
    
    public static List<PriceBookEntry> pList = null;
    public static List<Product2> optySplitList = null;

    
    public static OpportunityLineItem createOptySplitLineItem(Opportunity primaryOpty, Decimal total) {
        return manageOptySplitLineItem(primaryOpty, total)[0];
    }

    //Adds the phatom product to product line items, creates Product and PricebookEntry if needed
    public static List<OpportunityLineItem> manageOptySplitLineItem(Opportunity primaryOpty, Decimal total) {
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        OpportunityLineItem optySplitProductLineItem = null;
        OpportunityLineItem staticProductItem = null;
        boolean hasProducts = false;
        List<OpportunityLineItem> oliToDelete = new List<OpportunityLineItem>();
        //check and see if the Primary Opportunity has the phatam split Product
        for(OpportunityLineItem vLineItem : primaryOpty.OpportunityLineItems) {
            system.debug(vLineItem.ProductCode + ' - ' + vLineItem.TotalPrice + '\n~~~~ OpportunitySplitHelper : '+vLineItem);
            if(vLineItem.ProductCode == 'OPTY-SPLIT' && vLineItem.TotalPrice <= 0) {
                optySplitProductLineItem=vLineItem;
            } else if (vLineItem.ProductCode == 'OPTY-SPLIT' && vLineItem.TotalPrice > 0) {
                staticProductItem=vLineItem;    
            } else {
                hasProducts = true;
            }
        }
        
        if(!hasProducts && staticProductItem == null && primaryOpty.Amount > 0){
            OpportunityLineItem oli = createAmountProduct(primaryOpty, primaryOpty.Amount);
            if(oli.TotalPrice != 0){
                oliList.add(oli);
            }
        }
        if(total != 0){
            PricebookEntry vPricebookEntry = getPriceBook(primaryOpty);
            if(optySplitProductLineItem == null){                                    
                optySplitProductLineItem = new OpportunityLineItem();
                optySplitProductLineItem.PricebookEntryId = vPricebookEntry.Id;
                optySplitProductLineItem.OpportunityId = primaryOpty.Id;
                optySplitProductLineItem.Quantity = 1;
                optySplitProductLineItem.TotalPrice = total* (-1);
                optySplitProductLineItem.isSplit__c = true;
                //return optySplitProductLineItem;
            } else {
                optySplitProductLineItem.TotalPrice = total* (-1);
                //return optySplitProductLineItem;
            }
            oliList.add(optySplitProductLineItem);
        }else if(optySplitProductLineItem!= null){
            oliToDelete.add(optySplitProductLineItem);
        }
        if(!oliToDelete.isEmpty()){
            delete oliToDelete;
        }
        return oliList;
    }
    
    //TODO: REMOVE THIS METHOD - NOT NEEDED - CREATED ANOTHER
    //Copy Opportunity copies all required fiedls
    public static Opportunity copyOpportunity(Opportunity temp, Opportunity OpportunityItem){
    //public static Opportunity cloneOpportunity(Opportunity temp, Opportunity OpportunityItem){
        
        temp.split__c=true;
        temp.Opportunity_Split_Parent__c = OpportunityItem.Id;
        temp.Name = OpportunityItem.Name + ' - Split';
        temp.StageName = OpportunityItem.StageName;
        temp.Probability = OpportunityItem.Probability;
        // temp.CDM_Owner__c = OpportunityItem.CDM_Owner__c; //Removing this field's dependency as it needs to be deleted : SAL24-476
        temp.AccountId = OpportunityItem.AccountId;
        // temp.Partner_Level_Of_Involvement__c  = OpportunityItem.Partner_Level_Of_Involvement__c;//SAL24-387
        temp.Valooto_Quote_Stage__c = OpportunityItem.Valooto_Quote_Stage__c;
        // temp.ForecastCategory = OpportunityItem.ForecastCategory;
        temp.CloseDate = OpportunityItem.CloseDate;
        temp.Win_Alert_Sent__c = OpportunityItem.Win_Alert_Sent__c;
        //temp.Opportunity_Sub_Type__c  = OpportunityItem.Opportunity_Sub_Type__c;
        temp.Alliance_Partner_Name__c = OpportunityItem.Alliance_Partner_Name__c;
        temp.Alliance_Source_Type__c    = OpportunityItem.Alliance_Source_Type__c;
        temp.LeadSource = OpportunityItem.LeadSource;
        //temp.OpportunitySource__c = OpportunityItem.OpportunitySource__c;
        temp.Incumbent__c = OpportunityItem.Incumbent__c;
        temp.Other_Incumbent__c = OpportunityItem.Other_Incumbent__c;
        temp.Primary_Competitor__c = OpportunityItem.Primary_Competitor__c;
        temp.Compelling_Bus_Driver__c = OpportunityItem.Compelling_Bus_Driver__c;
        temp.Key_Feature_Needs__c = OpportunityItem.Key_Feature_Needs__c;
        temp.Installation_Assigned_To__c = OpportunityItem.Installation_Assigned_To__c;
        
        
        if(temp.Partner_Lookup__c==null){
            temp.Partner_Lookup__c=OpportunityItem.Partner_Lookup__c;
        }
        //temp.Distributor_Lookup__c=OpportunityItem.Distributor_Lookup__c;
        
        //Deal Registration Information
        //Child Opts should alwasy be RID
        temp.Deal_Registration_Type__c='Rubrik Sourced';
        temp.Converted_From_Lead__c=false;//must be false so the PID/JID Logic will not be invoked
        temp.Deal_Registration__c=OpportunityItem.Deal_Registration__c;
        temp.Deal_Reg_Approval_Status__c=OpportunityItem.Deal_Reg_Approval_Status__c;
        temp.Deal_Reg_Submitted_Date__c=OpportunityItem.Deal_Reg_Submitted_Date__c;
        temp.Deal_Reg_Approval_Timestamp__c=OpportunityItem.Deal_Reg_Approval_Timestamp__c;
        temp.Deal_Reg_Expiration_Date__c=OpportunityItem.Deal_Reg_Expiration_Date__c;
        temp.Deal_Registration_Number__c=OpportunityItem.Deal_Registration_Number__c;
        temp.Partner_Representative__c=OpportunityItem.Partner_Representative__c;
        temp.Partner_Rep_Email_Address__c=OpportunityItem.Partner_Rep_Email_Address__c;
        temp.Partner_SE_Name__c=OpportunityItem.Partner_SE_Name__c;
        temp.Partner_SE_Email__c=OpportunityItem.Partner_SE_Email__c;
        temp.Partner_SE_Phone__c=OpportunityItem.Partner_SE_Phone__c;
        temp.Distributor_Rep_Name__c=OpportunityItem.Distributor_Rep_Name__c;
        temp.Distributor_Rep_Email__c=OpportunityItem.Distributor_Rep_Email__c;
        temp.Distributor_Rep_Phone_Number__c=OpportunityItem.Distributor_Rep_Phone_Number__c;
        temp.Deal_Registration_Link__c=OpportunityItem.Deal_Registration_Link__c;
        
        temp.Distributor_Lookup__c=OpportunityItem.Distributor_Lookup__c;
        temp.Current_State__c = OpportunityItem.Current_State__c;
        temp.Initial_Contacts_Name__c = OpportunityItem.Initial_Contacts_Name__c;       
        temp.Cloud_Type__c = OpportunityItem.Cloud_Type__c;
        temp.Alliance_HW_Partner__c = OpportunityItem.Alliance_HW_Partner__c;
        temp.Alliance_Source_Type_SW__c = OpportunityItem.Alliance_Source_Type_SW__c;
        // temp.Alliance_Source_Type_HW__c = OpportunityItem.Alliance_Source_Type_HW__c; //SAL24-387      
        if(temp.Rubrik_Sales_Engineer__c == null){
            //temp.Rubrik_Sales_Engineer__c = OpportunityItem.Rubrik_Sales_Engineer__c;
        }
        temp.Negative_Consequences__c = OpportunityItem.Negative_Consequences__c;
        temp.Future_State__c = OpportunityItem.Future_State__c;     
        temp.Other_Primary_Competitor__c = OpportunityItem.Other_Primary_Competitor__c;
        temp.Positive_Business_Outcomes__c = OpportunityItem.Positive_Business_Outcomes__c;
        temp.SBQQ__PrimaryQuote__c = OpportunityItem.SBQQ__PrimaryQuote__c;     
        temp.Deal_Impact__c = OpportunityItem.Deal_Impact__c;       
        temp.Other_Key_Feature_Need__c = OpportunityItem.Other_Key_Feature_Need__c;
        temp.Win_Loss_Comments__c = OpportunityItem.Win_Loss_Comments__c;       
        temp.Lost_To__c = OpportunityItem.Lost_To__c;
        temp.Lost_Reason__c = OpportunityItem.Lost_Reason__c;
        temp.Metric__c = OpportunityItem.Metric__c;     
        temp.Economic_Buyer__c = OpportunityItem.Economic_Buyer__c;     
        temp.Decision_Criteria__c = OpportunityItem.Decision_Criteria__c;
        temp.Decision_Process__c = OpportunityItem.Decision_Process__c;
        temp.Identified_Pain__c = OpportunityItem.Identified_Pain__c;
        temp.Champion__c = OpportunityItem.Champion__c;
        
        return temp;
    }

    public static Opportunity copyOpportunityFieldToSplit(Opportunity temp, Opportunity opptyItem, List<OpportunitySplitMapping__c> oppSplitMapping){
        system.debug('Inside OpportunitySplitHelper - copyOpportunityFieldToSplit : oppSplitMapping : '+oppSplitMapping);
        Map<String, Schema.SObjectField> m = Schema.SObjectType.Opportunity.fields.getMap();

        for(OpportunitySplitMapping__c oppSplt : oppSplitMapping) {
            
            Schema.SObjectField fld = m.get(oppSplt.Field__c);
            Schema.DisplayType fldType = fld.getDescribe().getType();
            
            //system.debug('Inside OpportunitySplitHelper - copyOpportunityFieldToSplit : Field__c : '+oppSplt.Field__c +' -- '+ opptyItem.get(oppSplt.Field__c));
            if(String.isNotBlank(oppSplt.Default_Value__c)) {
                if(fldType.name() == 'Boolean') {
                    temp.put(oppSplt.Field__c, Boolean.valueOf(oppSplt.Default_Value__c));
                } else if(fldType.name() == 'Integer') {
                    temp.put(oppSplt.Field__c, Integer.valueOf(oppSplt.Default_Value__c));
                } else if(fldType.name() == 'Double') {
                    temp.put(oppSplt.Field__c, Decimal.valueOf(oppSplt.Default_Value__c));
                } else {
                    temp.put(oppSplt.Field__c, oppSplt.Default_Value__c);
                }
            } else if(String.isNotBlank(oppSplt.Suffix__c)) {
                temp.put(oppSplt.Field__c, opptyItem.get(oppSplt.Field__c) + ' ' + oppSplt.Suffix__c);
            } else if(String.isNotBlank(oppSplt.From_Field__c)) {
                temp.put(oppSplt.Field__c, opptyItem.get(oppSplt.From_Field__c));
            } else {
                if(!oppSplt.Skip_Update_if_child_has_value__c){
                    temp.put(oppSplt.Field__c, opptyItem.get(oppSplt.Field__c));
                }else if(temp.get(oppSplt.Field__c) == null){
                    temp.put(oppSplt.Field__c, opptyItem.get(oppSplt.Field__c));
                }
            }
        }
        
        return temp;
    }
    
    //Create the Amount Product, if no products are in the product Item list
    public static OpportunityLineItem createAmountProduct(Opportunity primaryOpty, Decimal total) {
        
        PricebookEntry vPricebookEntry = getPriceBook(primaryOpty);
        OpportunityLineItem staticAmountProductItem = null;
        for(OpportunityLineItem vLineItem: primaryOpty.OpportunityLineItems) {
            if(vLineItem.ProductCode == 'OPTY-SPLIT' && vLineItem.TotalPrice>0) {
                staticAmountProductItem = vLineItem;
            } 
        }
        system.debug('\n\n\n staticAmountProductItem '+staticAmountProductItem+'\n\n');
        if(staticAmountProductItem == null) {
            staticAmountProductItem= new OpportunityLineItem();
            staticAmountProductItem.PricebookEntryId  = vPricebookEntry.Id;
            staticAmountProductItem.OpportunityId = primaryOpty.Id;
            staticAmountProductItem.Quantity = 1;
            staticAmountProductItem.TotalPrice =  total;
            staticAmountProductItem.isSplit__c = true;
            //insert staticAmountProductItem;
        } else {
            staticAmountProductItem.TotalPrice = total;
            //update staticAmountProductItem;
        }
        return staticAmountProductItem;
    }
    
    //get the pricebook of the OptySplit Product, and create necessary phatom products
    public static PricebookEntry getPriceBook(Opportunity primaryOpty) {
        
        Product2 optySplitProduct;
        PricebookEntry vPricebookEntry;
        Pricebook2 priceBook;
        Id priceBook2Id;
        
        //Find the "Opportunity Split" PRODUCT, or create a new one if it doesn't exits
        if(optySplitList == null){
            optySplitList = [SELECT Id, Name FROM Product2 WHERE Name = 'Opportunity Split' LIMIT 1];
        }
        if(optySplitList.size() == 0){
            //Insert the phatom product
            optySplitProduct = new Product2(Name = 'Opportunity Split');
            optySplitProduct.ProductCode = 'OPTY-SPLIT';
            insert optySplitProduct;
        } else {
            optySplitProduct = optySplitList[0];            
        }
        
        system.debug('primaryOpty : '+primaryOpty+'\n');
        //Get the PriceBookEntry or create a new one
        if(primaryOpty.Pricebook2Id == null){
            if(!Test.isRunningTest()){
                priceBook = [SELECT Id, Name, IsActive FROM Pricebook2 WHERE IsActive = TRUE AND Name = 'CPQ PriceBook' LIMIT 1];
            }else{
                priceBook = [SELECT Id, Name, IsActive FROM Pricebook2 WHERE IsActive = TRUE LIMIT 1];
            }
            priceBook2Id = priceBook.Id;
        } else {
            priceBook2Id = primaryOpty.Pricebook2Id;
        }
        if(pList == null) {
            pList = [SELECT Id, Product2Id, Pricebook2Id FROM Pricebookentry WHERE PriceBook2Id = :priceBook2Id AND ProductCode = 'OPTY-SPLIT' LIMIT 1];
        }
        if(pList.size() == 0) {
            vPricebookEntry = new PricebookEntry();
            vPricebookEntry.product2id = optySplitProduct.id;
            vPricebookEntry.isActive = true;
            vPricebookEntry.unitprice = 100;
            vPricebookEntry.pricebook2Id  = priceBook2Id;  
            insert vPricebookEntry;     
            pList.add(vPricebookEntry);         
        } else {
            vPricebookEntry=pList[0];
        }
        
        system.debug('\n\n\n vPricebookEntry '+vPricebookEntry+'\n\n');
        return vPricebookEntry;
    }
    
}