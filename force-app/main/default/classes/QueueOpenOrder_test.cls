@istest
public class QueueOpenOrder_test {
    static TestDataFactory t;
    static {
        t = new TestDataFactory(); 
    } 
    
	static testmethod void test() {
        Set<Id> recordIds = new Set<Id>();
        recordIds.add(t.opp.Id);
        QueueOpenOrder queueJob = new QueueOpenOrder(recordIds);
        Test.startTest();        
        System.enqueueJob(queueJob);
        Test.stopTest();
    }
}