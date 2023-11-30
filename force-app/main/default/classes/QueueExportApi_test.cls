@istest
public class QueueExportApi_test {
    static TestDataFactory t;
    static {
        t = new TestDataFactory(); 
    } 
    
	static testmethod void test() {
        List<Document> docList = new List<Document>();
        docList.add(t.document);
        QueueExportApi queueJob = new QueueExportApi(docList, 'Relevanc_Export');
        Test.startTest();        
        System.enqueueJob(queueJob);
        Test.stopTest();
    }
}