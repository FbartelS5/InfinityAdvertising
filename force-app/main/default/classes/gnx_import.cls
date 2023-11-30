public class gnx_import {
    
    public static HttpResponse sendReqOk(Http http, HttpRequest request){
        try{
            return http.send(request);
        }catch(Exception e){
            System.debug('Salesforce ERROR: Caught exception ' + e.getStackTraceString() +' '+ e.getMessage());
            HttpResponse response = new HttpResponse();
            response.setStatusCode(500);
            response.setStatus('Salesforce ERROR: Caught exception ' + e.getStackTraceString() +' '+ e.getMessage());
            return response;
        }
    }
    
    @future(callout = true)
    public static void importFromAPI(List<String> filesToImport){
        String importedFile;
        FTP_credentials__mdt creds = new FTP_credentials__mdt();
        if(Test.isRunningTest()){          
 
            creds = FTP_credentials_testing(creds);
        } else {
            creds = [SELECT DeveloperName, host__c, username__c, pass__c, port__c, directory__c, endpoint__c, errorRecipient__c
                                      FROM FTP_credentials__mdt WHERE DeveloperName =: 'Regie3W_Import' limit 1];
        }
 
        Messaging.SingleEmailMessage[] mailList = new List<Messaging.SingleEmailMessage>{};
        for(String file : filesToImport){
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            HttpResponse requestResult = new HttpResponse();
            Integer attempts=5;
            Integer i=0;
            String boundary = 'WebKitFormBoundary';
            String directory = creds.directory__c;
            String host = creds.host__c;
            String user = creds.username__c;
            String pass = creds.pass__c;
            String port = creds.port__c;
            String mailError = creds.errorRecipient__c;
            String sfurl = URL.getOrgDomainUrl().toExternalForm();
            String sessionid = UserInfo.getSessionId();
            request.setTimeout(120000);
            request.setEndpoint(creds.endpoint__c);
            request.setMethod('POST');
            request.setHeader('Content-Type', 'multipart/form-data; boundary=' + boundary);
            request.setBody('--' + boundary +'\r\n'
                            + 'Content-Disposition: form-data;name=\"directory\"\r\n\r\n'+ directory +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data; name=\"host\"\r\n\r\n'+ host +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data; name=\"sfurl\"\r\n\r\n'+ sfurl +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data; name=\"sessionid\"\r\n\r\n'+ sessionid +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data;name=\"user\"\r\n\r\n'+ user +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data; name=\"password\"\r\n\r\n'+ pass +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data;name=\"port\"\r\n\r\n'+ port +'\r\n'
                            + '--' +  boundary +'\r\n'
                            + 'Content-Disposition: form-data; name=\"file\"\r\n\r\n'+ file +'\r\n'
                            + '--' +  boundary +'--');
            while(i<attempts){
                requestResult=sendReqOk(http, request);
                if(requestResult.getStatusCode() == 200) break;
                i++;
            }
            if(requestResult.getStatusCode() == 200){
                continue;
            }else{
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.toAddresses = new String[] {mailError};
                mail.setSubject('API Error: 3wRegie Import, Code : '+requestResult.getStatusCode());
                mail.setPlainTextBody('Organisation : 3wRegie \r\n API : Import \r\n Code : '+requestResult.getStatusCode()+' '+requestResult.getStatus());
                mailList.add(mail);
            }
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(mailList);
    }
    public static FTP_credentials__mdt FTP_credentials_testing(FTP_credentials__mdt credtest)
    {
        credtest.host__c = 'Test123';
        credtest.username__c = 'Test123';
        credtest.pass__c = 'Test123';
        credtest.port__c = 'Test123';
        credtest.endpoint__c = 'test123';

        return credtest;
    }

}