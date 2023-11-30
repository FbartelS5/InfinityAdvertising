@isTest 
public with sharing class RelevancInvoicesToFtpTest {
    @isTest
    static void testRelevanInvoices(){

        Account account = new Account(Name = 'test', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R55555', SapCode__c='test123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR00999999999', Siret__c = '99999999999999', Siren__c='123456789');
        insert account;

        BillingEntity__c be =  new BillingEntity__c(Name = 'Infinity Advertising', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be;

        Contact contact = new Contact(AssistantName='Test1', AccountId = account.id,LastName='Test2');
        insert contact;

        Opportunity opp = new Opportunity(Name = 'opp test', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id,	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        insert opp;


        Invoice__c inv= new Invoice__c(Status__c = 'validated',SentInvoice__c=false, Account__c = account.Id,Opportunity__c=opp.Id, Name='test Fac Tech', InvoiceDate__c=System.today());
        insert inv;

        //Invoice__c testinvoice=[SELECT Id, Name, Status__c, SentInvoice__c, BillingEntity__c FROM Invoice__c  WHERE Status__c ='validated' AND BillingEntity__c = 'Relevanc' AND SentInvoice__c != true];

        //system.debug('testinvoice'+testinvoice);
        System.Test.startTest();
        
        //Invoking Batch

        RelevancInvoicesToFtp batch = new RelevancInvoicesToFtp();
        Id batchId = Database.executeBatch(batch);

        RelevancInvoicesToFtp schedule = new RelevancInvoicesToFtp();
        System.schedule('test','0 0 8 13 2 ?', schedule);
        Id batchJobId = Database.executeBatch(new RelevancInvoicesToFtp(), 8);
    //    Database.executeBatch(new RelevancInvoicesToFtp());

        System.Test.stopTest();

    }
}