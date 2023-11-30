trigger InsertionAfterTrigger on Insertion__c (after update, after insert) {
    Set<Id> insertions = new Set<Id>();
    Set<Id> insClosedToSigned = new Set<Id>();
    if(Trigger.isUpdate == true){
        for(insertion__c i : Trigger.new) {
            if(i.Status__c == 'Clôturé' && Trigger.oldMap.get(i.id).Status__c != 'Clôturé' && Trigger.oldMap.get(i.id).Status__c != 'OI facturé' && i.Revenue__c != 0  && i.Revenue__c != null) insertions.add(i.Id);
            if((i.Status__c == 'Signé' || i.Status__c == 'Signé/Contrôlé') && Trigger.oldMap.get(i.id).Status__c == 'Clôturé') insClosedToSigned.add(i.Id);
        }
    } else {
        for(insertion__c i : Trigger.new) {
            if(i.Status__c == 'Clôturé' && i.Revenue__c != 0  && i.Revenue__c != null) insertions.add(i.Id);
        }
    }
    if(insertions.size() > 0) ForecastHelper.handleClosingInsertion(insertions); 
    if(insertions.size() > 0) invoicing_controller.createDraftInvoiceItems(insertions);
    if(insClosedToSigned.size() > 0) invoicing_controller.deleteInvoiceItems(insClosedToSigned);
}