public class ForecastHelper {
    public class ForecastException extends Exception {}
    
    public class request {
        public ID recordId;
        public Date startDate;
        public Date endDate;
        public Decimal amount;
        public String bu;
    }
    
    public static void handleOpportunityProduct(List<Product__c> prodOppList){
        List<request> requests = new List<request>();
        Map<Id, String> prodIdToBu = new Map<Id, String>();
        Set<Id> prodIds = new Set<Id>();
        for(Product__c prod : prodOppList)prodIds.add(prod.Id);
        List<Product__c> queryBU = [SELECT Id, Opportunity__r.Bu__c FROM Product__c WHERE Id IN: prodIds];
        for(Product__c prodOpp : queryBU) prodIdToBu.put(prodOpp.Id, prodOpp.Opportunity__r.Bu__c);
        for(Product__c prodOpp : prodOppList){
            if(prodOpp.Offert__c != true){
                request req = new request();
                req.recordId = prodOpp.Id;
                req.amount = prodOpp.Total__c ;
                req.startDate = prodOpp.startDate__c;
                req.endDate = prodOpp.EndDate__c;
                req.bu = prodIdToBu.get(prodOpp.Id);
                requests.add(req);
            }
        }
        follow(requests);
    }
    
    public static void handleClosingInsertion(Set<Id> insertionIds){
        Set<Id> productIds = new Set<Id>();
        List<Forecast_Item__c> items = new List<Forecast_Item__c>();
        Map<Id, Integer> itemToDaysNb = new Map<Id, Integer>();
        List<Insertion__c> insertionList = [SELECT Id, Name, Revenue__c, OpportunityProduct__c, StartDate__c, EndDate__c  FROM Insertion__c WHERE Id IN:insertionIds AND Status__c = 'Clôturé' ];
        for(Insertion__c ins : insertionList) productIds.add(ins.OpportunityProduct__c);
        List<Insertion__c> allInsertions = [SELECT Id, Name, Revenue__c, OpportunityProduct__c, StartDate__c, EndDate__c  FROM Insertion__c WHERE OpportunityProduct__c IN:productIds AND Status__c = 'Clôturé' ];
        List<product__c> forecastItemProdList = [SELECT Id, Total__c, startDate__c, EndDate__c, Offert__c,
                                                 (SELECT Id, Block__c, ClosedRevenue__c, forecast__r.Id, forecast__r.Month__c, forecast__r.Year__c, forecast__r.BU__c, Product__c, Revenue__c
                                                  FROM Lignes_d_atterrissage__r)
                                                 FROM product__c WHERE Id IN: productIds];
        
        //Put Insertion's closedRevenue in Forecast_Item
        for(Insertion__c ins : allInsertions){
            for(Product__c prodOpp : forecastItemProdList){
                Date start = prodOpp.startDate__c;
                for(Forecast_Item__c item : prodOpp.Lignes_d_atterrissage__r){
                    Integer month = Date.parse('01/'+Forecasthelper.toMonthString(item.forecast__r.Month__c)+'/2000').month();
                    Integer numberOfDays = Date.daysInMonth(Integer.valueOf(item.forecast__r.Year__c), month);
                    Date itemDateMin = Date.newInstance(Integer.valueOf(item.forecast__r.Year__c), month, 01);
                    Date itemDateMax = Date.newInstance(Integer.valueOf(item.forecast__r.Year__c), month, numberOfDays);
                    if(ins.Revenue__c == null) ins.Revenue__c = 0;
                    if(ins.OpportunityProduct__c == item.Product__c && itemDateMin == ins.StartDate__c || ins.OpportunityProduct__c == item.Product__c && itemDateMax == ins.EndDate__c){
                        system.debug(items.indexOf(item));
                        system.debug(ins.Revenue__c);
                        if(items.indexOf(item) > -1 && items[items.indexOf(item)] != null){
                            items[items.indexOf(item)].ClosedRevenue__c += ins.Revenue__c;
                        }else{
                            item.ClosedRevenue__c = ins.Revenue__c;
                            items.add(item);
                        }
                    }
                    Integer duration;
                    Integer daysinmonth = date.daysInMonth(Integer.valueOf(start.Year()), start.Month());
                    if(start.addMonths(1).toStartOfMonth()-1 >= prodOpp.endDate__c) duration = prodOpp.endDate__c.day();
                    else if(start.day() == 1) duration = daysinmonth;
                    else duration = daysinmonth - start.day();
                    if(item == prodOpp.Lignes_d_atterrissage__r[0]) duration = duration +1;
                    itemToDaysNb.put(item.Id, duration);
                    start = start.addMonths(1).toStartOfMonth();
                }
            }
        }
        Database.update(items);
        postponedFollow(forecastItemProdList, itemToDaysNb);
    }
    
