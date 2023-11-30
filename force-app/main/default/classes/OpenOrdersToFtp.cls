global class OpenOrdersToFtp implements Database.Batchable<sObject>, Schedulable{
    global OpenOrdersToFtp(){
    }
    
    global void execute(SchedulableContext SC) {
 		database.executebatch(new OpenOrdersToFtp()); 
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Status__c, SentInvoice__c, Opportunity__r.RecordType.Name, Opportunity__r.CloseDate'
            +' FROM Invoice__c WHERE Status__c != \'validated\' AND Status__c != \'canceled\' AND SentInvoice__c != true'
            +' AND Opportunity__r.RecordType.name = \'Open Order\' AND CreatedDate = LAST_N_DAYS:3';
        //
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<Invoice__c> scope){
        system.debug(scope);
        List<Invoice__c> invList = new List<Invoice__c>();
        Set<Id> IdsToExport = new Set<Id>();
        List<Document> docList = new List<Document>();
        for(Invoice__c inv : scope){
            if(inv.SentInvoice__c != true){
                invList.add(inv);
                IdsToExport.add(inv.Id);
            }
        }
        Database.SaveResult[] srList = Database.update(invList, false);
        List<Invoice__c> exportInvList = gnx_export.queryInvoiceExportFields(IdsToExport);
        docList = new List<Document>(gnx_export.exportGnxSched(exportInvList));
        if(docList.size() > 0)System.enqueueJob(new QueueExportApi(docList, 'Regie3W_Export'));
    }    
    global void finish(Database.BatchableContext bc){
        
    } 
}