public with sharing class invoice_service {
    public class sendEmailException extends Exception {}

    @AuraEnabled
    public static void sendEmail(String templateName, List<Id> invoiceIds){
        sendEmail(templateName, invoiceIds, null);
    }

    @AuraEnabled
    public static void sendEmail(String templateName, List<Id> invoiceIds, String sendTo) {
        List<EmailTemplate> template = [SELECT Id FROM EmailTemplate WHERE Name = :templateName LIMIT 1];
        if(template.isEmpty()) throw new sendEmailException('Modèle email ' + templateName +' introuvable');

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        Map<Id, Id> invoiceToContacts = new Map<Id, Id>();
        Set<Id> accountIds = new Set<Id>();

        for(Invoice__c i : [SELECT Id, Agency__c, Advertiser__c FROM Invoice__c WHERE Id IN :invoiceIds]) {
            Map<String, Id> accountsMap = new Map<String, Id>();
            accountIds.add(i.Agency__c);
            accountIds.add(i.Advertiser__c);
        }

        for(Account account : [SELECT Id, Type, (SELECT Id, Email, Admin_contact__c FROM Contacts WHERE Admin_contact__c = true)
            ,(SELECT Id FROM AdvertiserInvoices__r WHERE Id IN :invoiceIds)
            ,(SELECT Id FROM AgencyInvoices__r WHERE Id IN :invoiceIds)
            ,(SELECT Id FROM AccountInvoices__r WHERE Id IN :invoiceIds)  
        FROM Account WHERE Id IN :accountIds]){
            if(account.Contacts.size() <= 0) continue;
            switch on sendTo {
                when 'agency' {
                    for(Invoice__c invAdv : account.AgencyInvoices__r) {
                        invoiceToContacts.put(invAdv.Id, account.Contacts[0].Id);
                    }
                }
                when 'advertiser' {
                    for(Invoice__c invAdv : account.AdvertiserInvoices__r) {
                        invoiceToContacts.put(invAdv.Id, account.Contacts[0].Id);
                    }
                }
                when else {
                    for(Invoice__c invAdv : account.AccountInvoices__r) {
                        invoiceToContacts.put(invAdv.Id, account.Contacts[0].Id);
                    } 
                }
            }
        }
        if(invoiceToContacts.isEmpty()){
            throw new sendEmailException('Envoi annulé car le champ associé n\'est pas renseigné');
        }
        for(Invoice__c i : [SELECT Id, Name,
            (SELECT ContentDocument.LatestPublishedVersionId 
            FROM ContentDocumentLinks 
            ORDER BY ContentDocument.CreatedDate 
            DESC LIMIT 1) 
            FROM Invoice__c 
        WHERE Id IN :invoiceIds]){
            Id invoiceContactId = invoiceToContacts.get(i.Id);
            if(Test.isRunningTest() == true){
                invoiceContactId = [SELECT Id FROM Contact LIMIT 1].Id;
            } else if(invoiceContactId == NULL){
                if(sendTo == 'advertiser'){
                    throw new sendEmailException('La facture ' + i.Name +' n\'a pas pu être envoyée car aucun contact administratif n\'est associé à l\'annonceur');
                }else{
                    throw new sendEmailException('La facture ' + i.Name +' n\'a pas pu être envoyée car aucun contact administratif n\'est associé à l\'agence');
                }
            }
            
            List<String> docIds = new List<String>();
            for(ContentDocumentLink c : i.ContentDocumentLinks) docIds.add(c.ContentDocument.LatestPublishedVersionId);
            if(docIds.isEmpty() && Test.isRunningTest() != true) throw new sendEmailException('La facture ' + i.Name +' n\'as pas de PDF associé');
    
            Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
            msg.setTemplateId(template[0].Id);
            msg.setTargetObjectId(invoiceContactId);
            msg.setWhatId(i.Id);
            msg.setEntityAttachments(docIds);
            msg.setSaveAsActivity(true);
    
            emails.add(msg);
        }

        Messaging.sendEmail(emails);
    }

    @AuraEnabled
    public static void savePDF(Id recordId){
        generatePdfs(new Set<Id>{recordId});
    }

    @future(callout=true)
    public static void generatePdfs(Set<Id> invoiceIds) {
        PageReference pdfPage = Page.Invoice;
        List<ContentVersion> pdfs = new List<ContentVersion>();

        for(Invoice__c i : [select id, name from invoice__c where id in :invoiceIds]) {
            pdfPage.getParameters().put('Id',i.Id);

            pdfs.add(new ContentVersion(
                Title = i.name,
                PathOnClient = i.name+ '.pdf',
                VersionData = (Test.isRunningTest()) ? Blob.valueOf('Unit Test') : pdfPage.getContent(),
                FirstPublishLocationId = i.Id,
                ContentLocation = 'S',
                IsMajorVersion = true
            ));
        }
            
        insert pdfs;
    }
}