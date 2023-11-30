public class invoice_export {
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
    public static InfinityExportNumber__c infinityExportNumber{
        get{
            if (infinityExportNumber == null)
            infinityExportNumber = new InfinityExportNumber__c(Counter__c = 0);
            return infinityExportNumber;
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
    
    //Define Json structure
    class fieldConf {
        String name;
        Integer length;
        String value;
    }
    class lineConf {
        List<fieldConf> line1;
        List<fieldConf> line2;
        List<fieldConf> line3;
        List<fieldConf> line4;
    }
    
    public static List<Invoice__c> invoices;
    public static Map<String, String> costCenter;
    public static lineConf facInfinity;

    // Invoice_Export_Settings__mdt contains report and error mail adresses.
    public static Invoice_Export_Settings__mdt export_settings = [SELECT DeveloperName, info_recipients__c, error_recipients__c FROM Invoice_Export_Settings__mdt WHERE DeveloperName = 'Mail_Export_Recipients' limit 1];
    
    static {
        Blob infinityExportJson = [select body from StaticResource Where Name = 'model_infinity_export'].Body; 
        facInfinity = (lineConf)JSON.deserialize(infinityExportJson.toString(), lineConf.class);
        
        //cost_center
        List<cost_center__mdt> ccs = [SELECT BU__c, cost_center__c FROM cost_center__mdt];
        costCenter = new Map<String, String> ();
        for( cost_center__mdt cc : ccs) costCenter.put(cc.BU__c, cc.cost_center__c);
        costCenter.put(null, 'NO_BU');
    }
    
    public invoice_export(ApexPages.StandardSetController controller) {
        invoices = [SELECT Id, Name, TotalWithVat__c, VAT_Amount__c, InvoiceTerm__c, InvoiceDate__c, InvoiceNumber__c, Avoir__c, OI_Number__c, BU__c, Account__r.Centre_profit_partenaire__c, Account__r.PartnerCompany_Code__c, VatRate__c, TotalExcludingVat__c,
                    (select id, Insertion__c, TotalExcludingVat__c, VAT_Amount__c, Ordre_Interne__c from InvoiceItems__r)
                    FROM Invoice__c
                    WHERE Id IN :controller.getSelected()];
        List<InfinityExportNumber__c> ltin = [SELECT Id, Counter__c, LineCounter__c FROM InfinityExportNumber__c ORDER BY Counter__c DESC LIMIT 1];
        if (ltin.size() > 0) infinityExportNumber = ltin[0];
        else{
            infinityExportNumber = new infinityExportNumber__c(Counter__c = 0, LineCounter__c = 0);
        }
    }
    
    public static void exportInfinity() {
        Map<String, String> infDataMap = new Map<String, String>();
        for(Invoice__c i : invoices) {
            generatedInvoices.add(i.Name);
        }
        infDataMap.put('infinity', writeInfinityInvoice(invoices));
        
        if(generatedInvoices.size() > 0) {
            Document docFactures = new Document(body = Blob.valueOf(String.join(infDataMap.values(),'\r\n')),
                                                folderid = UserInfo.getUserId(),
                                                name = 'winLogic_InfinityAds_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
            insert docFactures;
            
            ContentVersion fichierFactures = new ContentVersion();
            fichierFactures.ContentLocation = 'S';
            fichierFactures.VersionData = docFactures.Body;
            fichierFactures.Title = docFactures.Name;
            fichierFactures.PathOnClient = docFactures.Name;
            insert fichierFactures;
            system.debug(docFactures.Id);
            generatedFiles.add(fichierFactures);
            Set<Id> docSet = new Set<Id>();
            docSet.add(docFactures.Id);
            exportToMail(docSet);
        }
    }
    
    public static Document exportInfinitySched(List<Invoice__c> invoices) {
        Map<String, String> infDataMap = new Map<String, String>();
        infDataMap.put('infinity', writeInfinityInvoice(invoices));
        Document docFactures = new Document(body = Blob.valueOf(String.join(infDataMap.values(),'\r\n')),
                                            folderid = UserInfo.getUserId(),
                                            name = 'winLogic_InfinityAds_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
        return docFactures;
    }
    
    
    public static String writeInfinityInvoice(List<Invoice__c> invoiceList) {
        List<InfinityExportNumber__c> ltin = [SELECT Id, Counter__c, LineCounter__c FROM InfinityExportNumber__c ORDER BY Counter__c DESC LIMIT 1];
        if (ltin.size() > 0) infinityExportNumber = ltin[0];
        else{
            infinityExportNumber = new infinityExportNumber__c(Counter__c = 0, LineCounter__c = 0);
        }
        String output ='';
        Date lastMonthDate = Date.today().addMonths(-1);
        infinityExportNumber.counter__c++;
        Set<Id> invItemIds = new Set<Id>();
        
        for(Invoice__c inv : invoiceList){
            infinityExportNumber.lineCounter__c++;
            //START - line 1 Invoice
            for(fieldConf f : facInfinity.line1) { 
                if(f.value == 'blank'){
                    output += genValue('', f.length);
                }else if(f.value != ''){
                    if(f.value == 'E') output += genValue('E ', f.length);
                    else output += genValue(f.value, f.length);
                }else{
                    switch on f.name {
                        when 'societe' { // Si compta multi sociétés sinon 00000
                            output += genValue('00000', f.length);
                        }
                        when 'dateOrigPiece' {
                            Datetime dt = Date.Today();
                            if(inv.InvoiceDate__c != null) dt = inv.InvoiceDate__c;
                            output += genValue(dt.format('yyyyMMdd'), f.length);
                        }
                        when 'dateCompta' {
                            Datetime dt = Date.Today();
                            output += genValue(dt.format('yyyyMMdd'), f.length);
                        }
                        when 'dateEcheance' {
                            if(1==1){
                                Datetime dt = Date.Today();
                                if(inv.InvoiceTerm__c != null) dt = inv.InvoiceTerm__c;
                                output += genValue(dt.format('yyyyMMdd'), f.length);
                            }else{
                                output += genValue('', f.length);
                            }
                        }
                        when 'numPiece' {
                            output += genValue(inv.InvoiceNumber__c, f.length);
                        }
                        when 'descEcriture' {
                            output += genValue('Facture '+inv.OI_Number__c, f.length);
                        }
                        when 'signMontantEcriture' {
                            String signe = inv.Avoir__c ? '-' : '+';
                            output += genValue(signe, f.length);
                        }
                        when 'montantEcriture' {
                            output += genValue(inv.TotalExcludingVat__c , f.length);
                        }
                        when 'signeMontantTva' {
                            String signe = inv.Avoir__c ? '-' : '+';
                            output += genValue(signe, f.length);
                        }
                        when 'montantTva' {
                            output += genValue(inv.VAT_Amount__c , f.length);
                        }
                        when 'sensEcriture' {
                            String signe = inv.Avoir__c ? 'D' : 'C';
                            output += genValue(signe, f.length);
                        }
                        when 'codeDevise' {
                            output += genValue('EUR', f.length);
                        }
                        when 'ModeReglement' {
                            output += genValue(getModeReglement('00'), f.length);
                        }
                        when 'journal' { //(ne pas renseigner sur les lignes analytiques)
                            output += genValue('VE', f.length);
                        }
                        when 'compteGeneral' {
                            output += genValue('', f.length);
                        }
                        when 'compteAux' {
                            output += genValue('', f.length);
                        }
                        when 'sectAnaly1' {
                            output += genValue('', f.length);
                        }
                        when 'sectAnaly2' {
                            output += genValue('', f.length);
                        }
                        when 'sectAnaly3' {
                            output += genValue('', f.length);
                        }
                        when 'codeOrigPiece' {
                            output += genValue('', f.length);
                        }
                        when 'numOrig' {
                            output += genValue(String.valueOf(infinityExportNumber.LineCounter__c), f.length);
                        }
                        when 'finEnreg' {
                            output += genValue(';', f.length);
                        }
                        when else {
                            throw new infinityExportException('Error: Name not recognized at line 1 -> ' + f.name);
                        }
                    }
                }
            }
            output += '\r\n';
            //END - line 1 Invoice

            for(InvoiceItem__c invItem : inv.InvoiceItems__r){
                //START - line 1 InvoiceItem
                for(fieldConf f : facInfinity.line1) { 
                    if(f.value == 'blank'){
                        output += genValue('', f.length);
                    }else if(f.value != ''){
                        if(f.value == 'E') output += genValue('E ', f.length);
                        else output += genValue(f.value, f.length);
                    }else{
                        switch on f.name {
                            when 'societe' { // Si compta multi sociétés sinon 00000
                                output += genValue('00000', f.length);
                            }
                            when 'dateOrigPiece' {
                                Datetime dt = Date.Today();
                                if(inv.InvoiceDate__c != null) dt = inv.InvoiceDate__c;
                                output += genValue(dt.format('yyyyMMdd'), f.length);
                            }
                            when 'dateCompta' {
                                Datetime dt = Date.Today();
                                output += genValue(dt.format('yyyyMMdd'), f.length);
                            }
                            when 'dateEcheance' {
                                if(1==1){
                                    Datetime dt = Date.Today();
                                    if(inv.InvoiceTerm__c != null) dt = inv.InvoiceTerm__c;
                                    output += genValue(dt.format('yyyyMMdd'), f.length);
                                }else{
                                    output += genValue('', f.length);
                                }
                            }
                            when 'numPiece' {
                                output += genValue(inv.InvoiceNumber__c, f.length);
                            }
                            when 'descEcriture' {
                                output += genValue('Facture '+inv.OI_Number__c, f.length);
                            }
                            when 'signMontantEcriture' {
                                String signe = inv.Avoir__c ? '-' : '+';
                                output += genValue(signe, f.length);
                            }
                            when 'montantEcriture' {
                                output += genValue(invItem.TotalExcludingVat__c, f.length);
                            }
                            when 'signeMontantTva' {
                                String signe = inv.Avoir__c ? '-' : '+';
                                output += genValue(signe, f.length);
                            }
                            when 'montantTva' {
                                output += genValue(invItem.VAT_Amount__c, f.length);
                            }
                            when 'sensEcriture' {
                                String signe = inv.Avoir__c ? 'D' : 'C';
                                output += genValue(signe, f.length);
                            }
                            when 'codeDevise' {
                                output += genValue('EUR', f.length);
                            }
                            when 'ModeReglement' {
                                output += genValue(getModeReglement('00'), f.length);
                            }
                            when 'journal' { //(ne pas renseigner sur les lignes analytiques)
                                output += genValue('', f.length);
                            }
                            when 'compteGeneral' {
                                output += genValue('', f.length);
                            }
                            when 'compteAux' {
                                output += genValue('', f.length);
                            }
                            when 'sectAnaly1' {
                                output += genValue('', f.length);
                            }
                            when 'sectAnaly2' {
                                output += genValue('', f.length);
                            }
                            when 'sectAnaly3' {
                                output += genValue('', f.length);
                            }
                            when 'codeOrigPiece' {
                                output += genValue('', f.length);
                            }
                            when 'numOrig' {
                                output += genValue(String.valueOf(infinityExportNumber.LineCounter__c), f.length);
                            }
                            when 'finEnreg' {
                                output += genValue(';', f.length);
                            }
                            when else {
                                throw new infinityExportException('Error: Name not recognized at line 1 -> ' + f.name);
                            }
                        }
                    }
                }
                output += '\r\n';
            }
            //END - line 1 InvoiceItem
            inv.SentInvoice__c = true;
        }
        output += '\r\n';
        update infinityExportNumber;
        update invoiceList;
        system.debug(output);
        return output;
    }
    
    public class infinityExportException extends Exception{}

    @future(callout = true)
    public static void exportToMail(Set<Id> docSet){
        Id emailTemplateId = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName = 'ExportedInvoices' LIMIT 1].Id;
        List<Document> listDoc = [SELECT Id, Name, Body, Bodylength FROM Document WHERE Id IN: docSet];
        List<Id> docIdList = new List<Id>();
        for(Id docId : docSet){
            docIdList.add(docId);
        }
        String exportedFiles ='';
        if(listDoc.size() > 0){
            exportedFiles+= '\r\n';
        }else{
            system.debug(docSet);
            system.debug('no files');
            return;
        } 
        Messaging.SingleEmailMessage[] mailList = new List<Messaging.SingleEmailMessage>{};
        for(Document file : listDoc){
            exportedFiles += file.Name+'\r\n';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String [] emailArray = Test.isRunningTest() ? new List<String>{'project@isochronix.com'} : export_settings.info_recipients__c.split(';');
            system.debug(emailArray);
            mail.toAddresses = emailArray;
            mail.setTemplateId(emailTemplateId);
            mail.setEntityAttachments(docIdList);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setTargetObjectId(UserInfo.getUserId());
            mailList.add(mail);
        }
        Messaging.SendEmailResult[] results = Messaging.sendEmail(mailList);
    }
    
    private static String genValue(String value, Integer validLength){
        if(value == null) value = '';
        if(value.length() > validLength) value = value.substring(0, validLength);
        else value = value.rightPad(validLength, ' ');
        return removeAccents(value);
    }

    private static String genValue(Decimal value, Integer validLength){
        String returnValue;
        if(value == null) value = 0;
        if(String.valueOf(value).remove('.').length() > validLength) returnValue = String.valueOf(value).remove('.').substring(0, validLength);
        else returnValue = String.valueOf(value).remove('.').leftPad(validLength, '0');
        return returnValue;
    }

    private static String genValueAsDecimal(String value, Integer validLength){
        if(value == null) value = '0';
        if(value.length() > validLength) value = value.substring(0, validLength);
        else value = value.leftPad(validLength, '0');
        return removeAccents(value);
    }

    public static List<Invoice__c> queryInvoiceExportFields(Set<Id> invoiceIds){
        return invoices = [SELECT Id, Name, TotalWithVat__c, VAT_Amount__c, InvoiceTerm__c, InvoiceDate__c, InvoiceNumber__c, Avoir__c, OI_Number__c, BU__c, Account__r.Centre_profit_partenaire__c, Account__r.PartnerCompany_Code__c, VatRate__c, TotalExcludingVat__c,
            (select id, Insertion__c, TotalExcludingVat__c, VAT_Amount__c, Ordre_Interne__c from InvoiceItems__r)
            FROM Invoice__c
            WHERE Id IN :invoiceIds];
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

    private static String getModeReglement(String code){
        Map<String, String> regMap = new Map<String, String>();
        regMap.put('Divers', '00'); 
        regMap.put('Espèces', '01'); 
        regMap.put('Chèque postal', '02'); 
        regMap.put('Chèque Bancaire', '03'); 
        regMap.put('Mandat administratif', '04'); 
        regMap.put('BOC', '05'); 
        regMap.put('LCC non sousmise accept.', '06'); 
        regMap.put('LCC accept.client', '07'); 
        regMap.put('LCC accept.banque', '08'); 
        regMap.put('LCC accept.domiciliée', '09'); 
        regMap.put('Virement postal', '10'); 
        regMap.put('Virement bancaire', '11'); 
        regMap.put('LCR-pap.non soumise accep', '12'); 
        regMap.put('LCR-pap. accept.client', '13'); 
        regMap.put('LCR-pap. accept.banque', '14'); 
        regMap.put('Prélèvement automatique', '15'); 
        regMap.put('BOR-pap.simple', '16'); 
        regMap.put('BOR-pap.accept.banque', '17'); 
        regMap.put('BOR-pap.aval client', '18'); 
        regMap.put('Transfert télégraphique', '19'); 
        regMap.put('LCR magnétique', '20'); 
        regMap.put('BOR magnétique', '21'); 
        regMap.put('LCC émise par client', '22'); 
        regMap.put('LCR-pap.émise par client', '23'); 
        regMap.put('Crédit documentaire', '24'); 
        regMap.put('Virement SWIFT', '25'); 
        regMap.put('Crédit documentaire à vue', '26'); 
        regMap.put('Crédit documentaire avec LC', '27'); 
        regMap.put('Contre remb par le transitaire', '28'); 
        regMap.put('Lettre de crédit', '29');
        regMap.put('Virement commercial', '30');
        return regMap.get(code);
    }
}