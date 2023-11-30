({
    doInit : function(component, event, helper) {
        component.set('v.columns', [
            {label: 'Produit', fieldName: 'Name', type: 'text', editable: false},
            {label: 'Type', fieldName: 'Type__c', type: 'text', editable: false},
            {label: 'Support', fieldName: 'Medium__c', type: 'text', editable: false},
            {label: 'Prix Unitaire', fieldName: 'UnitPrice__c', type: 'number', editable: true, typeAttributes: { maximumFractionDigits : 6, maximumSignificantDigits : 12}},
            {label: 'Volume', fieldName: 'Volume__c', type: 'number', editable: true , typeAttributes: { maximumFractionDigits : 2, maximumSignificantDigits : 16}},
            {label: 'CA', fieldName: 'Revenue__c', type: 'currency', editable: true, typeAttributes: { currencyCode: 'EUR'}},
            {label: 'Statut', fieldName: 'Status__c', type: 'text', editable: false},
            {label: 'Date début', fieldName: 'StartDate__c', type: 'date-local', editable: true},
            {label: 'Date fin', fieldName: 'EndDate__c', type: 'date-local', editable: true},
            {label: 'Supp.', type: 'button', initialWidth: 100, typeAttributes: {  name: 'delete', iconName: 'utility:delete'}}
        ]);
        //component.set('v.data', JSON.parse(JSON.stringify(component.get('v.data'))))
    },
    handleSaveEdition : function(component, event, helper) {
        var draftValues = event.getParam('draftValues')
        console.log('draftValues',JSON.stringify(draftValues)) 
        var data = component.get('v.data');
        let res = data.reduce(function(a,b) {
            console.log(a,b)
            let a1 = draftValues.find(e => e.Id === b.Id) || {};
            console.log(Object.assign(b, a1))
            return a.concat(Object.assign(a1, b));
        },[]);
        console.log(res)
        component.set("v.data", res);
        component.set("v.draftValues", []);
    },
    handleRowAction: function (component, event, helper) {
        var i = event.getParam('row');
        var action = event.getParam('action');
        switch (action.name) {
            case 'delete':
                var data = component.get('v.data');
                data = data.filter(d => d.Id != i.Id);
                component.set("v.data", data);
                if(data.length == 0) component.find("popuplib").notifyClose();

                break;
        }
    },
    saveDuplicates: function (component, event, helper) {
        var data = component.get('v.data');
        var res = [];
        
        for(var d of data.map(function(d){delete d.Id; return d;})){
            const range = moment.range(moment.min(moment(d.StartDate__c)), moment.max(moment(d.EndDate__c)));
            const rangeIterator = range.snapTo("months").by('months');
            const rangeArr = [...rangeIterator];
            
            for (let month of rangeIterator) {
                var newFields = JSON.parse(JSON.stringify(d));
                newFields.StartDate__c = rangeArr[0].isSame(month) ? d.StartDate__c : month.startOf('month').format('YYYY-MM-DD');
                newFields.EndDate__c = rangeArr[rangeArr.length-1].isSame(month) ? d.EndDate__c : month.endOf('month').format('YYYY-MM-DD');
                res.push(newFields);
            }
        }
        
        function nullify(i, val) {
            return ( val === "" ) ? null : val;
        }
        
        
        
        var action = component.get("c.updateInsertions");  
        action.setParams({ data: JSON.stringify(res,nullify) });
        helper.launch(action,function(error, result) {
            if (!error) {
                var navEvt = $A.get("e.force:navigateToSObject");
                navEvt.setParams({
                    "recordId": component.get('v.OpportunityId')
                });
                navEvt.fire();
                component.find("popuplib").notifyClose();
            } else {
                console.log('error')
            }
        },true)
    }
})