    public static void handleReOpeningInsertion(Set<Id> insertionIds){
        Set<Id> productIds = new Set<Id>();
        Set<String> setBu = new Set<String>();
        Map<Id, String> prodIdToBu = new Map<Id, String>();
        Map<String, String> pickLabel = getBuLabels();
        List<Forecast_Item__c> items = new List<Forecast_Item__c>();
        Map<Id, Integer> itemToDaysNb = new Map<Id, Integer>();
        List<Insertion__c> insertionList = [SELECT Id, Name, Revenue__c, OpportunityProduct__c, StartDate__c, EndDate__c, BU__c  FROM Insertion__c WHERE Id IN:insertionIds AND Status__c != 'Clôturé' ];
        for(Insertion__c ins : insertionList) productIds.add(ins.OpportunityProduct__c);
        List<Product__c> queryBU = [SELECT Id, Opportunity__r.Bu__c FROM Product__c WHERE Id IN: productIds];
        for(Product__c prodOpp : queryBU) prodIdToBu.put(prodOpp.Id, prodOpp.Opportunity__r.Bu__c);
        List<product__c> forecastItemProdList = [SELECT Id, Total__c, startDate__c, EndDate__c, Offert__c, Opportunity__r.BU__c,
                                                 (SELECT Id, Block__c, ClosedRevenue__c, forecast__r.Id, forecast__r.Month__c, forecast__r.Year__c, forecast__r.Month_Year__c, forecast__r.BU__c, Product__c, Revenue__c
                                                  FROM Lignes_d_atterrissage__r ORDER BY forecast__r.Month_Year__c)
                                                 FROM product__c WHERE Id IN: productIds];
        for(Product__c prodOpp : forecastItemProdList){
            prodIdToBu.put(prodOpp.Id, prodOpp.Opportunity__r.BU__c);
            setBu.add(prodOpp.Opportunity__r.BU__c);
        }
        List<Forecast__c> existingForecasts = [SELECT Id, Month__c, Year__c, BU__c FROM Forecast__c WHERE Bu__c IN: setBu ORDER BY Month_Year__c];
        List<String> monthList = getMonthLabels();
        for(product__c r : forecastItemProdList) {
            for(Forecast_Item__c item : r.Lignes_d_atterrissage__r){
                Date itemStartDate = Date.newInstance(Integer.valueOf(item.Forecast__r.year__c), Integer.valueOf(toMonthString(item.Forecast__r.Month__c)), 01);
                for(Insertion__c ins : insertionList){
                    if(ins.StartDate__c.month() == itemStartDate.month() && ins.StartDate__c.year() == itemStartDate.year() && pickLabel.get(ins.BU__c) == prodIdToBu.get(r.Id)){
                        system.debug(item);
                        if(item.ClosedRevenue__c != null){
                            if(items.indexOf(item) != -1){
                                items[items.indexOf(item)].ClosedRevenue__c = items[items.indexOf(item)].ClosedRevenue__c - ins.Revenue__c;
                            }else{
                                item.ClosedRevenue__c = item.ClosedRevenue__c - ins.Revenue__c;
                                items.add(item);
                            }
                        }else{
                            if(items.indexOf(item) != -1){
                                items[items.indexOf(item)].ClosedRevenue__c = 0;
                            }else{
                                item.ClosedRevenue__c = 0;
                                items.add(item);
                            }
                        }
                        Integer duration;
                        Integer daysinmonth = date.daysInMonth(Integer.valueOf(ins.StartDate__c.Year()), ins.StartDate__c.Month());
                        if(ins.StartDate__c.addMonths(1).toStartOfMonth()-1 >= ins.endDate__c) duration = ins.endDate__c.day();
                        else if (ins.StartDate__c.day() == 1) duration = daysinmonth;
                        else duration = daysinmonth - ins.StartDate__c.day();
                        itemToDaysNb.put(item.Id, duration);
                    }
                }
            }
        }
        Database.update(items);
    }
    
