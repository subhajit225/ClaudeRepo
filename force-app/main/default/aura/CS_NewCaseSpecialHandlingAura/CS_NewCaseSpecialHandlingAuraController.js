({
    onPageReferenceChange: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var state = myPageRef.state;
        var context = state.inContextOfRef;
        if (context.startsWith("1\.")) {
            context = context.substring(2);
            var addressableContext = JSON.parse(window.atob(context));
            var data = JSON.stringify(addressableContext);
            cmp.set('v.redirectedFromDetails', data);
        }
    }
})