({
    doInit : function(cmp,event){
        if(document.URL.endsWith('/s/')){
           cmp.set("v.isHome",true);
        }
        document.addEventListener('click', function(ev){
            if(ev.target.accessKey != 'mobile_menu' && ev.target.nodeName != 'LIGHTNING-ICON' && !document.getElementById("mobile_menus").classList.contains('slds-hide') && ev.target.accessKey != '123'){
                document.getElementById("mobile_menus").classList.add("slds-hide");
            }
            return;
        });
        cmp.set('v.showloader',false);
    },

    TabsVisible : function(cmp,event){
        var visibiltyTabs = cmp.get("v.UserRecord.Account.Tabs_Visibility__c");
        if(visibiltyTabs != null){
            console.log(visibiltyTabs);
            if(visibiltyTabs.includes('Training')){
                cmp.set("v.showTraining",true);
            }
            if(visibiltyTabs.includes('Forums')){
                cmp.set("v.showForums",true);
            }
        }
        cmp.set("v.showMenu",true);
    },
    Toggle1 : function(cmp,event){
        document.getElementById("mobile_menus").classList.toggle("slds-hide");
        devt.preventDefault();
    },
     gotoURL : function(cmp, event, helper) {
        helper.gotoURL(cmp);
    }
    ,
    redirect : function(cmp, event, helper) {
        if(event.getParams().keyCode == 13){
            var searchText = cmp.get("v.searchString");
            if(searchText == undefined){
                searchText = '';
            }
            window.location =$A.get("$Label.c.Community_Base_URL")+"search-results-page?searchString="+encodeURIComponent(searchText) +"&from=0&sortby=_score&orderBy=desc&pageNo=1"
        }
    },
    redirectMobile : function(cmp, event, helper) {
        window.location ="search-results-page?searchString=&from=0&sortby=_score&orderBy=desc&pageNo=1"
    }
})