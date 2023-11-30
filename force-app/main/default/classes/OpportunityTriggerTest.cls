@isTest
global class OpportunityTriggerTest {
    @testSetup
    static void setup() {
        insert new BillingEntity__c(Name = 'Infinity Advertising');
    }

    @isTest
    static void test_Sales() {
        //Given
        Account acc = (Account) TestApexDataFactory.createSObject(
            'Account',
            new Map<String, Object>{
                'Name' => 'Acc Name',
                'BillingCountry' => 'France',
                'BillingStreet'	=> 'Montée de la bonne mère',
                'BillingPostalCode'	=> '13006',
                'BillingCity'	=> 'Marseille',
                'BillingCountry' => 'France',
                'BillingCountryCode' => 'FR',
                'Type'	=> 'Annonceur',
                'GenerixCode__c'=> 'GNX12340',
                'SapCode__c'	=> 'SAP12340',
                'IntracomVatNumber__c'	=> 'FR12341231234',
                'Siret__c'	=> 'SIRET123401234',
                'Siren__c'	=> '123456789'
            }
        );

        //When
        Test.startTest();        
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
        Test.stopTest();
    }
}