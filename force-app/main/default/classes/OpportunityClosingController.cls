public class OpportunityClosingController {
    
    @AuraEnabled
    public static List<Opportunity> getOpportunities() {
        return [SELECT Id, Name, AutoOppId__c, Account.Name, Owner.Name, Amount, ControledAmount__c, ClosedAmount__c, ClosedAmountNotInvoiced__c,
                InvoicedAmount__c,
                (SELECT Id, StartDate__c, EndDate__c, Volume__c, Revenue__c, Status__c, OpportunityProduct__c, Opportunity__c, Product__c, CampaignNumber__c, 
                 OrderReference__c, OpportunityProduct__r.Name, OpportunityProduct__r.UnitPrice__c, OpportunityProduct__r.PricingModel__c, 
                 NewInsertion__c, Product__r.Devices__c, Product__r.Targeting__c, Product__r.Medium__c, Product__r.Type__c, Product__r.PricingModel__c,
                 UnitPrice__c, Free__c, OpportunityProduct__r.Type__c, OpportunityProduct__r.Offert__c
                 FROM Insertions__r) 
                FROM Opportunity
                WHERE Id IN (Select Opportunity__c from Insertion__c WHERE Status__c in ('Signé','Signé/contrôlé','Clôturé','OI facturé'))];
    }
    
    @AuraEnabled
    public static void updateData(String data, String objectType) {
        switch on (objectType) {
            when 'Insertion__c' {
                update (List<Insertion__c>) JSON.deserialize(data, List<Insertion__c>.class);
            }
            when else {
                system.debug('default');
            }
        }
    }
        
}