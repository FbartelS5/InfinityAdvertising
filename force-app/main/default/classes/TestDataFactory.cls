@isTest
public class TestDataFactory {
    public Account account;
    public Contact contact;
    public Product2 product;
    public Product2 productForecast;
    public Product2 productTech;
    public Product2 productCampaign;
    public Product__c oppProduct;
    public Product__c oppProductForecast;
    public Product__c oppProduct2;
    public Product__c oppTechProduct;
    public Product__c oppCampaignProduct;
    public Product__c oppCampaignProduct2;
    public Opportunity opp;
    public Opportunity opp2;
    public Opportunity oppTech;
    public Opportunity oppTech2;
    public Opportunity oppCampaign;
    public Opportunity oppCampaign2;
    public Insertion__c ins;
    public Insertion__c ins2;
    public Insertion__c insTech;
    public Insertion__c insTech2;
    public Insertion__c insCampaign1;
    public Insertion__c insCampaign2;
    public Insertion__c insCampaign3;
    public Insertion__c insCampaign4;
    public Insertion__c insForecast;
    public Invoice__c inv1;
    public Invoice__c inv2;
    public Invoice__c inv3;
    public Invoice__c invCamp;
    public Invoice__c invoiceValAutoFtp;
    public DocumentTemplate__c dt;
    public Document document;
    public BillingEntity__c be;
    public User myUser;
    List<Opportunity> oppList = new List<Opportunity>();
    List<Product2> pro2List = new List<Product2>();
    List<Product__c> proList = new List<Product__c>();
    List<Invoice__c> invList = new List<Invoice__c>();
    List<Insertion__c> insList = new List<Insertion__c>();


    public TestDataFactory() {
        
        Id RecordTypeIdOI = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Autres').getRecordTypeId();
        
        Profile stdProfile = [SELECT Id FROM Profile LIMIT 1];
        User myUser = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = stdProfile.Id, TimeZoneSidKey='America/Los_Angeles', UserName='standardtestuser@123testorg.com');
        insert myUser; 
        
         be =  new BillingEntity__c(Name = 'Infinity Advertising', LastInvoiceNumber__c = 1, InvoicePrefix__c = '65');
        insert be;
        
        insert new InvoiceNumber__c(counter__c = 0);
        insert new InvoiceRegulationTreshold__c(Amount__c = 1);
        dt = new DocumentTemplate__c(isHTML__c = true, TemplateBodyHTML__c = '<div class=" bold">{{{Account.Name}}} {{{Account.Phone }}} (((BrandName__c))) (((AdresaID__c))) [[[{\"typelist\":\"table\",\"fields\":\"Name\",\"objectname\":\"Product__c\",\"lookup\":\"Opportunity__c\",\"labels\":\"Name\"}]]] [[[{\"typelist\":\"list\",\"fields\":\"Name\",\"objectname\":\"Product__c\",\"lookup\":\"Opportunity__c\",\"labels\":\"Name\"}]]] ###{"resource": "io_sign_blandineM", "path":"none", "width":"25%"}###</div>', Name='Test');
        insert dt;
        
        List<AssociationDocumentTemplate__mdt> ladt = [select id, MasterLabel, Template_to_use__c,  Master_object__c, Vfp_used__c from AssociationDocumentTemplate__mdt];
		List<FTP_credentials__mdt> creds = [SELECT DeveloperName, host__c, username__c, pass__c, port__c, directory__c, endpoint__c, errorRecipient__c, reportRecipients__c
                                      FROM FTP_credentials__mdt];
        
        account = new Account(Name = 'test', BillingStreet =  '1 rue Test', BillingPostalCode = '75001', BillingCity = 'Paris', GenerixCode__c='R55555', SapCode__c='test123', BillingCountryCode = 'FR', IntracomVatNumber__c = 'FR00999999999', Siret__c = '99999999999999', Siren__c='123456789');
        insert account;

        contact = new Contact(AssistantName='Test1', AccountId = account.id,LastName='Test2');
        insert contact;
        
