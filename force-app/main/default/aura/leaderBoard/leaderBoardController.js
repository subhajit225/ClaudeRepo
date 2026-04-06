({
    doInit : function(component, event, helper){
       component.set("v.showSpinner", true);
       component.set("v.userRecordPaged",[]);
        let params = window.location.search;
        params = params.replace('?','');
        params = params.split('&');
        let parammap = new Object();

        for(var i = 0; i < params.length; i++){
            var data = params[i].split('=');
            parammap[data[0]] = data[1];
        }

        let type = parammap["type"];
        let filter = parammap["filter"];
        component.set("v.selectedTab", type);
        component.set("v.selectedFilter", filter);

        if(filter != 'LeaderBoard'){
            helper.fetchData(component, filter);
        }
        else{
            component.set("v.showSpinner", false);
        }
    },

    onNext : function(component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber+1);
        helper.buildData(component, helper);
    },

    onPrev : function(component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber-1);
        helper.buildData(component, helper);
    },

    processMe : function(component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        console.log(component.get("v.currentPageNumber"));
        helper.buildData(component, helper);
    },

    onFirst : function(component, event, helper) {
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },

    onLast : function(component, event, helper) {
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    },

    changeFilter : function(component, event, helper){
        var filter = event.target.id;
        component.set("v.selectedFilter", filter);
        component.set("v.showSpinner", true);

        if (filter && filter != 'LeaderBoard') {
            if(filter == 'MostPopular'){
                helper.fetchOrPrepareData(component, component.get("v.popularPosts"), filter);
            }
            else if(filter == 'MostReplied'){
                helper.fetchOrPrepareData(component, component.get("v.mostRepliedPosts"), filter);
            }
            else if(filter == 'Recent'){
                helper.fetchOrPrepareData(component, component.get("v.recentPosts"), filter);
            }
        } else {
            window.setTimeout(() => {
                component.set("v.showSpinner", false);
            }, 500);
        }
    },
})