public class QueueOpenOrder implements Queueable, Database.AllowsCallouts {
    Set<Id> recordids;
    public QueueOpenOrder(Set<Id> recordIds) {
        this.recordIds = recordIds;
    }
    public void execute(QueueableContext context) {
        // GDO BUG
        // gnx_export.exportToAPI(recordIds);
    }
}