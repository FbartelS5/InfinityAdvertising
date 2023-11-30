public class OpportunityTriggerHandler extends TriggerHandler {
    Map<Id, Opportunity> newMap;
    Map<Id, Opportunity> oldMap;
    List<Opportunity> newList;
    List<Opportunity> oldList;
    Boolean sizeForSchedule;

    public class OpportunityTriggerHandlerException extends Exception {}
 
    public OpportunityTriggerHandler() {
       super('OpportunityTriggerHandler');
       oldMap = (Map<Id, Opportunity>) Trigger.oldMap;
       newMap = (Map<Id, Opportunity>) Trigger.newMap;
       oldList = Trigger.old;
       newList = Trigger.new;
       sizeForSchedule = newList != null ? newList.size() >= 100 : false;
    }
 
    public override void afterInsert() {
        List<Opportunity> oppList = [SELECT Id, Owner.BU__c, RecordTypeId, RecordType.Name, BU__c, InsertionOrderId__c, CampaignStartDate__c, OwnerId FROM Opportunity WHERE Id IN: newMap.keySet()];
        List<BillingEntity__c> billingEntList = [SELECT Id, Name FROM BillingEntity__c WHERE Name = 'Infinity Advertising' LIMIT 1];
        system.debug('billingEntList.size()'+billingEntList.size());
        system.debug('billingEntList'+billingEntList);

        Id billingEntityId;
        if(billingEntList.size() > 0){
            billingEntityId = billingEntList[0].Id;
        }else{
            throw new OpportunityTriggerHandlerException('L\'entité de facturation "Infinity Advertising" est introuvable');
        }
        for(Opportunity opp : oppList){
//            opp.BU__c = opp.Owner.BU__c;
            opp.BillingEntity__c = billingEntityId;
            opp.AutoOppId__c = opp.InsertionOrderId__c;
        }
        update oppList;
    }

    
    public override void afterUpdate() {
        if(Recursion.oppRecursion) return;
        Recursion.oppRecursion = true;
        
        Set<id> opps = new Set<id>();
        Set<id> invoicingLevelOpps = new Set<id>();
        Set<id> technicalFeesInvoicingOpps = new Set<id>();
        Set<id> invoicingStageNameOpps = new Set<id>();
        
        // create insertions
        invoicing_controller.createInsertions(newMap.keySet());
        
        for(Opportunity opp : newList) {
            Opportunity oldOpp = oldMap.get(opp.id);
            
            //if account/agency/BU/Invoiced account changed
            if(opp.AccountId != oldOpp.AccountId  || opp.Agency__c != oldOpp.Agency__c  || opp.BU__c != oldOpp.BU__c || opp.InvoicedAccount__c != oldOpp.InvoicedAccount__c) opps.add(opp.Id);
            
            //if InvoicingLevel__c changed
            if(opp.InvoicingLevel__c != oldOpp.InvoicingLevel__c) invoicingLevelOpps.add(opp.id);
            
            //if TechnicalFeesInvoicing__c changed
            if(opp.TechnicalFeesInvoicing__c != oldOpp.TechnicalFeesInvoicing__c) technicalFeesInvoicingOpps.add(opp.id);
            
            //if StageName changed
            if(opp.StageName != oldOpp.StageName) invoicingStageNameOpps.add(opp.id);
        }
        
        if(opps.size() > 0) 						invoicing_controller.updateProforma(opps);
        if(invoicingLevelOpps.size() > 0) 			invoicing_controller.handleInvoicingLevel(invoicingLevelOpps);
        if(technicalFeesInvoicingOpps.size() > 0) 	invoicing_controller.handleTechnicalFeesInvoicing(technicalFeesInvoicingOpps);
        if(invoicingStageNameOpps.size() > 0) 		ForecastHelper.handleOppStageName(invoicingStageNameOpps);
        
        Recursion.oppRecursion = false;
    }  


}