({
    
    getValues : function (component,helper){
        var bodyCom = component.find('dvSpinner3');
        $A.util.removeClass(bodyCom, 'disSpiner');
        var filters = component.get("v.selectedFilter");
        var action = component.get("c.getIdeas");
        action.setParams({
            zoneId : component.get("v.commId"),
            selectedfilter : filters,
            selectedCateg : component.get("v.selectedCateg")
        });
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.allIdeas",result);
            component.set("v.pageNum",1);
            component.set("v.totalPages",Math.ceil(result.length/component.get("v.recordsPerPage")));
           
            helper.setdata(component);
          
        });
        $A.enqueueAction(action);
      
    } , 
    setdata : function(component) {
      
        var data = [];
        var pageNumber = component.get("v.pageNum");
        var pageSize = component.get("v.recordsPerPage");
        var allData = component.get("v.allIdeas");
        var x = (pageNumber-1)*pageSize;
        component.set('v.startNum',x+1);
        if(allData.length == 0){
            component.set('v.startNum',0);
        }
        
        if(pageNumber*pageSize<allData.length){
            component.set('v.endNum',pageNumber*pageSize);  
        }else{
            var extraCount = (pageNumber*pageSize)-allData.length;
            component.set('v.endNum',(pageNumber*pageSize)-extraCount);
        }
        
        for(; x<(pageNumber)*pageSize; x++){
            if(allData[x]){
                data.push(allData[x]);
            }
        }
        var bodyCom = component.find('spinner');
        $A.util.addClass(bodyCom, 'slds-hide');
        component.set("v.IdeasList", data);
    },
    categoriesPicklist : function(component){
        var action = component.get("c.getCategories");
        var url_string = window.location.href;
        var url = new URL(url_string);
        var isNew = url.searchParams.get("newIdea");
        if(isNew){
             component.set("v.ModalOpen", true);
        }
        action.setCallback(component, function(response) {
            var result = response.getReturnValue();
            component.set("v.categories",result);
              var bodyCom = component.find('dvSpinner3');
      
        });
        $A.enqueueAction(action);
        
    },
    
 
  
})