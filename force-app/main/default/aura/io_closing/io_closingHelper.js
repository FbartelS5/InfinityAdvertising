({
    launch: function(action, cb, nostore) {
        //if (!nostore) action.setStorable();
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") cb(null, response.getReturnValue())
            else if (state === "ERROR") {
                var errors = response.getError();
                console.log('error->'+JSON.stringify(errors))
                if (errors) {
                    if (errors[0] && errors[0].message) cb(errors[0].message)
                    else cb(errors);
                }
            }
        });
        $A.enqueueAction(action);
    },
    initGrid: function(component,helper) {                 
        var action = component.get('c.getOppInsertions');
        action.setParams({ recordId : component.get("v.recordId")})
        helper.launch(action,function(error, result) {
            if (!error) {
                var data = result.filter( i => i.StartDate__c.substring(0,7) == component.get('v.range') ).map(i => flattenObj(i))
                var filters = {}
                filters.product = data.map(value => value.Name ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterProduct").get("v.value") == value }}).sort()
                filters.type = data.map(value => value.Type__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterType").get("v.value") == value }}).sort()
                filters.targeting = data.map(value => value.Targeting__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterTargeting").get("v.value") == value  }}).sort()
                filters.medium = data.map(value => value.Medium__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterMedium").get("v.value") == value  }}).sort()
                filters.devices = data.map(value => value.Devices__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterDevices").get("v.value") == value  }}).sort()
                filters.pricing = data.map(value => value.PricingModel__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterPricing").get("v.value") == value  }}).sort()
                filters.promo = data.map(value => value.Type_Promogaming__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterPromo").get("v.value") == value  }}).sort()
                filters.status = data.map(value => value.Status__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterStatus").get("v.value") == value  }}).sort()
                filters.order = data.map(value => value.OrderReference__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterOrder").get("v.value") == value  }}).sort()
                filters.campaign = data.map(value => value.CampaignNumber__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected": component.find("filterCampaign").get("v.value") == value  }}).sort()

                const total = data
                .filter(item => item.Revenue__c )
                .map(item => item.Revenue__c)
                .reduce((prev, curr) => prev + curr, 0);
                
                console.log(filters);
                
                component.set('v.filters',filters)
                component.set('v.total',total)
                component.set('v.data',data)
                component.set('v.allData',data)
                
                
                
                helper.search(component, helper)
                
                
            } else helper.showToast('error', 'Error!', JSON.stringify(error));
            helper.hideSpinner(component);
        }, true);
        
        function flattenObj(obj, parent, res = {}){
            for(let key in obj){
                if(key == 'Id' && parent) continue;
                if(key == 'UnitPrice__c' && parent) continue;
                if(typeof obj[key] == 'object'){
                    flattenObj(obj[key], key, res);
                } else {
                    res[key] = obj[key];
                }
            }
            return res;
        }
    },
    search: function(component, helper) {
        var data = component.get('v.allData');
        var filterProduct = component.find("filterProduct").get("v.value");
        var filterType = component.find("filterType").get("v.value");
        var filterMedium = component.find("filterMedium").get("v.value");
        var filterTargeting = component.find("filterTargeting").get("v.value");
        var filterPricing = component.find("filterPricing").get("v.value");
        var filterPromo = component.find("filterPromo").get("v.value");
        var filterDevices = component.find("filterDevices").get("v.value");
        var filterStatus = component.find("filterStatus").get("v.value");
        var filterOrder = component.find("filterOrder").get("v.value");
        var filterCampaign = component.find("filterCampaign").get("v.value");
    
        var tables = data.slice(0)
        var result = tables.filter(function(p) {
            var filterProductActive = true;
            if(filterProduct) filterProductActive = filterProduct == p.Name;
            
            var filterTypeActive = true;
            if(filterType) filterTypeActive = filterType == p.Type__c;
            
            var filterMediumActive = true;
            if(filterMedium) filterMediumActive = filterMedium == p.Medium__c;
            
            var filterTargetingActive = true;
            if(filterTargeting) filterTargetingActive = filterTargeting == p.Targeting__c;
            
            var filterPricingActive = true;
            if(filterPricing) filterPricingActive = filterPricing == p.PricingModel__c;
          
            var filterPromoActive = true;
            if(filterPromo) filterPromoActive = filterPromo == p.Type_Promogaming__c;
            
            var filterDevicesActive = true;
            if(filterDevices) filterDevicesActive = filterDevices == p.Devices__c;
            
            var filterStatusActive = true; 
            if(filterStatus) filterStatusActive = filterStatus == p.Status__c;
            
            var filterOrderActive = true; 
            if(filterOrder) filterOrderActive = filterOrder == p.OrderReference__c;
            
            var filterCampaignActive = true; 
            if(filterCampaign) filterCampaignActive = filterCampaign == p.CampaignNumber__c;
          
            return filterProductActive && filterTypeActive && filterMediumActive && filterTargetingActive && filterPricingActive &&  filterDevicesActive && filterStatusActive && filterOrderActive && filterCampaignActive && filterPromoActive;
        });
      
        const total = result
        .filter(item => item.Revenue__c )
        .map(item => item.Revenue__c)
        .reduce((prev, curr) => prev + curr, 0);
        component.set('v.data', result);
        component.set('v.total', total);
        
    },
    sortData: function (component, fieldName, sortDirection) {
        var data = component.get("v.data");
         //function to return the value stored in the field
        var key = function(a) { return a[fieldName]; }
        var reverse = sortDirection == 'asc' ? 1: -1;
        
        // to handel number/currency type fields 
        if(fieldName == 'Volume__c' || fieldName == 'UnitPrice__c' || fieldName == 'Revenue__c' || fieldName == 'Free__c'){ 
            data.sort(function(a,b){
                var a = key(a) ? key(a) : '';
                var b = key(b) ? key(b) : '';
                return reverse * ((a>b) - (b>a));
            }); 
        }
        else{// to handel text type fields 
            data.sort(function(a,b){ 
                var a = key(a) ? key(a).toLowerCase() : '';//To handle null values , uppercase records during sorting
                var b = key(b) ? key(b).toLowerCase() : '';
                return reverse * ((a>b) - (b>a));
            });    
        }
        //set sorted data to accountData attribute
        component.set("v.data", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ? function(x) { return primer(x[field]); } : function(x) { return x[field];  };

        return function (a, b) {
            var A = key(a);
            var B = key(b);
            return reverse * ((A > B) - (B > A));
        };
    },
    hideSpinner: function (cmp) {
        var spinner = cmp.find("spin");
        $A.util.addClass(spinner, "slds-hide");
    },
    showSpinner: function (cmp) {
        var spinner = cmp.find("spin");
        $A.util.removeClass(spinner, "slds-hide");
    },
    showToast : function( mType,title,message) { 
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : title,
            message: message,
            type: mType,
            mode: "sticky"
        });
        toastEvent.fire();
    }
})