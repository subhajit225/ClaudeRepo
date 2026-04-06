({
    gotoURL : function (cmp) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": "my-cases"
       });
        urlEvent.fire();
    }
})