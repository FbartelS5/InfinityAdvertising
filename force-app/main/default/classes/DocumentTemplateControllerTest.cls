@isTest class DocumentTemplateControllerTest {

    static TestDataFactory t;
    static {
        t = new TestDataFactory();
    }
    static testmethod void test_showDataController() {
        showData.getLinks(t.opp.Id);
        showData.saveDocs(t.opp.Id);
        showData.fetchURL();
    }
    
    static testmethod void test_OIDocumentController() {
        List<Opportunity> invList = new List<Opportunity>();
        invList.add(t.opp);
        ApexPages.StandardController a = new ApexPages.StandardController(t.opp);
        OIDocumentController Controller = new OIDocumentController(a);
        Test.startTest();
        OIDocumentController.getDocsToSave(t.opp.Id);
        Test.stopTest();

    }
    
    static testmethod void test_OISaveController() {
        List<Opportunity> invList = new List<Opportunity>();
        invList.add(t.opp);
        ApexPages.StandardController a = new ApexPages.StandardController(t.opp);
        OISaveController Controller = new OISaveController(a);

    }
    
    static testmethod void test_generateBody() {
        PageReference pageRef = Page.DocumentTemplatePage;
        pageRef.getParameters().put('id',t.opp.Id);
        pageRef.getParameters().put('masterObject','Opportunity');
        pageRef.getParameters().put('relatedId',t.oppProduct.Id);
        pageRef.getParameters().put('templateId',t.dt.Id);
        pageRef.getParameters().put('relatedObject','Product__c');
        
        Test.setCurrentPage(pageRef);

        
        DocumentTemplateController.getDocumentBody();
    }
    
}