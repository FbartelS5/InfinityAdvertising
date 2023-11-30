@isTest 
class invoice_service_TEST {
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
                'Name' => 'Infinity Advertising'
            },
            'CampaignStartDate__c'	=> Date.newInstance(2020, 2, 17),
            'CampaignEndDate__c'	=> Date.newInstance(2020, 2, 25),
            'AdvertiserContact__r'	=> new Map<String,Object>{
                'AccountId' => accounts[1].Id,
                'LastName' => 'Contact Advertiser',
                'Email'	=> 'test1@test.com',
                'Admin_contact__c' => true
            },
            'AgencyContact__r'	=> new Map<String,Object>{
                'AccountId' => accounts[2].Id,
                'LastName' => 'Contact Agence',
                'Email'	=> 'test@test.com',
                'Admin_contact__c' => true
            },
            'Agency__r' => accounts[0],
            'CustomerReference__c'	=> 'RefClient',
            'CloseDate'	=> Date.newInstance(1960, 2, 17),
            'StageName' => 'Proposition push',
            'Name'	=> 'TestOpp'
        });
        
        List<Insertion__c> insertions = TestApexDataFactory.createSObjectList('Insertion__c', new Map<String,Object>{
            'Opportunity__c' => opportunity.Id,
            'Product__c'	=> product.Id,
            'CampaignNumber__c'	=> '1',
            'StartDate__c ' => Date.newInstance(2020, 2, 17),
            'EndDate__c ' => Date.newInstance(2020, 2, 17)
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
                'advertiser__c'	=> advertiser.Id,
                'agency__c'	=> accounts[1].Id
            }
        });

        List<InvoiceItem__c> invoiceItems = TestApexDataFactory.createSObjectList('InvoiceItem__c', new Map<String,Object>{
            'Quantity__c'	=> 50,
            'Product__c'	=> product.Id,
            'Insertion__c'	=> insertions[0].Id,
            'Invoice__r'	=> new Map<String,Object>{
                'Account__c'	=> accounts[1].Id,
                'Name'	=>	'test Fac {!index}',
                'Opportunity__c'	=> opportunity.Id,
                'InvoiceDate__c'	=> System.today(),
                'OriginalInvoiceNumber__c'	=> mainInvoiceItem.Invoice__r.Id,
                'advertiser__c'	=> advertiser.Id,
                'agency__c'	=> accounts[1].Id
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

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode('aGVsbG8=');
        cv.Title = 'test';
        cv.PathOnClient = 'test';
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = invoiceItems[0].Invoice__r.id;
        cdl.ShareType = 'V';
        insert cdl;
    }

    @isTest
    static void test_savePDF() {
        Invoice__c inv = [SELECT Id FROM Invoice__c LIMIT 1];
        system.debug('inv'+inv);
        Test.startTest();
        invoice_service.savePDF(inv.Id);
        Test.stopTest();
    }

    
    @isTest
    static void test_sendEmail() {
        //Given
        List<Invoice__c> invoices = [SELECT Id FROM Invoice__c];
        String templateName = [SELECT Id, Name FROM EmailTemplate LIMIT 1].Name;
        String result;
        List<Id> invoiceIds = new List<Id>();
        for(Invoice__c inv : invoices){
            invoiceIds.add(inv.Id);
        }
        //When
        Test.startTest();
        try {
            invoice_service.sendEmail(templateName, invoiceIds);
            invoice_service.sendEmail(templateName, invoiceIds, 'agency');
            invoice_service.sendEmail(templateName, invoiceIds, 'advertiser');
            invoice_service.sendEmail(templateName, invoiceIds, 'test');
        } catch (invoice_service.sendEmailException e) {
            result = e.getMessage();
        }
        
        Test.stopTest();
    }
}