({
    doinit : function(component, event, helper) {
        
        var priority=component.get("v.caseRecord").Priority;
        var myEvents = $A.get('e.E2CAdv:FetchDynnamicCaseEvent');
        var today_d = new Date();
                
        var dayOfWeek=today_d.getDay();
        if(priority=='P1' || priority=='P2'){
            (dayOfWeek=='5')? today_d.setDate(today_d.getDate() + 3):today_d.setDate(today_d.getDate() + 1);   
        }
        else{ 
            if(dayOfWeek=='3' || dayOfWeek=='4' || dayOfWeek=='5'){
                today_d.setDate(today_d.getDate() + 5);
            }
            else{
                today_d.setDate(today_d.getDate() + 3);
            }
        }
        
        today_d=$A.localizationService.formatDate(today_d, "yyyy-MM-ddTHH:mm:ss.000Z");
        myEvents.setParams({
            
            CaseData:'{"NCC_date__c":"'+today_d+'"}'
        });                              
        
        myEvents.fire(); 
    },
    
    
    
})