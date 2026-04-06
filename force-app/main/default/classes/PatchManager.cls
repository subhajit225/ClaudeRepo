/*******************************************************************************************************
* @author Rubrik
* @date 2018
* @description Partner Community
*******************************************************************************************************/
public class PatchManager {
    public static String PARTNER_TYPE_RESALE ='Reseller';
    public static String PARTNER_TYPE_RESALE_MSP ='MSP-Reseller'; // 1st CDM, 2nd MSP Rep
    public static String PARTNER_TYPE_DISTRIBUTOR ='Distributor';
    public static String PARTNER_TYPE_TAP ='Alliance Partner';
    public static String PARTNER_TYPE_MSP ='MSP';
    public static String PARTNER_ONBOARD_STATUS_PENDING ='Pending';
    public static String DEAL_REG='Deal_Registration__c';
    public static String ALLIANCE_DEAL_REG = 'Alliance_Deal_Registration__c';
    public static String LEAD='Lead';
    public static String ACCOUNT='Account';
    public static String CONTACT='Contact';
    public static String PARTNER_ONBOARDING='Partner_Onboarding_Request__c';
    public static String PARTNER_ACCESS='Partner_Registration_Request__c';
    public static String ALL_RECORDS='All';
    public static PatchManagerSettings__c patchManagerCustomSetting = PatchManagerSettings__c.getOrgDefaults();
    public static Decimal REVENUE_THRESHOLD = patchManagerCustomSetting.Segment_Revenue__c;
    public static String DEFAULT_USER = patchManagerCustomSetting.Default_User_Id__c;
    public static String DEFAULT_SDR = patchManagerCustomSetting.Default_SDR_ID__c;
    public static String DEFAULT_ACCT_OWNER = patchManagerCustomSetting.Default_Account_User__c;
    public static String DEFAULT_DISTRIBUTOR_OWNER = patchManagerCustomSetting.Default_Distributor_ID__c;
    public static String DEFAULT_TAP_OWNER = patchManagerCustomSetting.Default_TAP_ID__c;
    public static boolean ROUTE_ON_INSERT_ACCOUNT = patchManagerCustomSetting.Route_on_Insert_Account__c;
    public static boolean ROUTE_ON_INSERT_LEAD = patchManagerCustomSetting.Route_on_Insert_Lead__c;
    public static boolean ROUTE_ON_INSERT_DEALREG = patchManagerCustomSetting.Route_on_Insert_Deal_Reg__c;
    public static boolean ROUTE_ON_INSERT_CONTACT = patchManagerCustomSetting.Route_on_Insert_Contact__c;
    public static boolean ROUTE_ON_INSERT_PARTNER = patchManagerCustomSetting.Route_on_Insert_Partner__c;
    
    /**********************************************************************
    Deal Registration Assignment - Primary method for which Patch a the Deal reg is assigned to
    ***********************************************************************/
    public static PatchManager__c assignDealReg(Map<String, List<PatchManager__c>> patchMap, Deal_Registration__c vDealReg){
        PatchManager__c vManager = null;
        System.debug('@@Deal Reg Data: '+ vDealReg.Country__c+':'+ vDealReg.PostalCode__c+':'+ vDealReg.StateCode__c+':');
        String postalCode = cleanPostalCode(vDealReg.PostalCode__c);

        if(patchMap.containsKey(vDealReg.Country__c+'/'+vDealReg.StateCode__c +'/'+postalCode)){
            vManager = patchMap.get(vDealReg.Country__c+'/'+vDealReg.StateCode__c +'/'+postalCode).get(0);
        } else if(patchMap.containsKey(vDealReg.Country__c+'/'+vDealReg.StateCode__c )){
            vManager = patchMap.get(vDealReg.Country__c+'/'+vDealReg.StateCode__c).get(0);
        } else if(patchMap.containsKey(vDealReg.Country__c+'/'+postalCode)){
            vManager = patchMap.get(vDealReg.Country__c+'/'+postalCode).get(0);
        } else if(patchMap.containsKey(vDealReg.Country__c)){
            vManager = patchMap.get(vDealReg.Country__c).get(0);
        } else if(patchMap.containsKey(postalCode)){
            vManager = patchMap.get(postalCode).get(0);
        }
		//prit25-161
        /*if(vManager != null && vManager.RecordType.Name == 'Geographic'){  // PRIT24-865 : RecordType Check
            vDealReg.PatchManager__c = vManager.Id;

            if(vManager.CDM__c != null){
                vDealReg.CDM__c = vManager.CDM__c;
            }
            if(String.isBlank(vDealReg.Company_Name__c) && vManager.CDM__c != null && vManager.CDM__r.IsActive){
                vDealReg.OwnerId = vManager.CDM__c;
            }else if((vManager.CDM__c != null && !vManager.CDM__r.IsActive) || vManager.CDM__c == null){
                vDealReg.OwnerId = vManager.OwnerId;
            }
        }*/
        System.debug('@@Deal Reg Assigned: '+ vManager);
        return vManager;
    }

