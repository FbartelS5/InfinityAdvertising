({
	doInit : function(component, event, helper) {
        helper.getStatsPromoValues(component);
        helper.getBrandNameValues(component);
        //helper.getPromogamingTypesValues(component);
        component.set('v.loading',true)
        console.log(component.get('v.recordId'))
		var initFilters = component.get('c.getFilters');
        helper.launch(initFilters,function(error, result) {
            if (!error) {
                console.log(JSON.parse(result));
                var filters = JSON.parse(result)
                var bu = '';
                component.set('v.filters', filters);
                filters.BU__c.forEach(function(f){
                    if(f.selected == 'true') bu = f.value
                })
                
                if(bu != '') {
                    helper.loadItems(component, helper, bu);
                    component.find("filterBU").set("v.value",bu);
                    component.set("v.BU",bu);
                } else{
                    component.set('v.loading',false);
                }
                
                console.log(component.get('v.availableItems'));
                
                
            } else helper.showToast('error', 'Error!', JSON.stringify(error));
        }, true);
	},
    
    buChange: function (component, event, helper) {
        var bu = component.find("filterBU").get("v.value")
        if(bu == '') {
            component.set('v.items',[]);
            component.set('v.availableItems',[])
        } else {
            component.set('v.loading',true)
            component.set('v.activeItem', 'hidden');
            component.set("v.BU", bu);
            helper.loadItems(component, helper,bu);
        }
    },
    
    closeSection: function (component, event, helper) {
        component.set('v.activeItem', 'hidden');
    },
    
    handleSectionToggle: function (component, event, helper) {
        if(component.get('v.loading') == true) return;
        var activeItem = event.getParam('openSections')[0];
        var catalogType = component.get('v.catalogType');
        console.log(catalogType);
        console.log('activeItem',activeItem);
        if(activeItem && activeItem != "hidden") {
            component.set('v.isPromogaming', false);
            component.set('v.isRetail', false);
            //component.set('v.isRetailMediaOnsite', true);

            helper.showSpinner(component);
            component.set('v.btnDisabled',true)
            component.set("v.availableTypes" ,[]);
            component.set("v.availableMediums" ,[]);
            component.set("v.availableDevices" ,[]);
            component.set("v.availableTargeting" ,[]);
            component.set("v.availablePricing" ,[]);
            component.set("v.availableFormat" ,[]);
            console.log('testFormat',component.set("v.availableFormat"));
            //component.set("v.availablePromogamingTypes",[]);
            component.set("v.availableRetailMediaOnsiteTypes",[]);
            
            component.set("v.selectedTypes" ,[]);
            component.set("v.selectedMediums" ,[]);
            component.set("v.selectedDevices" ,[]);
            component.set("v.selectedTargeting" ,"");
            component.set("v.selectedPricing" ,"");
            component.set("v.selectedFormat" ,"");
            component.set("v.selectedEAN" ,"");
            component.set("v.selectedAmountExclTaxes" ,"");
            component.set("v.selectedStatsPromo" ,"");
            component.set("v.selectedOffert" ,false);
            component.set("v.selectedBrandName" ,"");
            component.set("v.selectedFrameworkAgreement" ,"");
            component.set("v.selectedPromogamingTypes",[]);
            component.set("v.selectedRetailMediaOnsiteTypes",[]);

            var products = component.get('v.items')[catalogType];
            console.log('testProducts', products);
            console.log(component.get("v.availableStatsPromo"));
            var matchingProducts = (catalogType == 'SalesProduct') ? products.filter(value => value.Name == activeItem)[0].packageProducts__r : products.filter(value => value.Category__c == activeItem)
            console.log('testMatchingPrdoucts', matchingProducts);
            var types = matchingProducts.map(value => value.Type__c ).filter((value, index, self) => self.indexOf(value) === index)
            component.set('v.availableTypes',types.map( function(value){ return { "label": value, "value": value }; }).sort());
            if(catalogType == 'SalesProduct') {
                component.set('v.selectedTypes',types);
                console.log('activeItem', activeItem)
                if(activeItem.includes('Promogaming')){
                    component.set('v.isPromogaming', true);
                    if(activeItem.includes('Mono')){
                        let data = ['Temps fort industriel','Search','Always on','Pimp your promo','Ultra personnalisé'];
                        component.set("v.availablePromogamingTypes" ,data.map( function(value){ return { "label": value, "value": value }; }).sort());
                        component.set('v.selectedPromogamingTypes',data);
                    }else if(activeItem.includes('Multi')){
                        let data1 = ['Temps fort multimarque', 'Premier panier'];
                        component.set("v.availablePromogamingTypes" ,data1.map( function(value){ return { "label": value, "value": value }; }).sort());
                        component.set('v.selectedPromogamingTypes',data1);
                    }
                }

                var mediums = matchingProducts.map(value => value.Medium__c ).filter((value, index, self) => self.indexOf(value) === index);
                component.set('v.availableMediums',mediums.map( function(value){ return { "label": value, "value": value }; }).sort());
                component.set('v.selectedMediums',mediums);
                
                var availableTargeting = matchingProducts.map(value => value.Targeting__c ).filter((value, index, self) => self.indexOf(value) === index);
                if(availableTargeting.length == 1) component.set('v.selectedTargeting',availableTargeting[0]);
                component.set('v.availableTargeting', availableTargeting.map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedTargeting') == value) ? true : false}; }).sort());
                
                var availablePricing = matchingProducts.map(value => value.PricingModel__c ).filter((value, index, self) => self.indexOf(value) === index);
                if(availablePricing.length == 1) component.set('v.selectedPricing',availablePricing[0]);
                component.set('v.availablePricing', availablePricing.map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedPricing') == value) ? true : false}; }).sort());
   

                if(activeItem.includes('Retail')){
                    component.set('v.isRetail', true);
                    console.log('matchingProducts', matchingProducts);

                    var format = component.get('v.filters').Format__c.map(f => {
                        return { "label": f.label, "value": f.value, "selected" :f.selected}
                        
                    })
                    //var format = matchingProducts.map(value => value.Format__c ).filter((value, index, self) => self.indexOf(value) === index);
                    // console.log('format', format);
                     //component.set('v.availableFormat', format.map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedFormat') == value) ? true : false}; }).sort());
                    component.set('v.availableFormat',format);
                    component.set('v.selectedFormat',format);

                }

                var availableDevices = matchingProducts.map(value => value.Devices__c ).filter((value, index, self) => self.indexOf(value) === index);
                if(availableDevices.length == 1) component.set('v.selectedDevices',availableDevices);
                component.set('v.availableDevices', availableDevices.map( function(value){ return { "label": value, "value": value}; }).sort());
                
                helper.checkBtn(component);
                component.set('v.availableDiscount', products.filter(value => value.Name == activeItem)[0].Discount__c);
            }else{
                component.set('v.availableDiscount', products.filter(value => value.Category__c == activeItem)[0].Discount__c);
            }
            var opp = component.get('v.oppRecord')
            component.set('v.startDate',opp.CampaignStartDate__c);
            component.set('v.endDate',opp.CampaignEndDate__c);
            console.log(component.get('v.startDate'));
            console.log(component.get('v.endDate'));
        }
    },
    handleStatsPromoSelected: function (component, event, helper) {
        var selected = event.getParam("value");
        console.log("handleStatsPromoSelected",selected)
        helper.checkBtn(component);
        var catalogType = component.get('v.catalogType');
        if(selected.length > 0) {
            var catalogType = component.get('v.catalogType');
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            console.log(products);
            var matchingProducts = products.filter(value => value.Category__c == category && selected.includes(value.Type__c) )
            
            component.set('v.availableStatsPromo',matchingProducts.map(value => (value.StatsPromoUnit__c) ? value.StatsPromoUnit__c : "").filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedStatsPromo') == value) ? true : false}; }).sort());
            helper.validate(component);
            console.log(JSON.parse(JSON.stringify(component.get('v.availableStatsPromo'))));
        } else component.set('v.availableStatsPromo',[]);
    },
    
    handleBrandNameSelected: function (component, event, helper) {
        var selected = event.getParam("value");
        console.log("handleBrandNameSelected",selected)
        helper.checkBtn(component);
        var catalogType = component.get('v.catalogType');
        if(selected.length > 0) {
            var catalogType = component.get('v.catalogType');
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            console.log(products);
            var matchingProducts = products.filter(value => value.Category__c == category && selected.includes(value.Type__c) )
            
            component.set('v.availableBrandName',matchingProducts.map(value => (value.BrandName__c) ? value.BrandName__c : "").filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedBrandName') == value) ? true : false}; }).sort());
            helper.validate(component);
            console.log(JSON.parse(JSON.stringify(component.get('v.availableBrandName'))));
        } else component.set('v.availableBrandName',[]);
    },
    
    handleTypeSelected: function (component, event, helper) {
        var selected = event.getParam("value");       
        
        console.log("handleTypeSelected",selected)
        helper.checkBtn(component);
        
        if(selected.length > 0) {
            var catalogType = component.get('v.catalogType');
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            
            var matchingProducts = products.filter(value => value.Category__c == category && selected.includes(value.Type__c) )
            
            component.set('v.availableMediums',matchingProducts.map(value => value.Medium__c ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value }; }).sort());
            helper.validate(component);
        } else component.set('v.availableMediums',[])
    },
    
    handleMediumSelected: function (component, event, helper) {
        var selected = event.getParam("value");
        console.log("handleMediumSelected",selected)
        console.log(component.get('v.selectedMediums'));
        helper.checkBtn(component);
        
        if(selected.length > 0) {
            var catalogType = component.get('v.catalogType');
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            var types = component.get('v.selectedTypes');
            
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c)  && selected.includes(value.Medium__c) )
            
            component.set('v.availableTargeting',matchingProducts.map(value => (value.Targeting__c) ? value.Targeting__c : "" ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedTargeting') == value) ? true : false}; }).sort());
            helper.validate(component);
        } else component.set('v.availableTargeting',[])
    },

    handleFormatSelected: function (component, event, helper) {
        var selected = component.get('v.selectedFormat');
        console.log("handleFormatSelected",selected);
        console.log(component.get('v.selectedFormat'));
        helper.checkBtn(component);
        
        var catalogType = component.get('v.catalogType');
        if(catalogType == 'SalesProduct') return;
        
        if(selected != 'none') {
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            var types = component.get('v.selectedTypes');
            //var targeting = component.get('v.selectedTargeting');
            var pricing = component.get('v.selectedPricing');
            var mediums = component.get('v.selectedMediums');
            
            
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c)  && mediums.includes(value.Medium__c) && pricing.includes(value.PricingModel__c) && selected == value.Format__c)
            component.set('v.availableFormat',matchingProducts.map(value => (value.Format__c) ? value.Format__c : "" ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value,"selected" : (component.get('v.selectedFormat') == value) ? true : false}; }).sort());
            helper.validate(component);
        } else component.set('v.availableFormat',[])
    },

    handleTargetingSelected: function (component, event, helper) {
        var selected = component.get('v.selectedTargeting');
        console.log("handleTargetingSelected",selected)
        helper.checkBtn(component);
        
        var catalogType = component.get('v.catalogType');
        if(catalogType == 'SalesProduct') return;
        
        if(selected != 'none') {
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            var types = component.get('v.selectedTypes');
            var mediums = component.get('v.selectedMediums');
            
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c)  && mediums.includes(value.Medium__c)  && selected == value.Targeting__c )
            
            component.set('v.availablePricing',matchingProducts.map(value => (value.PricingModel__c) ? value.PricingModel__c : "" ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedPricing') == value) ? true : false}; }).sort());
            helper.validate(component);
        } else component.set('v.availablePricing',[])
    },
    
    handlePricingSelected: function (component, event, helper) {
        var selected = component.get('v.selectedPricing');
        console.log("handlePricingSelected",selected)
        helper.checkBtn(component);
        
        var catalogType = component.get('v.catalogType');
        if(catalogType == 'SalesProduct') return;
        
        if(selected != 'none') {
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            var types = component.get('v.selectedTypes');
            var mediums = component.get('v.selectedMediums');
            var targeting = component.get('v.selectedTargeting');
            
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c)  && mediums.includes(value.Medium__c)  && targeting == value.Targeting__c && selected == value.PricingModel__c )
            
            component.set('v.availableDevices',matchingProducts.map(value => (value.Devices__c) ? value.Devices__c : "" ).filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value}; }).sort());
            helper.validate(component);
        } else component.set('v.availableDevices',[])
    },

    
    handlePromogamingTypesSelected: function (component, event, helper) {
        var selected = event.getParam("value");
        console.log("handlePromogamingTypesSelected",selected);
        console.log(component.get('v.selectedPromogamingTypes'));
        helper.checkBtn(component);
        var catalogType = component.get('v.catalogType');
        if(selected.length > 0) {
            //var catalogType = component.get('v.catalogType');
            var products = component.get('v.items')[catalogType];
            var category = component.get('v.activeItem');
            var types = component.get('v.selectedTypes');
            var mediums = component.get('v.selectedMediums');
            var targeting = component.get('v.selectedTargeting');
            var pricing = component.get('v.selectedPricing');

            console.log(products);
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c) && mediums.includes(value.Medium__c)  && targeting == value.Targeting__c && pricing.includes(value.PricingModel__c) && selected.includes(value.Type_Promogaming__c) )
            console.log('test matching', matchingProducts);
            component.set('v.availablePromogamingTypes',matchingProducts.map(value => (value.Type_Promogaming__c) ? value.Type_Promogaming__c : "").filter((value, index, self) => self.indexOf(value) === index).map( function(value){ return { "label": value, "value": value, "selected" : (component.get('v.selectedPromogamingTypes') == value) ? true : false}; }).sort());
            console.log(component.get('v.availablePromogamingTypes'));
            helper.validate(component);
            console.log(JSON.parse(JSON.stringify(component.get('v.availablePromogamingTypes'))));
        } else component.set('v.availablePromogamingTypes',[]);
    },
    
    handleDeviceSelected: function (component, event, helper) {
        var selected = event.getParam("value");
        console.log("handleDeviceSelected",selected)
        helper.checkBtn(component);
        
        var catalogType = component.get('v.catalogType');
        if(catalogType == 'SalesProduct') return;
        
        helper.validate(component);
    },
    
    handleSubmit: function(component, event, helper) { //availableDevices
        event.preventDefault(); // stop the form from submitting
        helper.showSpinner(component);
        var catalogType = component.get('v.catalogType');
        var types = component.get('v.selectedTypes');
        var mediums = component.get('v.selectedMediums');
        var promo = component.get('v.selectedPromogamingTypes');
        var devices = component.get('v.selectedDevices');
        var targeting = component.get('v.selectedTargeting');
        var pricing = component.get('v.selectedPricing');
        var format = component.get('v.selectedFormat');
        var ean = component.get('v.selectedEAN');
        var montant = component.get('v.selectedAmountExclTaxes'); 
        var statsPromo = component.get('v.selectedStatsPromo');
        var offert = component.get('v.selectedOffert');
        var brandName = component.get('v.selectedBrandName');
        var frameworkAgree = component.get('v.selectedFrameworkAgreement');
        var contractProductName = component.get('v.selectedContractProductName');
        
        if(targeting == 'data' && devices.includes('non applicable') == false) devices.push('non applicable');
        
        var typeWarnings = component.get('v.typeWarnings');
		var mediumWarnings = component.get('v.mediumWarnings');
        
        var products = component.get('v.items')[catalogType];
        
        var f = event.getParam('fields');
        
        if(catalogType == 'SalesProduct') {
            var bundle = products.filter(value => value.Name == component.get('v.activeItem'))[0]
            var bundleProducts  = bundle.packageProducts__r.filter(value => types.includes(value.Type__c)  && mediums.includes(value.Medium__c) && format.includes(value.Format__c)  && targeting == value.Targeting__c && pricing == value.PricingModel__c).map(value => value.Id )
            f.TechnicalProductIds__c = bundleProducts.join(';')
            f.Package__c = bundle.Id
        } else {
            var category = component.get('v.activeItem'); 
            var matchingProducts = products.filter(value => value.Category__c == category && types.includes(value.Type__c)  && mediums.includes(value.Medium__c) && format == value.Format__c && targeting == value.Targeting__c && pricing == value.PricingModel__c && devices.includes(value.Devices__c))
            f.TechnicalProductIds__c = matchingProducts.map(value => value.Id ).join(';');
            f.Category__c = category;
        }
        
        f.CustomDiscount__c = component.get('v.availableDiscount');
        f.Type__c = types.filter(value => !typeWarnings.split(',').includes(value)).join(';');
        f.Medium__c = component.get('v.selectedMediums')[0];
        f.Device__c = devices.join(';');
        f.Type_Promogaming__c = component.get('v.selectedPromogamingTypes')[0];
        f.Targeting__c = 'rotation générale';
        f.PricingModel__c = pricing;
        f.Format__c = format;
        f.StartDate__c = component.get('v.startDate');
        f.EndDate__c = component.get('v.endDate');
        f.Amount_Excl_taxes__c = montant;
        f.EAN__c = ean; 
        f.StatsPromoUnit__c = statsPromo;
        f.Offert__c = offert;
        f.BrandName__c = brandName;
        f.FrameworkAgreement__c = frameworkAgree;
        f.ContractProductName__c = contractProductName;
        console.log(JSON.parse(JSON.stringify(f)));
        event.getSource().submit(f);
        //component.find('recordForm').submit(f);
    },
    
    handleSuccess: function (component, event, helper) {
        helper.showToast('success', 'Succès!', 'Votre produit a bien été ajouté');
        component.set('v.activeItem', 'hidden');
        component.getEvent("CloseParentModal").fire();
        $A.get('e.force:refreshView').fire();
    },
    
    handleLoad: function (component, event, helper) {
        helper.hideSpinner(component)
    },
    
    handleCatalogChange: function (component, event, helper) {
        var items = component.get('v.items');
        var catalogType = component.get('v.catalogType')
        console.log("handleCatalogChange "+catalogType)
        
        if(items != null && items[catalogType]) component.set('v.availableItems',items[catalogType].map(item => (catalogType == 'SalesProduct') ? item.Name : item.Category__c).filter((value, index, self) => self.indexOf(value) === index));
        else component.set('v.availableItems', [])
    }
})