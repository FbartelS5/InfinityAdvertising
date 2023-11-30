public with sharing class AAFCreatorController {
    @AuraEnabled
    public static List<Insertion__c> getAAFInput(String dateString) {
        //Date permettant de trier les Insertions correspondantes
        Date targetDate = Date.newInstance(Integer.valueOf(dateString.split('-')[0]), Integer.valueOf(dateString.split('-')[1]), 1);
        system.debug(targetDate);
        return [SELECT Id, StartDate__c, EndDate__c, Revenue__c, Product__r.Type__c,
                                       Product__r.Targeting__c, Product__r.Medium__c, Product__r.Category__c,
                					   Product__r.Rate__c, Opportunity__r.InvoicedAccount__c, Opportunity__r.Owner.Name,
                					   Opportunity__r.Agency__r.Name, Opportunity__r.Account.Name
                                       FROM Insertion__c
                                       WHERE CALENDAR_MONTH(StartDate__c) =: targetDate.month()
                                       AND CALENDAR_YEAR(StartDate__c) =: targetDate.year()
                                       AND Revenue__c != NULL
                                       AND (Status__c ='Clôturé'
                                       OR Status__c ='OI facturé')
                                       ORDER BY Product__r.Medium__c];
    }
    
    @AuraEnabled
    public static void saveAAF(String fileBlob, String fileTitle){        
        Document docSave = new Document(body = EncodingUtil.base64Decode(fileBlob),
                                        folderid = UserInfo.getUserId(),
                                        name = fileTitle +'.xlsx');
        upsert docSave;
        
        ContentVersion fileSave = new ContentVersion();
        fileSave.ContentLocation = 'S';
        fileSave.VersionData = docSave.Body;
        fileSave.Title = docSave.Name;
        fileSave.PathOnClient = docSave.Name;
        upsert fileSave;
    }
}