    /* follow :
This method uses a list of requests (Product__c) to generate Forecasts and Forecast_Items
It creates a Forecast for each BU, for each Month of each Year.
Each Forecast creates a Forecast_Item that holds the price calculated using Pro Rata
A Forecast_Item can be Blocked, meaning the price won't change so the other Items have to readjust
*/
    public static void follow(List<request> requests) {
        Set<id> oldIds = new Set<id>();
        for (request r : requests) oldIds.add(r.recordId);
        List<Forecast_Item__c> itemsToInsert = new list<Forecast_Item__c>();
        List<Forecast_Item__c> itemsToUpdate = new list<Forecast_Item__c>();
        List<Forecast__c> itemGroups = new list<Forecast__c>();
        List<product__c> products = new List<product__c>();
        Map<String, Forecast__c> prodToForecastId = new Map<String, Forecast__c>();
        Set<String> prodToForecastIdUsedStrings = new Set<String>();
        List<Forecast_Item__c> oldForecasts = new List<Forecast_Item__c>();
        Map<Id, String> prodIdToBu = new Map<Id, String>();
        Map<String, String> pickLabel = getBuValues();
        Set<String> setBu = new Set<String>();
        List<product__c> forecastItemProdList = [SELECT Id, Total__c, startDate__c, EndDate__c, Opportunity__r.BU__c, Opportunity__r.Probability, 
                                                 (SELECT Id, Block__c, forecast__r.Id, forecast__r.Month__c, forecast__r.Year__c, forecast__r.Month_Year__c , forecast__r.BU__c, Product__c, Revenue__c, ClosedRevenue__c FROM Lignes_d_atterrissage__r ORDER BY forecast__r.Month_Year__c) 
                                                 FROM product__c WHERE Id IN: oldIds];
        for(Product__c prodOpp : forecastItemProdList){
            prodIdToBu.put(prodOpp.Id, prodOpp.Opportunity__r.BU__c);
            setBu.add(prodOpp.Opportunity__r.BU__c);
        }
        List<Forecast__c> existingForecasts = [SELECT Id, Month__c, Year__c, BU__c, Month_Year__c  FROM Forecast__c WHERE Bu__c IN: setBu ORDER BY Month_Year__c];
        
        List<String> monthList = getMonthLabels();
        Integer days;
        Date start;
        Decimal lockedDifference;
        Integer lockedDuration;
        Integer lockedDays;
        Integer month;
        Integer months;
        Datetime monthDt;
        String dateStr;
        String monthStr;
        Integer daysinmonth;
        Integer duration;
        Boolean needToCreateForecast;
        Boolean needToCreateForecastItem;
        //locked values are used to store the missing chunk of revenue and duration due to Blocked Items
        lockedDifference = 0;
        lockedDuration = 0;
        for (product__c r : forecastItemProdList) {
            itemGroups.clear();
            days = r.startDate__c.daysBetween(r.endDate__c);
            start = r.startDate__c;
            if(start.day() == 1) days++;
            //Search for the Blocked Forecast_Items
            //for(Integer i=0;i< r.Lignes_d_atterrissage__r.size();i++){
            for(Forecast_Item__c forecastItem : r.Lignes_d_atterrissage__r){
                //Forecast_Item__c forecastItem = r.Lignes_d_atterrissage__r[i];
                month = monthList.indexOf(forecastitem.forecast__r.Month__c);
                if(Integer.valueOf(toMonthString(forecastitem.forecast__r.Month__c)) < r.startDate__c.Month() && forecastitem.forecast__r.Year__c == String.valueOf(r.startDate__c.Year())
                   || Integer.valueOf(toMonthString(forecastitem.forecast__r.Month__c)) > r.endDate__c.Month() && forecastitem.forecast__r.Year__c == String.valueOf(r.endDate__c.Year())
                   || forecastitem.forecast__r.Year__c > String.valueOf(r.endDate__c.Year())
                   || forecastitem.forecast__r.Year__c < String.valueOf(r.startDate__c.Year())){
                       oldForecasts.add(forecastitem); 
                       continue;
                   }
                
                daysinmonth = date.daysInMonth(start.year(), start.month());
                system.debug(daysinmonth);
                system.debug(month);
                if(start.addMonths(1).toStartOfMonth()-1 >= r.endDate__c) duration = r.endDate__c.day();
                else if(start.day() == 1) duration = daysinmonth;
                else duration = daysinmonth - start.day();
                if(forecastItem.forecast__r.BU__c == prodIdToBu.get(r.id) && forecastItem.product__c == r.Id && forecastItem.Block__c == true){
                    lockedDuration = lockedDuration + duration;
                    if(forecastItem.ClosedRevenue__c == null) lockedDifference += forecastItem.Revenue__c;
                    else lockedDifference += forecastItem.ClosedRevenue__c;
                }
                start = start.addMonths(1).toStartOfMonth();
            }
            start = r.startDate__c;
            months = r.startDate__c.monthsBetween(r.endDate__c);
            for(Integer i = 0; i<=months; i++) {
                monthDt = r.startDate__c.addMonths(i).toStartOfMonth();
                String dateYear = monthDt.format('YYYY');
                String dateMonth = monthDt.format('MM');
                String strMonth = monthDt.format('MMMM');
                dateStr = dateYear+'-'+dateMonth;
                daysinmonth = date.daysInMonth(Integer.valueOf(dateYear), Integer.valueOf(dateMonth));
                needToCreateForecast = true;
                for(Forecast__c forecast : existingForecasts){
                    if(forecast.month_Year__c == dateStr && forecast.BU__c == prodIdToBu.get(r.id)){
                        prodToForecastId.put(dateYear+'/'+dateMonth+'/'+forecast.BU__c, forecast);
                        needToCreateForecast = false;
                        break;
                    }
                }
                if(needToCreateForecast == true){
                    system.debug(pickLabel.get(prodIdToBu.get(r.id)));
                    Forecast__c atterrissage = new Forecast__c(Name = 'Forecast: '+toMonthString(strMonth)+' '+String.valueOf(dateYear)+' '+pickLabel.get(prodIdToBu.get(r.id)), Year__c = String.valueOf(dateYear), Month__c = toMonthString(strMonth), Bu__c = prodIdToBu.get(r.id));
                    itemGroups.add(atterrissage);
                    prodToForecastId.put(dateYear+'/'+dateMonth+'/'+prodIdToBu.get(r.id), atterrissage);
                }
            }
            insert itemGroups;
            
            for(Integer i = 0; i<=months; i++) {
                monthDt = r.startDate__c.addMonths(i).toStartOfMonth();
                String dateYear = monthDt.format('YYYY');
                String dateMonth = monthDt.format('MM');
                dateStr = dateYear+'-'+dateMonth;
                daysinmonth = date.daysInMonth(Integer.valueOf(dateYear), Integer.valueOf(dateMonth));
                lockedDays = days;
                
                if(monthDt.month() == r.endDate__c.month()) duration = r.endDate__c.day();
                else if(monthDt.month() == r.startDate__c.month()) duration = daysinmonth - r.StartDate__c.day();
                else if(monthDt.day() == 1) duration = daysinmonth;
                
                needToCreateForecastItem = true;
                //Recherche d'un item existant
                for(Forecast_Item__c forecastItem : r.Lignes_d_atterrissage__r){
                    if(forecastItem.forecast__r.month_Year__c == dateStr && forecastItem.product__c == r.Id){
                        system.debug('FOUND FORECAST ITEM '+dateMonth+' '+dateYear);
                        needToCreateForecastItem = false;
                        break;
                    }
                }
                lockedDays -= lockedDuration;
                if(lockedDays == 0) lockedDays = 1;
                if(duration > lockedDays) duration = lockedDays;
                Decimal total = r.Total__c * (r.Opportunity__r.Probability * 0.01) - lockedDifference;
                Decimal revenue = total * duration / lockedDays;
                
                system.debug(r.Total__c+'*('+r.Opportunity__r.Probability * 0.01+') -'+lockedDifference);
                system.debug(lockedDays+'='+days+'-'+lockedDuration);
                system.debug(revenue+' = '+total+' * '+duration+' / '+lockedDays);
                //Apply updated price to Item
                for(Forecast_Item__c forecastItem : r.Lignes_d_atterrissage__r){
                    if(forecastItem.forecast__r.month_Year__c == dateStr && forecastItem.product__c == r.Id){
                        if(forecastItem.Block__c == false)forecastItem.Revenue__c = revenue;
                        itemsToUpdate.add(forecastItem);
                        continue;
                    }
                }
                //Create Forecast Item 
                if(needToCreateForecastItem == true && prodToForecastId.get(dateYear+'/'+dateMonth+'/'+prodIdToBu.get(r.Id)) != null){
                    system.debug('needtocreateItem : '+ dateYear+'/'+dateMonth+'/'+prodIdToBu.get(r.Id));
                    itemsToInsert.add(new Forecast_Item__c( Product__c = r.Id, Revenue__c = revenue, Forecast__c = prodToForecastId.get(dateYear+'/'+dateMonth+'/'+prodIdToBu.get(r.Id)).Id));
                }
            }
        }
        itemsToInsert.addAll(itemsToUpdate);
        Database.upsert(itemsToInsert);
        system.debug('itemsToInsert'+itemsToInsert);
        system.debug('oldForecasts'+oldForecasts);
        Database.delete(oldForecasts, false);
    }
    
