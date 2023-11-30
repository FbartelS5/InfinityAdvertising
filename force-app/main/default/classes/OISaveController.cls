public class OISaveController {
    
	public Opportunity opp{get;set;}
    public List<String> listDocs{get;set;}

    public OISaveController(ApexPages.StandardController stdController) {
        opp = (Opportunity)stdController.getRecord();
        listDocs = new List<String>();
        List<Document> saveDocsList = new List<Document>();
        List<String> alreadyAddDocs = new List<String>();
        Opportunity opport = [select id, 
                              (select id, package__r.Name, 
                               package__r.DocumentTemplate__r.Id,
                               package__r.DocumentTemplate__r.TemplateBodyHTML__c,
                               package__r.DocumentTemplate__r.isHTML__c from Products__r) 
                              from opportunity 
                              where id =: opp.Id];
        
        List<AssociationDocumentTemplate__mdt> ladt = [select id, MasterLabel, Template_to_use__c, Master_object__c, Vfp_used__c, order__c from AssociationDocumentTemplate__mdt order by order__c asc];
        
        for(AssociationDocumentTemplate__mdt adt : ladt) {
            for(Product__c p : opport.Products__r) {
                if(alreadyAddDocs.contains(p.Package__r.Name)) continue;
                String templateBody = p.package__r.DocumentTemplate__r.isHtml__c ? p.package__r.DocumentTemplate__r.TemplateBodyHTML__c : p.package__r.DocumentTemplate__r.TemplateBody__c;
                if(adt.Template_to_use__c == p.package__r.DocumentTemplate__r.Id && adt.MasterLabel == 'Telemarketing') {
                    PageReference page = new PageReference('/apex/io_save'+ '?id='+opp.Id+ '&masterObject='+adt.Master_object__c+ '&relatedObject='+'Product__c'+ '&relatedId='+p.Id);
                    listDocs.add(DocumentTemplateController.getDocumentBody(templateBody, page));
                    alreadyAddDocs.add(p.Package__r.Name);
                    
                }
            }
        }
    }
}