        opp = new Opportunity(Name = 'opp test', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id,	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        //insert opp;
       
        opp2 = new Opportunity(Name = 'opp test2', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur', BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id,	AdvertiserContact__c=contact.id ,AgencyContact__c = contact.id);
        //insert opp2;
        
        oppCampaign = new Opportunity(Name='opp testCampagne', AccountId = account.id, CloseDate = Date.today().addDays(-2), StageName = 'Proposition push',InvoicedAccount__c = 'Agence',
                                  BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id, RecordTypeId = RecordTypeIdOI, CampaignStartDate__c =Date.today().addDays(5) , CampaignEndDate__c = Date.today().addDays(8),
                                 TechnicalFeesInvoicing__c ='Agence', InvoicingLevel__c='Campagne', Agency__c=account.id,	AdvertiserContact__c=contact.id ,AgencyContact__c = contact.id);
        //insert oppCampaign;
        
        oppCampaign2 = new Opportunity(Name='opp testCampagne2', AccountId = account.id, CloseDate = Date.today().addDays(-2), StageName = 'Proposition push',InvoicedAccount__c = 'Agence',
                                  BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id, RecordTypeId = RecordTypeIdOI, CampaignStartDate__c =Date.today().addDays(5) , CampaignEndDate__c = Date.today().addDays(8),
                                 TechnicalFeesInvoicing__c ='Agence', InvoicingLevel__c='Contrat', Agency__c=account.id,	AdvertiserContact__c=contact.id ,AgencyContact__c = contact.id);
        //insert oppCampaign2;
        
        oppTech = new Opportunity(Name='opp testTech', AccountId = account.id, CloseDate = Date.today().addDays(-2), StageName = 'Proposition push',InvoicedAccount__c = 'Agence',
                                  BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id, RecordTypeId = RecordTypeIdOI, CampaignStartDate__c =Date.today().addDays(5) , CampaignEndDate__c = Date.today().addDays(8),
                                 TechnicalFeesInvoicing__c ='Agence', InvoicingLevel__c='Campagne', Agency__c=account.id,	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        //insert oppTech;
        
        oppTech2 = new Opportunity(Name='opp testTech2', AccountId = account.id, CloseDate = Date.today(), StageName = 'Proposition push',InvoicedAccount__c = 'Annonceur',
                                  BU__c = 'ESPPUBALIMENTAIR',BillingEntity__c =be.Id, RecordTypeId = RecordTypeIdOI,  CampaignStartDate__c =Date.today().addDays(5) , CampaignEndDate__c = Date.today().addDays(8),
                                 TechnicalFeesInvoicing__c ='Agence/Annonceur', InvoicingLevel__c='Contrat',	AdvertiserContact__c=contact.id,AgencyContact__c = contact.id);
        //insert oppTech2;
        

        oppList.add(opp);
        oppList.add(opp2);
        oppList.add(oppCampaign);
        oppList.add(oppCampaign2);
        oppList.add(oppTech);
        oppList.add(oppTech2);
        
        insert oppList;
        
        product = new Product2(Name = 'test', Type__c = 'Display', PricingModel__c = 'Prix Unitaire',  CampaignType__c = 'Open Order', isactive = true);
        product.DocumentTemplate__c = dt.Id;
        //insert product;
        
        
        productForecast = new Product2(Name = 'test', Type__c = 'Display', PricingModel__c = 'Prix Unitaire', CampaignType__c = 'Ordre d\'insertion', isactive = true);
        productForecast.DocumentTemplate__c = dt.Id;
        //insert productForecast;
        
        productTech = new Product2(Name = 'test', Type__c = 'Frais technique', PricingModel__c = 'Prix Unitaire',  CampaignType__c = 'Open Order', isactive = true);
        productTech.DocumentTemplate__c = dt.Id;
        //insert productTech;
        
        productCampaign = new Product2(Name = 'test', Type__c = 'Data', PricingModel__c = 'Prix Unitaire', CampaignType__c = 'Open Order', isactive = true);
        productCampaign.DocumentTemplate__c = dt.Id;
        //insert productCampaign;
        
        //insert new Product2(Name = 'régule test', Type__c = 'Régule', PricingModel__c = 'Forfait', Category__c = 'Régule', Medium__c = 'Infinity Advertising',isactive = true);

        pro2List.add(product);
        pro2List.add(productForecast);
        pro2List.add(productTech);
        pro2List.add(productCampaign);
        
        insert pro2List;
        
        oppProduct = new Product__c(UnitPrice__c = 1, Package__c =pro2List[0].Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Display', PricingModel__c = 'Prix Unitaire', Opportunity__c = oppList[0].Id, TechnicalProductIds__c = pro2List[0].Id, Description__c = 'TestDataFactory');
        //insert oppProduct;
        
        oppProductForecast = new Product__c(UnitPrice__c = 500, Package__c =pro2List[1].Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today().addMonths(1), Type__c = 'Display', PricingModel__c = 'Prix Unitaire',  Opportunity__c = oppList[0].Id, TechnicalProductIds__c = pro2List[1].Id, Description__c = 'TestDataFactory');
        //insert oppProductForecast;
        
        oppProduct2 = new Product__c(UnitPrice__c = 1, Package__c =pro2List[0].Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Display', PricingModel__c = 'Prix Unitaire', Opportunity__c = oppList[1].Id, TechnicalProductIds__c = pro2List[0].Id, Description__c = 'TestDataFactory');
        //insert oppProduct2;
        
        oppTechProduct = new Product__c(UnitPrice__c = 1, Package__c =pro2List[2].Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Frais technique', PricingModel__c = 'Prix Unitaire', Opportunity__c = oppList[2].Id, TechnicalProductIds__c = pro2List[2].Id, Description__c = 'TestDataFactory');
        //insert oppTechProduct;
        
        oppCampaignProduct = new Product__c(UnitPrice__c = 1, Package__c =pro2List[3].Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Data', PricingModel__c = 'Prix Unitaire',  Opportunity__c = oppList[4].Id, TechnicalProductIds__c = pro2List[3].Id, Description__c = 'TestDataFactory');
        //insert oppCampaignProduct;
        
        oppCampaignProduct2 = new Product__c(UnitPrice__c = 1, Package__c =pro2List[3].Id, Quantity__c = 1, StartDate__c = Date.today(), EndDate__c = Date.today(), Type__c = 'Data', PricingModel__c = 'Prix Unitaire',  Opportunity__c = oppList[5].Id, TechnicalProductIds__c = pro2List[3].Id, Description__c = 'TestDataFactory');
        //insert oppCampaignProduct2;

        proList.add(oppProduct);
        proList.add(oppProductForecast);
        proList.add(oppProduct2);
        proList.add(oppTechProduct);
        proList.add(oppCampaignProduct);
        proList.add(oppCampaignProduct2);
       
        insert proList;
        
        Invoice__c inv1 =  new Invoice__c(Account__c = account.Id, Name='test', Opportunity__c=opp.Id, InvoiceDate__c=System.today());
        //insert inv1;
        inv2= new Invoice__c(Account__c = account.Id, Name='test Fac2', Opportunity__c=opp.Id, OriginalInvoiceNumber__c=inv1.Id, InvoiceDate__c=System.today());
        //insert inv2;
        
        inv3= new Invoice__c(Status__c = 'validated', Account__c = account.Id, Name='test Fac Tech', Opportunity__c=oppTech.Id, InvoiceDate__c=System.today());
        //insert inv3;
        
        invCamp= new Invoice__c(Status__c = 'validated', Account__c = account.Id, Name='test Fac Campagne', Opportunity__c=oppCampaign.Id, InvoiceDate__c=System.today());
        //insert invCamp;

        invoiceValAutoFtp= new Invoice__c(Status__c = 'draft', Account__c = account.Id, Name='test Validation Auto', SentInvoice__c= false, Opportunity__c=oppTech.Id, InvoiceDate__c=System.today());
        //insert invoiceValAutoFtp;

        invList.add(inv1);
        invList.add(inv2);
        invList.add(inv3);
        invList.add(invCamp);
        invList.add(invoiceValAutoFtp);
       
        insert invList;

        ins= new Insertion__c( Opportunity__c = oppList[0].Id, OpportunityProduct__c = proList[0].id, product__c = pro2List[0].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé');
		//insert ins;
        
        ins2= new Insertion__c( Opportunity__c = oppList[1].Id, OpportunityProduct__c = proList[2].id, product__c = pro2List[0].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé');
		//insert ins2;
        
        insTech= new Insertion__c( Opportunity__c = oppList[2].Id, OpportunityProduct__c = proList[3].id, product__c = pro2List[2].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé', CampaignNumber__c='123',volume__c=1, Revenue__c=5);
		//insert insTech;
        
        insTech2= new Insertion__c( Opportunity__c = oppList[2].Id, OpportunityProduct__c = proList[3].id, product__c = pro2List[2].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé', CampaignNumber__c='456',volume__c=1, Revenue__c=5);
		//insert insTech2;
        
        insCampaign1= new Insertion__c( Opportunity__c = oppList[4].Id, OpportunityProduct__c = proList[4].id, product__c = pro2List[0].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé', CampaignNumber__c='123',volume__c=1, Revenue__c=5);
		//insert insCampaign1;
        
        insCampaign2= new Insertion__c( Opportunity__c = oppList[4].Id, OpportunityProduct__c = proList[4].id, product__c = pro2List[0].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé', CampaignNumber__c='456',volume__c=1, Revenue__c=5);
		//insert insCampaign2;
        
        insCampaign3= new Insertion__c( Opportunity__c = oppList[5].Id, OpportunityProduct__c = proList[5].id, product__c = pro2List[0].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé', CampaignNumber__c='123',volume__c=1, Revenue__c=5);
		//insert insCampaign3;
        
        insCampaign4= new Insertion__c( Opportunity__c = oppList[5].Id, OpportunityProduct__c = proList[5].id, product__c = pro2List[0].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé', CampaignNumber__c='456',volume__c=1, Revenue__c=5);
		//insert insCampaign4;
        
        insForecast = new Insertion__c( Opportunity__c = oppList[0].Id, OpportunityProduct__c = proList[1].id, product__c = pro2List[1].Id, UnitPrice__c = 1, EndDate__c= Date.today(), StartDate__c=Date.today(), Status__c='	Signé');
		//insert insForecast;

        insList.add(ins);
        insList.add(ins2);
        insList.add(insTech);
        insList.add(insTech2);
        insList.add(insCampaign1);
        insList.add(insCampaign2);
        insList.add(insCampaign3);
        insList.add(insCampaign4);
        insList.add(insForecast);

        for(integer i=0;i<9;i++)
        {
        system.debug('Insertion List'+insList[i].Opportunity__c+' and' +insList[i].OpportunityProduct__c);
        }
  
        insert insList;

        
        document = new Document(body = Blob.valueOf('a'),folderid = myUser.Id,name = 'a.txt');
        
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = EncodingUtil.base64Decode('aGVsbG8=');
        cv.Title = 'test';
        cv.PathOnClient = 'test';
        insert cv;
        
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv.Id].ContentDocumentId;
        cdl.LinkedEntityId = opp.id;
        cdl.ShareType = 'V';
        insert cdl;
        
        ContentVersion cv2 = new ContentVersion();
        cv2.ContentLocation = 'S';
        cv2.VersionData = EncodingUtil.base64Decode('aGVsbG8=');
        cv2.Title = 'test';
        cv2.PathOnClient = 'test';
        insert cv2;
        
        ContentDocumentLink cdl2 = new ContentDocumentLink();
        cdl2.ContentDocumentId = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: cv2.Id].ContentDocumentId;
        cdl2.LinkedEntityId = opp2.Id;
        cdl2.ShareType = 'V';
        insert cdl2;

    }
}