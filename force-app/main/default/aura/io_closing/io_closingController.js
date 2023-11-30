({
    doInit : function(component, event, helper) { 
        window['moment-range'].extendMoment(moment);
        component.set('v.columns', [
            {label: 'Produit', fieldName: 'Name', type: 'text', editable: false, sortable:true},
            {label: 'Type', fieldName: 'Type__c', type: 'text', editable: false, sortable:true},
            {label: 'Ciblage', fieldName: 'Targeting__c', type: 'text', editable: false, sortable:true},
            {label: 'Support', fieldName: 'Medium__c', type: 'text', editable: false, sortable:true},
            {label: 'Réf. Bon de commande', fieldName: 'OrderReference__c', type: 'text', editable: false, sortable:true},
            {label: 'Campaign n°', fieldName: 'CampaignNumber__c', type: 'text', editable: false, sortable:true},
            {label: 'Device', fieldName: 'Devices__c', type: 'text', editable: false, sortable:true},
            {label: 'Mode de com', fieldName: 'PricingModel__c', type: 'text', editable: false, sortable:true}, 
            {label: 'Prix Unitaire', fieldName: 'UnitPrice__c', type: 'number', editable: true, sortable:true, typeAttributes: { maximumFractionDigits : 6, maximumSignificantDigits : 12}},
            {label: 'Volume', fieldName: 'Volume__c', type: 'number', editable: true, sortable:true , typeAttributes: { maximumFractionDigits : 2, maximumSignificantDigits : 16}},
            {label: 'CA', fieldName: 'Revenue__c', type: 'currency', editable: true, sortable:true, typeAttributes: { currencyCode: 'EUR'}},
            {label: 'Statut', fieldName: 'Status__c', type: 'text', editable: false, sortable:true},
            {label: 'Offert', fieldName: 'Free__c', type: 'boolean', editable: false, sortable:true},
            {label: 'Cloner', type: 'button', initialWidth: 100, typeAttributes: {  name: 'clone', iconName: 'utility:copy'}},
            {label: 'Supp.', type: 'button', initialWidth: 100, typeAttributes: {  name: 'delete', iconName: 'utility:delete'}}
        ]);
        
        var dates = []
        var rangeOptions = []
        var action = component.get('c.getOppInsertions');
        action.setParams({ recordId : component.get("v.recordId")})
        helper.launch(action,function(error, result) {
            
            if (!error) {
                console.log(result)
                for (const [index, p] of result.entries()){
                    dates.push(moment(p.StartDate__c));
                    dates.push(moment(p.EndDate__c));
                }
                
                const range = moment.range(moment.min(dates), moment.max(dates));
                var currentRange;
                for (let month of range.snapTo("months").by('months')) {
                    if(moment().subtract(1,'month').startOf('month').format() == month.startOf('month').format()) currentRange = month.startOf('month').format('YYYY-MM')
                    rangeOptions.push({
                        label: month.startOf('month').format('MM/YYYY'),
                        value: month.startOf('month').format('YYYY-MM'),
                        selected: moment().subtract(1,'month').startOf('month').format() == month.startOf('month').format()
                    })
                }
                if(!currentRange) currentRange = rangeOptions[0].value
                
                component.set('v.range',currentRange)
                component.set('v.options',rangeOptions)
                helper.initGrid(component,helper);
            } else helper.showToast('error', 'Error!', JSON.stringify(error));
        })
        
        var getUserProfile = component.get('c.getUserProfile');
        helper.launch(getUserProfile,function(error, result) {
            if (!error) {
                console.log('result', result);
                component.set('v.userBU', result.BU__c)
                component.set('v.userProfile',result.Profile.Name)
                component.set('v.isAdmin', result.Profile.Name.includes('Admin'))
            } else helper.showToast('error', 'Error!', JSON.stringify(error));
        })
        
    },
    rangeChange : function(component, event, helper) { 
        helper.showSpinner(component);
        helper.initGrid(component,helper);
    },
    handleSaveEdition: function (component, event, helper) {
        helper.showSpinner(component);
        component.set('v.errors',[]);
        
        function nullify(i, val) {
            return ( val === "" ) ? null : val;
        }
        
        var draftValues = event.getParam('draftValues');
        var data = component.get('v.data')
        var dataMap = {}
        for (const [i, insertion] of data.entries()){
            dataMap[insertion.Id] = insertion;
        }
        
        console.log('draftValues',JSON.stringify(draftValues))
        
        var errors = {};// new Map<String, Object>();
        var rowsError = {};// new Map<String, Object>();
        var hasErrors = false
        draftValues.forEach(function(v){
           console.log('value',v)
            var rowErrorMessages = [];
            var rowErrorFieldNames = [];
                        
            if (dataMap[v.Id].Status__c == 'OI facturée') {
                hasErrors = true
                rowsError[v.Id] = {
                    messages: ['Cette insertion est déjà facturée'],
                    fieldNames: ["Volume__c","Revenue__c"],
                    title: 'Erreur de validation'
                };
            } else if (v.Volume__c && v.Revenue__c && component.get('v.userBU') != 'ESPPUBPROG') {
                hasErrors = true
                rowsError[v.Id] = {
                    messages: ['Merci de renseigner le Volume OU le CA'],
                    fieldNames: ["Volume__c","Revenue__c"],
                    title: 'Erreur de validation'
                };
            } else if(dataMap[v.Id].PricingModel__c == 'Forfait' && v.Volume__c) {
                hasErrors = true
                rowsError[v.UID__c] = {
                    messages: ['Merci de renseigner uniquement le CA pour ce produit'],
                    fieldNames: ["Volume__c"],
                    title: 'Erreur de validation'
                };
           /* } else if(dataMap[v.Id].PricingModel__c != 'Forfait' && v.Revenue__c ) {
                hasErrors = true
                rowsError[v.Id] = {
                    messages: ['Merci de renseigner uniquement le Volume pour ce produit'],
                    fieldNames: ["Revenue__c"],
                    title: 'Erreur de validation'
                }; */
            } else if(v.UnitPrice__c ) {
                if(component.get('v.userBU') == 'ESPPUBPROG' || component.get('v.userBU') == 'ESPPUBPART') null;
                else if(dataMap[v.Id].Type__c == 'Push SMS' || dataMap[v.Id].Type__c == 'Frais technique' || dataMap[v.Id].Type__c == 'Frais technique push SMS') null;
                    else {
                        hasErrors = true
                        rowsError[v.Id] = {
                            messages: ['Vous ne pouvez pas changer le prix de cette insertion'],
                            fieldNames: ["UnitPrice__c"],
                            title: 'Erreur de validation'
                        };
                    }
                
            } 
        })

        if (hasErrors) {
            component.set('v.errors', {
                rows: rowsError,
                table: { // displayed at the end of the table
                    title : 'Erreur', // the title of the popover
                    messages : ['Veuillez vérifier les lignes en erreur'] // A list of messages to be displayed as the popover content
                }
            });
            helper.hideSpinner(component);
        } else {
            var action = component.get("c.updateInsertions");  
            action.setParams({ data: JSON.stringify(draftValues,nullify) });
            helper.launch(action,function(error, result) {
                if (!error) {
                    helper.initGrid(component,helper);
                    //$A.get('e.force:refreshView').fire();
                    component.set("v.draftValues", []);
                } else {
                    helper.hideSpinner(component);
                    helper.showToast('error', 'Error!', JSON.stringify(error));
                }
            },true)
        }
    },
    setControlled: function (component, event, helper) {
        var action = component.get("c.updateInsertions");  
        var data = component.get('v.selectedRows')

        if(data.filter( v => v.Status__c != "Signé").length > 0 ) {
            helper.showToast('error', 'Erreur!', 'Veuillez selectionner uniquement des OI/BDC Signé');
            return;
        } /*else if(data.filter( v => !v.Revenue__c).length > 0 ) {
            helper.showToast('error', 'Erreur!', 'Veuillez selectionner uniquement des OI avec du CA');
            return;
        }*/
        
        helper.showSpinner(component);
        action.setParams({  
            "data": JSON.stringify(data.map(function(i) { return { Id : i.Id, Status__c : "Signé/contrôlé"}; }))
        });      
        helper.launch(action,function(error, result) {
            if (!error) {
                helper.initGrid(component,helper);
                $A.get('e.force:refreshView').fire();
                component.set('v.selectedRows',[])
                component.find('table').set('v.selectedRows',[]);
            } else {
                helper.hideSpinner(component);
                helper.showToast('error', 'Error!', JSON.stringify(error));
            }
        },true)        
    },
    setClosed: function (component, event, helper) {
        var action = component.get("c.updateInsertions"); 
        var data = component.get('v.selectedRows')
        
        if(data.filter( v => v.Status__c != "Signé/contrôlé" && v.Status__c != "Signé").length > 0 ) {
            helper.showToast('error', 'Erreur!', 'Veuillez selectionner uniquement des OI contrôlés ou OI/BDC Signé');
            return;
        }
        
        helper.showSpinner(component);
        action.setParams({  
            "data": JSON.stringify(data.map(function(i) { return { Id : i.Id, Status__c : "Clôturé"}; }))
        });      
        helper.launch(action,function(error, result) {
            if (!error) {
                helper.initGrid(component,helper);
                $A.get('e.force:refreshView').fire();
                component.set('v.selectedRows',[])
                component.find('table').set('v.selectedRows',[]);
            } else {
                helper.hideSpinner(component);
                helper.showToast('error', 'Error!', JSON.stringify(error));
            }
        },true)
    },
    unsetClosed: function (component, event, helper) {
        var action = component.get("c.updateInsertions"); 
        var data = component.get('v.selectedRows')
        
        if(data.filter( v => v.Status__c != "Clôturé").length > 0 ) {
            helper.showToast('error', 'Erreur!', 'Veuillez selectionner uniquement des Clôturées');
            return;
        }
        
        helper.showSpinner(component);
        action.setParams({  
            "data": JSON.stringify(data.map(function(i) { return { Id : i.Id, Status__c : "Signé"}; }))
        });      
        helper.launch(action,function(error, result) {
            if (!error) {
                helper.initGrid(component,helper);
                $A.get('e.force:refreshView').fire();
                component.set('v.selectedRows',[])
                component.find('table').set('v.selectedRows',[]);
            } else {
                helper.hideSpinner(component);
                helper.showToast('error', 'Error!', JSON.stringify(error));
            }
        },true)
    },
    updateRowSelection: function (cmp,event) {
        cmp.set('v.selectedRows', event.getParam('selectedRows'));
    },
    handleRowAction: function (cmp, event, helper) {
        var i = event.getParam('row');
        var action = event.getParam('action');
        switch (action.name) {
            case 'clone':
                var cloneInsertion = $A.get("e.force:createRecord");
                cloneInsertion.setParams({ 
                    "entityApiName": "Insertion__c",
                    "defaultFieldValues": {
                        'Opportunity__c' : i.Opportunity__c,
                        'OpportunityProduct__c' : i.OpportunityProduct__c,
                        'Product__c' : i.Product__c,
                        'StartDate__c' : i.StartDate__c,
                        'EndDate__c' : i.EndDate__c,
                        'UnitPrice__c' : i.UnitPrice__c,
                        'Status__c' : 'Signé'
                    }
                });
                cloneInsertion.fire();
                break;
            case 'delete':
                if(i.canDelete__c == false) helper.showToast('error', 'Erreur!', 'Cette insertion ne peut pas être supprimée');
                else {
                    var action = cmp.get("c.deleteInsertion");  
                    action.setParams({ recordId: i.Id });
                    helper.launch(action,function(error, result) {
                        if (!error) {
                            helper.initGrid(cmp,helper);
                            $A.get('e.force:refreshView').fire();
                            cmp.set("v.draftValues", []);
                        } else {
                            helper.hideSpinner(cmp);
                            helper.showToast('error', 'Error!', JSON.stringify(error));
                        }
                    },true)
                }
                
                break;
        }
    },
    addInsertion: function (cmp, event, helper) {
        var range = cmp.get('v.range')

        $A.createComponent("c:io_closing_create_insertion", { 'OpportunityId' : cmp.get('v.recordId'),
                                                             'Status' : 'Signé',
                                                             'StartDate' : range+'-01',
                                                             'EndDate' : moment(range+'-01').endOf('month').format("YYYY-MM-DD") }, //line_ref_cdiscount
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   cmp.find('overlayLib').showCustomModal({
                                       header: "Nouvelle insertion",
                                       body: content, 
                                       showCloseButton: true,
                                       cssClass: "mymodal",
                                       
                                   })
                               }                               
                           });
                           
        /*
        var addInsertion = $A.get("e.force:createRecord");
        addInsertion.setParams({ 
            "entityApiName": "Insertion__c",
            "defaultFieldValues": {
                'Opportunity__c' : cmp.get('v.recordId'),
                'Status__c' : 'Signé',
                'StartDate__c' : range+'-01',
                'EndDate__c' : moment(range+'-01').endOf('month').format("YYYY-MM-DD"),
            }
        });
        addInsertion.fire();*/
    },
    duplicateInsertions : function(cmp, event){
        console.log('dup', cmp.get('v.selectedRows')) 
        var rows = cmp.get('v.selectedRows');
        for (var r of rows) r.Status__c = 'Signé';
        console.log(rows);
        $A.createComponent("c:io_closing_duplicate_insertion", 
                           { 'OpportunityId' : cmp.get('v.recordId'), data : rows },
                           function(content, status) {
                               if (status === "SUCCESS") {
                                   cmp.find('overlayLib').showCustomModal({
                                       header: "Dupliquer des insertions",
                                       body: content, 
                                       showCloseButton: true,
                                       cssClass: cmp.getName() + " duplicateModal",
                                   })
                               }                               
                           });
    },
    search: function (component, event, helper) {
        helper.search(component, helper)
    },
    
    updateColumnSorting: function(component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
});