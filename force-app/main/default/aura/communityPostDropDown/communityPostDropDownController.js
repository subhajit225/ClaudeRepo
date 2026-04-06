({
    doInit: function(cmp, event, helper) {
        var action = cmp.get("c.feedItemOwnerId");
        action.setParams({
            'postId': cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            if (response.getState() == 'SUCCESS') {
                cmp.set("v.ownerId", response.getReturnValue().ownerId);
                cmp.set("v.currentUserId", $A.get("$SObjectType.CurrentUser.Id"));
                cmp.set("v.notContainComments", response.getReturnValue().containComments);
                cmp.set("v.isModerator", response.getReturnValue().isModerator);
                cmp.set("v.flagged", response.getReturnValue().flagged);
                cmp.set("v.isDeleted", response.getReturnValue().isDeleted);
            }
        });
        $A.enqueueAction(action);
    },
    handleDelete: function(cmp, event, helper) {
        var action = cmp.get("c.deletePost");
        action.setParams({
            'postId': cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            window.history.go(-1);
        });
        $A.enqueueAction(action);

    },
    handleFlag: function(cmp, event, helper) {
        var action = cmp.get("c.flagPost");
        action.setParams({
            'feedItemId': cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            location.reload();
        });
        $A.enqueueAction(action);
},
    handleUnflag: function(cmp, event, helper) {
        var action = cmp.get("c.unflagPost");
        action.setParams({
            'feedItemId': cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            location.reload();
        });
        $A.enqueueAction(action);
    }
})