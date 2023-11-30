({
    getRecordTypeName : function(component){
        var action = component.get("c.getClosingOpp");
        action.setParams({recordId:component.get('v.OpportunityId')});
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                component.set('v.RecordTypeName', response.getReturnValue());
            }else if(state === "INCOMPLETE"){
                console.log("Error : Response from Apex was incomplete");
            }else if(state === "ERROR"){
                var errors = response.getError();
                if(errors){
                    if(errors[0] && errors[0].message){
                        console.log("Error message: "+errors[0].message);
                    }
                }else{
                    console.log("Unknown error");
                }
            }
        });
        $A.enqueueAction(action);
    },
	closeModal : function(component) {
        component.find("overlayLib").notifyClose();
	}
})