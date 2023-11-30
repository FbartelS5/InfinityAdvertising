@isTest
public class invoice_export_test {
   @testSetup static void setup() {
  
      BillingEntity__c testabc= new BillingEntity__c();
      testabc.Name='Infinity Advertising';
      testabc.LastInvoiceNumber__c=4;
      insert testabc;


      /*  BillingEntity__c billEnt = (BillingEntity__c)TestApexDataFactory.createSObject('BillingEntity__c', new Map<String,Object>{
            'Name' => 'Infinity Advertising'
            
        });
        */

        List<Account> accounts = TestApexDataFactory.createSObjectList('Account', new Map<String,Object>{
          'Name' => new List<String>{'test12', 'testAgence', 'testAdvertiser'},
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
          'Siren__c'	=> '123456780'
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

        /*
        Invoice__c invoiceent = (Invoice__c)TestApexDataFactory.createSObject('Invoice__c', new Map<String,Object>{
            'Name' => 'Infinity Advertising'
        });
        */
        
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
            //'Category__c' 	=> 'PLV', 
            //'BU__c'	=> 'ESPPUBALIMENTAIR', 
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
                'Name'	=>	'test1',
                'Opportunity__c'	=> opportunity.Id,
                'InvoiceDate__c'	=> System.today(),
                'BU__c'			=> 'ESPPUBALIMENTAIR',
                'advertiser__r'	=> new Map<String,Object>{
                'Name'	=> 'Advertisername8',
                'BillingStreet'	=> 'Montée de la bonne mère',
                'BillingPostalCode'	=> '13006',
                'BillingCity'	=> 'Marseille',
                'BillingCountryCode' => 'FR',
                'BillingCountry'	=> 'France',
                'Type'	=> 'Annonceur',
                'BillingStreet'	=> 'Montée de la bonne mère',
                'GenerixCode__c'=> 'GNX77390',
                'SapCode__c'	=> 'SAP72740',
                'IntracomVatNumber__c'	=> 'FR17371231234',
                'Siret__c'	=> 'SIRET123409235',
                'Siren__c'	=> '171456323'
                }
            }
        });
    }
 
    @isTest
    public static void test_queryInvoiceExportFields() {
        //Given
        Set<Id> invoiceIds = (new Map<Id, Invoice__c>([SELECT Id FROM Invoice__c])).keySet();
        
        //When
        Test.startTest();
        List<Invoice__c> result = invoice_export.queryInvoiceExportFields(invoiceIds);
        Test.stopTest();
    }
    
    
    @isTest
    public static void test_exportInfinitySched() {
        //Given
        List<Invoice__c> li = invoice_export.queryInvoiceExportFields((new Map<Id, Invoice__c>([SELECT Id FROM Invoice__c])).keySet());
        
        //When
        Test.startTest(); 
        Document result = invoice_export.exportInfinitySched(li);
        Test.stopTest();
        
        //Then
        System.assertEquals(true, result != null); 
    }
    
    /*
    * System.DmlException: Update failed. First exception on row 0 with id a0O3N000002n6FRUAY; first error: 
    * CANNOT_EXECUTE_FLOW_TRIGGER, Nous ne pouvons pas sauvegarder cet enregistrement, car le processus 
    * « Invoice validation » a échoué. Contactez votre administrateur Salesforce avec ces détails. An Apex 
    * error occurred: System.NullPointerException: Attempt to de-reference a null object

    @isTest
    public static void test_exportInfinity() {
        //Given
        List<Invoice__c> li = invoice_export.queryInvoiceExportFields((new Map<Id, Invoice__c>([SELECT Id FROM Invoice__c])).keySet());
        for(Invoice__c i : li){
           i.Status__c = 'validated';
           i.bu__c = 'ESPPUBALIMENTAIR';  
        } 
        update li;
        ApexPages.StandardSetController a = new ApexPages.StandardSetController(li);
        a.setSelected(li);
        invoice_export Controller = new invoice_export(a);
        
        //When
        Test.startTest();
        invoice_export.exportInfinity();
        Test.stopTest();
    }
    */

    @isTest
    public static void test_exportToMail() {
        //Given
        Set<Id> docId = (new Map<Id, Document>([SELECT Id FROM Document])).keySet();
        
        //When
        Test.startTest();
        invoice_export.exportToMail(docId);
        Test.stopTest();
        
        //Then
        // ?
    }    

    @isTest
    public static void test_queue() {
        //Given
        User u = [SELECT Id FROM User LIMIT 1];
        Document d = new Document(
            Body=Blob.valueOf('test'),
            FolderId=u.Id,
            Name = 'TEST.TXT'
        );

        //When
        Test.startTest();
        System.enqueueJob(new invoice_export_queue(new List<Document>{d}));
        Test.stopTest();
        
        //Then
        // ?
    }    


    @isTest
    public static void test_batch_empty() {
        //When
        Test.startTest();
        Database.executeBatch(new invoice_export_batch());
        Test.stopTest();
        
        //Then
        // ?
    }    

    
    @isTest
    public static void test_batch() {
        //Given
        Invoice__c invoice = [SELECT Id FROM Invoice__c LIMIT 1];
        system.debug('invoice'+invoice);
        invoice.Status__c = 'validated';
        invoice.SentInvoice__c = false;
        update invoice;
       
        //When
        Test.startTest();
        Database.executeBatch(new invoice_export_batch());
        Test.stopTest();
        
        //Then
        // ?
    } 
    
       
}