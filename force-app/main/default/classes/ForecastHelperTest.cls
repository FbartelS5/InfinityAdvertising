@isTest class ForecastHelperTest {
    static TestDataFactory t;
    static { t = new TestDataFactory(); }
    static testmethod void test_all() {
        User myUser = [SELECT Id FROM User LIMIT 1];
        ForecastHelper.getUserInfo(myUser.Id);
        Forecast__c forecast = new Forecast__c();
        forecast.BU__c = 'ESPPUBALIMENTAIR';
        forecast.Month__c = 'Août';
        forecast.Year__c = '2020';
        insert forecast;
        
        Forecast_Item__c fItem = new Forecast_Item__c();
        fItem.Block__c = true;
        fItem.Forecast__c = forecast.Id;
        fItem.Product__c = t.oppProductForecast.Id;
        fItem.Revenue__c = 15;
        insert fItem;
        
        Forecast_Item__c foreItem = new Forecast_Item__c();
        foreItem.Block__c = false;
        foreItem.Forecast__c = forecast.Id;
        foreItem.Product__c = t.oppProductForecast.Id;
        foreItem.Revenue__c = 30;
        insert foreItem;

        Product2 protest= new Product2();
        protest.Name='Testpro';
        protest.Type__c='Régule';
        protest.Medium__c='Infinity Advertising';
        insert protest;
        
        Insertion__c myIns = [SELECT Id, opportunity__r.Id FROM Insertion__c WHERE OpportunityProduct__c =: t.oppProductForecast.Id LIMIT 1];
        myIns.Status__c = 'Clôturé';
        myIns.Revenue__c = 50;
        myIns.OpportunityProduct__c = t.oppProductForecast.Id;
        update myIns;

        Set<Id> insertionsIds = new Set<Id>();
        insertionsIds.add(myIns.Id);
        List<Product__c> productsList = new List<Product__c>();
        productsList.add(t.oppProductForecast);
        Set<Id> insClosedToSigned = new Set<Id>();
        insClosedToSigned.add(myIns.Id);
        invoicing_controller.deleteInvoiceItems(insClosedToSigned);
        ForecastHelper.handleReOpeningInsertion(insertionsIds);
        ForecastHelper.addInsertions(productsList);
    }
}