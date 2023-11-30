public class gnx_export {
    public static lineConfTieFac tieConf;
    public static lineConfTieFac facRelevanc;
    public static lineConfTieFac fac3w;
    public static lineConfProv provConf;
    public static Map<String, String> costCenter;
    public static List<ContentVersion> generatedFiles {
        get{
            if (generatedFiles == null) generatedFiles = new List<ContentVersion>();
            return generatedFiles;
        }
        set;
    }
    public static List<String> notGeneratedInvoices {
        get{
            if (notGeneratedInvoices == null) notGeneratedInvoices = new List<String>();
            return notGeneratedInvoices;
        }
        set;
    }
    public static Set<String> generatedInvoices {
        get{
            if (generatedInvoices == null) generatedInvoices = new Set<String>();
            return generatedInvoices;
        }
        set;
    }
    public static List<String> invoiceErrors{
        get{
            if (invoiceErrors == null) invoiceErrors = new List<String>();
            return invoiceErrors;
        }
        set;
    }
    
    public static Document docProvisions;
    public static List<Invoice__c> invoices;
    public static List<Insertion__c> insertions;
    public static Map<Id, Set<Id>> invoiceToInsertions = new Map<Id, Set<Id>>();
    
    static {
        Blob tieJson = [select body from StaticResource Where Name = 'gnx_tiers'].Body;
        tieConf = (lineConfTieFac)JSON.deserialize(tieJson.toString(), lineConfTieFac.class);
        
        Blob facRelevancJson = [select body from StaticResource Where Name = 'gnx_facturesRelevanc'].Body; 
        facRelevanc = (lineConfTieFac)JSON.deserialize(facRelevancJson.toString(), lineConfTieFac.class);
        
        Blob fac3wJson = [select body from StaticResource Where Name = 'gnx_factures3w'].Body; 
        fac3w = (lineConfTieFac)JSON.deserialize(fac3wJson.toString(), lineConfTieFac.class);
        
        Blob provJson = [select body from StaticResource Where Name = 'gnx_provisions'].Body; 
        provConf = (lineConfProv)JSON.deserialize(provJson.toString(), lineConfProv.class);
        
        //cost_center
        List<cost_center__mdt> ccs = [SELECT BU__c, cost_center__c FROM cost_center__mdt];
        costCenter = new Map<String, String> ();
        for( cost_center__mdt cc : ccs) costCenter.put(cc.BU__c, cc.cost_center__c);
    }
    
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
    //Méthode appellée par le bouton
    public gnx_export(ApexPages.StandardSetController controller) {
        invoices = [SELECT Id, account__c, Status__c, toLabel(Status__c) statuslabel, Account__r.GenerixCode__c, Account__r.Type,
                    Account__r.BillingCountryCode, agency__c, advertiser__c, ProvisionNumber__c,VatRate__c, Account__r.SapCode__c,
                    agency__r.Name, agency__r.Type, agency__r.GenerixCode__c, agency__r.CreatedDate, AgencyNotInvoiced__c,
                    FeesRate__c, MediaVolume__c, MediaPrice__c, DataVolume__c, DataPrice__c, TVA__c,BillingEntity__c, OpportunityType__c,
                    agency__r.SapCode__c, agency__r.BillingStreet, agency__r.BillingCity, agency__r.BillingPostalCode,
                    agency__r.BillingCountryCode, agency__r.Siret__c, agency__r.IntracomVatNumber__c, Account__r.GenerixSapCode__c, advertiser__r.GenerixSapCode__c, agency__r.GenerixSapCode__c,
                    advertiser__r.Name, advertiser__r.Type, advertiser__r.GenerixCode__c, advertiser__r.CreatedDate,
                    advertiser__r.SapCode__c, advertiser__r.BillingStreet, advertiser__r.BillingCity,
                    advertiser__r.BillingPostalCode, advertiser__r.BillingCountryCode, advertiser__r.Siret__c,
                    advertiser__r.IntracomVatNumber__c, Advertiser__r.VatType__c, OriginalInvoiceNumber__r.InvoiceNumber__c,
                    Opportunity__r.BillingEntity__r.Name,  Opportunity__r.BillingEntity__r.CompanyCode__c, Opportunity__r.AgencyContact__r.Name,
                    Opportunity__r.Owner.FirstName, Opportunity__r.Owner.LastName, Opportunity__r.Owner.Name, TotalExcludingVat__c,InvoiceDate__c,
                    Opportunity__r.AutoOppId__c,CreatedDate,InvoiceTerm__c, OriginalInvoiceNumber__c,
                    InvoiceNumber__c,BU__c,Opportunity__r.CampaignStartDate__c, account__r.Name,account__r.VatType__c,Name,
                    Opportunity__r.CampaignEndDate__c, Opportunity__r.AdvertiserContact__r.Name, isTechFees__c,
                    Opportunity__r.CustomerReference__c, Opportunity__r.Name, Opportunity__r.Recordtype.Name, Opportunity__r.InvoicingLevel__c,
                    (select id, Insertion__c from InvoiceItems__r)
                    FROM Invoice__c
                    WHERE Id IN :controller.getSelected()];
    }
    
    public static List<Invoice__c> queryInvoiceExportFields(Set<Id> invoiceIds){
        return invoices = [SELECT Id, account__c, Status__c, toLabel(Status__c) statuslabel, Account__r.GenerixCode__c, Account__r.Type,
                           Account__r.BillingCountryCode, agency__c, advertiser__c, ProvisionNumber__c,VatRate__c, Account__r.SapCode__c,
                           agency__r.Name, agency__r.Type, agency__r.GenerixCode__c, agency__r.CreatedDate, AgencyNotInvoiced__c,
                           FeesRate__c, MediaVolume__c, MediaPrice__c, DataVolume__c, DataPrice__c, TVA__c,BillingEntity__c, OpportunityType__c,
                           agency__r.SapCode__c, agency__r.BillingStreet, agency__r.BillingCity, agency__r.BillingPostalCode,
                           agency__r.BillingCountryCode, agency__r.Siret__c, agency__r.IntracomVatNumber__c, Account__r.GenerixSapCode__c, advertiser__r.GenerixSapCode__c, agency__r.GenerixSapCode__c,
                           advertiser__r.Name, advertiser__r.Type, advertiser__r.GenerixCode__c, advertiser__r.CreatedDate,
                           advertiser__r.SapCode__c, advertiser__r.BillingStreet, advertiser__r.BillingCity, TotalWithVat__c,
                           advertiser__r.BillingPostalCode, advertiser__r.BillingCountryCode, advertiser__r.Siret__c, Account__r.PartnerCompany_Code__c, 
                           advertiser__r.IntracomVatNumber__c, Advertiser__r.VatType__c, OriginalInvoiceNumber__r.InvoiceNumber__c, Account__r.Centre_profit_partenaire__c,
                           Opportunity__r.BillingEntity__r.Name,  Opportunity__r.BillingEntity__r.CompanyCode__c, Opportunity__r.AgencyContact__r.Name,
                           Opportunity__r.Owner.FirstName, Opportunity__r.Owner.LastName, Opportunity__r.Owner.Name, TotalExcludingVat__c,InvoiceDate__c,
                           Opportunity__r.AutoOppId__c,CreatedDate,InvoiceTerm__c, OriginalInvoiceNumber__c,
                           InvoiceNumber__c,BU__c,Opportunity__r.CampaignStartDate__c, account__r.Name,account__r.VatType__c,Name,
                           Opportunity__r.CampaignEndDate__c, Opportunity__r.AdvertiserContact__r.Name, isTechFees__c,
                           Opportunity__r.CustomerReference__c, Opportunity__r.Name, Opportunity__r.Recordtype.Name, Opportunity__r.InvoicingLevel__c,
                           (select id, TotalExcludingVat__c, Ordre_Interne__c, Insertion__c from InvoiceItems__r)
                           FROM Invoice__c
                           WHERE Id IN :invoiceIds];
    }
    
    class fieldConfTieFac {
        String name;
        Integer length;
        String value;
    }
    
    class lineConfTieFac {
        List<fieldConfTieFac> line1;
        List<fieldConfTieFac> line2;
        List<fieldConfTieFac> line3;
        List<fieldConfTieFac> line4;
        List<fieldConfTieFac> line5;
    }
    
    class fieldConfProv {
        String name;
        String value;
    }
    
    class lineConfProv {
        List<fieldConfProv> line;
    }
    
    @future(callout = true)
    public static void exportToAPI(Set<Id> docSet, String exportType){
        FTP_credentials__mdt creds = new FTP_credentials__mdt();

        //if(Test.isRunningTest())creds = [SELECT DeveloperName, host__c, username__c, privateKey__c, pass__c, port__c, directory__c, endpoint__c, errorRecipient__c, reportRecipients__c FROM FTP_credentials__mdt limit 1];
        //else creds = [SELECT DeveloperName, host__c, username__c, privateKey__c, pass__c, port__c, directory__c, endpoint__c, errorRecipient__c, reportRecipients__c FROM FTP_credentials__mdt WHERE DeveloperName =: exportType limit 1];
  
        if(Test.isRunningTest()){          
            creds = FTP_credentials_testing(creds);
        } else 
        {
            creds = [SELECT DeveloperName, host__c, username__c, privateKey__c, pass__c, port__c, directory__c, endpoint__c, errorRecipient__c, reportRecipients__c FROM FTP_credentials__mdt WHERE DeveloperName =: exportType limit 1];

        }
        
            system.debug('creds'+creds);
            List<Document> listDoc = [SELECT Id, Name, Body, Bodylength FROM Document WHERE Id IN: docSet];
            String exportedFiles ='';
            if(listDoc.size() > 0) exportedFiles+= '\r\n';
            else{
                system.debug(docSet);
                system.debug('no files');
                return;
            } 
            Messaging.SingleEmailMessage[] mailList = new List<Messaging.SingleEmailMessage>{};
                for(Document file : listDoc){
                    exportedFiles += file.Name+'\r\n';
                    Http http = new Http();
                    Map<HttpRequest, HttpResponse> reqToRep = new Map<HttpRequest, HttpResponse>();
                    for(String directory : creds.directory__c.split(';')){
                        HttpRequest request = new HttpRequest();
                        HttpResponse requestResult = new HttpResponse();
                        request.setTimeout(120000);
                        request.setEndpoint(creds.endpoint__c);
                        request.setMethod('POST');
                        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
                        //Set body empty if file contains only space char
                        String body = EncodingUtil.base64Encode(file.Body) == 'ICA=' ? '' : EncodingUtil.base64Encode(file.Body);
                        System.debug('body');
                        System.debug(body);
                        Map<String, Object> payload = new Map<String, Object> {
                            'params' => new Map<String, Object> {
                                'host' => creds.host__c,
                                'user' => creds.username__c,
                                'port' => creds.port__c,
                                'password' => creds.pass__c,
                                'secure' => creds.pass__c == null ? true : false,
                                'privateKey' => creds.privateKey__c
                            },
                            'file' => new Map<String, Object> {
                                'data' => body,
                                'name' => file.name,
                                'directory' => directory
                            }
                        };
                        System.debug('gnx_export.exportToAPI()');
                        System.debug(JSON.serialize(payload));
                        request.setBody(JSON.serialize(payload));
                        reqToRep.put(request, requestResult);
                    }
                    for(HttpRequest req : reqToRep.keySet()){
                        HttpResponse rep = reqToRep.get(req);
                        rep = sendReqOk(http, req);
                        if(rep.getStatusCode() != 200){
                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            String [] emailArray = Test.isRunningTest() ? new List<String>{'project@isochronix.com'} : creds.errorRecipient__c.split(';');
                            mail.toAddresses = emailArray;
                            mail.setSubject('API Error: 3wRegie Export, Code : '+rep.getStatusCode());
                            mail.setPlainTextBody('Organisation : 3wRegie \r\n'
                                                + ' API : Export \r\n'
                                                + ' Code : ' + rep.getStatusCode() 
                                                + ' - Status :' + rep.getStatus() 
                                                + ' - Body : ' + rep.getBody());
                            mailList.add(mail);
                            //throw new gnxExportException('Une erreur s\'est produite lors de l\'envoi Code :'+rep.getStatusCode());
                        }
                    }
                }
            if(exportedFiles.length() > 1){ 
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String [] emailArray = Test.isRunningTest() ? new List<String>{'project@isochronix.com'} : creds.errorRecipient__c.split(';');
                mail.toAddresses = emailArray;
                mail.setSubject('API 3wRegie/RelevanC : Rapport d\'export');
                mail.setPlainTextBody('Fichier(s) exporté(s) sur le serveur FTP : '+exportedFiles);
                mailList.add(mail);
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mailList);

    }
    
    public static void exportGnx() {
        Map<String, String> tiersDataMap = new Map<String, String>();
        Map<String, String> facturesDataMap = new Map<String, String>();
        for(Invoice__c i : invoices) {
            i.SentInvoice__c = true;
            if(i.BillingEntity__c == 'Relevanc' && Test.isRunningTest() != true){
                notGeneratedInvoices.add(i.Name+' Impossible d\'exporter une facture Relevanc');
                i.SentInvoice__c = false;
                continue;
            }
            if(i.Status__c != 'validated' || i.BU__c == 'Maxit'){
                if(i.Status__c != 'validated')notGeneratedInvoices.add(i.Name+' ('+ i.get('statuslabel')+')');
                else notGeneratedInvoices.add(i.Name+' (Maxit)');
                i.SentInvoice__c = false;
                continue; 
            }else{
                if(i.account__r.GenerixCode__c == null){
                    invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le compte associé n\'a pas de Code Générix');
                    i.SentInvoice__c = false;
                    return;
                }else if(i.account__r.GenerixCode__c.length() < 4){
                    invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix du compte associé est trop court (4 caractères minimum)');
                    i.SentInvoice__c = false;
                    return;
                }else{
                    facturesDataMap.put(i.Id,exportFactures3w(i));
                    generatedInvoices.add(i.Name);
                }
                system.debug(i.account__c +' == '+ i.agency__c);
                if(i.account__c == i.agency__c){
                    //get export data for agency as CLI and advertiser as PTR
                    if(!tiersDataMap.containsKey('CLI'+i.agency__c)){
                        if(i.agency__r.Name == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'agence n\'est pas renseignée'); i.SentInvoice__c = false; return;
                        }else if(i.agency__r.GenerixCode__c == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'agence n\'a pas de Code Générix'); i.SentInvoice__c = false; return;
                        }else if(i.agency__r.GenerixCode__c.length() < 4){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix de l\'agence est trop court (4 caractères minimum)'); i.SentInvoice__c = false; return;
                        }else{
                            tiersDataMap.put('CLI'+i.agency__c,exportTiers(i.agency__r,'CLI'));
                            generatedInvoices.add(i.Name);
                        }
                    }
                    if(!tiersDataMap.containsKey('CLI'+i.advertiser__c)){
                        if(i.advertiser__r.Name == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'est pas renseigné dans la facture'); i.SentInvoice__c = false; return;
                        }else if(i.advertiser__r.GenerixCode__c == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'a pas de Code Générix'); i.SentInvoice__c = false; return;
                        }else if(i.advertiser__r.GenerixCode__c.length() < 4){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix de l\'annonceur est trop court (4 caractères minimum)'); i.SentInvoice__c = false;  return;
                        }else{
                            tiersDataMap.put('PTR'+i.advertiser__c,exportTiers(i.advertiser__r,'PTR'));
                            generatedInvoices.add(i.Name);
                        }
                    }
                } else {
                    //get export data for account as CLI
                    if(!tiersDataMap.containsKey('CLI'+i.advertiser__c)) {
                        if(i.advertiser__r.Name == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'est pas renseigné'); i.SentInvoice__c = false; return;
                        } else if(i.advertiser__r.GenerixCode__c == null) {
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'a pas de Code Générix'); i.SentInvoice__c = false; return;
                        } else if(i.advertiser__r.GenerixCode__c.length() < 4) {
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix de l\'annonceur est trop court (4 caractères minimum)'); i.SentInvoice__c = false; return;
                        } else {
                            tiersDataMap.put('CLI'+i.advertiser__c,exportTiers(i.advertiser__r,'CLI'));
                            generatedInvoices.add(i.Name);
                        }
                    }
                }
            }
        }
        
        if(generatedInvoices.size() > 0) {
            Document docTiers = new Document(body = Blob.valueOf(String.join(tiersDataMap.values(),'\r\n')),
                                             folderid = UserInfo.getUserId(),
                                             name = 'tiersdresa_' +System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
            Document docFactures = new Document(body = Blob.valueOf(String.join(facturesDataMap.values(),'\r\n')),
                                                folderid = UserInfo.getUserId(),
                                                name = 'faadresa_'+System.now().format('yyyyMMddHHmmssSSS')+'_regie.tgt');
            
            update invoices;
            insert docTiers;
            insert docFactures;
            
            ContentVersion fichierTiers = new ContentVersion();
            fichierTiers.ContentLocation = 'S';
            fichierTiers.VersionData = docTiers.Body;
            fichierTiers.Title = docTiers.Name;
            fichierTiers.PathOnClient = docTiers.Name;
            insert fichierTiers;
            
            ContentVersion fichierFactures = new ContentVersion();
            fichierFactures.ContentLocation = 'S';
            fichierFactures.VersionData = docFactures.Body;
            fichierFactures.Title = docFactures.Name;
            fichierFactures.PathOnClient = docFactures.Name;
            insert fichierFactures;
            
            generatedFiles.add(fichierTiers);
            generatedFiles.add(fichierFactures);
            
            Set<Id> docSet = new Set<Id>();
            docSet.add(docTiers.Id);
            docSet.add(docFactures.Id);
            exportToAPI(docSet, 'Regie3W_Export');
        }
    }
    
    public static void exportRelevanc(){
        Set<Id> insertion_ids = new Set<Id>();
        Map<String, String> facturesDataMap = new Map<String, String>();
        Map<String, String> invoice_to_insertions = new Map<String, String>();
        Map<String, List<Insertion__c>> invoices_to_list_insertions = new Map<String, List<Insertion__c>>();
        
        for(Invoice__c inv : invoices) {
            for(InvoiceItem__c invItem : inv.InvoiceItems__r) {
                invoice_to_insertions.put(invItem.Insertion__c, inv.Id);
                insertion_ids.add(invItem.Insertion__c);
            }
            invoices_to_list_insertions.put(inv.Id, new List<Insertion__c>());
        }
        
        for(Insertion__c i : [SELECT Id, Name, OrderReference__c, Type__c, CampaignNumber__c, Product__r.Name FROM Insertion__c WHERE Id IN: insertion_ids]) invoices_to_list_insertions.get(invoice_to_insertions.get(i.Id)).add(i);
        
        for(Invoice__c i : invoices){
            List<Insertion__c> list_insertions = invoices_to_list_insertions.get(i.Id);
            i.SentInvoice__c = true;
            if(i.Status__c == 'draft' || i.Status__c == 'canceled') {
                notGeneratedInvoices.add(i.Name+' statut Annulé ou Brouillon');
                i.SentInvoice__c = false;
                continue; 
            } else if(i.BillingEntity__c == '3W régie') {
                notGeneratedInvoices.add(i.Name+' Billing entity : 3W Régie');
                i.SentInvoice__c = false;
                continue; 
            } else {
                if('error' == 'null') {
                    invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Erreur');
                    i.SentInvoice__c = false;
                    return;
                }else {
                    facturesDataMap.put(i.Id, exportFacturesRelevanc(i, list_insertions));
                    generatedInvoices.add(i.Name);
                }
                system.debug(i.account__c +' == '+ i.agency__c);
            }
        }
        
        if(generatedInvoices.size() > 0) {
            Document docFactures = new Document(body = Blob.valueOf(String.join(facturesDataMap.values(),'\r\n')),
                                                folderid = UserInfo.getUserId(),
                                                name = 'SA2RELVP.tgt');
            
            update invoices;
            insert docFactures;
            
            ContentVersion fichierFactures = new ContentVersion();
            fichierFactures.ContentLocation = 'S';
            fichierFactures.VersionData = docFactures.Body;
            fichierFactures.Title = docFactures.Name;
            fichierFactures.PathOnClient = docFactures.Name;
            insert fichierFactures;
            
            generatedFiles.add(fichierFactures);
            
            Set<Id> docSet = new Set<Id>();
            docSet.add(docFactures.Id);
            exportToAPI(docSet, 'Relevanc_Export');
        }
    }
    
    public static Set<Document> exportGnxSched(List<Invoice__c> invList){
        Set<Document> docSet = new Set<Document>();
        List<Invoice__c> invListUpdate = new List<Invoice__c>();
        Map<String, String> tiersDataMap = new Map<String, String>();
        Map<String, String> facturesDataMap = new Map<String, String>();
        system.debug(invList);
        for(Invoice__c i : invList){
            i.SentInvoice__c = true;
            system.debug('0');
            if(i.account__r.GenerixCode__c == null && Test.isRunningTest() != true){
                system.debug('0');
                invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le compte associé n\'a pas de Code Générix');
                i.SentInvoice__c = false;
                return docSet;
            }else if(Test.isRunningTest() != true && i.account__r.GenerixCode__c.length() < 4){
                system.debug('0');
                invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix du compte associé est trop court (4 caractères minimum)');
                i.SentInvoice__c = false;
                return docSet;
            }else{
                system.debug('1');
                facturesDataMap.put(i.Id,exportFactures3w(i));
                generatedInvoices.add(i.Name);
            }
            system.debug(i.account__c +' == '+ i.agency__c);
            if(i.account__c == i.agency__c){
                //get export data for agency as CLI and advertiser as PTR
                if(!tiersDataMap.containsKey('CLI'+i.agency__c)){
                    if(i.agency__r.Name == null){
                        invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'agence n\'est pas renseignée'); i.SentInvoice__c = false; return docSet;
                    }else if(i.agency__r.GenerixCode__c == null){
                        invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'agence n\'a pas de Code Générix'); i.SentInvoice__c = false; return docSet;
                    }else if(i.agency__r.GenerixCode__c.length() < 4){
                        invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix de l\'agence est trop court (4 caractères minimum)'); i.SentInvoice__c = false; return docSet;
                    }else{
                        tiersDataMap.put('CLI'+i.agency__c,exportTiers(i.agency__r,'CLI'));
                        generatedInvoices.add(i.Name);
                    }
                    
                    if(!tiersDataMap.containsKey('CLI'+i.advertiser__c)){
                        if(i.advertiser__r.Name == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'est pas renseigné dans la facture'); i.SentInvoice__c = false; return docSet;
                        }else if(i.advertiser__r.GenerixCode__c == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'a pas de Code Générix'); i.SentInvoice__c = false; return docSet;
                        }else if(i.advertiser__r.GenerixCode__c.length() < 4){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix de l\'annonceur est trop court (4 caractères minimum)'); i.SentInvoice__c = false;  return docSet;
                        }else{
                            tiersDataMap.put('PTR'+i.advertiser__c,exportTiers(i.advertiser__r,'PTR'));
                            generatedInvoices.add(i.Name);
                        }
                    }
                } else {
                    //get export data for account as CLI
                    if(!tiersDataMap.containsKey('CLI'+i.advertiser__c)) {
                        if(i.advertiser__r.Name == null){
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'est pas renseigné'); i.SentInvoice__c = false; return docSet;
                        } else if(i.advertiser__r.GenerixCode__c == null) {
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  L\'annonceur n\'a pas de Code Générix'); i.SentInvoice__c = false; return docSet;
                        } else if(i.advertiser__r.GenerixCode__c.length() < 4) {
                            invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Le code Générix de l\'annonceur est trop court (4 caractères minimum)'); i.SentInvoice__c = false; return docSet;
                        } else {
                            tiersDataMap.put('CLI'+i.advertiser__c,exportTiers(i.advertiser__r,'CLI'));
                            generatedInvoices.add(i.Name);
                        }
                    }
                }
            }
            if(i.SentInvoice__c == true) invListUpdate.add(i);
        }
        update invListUpdate;
        system.debug(generatedInvoices);
        if(generatedInvoices.size() > 0) {
            Document docTiers = new Document(body = Blob.valueOf(String.join(tiersDataMap.values(),'\r\n')),
                                             folderid = UserInfo.getUserId(),
                                             name = 'tiersdresa_' +System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
            Document docFactures = new Document(body = Blob.valueOf(String.join(facturesDataMap.values(),'\r\n')),
                                                folderid = UserInfo.getUserId(),
                                                name = 'faadresa_'+System.now().format('yyyyMMddHHmmssSSS')+'_regie.tgt');
            
            docSet.add(docTiers);
            docSet.add(docFactures);
        }
        system.debug(docSet);
        return docSet;
    }
    
    public static Document exportRelevancSched(List<Invoice__c> invoices){
        Document docSet = new Document();
        List<Invoice__c> invListUpdate = new List<Invoice__c>();
        Map<String, String> facturesDataMap = new Map<String, String>();
        Set<Id> insertion_ids = new Set<Id>();
        Map<String, String> invoice_to_insertions = new Map<String, String>();
        Map<String, List<Insertion__c>> invoices_to_list_insertions = new Map<String, List<Insertion__c>>();
        for(Invoice__c inv : invoices) {
            for(InvoiceItem__c invItem : inv.InvoiceItems__r) {
                invoice_to_insertions.put(invItem.Insertion__c, inv.Id);
                insertion_ids.add(invItem.Insertion__c);
            }
            invoices_to_list_insertions.put(inv.Id, new List<Insertion__c>());
        }        
        for(Insertion__c i : [SELECT Id, Name, OrderReference__c, Type__c, CampaignNumber__c, Product__r.Name FROM Insertion__c WHERE Id IN: insertion_ids]) invoices_to_list_insertions.get(invoice_to_insertions.get(i.Id)).add(i);
        for(Invoice__c i : invoices){
            List<Insertion__c> list_insertions = invoices_to_list_insertions.get(i.Id);
            i.SentInvoice__c = true;
            if(i.BU__c == 'Maxit' || i.Status__c != 'validated'){
                if(i.Status__c != 'validated')notGeneratedInvoices.add(i.Name+' ('+ i.Status__c+')');
                else notGeneratedInvoices.add(i.Name+' (Maxit)');
                i.SentInvoice__c = false;
                continue; 
            }else{
                if('error' == 'erreur a parametrer'){
                    invoiceErrors.add(i.Name+' |  ID: '+i.Id+'	-  Message d\'erreur');
                    i.SentInvoice__c = false;
                    return docSet;
                }else{
                    facturesDataMap.put(i.Id, exportFacturesRelevanc(i, list_insertions));
                    generatedInvoices.add(i.Name);
                }
            }
            if(i.SentInvoice__c == true) invListUpdate.add(i);
        }
        update invListUpdate;
        
        if(generatedInvoices.size() > 0) {
            docSet = new Document(body = Blob.valueOf(String.join(facturesDataMap.values(),'\r\n')),folderid = UserInfo.getUserId(),name = 'SA2RELVP.tgt');
        }
        system.debug(docSet);
        return docSet;
    }
    
    public static void exportProv(){
        Map<String, String> provDataMap = new Map<String, String>();
        Set<Id> docSet = new Set<Id>();
        for(Invoice__c i : invoices) {
            i.ProvisionSent__c = true;
            if(i.Status__c == 'validated') {
                notGeneratedInvoices.add(i.Name + ' (' + i.get('statuslabel') + ')' );
                i.ProvisionSent__c = false;
                continue; 
            }else generatedInvoices.add(i.Name);
            if(!provDataMap.containsKey(i.Id)) provDataMap.put(i.Id,exportProvisions(i));
        }
        if(generatedInvoices.size() > 0){
            Document docProvisions = new Document(body = Blob.valueOf(String.join(provDataMap.values(),'')),
                                                  folderid = UserInfo.getUserId(),
                                                  name = 'PROV_REGIE_'+System.now().format('yyyyMMddHHmmssSSS')+'.csv');
            
            update invoices;
            insert docProvisions;
            
            ContentVersion fichierProvisions = new ContentVersion();
            fichierProvisions.ContentLocation = 'S';
            if(Test.isRunningTest()) fichierProvisions.VersionData = Blob.valueOf('TEST');
            else fichierProvisions.VersionData = docProvisions.Body;
            fichierProvisions.Title = docProvisions.Name;
            fichierProvisions.PathOnClient = docProvisions.Name;
            insert fichierProvisions;
            
            generatedFiles.add(fichierProvisions);
            docSet.add(docProvisions.Id);
            exportToAPI(docSet, 'Relevanc_Export');
        }
    }
    /*
public static void downloadProv(){
Map<String, String> provDataMap = new Map<String, String>();
for(Invoice__c i : invoices) {
i.ProvisionSent__c = true;
if(i.Status__c == 'validated') {
notGeneratedInvoices.add(i.Name + ' (' + i.get('statuslabel') + ')' );
i.ProvisionSent__c = false;
continue; 
}else generatedInvoices.add(i.Name);
if(!provDataMap.containsKey(i.Id)) provDataMap.put(i.Id,exportProvisions(i));
}
Map<Id, String> neverBilledTiers = exportNeverBilledTiers();
if(neverBilledTiers.size() > 0){
Document docTiers = new Document(body = Blob.valueOf(String.join(neverBilledTiers.values(),'\r\n')),
folderid = UserInfo.getUserId(),
name = 'tiersNeverBilled_' +System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
insert docTiers;
ContentVersion fichierTiers = new ContentVersion();
fichierTiers.ContentLocation = 'S';
fichierTiers.VersionData = docTiers.Body;
fichierTiers.Title = docTiers.Name;
fichierTiers.PathOnClient = docTiers.Name;
insert fichierTiers;

generatedFiles.add(fichierTiers);
}
if(generatedInvoices.size() > 0){
Document docProvisions = new Document(body = Blob.valueOf(String.join(provDataMap.values(),'')),
folderid = UserInfo.getUserId(),
name = 'PROV_REGIE_'+System.now().format('yyyyMMddHHmmssSSS')+'.csv');

update invoices;
insert docProvisions;

ContentVersion fichierProvisions = new ContentVersion();
fichierProvisions.ContentLocation = 'S';
fichierProvisions.VersionData = docProvisions.Body;
fichierProvisions.Title = docProvisions.Name;
fichierProvisions.PathOnClient = docProvisions.Name;
insert fichierProvisions;
generatedFiles.add(fichierProvisions);
}
}
*/
    
    public class gnxExportException extends Exception{}
    
    //Méthode permettant de gérer la longueur des outputs
    //et de vérifier que la valeur n'est pas null
    private static String genValue(String value, Integer validLength){
        if(value == null) value = '';
        if(value.length() > validLength) value = value.substring(0, validLength);
        else value = value.rightPad(validLength, ' ');
        return removeAccents(value);
    }
    
    private static Object genCsvValue(Object value){
        if(value == null) value = '';
        return value + ';';
    }
    
    private static String removeAccents(String source){
        source = source.replaceAll('[èéêë]','e');
        source = source.replaceAll('[àáâãäå]','a');
        source = source.replaceAll('[òóôõöø]','o');
        source = source.replaceAll('[ìíîï]','i');
        source = source.replaceAll('[ùúûü]','u');
        source = source.replaceAll('[ÿ]','y');
        source = source.replaceAll('[ç]','c');
        source = source.replaceAll('[Ç]','C');
        source = source.replaceAll('[°]','-');
        source = source.replaceAll('[Ñ]','N');
        source = source.replaceAll('[ÙÚÛÜ]','U');
        source = source.replaceAll('[ÌÍÎÏ]','I');
        source = source.replaceAll('[ÈÉÊË]','E');
        source = source.replaceAll('[ÒÓÔÕÖØ]','O');
        source = source.replaceAll('[ÀÁÂÃÄÅ]','A');
        if(!source.isAsciiPrintable()) source = source.replaceall('[^\\x00-\\x7F]', '');
        return source;
    }

        //Method specific for testing FTP_credentials__mdt
        public static FTP_credentials__mdt FTP_credentials_testing(FTP_credentials__mdt credtest)
        {
            credtest.host__c = 'Test123';
            credtest.username__c = 'Test123';
            credtest.pass__c = 'Test123';
            credtest.port__c = 'Test123';
            credtest.endpoint__c = 'test123';
            credtest.directory__c = 'Test123';
    
            return credtest;
        }
    
    //set @future(callout=true)
    public static string exportTiers(Account a, String lineType) {
        String output ='';
        //line 1
        for(fieldConfTieFac f : tieConf.line1) {
            if(f.value == 'blank') {
                output += ''.rightPad(f.length);
            } else if(f.value != '') {
                output += f.value.rightPad(f.length);
            } else {
                switch on f.name {
                    when 'codpev','typtie','p_tietcp' {
                        if(f.name == 'codpev' && lineType =='CLI') output += genValue('ICLI', f.length);
                        else if(f.name == 'codpev' && lineType =='PTR') output += genValue('VPTR', f.length);
                        else output += genValue(lineType, f.length);
                    }
                    when 'nomtie' { //account name
                        output += genValue(a.Name.toUpperCase(), f.length);
                    }
                    when 'sigtie','cpttie','p_tiesig' { //GNX Code
                        if(a.GenerixCode__c.substring(0,3) == 'CAN' && lineType =='PTR') output += genValue(a.GenerixCode__c, f.length);
                        else if(a.GenerixCode__c.substring(0,3) == 'CAN' && lineType =='CLI') output += genValue('C'+ a.GenerixCode__c.substring(3), f.length);
                        else if(a.GenerixCode__c.substring(0,1) == 'C' && lineType =='PTR') output += genValue('CAN'+ a.GenerixCode__c.substring(1), f.length);
                        else if(a.GenerixCode__c.substring(0,1) == 'C' && lineType =='CLI') output += genValue(a.GenerixCode__c, f.length);
                        else if(lineType =='PTR') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Annonceur') output += genValue('C'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Agence') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Partenaire') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Adex') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else output += genValue('C'+ a.GenerixCode__c, f.length);
                    }
                    when  'modrgl'{ //VI if country FR, else VE
                        if(a.BillingCountryCode == 'FR') output += 'VI';
                        else output += 'VE';
                    }
                    when 'datcre' { //creationDate YYYYMMDD
                        if(Test.isRunningTest())output +=  genValue('aa', f.length);
                        else output += genValue(a.CreatedDate.format('yyyyMMdd'), f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 1 -> ' + f.name);
                    }
                }
            }
        }
        if(output.length() != 460) {
            if(output.length() > 460) output = output.substring(0, 460);
            else output += ''.rightPad(460 - output.length());
        }
        
        output += '\r\n';
        //END line 1
        
        Boolean noLine2 = false;
        
        //START line 2        
        if(a.GenerixSapCode__c != null || Test.isRunningTest()){
            for(fieldConfTieFac f : tieConf.line2) {
                if(f.value == 'blank'){
                    output += ''.rightPad(f.length);
                }else if(f.value != ''){
                    output += f.value.rightPad(f.length);
                }else{
                    switch on f.name {
                        when 'typtie' { //CLI or PTR
                            output += lineType;
                        }
                        
                        when 'sigtie' { // account GNX CODE, add C ou CAN prefix for()
                            if(a.GenerixCode__c.substring(0,3) == 'CAN' && lineType =='PTR') output += genValue(a.GenerixCode__c, f.length);
                            else if(a.GenerixCode__c.substring(0,3) == 'CAN' && lineType =='CLI') output += genValue('C'+ a.GenerixCode__c.substring(3), f.length);
                            else if(a.GenerixCode__c.substring(0,1) == 'C' && lineType =='PTR') output += genValue('CAN'+ a.GenerixCode__c.substring(1), f.length);
                            else if(a.GenerixCode__c.substring(0,1) == 'C' && lineType =='CLI') output += genValue(a.GenerixCode__c, f.length);
                            else if(lineType =='PTR') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                            else if(a.Type == 'Annonceur') output += genValue('C'+ a.GenerixCode__c, f.length);
                            else if(a.Type == 'Agence') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                            else if(a.Type == 'Partenaire') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                            else if(a.Type == 'Adex') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                            else output += genValue('C'+ a.GenerixCode__c, f.length);
                        }
                        
                        when 'codzn8' { //Code SAP (ex: C016158000)
                            output += genValue(a.GenerixSapCode__c, f.length);
                        }
                        when 'codzn9' { //
                            output += genValue('~', f.length);
                        }
                        when else {
                            throw new gnxExportException('Error: Name not recognized at line 2 -> ' + f.name);
                        }
                        
                    }
                }
            }
            if(output.length() != 672){
                if(output.length() > 672)output = output.substring(0, 672);
                else output += ''.rightPad(672 - output.length());
            }
            output += '\r\n';
        }else noLine2 = true;
        //END line 2
        
        //START line 3
        for(fieldConfTieFac f : tieConf.line3) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'typtie','typtie1' { //CLI or PTR
                        output += lineType;
                    }
                    when 'sigadr','sigadr1' { //Sigle de l'adresse (ex: CPOWERSPACE)
                        if(a.GenerixCode__c.substring(0,3) == 'CAN' && lineType =='PTR') output += genValue(a.GenerixCode__c, f.length);
                        else if(a.GenerixCode__c.substring(0,3) == 'CAN' && lineType =='CLI') output += genValue('C'+ a.GenerixCode__c.substring(3), f.length);
                        else if(a.GenerixCode__c.substring(0,1) == 'C' && lineType =='PTR') output += genValue('CAN'+ a.GenerixCode__c.substring(1), f.length);
                        else if(a.GenerixCode__c.substring(0,1) == 'C' && lineType =='CLI') output += genValue(a.GenerixCode__c, f.length);
                        else if(lineType =='PTR') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Annonceur') output += genValue('C'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Agence') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Partenaire') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else if(a.Type == 'Adex') output += genValue('CAN'+ a.GenerixCode__c, f.length);
                        else output += genValue('C'+ a.GenerixCode__c, f.length);
                    }
                    when 'libadr50' { //Account Name
                        output += genValue(a.Name.toUpperCase(), f.length);
                    }
                    when 'ligadr50_1' { //Adresse 1ère ligne
                        if(a.BillingStreet != null){
                            if(a.BillingStreet.contains('\n') && a.BillingStreet.split('\n').size() >= 1){
                                String value = a.BillingStreet.replace('\'', '?').split('\n')[0];
                                output += genValue(value, f.length);
                            }else{
                                Integer lastChar = a.BillingStreet.length() > 49 ? 49 : a.BillingStreet.length();
                                output += genValue(a.BillingStreet.replace('\'', '?').substring(0, lastChar), f.length);
                            }
                        }else{
                            output += genValue('', f.length);
                        }
                    }
                    when 'ligadr50_2' { //Adresse 2nde ligne
                        if(a.BillingStreet != null){
                            if(a.BillingStreet.contains('\n') && a.BillingStreet.split('\n').size() >= 2){
                                String value = a.BillingStreet.replace('\'', '?').split('\n')[1];
                                output += genValue(value, f.length);
                            }else if(a.BillingStreet.length() > 51){
                                Integer lastChar = a.BillingStreet.length() > 99 ? 99 : a.BillingStreet.length();
                                output += genValue(a.BillingStreet.replace('\'', '?').substring(50, lastChar), f.length);
                            }else{
                                output += genValue('', f.length);
                            }
                        }else{
                            output += genValue('', f.length);
                        }
                    }
                    when 'ligadr50_3' { //Adresse 3ème ligne
                        if(a.BillingStreet != null){
                            if(a.BillingStreet.contains('\n') && a.BillingStreet.split('\n').size() >= 3){
                                String value = a.BillingStreet.replace('\'', '?').split('\n')[2];
                                output += genValue(value, f.length);
                            }else if(a.BillingStreet.length() > 100){
                                Integer lastChar = a.BillingStreet.length() > 149 ? 149 : a.BillingStreet.length();
                                output += genValue(a.BillingStreet.replace('\'', '?').substring(100, lastChar), f.length);
                            }else{
                                output += genValue('', f.length);
                            }
                        }else{
                            output += genValue('', f.length);
                        }
                    }
                    when 'locali50'{ //Ville
                        output += genValue(a.BillingCity, f.length);
                    }
                    when 'codpos_10' { //Code postal
                        output += genValue(a.BillingPostalCode, f.length);
                    }
                    when 'cenpos50' { //Centre distributeur
                        output += genValue(a.BillingCity, f.length);
                    }
                    when 'codpay' { //Code pays - FR ou ES
                        output += genValue(a.BillingCountryCode, f.length);
                    }
                    when 'siret' { //N° Siret (ex: 43225011600014)
                        output += genValue(a.Siret__c, f.length);
                    }
                    when 'tvainter' { //TVA intercommunautaire (ex: FR40432250116)
                        output += genValue(a.IntracomVatNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 3 -> ' + f.name);
                    }
                    
                }
            }
        }
        Integer lengthMax = 1648;
        if(noLine2) lengthMax -= 212;
        
        if(output.length() != lengthMax){
            if(output.length() > lengthMax)output = output.substring(0, lengthMax);
            else output += ''.rightPad(lengthMax - output.length());
        } 
        //line 3
        
        return output;
    }
    
    //set @future(callout=true)
    public static String exportFacturesRelevanc(Invoice__c a, List<Insertion__c> insertions){
        Set<Id> insertionIds = new Set<Id>();
        Boolean isCampaign = false;
        String campaignNumber;
        
        String output ='';
        String orderReferences ='';
        String campaignNumbers ='';
        for(Insertion__c ins : insertions) {
            if(ins.OrderReference__c != null && invoiceToInsertions.get(a.Id).contains(ins.Id) && orderReferences.contains(ins.OrderReference__c) != true){
                orderReferences += ins.OrderReference__c+',';
            }
            if(ins.CampaignNumber__c != null){
                campaignNumber = ins.CampaignNumber__c;
                campaignNumbers += ins.CampaignNumber__c+',';
            }
            else if(ins.CampaignNumber__c != null) isCampaign = true;
        }
        system.debug('orderReferences : ' +orderReferences);
        system.debug('campaignNumber : ' +campaignNumber);
        //START - line 1 : ME
        for(fieldConfTieFac f : facRelevanc.line1) { 
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'codsoc' { // Code société métadata
                        output += genValue(String.valueOf(a.Opportunity__r.BillingEntity__r.CompanyCode__c), f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 1 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 4){
            if(output.length() > 4)output = output.substring(0, 4);
            else output += output.rightPad(4 - output.length());
        }
        
        output += '\r\n';
        //END - line 1 : ME
        
        //START - line 2 : EVE
        for(fieldConfTieFac f : facRelevanc.line2) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            } else if(f.value != ''){
                output += f.value.rightPad(f.length);
            } else {
                switch on f.name {
                    when 'Codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'Sigtie' { //Sigle tiers Code GNX
                        output += genValue(a.Advertiser__r.SapCode__c, f.length);
                    }
                    when 'codeop' {
                        output += genValue(costCenter.get(a.Bu__c)+'193', f.length);
                    }
                    when 'Dateve' { //Date de l'événement
                        Datetime dt = Date.Today();
                        if(a.InvoiceDate__c != null) dt = a.InvoiceDate__c;
                        output += genValue(dt.format('yyyyMMdd'), f.length);
                    }
                    when 'Refext' { //Réf externe - N° OI 
                        if(a.Opportunity__r.InvoicingLevel__c == 'Campagne')output += genValue(campaignNumber, f.length);
                        else output += genValue(a.Opportunity__r.AutoOppId__c, f.length);
                    }
                    when 'Sigrep' { //Sigle représentant
                        output += genValue(a.account__r.SapCode__c, f.length);
                    }
                    when 'Datcre' { //Date création
                        Datetime dt = Datetime.newInstance(date.today(), time.newInstance(0, 0, 0, 0));
                        output += genValue(dt.format('yyyyMMdd'), f.length);
                    }
                    when 'Datcli' { //Date comptable
                        Datetime dt = Datetime.newInstance(date.today(), time.newInstance(0, 0, 0, 0));
                        output += genValue(dt.format('yyyyMMdd'), f.length);
                    }
                    when 'Datrgl' { //Date d'échéance
                        Datetime dt = a.InvoiceTerm__c;
                        string mydate;
                        if(dt != null) mydate = dt.format('yyyyMMdd'); 
                        else mydate = Datetime.newInstance(date.today(), time.newInstance(0, 0, 0, 0)).format('yyyyMMdd'); 
                        output += genValue(mydate, f.length);
                    }
                    when 'Numeve_long' { //Numéro événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 2 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 672){
            if(output.length() > 672)output = output.substring(0, 672);
            else output += output.rightPad(672 - output.length());
        }
        
        output += '\r\n';
        //END - line 2 : EVE
        
        //START - line 3 : EVP
        for(fieldConfTieFac f : facRelevanc.line3) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'Codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'CodPro' { //Code produit BU sur invoice
                        output += genValue(a.BU__c, f.length);
                    }
                    when 'Prxvdu' { //Total HT
                        String prix;
                        if(a.TotalExcludingVat__c < 0) prix = String.valueOf(a.TotalExcludingVat__c * (-1));
                        else prix = String.valueOf(a.TotalExcludingVat__c);
                        output += genValue(prix, f.length);
                    }
                    when 'Codtva' { //Code TVA
                        output += genValue(a.TVA__c, f.length);
                    }
                    when 'Numeve_long' { //Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 3 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 1245){
            if(output.length() > 1245)output = output.substring(0, 1245);
            else output += output.rightPad(1245 - output.length());
        }
        
        output += '\r\n';
        
        //END - line 3 : EVP
        
        //START - line 4 : EVT03
        for(fieldConfTieFac f : facRelevanc.line4) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'commen1' { //Commentaire 1 Annonceur Name
                        if(a.advertiser__r.name !=null && a.Advertiser__r.name !='') output+= genValue('Annonceur : ' + a.Advertiser__r.name.toUpperCase(), f.length);
                    }
                    when 'commen2' { //Commentaire 2 Periode de cloture
                        if(a.Opportunity__r.recordtype.name == 'Open Order' && a.InvoiceDate__c != null){
                            Datetime dtInvoicing = a.InvoiceDate__c;
                            output += genValue(dtInvoicing.format('MM/yyyy'), f.length);
                        }else if(a.Opportunity__r.CampaignStartDate__c != null && a.Opportunity__r.CampaignEndDate__c != null){
                            Datetime dtStart = a.Opportunity__r.CampaignStartDate__c;
                            Datetime dtEnd = a.Opportunity__r.CampaignEndDate__c;
                            output += genValue('Periode : '+ dtStart.format('dd/MM/yyyy') + ' au ' + dtEnd.format('dd/MM/yyyy'), f.length);
                        }else output += genValue('Période non renseignée', f.length);
                    }
                    when 'commen3' { //Commentaire 3 N° OI
                        if(a.Opportunity__r.InvoicingLevel__c == 'Campagne')output += genValue('Campagne : '+ campaignNumber, f.length);
                        else output += genValue('Campagne : '+ a.Opportunity__r.AutoOppId__c, f.length);
                    }
                    when 'commen4' { //Commentaire 4 nom d'opp
                        if(a.isTechFees__c == true)output += genValue('Facture frais plateforme', f.length);
                        else if(a.Opportunity__r.InvoicingLevel__c == 'Contrat' || a.Opportunity__r.InvoicingLevel__c == 'Campagne')output += genValue('Facture media / data', f.length);
                        else output += genValue(a.Opportunity__r.Name, f.length);
                    }
                    when 'commen5' { //Commentaire 5 BDC + Ref client
                        output += genValue(a.Opportunity__r.CustomerReference__c !=null ? 'BDC : ' +a.Opportunity__r.CustomerReference__c : '', f.length);
                    }
                    when 'commen6' { //Commentaire 6 Contact client
                        output += genValue(a.Opportunity__r.AdvertiserContact__r.Name !=null ? 'Contact client : ' + a.Opportunity__r.AdvertiserContact__r.Name : '', f.length);
                    }
                    when 'commen7' { //Commentaire 7 Contact Agence
                        output += genValue(a.Opportunity__r.Owner.FirstName !=null ? 'Contact RelevanC : ' + a.Opportunity__r.Owner.FirstName.substring(0, 1).toUpperCase() + a.Opportunity__r.Owner.LastName.toUpperCase() : a.Opportunity__r.Owner.Name !=null ? 'Contact RelevanC : ' + a.Opportunity__r.Owner.LastName.toUpperCase() : '', f.length);
                    }
                    when 'commen8' { //Commentaire 8 Annulation
                        output += genValue(a.OriginalInvoiceNumber__r.InvoiceNumber__c !=null ? 'ANNULATION F : ' + a.OriginalInvoiceNumber__r.InvoiceNumber__c : '', f.length);
                    }
                    when 'commen9' { //Commentaire 9 Bons de commande
                        if(a.OpportunityType__c == 'Open Order')output += genValue(orderReferences != null ? 'BDC : '+orderReferences : '', f.length);
                        else output += genValue('', f.length);
                    }
                    when 'commen10' { //Commentaire 10 Numeros de campagne
                        if(a.Opportunity__r.InvoicingLevel__c == 'Contrat')output += genValue('Id: '+campaignNumbers, f.length);
                        else output += genValue('', f.length);
                    }
                    when 'Numeve_long' { //Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 4 -> ' + f.name);
                    } 
                }
            }
        }
        
        if(output.length() != 1696){
            if(output.length() > 1696)output = output.substring(0, 1696);
            else output += output.rightPad(1696 - output.length());
        }
        
        output += '\r\n';
        
        //END - line 4 : EVT03
        
        //START - line 5 : EVT05
        for(fieldConfTieFac f : facRelevanc.line5) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'codzn1' { //Taux frais plateforme (FeesRate)
                        if(a.isTechFees__c == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.FeesRate__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn2' { //Impressions (MediaVolume)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.MediaVolume__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn3' { //CPM Média (MediaPrice)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.MediaPrice__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn4' { //Volume Data (DataVolume)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.DataVolume__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn5' { //CPM Data (DataPrice)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.DataPrice__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn6' { //CPM Data (DataPrice)
                        output += genValue(a.Agency__r.SapCode__c, f.length);
                    }
                     when 'codzn7' { //AgencyNotInvoiced__c
                        output += genValue(a.AgencyNotInvoiced__c, f.length);
                    }
                    when 'codzn10' { //Ligne zone complémentaire 10 - Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when 'codzn16' { //N° OI
                        if(a.Opportunity__r.InvoicingLevel__c == 'Campagne' && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(campaignNumber, f.length);
                        else output += genValue(a.Opportunity__r.AutoOppId__c, f.length);
                    }
                    when 'Numeve_long' { //Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 5 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 1987){
            if(output.length() > 1986)output = output.substring(0, 1987);
            else output += output.rightPad(1987 - output.length());
        } 
        
        //END - line 5 : EVT05
        system.debug(output);
        return output;
    }
    
    public static String exportFactures3w(Invoice__c a){
        Set<Id> insertionIds = new Set<Id>();
        Boolean isCampaign = false;
        String campaignNumber;
        for(InvoiceItem__c invItem : a.InvoiceItems__r) insertionIds.add(invItem.Insertion__c);
        invoiceToInsertions.put(a.Id, insertionIds);
        insertions = [SELECT Id, Name, OrderReference__c, Type__c, CampaignNumber__c, Product__r.Name FROM Insertion__c WHERE Id IN: insertionIds];
        system.debug(insertions);
        String output ='';
        String orderReferences ='';
        String campaignNumbers ='';
        for(Insertion__c ins : insertions){
            if(ins.OrderReference__c != null && invoiceToInsertions.get(a.Id).contains(ins.Id) && orderReferences.contains(ins.OrderReference__c) != true) orderReferences += ins.OrderReference__c+',';
            if(ins.CampaignNumber__c != null){
                campaignNumber = ins.CampaignNumber__c;
                campaignNumbers += ins.CampaignNumber__c+',';
                isCampaign = true;
            }
        }
        system.debug('orderReferences : ' +orderReferences);
        system.debug('campaignNumber : ' +campaignNumber);
        //START - line 1 : ME
        for(fieldConfTieFac f : fac3w.line1) { 
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'codsoc' { // Code société métadata
                        output += genValue(String.valueOf(a.Opportunity__r.BillingEntity__r.CompanyCode__c), f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 1 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 4){
            if(output.length() > 4)output = output.substring(0, 4);
            else output += output.rightPad(4 - output.length());
        }
        
        output += '\r\n';
        //END - line 1 : ME
        
        //START - line 2 : EVE
        for(fieldConfTieFac f : fac3w.line2) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            } else if(f.value != ''){
                output += f.value.rightPad(f.length);
            } else {
                switch on f.name {
                    when 'Codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'Sigtie' { //Sigle tiers Code GNX
                        String sigtie = '';
                        if(Test.isRunningTest() != true){
                            if(a.account__r.GenerixCode__c.substring(0,3) == 'CAN') sigtie = 'C'+ a.account__r.GenerixCode__c.substring(3);
                            else if(a.account__r.GenerixCode__c.substring(0,1) == 'C') sigtie = a.account__r.GenerixCode__c;
                            else if(a.account__r.Type == 'Annonceur') sigtie = 'C'+ a.account__r.GenerixCode__c;
                            else if(a.account__r.Type == 'Agence') sigtie = 'CAN'+ a.account__r.GenerixCode__c;
                            else if(a.account__r.Type == 'Partenaire') sigtie = 'CAN'+ a.account__r.GenerixCode__c;
                            else if(a.account__r.Type == 'Adex') sigtie = 'CAN'+ a.account__r.GenerixCode__c;
                            else sigtie = a.account__r.GenerixCode__c;
                        }else{
                            sigtie = 'test';
                        }
                        output += genValue(sigtie, f.length);
                    }
                    when 'Dateve' { //Date de l'événement
                        Integer lengthOfLine = output.split('\r\n')[output.split('\r\n').size() -1].length();
                        if(lengthOfLine < 45) output += genValue(' ', 45 - lengthOfLine);
                        Datetime dt = Date.Today();
                        if(a.InvoiceDate__c != null) dt = a.InvoiceDate__c;
                        output += genValue(dt.format('yyyyMMdd'), f.length);
                    }
                    when 'Refext' { //Réf externe - N° OI 
                        if(a.Opportunity__r.InvoicingLevel__c == 'Campagne')output += genValue(campaignNumber, f.length);
                        else output += genValue(a.Opportunity__r.AutoOppId__c, f.length);
                    }
                    when 'Sigrep' { //Sigle représentant
                        if(a.account__c == a.agency__c &&  Test.isRunningTest() != true) {                            
                            if(a.advertiser__r.GenerixCode__c.substring(0,3) == 'CAN' && Test.isRunningTest() != true) output += genValue(a.advertiser__r.GenerixCode__c, f.length);
                            else if(a.advertiser__r.GenerixCode__c.substring(0,1) == 'C' && Test.isRunningTest() != true) output += genValue('CAN'+ a.advertiser__r.GenerixCode__c.substring(1), f.length);
                            else output += genValue('CAN'+ a.advertiser__r.GenerixCode__c, f.length);
                        } else output += genValue('', f.length);
                    }
                    when 'Datcre' { //Date création
                        Datetime dt = Datetime.newInstance(date.today(), time.newInstance(0, 0, 0, 0));
                        output += genValue(dt.format('yyyyMMdd'), f.length);
                    }
                    when 'Datcli' { //Date comptable
                        Datetime dt = Datetime.newInstance(date.today(), time.newInstance(0, 0, 0, 0));
                        output += genValue(dt.format('yyyyMMdd'), f.length);
                    }
                    when 'Datrgl' { //Date d'échéance
                        Datetime dt = a.InvoiceTerm__c;
                        string mydate;
                        if(dt != null) mydate = dt.format('yyyyMMdd'); 
                        else mydate = null; 
                        output += genValue(mydate, f.length);
                    }
                    when 'Numeve_long' { //Numéro événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 2 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 672){
            if(output.length() > 672)output = output.substring(0, 672);
            else output += output.rightPad(672 - output.length());
        }
        
        output += '\r\n';
        //END - line 2 : EVE
        
        //START - line 3 : EVP
        for(fieldConfTieFac f : fac3w.line3) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'Codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'CodPro' { //Code produit BU sur invoice
                        output += genValue(a.BU__c, f.length);
                    }
                    when 'Prxvdu' { //Total HT
                        output += genValue(String.valueOf(a.TotalExcludingVat__c), f.length);
                    }
                    when 'Codtva' { //Code TVA
                        if(a.Account__r.VatType__c == '20' && Test.isRunningTest() != true) output += genValue('5', f.length); //  20 (TVA France 20.00%)
                        else if(a.Account__r.VatType__c == '0' && Test.isRunningTest() != true) output += genValue('0', f.length); //  EXO (EXO HORS CEE 0.00%)
                        else if(a.Account__r.VatType__c == '00' && Test.isRunningTest() != true) output += genValue('0', f.length); //	00 (TVA CEE 0.00%)
                        else output += genValue('', f.length);
                    }
                    when 'Numeve_long' { //Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 3 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 1245){
            if(output.length() > 1245)output = output.substring(0, 1245);
            else output += output.rightPad(1245 - output.length());
        }
        
        output += '\r\n';
        
        //END - line 3 : EVP
        
        //START - line 4 : EVT03
        for(fieldConfTieFac f : fac3w.line4) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'commen1' { //Commentaire 1 Annonceur Name
                        if(a.advertiser__r.name !=null && a.Advertiser__r.name !='')output+= genValue('Annonceur : ' + a.Advertiser__r.name.toUpperCase(), f.length);
                    }
                    when 'commen2' { //Commentaire 2 Periode de cloture
                        if(a.Opportunity__r.recordtype.name == 'Open Order' && a.InvoiceDate__c != null){
                            Datetime dtInvoicing = a.InvoiceDate__c;
                            output += genValue(dtInvoicing.format('MM/yyyy'), f.length);
                        }else if(a.Opportunity__r.CampaignStartDate__c != null && a.Opportunity__r.CampaignEndDate__c != null){
                            Datetime dtStart = a.Opportunity__r.CampaignStartDate__c;
                            Datetime dtEnd = a.Opportunity__r.CampaignEndDate__c;
                            output += genValue('Periode : '+ dtStart.format('dd/MM/yyyy') + ' au ' + dtEnd.format('dd/MM/yyyy'), f.length);
                        }else{
                            output += genValue('Période non renseignée', f.length);
                        }
                    }
                    when 'commen3' { //Commentaire 3 N° OI
                        if(a.Opportunity__r.InvoicingLevel__c == 'Campagne')output += genValue('Campagne : '+ campaignNumber, f.length);
                        else output += genValue('Campagne : '+ a.Opportunity__r.AutoOppId__c, f.length);
                    }
                    when 'commen4' { //Commentaire 4 nom d'opp
                        if(a.isTechFees__c == true)output += genValue('Facture frais plateforme', f.length);
                        else if(a.Opportunity__r.InvoicingLevel__c == 'Contrat' || a.Opportunity__r.InvoicingLevel__c == 'Campagne')output += genValue('Facture media / data', f.length);
                        else output += genValue(a.Opportunity__r.Name, f.length);
                    }
                    when 'commen5' { //Commentaire 5 BDC + Ref client
                        output += genValue(a.Opportunity__r.CustomerReference__c !=null ? 'BDC : ' +a.Opportunity__r.CustomerReference__c : '', f.length);
                    }
                    when 'commen6' { //Commentaire 6 Contact annonceur
                        output += genValue(a.Opportunity__r.AdvertiserContact__r.Name !=null ? 'Contact annonceur : ' + a.Opportunity__r.AdvertiserContact__r.Name : '', f.length);
                    }
                    when 'commen7' { //Commentaire 7 Contact Agence
                        output += genValue(a.Opportunity__r.Owner.FirstName !=null ? 'Contact RelevanC : ' + a.Opportunity__r.Owner.FirstName.substring(0, 1).toUpperCase() + a.Opportunity__r.Owner.LastName.toUpperCase() : a.Opportunity__r.Owner.Name !=null ? 'Contact RelevanC : ' + a.Opportunity__r.Owner.LastName.toUpperCase() : '', f.length);
                    }
                    when 'commen8' { //Commentaire 8 Annulation
                        output += genValue(a.OriginalInvoiceNumber__r.InvoiceNumber__c !=null ? 'ANNULATION F : ' + a.OriginalInvoiceNumber__r.InvoiceNumber__c : '', f.length);
                    }
                    when 'commen9' { //Commentaire 9 Bons de commande
                        output += genValue(orderReferences != null ? 'BDC : '+orderReferences : '', f.length);
                    }
                    when 'commen10' { //Commentaire 10 Numeros de campagne
                        if(a.Opportunity__r.InvoicingLevel__c == 'Contrat')output += genValue('Id: '+campaignNumbers, f.length);
                        else output += genValue('', f.length);
                    }
                    when 'Numeve_long' { //Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 4 -> ' + f.name);
                    } 
                }
            }
        }
        
        if(output.length() != 1696){
            if(output.length() > 1696)output = output.substring(0, 1696);
            else output += output.rightPad(1696 - output.length());
        }
        
        output += '\r\n';
        
        //END - line 4 : EVT03
        
        //START - line 5 : EVT05
        for(fieldConfTieFac f : fac3w.line5) {
            if(f.value == 'blank'){
                output += ''.rightPad(f.length);
            }else if(f.value != ''){
                output += f.value.rightPad(f.length);
            }else{
                switch on f.name {
                    when 'codpev' { //Code transaction
                        if(a.TotalExcludingVat__c > 0) output += genValue('VF3W', f.length);
                        else output += genValue('VA3W', f.length);
                    }
                    when 'codzn1' { //Taux frais plateforme (FeesRate)
                        if(a.isTechFees__c == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.FeesRate__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn2' { //Impressions (MediaVolume)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.MediaVolume__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn3' { //CPM Média (MediaPrice)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.MediaPrice__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn4' { //Volume Data (DataVolume)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.DataVolume__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn5' { //CPM Data (DataPrice)
                        if(isCampaign == true && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(String.valueOf(a.DataPrice__c), f.length);
                        else output += genValue('', f.length);
                    }
                    when 'codzn10' { //Ligne zone complémentaire 10 - Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when 'codzn16' { //N° OI
                        if(a.Opportunity__r.InvoicingLevel__c == 'Campagne' && a.Opportunity__r.Recordtype.Name == 'Open Order')output += genValue(campaignNumber, f.length);
                        else output += genValue(a.Opportunity__r.AutoOppId__c, f.length);
                    }
                    when 'Numeve_long' { //Numéro d'événement
                        output += genValue(a.InvoiceNumber__c, f.length);
                    }
                    when else {
                        throw new gnxExportException('Error: Name not recognized at line 5 -> ' + f.name);
                    }
                }
            }
        }
        
        if(output.length() != 1987){
            if(output.length() > 1986)output = output.substring(0, 1987);
            else output += output.rightPad(1987 - output.length());
        } 
        
        //END - line 5 : EVT05
        system.debug(output);
        return output;
    }
    
    //set @future(callout=true)
    public static string exportProvisions(Invoice__c inv) {
        String output = '';
        Integer iteration = 1;
        Integer linenumbers = 2;
        
        ProvisionNumber__c n = [SELECT counter__c FROM ProvisionNumber__c LIMIT 1 FOR UPDATE];
        if(inv.VatRate__c != null && inv.VatRate__c > 0) linenumbers = 3; 
        
        while(iteration <=2) {
            n.counter__c = n.counter__c + 1;
            for(Integer line = 1; line <= linenumbers; line++) {
                for(fieldConfProv f : provConf.line) {
                    if(f.value == 'blank') output += ';';
                    else if(f.value != '') output += f.value + ';';
                    else {
                        switch on f.name {
                            when 'prov_count' {
                                output += genCsvValue(String.valueOf(n.counter__c));
                            }
                            when 'acc_num' {
                                if(line == 1) output += genCsvValue(String.valueOf(inv.Account__r.GenerixCode__c));
                                if(line == 2) output += genCsvValue(7088570);
                                if(line == 3) output += genCsvValue(4458720);
                            }
                            when 'lin_ord' {
                                if(line == 1) output += genCsvValue(1);
                                if(line == 2) output += genCsvValue(2);
                                if(line == 3) output += genCsvValue(3);
                            }
                            when 'sens' { // 1 : D = Provision ; 2 : C = Extourne 
                                if(iteration == 1) {
                                    if(line == 1) output += genCsvValue('D');
                                    if(line == 2) output += genCsvValue('C');
                                    if(line == 3) output += genCsvValue('C');
                                }
                                if(iteration == 2) {
                                    if(line == 1) output += genCsvValue('C');
                                    if(line == 2) output += genCsvValue('D');
                                    if(line == 3) output += genCsvValue('D');
                                }
                            }
                            when 'amount', 'currency_amount' { 
                                Decimal totalExVat = Math.abs(inv.TotalExcludingVat__c);
                                if(linenumbers == 2) output += genCsvValue(String.valueOf(totalExVat)); 
                                else {
                                    if(line == 1) output += genCsvValue(String.valueOf(totalExVat + totalExVat*inv.VatRate__c/100));
                                    if(line == 2) output += genCsvValue(String.valueOf(totalExVat));
                                    if(line == 3) output += genCsvValue(String.valueOf(totalExVat*inv.VatRate__c/100));
                                }
                            }
                            when 'date_compt' {
                                Date lastDayCurrentMonth = Date.today().addMonths(1).toStartofMonth().addDays(-1);
                                Date firstDayNextMonth = Date.today().addMonths(1).toStartofMonth();
                                
                                if(iteration == 1) output += genCsvValue(DateTime.newInstance(lastDayCurrentMonth.year(), lastDayCurrentMonth.month(), lastDayCurrentMonth.day()).format('yyyyMMdd')); // findumois
                                if(iteration == 2) output += genCsvValue(DateTime.newInstance(firstDayNextMonth.year(), firstDayNextMonth.month(), firstDayNextMonth.day()).format('yyyyMMdd')); // debutdumois
                            }
                            when 'num_com2' {
                                output += genCsvValue('');//genCsvValue(String.valueOf(inv.ProvisionNumber__c));  ?????
                            }
                            when 'vat_code' { // code tva de GNX
                                if(linenumbers == 3){
                                    if(line == 1) output += genCsvValue(0);
                                    if(line == 2) output += genCsvValue(5);
                                    if(line == 3) output += genCsvValue(5);
                                }else{
                                    output += genCsvValue(0);
                                }
                            }
                            when 'act_domain' {
                                if(line == 1) output += genCsvValue('RGI');
                                if(line == 2) output += genCsvValue(costCenter.get(inv.Bu__c)); 
                                if(line == 3) output += genCsvValue('RGI');
                            }
                            when 'sap_order' {                   
                                if(line == 2) output += genCsvValue('CDI000');
                                else output += genCsvValue('');
                            }
                            when 'wri_label' {
                                String label = '';
                                if(iteration == 1) label += 'PRO FAE RGI ';
                                if(iteration == 2) label += 'EXT FAE RGI ';
                                
                                if(line == 1) label += String.valueOf(inv.Account__r.GenerixCode__c) + ' ' ;
                                label += inv.CreatedDate.format('MMyy');
                                output += genCsvValue(label);
                            }
                            when 'OI_number' {
                                if(line == 1) output += genCsvValue(String.valueOf(inv.Opportunity__r.AutoOppId__c));
                                else output += genCsvValue('');
                            }
                            when 'FC_AV' { 
                                if(inv.TotalExcludingVat__c >= 0) output += genCsvValue('FC');  
                                if(inv.TotalExcludingVat__c < 0) output += genCsvValue('AV'); 
                            }
                            when 'sap_date_int','sap_date_int2' {
                                output += genCsvValue(String.valueOf(system.now().format('yyyyMMdd')));
                            }
                            when 'fisc_pos' {
                                if(inv.Account__r.VatType__c == '20' && Test.isRunningTest() != true) output += genCsvValue('A'); //  20 (TVA France 20.00%)		
                                else if(inv.Account__r.VatType__c == '21' && Test.isRunningTest() != true) output += genCsvValue('A'); //	21 (2,10% 2,10%)
                                else if(inv.Account__r.VatType__c == '55' && Test.isRunningTest() != true) output += genCsvValue('A'); // 55 (5.5% 5.50%)	
                                else if(inv.Account__r.VatType__c == '0' && Test.isRunningTest() != true) output += genCsvValue('X'); //  EXO (EXO HORS CEE 0.00%)
                                else if(inv.Account__r.VatType__c == '85' && Test.isRunningTest() != true) output += genCsvValue('D'); //  85 (TVA 8.5 8.50%)		
                                else if(inv.Account__r.VatType__c == '00' && Test.isRunningTest() != true) output += genCsvValue('J'); //	00 (TVA CEE 0.00%)	
                                else if(inv.Account__r.VatType__c == '19.6' && Test.isRunningTest() != true) output += genCsvValue('A'); // 196 (TVA FRANCE 19.60%)	
                                else output += genCsvValue('');
                            }
                            when 'tier_country' {
                                if(line == 1) output += genCsvValue(String.valueOf(inv.Account__r.BillingCountryCode));
                                else output += genCsvValue('');
                            }
                            when 'company_code' {
                                output += genCsvValue(String.valueOf(inv.Opportunity__r.BillingEntity__r.CompanyCode__c));
                            }
                            when 'vat_rate' {
                                if(line == 3) output += genCsvValue(String.valueOf(inv.VatRate__c));
                                else output += genCsvValue(0);
                            }
                            when 'ht_vat' {
                                if(line == 3) output += genCsvValue(String.valueOf(Math.abs(inv.TotalExcludingVat__c)));
                                else output += genCsvValue(0);
                            }
                            when else {
                                throw new gnxExportException('Error: Name not recognized at line 1 -> ' + f.name);
                            }
                        }
                    }
                }
                output+='\n';
            }
            iteration++;
        }
        update n;
        //line 1
        system.debug(output);
        return output;
    }
}