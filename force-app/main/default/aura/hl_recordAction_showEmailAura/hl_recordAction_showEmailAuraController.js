({
    doInit : function(component, event, helper) {

        let action = component.get("c.getEmailMessageBody");
        action.setParams({"recordId": component.get("v.recordId")});
        action.setCallback(this, function(response) {
            let state = response.getState();
            if(state === "SUCCESS") {
                component.set("v.messageContent", response.getReturnValue());
            } else {
                console.error('Problem getting account, response state: ' + state);
            }
        });
        $A.enqueueAction(action);
    },

    handleClose: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})