global class RelevancInvoicesToFtp implements Database.Batchable<sObject>, Schedulable{

    global String query = 'SELECT Id, Name, Status__c, SentInvoice__c, BillingEntity__c FROM Invoice__c WHERE Status__c = \'validated\' AND BillingEntity__c = \'Relevanc\' AND SentInvoice__c != true';
    
    global RelevancInvoicesToFtp(){
        if(Database.query(query).isEmpty()){
            System.enqueueJob(new QueueExportApi(new List<Document>{new Document(body = Blob.valueOf('  '),folderid = UserInfo.getUserId(),name = 'SA2RELVP.tgt')}, 'Relevanc_Export'));
        }
    }
    
    global void execute(SchedulableContext SC) {
 		database.executebatch(new RelevancInvoicesToFtp()); 
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            query = 'SELECT Id, Name, Status__c, SentInvoice__c, BillingEntity__c FROM Invoice__c ';
        }
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext bc, List<Invoice__c> scope){
        try{
            Set<Id> IdsToExport = new Set<Id>();
            for(Invoice__c inv : scope) IdsToExport.add(inv.Id);
            List<Invoice__c> exportInvList = gnx_export.queryInvoiceExportFields(IdsToExport);
            System.enqueueJob(new QueueExportApi(new List<Document>{gnx_export.exportRelevancSched(exportInvList)}, 'Relevanc_Export'));
        }catch(Exception e){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new String[]{'Projet@isochronix.com'};mail.setSubject('API 3wRegie/RelevanC : Erreur lors de l\'export en masse');mail.setPlainTextBody('Message : '+e.getMessage()+' line : '+e.getLineNumber());
        	Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    } 
}