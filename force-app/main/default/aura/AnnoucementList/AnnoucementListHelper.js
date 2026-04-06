({
    getannouncements : function(component ) {
        console.log('main');
        var categ =   component.get("v.clickedCateg");

        var pageNum = component.get("v.pageNum");
        var pageSize = component.get("v.pageSize");
        let isForums = component.get("v.isForums");

        var action = component.get("c.getPortalNews");
        action.setParams({
            pageNumber: pageNum,
            pageSize: pageSize,
            type : categ,
            isForums : isForums
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            var result=response.getReturnValue();
            if(result!=null && result!=undefined){
                console.log('aaaaccc ',result);
                component.set("v.newsList", result.announcement);
                component.set("v.TypeOptions",result.TypeOptions);
                component.set("v.totalResults",result.totalcount);
                component.set("v.pageNum",pageNum);
            }else{
                component.set("v.totalResults",0);
                component.set("v.newsList", []);

            }
        });
        $A.enqueueAction(action);
    },

    pageFunc: function(component,event,helper){
        console.log('__________',event);
        var currentPage =  parseInt(component.get("v.pageNum")) - 1;
        component.set("v.pageNum",currentPage);
        helper.getannouncements(component);
    },

    nextPageFunc : function(component,event,helper){
        var currentPage =  parseInt(component.get("v.pageNum")) + 1;
        component.set("v.pageNum",currentPage);
        helper.getannouncements(component);
    }
})