({
    doInit: function(component, event, helper) {
        // Assume file size in bytes comes from some source
        var fileSizeBytes = component.get("v.fileSizeBytes");
        var fileSizeMB = helper.convertBytesToMB(fileSizeBytes);
        component.set("v.fileSizeMB", fileSizeMB);
    }
})