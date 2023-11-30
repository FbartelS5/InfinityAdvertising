@isTest
public class OpenOrderToFtpTest {
    
    static TestDataFactory t;
    static {
        t = new TestDataFactory();
    }
    
	static testMethod void testMethod1(){
        
        Test.startTest();
        	OpenOrdersToFtp schedule = new OpenOrdersToFtp();
        	System.schedule('test','0 0 8 13 2 ?', schedule);
        	Id batchJobId = Database.executeBatch(new OpenOrdersToFtp(), 10);
        Test.stopTest();
    }
}