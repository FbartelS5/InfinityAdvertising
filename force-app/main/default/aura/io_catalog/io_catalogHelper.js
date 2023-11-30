({
	launch: function(action, cb, nostore) {
        if (!nostore) action.setStorable();
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                cb(null, response.getReturnValue());
                console.log(JSON.parse(response.getReturnValue()));
            }
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
    },

    getTypePromoValues: function(component) {
        var action = component.get('c.getTypePromoValues');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var arrayTypePromo = [];
                var res = response.getReturnValue();
                for(var key in res){
                    var obj = {};
                    obj.label = key;
                    obj.value = res[key];
                    arrayTypePromo.push(obj);
                }
                component.set('v.availablePromogamingTypes',arrayTypePromo);
                console.log(component.get('v.availablePromogamingTypes'));
            }
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
    },

    getFormatValues: function(component) {
        var action = component.get('c.getFormatValues');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var arrayFormat = [];
                var res = response.getReturnValue();
                for(var key in res){
                    var obj = {};
                    obj.label = key;
                    obj.value = res[key];
                    arrayFormat.push(obj);
                }
                component.set('v.availableFormat',arrayFormat);
                console.log(component.get('v.availableFormat'));
            }
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
    },


    getStatsPromoValues: function(component) {
        var action = component.get('c.getStatsPromoValues');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var arrayStatPromo = [];
                var res = response.getReturnValue();
                for(var key in res){
                    var obj = {};
                    obj.label = key;
                    obj.value = res[key];
                    arrayStatPromo.push(obj);
                }
                component.set('v.availableStatsPromo',arrayStatPromo);
                console.log(component.get('v.availableStatsPromo'));
            }
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
    },
    getBrandNameValues: function(component) {
        var action = component.get('c.getBrandNameValues');
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                var arrayStatPromo = [];
                var res = response.getReturnValue();
                for(var key in res){
                    var obj = {};
                    obj.label = key;
                    obj.value = res[key];
                    arrayStatPromo.push(obj);
                }
                component.set('v.availableBrandName',arrayStatPromo);
                console.log(component.get('v.availableBrandName'));
            }
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
    },
    loadItems: function(component,helper,BU) {
        var catalogType = component.get('v.catalogType') || 'SalesProduct';
        var action = component.get('c.getProducts');
        
        action.setParams({BU : BU});
        helper.launch(action,function(error, result) {
            console.log('result', result);
            if (!error && Object.keys(result).length != 0) {
                if(result.SalesProduct) result.SalesProduct = result.SalesProduct.filter( p => p.packageProducts__r ).map(function(p){
                    p.packageProducts__r = p.packageProducts__r.filter( pp => pp.ParentProduct__c ).map(pp => flattenObj(pp))
                    return p;
                });
                
                component.set('v.items',result);
                if(catalogType == 'SalesProduct'){
                    if(result[catalogType]) component.set('v.availableItems',result[catalogType].map(item => (catalogType == 'SalesProduct') ? item.Name : item.Category__c).filter((value, index, self) => self.indexOf(value) === index));
                    else component.set('v.availableItems', []);
                    if(result['SalesProduct']) component.set('v.availableItems',result['SalesProduct'].map(item => item.Name).filter((value, index, self) => self.indexOf(value) === index));
                    else component.set('v.availableItems', []);
                }else{
                    component.set('v.availableItems',result.TechnicalProduct.map(item => item.Category__c).filter((value, index, self) => self.indexOf(value) === index));
                }
        
            } else if(Object.keys(result).length === 0) {
                helper.showToast('error', 'Erreur', 'Aucun produit trouvé');
                component.set('v.items',null);
                component.set('v.availableItems', []);
            } else helper.showToast('error', 'Erreur!', JSON.stringify(error));
            component.set('v.loading',false);
            console.log(component.get('v.availableItems'));
        }, true);
        function flattenObj(obj, parent, res = {}){
            for(let key in obj){
                if(typeof obj[key] == 'object'){
                    flattenObj(obj[key], key, res);
                } else {
                    res[key] = obj[key];
                }
            }
            return res;
        }
    },
    showToast : function( mType,title,message) { 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            type: mType
        });
        toastEvent.fire();
    },
    hideSpinner: function (cmp) {
        var spinner = cmp.find("spin");
        $A.util.addClass(spinner, "slds-hide");
    },
    showSpinner: function (cmp) {
        var spinner = cmp.find("spin");
        $A.util.removeClass(spinner, "slds-hide");
    },    
    checkBtn: function(component) {
        var types = component.get('v.selectedTypes');
        var mediums = component.get('v.selectedMediums');
        var targeting = component.get('v.selectedTargeting');
        var pricing = component.get('v.selectedPricing');
        var format = component.get('v.selectedFormat');
        var devices = component.get('v.selectedDevices');
        var catalogType = component.get('v.catalogType');
        var statsPromo = component.get('v.selectedStatsPromo');
        var promo = component.get('v.selectedPromogamingTypes');
        if(catalogType == 'SalesProduct') component.set('v.btnDisabled',types.length == 0 || mediums.length == 0 || targeting == '' || pricing == '' || format.length == 0, promo.length == 0)
        else component.set('v.btnDisabled',types.length == 0 || mediums.length == 0 || targeting == '' || pricing == '' || format.length == 0 || promo.length == 0)
    },
    validate: function(component) {
        component.set('v.typeWarnings','');
        component.set('v.mediumWarnings','');
        
        var category = component.get('v.activeItem');
        var types = component.get('v.selectedTypes');
        var mediums = component.get('v.selectedMediums');
        var targeting = component.get('v.selectedTargeting');
        var pricing = component.get('v.selectedPricing');
        var format = component.get('v.selectedFormat');
        var devices = component.get('v.selectedDevices');
        var catalogType = component.get('v.catalogType');
        var promo = component.get('v.selectedPromogamingTypes');

        if(category && types.length > 0 && mediums.length > 0 && format.length > 0 && targeting && pricing && promo.length > 0 && devices.length > 0) {
            
            var products = component.get('v.items')[catalogType];
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c)  && mediums.includes(value.Medium__c) && format.includes(value.Format__c) && targeting == value.Targeting__c && pricing == value.PricingModel__c && promogamingTypes == value.Type_Promogaming__c && devices.includes(value.Devices__c))
            
            matchingProducts.forEach(function(p) {
                types = types.filter(value => value != p.Type__c)
                mediums = mediums.filter(value => value != p.Medium__c)
                
            })
            console.log('matchingProducts',matchingProducts)
            console.log('warnings',types,mediums)
            
            if(mediums.length > 0 || types.length > 0) {
                component.set('v.typeWarnings',types.join(','))
                component.set('v.mediumWarnings',mediums.join(','))
            } 
        } else console.log(('too soon to validate'));
    }
    
})