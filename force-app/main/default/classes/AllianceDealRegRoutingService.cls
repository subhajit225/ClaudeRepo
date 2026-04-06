public inherited sharing class AllianceDealRegRoutingService {
    public List<Alliance_Deal_Registration__c> routeAsPerMatchStatus(Map<String, List<Alliance_Deal_Registration__c>> statusTodealRegMap){
        List<Alliance_Deal_Registration__c> routedDealRegs = new List<Alliance_Deal_Registration__c>();
        if(!statusTodealRegMap.isEmpty()){
            List<Alliance_Deal_Registration__c> dealRegsforOpptyMatch = new List<Alliance_Deal_Registration__c>();
            if(statusTodealRegMap.containsKey('Contact Match')) {
                dealRegsforOpptyMatch.addAll(statusTodealRegMap.get('Contact Match'));
            }
            if(statusTodealRegMap.containsKey('Account Match')){
                dealRegsforOpptyMatch.addAll(statusTodealRegMap.get('Account Match'));
            }
            if(statusTodealRegMap.containsKey('Lead Match')){
                routedDealRegs.addAll(this.routeForLeadMatch(statusTodealRegMap.get('Lead Match')));
            }
            if(statusTodealRegMap.containsKey('Domain Match')) {
                dealRegsforOpptyMatch.addAll(statusTodealRegMap.get('Domain Match'));
            }
            if(statusTodealRegMap.containsKey('Net New Lead')){
                routedDealRegs.addAll(this.routeForNoMatch(statusTodealRegMap.get('Net New Lead')));
            }
            if(!dealRegsforOpptyMatch.isEmpty())
                routedDealRegs.addAll(this.routeAsPerOpportunity(dealRegsforOpptyMatch));
        }
        return routedDealRegs;
    }
    public List<Alliance_Deal_Registration__c> routeAsPerOpportunity(List<Alliance_Deal_Registration__c> dealRegistrations){
        Set<Id> accountIds = new Set<Id>();
		Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(dealRegistrations, PatchManager.ALLIANCE_DEAL_REG);
        for(Alliance_Deal_Registration__c dealReg : dealRegistrations){
            accountIds.add(dealReg.Account__c);
        }
        Map<Id,Account> accountIdToAccount = new Map<Id,Account>([SELECT Id, Account_Status__c, OwnerId,Owner.IsActive
                                                    FROM Account WHERE Id IN :accountIds]);
        List<Alliance_Deal_Registration__c> lostOrProspectOpptys = new List<Alliance_Deal_Registration__c>();
        for(Alliance_Deal_Registration__c dealReg : dealRegistrations){
            Account acc = accountIdToAccount.get(dealReg.Account__c);
            if(acc.Owner.IsActive){
                dealReg.OwnerId = acc.OwnerId;
            }else{
				if(dealReg.Alliance_Partner__c != 'Amazon'){
                   dealReg.OwnerId = dealreg.BDM__c;
				}else{
					PatchManager.assignAllianceDealReg(patchMap, dealReg);
				}
            }
        }
        return dealRegistrations;
    }
    public List<Alliance_Deal_Registration__c> routeForLeadMatch(List<Alliance_Deal_Registration__c> dealRegistrations){
        Set<Id> LeadIds = new Set<Id>();
		Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(dealRegistrations, PatchManager.ALLIANCE_DEAL_REG);
        for(Alliance_Deal_Registration__c dealReg : dealRegistrations){
            leadIds.add(dealReg.Lead__c);
        }
        Map<Id, Lead> idToleads = new Map<Id, Lead>([SELECT Id, OwnerId
                                                        FROM Lead WHERE Id IN :leadIds]);
        for(Alliance_Deal_Registration__c dealReg : dealRegistrations){
            if(dealReg.Alliance_Partner__c != 'Amazon'){
				dealReg.OwnerId = idToleads.get(dealReg.Lead__c).OwnerId.getSObjectType() == Schema.User.SObjectType ? idToleads.get(dealReg.Lead__c).OwnerId : dealReg.BDM__c;
			}else{
				PatchManager.assignAllianceDealReg(patchMap, dealReg);
			}
        }
        return dealRegistrations;
    }
    
    public List<Alliance_Deal_Registration__c> routeForNoMatch(List<Alliance_Deal_Registration__c> dealRegistrations){
        Map<String, List<PatchManager__c>> patchMap = PatchManager.getPatchMap(dealRegistrations, PatchManager.ALLIANCE_DEAL_REG);
		for(Alliance_Deal_Registration__c dealReg : dealRegistrations){
            if(dealReg.Alliance_Partner__c != 'Amazon'){
				dealReg.OwnerId = dealReg.BDM__c;
		    }else{
				PatchManager.assignAllianceDealReg(patchMap, dealReg);
			}
        }
        return dealRegistrations;
    }
}
//to deploy