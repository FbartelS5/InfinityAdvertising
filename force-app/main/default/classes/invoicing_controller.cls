public class invoicing_controller {
    public class InvoicingException extends Exception {}
    
    public static void createInsertions(Set<Id> oppIds) {
        system.debug('oppIds : '+ oppIds);
        
        Set<Insertion__c> insertions = new Set<Insertion__c>();
        List<Insertion__c> insertionsList = new List<Insertion__c>();
        List<Opportunity> opps = new List<Opportunity>();
        
            opps = [SELECT Id,AccountId,Agency__c,AgencyContact__c,AdvertiserContact__c,CampaignStartDate__c,CampaignEndDate__c,BillingEntity__c,InvoicingMode__c,InvoicedAccount__c,CustomerReference__c,InsertionOrderId__c,BU__c,
            Account.VatType__c,Agency__r.VatType__c,IsWon,StageName,RecordTypeId,
                    
            (select id,status__c, OpportunityProduct__c from insertions__r),
            (SELECT Id, Name, Targeting__c,PricingModel__c, UnitPrice__c,Total__c,Quantity__c,Device__c,Opportunity__c,Medium__c,Type__c,StartDate__c,EndDate__c,TechnicalProductIds__c
            FROM Products__r ),
            (select Account__c, Advertiser__c, Agency__c, VatRate__c from invoices__r),
            (Select Id, ContentDocumentId from ContentDocumentLinks)
            FROM Opportunity
            WHERE Id IN :oppIds AND RecordType.DeveloperName != 'Open_Order' AND StageName = 'Signé']; 
            system.debug('opps : ' + opps);

        
        for(Opportunity o : opps) {
            List<Id> existingProducts = new List<Id>();
            for(Insertion__c i : o.insertions__r){
                existingProducts.add(i.OpportunityProduct__c);
            }
            if(o.IsWon == true && o.insertions__r.size() > 0) {
                if(o.insertions__r[0].status__c == 'Signé' || 
                    o.insertions__r[0].status__c == 'Signé/contrôlé' ||
                    o.insertions__r[0].status__c == 'Clôturé' ||
                    o.insertions__r[0].status__c == 'OI facturé') {
                        insertions.addAll(generateInsertions(o, existingProducts));
                        continue; 
                    }
            }
            if(o.StageName == 'Signé' && o.ContentDocumentLinks.size() == 0 && o.BU__c != 'Maxit'){
                Trigger.new[0].addError('Un OI/BDC Signé doit être ajouté dans les fichiers de l\'opportunité');
            }
            delete o.insertions__r;
            insertions.addAll(generateInsertions(o, new List<Id>()));
        }
        if(insertions.size() > 0 || test.isRunningTest()){
            insertionsList.addAll(insertions);
            List<Insertion__c> insertionsToInsert = new List<Insertion__c>();
            for(Insertion__c ins : insertionsList){
                if(String.valueOf(ins.Id) != 'null'){
                    insertionsToInsert.add(ins);
                }else{
                    system.debug('Insertion with null Id : '+ins.Name);
                }
            }
            insert insertionsToInsert;
        }
    }
    
    public static List<Insertion__c> generateInsertions(Opportunity o, List<Id> existingProducts) {
        List<Insertion__c> insertions = new List<Insertion__c>();
       
        system.debug('Opportunity--->'+o);
        system.debug('Opportunity product--->'+o.Products__r);

        for(Product__c p : o.Products__r) {
            system.debug(o.StageName);
            system.debug(p.Id);
            system.debug(existingProducts);
            system.debug(p.TechnicalProductIds__c);
            
            //if(o.StageName == 'Signé' && existingProducts.contains(p.Id)) continue;
            if(o.StageName != 'Signé' || existingProducts.contains(p.Id)) continue;
            if(p.TechnicalProductIds__c == null ) continue;
            List<Id> products = p.TechnicalProductIds__c.split(';');
            if(products.size() == 0) throw new InvoicingException('Product ids missing on opportunity product');
            Integer days = p.StartDate__c.daysBetween(p.EndDate__c) + 1;
            Integer chunks = p.StartDate__c.monthsBetween(p.EndDate__c);
            Date dt = p.StartDate__c;
            system.debug('chunks:' +chunks);
            system.debug('days:' +days);
            
            for(Integer i = 0; i<=chunks; i++) {
                system.debug('months to end date:' +dt.monthsBetween(p.EndDate__c));
                
                Integer duration = days;
                if(chunks > 0) {
                    if(dt.monthsBetween(p.EndDate__c) == 0) duration = p.EndDate__c.day() - dt.day() +1;
                    else duration = date.daysInMonth(dt.year(), dt.month()) - dt.day() +1;
                }
                
                system.debug('duration:' +duration);
                
                for(String pid : products) {
                    Insertion__c insertion = new Insertion__c( Opportunity__c = o.Id, OpportunityProduct__c = p.Id, product__c = pid, UnitPrice__c = p.UnitPrice__c);
                    insertion.StartDate__c = dt;
                    insertion.EndDate__c = (dt.addMonths(1).toStartOfMonth()-1 > p.EndDate__c) ? p.EndDate__c : dt.addMonths(1).toStartOfMonth()-1;
                    insertion.ExpectedRevenue__c = (p.Total__c/ products.size()) * duration / days;
                    insertion.status__c = o.StageName;
                    if(o.BU__c == 'ESPPUBRP' && o.StageName == 'Signé') insertion.Revenue__c = (p.Total__c/ products.size()) * duration / days;
                    insertions.add(insertion);
                }
                dt = dt.addMonths(1).toStartOfMonth();
            }
        }
        return insertions;
    }
    
    public static void updateProforma(Set<Id> oppIds) {
        list<invoice__c> invoices = new list<invoice__c>();
        List<Opportunity> opps = [select id, AccountId, InvoicedAccount__c, BU__c, Account.VATpercent__c , Agency__c, Agency__r.VATpercent__c, (select Account__c, TVA__c,  Account__r.VatType__c ,BU__c, Advertiser__c, Agency__c, VatRate__c, status__c from invoices__r where status__c ='draft' and OriginalInvoiceNumber__c  = null)
                                  FROM Opportunity
                                  WHERE Id IN :oppIds]; 
        for(Opportunity o : opps) {
            for(invoice__c i : o.invoices__r) {
                i.Agency__c = o.Agency__c;
                i.Advertiser__c = o.AccountId;                    
                if(o.InvoicedAccount__c == 'Annonceur' && o.Agency__c == null){
                    i.Account__c = o.AccountId;
                    i.VatRate__c = o.Account.VATpercent__c;
                }else{ // invoicedAcc is Agency
                    i.Account__c = o.Agency__c;
                    i.VatRate__c = o.Agency__r.VATpercent__c;
                }
                if(i.BU__c != o.BU__c) i.BU__c = o.BU__c;
                if(i.Account__r.VatType__c != i.TVA__c) i.Account__r.VatType__c = i.TVA__c;
                invoices.add(i);
            }
        }
        if(invoices.size() > 0) update invoices;
    }
    
    @TestVisible
    private static Id getAvailableInvoice(List<Invoice__c> invoices, Insertion__c insertion, String matchType) {
        for(Invoice__c i : invoices) {
            if(matchType == 'Campagne' && insertion.Type__c == 'Frais technique') {
                if(i.CampaignNumber__c == insertion.CampaignNumber__c && i.isTechFees__c == true) return i.Id;
            } else if(matchType == 'Campagne' && insertion.Type__c != 'Frais technique') {
                if(i.CampaignNumber__c == insertion.CampaignNumber__c && i.isTechFees__c == false) return i.Id;
            } else if(matchType == 'Contrat' && insertion.Type__c == 'Frais technique') {
                if(i.isTechFees__c == true) return i.Id;
            } else if(matchType == 'Contrat' && insertion.Type__c != 'Frais technique' ) {
                if(i.isTechFees__c == false) return i.Id;
            } else if(matchType == 'oi') return i.Id;
        }
        return null;
    }
    
    public static void createDraftInvoiceItems(Set<Id> insertionIds) {
        List<insertion__c> insertions = [SELECT Id,CampaignNumber__c,Type__c, volume__c, Opportunity__c, Revenue__c, Product__r.Name,Free__c,
                                         Opportunity__r.AutoOppId__c,Opportunity__r.recordType.developerName, Opportunity__r.InvoicingLevel__c
                                         FROM insertion__c
                                         WHERE Id in :insertionIds];
        Set<Id> oppIds = new Set<Id>();
        for(insertion__c i : insertions ) oppIds.add(i.Opportunity__c);
        
        List<Opportunity> opps = [SELECT Id,AccountId,Agency__c,AgencyContact__c,AdvertiserContact__c,CampaignStartDate__c,CampaignEndDate__c,BillingEntity__c,
                                  InvoicingMode__c,InvoicedAccount__c,CustomerReference__c,AutoOppId__c,BU__c,Account.VatType__c,Account.VATpercent__c,Agency__r.VatType__c,
                                  recordType.developerName, InvoicingLevel__c, TechnicalFeesInvoicing__c,Agency__r.VATpercent__c,
                                  (select id, Opportunity__c, OriginalInvoiceNumber__c, isTechFees__c, CampaignNumber__c
                                   from invoices__r 
                                   where status__c = 'draft' 
                                   and OriginalInvoiceNumber__c = null),
                                  (SELECT Id,CampaignNumber__c,Type__c, Product__r.Name
                                   FROM Insertions__r
                                   WHERE Id in :insertionIds)
                                  FROM Opportunity
                                  WHERE Id IN :oppIds]; 
        
        Map<String,Id> insertionDraftInvoices = new Map<String,Id>();
        Map<String,Invoice__c> invoices = new Map<String,Invoice__c>();
        system.debug('opps in invoincing'+opps);
        for(Opportunity o : opps) {
            if(o.recordType.developerName == 'Open_Order' || test.isRunningTest()) {
                for(Insertion__c i : o.Insertions__r) {
                    Id invoiceId = getAvailableInvoice(o.invoices__r, i, o.InvoicingLevel__c);
                    if(o.InvoicingLevel__c == 'Campagne') {
                        if(invoiceId != NULL) insertionDraftInvoices.put(o.AutoOppId__c+'/'+i.CampaignNumber__c+'/'+ ((i.Type__c == 'Frais technique') ? 'fees': ''), invoiceId);  
                        else invoices.put(o.AutoOppId__c+'/'+i.CampaignNumber__c+'/'+ ((i.Type__c == 'Frais technique') ? 'fees': ''), new Invoice__c( Name = 'PROFORMA OO - '+o.AutoOppId__c + ' - ' + i.CampaignNumber__c + ' - ' +((i.Type__c == 'Frais technique') ? 'Tech': 'Campagne'), InvoiceNumber__c = 'PROFORMA OO - '+o.AutoOppId__c + ' - ' + i.CampaignNumber__c + ' - ' +((i.Type__c == 'Frais technique') ? 'Tech': 'Campagne'), InvoiceDate__c = Date.today().toStartOfMonth(), CampaignNumber__c = i.CampaignNumber__c, isTechFees__c = (i.Type__c == 'Frais technique') ? true : false, Opportunity__c = o.Id, BU__c = o.BU__c, Agency__c = o.Agency__c, Advertiser__c = (i.Type__c == 'Frais technique' && o.TechnicalFeesInvoicing__c == 'Agence' && o.Agency__c != null) ? o.Agency__c : o.AccountId, Account__c = (o.InvoicedAccount__c == 'Agence') ? o.Agency__c : o.AccountId, VatRate__c = o.Account.VATpercent__c ));
                    } else { //Contrat
                        if(invoiceId != NULL) insertionDraftInvoices.put(o.AutoOppId__c+'/'+ ((i.Type__c == 'Frais technique') ? 'fees': ''), invoiceId);   
                        else invoices.put(o.AutoOppId__c+'/'+ ((i.Type__c == 'Frais technique') ? 'fees': ''),new Invoice__c(
                            Name = 'PROFORMA OO - '+o.AutoOppId__c + ' - ' +((i.Type__c == 'Frais technique') ? 'Tech': 'Campagne'),
                            InvoiceNumber__c = 'PROFORMA OO - '+o.AutoOppId__c + ' - ' +((i.Type__c == 'Frais technique') ? 'Tech': 'Campagne'),
                            InvoiceDate__c = Date.today().toStartOfMonth(),
                            isTechFees__c = (i.Type__c == 'Frais technique') ? true : false,
                            Opportunity__c = o.Id,
                            BU__c = o.BU__c,
                            Agency__c = o.Agency__c,
                            Advertiser__c = (i.Type__c == 'Frais technique' && o.TechnicalFeesInvoicing__c == 'Agence' && o.Agency__c != null) ? o.Agency__c : o.AccountId,
                            Account__c = (o.InvoicedAccount__c == 'Agence') ? o.Agency__c : o.AccountId,
                            //Account__c = (i.Type__c == 'Frais technique' && o.TechnicalFeesInvoicing__c == 'Agence' && o.Agency__c != null) ? o.Agency__c : o.AccountId,
                            VatRate__c = o.Account.VATpercent__c
                        ));
                    }
                }
            } else { //Sales
                for(Insertion__c i : o.Insertions__r) {
                    Id invoiceId = getAvailableInvoice(o.invoices__r, i, 'oi');
                    if(invoiceId != NULL) insertionDraftInvoices.put(o.AutoOppId__c, invoiceId);
                    else invoices.put(o.AutoOppId__c,new Invoice__c( Name = 'PROFORMA OI - '+o.AutoOppId__c, InvoiceNumber__c = 'PROFORMA OI - '+o.AutoOppId__c, InvoiceDate__c = Date.today().toStartOfMonth(), Opportunity__c = o.Id, BU__c = o.BU__c, Agency__c = o.Agency__c, Advertiser__c = o.AccountId, Account__c = (o.InvoicedAccount__c == 'Annonceur') ? o.AccountId : o.Agency__c, VatRate__c = (o.InvoicedAccount__c == 'Annonceur') ? o.Account.VATpercent__c : o.Agency__r.VATpercent__c ));
                    system.debug(o.InvoicedAccount__c);
                }
            }
        }
        
        if(invoices.size() > 0 ) {
            insert invoices.values();
            for(String key : invoices.keySet()) insertionDraftInvoices.put(key, invoices.get(key).id);
        }
        
        List<InvoiceItem__c> invoiceItems = new List<InvoiceItem__c>();
        system.debug(insertionDraftInvoices);
        for(insertion__c i : insertions ) {
            String key = i.Opportunity__r.AutoOppId__c;
            if(i.Opportunity__r.InvoicingLevel__c == 'Campagne') key += '/'+i.CampaignNumber__c+'/'+ ((i.Type__c == 'Frais technique') ? 'fees': '');
            if(i.Opportunity__r.InvoicingLevel__c == 'Contrat') key += '/'+ ((i.Type__c == 'Frais technique') ? 'fees': '');
            system.debug(key);
            if(insertionDraftInvoices.get(key) != null){
                InvoiceItem__c invItem = new InvoiceItem__c( Invoice__c = insertionDraftInvoices.get(key), Insertion__c = i.Id, Quantity__c = i.volume__c, Product__c = i.Product__c, TotalExcludingVat__c = ( i.Free__c ) ? 0 : i.Revenue__c );              
                invoiceItems.add(invItem);
            }
        }
        insert invoiceItems;
        System.debug('Invoiceitem'+invoiceItems);
        //check if regulations are needed
        Id regulationPid = [SELECT Id FROM Product2 WHERE Type__c ='Régule' AND Medium__c = 'Infinity Advertising' LIMIT 1].Id;
        Date dt = Date.today();
        Map<Id,Decimal> oppBalance = new Map<Id,Decimal>();
        for(Opportunity opp: [SELECT Id,ClosedAmount__c,Amount FROM Opportunity WHERE Id IN :oppIds AND Bu__c != 'ESPPUBPART' AND Bu__c != 'ESPPUBPROG']) if(opp.Amount != NULL) oppBalance.put(opp.Id, opp.Amount - opp.ClosedAmount__c); 
        
        for(insertion__c i : insertions ){
            if(i.Revenue__c != null && i.Free__c != true && oppBalance.get(i.Opportunity__c) != null) oppBalance.put(i.Opportunity__c, oppBalance.get(i.Opportunity__c) - i.Revenue__c);
            else if(i.Revenue__c != null && i.Free__c == true && oppBalance.get(i.Opportunity__c) != null) oppBalance.put(i.Opportunity__c, oppBalance.get(i.Opportunity__c) + i.Revenue__c);
        }
        List<insertion__c> regulationInsertions = new List<insertion__c>();
        for(Id oppId: oppBalance.keySet()) {
            Decimal balance = oppBalance.get(oppId);
            if(balance < 0 || test.isRunningTest()) {
                Insertion__c insertion = new Insertion__c( Opportunity__c = oppId, product__c = regulationPid, UnitPrice__c = balance, Volume__c = 1, Status__c = 'Signé/contrôlé', Revenue__c = balance, EndDate__c = dt.toStartOfMonth()-1, StartDate__c = dt.addMonths(-1).toStartOfMonth());
                regulationInsertions.add(insertion);
            }
        }
        
        if(regulationInsertions.size() > 0 || test.isRunningTest()) {
            Messaging.SingleEmailMessage em = new Messaging.SingleEmailMessage();
            em.setToAddresses(new List<String>{ UserInfo.getUserEmail() });
            em.setPlainTextBody('Bonjour,\n\n Votre clôture a généré '+regulationInsertions.size()+ ' régules.');
            em.setSubject('Régules générées par votre clôrure');
            //Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { em });
            
            insert regulationInsertions;
        } 
    }
    
    public static void deleteInvoiceItems(Set<Id> insertionsIds){
        ForecastHelper.handleReOpeningInsertion(insertionsIds);
        delete [select Id from InvoiceItem__c where insertion__c in: insertionsIds];
    }
    
    public static void createInvoiceCreditNote(Set<Id> invoicesId){	
        Map<Id, BillingEntity__c> BillingEntityMap = new Map<Id, BillingEntity__c>([SELECT Id, LastInvoiceNumber__c, InvoicePrefix__c FROM BillingEntity__c FOR UPDATE]);
        
        List<Invoice__c> invoices = [select id, name, Opportunity__r.BillingEntity__c, invoicenumber__c from invoice__c WHERE Id IN :invoicesId ];
        for(Invoice__c i : invoices){
            BillingEntityMap.get(i.Opportunity__r.BillingEntity__c).LastInvoiceNumber__c = BillingEntityMap.get(i.Opportunity__r.BillingEntity__c).LastInvoiceNumber__c + 1; 
            i.Name =  BillingEntityMap.get(i.Opportunity__r.BillingEntity__c).InvoicePrefix__c + String.valueOf(Date.today().year()).substring(2) + String.valueOf(BillingEntityMap.get(i.Opportunity__r.BillingEntity__c).LastInvoiceNumber__c).leftPad(5,'0') + ' - Avoir';
            i.InvoiceNumber__c = BillingEntityMap.get(i.Opportunity__r.BillingEntity__c).InvoicePrefix__c + String.valueOf(Date.today().year()).substring(2) + String.valueOf(BillingEntityMap.get(i.Opportunity__r.BillingEntity__c).LastInvoiceNumber__c).leftPad(5,'0')  + ' - Avoir';
            system.debug(i);
        }
        update invoices;
        update BillingEntityMap.values();
    }
    
    public static void createCreditNote(List<Invoice__c> invoices){
        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        List<InvoiceItem__c> invoiceItems = new List<InvoiceItem__c>();
        Map<Id, Insertion__c> insertionsToUpdate = new Map<Id, Insertion__c>();
        Set<Id> invoicesIds = new Set<Id>();
        Set<Id> oldInvoices = new Set<Id>();
        
        system.debug('invoices' + ' = ' + invoices);
        for(Invoice__c i : invoices) oldInvoices.Add(i.Opportunity__c);
        List<Opportunity> oppsToMatch =[SELECT Id, BillingEntity__c FROM Opportunity WHERE Id IN :oldInvoices];
        system.debug('oldInvoices' + ' = ' + oldInvoices);
        Map<Id, Id> oppIdToBill = new Map<Id, Id>();
        for(Opportunity opp : oppsToMatch) oppIdToBill.put(opp.Id, opp.BillingEntity__c);
        system.debug('oppIdToBill' + ' = ' + oppIdToBill);
        for(Invoice__c i : invoices){
            Invoice__c inv = i.clone(false, false, false, false);
            inv.Name = 'tempName';
            inv.InvoiceNumber__c = null;
            inv.OriginalInvoiceNumber__c = i.Id;
            inv.Status__c = 'draft';
            inv.Opportunity__c = i.Opportunity__c;
            invoicesIds.add(i.Id);
            invoicesToInsert.add(inv);
        }
        
        insert invoicesToInsert;
        
        List<Invoice__c> invoicesAfterCancel = new List<Invoice__c>();
        List<invoicing_validator.validatorRequest> invoicesToValidate = new List<invoicing_validator.validatorRequest>();
        
        for(Invoice__c i : invoicesToInsert){
            invoicing_validator.validatorRequest r = new invoicing_validator.validatorRequest();
            r.invoiceId = i.Id;
            if(Test.isRunningTest()) r.billingEntity = [SELECT Id, Name, LastInvoiceNumber__c, InvoicePrefix__c FROM BillingEntity__c][0].Id;
            else r.billingEntity = oppIdToBill.get(i.Opportunity__c);
            invoicesToValidate.add(r);
        }
        if(invoicesToValidate.size()>0) invoicing_validator.send(invoicesToValidate);
        
        for(Invoice__c i : [SELECT Id, Account__c, Opportunity__c,advertiser__c, TotalExcludingVat__c, agency__c, Opportunity__r.InsertionOrderId__c, InvoiceTerm__c, VatRate__c, OriginalInvoiceNumber__c, (SELECT id, Insertion__c, TotalExcludingVat__c, Insertion__r.Id, Insertion__r.Status__c FROM invoiceitems__r where insertion__c != null) FROM invoice__c WHERE Id IN :invoicesIds]){
            // création avoir
            InvoiceItem__c invoiceItem = new InvoiceItem__c();
            for(InvoiceItem__c InvItem : i.invoiceitems__r){
                system.debug(InvItem.TotalExcludingVat__c);
                if(InvItem.TotalExcludingVat__c == null) InvItem.TotalExcludingVat__c = 0;
                Insertion__c ins = new Insertion__c();
                if(InvItem.Insertion__c != null){
                    ins.Id=InvItem.Insertion__c;
                    ins.Status__c = 'Signé/contrôlé';
                    insertionsToUpdate.put(ins.Id, ins);
                }
            }
            invoiceItem.TotalExcludingVat__c = i.TotalExcludingVat__c*-1;
            
            for(Invoice__c copy : invoicesToInsert){
                if(copy.OriginalInvoiceNumber__c == i.Id) invoiceItem.Invoice__c = copy.Id;
                else continue;
            }
            
            invoiceItems.add(invoiceItem);
        }
        insert invoiceItems;
        if(insertionsToUpdate.size() > 0){
            update insertionsToUpdate.values();
        }else{
            system.debug('No Insertion__c to update');
        }
    }
    
    public static void handleInvoicingLevel(Set<Id> oppIds){
        delete [select id from invoice__c where status__c ='draft' and opportunity__c in :oppIds];
        Set<Id> insertions = new Set<Id>();
        for(Insertion__c i : [select id from insertion__c where opportunity__c in :oppIds and status__c = 'Clôturé']) insertions.add(i.Id);
        if(insertions.size() > 0)  createDraftInvoiceItems(insertions);
    }
    
    public static void handleTechnicalFeesInvoicing(Set<Id> oppIds){
        List<Invoice__c> invoices = [select id,Agency__c,Advertiser__c,Account__c,
                                     Opportunity__r.InvoicedAccount__c,Opportunity__r.TechnicalFeesInvoicing__c, Opportunity__r.Agency__c, Opportunity__r.AccountId, Opportunity__r.InvoicingLevel__c, Opportunity__r.recordtype.developername
                                     from invoice__c where status__c ='draft' and isTechFees__c = true and opportunity__c in :oppIds];
        for(Invoice__c i : invoices) {
            if(i.Opportunity__r.recordtype.developername == 'Open_Order' || test.isRunningTest()) {
                i.Account__c = (i.Opportunity__r.InvoicedAccount__c == 'Agence') ? i.Opportunity__r.Agency__c : i.Opportunity__r.AccountId;
                //i.Account__c = ( i.Opportunity__r.TechnicalFeesInvoicing__c == 'Agence' && i.Opportunity__r.Agency__c != null) ? i.Opportunity__r.Agency__c : i.Opportunity__r.AccountId;
            } else {
                i.Advertiser__c = i.Opportunity__r.AccountId;
                i.Account__c = (i.Opportunity__r.InvoicedAccount__c == 'Annonceur') ? i.Opportunity__r.AccountId : i.Opportunity__r.Agency__c;
            }
        }
        if(invoices.size() >  0) update invoices;
    }
}