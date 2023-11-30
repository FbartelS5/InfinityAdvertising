@isTest
public class faeaae_exportTest {
    @testSetup static void setup() {
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

        BillingEntity__c billEnt = (BillingEntity__c)TestApexDataFactory.createSObject('BillingEntity__c', new Map<String,Object>{
            'Name' => 'Infinity Advertising'
        });

        Account advertiser = (Account)TestApexDataFactory.createSObject('Account', new Map<String,Object>{
            'Name'	=> 'Advertisername1',
            'BillingStreet'	=> 'Montée de la bonne mère',
            'BillingCity'	=> 'Marseille',
            'BillingCountry' => 'France',
            'Siret__c'	=> 'SIRET123401615',
            'Siren__c'	=> '123156789',
            'BillingPostalCode'	=> '13006'
        });

        Product2 product = (Product2)TestApexDataFactory.createSObject('Product2', new Map<String,Object>{
			'Name'	=> 'test1',     
            'Type__c'	=> 'Display', 
            'PricingModel__c'	=> 'Prix Unitaire', 
            'Category__c' 	=> 'Animation', 
            'BU__c'	=> 'ESPPUBALIMENTAIR', 
            'CampaignType__c'	=> 'Open Order',
            'isactive'	=> true
        });
        
        Opportunity opportunity = (Opportunity)TestApexDataFactory.createSObject('Opportunity', new Map<String,Object>{
        	'BillingEntity__r'	=> new Map<String,Object>{
             	'Name' => 'Billing Entity Name'
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
            'TotalExcludingVat__c'	=> 500,
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
            'TotalExcludingVat__c'	=> 500,
            'Insertion__c'	=> insertions[0].Id,
            'Invoice__r'	=> new Map<String,Object>{
                'Account__c'	=> accounts[0].Id,
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
    
    @isTest
    public static void faeaae_exportTest() {
        List<Invoice__c> invList = [SELECT Id FROM Invoice__c];
        List<Invoice__c> schedInvList = [SELECT Id, Name, TotalWithVat__c, VAT_Amount__c, BU__c, Account__r.Centre_profit_partenaire__c, Account__r.PartnerCompany_Code__c, VatRate__c, TotalExcludingVat__c,
                    (select id, Insertion__c, TotalExcludingVat__c, Ordre_Interne__c from InvoiceItems__r)
                    FROM Invoice__c];
        
        ApexPages.StandardSetController a = new ApexPages.StandardSetController(invList);
        a.setSelected(invList);
        faeaae_export Controller = new faeaae_export(a);
        faeaae_export.exportFae();
        faeaae_export.exportAae();
        faeaae_export.exportAaeSched(schedInvList);
        faeaae_export.exportFaeSched(schedInvList);
    }
}