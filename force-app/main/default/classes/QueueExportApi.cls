public class QueueExportApi implements Queueable, Database.AllowsCallouts {
    List<Document> docList;
    String exportType;
    public QueueExportApi(List<Document> docList, String exportType) {
        this.exportType = exportType;
        this.docList = docList;
    }
    public void execute(QueueableContext context) {
        system.Debug(docList);
        Set<Id> recordIds = new Set<Id>();
        Database.SaveResult[] srList = Database.insert(docList);
        for(Database.SaveResult sr : srList) recordIds.add(sr.getId());
        system.Debug(recordIds);
        gnx_export.exportToAPI(recordIds, exportType);
    }
}