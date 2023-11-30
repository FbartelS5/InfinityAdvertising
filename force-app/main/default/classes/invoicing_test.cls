@isTest 
class invoicing_test {
    @testSetup 
    static void setup() {
        List<Account> accounts = TestApexDataFactory.createSObjectList('Account', new Map<String,Object>{
            'Name' => new List<String>{'test', 'testAgence', 'testAdvertiser'},
            'BillingStreet'	=> 'Montée de la bonne mère',
            'BillingPostalCode'	=> '13006',
            'BillingCity'	=> 'Marseille',
            'BillingCountry' => 'France',
            'BillingCountryCode' => 'FR',
            'Type'	=> new List<String>{'Adex', 'Adex', 'Annonceur'},
            'GenerixCode__c'=> new List<String>{'R55555', 'GNX1234', 'GNX12340'},
            'SapCode__c'	=> new List<String>{'test123', 'SAP1234', 'SAP12340'},
            'IntracomVatNumber__c'	=> new List<String>{'FR00999999999', 'FR12341231234', 'FR12341231234'},
            'Siret__c'	=> new List<String>{'99999999999999', 'SIRET123401235', 'SIRET123401234'},
            'Siren__c'	=> '123456789'
        }, 3);

        Account advertiser = (Account)TestApexDataFactory.createSObject('Account', new Map<String,Object>{
            'Name'	=> 'Advertisername',
            'Siret__c'	=> 'SIRET123401236',
            'Siren__c'	=> '123456790',
            'BillingPostalCode'	=> '13006',
            'BillingStreet'	=> 'Montée des peuchères',
            'BillingCity'	=> 'Marseille',
            'BillingCountry' => 'France',
            'BillingCountryCode' => 'FR'
        });
        
        Product2 productRegule = (Product2)TestApexDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name'	=> 'testRegule',     
            'Type__c'	=> 'Régule', 
            'PricingModel__c'	=> 'Prix Unitaire', 
            'Category__c' 	=> 'CRM', 
            'BU__c'	=> Product2.BU__c.getDescribe().getPicklistValues()[0].getValue(), 
            'CampaignType__c'	=> 'Open Order',
            'isactive'	=> true,
            'Medium__c' => 'Infinity Advertising'
        });

        Product2 product = (Product2)TestApexDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name'	=> 'test',     
            'Type__c'	=> 'Display', 
            'PricingModel__c'	=> 'Prix Unitaire', 
            'Category__c' 	=> 'CRM', 
            'BU__c'	=> Product2.BU__c.getDescribe().getPicklistValues()[0].getValue(), 
            'CampaignType__c'	=> 'Open Order',
            'isactive'	=> true
        });

        Opportunity opportunity = (Opportunity)TestApexDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'BillingEntity__r'	=> new Map<String,Object>{
                'Name' => 'Infinity Advertising',
                'LastInvoiceNumber__c' => 1000,
                'InvoicePrefix__c' => 'I'
            },
            'CampaignStartDate__c'	=> Date.newInstance(2020, 2, 17),
            'CampaignEndDate__c'	=> Date.newInstance(2020, 2, 25),
            'AdvertiserContact__r'	=> new Map<String,Object>{
                'LastName' => 'Contact Advertiser'
            },
            'AgencyContact__r'	=> new Map<String,Object>{
                'LastName' => 'Contact Agence'
            },
            'CustomerReference__c'	=> 'RefClient',
            'CloseDate'	=> Date.newInstance(1960, 2, 17),
            'StageName' => 'Proposition push',
            'Name'	=> 'TestOpp',
            'Signed_IO__c' => true,
            'OI_signed__c' => true,
            'Agency__c' => accounts[1].Id,
            'InvoicedAccount__c' => 'Agence'
        });

        Product__c oppProduct = (Product__c)TestApexDataFactory.createSObject('Product__c', new Map<String,Object>{
            'UnitPrice__c'	=> 500, 
            'Package__c'	=> product.Id, 
            'Quantity__c' 	=> 1, 
            'StartDate__c'	=> Date.today(), 
            'EndDate__c'	=> Date.today().addMonths(1),
            'Type__c'	    => 'Display',
            'PricingModel__c'=> 'Prix Unitaire',
            'Category__c'=> 'CRM',
            'Opportunity__c'	    => opportunity.Id,
            'TechnicalProductIds__c'=> product.Id
        });
        
        List<Insertion__c> insertions = TestApexDataFactory.createSObjectList('Insertion__c', new Map<String,Object>{
            'Opportunity__c' => opportunity.Id,
            'Product__c'	=> product.Id,
            'CampaignNumber__c'	=> '1',
            'StartDate__c ' => Date.newInstance(2020, 2, 17),
            'EndDate__c ' => Date.newInstance(2020, 2, 17),
            'Status__c' => new List<String>{'Signé', 'Clôturé', 'Clôturé'}
        }, 3);
        
        InvoiceItem__c mainInvoiceItem = (InvoiceItem__c)TestApexDataFactory.createSObject('InvoiceItem__c', new Map<String,Object>{
            'Quantity__c'	=> 50,
            'Product__c'	=> product.Id,
            'Insertion__c'	=> insertions[0].Id,
            'Invoice__r'	=> new Map<String,Object>{
                'Account__c'	=> accounts[0].Id,
                'Name'	=>	'test',
                'Opportunity__c'	=> opportunity.Id,
                'InvoiceDate__c'	=> System.today(),
                'advertiser__c'	=> advertiser.Id
            }
        });

        List<InvoiceItem__c> invoiceItems = TestApexDataFactory.createSObjectList('InvoiceItem__c', new Map<String,Object>{
            'Quantity__c'	=> 50,
            'Product__c'	=> product.Id,
            'Insertion__c'	=> insertions[0].Id,
            'Invoice__r'	=> new Map<String,Object>{
                'Account__c'	=> new List<Id>{accounts[0].Id,accounts[1].Id,accounts[2].Id},
                'Name'	=>	'test Fac {!index}',
                'Opportunity__c'	=> opportunity.Id,
                'InvoiceDate__c'	=> System.today(),
                'OriginalInvoiceNumber__c'	=> mainInvoiceItem.Invoice__r.Id,
                'advertiser__c'	=> advertiser.Id
            }
        }, 3);
        
        Profile stdProfile = [SELECT Id FROM Profile LIMIT 1];
        User user = (User)TestApexDataFactory.createSObject('User', new Map<String,Object>{
            'Alias'	=> 'standt',
            'Email'	=> 'standarduser@testorg.com',
            'EmailEncodingKey'	=> 'UTF-8',
            'LastName'	=> 'Testing',
            'LanguageLocaleKey'	=> 'en_US',
            'LocaleSidKey'	=> 'en_US',
            'ProfileId'	=> stdProfile.Id,
            'TimeZoneSidKey'	=> 'America/Los_Angeles',
            'UserName'	=> 'standardtestuser@123testorg.com'
        });
        
        Document document = (Document)TestApexDataFactory.createSObject('Document', new Map<String,Object>{
            'body'	=> Blob.valueOf('a'),
            'folderid'	=> user.Id,
            'name'	=> 'a.txt'
        });
        
        ProvisionNumber__c provisionNumber = (ProvisionNumber__c)TestApexDataFactory.createSObject('ProvisionNumber__c', new Map<String,Object>{
            'counter__c'	=> 1
        });
                
        List<Contact> contacts = TestApexDataFactory.createSObjectList('Contact', new Map<String,Object>{
            'LastName'	=> new List<String>{'Contact Agence', 'Contact Advertiser'}
        }, 2);
    }
    
    static testmethod void test_all() {
        //Given
        Test.startTest();
        Account account = new Account(Name = 'test test 1', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R555555', SapCode__c='test2123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR0909999999', Siret__c = '9991999999999', Siren__c='115656789');
        insert account;
        BillingEntity__c be =  new BillingEntity__c(Name = 'Relevanc', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be;
        BillingEntity__c be2 =  new BillingEntity__c(Name = 'Infinity Advertising', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be2;
        
        Contact contact = new Contact(AssistantName='Test1 3', AccountId = account.id,LastName='Test2');
        insert contact;
        
        Opportunity opp = new Opportunity(Name = 'opp test 123', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id,	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        Opportunity opp2 = new Opportunity(Name = 'opp test2 123', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be2.Id,	AdvertiserContact__c=contact.id ,AgencyContact__c = contact.id);
        
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(opp);
        oppList.add(opp2);
        insert oppList;

        BillingEntity__c billingEntity = [SELECT Id FROM BillingEntity__c LIMIT 1];
        Invoice__c inv1 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test1 567', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );
         
        Invoice__c inv2 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test 345', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );

        List<Invoice__c> invList = new List<Invoice__c>();
        invList.add(inv1);
        invList.add(inv2);
        insert invList;
        
        //When
        invoicing_validator.validatorRequest r = new invoicing_validator.validatorRequest();
        r.invoiceId = invList[0].Id;
        r.billingEntity = billingEntity.Id;
        invoicing_validator.send(new List<invoicing_validator.validatorRequest>{r});
        Test.stopTest();
    }
    
    
    @isTest
    static void invoice_controllerTest(){
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        PageReference pr = Page.invoice;

        Test.startTest();
        Test.setCurrentPage(pr);
        ApexPages.currentPage().getParameters().put('id', invoice.Id);
        invoice_controller ic = new invoice_controller();
        Invoice__c i = ic.getInvoice();
        List<invoice_controller.invoiceDetail> details = ic.getInvoiceDetails();

        invoice_controller.invoiceDetail detail = new invoice_controller.invoiceDetail();
        detail.opportunityProductName = 'opportunityProductName';
        detail.description = 'description';
        detail.startDate = 'startDate';
        detail.endDate = 'endDate';
        Test.stopTest();
    }

    @isTest
    static void invoice_handleInvoicingLevel(){
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity];
        System.debug('opportunities'+opportunities);
        List<Product__c> products = [SELECT Id FROM Product__c];
        //Added testing
        Account account = new Account(Name = 'test test', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R555555', SapCode__c='test2123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR0909999999', Siret__c = '9991999999999', Siren__c='115656789');
        insert account;
        BillingEntity__c be =  new BillingEntity__c(Name = 'Relevanc', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be;
        BillingEntity__c be2 =  new BillingEntity__c(Name = 'Infinity Advertising', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be2;
        Contact contact = new Contact(AssistantName='Test1', AccountId = account.id,LastName='Test2');
        insert contact;
        Opportunity opp = new Opportunity(Name = 'opp test', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id, AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        insert opp;
        DocumentTemplate__c dt = new DocumentTemplate__c(isHTML__c = true, TemplateBodyHTML__c = '<div class=" bold">{{{Account.Name}}} {{{Account.Phone }}} (((BrandName__c))) (((AdresaID__c))) [[[{\"typelist\":\"table\",\"fields\":\"Name\",\"objectname\":\"Product__c\",\"lookup\":\"Opportunity__c\",\"labels\":\"Name\"}]]] [[[{\"typelist\":\"list\",\"fields\":\"Name\",\"objectname\":\"Product__c\",\"lookup\":\"Opportunity__c\",\"labels\":\"Name\"}]]] ###{"resource": "io_sign_blandineM", "path":"none", "width":"25%"}###</div>', Name='Test');
        insert dt;
        Product2 product = new Product2(Name = 'test', Type__c = 'Display', PricingModel__c = 'Prix Unitaire',  CampaignType__c = 'Open Order', isactive = true);
        product.DocumentTemplate__c = dt.Id;
        insert product;
        Product__c oppProduct = new Product__c(UnitPrice__c = 1, Package__c =product.Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Display', PricingModel__c = 'Prix Unitaire', Opportunity__c = opp.Id, TechnicalProductIds__c = product.Id, Description__c = 'TestDataFactory');
        insert oppProduct;
        Set<Id> resultIds = (new Map<Id,SObject>(opportunities)).keySet();
        Set<Id> resultIds1 = (new Map<Id,SObject>(products)).keySet();
        List<id> resultListIds = new List<id>();
        resultListIds.addall(resultIds1);
        Invoice__c inv1 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test 90', 
            Opportunity__c=opp.Id, 
            isTechFees__c = true,
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );

        insert inv1;

        Test.startTest();
        invoicing_controller.generateInsertions(opp,resultListIds);
        invoicing_controller.handleInvoicingLevel(resultIds);
        invoicing_controller.handleTechnicalFeesInvoicing(resultIds);
        invoicing_controller.deleteInvoiceItems(resultIds);
        invoicing_controller.createInsertions(resultIds);
        Test.stopTest();
    }

    @isTest
    static void invoice_createInvoiceCreditNote(){
        Test.startTest();
        Account account = new Account(Name = 'test 123', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R555555', SapCode__c='test2123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR0909999999', Siret__c = '9991999999999', Siren__c='115656789');
        insert account;
        BillingEntity__c be =  new BillingEntity__c(Name = 'Relevanc', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be;
        BillingEntity__c be2 =  new BillingEntity__c(Name = 'Infinity Advertising', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be2;
        
        Contact contact = new Contact(AssistantName='Test1 34', AccountId = account.id,LastName='Test2');
        insert contact;
        
        Opportunity opp = new Opportunity(Name = 'opp test 89', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id,	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        Opportunity opp2 = new Opportunity(Name = 'opp test 90', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be2.Id,	AdvertiserContact__c=contact.id ,AgencyContact__c = contact.id);
        
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(opp);
        oppList.add(opp2);
        insert oppList;

        BillingEntity__c billingEntity = [SELECT Id FROM BillingEntity__c LIMIT 1];
        Invoice__c inv1 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test 90', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );

        insert inv1;

        List<Invoice__c> invoices = [SELECT Id, Opportunity__c, Account__c FROM Invoice__c];
        Set<Id> resultIds = (new Map<Id,SObject>(invoices)).keySet();
        invoicing_controller.createInvoiceCreditNote(resultIds);
        invoicing_controller.createCreditNote(invoices);
        Test.stopTest();
    }

    @isTest
    static void updateProformaTest(){
        Set<Id> oppIds = new Set<Id>();

        Test.startTest();
        Account account = new Account(Name = 'test test', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R555555', SapCode__c='test2123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR0909999999', Siret__c = '9991999999999', Siren__c='115656789');
        insert account;
        BillingEntity__c be =  new BillingEntity__c(Name = 'Relevanc', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be;
        BillingEntity__c be2 =  new BillingEntity__c(Name = 'Infinity Advertising', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be2;
        
        Contact contact = new Contact(AssistantName='Test1', AccountId = account.id,LastName='Test2');
        insert contact;
        
        Opportunity opp = new Opportunity(Name = 'opp test', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id,	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        Opportunity opp2 = new Opportunity(Name = 'opp test2', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be2.Id,	AdvertiserContact__c=contact.id ,AgencyContact__c = contact.id);
        
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(opp);
        oppList.add(opp2);
        insert oppList;

        oppIds.add(oppList[0].Id);
        oppIds.add(oppList[1].Id);

        Invoice__c inv1 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test1', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );

        Invoice__c inv2 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test1', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            isTechFees__c = true,
            Status__c = 'draft'
        );

        Invoice__c inv3 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test2', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            isTechFees__c = false,
            Status__c = 'draft'
        );

        List<Invoice__c> invList = new List<Invoice__c>();
        invList.add(inv1);
        invList.add(inv2);
        invList.add(inv3);
        insert invList;

        DocumentTemplate__c dt = new DocumentTemplate__c(isHTML__c = true, TemplateBodyHTML__c = '<div class=" bold">{{{Account.Name}}} {{{Account.Phone }}} (((BrandName__c))) (((AdresaID__c))) [[[{\"typelist\":\"table\",\"fields\":\"Name\",\"objectname\":\"Product__c\",\"lookup\":\"Opportunity__c\",\"labels\":\"Name\"}]]] [[[{\"typelist\":\"list\",\"fields\":\"Name\",\"objectname\":\"Product__c\",\"lookup\":\"Opportunity__c\",\"labels\":\"Name\"}]]] ###{"resource": "io_sign_blandineM", "path":"none", "width":"25%"}###</div>', Name='Test');
        insert dt;

        Product2 prod1 = new Product2(Name = 'test1', Type__c = 'Display', PricingModel__c = 'Prix Unitaire',  CampaignType__c = 'Open Order', isactive = true);
        prod1.DocumentTemplate__c = dt.Id;
        insert prod1;

        Product2 prod2 = new Product2(Name = 'test2', Type__c = 'Frais technique', PricingModel__c = 'Prix Unitaire',  CampaignType__c = 'Open Order', isactive = true);
        prod2.DocumentTemplate__c = dt.Id;
        insert prod2;

        Product__c oppProduct = new Product__c(UnitPrice__c = 1, Package__c =prod1.Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Display', PricingModel__c = 'Prix Unitaire', Opportunity__c = oppList[0].Id, TechnicalProductIds__c = prod1.Id, Description__c = 'TestDataFactory');
        insert oppProduct;

        Insertion__c ins1= new Insertion__c( Opportunity__c = oppList[0].Id, OpportunityProduct__c = oppProduct.id, product__c = prod1.Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today() ,Status__c='	Signé');
		insert ins1;

        Insertion__c ins2= new Insertion__c( Opportunity__c = oppList[0].Id, OpportunityProduct__c = oppProduct.id, product__c = prod2.Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé');
		insert ins2;
        invoicing_controller.updateProforma(oppIds);
        invoicing_controller.getAvailableInvoice(invList ,ins1, 'Campagne');
        invoicing_controller.getAvailableInvoice(invList ,ins1, 'Contrat');
        invoicing_controller.getAvailableInvoice(invList ,ins2, 'Campagne');
        invoicing_controller.getAvailableInvoice(invList ,ins2, 'Contrat');
        invoicing_controller.getAvailableInvoice(invList ,ins2, 'io');

        // invoicing_validator.validatorRequest request = new invoicing_validator.validatorRequest();
        // request.billingEntity = be.Id;
        // request.invoiceId = invList[1].Id;

        // List<invoicing_validator.validatorRequest> requests = new List<invoicing_validator.validatorRequest>{request};

        // invoicing_validator validator = new invoicing_validator();
        // invoicing_validator.send(requests);
        Test.stopTest();
    }
}