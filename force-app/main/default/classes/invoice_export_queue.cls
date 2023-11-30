public class invoice_export_queue implements Queueable, Database.AllowsCallouts {
    List<Document> docList;
    public invoice_export_queue(List<Document> docList) {
        this.docList = docList;
    }
    public void execute(QueueableContext context) {
        system.Debug(docList);
        Set<Id> recordIds = new Set<Id>();
        Database.SaveResult[] srList = Database.insert(docList);
        for(Database.SaveResult sr : srList) recordIds.add(sr.getId());
        system.Debug(recordIds);
        invoice_export.exportToMail(recordIds);
    }
}