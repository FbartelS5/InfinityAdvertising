global class invoicing_validator {
    public class validatorException extends Exception {}
    
    global class validatorRequest {
        @InvocableVariable(label='Facture' required=true)
        public ID invoiceId;
        
        @InvocableVariable(label='Entité de facturation' required=true)
        public ID billingEntity;
    }
    
    @InvocableMethod(label='Valide la facture')
    global static void send(List<validatorRequest> requests) {
        for(Integer i=0;i<requests.size();i++){
            if(requests[i].BillingEntity == null) throw new validatorException('Erreur : La requête '+requests[i].invoiceId+' n\'a pas d\'Entité de facturation');
        }
        Date invoiceDate = Date.today();
        Date invoiceTermDate = invoiceDate.addDays(30);
        List<Invoice__c> invoices = new List<Invoice__c>();
        Set<Id> invoiceIds = new Set<Id>();
        
        Set<id> oldInvoicesids = new Set<Id>();
        Map<Id, Invoice__c> avoirSelector = new Map<Id, Invoice__c>();
        for(Integer i=0;i<requests.size();i++){
            oldInvoicesids.add(requests[i].invoiceId);
        }
        List<Invoice__c> oldInvoices = [SELECT Id, OriginalInvoiceNumber__c, Status__c, Opportunity__r.InsertionOrderId__c FROM Invoice__c WHERE Id IN :oldInvoicesids];
        for(Invoice__c i : oldInvoices){
            avoirSelector.put(i.Id, i);
        }
        
        Map<Id, BillingEntity__c> BillingEntityMap = new Map<Id, BillingEntity__c>([SELECT Id, LastInvoiceNumber__c, InvoicePrefix__c FROM BillingEntity__c FOR UPDATE]);
        for (validatorRequest r : requests) {
            system.debug(r.billingEntity + ' - ' + BillingEntityMap.get(r.billingEntity));
            BillingEntityMap.get(r.billingEntity).LastInvoiceNumber__c = BillingEntityMap.get(r.billingEntity).LastInvoiceNumber__c + 1; 
            invoiceIds.add(r.invoiceId);

            Invoice__c newInvoice = new Invoice__c(
                Id = r.invoiceId,
                InvoiceDate__c = invoiceDate,
                InvoiceTerm__c = invoiceTermDate
            );

            if(String.isBlank(avoirSelector.get(r.invoiceId).OriginalInvoiceNumber__c) == true){
                newInvoice.Name = BillingEntityMap.get(r.billingEntity).InvoicePrefix__c + String.valueOf(Date.today().year()).substring(2) + String.valueOf(BillingEntityMap.get(r.billingEntity).LastInvoiceNumber__c).leftPad(4,'0');
                newInvoice.InvoiceNumber__c = BillingEntityMap.get(r.billingEntity).InvoicePrefix__c + String.valueOf(Date.today().year()).substring(2) + String.valueOf(BillingEntityMap.get(r.billingEntity).LastInvoiceNumber__c).leftPad(4,'0');
                invoices.add(newInvoice);
            }else{
                if(avoirSelector.get(r.invoiceId).Status__c == 'validated'){
                    newInvoice.Name = BillingEntityMap.get(r.billingEntity).InvoicePrefix__c + String.valueOf(Date.today().year()).substring(2) + String.valueOf(BillingEntityMap.get(r.billingEntity).LastInvoiceNumber__c).leftPad(4,'0') + ' - Avoir';
                    newInvoice.InvoiceNumber__c = BillingEntityMap.get(r.billingEntity).InvoicePrefix__c + String.valueOf(Date.today().year()).substring(2) + String.valueOf(BillingEntityMap.get(r.billingEntity).LastInvoiceNumber__c).leftPad(4,'0');
                    invoices.add(newInvoice);
                }else{
                    newInvoice.Name = 'PROFORMA - '+ avoirSelector.get(r.invoiceId).Opportunity__r.InsertionOrderId__c + ' - Avoir';
                    newInvoice.SentInvoice__c = false;
                    newInvoice.ProvisionSent__c = false;
                    invoices.add(newInvoice);
                }
            }
        }
        update invoices;
        
        List<insertion__c> insertions = new List<insertion__c>();
        for(InvoiceItem__c i : [select insertion__c from InvoiceItem__c where invoice__c in :invoiceIds and insertion__c != null ]) insertions.add(new Insertion__c(Id = i.insertion__c, status__c = 'OI facturé'));
        
        update insertions;
        update BillingEntityMap.values();
    }
}