    public static void postponedFollow(List<product__c> requests, Map<Id, Integer> itemToDaysNb) {
        List<Forecast_Item__c> items = new List<Forecast_Item__c>();
        Set<id> oldIds = new Set<id>();
        for(Product__c prod : requests) oldIds.add(prod.Id);
        List<String> monthList = getMonthLabels();
        Map<String, Decimal> forecastItemToClosedDiff = new Map<String, Decimal>();
        
        Integer days;
        Date start;
        Integer month;
        Integer months;
        Datetime monthDt;
        String monthStr;
        Integer daysinmonth;
        Integer duration;
        system.debug(itemToDaysNb);
        for (Product__c r : requests) {
            List<Integer> closedMonths = new List<Integer>();
            start = r.startDate__c;
            Decimal closedTotal = 0;
            Integer closedDays = 0;
            //Search for the Closed Forecast_Items
            for(Integer i=0;i< r.Lignes_d_atterrissage__r.size();i++){
                Forecast_Item__c forecastItem = r.Lignes_d_atterrissage__r[i];
                month = monthList.indexOf(forecastitem.forecast__r.Month__c)+1;
                if(forecastItem.product__c == r.Id && forecastItem.Revenue__c != null){
                    system.debug('FOUND CLOSED MONTH : '+ month);
                    closedTotal += forecastItem.Revenue__c;
                    system.debug('closedTotal : '+ closedTotal);
                    closedDays += itemToDaysNb.get(forecastItem.Id);
                    system.debug('closedDays : '+ closedDays);
                    if(i!=0) closedDays++;
                    closedMonths.add(month);
                }
            }
            system.debug(closedMonths);
            months = r.startDate__c.monthsBetween(r.endDate__c);
            closedTotal = r.Total__c - closedTotal;
            if (months == 0) {
            } else {
                system.debug('closedDays '+closedDays);
                days = r.startDate__c.daysBetween(r.endDate__c) - closedDays;
                if(r.startDate__c.day() == 1) days++;
                for(Integer i = 0; i<=months; i++) {
                    monthDt = r.startDate__c.addMonths(i).toStartOfMonth();
                    String dateYear = monthDt.format('YYYY');
                    String dateMonth = monthDt.format('MM');
                    String strMonth =  monthDt.format('MMMM');
                    String dateStr = dateYear+'-'+dateMonth;
                    daysinmonth = date.daysInMonth(Integer.valueOf(dateYear), Integer.valueOf(dateMonth));
                    if(closedMonths.contains(Integer.valueOf(dateMonth))) {
                        system.debug('FOUND CLOSED MONTH : '+ dateMonth);
                        continue;
                    }
                    if(monthDt.month() == r.endDate__c.month()) duration = r.endDate__c.day();
                    else if(monthDt.month() == r.startDate__c.month()) duration = daysinmonth - r.StartDate__c.day();
                    else if(monthDt.day() == 1) duration = daysinmonth;
                    if(i == 0) duration = duration +1;
                    Decimal distributedClosing = closedTotal * duration / days;
                    system.debug('revenue: '+distributedClosing+' = '+closedTotal+' * '+duration+' / '+days);
                    forecastItemToClosedDiff.put(toMonthString(strMonth)+'/'+dateYear, distributedClosing);
                }
            }
            for(Integer i=0;i< r.Lignes_d_atterrissage__r.size();i++){
                monthDt = r.startDate__c.addMonths(i).toStartOfMonth();
                String dateYear = monthDt.format('YYYY');
                String dateMonth = monthDt.format('MM');
                String strMonth =  monthDt.format('MMMM');
                String dateStr = dateYear+'-'+dateMonth;
                daysinmonth = date.daysInMonth(Integer.valueOf(dateYear), Integer.valueOf(dateMonth));
                if(closedMonths.contains(Integer.valueOf(dateMonth)) == true) {
                    system.debug('FOUND CLOSED MONTH 2 : '+ dateMonth);
                    start = start.addMonths(1).toStartOfMonth();
                    continue;
                }
                Forecast_Item__c forecastItem = r.Lignes_d_atterrissage__r[i];
                month = monthList.indexOf(forecastitem.forecast__r.Month__c)+1;
                forecastItem.Revenue__c = forecastItemToClosedDiff.get(toMonthString(strMonth)+'/'+dateYear);
                if(forecastItem.Revenue__c == null) forecastItem.Revenue__c = 0;
                items.add(forecastItem);
            }
        }
        for(Forecast_Item__c item : items) system.debug('item: '+item);
        Database.update(items, false);
    }
    
