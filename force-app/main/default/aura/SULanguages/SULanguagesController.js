({
    doInit :  function(component, event,helper){
      
        var p = component.get("v.parent");
        component.set("v.child",p.translateText(component.get('v.child')))
       
}
})