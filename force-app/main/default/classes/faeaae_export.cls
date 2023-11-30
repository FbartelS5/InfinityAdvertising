public class faeaae_export {
    // Define class/vfp wide values
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
    public static FaeaaeExportNumber__c faeaaeExportNumber{
        get{
            if (faeaaeExportNumber == null)
                faeaaeExportNumber = new FaeaaeExportNumber__c(Counter__c = 0);
            return faeaaeExportNumber;
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
    public static lineConf facfae;
    public static lineConf facaae;
    
    static {
        Blob faeJson = [select body from StaticResource Where Name = 'model_fae'].Body; 
        facfae = (lineConf)JSON.deserialize(faeJson.toString(), lineConf.class);
        
        Blob aaeJson = [select body from StaticResource Where Name = 'model_aae'].Body; 
        facaae = (lineConf)JSON.deserialize(aaeJson.toString(), lineConf.class);
        
        //cost_center
        List<cost_center__mdt> ccs = [SELECT BU__c, cost_center__c FROM cost_center__mdt];
        costCenter = new Map<String, String> ();
        for( cost_center__mdt cc : ccs) costCenter.put(cc.BU__c, cc.cost_center__c);
        costCenter.put(null, 'NO_BU');
    }
    
    public faeaae_export(ApexPages.StandardSetController controller) {
        invoices = [SELECT Id, Name, TotalWithVat__c, VAT_Amount__c, BU__c, Account__r.Centre_profit_partenaire__c, Account__r.PartnerCompany_Code__c, VatRate__c, TotalExcludingVat__c,
                    (select id, Insertion__c, TotalExcludingVat__c, Ordre_Interne__c from InvoiceItems__r)
                    FROM Invoice__c
                    WHERE Id IN :controller.getSelected()];
        List<FaeaaeExportNumber__c> ltin = [SELECT Id, Counter__c, LineCounter__c FROM FaeaaeExportNumber__c 
                                            ORDER BY Counter__c DESC LIMIT 1];
        if (ltin.size() > 0) faeaaeExportNumber = ltin[0];
        else{
            faeaaeExportNumber = new faeaaeExportNumber__c(Counter__c = 0, LineCounter__c = 0);
            insert faeaaeExportNumber;
        }
    }
    
    public static void exportFae() {
        Map<String, String> faeDataMap = new Map<String, String>();
        for(Invoice__c i : invoices) {
            generatedInvoices.add(i.Name);
        }
        faeDataMap.put('fae', writeFae(invoices));
        
        if(generatedInvoices.size() > 0) {
            Document docFactures = new Document(body = Blob.valueOf(String.join(faeDataMap.values(),'\r\n')),
                                                folderid = UserInfo.getUserId(),
                                                name = 'SA1RLVFP_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
            insert docFactures;
            
            ContentVersion fichierFactures = new ContentVersion();
            fichierFactures.ContentLocation = 'S';
            fichierFactures.VersionData = docFactures.Body;
            fichierFactures.Title = docFactures.Name;
            fichierFactures.PathOnClient = docFactures.Name;
            insert fichierFactures;
            system.debug(docFactures.Id);
            generatedFiles.add(fichierFactures);
        }
    }
    
    public static Document exportFaeSched(List<Invoice__c> invoices) {
        Map<String, String> faeDataMap = new Map<String, String>();
        faeDataMap.put('fae', writeFae(invoices));
        Document docFactures = new Document(body = Blob.valueOf(String.join(faeDataMap.values(),'\r\n')),
                                            folderid = UserInfo.getUserId(),
                                            name = 'SA1RLVFP_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
        return docFactures;
    }
    
    public static String writeFae(List<Invoice__c> invoiceList) {
        String output ='';
        Date lastMonthDate = Date.today().addMonths(-1);
        faeaaeExportNumber.counter__c++;
        Set<Id> invItemIds = new Set<Id>();
        Map<Id, Decimal> TotalExcludingVatMap = new Map<Id, Decimal>();
        Decimal TotalExcludingVatMapTotal = 0;
        
        for(Invoice__c inv : invoiceList){
            faeaaeExportNumber.lineCounter__c++;
            
            TotalExcludingVatMap.clear();
            for(InvoiceItem__c invItem : inv.InvoiceItems__r){
                invItemIds.add(invItem.Id);
                TotalExcludingVatMap.put(invItem.Id, invItem.TotalExcludingVat__c.setScale(2));
                TotalExcludingVatMapTotal += invItem.TotalExcludingVat__c.setScale(2);
            }
            
            //START - line 1
            for(fieldConf f : facfae.line1) { 
                if(f.value == 'blank'){
                    output += genValue('', f.length);
                }else if(f.value != ''){
                    if(f.value == 'E') output += genValue('E ', f.length);
                    else output += genValue(f.value, f.length);
                }else{
                    switch on f.name {
                        when 'ref' { // Code société métadata
                            output += genValue('FAE '+lastMonthDate.year()+String.valueOf(lastMonthDate.month()).leftPad(2, '0')+'_'+String.valueOf(faeaaeExportNumber.lineCounter__c).leftpad(5, '0'), f.length);
                        }
                        when 'moiscomp' { // Code société métadata
                            output += genValue(String.valueOf(lastMonthDate.month()).leftPad(2, '0')+lastMonthDate.year(), f.length);
                        }
                        when else {
                            throw new faeaaeExportException('Error: Name not recognized at line 1 -> ' + f.name);
                        }
                    }
                }
            }
            
            output = output.removeEnd(';');
            output += '\r\n';
            //END - line 1
            
            //START - line 2
            for(fieldConf f : facfae.line2) {
                if(f.value == 'blank'){
                    output += genValue('', f.length);
                }else if(f.value != ''){
                    output += genValue(f.value, f.length);
                }else{
                    switch on f.name {
                        when 'montantdev' { 
                            String totalVat = inv.TotalWithVat__c != null ? String.valueof(inv.TotalWithVat__c).remove('-') : '0';
                            String montDev = totalVat.split('\\.').size() > 1 ? totalVat.split('\\.')[0]+totalVat.split('\\.')[1].left(2) : totalVat.split('\\.')[0]+'00' ;
                            output += genValue(montDev.remove('.').leftPad(12, '0'), f.length);
                        }
                        when 'centreprof' { 
                            output += genValue(costCenter.get(inv.Bu__c)+'193', f.length);
                        }
                        when 'codsocpart' { 
                            if(inv.Account__r.PartnerCompany_Code__c != null)output += genValue(inv.Account__r.PartnerCompany_Code__c, f.length);
                            else output += genValue('', f.length);
                        }
                        when 'centreprofpart' {
                            if(inv.Account__r.Centre_profit_partenaire__c != null)output += genValue(inv.Account__r.Centre_profit_partenaire__c, f.length);
                            else output += genValue('', f.length);
                        }
                        when 'cleref3' {
                            if(inv.Id != null)output += genValue(inv.Id, f.length);
                            else output += genValue('', f.length);
                        }   
                        when else {
                            throw new faeaaeExportException('Error: Name not recognized at line 2 -> ' + f.name);
                        }
                    }
                }
            }
            
            output = output.removeEnd(';');
            output += '\r\n';
            //END - line 2
            
            for(InvoiceItem__c invItem : inv.InvoiceItems__r){
                //START - line 3
                for(fieldConf f : facfae.line3) {
                    if(f.value == 'blank'){
                        output += genValue('', f.length);
                    }else if(f.value != ''){
                        output += genValue(f.value, f.length);
                    }else{
                        switch on f.name {
                            when 'montantdev' {
                                String totalVat = TotalExcludingVatMap.get(invItem.Id) != null ? String.valueof(TotalExcludingVatMap.get(invItem.Id)).remove('-') : '0';
                                String montDev = totalVat.split('\\.').size() > 1 ? totalVat.split('\\.')[0]+totalVat.split('\\.')[1].left(2) : totalVat.split('\\.')[0]+'00' ;
                                output += genValue(montDev.remove('.').leftPad(12, '0'), f.length);
                            }
                            when 'codtva' {
                                if(inv.VatRate__c == 0) output += genValue('W0', f.length);
                                else output += genValue('WK', f.length);
                            }
                            when 'centrecout' {
                                output += genValue(costCenter.get(inv.Bu__c)+'193E', f.length);
                            }
                            when 'centreprof' {
                                output += genValue(costCenter.get(inv.Bu__c)+'193', f.length);
                            }
                            when 'ordreint' {
                                output += genValue(invItem.Ordre_Interne__c, f.length);
                            }
                            when 'codsocpart' {
                                if(inv.Account__r.PartnerCompany_Code__c != null)output += genValue(inv.Account__r.PartnerCompany_Code__c, f.length);
                                else output += genValue('', f.length);
                            }
                            when 'centrecoutpart' {
                                if(inv.Account__r.Centre_profit_partenaire__c != null)output += genValue(inv.Account__r.Centre_profit_partenaire__c+'E', f.length);
                                else output += genValue('', f.length);
                            }
                            when 'centreprofpart' {
                                if(inv.Account__r.Centre_profit_partenaire__c != null)output += genValue(inv.Account__r.Centre_profit_partenaire__c, f.length);
                                else output += genValue('', f.length);
                            }
                            when 'cleref3' {
                                if(invItem.Id != null)output += genValue(invItem.Id, f.length);
                                else output += genValue('', f.length);
                            }
                            when else {
                                throw new faeaaeExportException('Error: Name not recognized at line 3 -> ' + f.name);
                            }
                        }
                    }
                }
                
                output = output.removeEnd(';');
                output += '\r\n';
                //END - line 3
            }
        }
        
        
        
        //START - line 4
        for(fieldConf f : facfae.line4) {
            if(f.value == 'blank'){
                output += genValue('', f.length);
            }else if(f.value != ''){
                output += genValue(f.value, f.length);
            }else{
                switch on f.name {
                    when 'seq' { 
                        output += genValue('SA1'+String.valueOf(faeaaeExportNumber.counter__c).leftpad(6, '0'), f.length);
                    }
                    when else {
                        throw new faeaaeExportException('Error: Name not recognized at line 4 -> ' + f.name);
                    } 
                }
            }
        }
        
        output = output.removeEnd(';');
        output += '\r\n';
        update faeaaeExportNumber;
        //END - line 4
        system.debug(output);
        return output;
    }
    
    public static void exportAae() {
        Map<String, String> aaeDataMap = new Map<String, String>();
        for(Invoice__c i : invoices) {
            generatedInvoices.add(i.Name);
        }
        aaeDataMap.put('aae', writeAae(invoices));
        
        if(generatedInvoices.size() > 0) {
            Document docFactures = new Document(body = Blob.valueOf(String.join(aaeDataMap.values(),'\r\n')),
                                                folderid = UserInfo.getUserId(),
                                                name = 'SA1RLVAP_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
            insert docFactures;
            
            ContentVersion fichierFactures = new ContentVersion();
            fichierFactures.ContentLocation = 'S';
            fichierFactures.VersionData = docFactures.Body;
            fichierFactures.Title = docFactures.Name;
            fichierFactures.PathOnClient = docFactures.Name;
            insert fichierFactures;
            system.debug(docFactures.Id);
            generatedFiles.add(fichierFactures);
        }
    }
    
    public static Document exportAaeSched(List<Invoice__c> invoices) {
        Map<String, String> aaeDataMap = new Map<String, String>();
        aaeDataMap.put('aae', writeAae(invoices));
        Document docFactures = new Document(body = Blob.valueOf(String.join(aaeDataMap.values(),'\r\n')),
                                            folderid = UserInfo.getUserId(),
                                            name = 'SA1RLVAP_'+System.now().format('yyyyMMddHHmmssSSS')+'.tgt');
        return docFactures;
    }
    
    public static String writeAae(List<Invoice__c> invoiceList) {
        String output ='';
        Date lastMonthDate = Date.today().addMonths(-1);
        Set<Id> invItemIds = new Set<Id>();
        Map<Id, Decimal> TotalExcludingVatMap = new Map<Id, Decimal>();
        Decimal TotalExcludingVatMapTotal = 0;
        faeaaeExportNumber.counter__c++;
        
        for(Invoice__c inv : invoiceList){
            faeaaeExportNumber.lineCounter__c++;
            
            TotalExcludingVatMap.clear();
            for(InvoiceItem__c invItem : inv.InvoiceItems__r){
                invItemIds.add(invItem.Id);
                TotalExcludingVatMap.put(invItem.Id, invItem.TotalExcludingVat__c.setScale(2));
                TotalExcludingVatMapTotal += invItem.TotalExcludingVat__c.setScale(2);
            }
            
            //START - line 1
            for(fieldConf f : facaae.line1) { 
                if(f.value == 'blank'){
                    output += genValue('', f.length);
                }else if(f.value != ''){
                    if(f.value == 'E') output += genValue('E ', f.length);
                    else output += genValue(f.value, f.length);
                }else{
                    switch on f.name {
                        when 'ref' { // Code société métadata
                            output += genValue('AAE '+lastMonthDate.year()+String.valueOf(lastMonthDate.month()).leftPad(2, '0')+'_'+String.valueOf(faeaaeExportNumber.lineCounter__c).leftpad(5, '0'), f.length);
                        }
                        when 'moiscomp' { // Code société métadata
                            output += genValue(String.valueOf(lastMonthDate.month()).leftPad(2, '0')+lastMonthDate.year(), f.length);
                        }
                        when else {
                            throw new faeaaeExportException('Error: Name not recognized at line 1 -> ' + f.name);
                        }
                    }
                }
            }
            output = output.removeEnd(';');
            output += '\r\n';
            //END - line 1
            
            //START - line 2
            for(fieldConf f : facaae.line2) {
                if(f.value == 'blank'){
                    output += genValue('', f.length);
                }else if(f.value != ''){
                    output += genValue(f.value, f.length);
                }else{
                    switch on f.name {
                        when 'montantdev' {
                            String totalVat = inv.TotalWithVat__c != null ? String.valueof(inv.TotalWithVat__c).remove('-') : '0';
                            String montDev = totalVat.split('\\.').size() > 1 ? totalVat.split('\\.')[0]+totalVat.split('\\.')[1].left(2) : totalVat.split('\\.')[0]+'00' ;
                            output += genValue(montDev.remove('.').leftPad(12, '0'), f.length);
                        }
                        when 'centreprof' { 
                            output += genValue(costCenter.get(inv.Bu__c)+'193', f.length);
                        }
                        when 'codsocpart' { 
                            if(inv.Account__r.PartnerCompany_Code__c != null)output += genValue(inv.Account__r.PartnerCompany_Code__c, f.length);
                            else output += genValue('', f.length);
                        }
                        when 'centreprofpart' {
                            if(inv.Account__r.Centre_profit_partenaire__c != null)output += genValue(inv.Account__r.Centre_profit_partenaire__c, f.length);
                            else output += genValue('', f.length);
                        }
                        when 'cleref3' {
                            if(inv.Id != null)output += genValue(inv.Id, f.length);
                            else output += genValue('', f.length);
                        }                      
                        when else {
                            throw new faeaaeExportException('Error: Name not recognized at line 2 -> ' + f.name);
                        }
                    }
                }
            }
            output = output.removeEnd(';');
            output += '\r\n';
            //END - line 2
            
            for(InvoiceItem__c invItem : inv.InvoiceItems__r){
                //START - line 3
                for(fieldConf f : facaae.line3) {
                    if(f.value == 'blank'){
                        output += genValue('', f.length);
                    }else if(f.value != ''){
                        output += genValue(f.value, f.length);
                    }else{
                        switch on f.name {
                            when 'montantdev' {
                                String totalVat = TotalExcludingVatMap.get(invItem.Id) != null ? String.valueof(TotalExcludingVatMap.get(invItem.Id)).remove('-') : '0';
                                String montDev = totalVat.split('\\.').size() > 1 ? totalVat.split('\\.')[0]+totalVat.split('\\.')[1].left(2) : totalVat.split('\\.')[0]+'00' ;
                                output += genValue(montDev.remove('.').leftPad(12, '0'), f.length);
                            }
                            when 'codtva' {
                                if(inv.VatRate__c == 0) output += genValue('W0', f.length);
                                else output += genValue('WK', f.length);
                            }
                            when 'centrecout' {
                                output += genValue(costCenter.get(inv.Bu__c)+'193E', f.length);
                            }
                            when 'centreprof' {
                                output += genValue(costCenter.get(inv.Bu__c)+'193', f.length);
                            }
                            when 'ordreint' {
                                output += genValue(invItem.Ordre_Interne__c, f.length);
                            }
                            when 'codsocpart' {
                                if(inv.Account__r.PartnerCompany_Code__c != null)output += genValue(inv.Account__r.PartnerCompany_Code__c, f.length);
                                else output += genValue('', f.length);
                            }
                            when 'centrecoutpart' {
                                if(inv.Account__r.Centre_profit_partenaire__c != null)output += genValue(inv.Account__r.Centre_profit_partenaire__c+'E', f.length);
                                else output += genValue('', f.length);
                            }
                            when 'centreprofpart' {
                                if(inv.Account__r.Centre_profit_partenaire__c != null)output += genValue(inv.Account__r.Centre_profit_partenaire__c, f.length);
                                else output += genValue('', f.length);
                            }
                            when 'cleref3' {
                                if(invItem.Id != null)output += genValue(invItem.Id, f.length);
                                else output += genValue('', f.length);
                            }
                            when else {
                                throw new faeaaeExportException('Error: Name not recognized at line 3 -> ' + f.name);
                            }
                        }
                    }
                }
                
                output = output.removeEnd(';');
                output += '\r\n';
                //END - line 3
            }
        }
        
        
        
        //START - line 4
        for(fieldConf f : facaae.line4) {
            if(f.value == 'blank'){
                output += genValue('', f.length);
            }else if(f.value != ''){
                output += genValue(f.value, f.length);
            }else{
                switch on f.name {
                    when 'seq' { 
                        output += genValue('SA1'+String.valueOf(faeaaeExportNumber.counter__c).leftpad(6, '0'), f.length);
                    }
                    when else {
                        throw new faeaaeExportException('Error: Name not recognized at line 4 -> ' + f.name);
                    } 
                }
            }
        }
        
        output = output.removeEnd(';');
        output += '\r\n';
        update faeaaeExportNumber;
        //END - line 4
        system.debug(output);
        return output;
    }
    
    public class faeaaeExportException extends Exception{}
    
    private static String genValue(String value, Integer validLength){
        if(value == null) value = ''; 
        return removeAccents(value.remove(';'))+';';
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
}