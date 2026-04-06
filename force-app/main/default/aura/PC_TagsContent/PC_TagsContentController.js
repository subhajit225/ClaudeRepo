({
    doInit : function(component, event, helper) {
        
        var tag = component.get("v.tag");
       // alert('tag--->'+tag);
        var tagSplits = tag.split(',');
         //alert('tagSplits--->'+tagSplits);
        var  tags = [];
        for(var i =0; i < tagSplits.length;  i++){
            tags.push(tagSplits[i]);
        }
        //alert('tags--->'+tags);
        component.set("v.tags",tags);
        component.set("v.selectedTag",component.get("v.defaultTag"));
        helper.loadData(component, event, helper);
    },
    handleClick : function(component, event, helper) {
        var selectedTag = event.getSource().get('v.name');
        component.set("v.selectedTag",selectedTag);
       // alert(selectedTag);
        helper.loadData(component, event, helper);
    },
    PreviewContent:function(component, event, helper) {
        var url= "/" + component.get("v.url"); 
        helper.gotoURL(component,event,url);//Called helperCmp method
    }
})