/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 01-30-2026
 * @last modified by  : Harshit Garg
**/
public without sharing class PC_PortalNavigationApexController {
    public static String EngagementRecordTypeId = Schema.SObjectType.Deal_Registration__c.getRecordTypeInfosByName().get('Engagement').getRecordTypeId();
    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getMenuConfigs(String userId){
        List<Partner_Page_Configuration__c> menuConfigListAll = new List<Partner_Page_Configuration__c>();
        List<String> allAudienceList = new List<String>();
        try {
            allAudienceList = PC_PortalNavigationApexController.getAudiencesRecord(userId);

            menuConfigListAll = [SELECT ID,Name,Menu_Label__c,Menu_Group__c,Order__c,Image_Type__c,Navigate_Url__c,Partner_Type__c,Primary_Role__c,Audience_Name__c,Link_Type__c,Has_Sub_Menu__c
                                FROM Partner_Page_Configuration__c
                                WHERE Image_Type__c IN ('Menu','Menu Item') AND Active__c = true ORDER BY Order__c];

            if(!menuConfigListAll.isEmpty()){
                for(Integer i = (menuConfigListAll.size()-1) ; i>= 0 ; i--){
                    if(menuConfigListAll[i].Audience_Name__c !=null && !allAudienceList.contains(menuConfigListAll[i].Audience_Name__c)){
                        menuConfigListAll.remove(i);
                    }
                }
            }
            System.debug(LoggingLevel.DEBUG, 'menuConfigListAll'+menuConfigListAll);
            return menuConfigListAll;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description : Get the audience record
     * @return : List of string
     * @param : userId
     */
    public static List<String> getAudiencesRecord(String userId){
        try {
            ConnectApi.AudienceCollection audCollection;

            if(userId != null) {
                List<String> communityIds = new List<String>();

                List<NetworkMember> communityMembers = [SELECT Id, MemberId, NetworkId
                                                        FROM NetworkMember
                                                        WHERE MemberId =: userId
                                                        AND Network.Name = 'Rubrik Partner Community' LIMIT 1];

                for (NetworkMember each : communityMembers) {
                    communityIds.add(each.NetworkId);
                }

                if (!communityIds.isEmpty()) {
                    userId = userId.substring(0, userId.length()-3);

                    String ipAddress;
                    String domain;
                    List<String> targetTypes;
                    String communityID = communityIds[0];

                    if(!Test.isRunningTest()){
                    audCollection = (ConnectApi.Personalization.getAudiences(communityID, ipAddress, domain, userId, ConnectApi.PublishStatus.Live, false, targetTypes));
                    }else{
                        Audience ad = [SELECT Id,DeveloperName FROM Audience LIMIT 1];
                        ConnectApi.AudienceCollection mockAudiences = new ConnectApi.AudienceCollection();
                        List<ConnectApi.Audience> adList = new List<ConnectApi.Audience>();  
                        ConnectApi.Audience aud = new ConnectApi.Audience();
						aud.name = ad.DeveloperName;
                        aud.Id = ad.Id;
                        adList.add(aud);
                        mockAudiences.audiences = adList;
                        audCollection = mockAudiences;
                    }
                }
            }

            List<String> audienceNameList = new List<String>();

            Map<String,Object> parsedJson = (Map<String,Object>)JSON.deserializeUntyped(JSON.serializePretty(audCollection));

            List<Object> allAudienceRec = new List<Object>();
            allAudienceRec = (List<Object>)JSON.deserializeUntyped(JSON.serializePretty(parsedJson.get('audiences')));

            for(Object ele : allAudienceRec){
                Map<String,Object> eleMap = (Map<String,Object>)JSON.deserializeUntyped(JSON.serializePretty(ele));
                audienceNameList.add((String)eleMap.get('name'));
            }
            return audienceNameList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+' '+e.getLineNumber());
        }
    }
	
    /**
     * @description : method to get picklist values of any object and any number 
     * @return map of fields and picklist values in the field
     * @lwc - pc_managedServiceRequestForm_lwc
     */
    @AuraEnabled
    public static Map<String,List<String>> getPicklistValues(String objName, List<String> fieldAPINamesList)
    {
        Map<String, List<String>> fieldWithPicklistValues = new Map<String, List<String>>();
        
        try{
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objName);
            Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
            for(String fieldName : fieldAPINamesList){
                String picklistFieldAPI = fieldName.toLowerCase();
                Schema.SObjectField picklistField = objFieldMap.get(picklistFieldAPI);
                List<Schema.PicklistEntry> fieldValues = picklistField.getDescribe().getPicklistValues();
                List<String> picklistValues = new List<String>();
                
                for (Schema.PicklistEntry pEntry : fieldValues) 
                {                  
                    picklistValues.add(pEntry.getLabel()+';'+pEntry.getValue());
                }
                fieldWithPicklistValues.put(fieldName, picklistValues);
            }
        }
        catch(Exception e){
            system.debug(LoggingLevel.WARN,'Exception occured-->'+e.getMessage()); 
        }
        return fieldWithPicklistValues;
    }

    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getPartnerPageConfigurations(String title){
        Boolean homeAdded = false;
        Partner_Page_Configuration__c lastRec;
        List<Partner_Page_Configuration__c> finalList = new List<Partner_Page_Configuration__c>();
        Map<String, Partner_Page_Configuration__c> pConfigMap = new Map<String, Partner_Page_Configuration__c>();

        for( Partner_Page_Configuration__c  pc : [SELECT Id, Navigate_Url__c, Menu_Label__c , Menu_Group__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Menu_Label__c != null
                                                    AND Image_Type__c IN ('Menu','Menu Item')]){
            pConfigMap.put(pc.Menu_Label__c, pc);
            if((pc.Menu_Label__c == 'Home' || title == 'Home') && !homeAdded){
                finalList.add(pc);
                homeAdded = true;
            }
            if(title != 'Home' && pc.Menu_Label__c == title && pc.Menu_Group__c == null){
                //add second page when its group is Home
                finalList.add(pc);
            }else if(title != 'Home' && pc.Menu_Label__c == title && pc.Menu_Group__c != null){
                lastRec = pc;
            }
        }
        if(lastRec != null){
            for(Partner_Page_Configuration__c  pc : pConfigMap.values())
            {
                if(pc.Menu_Label__c == lastRec.Menu_Group__c){
                    //add middle rec in the list
                    finalList.add(pc);
                    //add final rec in the list
                    finalList.add(lastRec);
                }
            }
        }
        return finalList;
    }

    @AuraEnabled
    public static homePageWrapper getWelcomePageDetails(){
        homePageWrapper  homeWrapper = new homePageWrapper();
        User u = [SELECT Id, Contact.Primary_Role__c FROM User WHERE Id =: UserInfo.getUserId()];
        Partner_Page_Configuration__c ppConfigRecord = new Partner_Page_Configuration__c();
        
        if(!String.isEmpty(u.Contact.Primary_Role__c) || u.Contact.Primary_Role__c != null)
        {
            if(u.Contact.Primary_Role__c =='Sales' || u.Contact.Primary_Role__c == 'Marketing' 
               || u.Contact.Primary_Role__c == 'Technical' || u.Contact.Primary_Role__c == 'Executive')
            {
                ppConfigRecord = [SELECT Id, Image_Type__c, Description__c, Image_Url__c, Headline__c FROM Partner_Page_Configuration__c
                                  WHERE Image_Type__c ='Welcome Page' AND Primary_Role__c =: u.Contact.Primary_Role__c AND Active__c = true
                                  LIMIT 1];
            }else{
                ppConfigRecord = [SELECT Id, Image_Type__c, Description__c, Image_Url__c, Headline__c FROM Partner_Page_Configuration__c
                                  WHERE Image_Type__c ='Welcome Page' AND Primary_Role__c = 'Admin' AND Active__c = true
                                  LIMIT 1];
            }
            
        }
        
        homeWrapper.pageRecord = ppConfigRecord;
        homeWrapper.userName = userinfo.getFirstName();
        return homeWrapper;
    }

    /**
     * @description       : Wrapper class to send welcome page details to LWC
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class HomePageWrapper{
        @AuraEnabled
        public Partner_Page_Configuration__c pageRecord;
        @AuraEnabled
        public String userName;
    }

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_popUpResources_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled
    public static List<Partner_Page_Configuration__c > getPartnerModalDetails(){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List< Partner_Page_Configuration__c > partnerModalConfigList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c, Channel_Program__c , Image_Height__c, Image_Text__c, Image_Type__c, Navigate_Text__c ,Image_Url__c, Link_Type__c, Mobile_Image_Url__c, Navigate_Url__c, Card_Title__c , Description__c ,Page_Name__c, Partner_Type__c, Static_Resource_Name__c , Tag__c , Headline__c, Audience_Name__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Active__c = true AND Image_Type__c IN ('Pop Up Card','Welcome Wizard Resources')]){
            if(config.Audience_Name__c == null || audienceList.contains(config.Audience_Name__c))
                partnerModalConfigList.add(config);
        }
        partnerModalConfigList = transformImageUrl(partnerModalConfigList);
        return partnerModalConfigList;
    }

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_homePageCards_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled
    public static List<Partner_Page_Configuration__c > gethomePageCardDetails(String pageName){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List< Partner_Page_Configuration__c > partnerModalConfigList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c, Channel_Program__c, Image_Height__c, Image_Text__c, Image_Type__c, Navigate_Text__c ,Image_Url__c, Link_Type__c, Mobile_Image_Url__c, Navigate_Url__c, Card_Title__c , Description__c ,Page_Name__c, Partner_Type__c, Static_Resource_Name__c , Tag__c , Headline__c, Audience_Name__c
                                                    FROM Partner_Page_Configuration__c WHERE Active__c = true 
                                                    AND Image_Type__c IN ('Pop Up Card') AND Page_Name__c=: pageName ORDER BY Order__c])
        {
            if(config.Audience_Name__c == null || audienceList.contains(config.Audience_Name__c))
                partnerModalConfigList.add(config);
        }
        //call the file method to get the ContentDocumentId
        partnerModalConfigList = transformImageUrl(partnerModalConfigList);
        return partnerModalConfigList;
    } 

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_personaQuestions_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getPersonaQuestionsDetails(){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List< Partner_Page_Configuration__c > configList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c,Image_Url__c, Name, Audience_Name__c, Description__c, Primary_role__c
                                                     FROM Partner_Page_Configuration__c WHERE Name='Persona Questions' AND Image_Type__c ='Welcome Page' AND Active__c = true
                                                     ORDER BY Order__c]){
            if(config.Audience_Name__c == null || audienceList.contains(config.Audience_Name__c))
                configList.add(config);
        }
        configList = transformImageUrl(configList);
        return configList;
    }

    @AuraEnabled
    public static String updateContactRecord(Contact conRec){
        if(conRec != null){
            update conRec;
        }
        return 'success';
    }

    @AuraEnabled(cacheable=true)
    public static User getContactWelcomeWizardConfig(String partnerUserId){
        User currentUser = [SELECT ID,Name, Contact.Primary_Role__c,Contact.Persona_Captured__c,Contact.Partner_Terms_of_Use__c,Contact.Partner_Promo_Banner__c,Contact.Partner_Welcome_Video__c,Contact.Email,Contact.Partner_Rubrik_Amplify_Terms__c
                            FROM User
                            WHERE ID =: partnerUserId];
            return currentUser;
    }

    @AuraEnabled(cacheable=true)
    public static List<Partner_Page_Configuration__c> getWelcomeWizardVideoConfig(){
        List< Partner_Page_Configuration__c > welcomeWizardVideoConfigList = new List<Partner_Page_Configuration__c>();

        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c, Headline__c, Link_Type__c, Navigate_Url__c,Description__c,Image_Url__c,Navigate_Text__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Active__c = TRUE AND Image_Type__c ='Welcome Wizard Video' LIMIT 1]){
            welcomeWizardVideoConfigList.add(config);
        }
        return welcomeWizardVideoConfigList;
    }

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_eventPromotionalPopUp_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled(cacheable=true)
    public static List<Partner_Page_Configuration__c> getEventPromotionalConfig(){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List<Partner_Page_Configuration__c> welcomeWizardPromoConfigList = new List<Partner_Page_Configuration__c>();

        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c, Name, Static_Resource_Name__c, Link_Type__c, Headline__c, Navigate_Url__c, Description__c,Navigate_Text__c, Image_Text__c, Audience_Name__c, Image_Url__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Active__c = TRUE AND Image_Type__c ='Welcome Wizard Promo' LIMIT 1])
        {
            if(config.Audience_Name__c == null || audienceList.contains(config.Audience_Name__c))
            welcomeWizardPromoConfigList.add(config);
        }
        welcomeWizardPromoConfigList = transformImageUrl(welcomeWizardPromoConfigList);
        return welcomeWizardPromoConfigList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Partner_Page_Configuration__c> getAccordionDetails(String pageName){
        List< Partner_Page_Configuration__c > partnerAccordionList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c, Description__c, Headline__c, Link_Type__c, Card_Title__c, Page_Name__c, Image_Text__c FROM Partner_Page_Configuration__c
                                                    WHERE Active__c = true AND Image_Type__c ='Accordion' AND Page_Name__c =: pageName ORDER BY Order__c]){
            partnerAccordionList.add(config);
        }
        return partnerAccordionList;
    }

    @AuraEnabled(cacheable=true)
    public static List<CertificateWrapper> getAccreditedDetails(){
        CertificateWrapper certWrap;
        List<CertificateWrapper> certWrapList = new List<CertificateWrapper>();
        String completedCssClass = 'slds-align_absolute-center circleDiv courseComplete';
        String notcompletedCssClass = 'slds-align_absolute-center circleDiv';
        String userType = UserInfo.getUserType();
        if(userType.equalsIgnoreCase('PowerPartner')){
            String fields = '';
            List<Partner_Page_Configuration__c> certificateFields = [SELECT Id, Name, Navigate_Url__c, Image_Type__c, Order__c, Menu_Label__c, Menu_Group__c, Navigate_Text__c, Tag__c, Primary_role__c,
                                                                    Link_Type__c FROM Partner_Page_Configuration__c
                                                                    WHERE Active__c = true AND Image_Type__c = 'Certifications' ORDER BY Order__c];

            for(Partner_Page_Configuration__c rec : certificateFields){
                fields = fields + ', Contact.' + rec.Tag__c + ', Contact.' + rec.Navigate_Text__c;
            }
            String query = 'SELECT Id, ContactId, Contact.Primary_Role__c '+ fields + ' FROM User WHERE Id = \'' + UserInfo.getUserId() + '\' LIMIT 1';
            system.debug(LoggingLevel.DEBUG, query);
            User sobjUser = Database.query(query);
            system.debug(LoggingLevel.DEBUG, sobjUser.getPopulatedFieldsAsMap());
            system.debug(LoggingLevel.DEBUG, sobjUser.getPopulatedFieldsAsMap().get('Contact'));
            Map<String,Object> conFields = ((sobject)sobjUser.getPopulatedFieldsAsMap().get('Contact')).getPopulatedFieldsAsMap();

			for(Partner_Page_Configuration__c config : certificateFields){
				if(config.Primary_role__c?.split(';')?.contains((String)conFields.get('Primary_Role__c'))){
					certWrap = new CertificateWrapper();
					certWrap.certificateLabel = config.Menu_Label__c;
					certWrap.certificateCategory = config.Menu_Group__c;
					certWrap.certificateLink = config.Navigate_Url__c;
                    certWrap.target = config.Link_Type__c == 'External URL' ? '_blank':'_self';
					certWrap.cssClass = conFields.get(config.Tag__c) != null && (Date)conFields.get(config.Navigate_Text__c) > System.today() ? completedCssClass : notcompletedCssClass;
					certWrap.iconName = certWrap.cssClass == completedCssClass ? 'utility:check' : 'utility:dash';
                    certWrapList.add(certWrap);
				}
			}
        }
        return certWrapList;
    }

    /**
     * @description       : Wrapper class to send certifice details to LWC
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class CertificateWrapper{
        @AuraEnabled
        public String certificateLabel;
        @AuraEnabled
        public String certificateCategory;
        @AuraEnabled
        public String certificateLink;
        @AuraEnabled
        public String target;
        @AuraEnabled
        public String cssClass;
        @AuraEnabled
        public String iconName;
    }

    @AuraEnabled(cacheable=true)
    public static List<Partner_Page_Configuration__c> getGlobalResourceConfigs(String portalPageName){
        List< Partner_Page_Configuration__c > resourceConfigList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c config : [SELECT Id, Active__c,Navigate_Url__c, Navigate_Text__c, Card_Title__c, Description__c, Headline__c, Image_Url__c, Order__c, Page_Name__c, Static_Resource_Name__c, Image_Type__c,Tag__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Active__c = true AND Image_Type__c IN ('Global Resource Card','Featured Item Card') AND Page_Name__c =:portalPageName  ORDER BY Order__c]){
            resourceConfigList.add(config);
        }
        system.debug(LoggingLevel.DEBUG, '-->'+resourceConfigList);
        return resourceConfigList;
    }

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_imageTextCard_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled(cacheable=true)
    public static Partner_Page_Configuration__c getImageTextCard(String portalPageName){
        List< Partner_Page_Configuration__c > configList = new List<Partner_Page_Configuration__c>();
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        for(Partner_Page_Configuration__c record : [SELECT Id, Image_Url__c, Description__c, Headline__c, Audience_Name__c
                FROM Partner_Page_Configuration__c
                WHERE Active__c = True AND Image_Type__c = 'Image Card' AND Page_Name__c =:portalPageName])
        {
            if(record.Audience_Name__c == null || audienceList.contains(record.Audience_Name__c))
                    configList.add(record);
        }
        configList = transformImageUrl(configList);
        return configList[0];
    }

    @AuraEnabled(cacheable=true)
    public static List<Partner_Page_Configuration__c> getLinkNameAndUrl(String portalPageName){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List< Partner_Page_Configuration__c > linkList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c config : [SELECT Id, Navigate_Text__c, Navigate_Url__c,Order__c,Link_Type__c, Audience_Name__c
                FROM Partner_Page_Configuration__c
                WHERE Active__c = True AND Image_Type__c = 'HelpLink' AND Page_Name__c =:portalPageName ORDER BY Order__c])
        {
            if(config.Audience_Name__c == null || audienceList.contains(config.Audience_Name__c))
                linkList.add(config);
        }
        return linkList;
    }

    @AuraEnabled(cacheable=true)
    public static List<Partner_Page_Configuration__c> getRelatedResourcesUrl(String portalPageName)
    {
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List<Partner_Page_Configuration__c> pList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c pRecord : [SELECT Id, Menu_Label__c, Navigate_Url__c, Card_Title__c, Description__c, Link_Type__c, Audience_Name__c
                                                     FROM Partner_Page_Configuration__c
                                                     WHERE Active__c = True AND Image_Type__c = 'Related Resource' AND Page_Name__c =:portalPageName ORDER BY Order__c])
        {
            if(pRecord.Audience_Name__c == null || audienceList.contains(pRecord.Audience_Name__c))
                pList.add(pRecord);
        }
        return pList;
    }

    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getPageDescription(String pageName){
        List<Partner_Page_Configuration__c> pList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c pRecord : [SELECT Id, Active__c, Navigate_Url__c, Card_Title__c, Link_Type__c, Description__c, Headline__c, Page_Name__c, Navigate_Text__c, Image_Type__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Image_Type__c = 'Page Description' AND Page_Name__c =:pageName AND Active__c =true]){
            pList.add(pRecord);
        }
        return pList;
    }

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_twoColumnImage_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getTwoColumnDetails(String pageName){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List<Partner_Page_Configuration__c> pList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c pRecord : [SELECT Id, Active__c, Navigate_Url__c, Card_Title__c, Image_Text__c, Headline__c, Page_Name__c, Navigate_Text__c, Image_Type__c, Image_Url__c, Image_Alignment__c, Link_Type__c, Audience_Name__c
                                                    FROM Partner_Page_Configuration__c
                                                    WHERE Image_Type__c = 'Two Column Card' AND Page_Name__c =:pageName AND Active__c =true]){
            if(pRecord.Audience_Name__c == null || audienceList.contains(pRecord.Audience_Name__c))
                pList.add(pRecord);
        }
        pList = transformImageUrl(pList);
        return pList;
    }

    /**
     * @description       : Method to fetch details from Partner Page Configuration
     * @author            : Partner IT team
     * @lwc               : pc_categoryCard_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled
    public static List<Partner_Page_Configuration__c> getCategoryCardConfigs(String pageName){
        List<String> audienceList = new List<String>();
        if(!Test.isRunningTest()){
            audienceList = getAudiencesRecord(UserInfo.getUserId());
        }
        List<Partner_Page_Configuration__c> pList = new List<Partner_Page_Configuration__c>();
        Map<String, Partner_Page_Configuration__c> pMap = new Map<String, Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c pRecord : [SELECT Id, Active__c, Navigate_Url__c, Card_Title__c, Description__c, Headline__c, Page_Name__c, Navigate_Text__c, Image_Type__c, Image_Url__c, Link_Type__c, Audience_Name__c
                                                    FROM Partner_Page_Configuration__c WHERE Image_Type__c = 'Card' 
                                                     AND Page_Name__c =:pageName AND Active__c =true ORDER BY Order__c])
        {
            if(pRecord.Audience_Name__c == null || audienceList.contains(pRecord.Audience_Name__c)){
                if(pageName == 'Incentives'){
                    pMap.put(pRecord.Navigate_Url__c.split('id=')[1], pRecord);
                }else{	
                    pList.add(pRecord);
                }
            }
        }
        if (pageName == 'Incentives'){
            for(Incentives__c rec : [Select Id, End__c, Active__c from Incentives__c WHERE Id IN: pMap.keySet()])
            {
                if((rec.End__c < Date.today() || rec.End__c == null)  && pMap.containsKey(String.valueOf(rec.Id))){
                    pMap.remove(String.valueOf(rec.Id));
                }
        	}
            pList = pMap.values();
            system.debug(LoggingLevel.DEBUG, 'pList.Size()->'+pList.size());
        }
        pList = transformImageUrl(pList); //update file ids for images
        return pList;
    }
    
    /**
     * @description       : Method to fetch details from Partner Page Configuration for footer
     * @author            : Partner IT team
     * @lwc               : pc_footer_lwc
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    @AuraEnabled
    public static footerWrapper getFooterDetails(){
        footerWrapper footWrap = new footerWrapper();
        Partner_Page_Configuration__c footerLogo = new Partner_Page_Configuration__c();
        List<Partner_Page_Configuration__c> configList = new List<Partner_Page_Configuration__c>();
        List<Partner_Page_Configuration__c> iconList = new List<Partner_Page_Configuration__c>();
        for(Partner_Page_Configuration__c pRecord : [SELECT Id, Navigate_Url__c, Navigate_Text__c, Link_Type__c , Image_Url__c, Image_Type__c FROM Partner_Page_Configuration__c
                                                     WHERE Image_Type__c ='Footer' AND Active__c =true ORDER BY Order__c ASC])
        {
            if(pRecord.Image_Url__c != null)
            {
                if(pRecord.Navigate_Url__c != null){
                    iconList.add(pRecord);
                }
                else{
                    footerLogo = pRecord;
                }
                
            }else{
                configList.add(pRecord);
            }
            
        }
        iconList.add(footerLogo);
        iconList = transformImageUrl(iconList);
        
        footWrap.footerLogo = iconList[iconList.size() - 1];
        iconList.remove(iconList.size() - 1);
        footWrap.iconList = iconList;
        footWrap.configList = configList;
        
        return footWrap;
    }
    
    /**
     * @description       : Wrapper class for Footer details to be displayed
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class FooterWrapper
    {
        @AuraEnabled
        public Partner_Page_Configuration__c footerLogo;
        @AuraEnabled
        public List<Partner_Page_Configuration__c> configList;
        @AuraEnabled
        public List<Partner_Page_Configuration__c> iconList;
    }
    
    @AuraEnabled
    public static mdfWrapper getPartnerFundRequestsData(){
        List<PartnerFundRequest> mdfList = new List<PartnerFundRequest>();
        Integer mdfRequestsMade = 0;
        Integer mdfClaimsOutstanding = 0;
        mdfWrapper mWrap = new mdfWrapper();
        try{
            User partnerUser = [SELECT Id, Name, Contact.AccountId, Contact.Primary_Role__c
                                FROM User
                                WHERE Id=:UserInfo.getUserId()];
            
            Id partnerAccountId = partnerUser != null ? partnerUser.Contact.AccountId : null;
            
            if(partnerAccountId != null )
            {
                Id userId = UserInfo.getUserId();
                Date today = System.today();
                String query = 'SELECT Id, Title , Status, Activity_Start_Date__c, Activity_End_Date__c, PO_Number__c,(Select Id from PartnerFundClaims) FROM PartnerFundRequest WHERE Activity_End_Date__c >=: today AND ChannelPartnerId =:partnerAccountId';
                if(partnerUser.Contact.Primary_Role__c == 'Marketing'){
                    query = query +' AND CreatedById =: userId';
                }
                query = query + ' ORDER BY Activity_End_Date__c DESC';
                for(PartnerFundRequest mdf : Database.query(query)){
                    if(mdf.Status == 'Approved' && mdf.PartnerFundClaims.size() == 0){
                        mdfClaimsOutstanding = mdfClaimsOutstanding + 1;
                    }
                    if(mdf.Status == 'Approved' || mdf.Status == 'Submitted'){
                        mdfRequestsMade = mdfRequestsMade + 1;
                    }
                    mdfList.add(mdf);
                }
            }
            mWrap.mdfRequestsMade = mdfList.size();
            mWrap.mdfClaimsOutstanding = mdfClaimsOutstanding;
            mWrap.mdfList = mdfList;
            return mWrap;
        }catch(Exception e)
        {
            system.debug(LoggingLevel.DEBUG, 'error'+ e.getMessage());
            return mWrap;
        }
    }
    
    /**
     * @description       : Wrapper class to MDF data
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class MdfWrapper{
        @AuraEnabled
        public Integer mdfRequestsMade;
        @AuraEnabled
        public Integer mdfClaimsOutstanding;
        @AuraEnabled
        public List<PartnerFundRequest> mdfList;
    }

    //PRIT24-289 - Fetch Accelerator Claim Data for the report
    @AuraEnabled
    public static TransAccClaimWrapper getTransformAccfClaimData(){
        List<Incentives__c> claimList = new List<Incentives__c>();
        Integer submitted = 0;
        Integer approved = 0;
        Integer rejected = 0;
        TransAccClaimWrapper taWrap = new TransAccClaimWrapper();
        try{
            User partnerUser = [SELECT Id, Name, Contact.AccountId, Contact.Primary_Role__c
                                FROM User
                                WHERE Id=:UserInfo.getUserId()];
            
            Id partnerAccountId = partnerUser != null ? partnerUser.Contact.AccountId : null;
            
            if(partnerAccountId != null )
            {
                Id userId = UserInfo.getUserId();
                Date today = System.today();
                String query = 'SELECT Id, Type__c , Status__c, Start__c FROM Incentives__c WHERE RecordType.Developername = \'Transform_Accelerator_Claim\' AND Account_Name__c = : partnerAccountId';
                query = query + ' ORDER BY CreatedDate DESC';
                for(Incentives__c i : Database.query(query)){
                    if(i.Status__c == 'Approved'){
                        approved = approved + 1;
                    }else if(i.Status__c == 'Submitted'){
                        submitted = submitted + 1;
                    }else if(i.Status__c == 'Rejected'){
                        rejected = rejected + 1;
                    }
                    claimList.add(i);
                }
            }
            taWrap.approved = approved;
            taWrap.submitted = submitted;
            taWrap.rejected = rejected;
            taWrap.claimList = claimList;
            return taWrap;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description       : Wrapper class for Transform Accelerator Claim form
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class TransAccClaimWrapper{
        @AuraEnabled
        public Integer approved;
        @AuraEnabled
        public Integer submitted;
        @AuraEnabled
        public Integer rejected;
        @AuraEnabled
        public List<Incentives__c> claimList;
    }
    
    @AuraEnabled
    public static String preferredDistributorSelection(Contact conObj, String distributorName){
        System.debug(LoggingLevel.DEBUG, 'conObj->'+conObj);
        System.debug(LoggingLevel.DEBUG, 'distributorName->'+distributorName);
        try{
            EmailTemplate prefDistiEmail = [SELECT Id, BrandTemplateId, Name, Subject,Body ,HtmlValue
                                        	FROM EmailTemplate 
                                        	WHERE DeveloperName = 'Partner_Preferred_Distributor_Selection' limit 1];
            
            String emailIds = System.Label.PDS_Emails;
            
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            
            OrgWideEmailAddress orgAdd = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'goforward@rubrik.com' LIMIT 1];
            List<String> emailIdsList = emailIds.split(','); 
            mail.setToAddresses(emailIdsList);
            
            
            if(prefDistiEmail.Body.contains('{!Link}')){
                prefDistiEmail.Body = prefDistiEmail.Body.replace('{!Link}', System.Label.PDS_Link);
            }
            if(prefDistiEmail.Body.contains('{!Name}')){
                prefDistiEmail.Body = prefDistiEmail.Body.replace('{!Name}', conObj.FirstName +' '+conObj.LastName);
            }
            if(prefDistiEmail.Body.contains('{!Company}')){
                prefDistiEmail.Body = prefDistiEmail.Body.replace('{!Company}', conObj.mkto71_Inferred_Company__c);
            }
            if(prefDistiEmail.Body.contains('{!JobTitle}')){
                prefDistiEmail.Body = prefDistiEmail.Body.replace('{!JobTitle}', conObj.Title);
            }
            if(prefDistiEmail.Body.contains('{!Email}')){
                prefDistiEmail.Body = prefDistiEmail.Body.replace('{!Email}', conObj.Email);
            }
            if(prefDistiEmail.Body.contains('{!Distributor}')){
                prefDistiEmail.Body = prefDistiEmail.Body.replace('{!Distributor}', distributorName);
            }
            mail.setHtmlBody(prefDistiEmail.Body);
            mail.setTemplateId(prefDistiEmail.Id);
            mail.setSubject('New Distributor Selection For '+conObj.mkto71_Inferred_Company__c);
            mail.setOrgWideEmailAddressId(orgAdd.Id);
            emails.add(mail);
            
            if(!emails.isEmpty()){ 
                System.debug(LoggingLevel.DEBUG, emails);
                Messaging.sendEmail(emails);
                system.debug(LoggingLevel.DEBUG, 'Email Sent');
            }
            
            return 'success'; 
            
        }catch(Exception e){
            return String.valueOf(e.getLineNumber());
        }
    }

    @AuraEnabled
    public static String saveIncentiveData(list<String> filesToInsert, String url, String type){
        try{
            String recordId;
            Id recordTypeId = Schema.SObjectType.Incentives__c.getRecordTypeInfosByName().get('Transform Accelerator Claim').getRecordTypeId();
            List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
            Id accId = [SELECT Id, Contact.AccountId FROM User WHERE Id =: UserInfo.getUserId()].Contact.AccountId;
            Incentives__c record = new Incentives__c(Type__c = type, Navigate_Url__c = url, 
                                                     RecordTypeId = recordTypeId, Status__c = 'Submitted', 
                                                     Start__c = date.today(),
                                                     Account_Name__c = accId);
            insert record;
            recordId = record.Id;
            List<ContentVersion> cvList = new List<ContentVersion>();
            for(ContentVersion cv : [SELECT Id,ContentDocumentId from ContentVersion WHERE ContentDocumentId IN : filesToInsert]){
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ShareType='V';
                cdl.LinkedEntityId = recordId;
                cdl.ContentDocumentId = cv.ContentDocumentId;
                cdlList.add(cdl);
            }
            insert cdlList;
            return 'success';
        }catch(exception e){
            system.debug(LoggingLevel.DEBUG, '->'+e);
            return e.getMessage();
        }
    }
    
    @AuraEnabled
    public static leadDashboardWrapper getLeadDashboardData(String searchText){
        leadDashboardWrapper leadWrap = new leadDashboardWrapper();
        List<Lead> leadList = new List<Lead>();
        List<Contact> contactList = new List<Contact>();
        Set<Id> leadIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Date today = Date.today();
        Id userID = UserInfo.getUserId();
        String sText = String.escapeSingleQuotes(searchText);
        try{
            String conQuery = 'SELECT Id, Contact_Status__c, Name, Account.Name, Email, Phone, Title, MailingCity, MailingState, MailingCountry, Last_MQL_Date__c, Lead_Share_Program_Expiration_Date__c, MailingStateCode, MailingCountryCode,CreatedDate,LastActivityDate,Lead_Source_Most_Recent__c,Lead_Source_Most_Recent_Details__c,'+
                			  '(Select Id,Primary_Contact__c,Deal_Registration_Status__c from Deal_Registrations1__r WHERE Lead_Share_Campaign__c = true),'+
                			  '(Select Id, Type, Post_Meeting_Status__c from Events WHERE Type = \'Marketing Generated Meeting\' AND Post_Meeting_Status__c != \'Meeting Cancelled\')'+
                			  ' FROM Contact WHERE OwnerId =: userID AND Contact_Status__c IN (\'Open\', \'Meeting Set\', \'Nurture\', \'Working\')'+
                			  ' AND Lead_Share_Program_Expiration_Date__c >=: today';
            
            String leadQuery = 'SELECT Id, Status, Name, Company, Email, Phone, Title, City, State, Country, Last_MQL_Date__c, Lead_Share_Program_Expiration_Date__c, StateCode, CountryCode,createdDate, LastActivityDate,Lead_Source_Most_Recent__c,Lead_Source_Most_Recent_Details__c,'+
                			   '(Select Id, Lead__c, Deal_Registration_Status__c from Deal_Registrations__r WHERE Lead_Share_Campaign__c = true),'+
                			   '(Select Id, Type, Post_Meeting_Status__c from Events WHERE Type = \'Marketing Generated Meeting\' AND Post_Meeting_Status__c != \'Meeting Cancelled\')'+
                			   ' FROM Lead WHERE OwnerId =: userID AND Status IN (\'Open\', \'Meeting Set\', \'Nurture\', \'Working\')'+
                			   ' AND ConversionStatus__c = \'Unconverted\' AND Lead_Share_Program_Expiration_Date__c >=: today';
            
            if(!String.isBlank(searchText) && searchText != null){
                conQuery = conQuery + ' AND (Name LIKE \'%'+ sText + '%\' OR Email LIKE \'%'+ sText +'%\' OR Account.Name LIKE \'%'+ sText +'%\')';
                leadQuery = leadQuery + ' AND (Name LIKE \'%'+ sText + '%\' OR Email LIKE \'%'+ sText +'%\' OR Company LIKE \'%'+ sText +'%\')';
            }
            for(Contact con : Database.query(conQuery)){
                contactList.add(con);
            }
            
            for(Lead lead : Database.query(leadQuery)){
                leadList.add(lead);
            }
            
            leadWrap.contactList = contactList;
            leadWrap.leadList = leadList;
            
            return leadWrap;
        }catch(exception e){
            system.debug(LoggingLevel.DEBUG, 'Error->'+ e);
            return null;
        }
        
    }

    @AuraEnabled(cacheable=true)
    public static accHierarchyWrapper getAccountHierarchy(){
        try {
            accHierarchyWrapper wrap = new accHierarchyWrapper();
            Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            User usr = [SELECT Id, Contact.AccountId, Contact.Primary_Role__c FROM User WHERE Id =: UserInfo.getUserId()];
            wrap.userRec = usr;
            if(usr.Contact.Primary_Role__c == 'Admin' || usr.Contact.Primary_Role__c == 'Executive'){
                List<Account> accList =  [SELECT Id, Name, ParentId FROM Account WHERE (Id =:usr.Contact.AccountId OR ParentId =:usr.Contact.AccountId) and RecordTypeId=:accRecordTypeId LIMIT 200];
                if(!accList.isEmpty() && accList.size() > 1){
                    wrap.accList = accList;
                }else{
                    wrap.accList = null;
                }
            }
            return wrap;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description       : Wrapper class to store Account hierarchy
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class AccHierarchyWrapper{
        @AuraEnabled
        public List<Account> accList;
        @AuraEnabled
        public User userRec;
    }

    @AuraEnabled
    public static List<sObject> getActiveCertifications(List<Id> accIds){
        try {
            Id accRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner/Distributor').getRecordTypeId();
            User usr = [SELECT Id, Contact.AccountId, Contact.Primary_Role__c FROM User WHERE Id =: UserInfo.getUserId()];
            if(usr.Contact.Primary_Role__c == 'Admin' || usr.Contact.Primary_Role__c == 'Executive'){
                String accId = usr.Contact.AccountId;
                String partQuery1 = 'SELECT Id, Name, Account_Name__c, RCSA_Accredited__c, RTA_Accredited__c, RRE_Accredited__c, RRS_Accredited__c, RTP_Accredited__c, RCIE_Certified__c FROM Contact ';
                String partQuery2 = 'WHERE AccountId IN (SELECT Id FROM Account WHERE ';
                String partQuery3 =  accIds.isEmpty() ? '(Id =:accId OR ParentId =:accId) ' : ' ID IN :accIds ';
                String partQuery4 = 'AND RecordTypeId=:accRecordTypeId) AND ';
                String partQuery5 = '((RCSA_Expiration__c != NULL AND RCSA_Expiration__c >= TODAY) OR (RTA_Expiration__c != NULL AND RTA_Expiration__c >= TODAY) OR '+
                                    '(RRE_Expiration__c != NULL AND RRE_Expiration__c >= TODAY) OR (RRS_Expiration__c != NULL AND RRS_Expiration__c >= TODAY) OR '+
                                    '(RTP_Expiration__c != NULL AND RTP_Expiration__c >= TODAY) OR (RCIE_Expiration__c != NULL AND RCIE_Expiration__c >= TODAY)) LIMIT 5000';
                String query= partQuery1 + partQuery2 + partQuery3 + partQuery4 + partQuery5;
                return Database.query(query);
            }
            return null;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static List<sObject> getRebateReportData(List<Id> accIds, String startDate, String endDate){
        try {
            User usr = [SELECT Id, Contact.AccountId, Contact.Primary_Role__c FROM User WHERE Id =: UserInfo.getUserId()];
            if(usr.Contact.Primary_Role__c == 'Admin' || usr.Contact.Primary_Role__c == 'Executive'){
                String accId = usr.Contact.AccountId;
				Map<Id,Account> childAccs = new Map<Id,Account> ([SELECT Id FROM Account WHERE ParentId = :accId]);
				Set<Id> childAccIds = childAccs.keyset();
                String partQuery1 = 'SELECT Id, Partner_Account__c,Partner_Account__r.Name,Status__c, Start_Date__c, End_Date__c, Approved_Date__c, Max_Rebate_Payout__c, Actual_Rebate_Payout__c, Max_Total_Milestone_Payout__c, Actual_Total_Milestone_Payout__c FROM MIP_Contract__c WHERE Status__c = \'Approved\' AND ';
                String partQuery2 =  accIds.isEmpty() ? '(Partner_Account__c =:accId OR Partner_Account__c  IN :childAccIds) ' : ' Partner_Account__c IN :accIds ';
                if(!String.isBlank(startDate)){
                    Date startDateConv = Date.valueOf(startDate);
                    partQuery2 = partQuery2 + ' AND End_Date__c >=: startDateConv';
                }
                if(!String.isBlank(endDate)){
                    Date endDateConv = Date.valueOf(endDate);
                    partQuery2 = partQuery2 + ' AND End_Date__c <=: endDateConv';
                }
                String partQuery3 = ' ORDER BY End_Date__c DESC';
                String query= partQuery1 + partQuery2 + partQuery3;

                return Database.query(query);
            }
            return null;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description       : Wrapper class for Lead Dashboard data
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class LeadDashboardWrapper{
        @AuraEnabled
        public List<Contact> contactList;
        @AuraEnabled
        public List<Lead> leadList;
    }
    
    @AuraEnabled
    public static List<FiscalYearSettings> getFiscalYear(){
        List<FiscalYearSettings> fysList = new List<FiscalYearSettings>();
        for(FiscalYearSettings fys : [Select Id,EndDate, Description, IsStandardYear, Name, PeriodId, PeriodLabelScheme, PeriodPrefix, QuarterLabelScheme, 
                                      QuarterPrefix, StartDate, SystemModstamp, WeekLabelScheme, WeekStartDay, YearType from FiscalYearSettings
                                      WHERE StartDate >=: Date.valueOf('2022-02-01') AND StartDate <=: Date.today() ORDER By StartDate DESC])
        {
            fysList.add(fys);
        }
        return fysList; 
    }
    
    @AuraEnabled
    public static wrapperData getAllData(String startDate, String endDate, List<String> accIds, String fiscalYear){
        wrapperData wrapper = new wrapperData();
        String salesRecId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Sales_Opportunity').getRecordTypeId();
        User partnerUser = [SELECT Id,Name,Contact.AccountId
                            FROM User WHERE Id =:UserInfo.getUserId()];
        
        String partnerAccId = String.escapeSingleQuotes(partnerUser.Contact.AccountId);
        Decimal fiscalYearDecimal = Decimal.valueOf(fiscalYear);
        List<String> activeWidgets = new List<String>();
        
        for( Partner_Page_Configuration__c  pc : [SELECT Headline__c FROM Partner_Page_Configuration__c WHERE Image_Type__c = 'Performance Dashboard Widget' AND Page_Name__c = 'Partner Performance Dashboard' AND Active__c = TRUE]){
            activeWidgets.add(pc.Headline__c);
        }
        //Opp Data
        //String oppQuery = 'SELECT Id, StageName, Amount, Partner_Lookup__c, CloseDate FROM Opportunity WHERE';
        String oppQuery = 'SELECT Id, StageName, Amount, ACV_Amount__c, Partner_Lookup__c, Partner_Lookup__r.Name,Deal_Registration_Type__c, CloseDate, Account.Name, Sourcing_Partner__c, Sourcing_Partner__r.Name FROM Opportunity WHERE';

        //PSNL Opp
        String psnlOppQuery = 'SELECT Id, StageName, Amount, ACV_Amount__c, Partner_Lookup__c, Partner_Lookup__r.Name,Deal_Registration_Type__c, CloseDate, Account.Name, Sourcing_Partner__c, Sourcing_Partner__r.Name FROM Opportunity WHERE';

        //PS Expand Opp
        String psExpOppQuery = 'SELECT Id, StageName, Amount, ACV_Amount__c, Partner_Lookup__c, Partner_Lookup__r.Name,Deal_Registration_Type__c, CloseDate, Account.Name, Sourcing_Partner__c, Sourcing_Partner__r.Name FROM Opportunity WHERE';

        //MDF Data
        //String mdfQuery = 'SELECT Id, RequestedAmount , Status, Activity_Start_Date__c, ChannelPartnerId FROM PartnerFundRequest WHERE';
        String mdfQuery = 'SELECT Id, RequestedAmount , Status, Activity_Start_Date__c, ChannelPartnerId, ChannelPartner.Name, Activity, Title, Amount FROM PartnerFundRequest WHERE Status =\'Approved\' AND';
        
        //Contact Data
        String conQuery = 'SELECT Id,Name,Account_Name__c,RCSA_Accredited__c,RTP_Accredited__c,RCRS_Accredited__c,RCCS_Accredited__c,RCDP_Accredited__c,RCDP_S_Accredited__c FROM Contact WHERE';
        				
        //Deal Reg Data
        //String dealRegQuery = 'SELECT Id, Opportunity_Amount_TVC__c, PID_Meeting_Task__c, Registration_Type__c, Deal_Registration_Status__c, Deal_Reg_Submitted_Date__c, DR_Approved_Date__c FROM Deal_Registration__c WHERE';
        String dealRegQuery = 'SELECT Id, Opportunity_Amount_TVC__c, PID_Meeting_Task__c, Registration_Type__c, Deal_Registration_Status__c, Deal_Reg_Submitted_Date__c, DR_Approved_Date__c, Deal_Registration_Type__c,Company__c,Partner_Lookup__r.Name,Opportunity__c,Opportunity__r.Sourcing_Partner__c  FROM Deal_Registration__c WHERE Opportunity__c != NULL AND'; //prit25-31
        
        //CCR Data
        //String ccrQuery = 'SELECT Id, Partner_SE_Amount__c, Partner_REP_Amount__c, Approval_Date__c, Partner_Company_Name__c FROM CCR__c WHERE RecordType.Name = \'Partner Claim Form\' AND CCR_Type__c =\'Channel SPIFF\' AND User__c =\'Approved\' AND';
        String ccrQuery = 'SELECT Id, Partner_SE_Amount__c, Partner_REP_Amount__c, Approval_Date__c, Partner_Company_Name__c,Incentive__r.Name,Customer_Company__c,Partner_Company_Name__r.Name FROM CCR__c WHERE RecordType.Name = \'Partner Claim Form\' AND CCR_Type__c =\'Channel SPIFF\' AND User__c =\'Approved\' AND';

        //MIP Contract Data
        String mipQuery = 'SELECT Id, Partner_Account__c, Actual_Rebate_Payout__c, Max_Rebate_Payout__c, Actual_Total_Milestone_Payout__c, Max_Total_Milestone_Payout__c, Status__c, Start_Date__c, End_Date__c FROM MIP_Contract__c WHERE Status__c = \'Approved\' AND';
        
        //Program points query
        String ppQuery = 'SELECT Id, Total__c, RCIE_Certification_Points__c , RRE_Certification_Points__c, RRS_Certification_Points__c, RTP_Certification_Points__c, Accelerator_Points__c, X100K_Increment_of_Total_Bookings__c, Save_the_Data_Events__c, Fiscal_Year__c , Partner_Lookup__c, Partner_Name__c, Partner_Sourced_New_Logo__c, Ransomware_Accreditations_Certifications__c, Technical_Certifications__c, Technical_Sales_Accreditation__c FROM Program_Point__c WHERE Fiscal_Year__c =: fiscalYearDecimal AND Is_Account_Deleted__c = false AND';
        
        //Account Hierarchy filter
        if(accIds != null && accIds.size() > 0){
            oppQuery = oppQuery + ' Partner_Lookup__c IN: accIds';

            psnlOppQuery = psnlOppQuery + ' Partner_Lookup__c IN: accIds AND (Deal_Registration_Type__c = \'Partner Sourced New Logo (PSNL)\' OR Deal_Registration_Type__c = \'Partner Initiated Deal\')';

            psExpOppQuery = psExpOppQuery + ' Partner_Lookup__c IN: accIds AND (Deal_Registration_Type__c = \'Partner Sourced Expand\' OR Deal_Registration_Type__c = \'Joint Initiated Deal\')';
            
            mdfQuery = mdfQuery + ' ChannelPartnerId IN: accIds';
            
            conQuery = conQuery + ' AccountId IN: accIds';
            
            dealRegQuery = dealRegQuery + ' Opportunity__r.Sourcing_Partner__c IN: accIds'; //prit25-31
             
            ccrQuery = ccrQuery + ' Partner_Company_Name__c  IN: accIds';

            mipQuery = mipQuery + ' Partner_Account__c IN: accIds';
            
            ppQuery = ppQuery + ' Partner_Lookup__c IN: accIds';
        }else{
            oppQuery = oppQuery + ' Partner_Lookup__c =: partnerAccId';
            
            mdfQuery = mdfQuery + ' ChannelPartnerId =: partnerAccId';
            
            conQuery = conQuery + ' AccountId =: partnerAccId';
            
            dealRegQuery = dealRegQuery + ' Opportunity__r.Sourcing_Partner__c =: partnerAccId';//prit25-31
            
            ccrQuery = ccrQuery + ' Partner_Company_Name__c  =: partnerAccId';

            mipQuery = mipQuery + ' Partner_Account__c =: partnerAccId';
            
            ppQuery = ppQuery + ' Partner_Lookup__c =: partnerAccId';
        }
        
        //Fiscal Year Filter
        if(!String.isBlank(startDate)){
            Date startDateConv = Date.valueOf(startDate);
            
            oppQuery = oppQuery + ' AND CloseDate >= :startDateConv';

            psnlOppQuery = psnlOppQuery + ' AND CloseDate >= :startDateConv';

            psExpOppQuery = psExpOppQuery + ' AND CloseDate >= :startDateConv';
            
            mdfQuery = mdfQuery + ' AND Activity_Start_Date__c >=: startDateConv';
            
            dealRegQuery = dealRegQuery + ' AND DR_Approved_Date__c >=: startDateConv';
            
            ccrQuery = ccrQuery + ' AND Approval_Date__c >=: startDateConv';

            mipQuery = mipQuery + ' AND End_Date__c >=: startDateConv';
            
        }
        if(!String.isBlank(endDate)){
            Date endDateConv = Date.valueOf(endDate);
            
            oppQuery = oppQuery + ' AND CloseDate <= :endDateConv';

            psnlOppQuery = psnlOppQuery + ' AND CloseDate <= :endDateConv';

            psExpOppQuery = psExpOppQuery + ' AND CloseDate <= :endDateConv';
            
            mdfQuery = mdfQuery + ' AND Activity_Start_Date__c <=: endDateConv';
            
            dealRegQuery = dealRegQuery + ' AND DR_Approved_Date__c <=: endDateConv';
            
            ccrQuery = ccrQuery + ' AND Approval_Date__c <=: endDateConv';

            mipQuery = mipQuery + ' AND End_Date__c <=: endDateConv';
            
        }
        
        oppQuery = oppQuery + ' AND RecordTypeId =: salesRecId';

        psnlOppQuery = psnlOppQuery + ' AND RecordTypeId =: salesRecId';

        psExpOppQuery = psExpOppQuery + ' AND RecordTypeId =: salesRecId';
        
        conQuery = conQuery + ' AND ((RCSA_Expiration__c != NULL AND RCSA_Expiration__c >= TODAY) OR '
                                + '(RTP_Expiration__c != NULL AND RTP_Expiration__c >= TODAY) OR '
                                + '(RCRS_Expiration__c != NULL AND RCRS_Expiration__c >= TODAY) OR '
                                + '(RCCS_Expiration__c != NULL AND RCCS_Expiration__c >= TODAY) OR '
                                + '(RCDP_Expiration__c != NULL AND RCDP_Expiration__c >= TODAY) OR '
                                + '(RCDP_S_Expiration__c != NULL AND RCDP_S_Expiration__c >= TODAY))';
        
        oppQuery = oppQuery + ' ORDER BY CloseDate DESC';
        psnlOppQuery = psnlOppQuery + ' ORDER BY CloseDate DESC';
        psExpOppQuery = psExpOppQuery + ' ORDER BY CloseDate DESC';
        mdfQuery = mdfQuery + ' ORDER BY Activity_Start_Date__c DESC';
        dealRegQuery = dealRegQuery + ' ORDER BY DR_Approved_Date__c DESC';
        ccrQuery = ccrQuery + ' ORDER BY Approval_Date__c DESC';
        conQuery = conQuery + ' ORDER BY CreatedDate DESC';
        mipQuery = mipQuery + ' ORDER BY End_Date__c DESC';
        ppQuery = ppQuery + ' ORDER BY CreatedDate DESC';
        
        system.debug(LoggingLevel.DEBUG, oppQuery);
        wrapper.oppList = Database.query(oppQuery);
        wrapper.psnlOppList = Database.query(psnlOppQuery);
        wrapper.psExpOppList = Database.query(psExpOppQuery);
        wrapper.pfrList = Database.query(mdfQuery);
        wrapper.conList = Database.query(conQuery);
        wrapper.dealRegList = Database.query(dealRegQuery);
        wrapper.ccrList = Database.query(ccrQuery);
        wrapper.mipContractList = Database.query(mipQuery);
        wrapper.programPointsList = Database.query(ppQuery);
        wrapper.activeWidgetList = activeWidgets;
        return wrapper;
    }
    
    /**
     * @description       : Wrapper class for storing all data with different dynamic queries
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class WrapperData{
        @AuraEnabled
        public List<Opportunity> oppList;
        @AuraEnabled
        public List<Opportunity> psnlOppList;
        @AuraEnabled
        public List<Opportunity> psExpOppList;
        @AuraEnabled
        public List<Deal_Registration__c> dealRegList;
        @AuraEnabled
        public List<PartnerFundRequest> pfrList;
        @AuraEnabled
        public List<Contact> conList;
        @Auraenabled
        public List<CCR__c> ccrList;
        @AuraEnabled
        public List<MIP_Contract__c> mipContractList;
        @AuraEnabled
        public List<Program_Point__c> programPointsList;
        @AuraEnabled
        public List<String> activeWidgetList;
    }

    @AuraEnabled
    public static mipWrapper loadMIPForm(){
        mipWrapper wrap = new mipWrapper();
        
        Partner_Page_Configuration__c pConfig = [SELECT Id, Name, Active__c, Card_Title__c, Image_Text__c,Fiscal_Period__c, Program_Start_Date__c, Program_End_Date__c, Headline__c, Tag__c FROM Partner_Page_Configuration__c WHERE Active__c = true 
                                                 AND Program_Start_Date__c <=: Date.today() AND Program_End_Date__c >=: Date.today() AND Tag__c = 'MIP Enrollment Form' AND Image_Type__c = 'Card'];
        User u = [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name, Contact.Account.OwnerId, Contact.Account.Owner.Name FROM User WHERE Id =: UserInfo.getUserId()];
        
        wrap.pConfig = pConfig;
        wrap.u = u;

        return wrap;
    }

    @AuraEnabled
    public static void generateMIPContract(String formData){
        Map<String, Object> parsedData = (Map<String, Object>)JSON.deserializeUntyped(formData);
        MIP_Contract__c mipContractRec = new MIP_Contract__c();
        mipContractRec.Partner_Account__c = (Id)parsedData.get('accId');
        mipContractRec.Partner_Contact_of_Signature__c = (Id)parsedData.get('conId');
        mipContractRec.CDM__c = (Id)parsedData.get('usrId');
        //mipContractRec.Participating_Partner_Accounts__c = (String)parsedData.get('accName') +';';
        mipContractRec.Start_Date__c = Date.valueOf((String)parsedData.get('sDate'));
        mipContractRec.End_Date__c = Date.valueOf((String)parsedData.get('eDate'));
        mipContractRec.Fiscal_Period__c = (String)parsedData.get('fPeriod');
        mipContractRec.Agreement__c = (String)parsedData.get('agrText');
        mipContractRec.Status__c = 'Draft';
        insert mipContractRec;

        MIP_Account_Contribution__c mipAccContri = new MIP_Account_Contribution__c();
        mipAccContri.Partner_Account__c = (Id)parsedData.get('accId');
        mipAccContri.MIP_Contract__c = mipContractRec.Id;
        insert mipAccContri;

        Approval.ProcessSubmitRequest req =  new Approval.ProcessSubmitRequest();
        req.setComments('Submitting request for approval.');
        req.setObjectId(mipContractRec.id);                
        req.setProcessDefinitionNameOrId('MIP_Contract_Approval_Processv2');
        Approval.ProcessResult result = Approval.process(req);
    }

    @AuraEnabled
    public static Map<String,String> callReSignPactsafe(String partnertype, String email){
        Map<String,String> jsonMap = new Map<String,String>();
        Custom_Error_Log__c errorLog = new Custom_Error_Log__c();
        String contractGenerationStatus = '';
            String Endpoint = 'https://api.pactsafe.com/v1.1/sites/'+system.label.pactsafe_Site_Id+'/activity?filter=event_type==agreed%20and%20signer_id=='+email+'&sort=created_time%20desc';
            Http http = new Http();
            if(Test.isRunningTest()){
                Endpoint= 'http://pactsafe.com/example/test';
            }
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Endpoint);
            req.setMethod('GET');
            req.setHeader('Authorization','Bearer '+system.label.pactsafe_access_token);
            HTTPResponse res = http.send(req);
            if(res.getStatusCode() == 200 && res.getStatus() == 'OK'){
                contractGenerationStatus = 'Successful';
            } else {
                contractGenerationStatus = 'Error';
                errorLog.Http_Request__c = 'GET';
                errorLog.Http_StatusCode__c = String.valueOf(res.getStatusCode());
                errorLog.Functionality__c = 'Partner Onboarding';
                errorLog.Http_Response__c = res.getBody();
                errorLog.Class__c = 'PC_PactsafeCalloutController';
            }
            insert errorLog;
            String resbody = res.getBody();
            JSONParser parser = JSON.createParser(resbody);

            jsonMap.put('Master','');
            if(partnertype == 'Reseller' || partnertype == 'MSP-Reseller'){
                jsonMap.put('Secondary','');
            }
            if(partnertype == 'MSP-Reseller' || partnertype == 'MSP'){
                jsonMap.put('Tertiary','');
            }
            String stremail = '';
            String page_query = '';
            String download_url = '';
            List<String> arr = new List<String>();
            List<String> arrtemp = new List<String>();
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == System.JSONToken.FIELD_NAME) {
                    String text = parser.getText();
                    if (parser.nextToken() != System.JSONToken.VALUE_NULL) {
                        if (text == 'page_query') {
                            page_query = parser.getText();
                            system.debug(LoggingLevel.DEBUG, '@@ page_query '+page_query);
                            if(page_query.contains('&')){
                                arr = page_query.split('&');
                                stremail = 'email='+email;
                                if(arr.size() > 2 && arr[2] == stremail && arr[0].contains('=')){
                                    arrtemp = arr[0].split('=');
                                    system.debug(LoggingLevel.DEBUG, '## arrtemp '+arrtemp);
                                    if(jsonMap != null && jsonMap.containskey(arrtemp[1]) && jsonMap.get(arrtemp[1]) == ''){
                                        system.debug(LoggingLevel.DEBUG, '## in arrtemp[1] '+arrtemp[1]);
                                        jsonMap.put(arrtemp[1],'fill');
                                    }
                                }
                            }
                        }else if (text == 'download_url') {
                            download_url = parser.getText();
                            system.debug(LoggingLevel.DEBUG, '@@ download_url '+download_url);
                            for(String key : jsonMap.keyset()){
                                if(jsonMap.get(key) == 'fill'){
                                    jsonMap.put(key,download_url);
                                }
                            }
                        }
                    }
                }
            }
        return jsonMap;
    }
	
	@AuraEnabled
    public static String createContract(String contactId, List<String> urls){        
        String returnStr = '';
        List<Contract> contractList = new List<Contract>();
        List<Contract> contractsToUpdate = new List<Contract>();
        Contact con = [SELECT Id, Title, AccountId, Account.ETM_Territory__c, Account.Type, Account.BillingCountry FROM Contact WHERE Id =: contactId];
        for(Integer i=0;i<urls.size();i++){
            Contract ct = new Contract();
            //ct.Territory__c= con.Account.ETM_Territory__c != null && con.Account.ETM_Territory__c != '' ? con.Account.ETM_Territory__c : '';
            if(i==0){
                ct.Terms_Download_Url__c = urls[0];
                ct.ClickThroughContract_Name__c = 'Master';
                ct.Agreement_Type__c = 'Master Agreement';
            }else if(i== 1 && (con.Account.Type == 'MSP-Reseller' || con.Account.Type == 'MSP' || con.Account.Type == 'Reseller')){
                ct.Terms_Download_Url__c = urls[1];
                ct.ClickThroughContract_Name__c = 'Secondary';
                ct.Agreement_Type__c = 'Reseller';
            }else if(i==2 && (con.Account.Type == 'MSP-Reseller' || con.Account.Type == 'MSP')){
                ct.Terms_Download_Url__c = urls[2];
                ct.ClickThroughContract_Name__c = 'Tertiary';
                ct.Agreement_Type__c = con.Account.Type;
            }
            system.debug(LoggingLevel.DEBUG, '@@ entered i '+i);
            ct.Territory_Country__c = con.Account.BillingCountry;
            ct.AccountId = con.AccountId;
            ct.CustomerSignedId = contactId;
            ct.CustomerSignedDate = System.today();
            if(con.Title!= null){
                ct.CustomerSignedTitle = con.Title.length() > 40 ? con.Title.left(40) : con.Title;
            }
            ct.ContractTerm = 1000;
            ct.Click_Through__c = true;
            ct.StartDate = system.today();
            ct.CompanySignedDate = system.today();
            ct.Contract_Status__c = 'Active';
            ct.CompanySignedId = UserInfo.getuserId();

            contractList.add(ct);
        }
        if(!contractList.isEmpty()){
            try{
                insert contractList;
            
                //Update old contract to Superseded
                for(Contract oldContract : [SELECT ID, Contract_Status__c FROM Contract WHERE AccountId =: con.AccountId AND Agreement_Type__c IN ('Master Agreement','Reseller','MSP','MSP-Reseller') and Id NOT IN :contractList]){
                    oldContract.Contract_Status__c = 'Superseded';
                    contractsToUpdate.add(oldContract);
                }
                update contractsToUpdate;
                
                //Update the Account to Signed-Active
                Account acc = new Account();
                acc.Id = con.AccountId;
                acc.Contract_Status__c = 'Signed-Active';
                acc.Partner_Agreement_Status__c = 'Signed-Active';
                acc.Program_Status__c = 'Compliant';
                acc.Agreed_To_POC_terms__c = true;
                update acc;
                
                //Create PDF files
                List<Id> contractListId = new List<Id>();
                for(Contract ct : contractList){
                    contractListId.add(ct.Id);
                }
                PartnerOnboardingRequestTriggerHelper.contractpdfcreation(contractListId, Network.getNetworkId());
                returnStr = 'SUCCESS';
            }catch(Exception e){
                returnStr = JSON.serialize(e);
            }
        }
        return returnStr;
    }

    /**
     * @description       : Wrapper class for MIP Form
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    public class MipWrapper{
        @AuraEnabled
        public Partner_Page_Configuration__c pConfig;
        @AuraEnabled
        public User u;
    }

    @AuraEnabled
    public static User getLoggedInUserDetails(){
        User u = [SELECT Id, Title, Name, ContactId, Contact.AccountId, Contact.Account.Type, Contact.Email FROM User Where Id=: UserInfo.getUserId()];
        return u;
    }
	
    /**
     * @description : method to insert engagement deal registration
     * @return Deal_Registration__c record with ID
     * @lwc - pc_managedServiceRequestForm_lwc
     */
    @AuraEnabled
    public static Deal_Registration__c saveEngagementDealRegistration(Deal_Registration__c record)
    {
        User u = getLoggedInUserDetails();
        List<Contact> conList = [SELECT Id FROM Contact WHERE FirstName=:record.FirstName__c AND LastName =: record.LastName__c AND Email=:record.Email__c LIMIT 1];
        if (!conList.isEmpty()) {
            record.Primary_Contact__c = conList[0].Id;
        }
        record.Created_by_Contact__c = u.ContactId;
        record.RecordTypeId = EngagementRecordTypeId;
        record.Partner_Rep_Email_Address__c = UserInfo.getUserEmail();
        record.Deal_Registration_Status__c = 'Submitted';
        record.Deal_Reg_Submitted_Date__c = Datetime.now();
        record.Partner_Lookup__c = u.Contact.AccountId;
        insert record;
        
        return record;
    }

    /**
     * @description       : Method to transform ContentDocument url to Content version's VersionDataUrl
     * @author            : Partner IT team
     * @group             : 
     * @last modified on  : 01-30-2026
     * @last modified by  : Harshit Garg
    **/
    private static List<Partner_Page_Configuration__c> transformImageUrl(List<Partner_Page_Configuration__c > configRecords)
    {
        Map<Id,String> configIdtoFileIdMap = new Map<Id,String>();
        Map<String, String> fileIdToUrlMap = new Map<String, String>();
        for(Partner_Page_Configuration__c record : configRecords){
            if(record.Image_Url__c != null && record.Image_Url__c.contains('ContentDocument/')){
                String docId = record.Image_Url__c.split('ContentDocument/')[1];
                docId = docId.split('/')[0];
                record.Image_Url__c = docId;
                configIdtoFileIdMap.put(record.Id, docId);
            }
        }
        if(!configIdtoFileIdMap.isEmpty())
        {
            for(ContentVersion cv : [SELECT Id, ContentDocumentId, Title, VersionDataUrl, FileExtension FROM ContentVersion 
                                     WHERE ContentDocumentId IN : configIdtoFileIdMap.values() AND IsLatest = TRUE])
                                     {
                                        fileIdToUrlMap.put(cv.ContentDocumentId, cv.VersionDataUrl);
                                     }
        }
        if(!fileIdToUrlMap.isEmpty())
        {
            for(Partner_Page_Configuration__c record : configRecords)
            {
                if(record.Image_Url__c != null && fileIdToUrlMap.containsKey(record.Image_Url__c))
                record.Image_Url__c = fileIdToUrlMap.get(record.Image_Url__c);
            }
        }
        return configRecords;
    } 
}