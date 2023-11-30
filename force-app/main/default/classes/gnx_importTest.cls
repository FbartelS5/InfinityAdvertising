@isTest
global class gnx_importTest {

    static TestDataFactory t;
    static { t = new TestDataFactory(); }

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
    @isTest static void testCallout() {
        List<String> a = new List<String>();
        a.add('test');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        gnx_import.importFromAPI(a);
        Test.stopTest();
    }
}