    /**********************************************************************
         Lead Assignment - Primary for which Patch a lead get's assigned to
      ***********************************************************************/
      public static void assignLead(Map<String, List<PatchManager__c>> patchMap, Lead vLead){
          PatchManager__c vManager=null;
          String postalCode = cleanPostalCode(vLead.PostalCode);
          
          //SF-535 - Update the priority of Lead Assignment
          //Will added Domain Routing and MatchedAccountOwner Routing
          if(patchMap.containsKey(vLead.Domain__c)) {
              vManager = patchMap.get(vLead.Domain__c).get(0);
          } else if(patchMap.containsKey(vLead.MatchedAccountOwner__c)) {
              vManager = patchMap.get(vLead.MatchedAccountOwner__c).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c)) {
              vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+postalCode+'/'+vLead.Industry_Category__c).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c)) {
              vManager = patchMap.get(vLead.Country+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c)) {
              vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+vLead.Industry_Category__c)) {
              vManager = patchMap.get(vLead.Country+'/'+vLead.Industry_Category__c).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode)) {
              vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+postalCode).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode)) {
              vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode).get(0);
          } else if(patchMap.containsKey(vLead.Country+'/'+postalCode)) {
              vManager = patchMap.get(vLead.Country+'/'+postalCode).get(0);
          } else if(patchMap.containsKey(vLead.Country)) {
              vManager = patchMap.get(vLead.Country).get(0);
          } 
          system.debug('PM Owner'+vManager);
          
          if(vManager !=null){
              if(vLead.Deal_Registration__c){
                  vLead.PatchManager__c=vManager.Id;
                  vLead.OwnerId = vManager.OwnerId;
              } else {
                  if('Sales' == vLead.Campaign_Sourced_By__c){
                      vLead.PatchManager__c=vManager.Id;
                  }else if('Domain' == vManager.Recordtype.Name) {
                      vLead.OwnerId = vManager.SDR__c==null?DEFAULT_SDR:vManager.SDR__c;
                      vLead.PatchManager__c=vManager.Id;
                  }else if(vLead.L2A_Confidence_Code__c >=3){
                      //assign dummy patchManager
                      vLead.PatchManager__c = Label.L2A_patch_key_Id;
                  }else {
                      vLead.OwnerId = vManager.SDR__c==null?DEFAULT_SDR:vManager.SDR__c;
                      vLead.PatchManager__c=vManager.Id;
                  }
              }
              
          }             
      }
      
      public static Map<Id, PatchManager__c> assignLead(Map<String, List<PatchManager__c>> patchMap, List<Lead> vLeads){
        Map<Id, PatchManager__c> leadIdToPatchManager = new Map<Id, PatchManager__c>();
        for(Lead vLead : vLeads){
            PatchManager__c vManager=null;
            String postalCode = cleanPostalCode(vLead.PostalCode);
            if(patchMap.containsKey(vLead.Domain__c)) {
                vManager = patchMap.get(vLead.Domain__c).get(0);
            } else if(patchMap.containsKey(vLead.MatchedAccountOwner__c)) {
                vManager = patchMap.get(vLead.MatchedAccountOwner__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c)) {
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+postalCode+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c)) {
                vManager = patchMap.get(vLead.Country+'/'+vLead.postalCode+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c)) {
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.Industry_Category__c)) {
                vManager = patchMap.get(vLead.Country+'/'+vLead.Industry_Category__c).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode+'/'+vLead.postalCode)) {
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode+'/'+postalCode).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+vLead.StateCode)) {
                vManager = patchMap.get(vLead.Country+'/'+vLead.StateCode).get(0);
            } else if(patchMap.containsKey(vLead.Country+'/'+postalCode)) {
                vManager = patchMap.get(vLead.Country+'/'+postalCode).get(0);
            } else if(patchMap.containsKey(vLead.Country)) {
                vManager = patchMap.get(vLead.Country).get(0);
            } 
            leadIdToPatchManager.put(vLead.Id, vManager); 
        }
        
        return leadIdToPatchManager;
    }
      /**********************************************************************
         Contact Assignment 
      ***********************************************************************/
      public static void assignContact(Map<String, List<PatchManager__c>> patchMap, Contact vContact){
          PatchManager__c vManager=null;
          String postalCode = cleanPostalCode(vContact.MailingPostalCode);
          if(patchMap.containsKey(vContact.MailingCountry+'/'+postalCode)){
              vManager = patchMap.get(vContact.MailingCountry+'/'+postalCode).get(0);
          } else if(patchMap.containsKey(postalCode)){
              vManager = patchMap.get(postalCode).get(0);
          } else if(patchMap.containsKey(vContact.MailingCity)){
              vManager = patchMap.get(vContact.MailingCity).get(0);
          } else if(patchMap.containsKey(vContact.MailingState)){
              vManager = patchMap.get(vContact.MailingState).get(0);
          } else if(patchMap.containsKey(vContact.MailingCountry)){
              vManager = patchMap.get(vContact.MailingCountry).get(0);
          }
          if(vManager !=null){
              vContact.PatchManager__c=vManager.Id;
              vContact.OwnerId = vManager.OwnerId;
          }
                      
      }
    
    /**********************************************************************
         Alliance Deal Registration Routing 
      ***********************************************************************/
      public static void assignAllianceDealReg(Map<String, List<PatchManager__c>> patchMap, Alliance_Deal_Registration__c vAllianceDealReg){
          PatchManager__c vManager=null;
          String zipCode = cleanPostalCode(vAllianceDealReg.Zip_code__c);
          if(patchMap.containsKey(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.Raw_State_Code__c+'/'+zipCode+'/'+vAllianceDealReg.City__c)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.Raw_State_Code__c+'/'+zipCode+'/'+vAllianceDealReg.City__c).get(0);
          }  else if(patchMap.containsKey(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.Raw_State_Code__c+'/'+zipCode)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.Raw_State_Code__c+'/'+zipCode).get(0);
          } else if(patchMap.containsKey(vAllianceDealReg.Country__c+'/'+zipCode+'/'+vAllianceDealReg.City__c)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c+'/'+zipCode+'/'+vAllianceDealReg.City__c).get(0);
          } else if(patchMap.containsKey(vAllianceDealReg.Country__c+'/'+zipCode)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c+'/'+zipCode).get(0);
          } else if(patchMap.containsKey(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.Raw_State_Code__c)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.Raw_State_Code__c).get(0);
          } else if(patchMap.containsKey(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.City__c)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c+'/'+vAllianceDealReg.City__c).get(0);
          } else if(patchMap.containsKey(vAllianceDealReg.Country__c)) {
              vManager = patchMap.get(vAllianceDealReg.Country__c).get(0);
          }
          if(vManager !=null && vManager.Alliance_BDM__c != null && vManager.Alliance_BDM__r.IsActive){
              vAllianceDealReg.PatchManager__c=vManager.Id;
              vAllianceDealReg.OwnerId = vManager.Alliance_BDM__c;
              vAllianceDealReg.BDM__c = vManager.Alliance_BDM__c;
          }else{
              vAllianceDealReg.OwnerId = vAllianceDealReg.BDM__c;
          }
      }
      
      /**********************************************************************
         Account Assignment 
      ***********************************************************************/
      public static void assignAccount(Map<String, List<PatchManager__c>> patchMap, Account vAccount){
          PatchManager__c vManager=null;
          String postalCode = cleanPostalCode(vAccount.BillingPostalCode);
          if(patchMap.containsKey(vAccount.Id)){
              vManager = patchMap.get(vAccount.Id).get(0);
          } else if(patchMap.containsKey(vAccount.BillingCountry+'/'+vAccount.BillingStatecode+'/'+postalCode)){
              vManager = patchMap.get(vAccount.BillingCountry+'/'+vAccount.BillingStatecode+'/'+postalCode).get(0);
          } else if(patchMap.containsKey(vAccount.BillingCountry+'/'+vAccount.BillingPostalCode)){
              vManager = patchMap.get(vAccount.BillingCountry+'/'+vAccount.BillingPostalCode).get(0);
          } else if(patchMap.containsKey(vAccount.BillingCountry+'/'+vAccount.BillingStatecode)){
              vManager = patchMap.get(vAccount.BillingCountry+'/'+vAccount.BillingStatecode).get(0);
          } else if(patchMap.containsKey(vAccount.BillingCountry)){
              vManager = patchMap.get(vAccount.BillingCountry).get(0);
          }
          if(vManager !=null){
              vAccount.PatchManager__c=vManager.Id;
              vAccount.OwnerId = vManager.OwnerId;
          } else {
              vAccount.OwnerId = DEFAULT_ACCT_OWNER;
          }
         system.debug('@@ vAccount '+vAccount);             
      }
      
      /**********************************************************************
         Partner Assignment 
      ***********************************************************************/
      public static void assignPartner(Map<String, List<PatchManager__c>> patchMap, Partner_Onboarding_Request__c vPartner){
          PatchManager__c vManager=null;
          //Boolean isOwnerUpdated = false;
          
          vPartner.OwnerId = label.POB_Exception_UserId;
          
          if(vPartner.PartnerType__c == PARTNER_TYPE_RESALE || vPartner.PartnerType__c == PARTNER_TYPE_RESALE_MSP){
              String postalCode = cleanPostalCode(vPartner.Postal_Code__c);
              
              if(patchMap.containsKey(vPartner.Country__c+'/'+vPartner.StateProvince__c +'/'+postalCode)){
                  vManager = patchMap.get(vPartner.Country__c+'/'+vPartner.StateProvince__c +'/'+postalCode).get(0);
              } else if(patchMap.containsKey(vPartner.Country__c+'/'+vPartner.StateProvince__c )){
                  vManager = patchMap.get(vPartner.Country__c+'/'+vPartner.StateProvince__c ).get(0);
              } else if(patchMap.containsKey(vPartner.Country__c+'/'+postalCode)){
                  vManager = patchMap.get(vPartner.Country__c+'/'+postalCode).get(0);
              } else if(patchMap.containsKey(vPartner.Country__c)){
                  vManager = patchMap.get(vPartner.Country__c).get(0);
              } else if(patchMap.containsKey(postalCode)){
                  vManager = patchMap.get(postalCode).get(0);
              }            
          }else if(vPartner.PartnerType__c == PARTNER_TYPE_MSP || vPartner.PartnerType__c == PARTNER_TYPE_DISTRIBUTOR){
              if(patchMap.containsKey(vPartner.Country__c+'/'+vPartner.StateProvince__c )){
                  vManager = patchMap.get(vPartner.Country__c+'/'+vPartner.StateProvince__c ).get(0);
              }else if(patchMap.containsKey(vPartner.StateProvince__c )){
                  vManager = patchMap.get(vPartner.StateProvince__c ).get(0);
              }else if(patchMap.containsKey(vPartner.Country__c)){
                  vManager = patchMap.get(vPartner.Country__c).get(0);
              }
          }else if(vPartner.PartnerType__c == PARTNER_TYPE_TAP){
              vPartner.OwnerId = DEFAULT_TAP_OWNER; // Jerome Noll
             // isOwnerUpdated = true;
          }
          
          if(vManager !=null){
              vPartner.PatchManager__c=vManager.Id;            
              //if(vPartner.PartnerType__c == PARTNER_TYPE_RESALE){
                  if(vManager.CDM__c != null && vManager.CDM__r.IsActive){
                      vPartner.OwnerId = vManager.CDM__c;
                      //isOwnerUpdated = true;
                  }else{
                    String exceptionOwnerID = Label.POB_Exception_UserId;
                    vPartner.OwnerId = exceptionOwnerID;
                  }                                
              /*}else if(vPartner.PartnerType__c == PARTNER_TYPE_RESALE_MSP){   
                      if(vManager.CDM__c != null){
                          vPartner.OwnerId = vManager.CDM__c;
                          vPartner.MSP_Approver__c = vManager.MSP_Rep__c;
                          //isOwnerUpdated = true;
                      }
                  /*else{
                      if(vManager.MSP_Rep__c != null){
                          vPartner.OwnerId = vManager.MSP_Rep__c;
                         // isOwnerUpdated = true;
                      } 
                  } */               
             /* }else if(vPartner.PartnerType__c == PARTNER_TYPE_MSP){
                  if(vManager.MSP_Rep__c != null){
                      vPartner.OwnerId = vManager.MSP_Rep__c;
                      //isOwnerUpdated = true;
                  }                
              }else if(vPartner.PartnerType__c == PARTNER_TYPE_DISTRIBUTOR){
                  if(vManager.Distributor_Rep__c != null){
                      vPartner.OwnerId = vManager.Distributor_Rep__c;
                      //isOwnerUpdated = true;
                  }                
              }*/
          }
          
         /* if(!isOwnerUpdated){
              vPartner.OwnerId = label.Unassigned_Partner_Request_Queue_Id;
          }*/
           System.debug('@@Partner onboarding: '+ vPartner);
          System.debug('@@Matching Patch manager: '+ vManager);
          
          
      }
      
       /**********************************************************************
         Partner Access Request 
    ***********************************************************************/
    public static PatchManager__c assignPartnerAccessRequest(Map<String, List<PatchManager__c>> patchMap, Partner_Registration_Request__c vPartnerAccess){
        PatchManager__c vManager=null;
        //Boolean isOwnerUpdated = false;
        String emailDomain = vPartnerAccess.Email__c.split('@')[1];
        List<Account> partnerAccount= [SELECT id, Owner.isActive, OwnerId FROM Account WHERE Id = :vPartnerAccess.Partner_Account_Lookup__c];  
        String postalCode = cleanPostalCode(vPartnerAccess.Postal_Code__c);
        system.debug('--country----->'+vPartnerAccess.Country_Picklist__c+'state--->'+vPartnerAccess.State_Picklist__c);
        system.debug('path map--->'+patchMap);
        //Changed country__c to countrypicklist__c
        if(patchMap.containsKey(vPartnerAccess.Country_Picklist__c+'/'+vPartnerAccess.State_Picklist__c +'/'+postalCode)){
            vManager = patchMap.get(vPartnerAccess.Country_Picklist__c+'/'+vPartnerAccess.State_Picklist__c +'/'+postalCode).get(0);
        } else if(patchMap.containsKey(vPartnerAccess.Country_Picklist__c+'/'+vPartnerAccess.State_Picklist__c )){
            vManager = patchMap.get(vPartnerAccess.Country_Picklist__c+'/'+vPartnerAccess.State_Picklist__c ).get(0);
        } else if(patchMap.containsKey(vPartnerAccess.Country_Picklist__c+'/'+postalCode)){
            vManager = patchMap.get(vPartnerAccess.Country_Picklist__c+'/'+postalCode).get(0);
        } else if(patchMap.containsKey(vPartnerAccess.Country_Picklist__c)){
            system.debug('Country_Picklist__c----->'+vPartnerAccess.Country_Picklist__c);
            vManager = patchMap.get(vPartnerAccess.Country_Picklist__c).get(0);
            system.debug('vManager----->'+vManager);
        } else if(patchMap.containsKey(postalCode)){
            vManager = patchMap.get(postalCode).get(0);
        } 

        if(partnerAccount.size() > 0 && partnerAccount[0].Owner.IsActive){
			vPartnerAccess.OwnerId = partnerAccount[0].OwnerId;
		}else if(vManager !=null && vManager.CDM__r.IsActive){
			vPartnerAccess.OwnerId = vManager.CDM__c;
		}else{
			vPartnerAccess.OwnerId = System.Label.POB_Exception_UserId;
		}
         
          System.debug('@@Partner Request form: '+ vManager);
          
          return vManager;
          
      }    
       /**********************************************************************
         Patch Manager Mapping - Creates a Map that the Query uses for the Where Clause
      ***********************************************************************/
      public static Map<String, List<PatchManager__c>> getPatchMap(List<SObject> vList, String objectType){
          Map<String, String> queryMap = new Map<String, String>();
          for(SObject so : vList){
                  if(DEAL_REG==objectType){
                      Deal_Registration__c vDealReg = (Deal_Registration__c)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vDealReg.PostalCode__c));
                      addQuery(queryMap, 'City__c', escapeString(vDealReg.City__c));
                      addQuery(queryMap, 'Domain__c', escapeString(vDealReg.Domain__c));
                      addQuery(queryMap, 'StateGlobal__c', escapeString(vDealReg.StateCode__c));
                      addQuery(queryMap, 'CountryGlobal__c', escapeString(vDealReg.Country__c));
                      addQuery(queryMap, 'Lead_Source_Detail__c', escapeString(vDealReg.Lead_Source_Details__c));  
                      addQuery(queryMap, 'LeadSource__c', escapeString(vDealReg.Lead_Source__c));
                      addQuery(queryMap, 'Industry_Category__c',escapeString(vDealReg.Industry_Category__c));    
                  // add here//
                  
                  } else if (LEAD == objectType){
                      Lead vLead = (Lead)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vLead.PostalCode)); 
                      addQuery(queryMap, 'City__c', escapeString(vLead.City));  
                      addQuery(queryMap, 'Domain__c', escapeString(vLead.Domain__c));
                      addQuery(queryMap, 'MatchedAccountOwner__r.Name', escapeString(vLead.MatchedAccountOwner__c));         
                      addQuery(queryMap, 'StateGlobal__c', escapeString(vLead.StateCode));
                      addQuery(queryMap, 'CountryGlobal__c', escapeString(vLead.Country));                
                      addQuery(queryMap, 'Lead_Source_Detail__c', escapeString(vLead.Lead_Source_Details__c));  
                      addQuery(queryMap, 'LeadSource__c', escapeString(vLead.LeadSource)); 
                      addQuery(queryMap, 'Industry_Category__c', escapeString(vLead.Industry_Category__c));                    
                  } else if (CONTACT == objectType){
                      Contact vContact = (Contact)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vContact.MailingPostalCode)); 
                      addQuery(queryMap, 'City__c', escapeString(vContact.MailingCity));          
                      addQuery(queryMap, 'StateGlobal__c', escapeString(vContact.MailingState));
                      addQuery(queryMap, 'CountryGlobal__c', escapeString(vContact.MailingCountry));              
                                  
                  } else if (ACCOUNT == objectType){
                      Account vAccount = (Account)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vAccount.BillingPostalCode)); 
                      addQuery(queryMap, 'City__c', escapeString(vAccount.BillingCity));          
                      addQuery(queryMap, 'StateGlobal__c', escapeString(vAccount.BillingStatecode));
                      addQuery(queryMap, 'CountryGlobal__c', escapeString(vAccount.BillingCountry)); 
                      addQuery(queryMap, 'Account__c', escapeString(vAccount.Id));
                                  
                  } else if(PARTNER_ONBOARDING == objectType){
                      Partner_Onboarding_Request__c vPartner = (Partner_Onboarding_Request__c)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vPartner.Postal_Code__c));
                      addQuery(queryMap, 'City__c', escapeString(vPartner.City__c));
                      //In case state value is null
                      if(escapeString(vPartner.StateProvince__c)!=null && escapeString(vPartner.StateProvince__c)!=''){
                          addQuery(queryMap, 'StateGlobal__c', escapeString(vPartner.StateProvince__c));
                      }
                      addQuery(queryMap, 'CountryGlobal__c', escapeString(vPartner.Country__c));                   
                  
                  }  else if(PARTNER_ACCESS == objectType){
                      Partner_Registration_Request__c vPartnerAccess = (Partner_Registration_Request__c)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vPartnerAccess.Postal_Code__c));
                      addQuery(queryMap, 'City__c', escapeString(vPartnerAccess.City__c));
                      system.debug('------vPartnerAccess.State_Picklist__c------->'+vPartnerAccess.State_Picklist__c);
                      //In case state value is null
                      if(escapeString(vPartnerAccess.State_Picklist__c)!=null && escapeString(vPartnerAccess.State_Picklist__c)!=''){
                          addQuery(queryMap, 'StateGlobal__c', escapeString(vPartnerAccess.State_Picklist__c));
                      }
                      
                      addQuery(queryMap, 'CountryGlobal__c', escapeString(vPartnerAccess.Country_Picklist__c));                   
                  }  else if (ALLIANCE_DEAL_REG == objectType){
                      Alliance_Deal_Registration__c vAllianceDealReg = (Alliance_Deal_Registration__c)so;
                      addQuery(queryMap, 'Zip_code__c', cleanPostalCode(vAllianceDealReg.Zip_code__c)); 
                      addQuery(queryMap, 'City__c', escapeString(vAllianceDealReg.City__c));          
                      addQuery(queryMap, 'StateGlobal__c', escapeString(vAllianceDealReg.Raw_State_Code__c));
                      addQuery(queryMap, 'Country__c', escapeString(vAllianceDealReg.Country__c));                                    
                  }
                         
          }
       
          System.debug('\n queryMap------- ---->'+ queryMap);        
          
          
          return queryPatchManger(queryMap, objectType);
      }
         
      /**********************************************************************
         Queries the Patch Manager Object  - returning a "patchMap" that is a
         map of all viable records for the given list of objects. 
      ***********************************************************************/
      public static  Map<String, List<PatchManager__c>> queryPatchManger(Map<String, String> query, String objectType){
              //TEMPORARY OVERRIDE OF THE OBJECT TYPE
              objectType = ALL_RECORDS;
              
              String soqlStatment = 'Select Id, Account__c, SearchCity__c, SearchState__c, SearchCountry__c, City__c, County__c, Domain__c,TLevel1__c,MatchedAccountOwner__r.Name,Region__c, Industry_Category__c, Lead_Source_Detail__c, LeadSource__c, Object_Type__c, OwnerId, SDR__c, SIC__c, Zip_code__c, CountryGlobal__c, StateGlobal__c, SMB_Owner__c, CDM__c, InsideAccountExecutive__c, Distributor_Rep__c, MSP_Rep__c,recordtypeId, RecordType.Name, Alliance_BDM__c, Alliance_BDM__r.IsActive, Country__c, SearchCountryCode__c,AccountExecutive__c,InsideAccountExecutive__r.IsActive,AccountExecutive__r.IsActive,CDM__r.IsActive from PatchManager__c';
  
          
          //Version 2.0
          String objectTypeCondition = 'Object_Type__c= \''+ String.escapeSingleQuotes(objectType)+'\'';
          String zipSearch = null;
          if(query.containsKey('Zip_code__c')){
              zipSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (Zip_code__c IN ('+query.get('Zip_code__c')+'))';
          }
          String citySearch=null;
          if(query.containsKey('City__c')){
                  citySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchCity__c IN ('+query.get('City__c')+'))';
          }
          String stateSearch=null;
          if(query.containsKey('StateGlobal__c')){
                  stateSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchState__c IN ('+query.get('StateGlobal__c')+'))';
          }
          String countrySearch=null;
          if(query.containsKey('CountryGlobal__c')){
                  countrySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchCountry__c IN ('+query.get('CountryGlobal__c')+'))';
          } else if(query.containsKey('Country__c')){
                  countrySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (SearchCountryCode__c IN ('+query.get('Country__c')+'))';
          }        
          String AccountIdSearch=null;
          if(query.containsKey('Account__c')){
                  AccountIdSearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND ( Account__c IN ('+query.get('Account__c')+'))';
          }        
          String MatchedOwnerSearch=null;
          if(query.containsKey('MatchedAccountOwner__r.Name')){
                  MatchedOwnerSearch= soqlStatment+' WHERE ('+objectTypeCondition+') AND ( MatchedAccountOwner__r.Name IN ('+query.get('MatchedAccountOwner__r.Name')+'))';
          }        
          String DomainSearch=null;
          if(query.containsKey('Domain__c')){
                  DomainSearch= soqlStatment+' WHERE ('+objectTypeCondition+') AND ( Domain__c IN ('+query.get('Domain__c')+'))';
          }
          String industryCategorySearch=null;
          if(query.containsKey('Industry_Category__c')){
              industryCategorySearch = soqlStatment+' WHERE ('+objectTypeCondition+') AND (Industry_Category__c IN ('+query.get('Industry_Category__c')+'))';
          }
           
          System.debug('soqlStatment: '+soqlStatment);
          System.debug('\n\n\n\n zipSearch: '+zipSearch);
          System.debug('citySearch: '+citySearch);
          System.debug('stateSearch: '+stateSearch);
          System.debug('countrySearch: '+countrySearch+'\n\n\n\n');
          System.debug('AccountIdSearch: '+AccountIdSearch+'\n\n\n\n');
          System.debug('DomainSearch: '+DomainSearch+'\n\n\n\n');
          System.debug('MatchedOwnerSearch: '+MatchedOwnerSearch+'\n\n\n\n');
          System.debug('industryCategorySearch: '+industryCategorySearch+'\n\n\n\n');
          
          //List<PatchManager__c> listPManager = Database.query(zipSearch);
          List<PatchManager__c> listPManager=null;
          
          Map<String, List<PatchManager__c>> patchMap = new Map<String, List<PatchManager__c>>();
          
          for(Integer i=0; i<8; i++){
              if(i==0 && zipSearch!=null){
                  listPManager=Database.query(zipSearch);
              } else if(i==1 && citySearch!=null){
                  listPManager=Database.query(citySearch);
              } else if (i==2 && countrySearch!=null){
                  listPManager=Database.query(countrySearch);
              } else if (i==3 && stateSearch!=null){
                  listPManager=Database.query(stateSearch);
              } else if (i==4 && AccountIdSearch!=null){
                  listPManager=Database.query(AccountIdSearch);
              } else if (i==5 && DomainSearch!=null){
                  listPManager=Database.query(DomainSearch);
              } else if (i==6 && MatchedOwnerSearch!=null){
                  listPManager=Database.query(MatchedOwnerSearch);
              } else if (i==7 && industryCategorySearch!=null){
                  listPManager=Database.query(industryCategorySearch);
              }
          
              if(listPManager!=null){
                  for(PatchManager__c vManager:listPManager){
                      //add as per industry category
                      if(vManager.Industry_Category__c == null) {
                          addPatchMap(vManager.SearchCity__c, vManager, patchMap);
                          // Satish 
                          //addPatchMap(vManager.SearchState__c, vManager, patchMap);
                          //addPatchMap(vManager.SearchCountry__c, vManager, patchMap);
                          addPatchMap(vManager.Domain__c, vManager, patchMap);
                          addPatchMap(vManager.MatchedAccountOwner__r.Name, vManager, patchMap);
                          addPatchMap(vManager.StateGlobal__c, vManager, patchMap);
                          addPatchMap(vManager.CountryGlobal__c, vManager, patchMap);
                          addPatchMap(vManager.Country__c, vManager, patchMap);
                          addPatchMap(vManager.SearchCountryCode__c, vManager, patchMap);
                          addPatchMap(vManager.Zip_Code__c, vManager, patchMap);
                          addPatchMap(vManager.Account__c, vManager, patchMap); 
                          addPatchMap(vManager.County__c, vManager, patchMap);
                          addPatchMap(vManager.Lead_Source_Detail__c, vManager, patchMap);
                          addPatchMap(vManager.Lead_Source_Detail__c+'/'+vManager.CountryGlobal__c, vManager, patchMap);
                          addPatchMap(vManager.LeadSource__c, vManager, patchMap);                    
                          addPatchMap(vManager.CountryGlobal__c+'/'+vManager.Zip_Code__c,vManager,patchMap); 
                          addPatchMap(vManager.Country__c+'/'+vManager.Zip_Code__c,vManager,patchMap);
                          addPatchMap(vManager.Country__c+'/'+vManager.Zip_Code__c+'/'+vManager.City__c,vManager,patchMap);
              addPatchMap(vManager.Country__c +'/'+vManager.StateGlobal__c+'/'+vManager.Zip_Code__c+'/'+vManager.City__c, vManager, patchMap);
                          addPatchMap(vManager.Country__c +'/'+vManager.StateGlobal__c+'/'+vManager.Zip_Code__c, vManager, patchMap);
                          addPatchMap(vManager.Country__c +'/'+vManager.StateGlobal__c, vManager, patchMap);
                          addPatchMap(vManager.Country__c +'/'+vManager.City__c, vManager, patchMap);
                          // Satish
                          addPatchMap(vManager.CountryGlobal__c +'/'+vManager.StateGlobal__c+'/'+vManager.Zip_Code__c, vManager, patchMap);
                          addPatchMap(vManager.CountryGlobal__c +'/'+vManager.StateGlobal__c, vManager, patchMap);    
                      }
                      else {
                          addPatchMap(vManager.CountryGlobal__c+'/'+vManager.StateGlobal__c+'/'+vManager.Zip_Code__c+'/'+vManager.Industry_Category__c, vManager, patchMap);
                          addPatchMap(vManager.CountryGlobal__c+'/'+vManager.Zip_Code__c+'/'+vManager.Industry_Category__c, vManager, patchMap);
                          addPatchMap(vManager.CountryGlobal__c+'/'+vManager.StateGlobal__c+'/'+vManager.Industry_Category__c, vManager, patchMap);
                          addPatchMap(vManager.CountryGlobal__c+'/'+vManager.Industry_Category__c, vManager, patchMap);
                      } 
                    }
                  
              }
          }
          
          debugPatchMap(patchMap);
          
          return patchMap;
      }
      
      /**********************************************************************
         Utility Method Used by the VF page to reassign a single Deal Reg
      ***********************************************************************/
      public static void reAssignObject(List<SObject> vList, String objectType){
              Map<String, List<PatchManager__c>> patchMap;
              
              if(objectType == DEAL_REG){
                  patchMap=PatchManager.getPatchMap(vList, PatchManager.DEAL_REG);
                  for(SObject vObj: vList){
                      PatchManager.assignDealReg(patchMap, (Deal_Registration__c)vObj); 
                  }
              } else if (objectType == LEAD){
                  patchMap=PatchManager.getPatchMap(vList, PatchManager.LEAD);
                  for(SObject vObj: vList){
                      PatchManager.assignLead(patchMap, (Lead)vObj); 
                  }
              } else if (objectType == CONTACT){
                  patchMap=PatchManager.getPatchMap(vList, PatchManager.CONTACT);
                  for(SObject vObj: vList){
                      PatchManager.assignContact(patchMap, (Contact)vObj); 
                  }
              } else if(objectType == ACCOUNT){
                  patchMap=PatchManager.getPatchMap(vList, PatchManager.ACCOUNT);
                  for(SObject vObj: vList){
                      PatchManager.assignAccount(patchMap, (Account)vObj); 
                  }
              }
              
  
              update vList;
                  
      }
      
        /**********************************************************************
         Utility Method for Building the Query Map
      ***********************************************************************/
      public static void addQuery(Map<String, String> queryMap, String key, String value1){
              if(value1!= Null && !value1.contains('null')){
                  String value = String.escapeSingleQuotes(value1);
                  if(!queryMap.containsKey(key)){
                      queryMap.put(key, '\''+value+'\'');
                  } else {
                      if(!queryMap.values().contains('\''+value+'\'')){
                          queryMap.put(key, queryMap.get(key)+','+'\''+value+'\'');
                      }
                      
                  }
              }
      }
      
        /**********************************************************************
         Utility Method for building the PatchMap
      ***********************************************************************/
      public static void addPatchMap(String key, PatchManager__c vManager, Map<String, List<PatchManager__c>> patchMap){
              if(key!=null && !key.contains('null')){
                  if(!patchMap.containsKey(key)){
                      patchMap.put(key, new List<PatchManager__c>());
                  }
                  patchMap.get(key).add(vManager);
              }
              
      }
      
      /***************************
      Escapes all the charaters for the query
      ***************************/
      public static String escapeString(String vString){
              if(vString!=null){
                  
                  vString=vString.escapeJava();
                  vString=String.escapeSingleQuotes(vString);
                  vString=vString.replace('\\"', '\"');
              }           
              return vString;     
      }
      
      /***************************
      Cleans the Zipcode
      ***************************/
      public static String cleanPostalCode(String postalCode){
          String vString;
              if(postalCode!=null){               
                  vString = postalCode.trim();
                  if(vString.contains('-')){
                      String[] zipSplit = vString.split('-');
                      if(zipSplit.size()==2 && zipSplit[0].isNumeric() && zipSplit[1].isNumeric()){
                          return zipSplit[0];
                      }
                  }
              }
              
          return escapeString(postalCode);
      }
      
        /**********************************************************************
         Utility for debugging the patchMap
      ***********************************************************************/
      public static void debugPatchMap(Map<String, List<PatchManager__c>> patchMap){
              System.debug('*********************************************');
              System.debug('Total Size: '+patchMap.size());
              for(String key: patchMap.keySet()){
                  System.debug('Key: '+key+' --> '+patchMap.get(key).size());
                  for(PatchManager__c vManager: patchMap.get(key)){
                      System.debug(vManager);
                  }
                  System.debug('---------------------------------------------');
              }
              System.debug('*********************************************');
      }
  }