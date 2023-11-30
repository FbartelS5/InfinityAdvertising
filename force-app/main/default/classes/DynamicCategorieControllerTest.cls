@isTest class DynamicCategorieControllerTest {


    public static testmethod void test_getOpportunities() {

        Id recordTypeIDUnivers = Schema.SObjectType.Categorie_Reservee__c.getRecordTypeInfosByName().get('Univers').getRecordTypeId();
        Id recordTypeIDRayon = Schema.SObjectType.Categorie_Reservee__c.getRecordTypeInfosByName().get('Rayon').getRecordTypeId();


        /*DynamicCategorieController.parentwrapper pwtest = new DynamicCategorieController.parentwrapper(); 
        DynamicCategorieController.childwrapper cwtest = new DynamicCategorieController.childwrapper(); */
        
        Categorie_reservee__c categorietest = new Categorie_reservee__c();
        categorietest.Name = 'Test Categorie';
        categorietest.IsActive__c = true;
        categorietest.RecordTypeId=recordTypeIDUnivers;

        insert categorietest;

        System.debug('categorietest.RecordTypeId'+ categorietest.RecordTypeId);
        System.debug('categorietest.Id'+ categorietest.Id);

        Categorie_reservee__c categorietest1 = new Categorie_reservee__c();
        categorietest1.Name = 'Test Categorie1';
        categorietest1.IsActive__c = true;
        categorietest1.RecordTypeId=recordTypeIDRayon;
        categorietest1.Univers__c=categorietest.Id;

        insert categorietest1;


        System.debug('categorietest1.RecordTypeId'+ categorietest1.RecordTypeId);

        System.debug('categorietest1.Univers__c'+ categorietest1.Univers__c);



        DynamicCategorieController.getAllParentAccounts();
        DynamicCategorieController.getChildAccounts(categorietest.Id);
        DynamicCategorieController.getuniversedetails();



    }
}