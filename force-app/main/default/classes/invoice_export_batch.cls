global class invoice_export_batch implements Database.Batchable<sObject>, Schedulable{
    global String query = 'SELECT Id, Name, Status__c, SentInvoice__c, BillingEntity__c FROM Invoice__c WHERE Status__c = \'validated\' AND SentInvoice__c != true';
    
    global invoice_export_batch(){
        if(Database.query(query).isEmpty()){ //Si rien a exporter, envoyer un fichier vide
            List<Document> documents = new List<Document>{new Document(
                body = Blob.valueOf('  '),
                folderid = UserInfo.getUserId(),
                name = 'winLogic_InfinityAds_empty.tgt'
            )};
            System.enqueueJob(new invoice_export_queue(documents));
        }
    }
    
    global void execute(SchedulableContext SC) {
 		database.executebatch(new invoice_export_batch()); 
    }
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext bc, List<Invoice__c> scope){
        try{
            Set<Id> IdsToExport = new Set<Id>();
            for(Invoice__c inv : scope){
                IdsToExport.add(inv.Id);
            } 
            List<Invoice__c> exportInvList = invoice_export.queryInvoiceExportFields(IdsToExport);
            List<Document> documents = new List<Document>{invoice_export.exportInfinitySched(exportInvList)};
            System.enqueueJob(new invoice_export_queue(documents));
        }catch(Exception e){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new String[]{'Projet@isochronix.com'};mail.setSubject('API Infinity Ads : Erreur lors de l\'export en masse');mail.setPlainTextBody('Message : '+e.getMessage()+' line : '+e.getLineNumber());
        	Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        }
    }    
    global void finish(Database.BatchableContext bc){
        
    } 
}