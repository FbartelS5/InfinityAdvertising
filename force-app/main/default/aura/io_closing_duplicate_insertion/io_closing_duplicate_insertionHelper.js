({
	launch: function(action, cb, nostore) {
        //if (!nostore) action.setStorable();
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") cb(null, response.getReturnValue())
            else if (state === "ERROR") {
                var errors = response.getError();
                console.log(JSON.stringify(errors))
                if (errors) {
                    if (errors[0] && errors[0].message) cb(errors[0].message)
                    else cb(errors);
                }
            }
        });
        $A.enqueueAction(action);
    }
})