@isTest 
class io_test { 

    @testSetup 
    static void setup() {
        BillingEntity__c billEnt = (BillingEntity__c)TestApexDataFactory.createSObject('BillingEntity__c', new Map<String,Object>{
            'Name' => 'Infinity Advertising'
        });
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
        
        Opportunity opportunity = (Opportunity)TestApexDataFactory.createSObject('Opportunity', new Map<String,Object>{
        	'BillingEntity__r'	=> new Map<String,Object>{
             	'Name' => 'Relevanc'
             },
        	'CampaignStartDate__c'	=> Date.newInstance(2022, 5, 17),
        	'CampaignEndDate__c'	=> Date.newInstance(2022, 5, 25),
        	'AdvertiserContact__r'	=> new Map<String,Object>{
             	'LastName' => 'Contact Advertiser'
            },
        	'AgencyContact__r'	=> new Map<String,Object>{
             	'LastName' => 'Contact Agence'
            },
        	'CustomerReference__c'	=> 'RefClient',
        	'CloseDate'	=> Date.newInstance(2022, 5, 20),
        	'StageName' => 'Proposition push',
        	'Name'	=> 'TestOpp'
        });
        
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

        Product2 product = (Product2)TestApexDataFactory.createSObject('Product2', new Map<String,Object>{
			'Name'	=> 'test',     
            'Type__c'	=> 'Display', 
            'PricingModel__c'	=> 'Prix Unitaire', 
            'Category__c' 	=> 'CRM', 
            'BU__c'	=> 'ESPPUBALIMENTAIR', 
            'CampaignType__c'	=> 'Open Order',
            'isactive'	=> true
        });
       
        Document document = (Document)TestApexDataFactory.createSObject('Document', new Map<String,Object>{
        	'body'	=> Blob.valueOf('a'),
            'folderid'	=> user.Id,
            'name'	=> 'a.txt'
        });
        
        InfinityExportNumber__c provisionNumber = (InfinityExportNumber__c)TestApexDataFactory.createSObject('InfinityExportNumber__c', new Map<String,Object>{
        	'counter__c'	=> 1,
            'linecounter__c' => 1
        });
                
		List<Contact> contacts = TestApexDataFactory.createSObjectList('Contact', new Map<String,Object>{
        	'LastName'	=> new List<String>{'Contact Agence', 'Contact Advertiser'}
        }, 2);

        List<Insertion__c> insertions = TestApexDataFactory.createSObjectList('Insertion__c', new Map<String,Object>{
            'Opportunity__c' => opportunity.Id,
            'Product__c'	=> product.Id,
            'CampaignNumber__c'	=> '1',
            'StartDate__c' => Date.newInstance(2022, 5, 10),
            'EndDate__c' => Date.newInstance(2022, 5, 25)
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
                'BU__c'			=> 'ESPPUBALIMENTAIR',
                'advertiser__r'	=> new Map<String,Object>{
                	'Name'	=> 'Advertisername',
                    'BillingStreet'	=> 'Montée de la bonne mère',
                      'BillingPostalCode'	=> '13006',
                      'BillingCity'	=> 'Marseille',
                      'BillingCountryCode' => 'FR',
                      'BillingCountry'	=> 'France',
                      'Type'	=> 'Annonceur',
                      'GenerixCode__c'=> 'GNX77390',
                      'SapCode__c'	=> 'SAP72740',
                      'IntracomVatNumber__c'	=> 'FR17371231234',
                      'Siret__c'	=> '99799999999788',
                      'Siren__c'	=> '173456779'
                }
            }
        });
    }
    
    @isTest
    static void test_getProducts() {
        io_controller.getProducts('ESPPUBCAPTIF');
    }
    
    static testmethod void test_getUserProfile() {
        io_controller.getUserProfile();    
    }
    
    
    static testmethod void test_getFilters() {
        io_controller.getFilters();    
    }
    
     static testmethod void test_getStatsPromoValues() {
        io_controller.getStatsPromoValues();    
    }
    
     static testmethod void test_getBrandNameValues() {
        io_controller.getBrandNameValues();    
    }
    
    /**  Class.io_test.test_oppTrigger: line 145, column 1                                                                                                                                                             2101        
     *   System.DmlException: Update failed. First exception on row 0 with id 0063N00000FNqbbQAD; 
     *   first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Un Signé doit être ajouté dans les fichiers de l'opportunité: []  
    static testmethod void test_oppTrigger() {
        //Given
        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        op.StageName = 'Signé';
        update op;
        Test.stopTest();
    }
    */
    
    
    static testmethod void test_save() {
        //Given
        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];

        //When
        io_controller.save(op.Id, 'namePrefix', 'io_pdf');
    }
    
    
    static testmethod void test_getOppInsertions() {
        //Given
        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];

        //When
        io_controller.getOppInsertions(op.id);
    }
    
    static testmethod void test_updateInsertions() {
        io_controller.updateInsertions(JSON.serialize([select Id,StartDate__c,EndDate__c,volume__c,revenue__c,Status__c,OpportunityProduct__c,Opportunity__c,Product__c, CampaignNumber__c, OrderReference__c,
                OpportunityProduct__r.Name,OpportunityProduct__r.UnitPrice__c,OpportunityProduct__r.PricingModel__c, NewInsertion__c,
                product__r.Devices__c, product__r.Targeting__c,product__r.Medium__c,product__r.Type__c,product__r.PricingModel__c,canDelete__c,UnitPrice__c, Free__c from insertion__c LIMIT 2]));
    }
    
    static testmethod void test_cloneWithProducts() {
        //Given
        Opportunity op = [SELECT Id FROM Opportunity LIMIT 1];

        //When
        io_controller.cloneWithProducts(op.id,'Name,AccountId,Agency__c,BU__c,Targeting__c,SpecialConditions__c,AgencyContact__c,AdvertiserContact__c,BillingEntity__c,InvoicingMode__c,ioObservations__c,InvoicedAccount__c,CustomerReference__c ',date.today(),date.today());
    }
}