({
    fetchData : function(component, filter) {
        var action = component.get("c.getPostsData");
        action.setParams({
            'filter' : filter
        });
        action.setCallback(this, function (response) {
            if(filter == 'MostPopular'){
                component.set("v.popularPosts", response.getReturnValue().feedWrap);
                }
            else if(filter == 'MostReplied'){
                component.set("v.mostRepliedPosts", response.getReturnValue().feedWrap);
            }
            else if(filter == 'Recent'){
                component.set("v.recentPosts", response.getReturnValue().feedWrap);
        }

            this.sortData(component, response.getReturnValue().feedWrap);
        });
        $A.enqueueAction(action);
    },

	sortData: function(component, data) {
        console.log('inside sortData');
        component.set("v.totalPages", Math.ceil(data.length / component.get("v.pageSize")));
        var i = 1;
        var arrayList = [];
        while(i <= component.get("v.totalPages")){
            arrayList.push(i);
            i++;
        }

        component.set("v.totalPagesList",arrayList);
        component.set("v.currentPageNumber",1);
        component.set("v.userRecord", data);

        this.buildData(component);
    },

    buildData : function(component) {
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.userRecord");
        var x = (pageNumber-1)*pageSize;

        //creating data-table data
        for(; x<(pageNumber)*pageSize; x++){
            if(allData[x]){
            	data.push(allData[x]);
            }
        }
        component.set("v.userRecordPaged", data);
        component.set("v.showSpinner", false);
    },

    fetchOrPrepareData : function(component, data, filter){
        if(data == null || data.length < 1){
            this.fetchData(component, filter);
            }
        else{
            this.sortData(component, data);
    }
    },
})