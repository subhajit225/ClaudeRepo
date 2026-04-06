({
	identifyObject : function(component) {
		let recordId = component.get("v.recordId");
        let sourceObject = '';
        if(recordId.startsWith("001")){
            sourceObject = 'Account';
        }
        else if(recordId.startsWith('a0E')){
            sourceObject = 'Cluster__c';
        }
        else if(recordId.startsWith('500')){
            sourceObject = 'Case';
        }
        component.set("v.sourceObject", sourceObject);
	},

    retrieveInsightMatchesWrapper : function(component) {
        var action = component.get("c.getInsightMatchesWrapper");
        console.log(component.get("v.recordId"));
        let sourceObject = component.get("v.sourceObject");

        action.setParams({
            'recordId': component.get("v.recordId"),
            'sourceObject' : sourceObject
        });

        action.setCallback(this,function(result){
            let insightMatchesWrapper = result.getReturnValue();
            if(insightMatchesWrapper != null){
                component.set("v.insightMatchesWrapper", insightMatchesWrapper);
                let insightMatchesList = insightMatchesWrapper.insightMatchesList;

                if(insightMatchesList != null && insightMatchesList.length > 0) {
                    if(sourceObject == 'Account' || sourceObject == 'Cluster__c'){
                        this.generateStatusIconURL(component, insightMatchesList);
                        this.sortInsightMatchesBySeverityList(component, component.get("v.insightMatchesList"));
                    }
                    else if(sourceObject == 'Case'){
                        this.generateObjectIconURL(component, insightMatchesList);
                        this.sortInsightMatchesByObjectList(component, insightMatchesList);
                        this.generateSeverityMap(component, insightMatchesList);
                        this.generateStatusIconURL(component, component.get("v.insightMatchSeverityWiseList"));
                    }

                    component.set("v.showInsightMatchesSection", true);
                }
            }

            component.set("v.showSpinner", false);

        });
        $A.enqueueAction(action);
    },

    generateStatusIconURL : function(component, insightMatchesList) {
        for(let i = 0; i < insightMatchesList.length; i++){
            if(insightMatchesList[i].severity == 'Info'){
                console.log('inside info');
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Status_Icon_Info.svg';
                insightMatchesList[i].sortOrder = 4;
            }
            else if(insightMatchesList[i].severity == 'Minor'){
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Status_Icon_Minor.svg';
                insightMatchesList[i].sortOrder = 3;
            }
            else if(insightMatchesList[i].severity == 'Major'){
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Status_Icon_Major.svg';
                insightMatchesList[i].sortOrder = 2;
            }
            else if(insightMatchesList[i].severity == 'Critical'){
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Status_Icon_Critical.svg';
                insightMatchesList[i].sortOrder = 1;
            }
            if(insightMatchesList[i].severity == ""){
                console.log('inside info');
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Status_Icon_Info.svg';
                insightMatchesList[i].severity = "Info";
                insightMatchesList[i].sortOrder = 4;
            }
        }
        component.set("v.insightMatchesList", insightMatchesList);
    },

    sortInsightMatchesBySeverityList : function(component, insightMatchesList){
    	insightMatchesList.sort((a, b) => a.sortOrder - b.sortOrder);
        component.set("v.insightMatchesList", insightMatchesList);
    },

    sortInsightMatchesByObjectList : function(component, insightMatchesList){
    	insightMatchesList.sort((a, b) => (a.match_level > b.match_level) ? 1 : ((b.match_level > a.match_level) ? -1 : 0));
        component.set("v.insightMatchesList", insightMatchesList);
    },

    generateObjectIconURL : function(component, insightMatchesList) {
        for(let i = 0; i < insightMatchesList.length; i++){
            if(insightMatchesList[i].match_level.toUpperCase() == 'CLUSTER_UUID'){
                console.log('inside info');
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Object_Icon_Cluster.png';
            }
            else if(insightMatchesList[i].match_level.toUpperCase() == 'ACCOUNT_ID'){
                insightMatchesList[i].iconURL = $A.get('$Resource.Insight_Matches_Status_Icons') + '/InsightMatchesStatusIcons/Object_Icon_Account.png';
            }
        }
        component.set("v.insightMatchesList", insightMatchesList);
    },

    generateSeverityMap : function(component, insightMatchesList){
        let severityList = component.get("v.severityList");
        let currentSeverity;
        let insightMatchSeverityWiseList = [], insightMatchesSeverityList = [];
        for(var i = 0; i < severityList.length; i++){
            currentSeverity = severityList[i];
            insightMatchSeverityWiseList = [];
            for(var j = 0; j < insightMatchesList.length; j++){
                if((currentSeverity.toUpperCase() == (insightMatchesList[j].severity).toUpperCase()) || (currentSeverity.toUpperCase() == 'INFO' && (insightMatchesList[j].severity == ""))){
                    insightMatchSeverityWiseList.push(insightMatchesList[j]);
                }
            }

            if(insightMatchSeverityWiseList.length > 0) {
                insightMatchesSeverityList.push({
                    severity : currentSeverity,
                    count : insightMatchSeverityWiseList.length,
                    insightMatches : insightMatchSeverityWiseList,
                    downArrowId : currentSeverity + 'DownArrow',
                    rightArrowId : currentSeverity + 'RightArrow',
                    section : currentSeverity + 'Section'
                });
            }
        }

        component.set("v.insightMatchSeverityWiseList", insightMatchesSeverityList);
    }
})