    public static void addInsertions(List<Product__c> requests){
        Set<Id> resultIds = (new Map<Id,SObject>(requests)).keySet();
        List<Product__c> oppProducts = [SELECT id, startDate__c, Package__c, endDate__c, Total__c, TechnicalProductIds__c, Opportunity__c, Opportunity__r.Probability, (SELECT Id, OpportunityProduct__c, startDate__c, endDate__c, product__c, Revenue__c FROM insertions__r) FROM Product__c WHERE Id IN: resultIds];
        
        List<Insertion__c> insToUpdate = new list<Insertion__c>();
        List<Insertion__c> insToInsert = new list<Insertion__c>();
        Map<Id, String> prodIdToBu = new Map<Id, String>();
        Map<String, Forecast__c> prodToForecastId = new Map<String, Forecast__c>();
        
        for(Product__c r : oppProducts){
            if(r.TechnicalProductIds__c == null) continue;
            List<Id> products = r.TechnicalProductIds__c.split(';');
            if(products.size() == 0) throw new ForecastException('Product ids missing on opportunity product');
            Set<Id> bundleIds = new Set<Id>(products);
            for(Id bundleId : bundleIds){
                Integer days = r.startDate__c.daysBetween(r.endDate__c);
                Date start = r.startDate__c;
                if(start.day() == 1) days++;
                Integer months = r.startDate__c.monthsBetween(r.endDate__c);
                system.debug(months);
                for(Integer i = 0; i<=months; i++) {
                    Datetime monthDt = r.startDate__c.addMonths(i).toStartOfMonth();
                    String dateYear = monthDt.format('YYYY');
                    String dateMonth = monthDt.format('MM');
                    String dateStr = dateYear+'-'+dateMonth;
                    Integer daysinmonth = date.daysInMonth(Integer.valueOf(dateYear), Integer.valueOf(dateMonth));
                    
                    if(monthDt.month() == r.startDate__c.month()){
                        monthDt = r.startDate__c;
                    }
                    if(monthDt.day() != 1) monthDt.addDays(1);
                    Date curDate = Date.valueOf(monthDt);
                    
                    Boolean needToCreateInsertion = true;
                    //Recherche d'une insertion existante
                    for(Insertion__c ins : r.insertions__r){
                        if(ins.StartDate__c.year() != ins.endDate__c.year()){
                            system.debug('Insertions can\'t be over two different years');
                        }else if(ins.StartDate__c == curDate && ins.OpportunityProduct__c == r.Id && ins.Product__c == bundleId){
                            needToCreateInsertion = false;
                            break;
                        }else if(ins.StartDate__c.month() == curDate.month() && ins.StartDate__c.year() == curDate.year() && ins.OpportunityProduct__c == r.Id && ins.Product__c == bundleId){ 
                            needToCreateInsertion = false;
                            break;
                        }
                    }
                    
                    //Apply updated date to Insertion
                    for(Insertion__c ins : r.insertions__r){
                        if(ins.StartDate__c.month() == monthDt.month() && ins.StartDate__c.year() == monthDt.year() && ins.OpportunityProduct__c == r.Id && ins.Product__c == bundleId){
                            ins.StartDate__c = monthDt.date();
                            insToUpdate.add(ins);
                        }
                    }
                    //Create Insertion
                    if(needToCreateInsertion == true){
                        Date endDate = monthDt.month() == r.endDate__c.month() ? r.endDate__c : curDate.addMonths(1).toStartofMonth().addDays(-1);
                        system.debug(endDate);
                        insToInsert.add(new Insertion__c( OpportunityProduct__c = r.Id, Product__c = bundleId, Opportunity__c = r.Opportunity__c, Status__c='Signé', StartDate__c = curDate, EndDate__c = endDate));
                    }
                }
            }
        }
        Set<Insertion__c> setInsToInsert = new Set<Insertion__c>(insToInsert);
        List<Insertion__c> finalInsToInsert = new List<Insertion__c>(setInsToInsert);
        system.debug('finalInsToInsert'+finalInsToInsert);
        try{
            if(finalInsToInsert.size() > 0)Database.insert(finalInsToInsert);
        }catch(Exception e){
            throw new ForecastException(e.getMessage());
            //'Un ou plusieurs des produits techniques liés au Produit d\'Opportunité n\'existent plus'
        }
        Set<Insertion__c> setInsToUpdate = new Set<Insertion__c>(insToUpdate);
        List<Insertion__c> finalInsToUpdate = new List<Insertion__c>(setInsToUpdate);
        if(finalInsToUpdate.size() > 0)Database.update(finalInsToUpdate);
    }
    
