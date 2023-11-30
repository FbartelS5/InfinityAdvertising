trigger ProductTrigger on Product__c (after insert, after update, before update, before delete) {
    List<Product__c> prodList = new List<Product__c>();
    
    if(Trigger.isBefore) {
        if(Trigger.isDelete) {
            for(Product__c prod : Trigger.old) {
                if(ForecastHelper.checkInsertion(prod.Id, prod.Opportunity__c, null, null) == true) prod.addError('Une ou plusieurs insertions sont clôturées sur ce produit');
            }
        } else {
            for(Product__c prod : Trigger.new) {
                Product__c oldProd = Trigger.oldMap.get(prod.id);
                Date startDt = prod.StartDate__c > oldProd.StartDate__c ? oldProd.StartDate__c : null;
                Date endDt = prod.EndDate__c < oldProd.EndDate__c ? oldProd.EndDate__c : null;
                if(startDt != null || endDt != null) {
                    if(ForecastHelper.checkInsertion(prod.Id, prod.Opportunity__c, startDt, endDt) == true) prod.addError('Une ou plusieurs insertions sont clôturées sur ce produit');
                } 
            }
        }
    }
    
    if(Trigger.isAfter) {
        if(Recursion.productRecursion != true) {
            Recursion.productRecursion = true;
            
            List<Id> opps = new List<Id>();
            Map<Id, Decimal> oppTotalProducts = new Map<Id, Decimal>();
            List<Product__c> products = [SELECT Id, Total__c, Opportunity__r.StageName, Opportunity__c, Opportunity__r.ClosedAmount__c FROM Product__c WHERE Id IN : Trigger.newMap.keySet()];
            Map<Id, Product__c> mapProd = new Map<Id, Product__c>(products);
            for(Product__c p : products) opps.add(p.Opportunity__c);
            
            for(AggregateResult ag : [SELECT SUM(Total__c) total, Opportunity__c FROM Product__c WHERE Opportunity__c IN :opps GROUP BY Opportunity__c]) {
                oppTotalProducts.put((Id) ag.get('Opportunity__c'), (Decimal) ag.get('total'));
            }
            
            ForecastHelper.handleOpportunityProduct(Trigger.new);
            for(Product__c prod : Trigger.new) {
                Product__c p = mapProd.get(prod.Id);
                if(p.Opportunity__r?.StageName == 'Signé') prodList.add(prod);
                if(Trigger.isUpdate && Trigger.oldMap.get(prod.Id).Total__c != p.Total__c && oppTotalProducts.get(p.Opportunity__c) < p.Opportunity__r?.ClosedAmount__c) prod.addError('Le montant indiqué est inférieur aux montants déjà clôturé');
            }
            
            if(prodList.size() > 0) ForecastHelper.addInsertions(prodList);
        }
    }
}