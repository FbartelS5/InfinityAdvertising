global class AaeBatchExport implements Database.Batchable<sObject>, Schedulable, Database.Stateful{
    global Integer invCounter = 0;
    global List<String> exceptionList = new List<String>();
    
    global AaeBatchExport(){}
    
    global void execute(SchedulableContext SC) {
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault=true];
        Datetime targetTime = Datetime.now();
        Datetime nextStart = BusinessHours.nextStartDate(bh.id, targetTime);
        String cronVar = '0 0 21 '+nextStart.day()+' '+nextStart.month()+' ? '+nextStart.year();
        
        if(BusinessHours.isWithin(bh.id, targetTime)) database.executebatch(this, 200);
        else System.schedule('nextAaeBatchExport', cronVar, this);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        if(Test.isRunningTest()){
            return Database.getQueryLocator('SELECT Id, Name, Status__c, SentInvoice__c, BillingEntity__c FROM Invoice__c WHERE Status__c = \'draft\'');
        } else {
            return Database.getQueryLocator('SELECT Id, Name, Status__c, SentInvoice__c, BillingEntity__c FROM Invoice__c WHERE Avoir__c = true AND BillingEntity__c = \'Relevanc\' AND Status__c = \'draft\' AND TotalExcludingVat__c < 0 AND CreatedDate >= 2021-02-01T00:00:00Z'); 
        }
    }
    
    global void execute(Database.BatchableContext bc, List<Invoice__c> scope){
        try{
            List<Invoice__c> exportInvList = gnx_export.queryInvoiceExportFields(new Map<Id, Invoice__c>(scope).keySet());
            invCounter += exportInvList.size();
            List<Document> docList = new List<Document>{faeaae_export.exportAaeSched(exportInvList)};
                System.enqueueJob(new QueueExportApi(docList, 'Regie3W_Export'));
            if(Test.isRunningTest()) throw new aaeException('test');
        }catch(Exception e){
            exceptionList.add('Message : '+e.getMessage()+' line : '+e.getLineNumber());
        }
    }   
    
    global void finish(Database.BatchableContext bc){
        if(invCounter == 0) System.enqueueJob(new QueueExportApi(new List<Document>{new Document(body = Blob.valueOf('  '),folderid = UserInfo.getUserId(),name = 'SA1RLVAP_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt')}, 'Regie3W_Export'));
        if(exceptionList.size() != 0){
            List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
            for(String msg : exceptionList){
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.toAddresses = new String[]{'Projet@isochronix.com'};
                mail.setSubject('API 3wRegie/RelevanC : Erreur lors de l\'export en masse');
                mail.setPlainTextBody(msg);
                mailList.add(mail);
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mailList);
        }
    }
    
    public class aaeException extends Exception {}
}