    //Initialize a map between BU value and BU label
    public static Map<String, String> getBuValues(){
        Map<String, String> picklistLabel = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = forecast__c.BU__c.getDescribe(); 
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues(); 
        for(Schema.PicklistEntry v : values) picklistLabel.put(v.getValue(), v.getLabel());
        return picklistLabel;
    }
    
    //Initialize a map between BU label and BU value
    public static Map<String, String> getBuLabels(){
        Map<String, String> picklistLabel = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = forecast__c.BU__c.getDescribe(); 
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues(); 
        for(Schema.PicklistEntry v : values) picklistLabel.put(v.getLabel(), v.getValue());
        return picklistLabel;
    }
    
    public static List<String> getMonthLabels(){
        List<String> picklistLabel = new List<String>();
        for(Schema.PicklistEntry v : forecast__c.Month__c.getDescribe().getPicklistValues()) picklistLabel.add(v.getValue());
        return picklistLabel;
    }
    
    public static String toMonthString(String month){
        switch on month{
            when 'January' {month = 'Janvier';}
            when 'February'{month = 'Février';}
            when 'March'{month = 'Mars';}
            when 'April'{month = 'Avril';}
            when 'May'{month = 'Mai';}
            when 'June'{month = 'Juin';}
            when 'July'{month = 'Juillet';}
            when 'August'{month = 'Août';}
            when 'September'{month = 'Septembre';}
            when 'October'{month = 'Octobre';}
            when 'November'{month = 'Novembre';}
            when 'December'{month = 'Décembre';}
            when 'Janvier' {month = '01';}
            when 'Février'{month = '02';}
            when 'Mars'{month = '03';}
            when 'Avril'{month = '04';}
            when 'Mai'{month = '05';}
            when 'Juin'{month = '06';}
            when 'Juillet'{month = '07';}
            when 'Août'{month = '08';}
            when 'Septembre'{month = '09';}
            when 'Octobre'{month = '10';}
            when 'Novembre'{month = '11';}
            when 'Décembre'{month = '12';}
        }
        return month;
    }
    
