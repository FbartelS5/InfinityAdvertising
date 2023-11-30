({
    doInit : function(component,event,helper) {
        helper.getRecordTypeName(component);
    },
    handleSubmit : function(component,event,helper) {
        window['moment-range'].extendMoment(moment);

        event.preventDefault();
        var fields = event.getParam('fields');
        
        const range = moment.range(moment.min(moment(fields.StartDate__c)), moment.max(moment(fields.EndDate__c)));
        const rangeIterator = range.snapTo("months").by('months');
        const rangeArr = [...rangeIterator];
        
        for (let month of rangeIterator) {
            var newFields = JSON.parse(JSON.stringify(fields));
            newFields.StartDate__c = rangeArr[0].isSame(month) ? fields.StartDate__c : month.startOf('month').format('YYYY-MM-DD');
            newFields.EndDate__c = rangeArr[rangeArr.length-1].isSame(month) ? fields.EndDate__c : month.endOf('month').format('YYYY-MM-DD');
            component.find("editForm").submit(newFields);
        }
    },
    handleSuccessMessage : function(component,event,helper) {
         component.find('notifLib').showToast({
            "variant": "success",
            "title": "Insertion créée",
            "message": "Votre insertion a bien été créé"
        });
        
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": component.get('v.OpportunityId') });
        navEvt.fire();
    },
    closeModal : function(component,event,helper) {
        var navEvt = $A.get("e.force:navigateToSObject");
        navEvt.setParams({ "recordId": component.get('v.OpportunityId') });
        navEvt.fire();
    }
})