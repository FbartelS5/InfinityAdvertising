public with sharing class showData {
    //public static string cnval{get; set;}
    
    public class Link {
        String Name;
        String url;
    }
    /*@AuraEnabled public static string assignValue(string svr){cnval = svr;system.debug('aura-->'+cnval);return svr;}*/
    @AuraEnabled
    public static String getLinks(string recordId){
        List<link> listLinks = new List<link>();
        List<String> alreadyAddDocs = new List<String>();
        List<Integer> docsToRemove = new List<Integer>();
        Integer counter = 0;
        Map<id, AssociationDocumentTemplate__mdt> mapIdTemplate = new Map<id, AssociationDocumentTemplate__mdt>();
        Opportunity opport = [select id, AccountId, (select id, Category__c, package__r.Name, package__r.Category__c, package__r.DocumentTemplate__c , package__r.DocumentTemplate__r.Id from Products__r) 
                              from opportunity where id =: recordId];
        List<AssociationDocumentTemplate__mdt> ladt = [select id, MasterLabel, Template_to_use__c, Master_object__c, Vfp_used__c from AssociationDocumentTemplate__mdt];
        for(AssociationDocumentTemplate__mdt adt : ladt){
            if(adt.MasterLabel == 'Telemarketing' || adt.MasterLabel == 'Activation MD' ) docsToRemove.add(counter);
            counter++;
        }
        for(Integer docRef : docsToRemove) ladt.remove(docRef);
        for(AssociationDocumentTemplate__mdt adt : ladt) mapIdTemplate.put(adt.Template_to_use__c, adt);
        for(Product__c p : opport.Products__r) {
            system.debug(p.Package__r.DocumentTemplate__c);
            if(alreadyAddDocs.contains(p.Package__r.Id)) continue;
            system.debug(p.Package__r.DocumentTemplate__c + ' ' + mapIdTemplate.get(p.Package__r.DocumentTemplate__c));
            if(p.Package__r.DocumentTemplate__c != null && mapIdTemplate.get(p.Package__r.DocumentTemplate__c) != null){
                AssociationDocumentTemplate__mdt adt = mapIdTemplate.get(p.Package__r.DocumentTemplate__c);
                Link link = new Link();
                link.Name = adt.MasterLabel; link.url = '';
                if(adt.Master_object__c != null) link.url+= '&masterObject='+adt.Master_object__c;
                if(adt.Template_to_use__c != null) link.url+= '&templateId='+adt.Template_to_use__c;
                listLinks.add(link);
                alreadyAddDocs.add(p.Package__r.Id);
            }
        } 
        return JSON.serialize(listLinks);
    }
    
    @AuraEnabled
    public static void saveDocs(Id oppId){
        List<String> docsToSave = OIDocumentController.getDocsToSave(oppId);
        Opportunity opp = [select id, AutoOppId__c,Numero_OI_BDC__c from opportunity where id =: oppId];
        io_controller.save(oppId, opp.Numero_OI_BDC__c+'_', docsToSave[0] + oppId);
    }
    
    @AuraEnabled
    public static String fetchUrl(){
        string urler = URL.getSalesforceBaseUrl().toExternalForm();
        return (urler);
    }
}