@isTest
public class AaeBatchExportTest {
    // static TestDataFactory t;
    // static { t = new TestDataFactory(); }
    
    /*
    @testSetup static void setup() {
        List<Account> accounts = TestApexDataFactory.createSObjectList('Account', new Map<String,Object>{
            'Name' => new List<String>{'test', 'testAgence', 'testAdvertiser'},
                'BillingStreet'	=> 'Montée de la bonne mère',
                'BillingPostalCode'	=> '13006',
                'BillingCity'	=> 'Marseille',
                'BillingCountryCode' => 'FR',
                'Type'	=> new List<String>{'Adex', 'Adex', 'Annonceur'},
                    'GenerixCode__c'=> new List<String>{'R55555', 'GNX1234', 'GNX12340'},
                        'SapCode__c'	=> new List<String>{'test123', 'SAP1234', 'SAP12340'},
                            'IntracomVatNumber__c'	=> new List<String>{'FR00999999999', 'FR12341231234', 'FR12341231234'},
                                'Siret__c'	=> new List<String>{'99999999999999', 'SIRET123401235', 'SIRET123401234'},
                                    'Siren__c'	=> '123456789'
                                    }, 3);
        
        Product2 product = (Product2)TestApexDataFactory.createSObject('Product2', new Map<String,Object>{
            'Name'	=> 'test',     
                'Type__c'	=> 'Display', 
                'PricingModel__c'	=> 'Prix Unitaire', 
                'Category__c' 	=> 'Animation', 
  //              'BU__c'	=> 'ESPPUBCAPTIF', 
                'CampaignType__c'	=> 'Open Order',
                'isactive'	=> true
                });

        BillingEntity__c billEnt = (BillingEntity__c)TestApexDataFactory.createSObject('BillingEntity__c', new Map<String,Object>{
            'Name' => 'Infinity Advertising'
        });
        
        Opportunity opportunity = (Opportunity)TestApexDataFactory.createSObject('Opportunity', new Map<String,Object>{
            'BillingEntity__r'	=> new Map<String,Object>{
                'Name' => 'Relevanc'
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
                                                'Name'	=> 'TestOpp'
                                                });
        
        List<Insertion__c> insertions = TestApexDataFactory.createSObjectList('Insertion__c', new Map<String,Object>{
            'Opportunity__c' => opportunity.Id,
                'Product__c'	=> product.Id,
                'CampaignNumber__c'	=> '1',
                'StartDate__c' => Date.newInstance(2010, 3, 17),
                'EndDate__c' => Date.newInstance(2010, 3, 18)
                }, 3);
        
        InvoiceItem__c mainInvoiceItem = (InvoiceItem__c)TestApexDataFactory.createSObject('InvoiceItem__c', new Map<String,Object>{
            'Quantity__c'	=> 50,
                'Product__c'	=> product.Id,
                'Insertion__c'	=> insertions[0].Id,
                'TotalExcludingVat__c' => -50000,
                'Invoice__r'	=> new Map<String,Object>{
                    'Account__c'	=> accounts[0].Id,
                        'Name'	=>	'test',
                        'Opportunity__c'	=> opportunity.Id,
                        'InvoiceDate__c'	=> System.today(),
                        'Status__c'			=> 'draft'
                        }
        });
        
        List<InvoiceItem__c> invoiceItems = TestApexDataFactory.createSObjectList('InvoiceItem__c', new Map<String,Object>{
            'Quantity__c'	=> 50,
                'Product__c'	=> product.Id,
                'Insertion__c'	=> insertions[0].Id,
                'TotalExcludingVat__c' => -50000,
                'Invoice__r'	=> new Map<String,Object>{
                    'Account__c'	=> accounts[0].Id,
                        'Name'	=>	'test Fac {!index}',
                        'Opportunity__c'	=> opportunity.Id,
                        'InvoiceDate__c'	=> System.today(),
                        'Status__c'			=> 'draft',
                        'OriginalInvoiceNumber__c'	=> mainInvoiceItem.Invoice__r.Id
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
        
        ProvisionNumber__c provisionNumber = (ProvisionNumber__c)TestApexDataFactory.createSObject('ProvisionNumber__c', new Map<String,Object>{
            'counter__c'	=> 1
                });
        
        List<Contact> contacts = TestApexDataFactory.createSObjectList('Contact', new Map<String,Object>{
            'LastName'	=> new List<String>{'Contact Agence', 'Contact Advertiser'}
        }, 2);
    }
    */
    
    static testMethod void testMethod1(){
        
        Test.startTest();
        Account account = new Account(Name = 'test', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R55555', SapCode__c='test123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR00999999999', Siret__c = '99999999999999', Siren__c='123456789');
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
        
        Invoice__c inv1 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test1', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );

        Invoice__c inv2 =  new Invoice__c(
            Account__c = account.Id, 
            Name='test', 
            Opportunity__c=oppList[0].Id, 
            InvoiceDate__c=System.today(),
            Status__c = 'draft'
        );

        List<Invoice__c> invList = new List<Invoice__c>();
        invList.add(inv1);
        invList.add(inv2);
        insert invList;
        invList[1].OriginalInvoiceNumber__c = invList[0].Id;
        update invList;
        
        AaeBatchExport batch = new AaeBatchExport();
        Id batchId = Database.executeBatch(batch);
        
        AaeBatchExport schedule = new AaeBatchExport();
        System.schedule('test','0 0 8 13 2 ?', schedule);
        Id batchJobId = Database.executeBatch(new AaeBatchExport(), 8);
        Test.stopTest();
    }
}