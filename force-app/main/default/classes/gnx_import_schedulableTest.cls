@istest
public class gnx_import_schedulableTest {
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            System.assertEquals('POST', req.getMethod());
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(EncodingUtil.base64Encode(Blob.valueOf('test')));
            res.setStatusCode(200);
            return res;
        }
    }
    static testmethod void test() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        gnx_import_schedulable targetClass = new gnx_import_schedulable ();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test', chron, targetClass);
        Test.stopTest();
    }
    
    
}