    public static void handleOppStageName(Set<Id> oppIds){
        handleOpportunityProduct([SELECT Id, Opportunity__r.Bu__c, Offert__c, Total__c, startDate__c, EndDate__c FROM Product__c WHERE Opportunity__c IN: oppIds]);
    }
    
    public static boolean checkInsertion(Id productId, Id oppId, Date startDt, Date endDt){
        Boolean val = false;
        Opportunity opp = [SELECT Id,(SELECT Id, Status__c, StartDate__c, EndDate__c, OpportunityProduct__c, Opportunity__c FROM Insertions__r WHERE OpportunityProduct__c =: productId AND Opportunity__c =: oppId) FROM Opportunity WHERE Id =: oppId];
        for(Insertion__c ins : opp.Insertions__r){
            if(startDt != null && ins.StartDate__c == startDt && (ins.Status__c == 'Clôturé' || ins.Status__c == 'OI facturé')) val = true;
            if(endDt != null && ins.EndDate__c == endDt && (ins.Status__c == 'Clôturé' || ins.Status__c == 'OI facturé')) val = true;
            if(startDt == null && endDt == null && (ins.Status__c == 'Clôturé' || ins.Status__c == 'OI facturé'))val = true;
        }
        return val;
    }
    
    @AuraEnabled
    public static Map<String,String> getUserInfo(String userId){
        Set<String> reportTypesSet = new Set<String>{'Vue_Annuelle_BU_Olh', 'Vue_par_OI_interface_Sales_IFO', 'Vue_Annuelle_Produit_RaM', 'Vue_Annuelle_commerciaux_qbh'};
            List<Report> reports = [SELECT Id, DeveloperName FROM Report WHERE DeveloperName  IN: reportTypesSet];
        User x = [SELECT Id, Name, BU__c, UserRole.Name FROM User WHERE Id =: userId];
        Map<String,String> btnNameToReport = new Map<String,String>();
        Map<String,String> finalMap = new Map<String,String>();
        Map<String, String> picklistLabel = getBuValues();
        String allBu = '';
        for(Report rep : reports) btnNameToReport.put(rep.DeveloperName, rep.id);
        if(x.BU__c != null) for(String bu : x.BU__c.split(';'))if(picklistLabel.get(bu) != null) allBu += picklistLabel.get(bu)+',';
        for(String btnName : reportTypesSet) finalMap.put(btnName, btnNameToReport.get(btnName)+'/'+x.UserRole.Name+'/'+allBu+'/'+x.Name);
        return finalMap;
    }
}