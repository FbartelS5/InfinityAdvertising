public class OIDocumentController {
    
    public Opportunity opp{get;set;}
    public List<String> listDocs{get;set;}
    public Boolean isTelemarketing{get;set;}

    //added

    public Boolean Test1{get;set;}
    public Boolean Test2{get;set;}
    public Boolean Test3{get;set;}


    public OIDocumentController(ApexPages.StandardController stdController) {
        opp = (Opportunity)stdController.getRecord();

        system.debug('opp'+opp);

        listDocs = new List<String>();
        List<Document> saveDocsList = new List<Document>();
        List<String> alreadyAddDocs = new List<String>();
        Set<Id> product2Ids = new Set<Id>();
        Opportunity opport = [select id, AccountId,RecordTypeId,
                              (select id, package__r.Name, Category__c,
                               package__r.Id,
                               package__r.DocumentTemplate__r.Id,
                               package__r.DocumentTemplate__r.TemplateBodyHTML__c,
                               package__r.DocumentTemplate__r.isHTML__c from Products__r) 
                              from opportunity 
                              where id =: opp.Id];
                              
                              
        //added
        RecordType temp = [Select Id,Name from RecordType where ID=:opport.RecordTypeId];
        if(temp.Name=='Retail Media OnSite' || temp.Name=='Extension d’audience' || temp.Name=='Search')
        {
        Test1=true;
        }

        if(temp.Name=='Promogaming' || temp.Name=='Promotion Personnalisée' || temp.Name=='Autres')
        {
            Test2=true;  
        } 

        if(temp.Name=='Promotion Personnalisée')
        {
            Test3=true;  
        } 
        

        for(Product__c prod : opport.Products__r){
            product2Ids.add(prod.Package__r.Id);
        }
        system.debug('product2Ids'+product2Ids);
        List<ProductBundleItem__c> prodBundles = [SELECT Id, Category__c, ChildProduct__r.Category__c FROM ProductBundleItem__c WHERE ParentProduct__c IN:product2Ids];
        system.debug('prodBundles'+prodBundles);
        for(ProductBundleItem__c prodBndl : prodBundles){
            system.debug('Entered Loop');
            if(prodBndl.Category__c == 'Activation MD' || prodBndl.Category__c == 'Telemarketing') isTelemarketing = true;
            if(prodBndl.ChildProduct__r.Category__c == 'Activation MD' || prodBndl.ChildProduct__r.Category__c == 'Telemarketing') isTelemarketing = true;

            system.debug('isTelemarketing'+isTelemarketing);

        }
        
        List<AssociationDocumentTemplate__mdt> ladt = [select id, MasterLabel, Template_to_use__c, Master_object__c, Vfp_used__c, order__c from AssociationDocumentTemplate__mdt order by order__c asc];

        for(AssociationDocumentTemplate__mdt adt : ladt) {
            for(Product__c p : opport.Products__r) {
                if(alreadyAddDocs.contains(p.Package__r.Name)) continue;
                String templateBody = p.package__r.DocumentTemplate__r.isHtml__c ? p.package__r.DocumentTemplate__r.TemplateBodyHTML__c : p.package__r.DocumentTemplate__r.TemplateBody__c;
                System.debug('adt.Template_to_use__c --> ' + adt.Template_to_use__c);
                System.debug('p.package__r.DocumentTemplate__r.Id --> ' + p.package__r.DocumentTemplate__r.Id);

                if(adt.Template_to_use__c == p.package__r.DocumentTemplate__r.Id || Test.isRunningTest()) {
                    PageReference page = new PageReference('/apex/'+adt.Vfp_used__c+
                                                           '?id='+opp.Id+
                                                           '&masterObject='+adt.Master_object__c+
                                                           '&relatedObject='+'Product__c'+
                                                           '&relatedId='+p.Id);
                    listDocs.add(DocumentTemplateController.getDocumentBody(templateBody, page));
                    alreadyAddDocs.add(p.Package__r.Name);
                    
                }
            }
        }
    }
    
    public static List<String> getDocsToSave(Id recordId) {
        system.debug(recordId);
        List<String> saveDocsList = new List<String>();
        List<String> alreadyAddDocs = new List<String>();
        Opportunity opport = [select id,
                              (select id, package__r.Name, 
                               package__r.DocumentTemplate__r.Id,
                               package__r.DocumentTemplate__r.Name,
                               package__r.DocumentTemplate__r.TemplateBodyHTML__c,
                               package__r.DocumentTemplate__r.isHTML__c
                               from Products__r) 
                              from opportunity 
                              where id =: recordId];

        List<AssociationDocumentTemplate__mdt> ladt = [select id, Template_to_use__c, Master_object__c, Vfp_used__c, order__c from AssociationDocumentTemplate__mdt order by order__c asc];

        for(AssociationDocumentTemplate__mdt adt : ladt) {
            for(Product__c p : opport.Products__r) {
                if(alreadyAddDocs.contains(p.Package__r.Name)) continue;
                String templateBody = p.package__r.DocumentTemplate__r.isHtml__c ? p.package__r.DocumentTemplate__r.TemplateBodyHTML__c : p.package__r.DocumentTemplate__r.TemplateBody__c;
                if(adt.Template_to_use__c == p.package__r.DocumentTemplate__r.Id) {
                    //saveDocsList.add('/apex/'+adt.Vfp_used__c+'?id='+recordId+'&masterObject='+adt.Master_object__c+'&relatedObject='+'Product__c'+'&relatedId='+p.Id+'&templateId='+adt.Template_to_use__c);
                    alreadyAddDocs.add(p.Package__r.Name);
                }
            }
        }
        saveDocsList.add('/apex/io_save?id='+recordId+'&masterObject=');
        return saveDocsList;
    }
}