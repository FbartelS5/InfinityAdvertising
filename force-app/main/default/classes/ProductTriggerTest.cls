@isTest
public class ProductTriggerTest {
	static TestDataFactory t;
    static {
        t = new TestDataFactory();
    }
    
    @isTest
    public static void test(){
        upsert t.oppProduct;
    }
}