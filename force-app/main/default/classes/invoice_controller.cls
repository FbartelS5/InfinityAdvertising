public with sharing class invoice_controller {
    public final Invoice__c Invoice;
    public final List<invoiceDetail> invoiceDetails;

    public invoice_controller() {
        invoiceDetails = new List<invoiceDetail>();

        Invoice = [SELECT 
                    Id, 
                    Status__c,
                    Today__c,
                    Name,
                    Avoir__c,
                    OriginalInvoiceNumber__r.InvoiceNumber__c,
                    Opportunity__r.AutoOppId__c,
                    Opportunity__r.Name,
                    Advertiser__r.Name,
                    Advertiser__r.GenerixCode__c,
                    Advertiser__r.BillingStreet,
                    Advertiser__r.BillingPostalCode,
                    Advertiser__r.BillingCity,
                    Advertiser__r.BillingCountry,
                    Advertiser__r.IntracomVatNumber__c,
                    Account__r.Name,
                    Account__r.GenerixCode__c,
                    Invoice__c.Account__r.BillingStreet,
                    Account__r.BillingCity,
                    Account__r.BillingPostalCode,
                    Account__r.BillingCountry,
                    Account__r.IntracomVatNumber__c,
                    TotalExcludingVat__c,
                    VAT_Amount__c,
                    TotalWithVat__c,
                    InvoiceTerm__c,
                    InvoiceDate__c,
                    Opportunity__r.Developer_Name__c,
                    Opportunity__r.BillingEntity__r.ioConditions__c,
                    (SELECT 
                        Id, 
                        Insertion__r.OpportunityProduct__r.Id,
                        Insertion__r.OpportunityProduct__r.Name,
                        Insertion__r.OpportunityProduct__r.StartDate__c,
                        Insertion__r.OpportunityProduct__r.EndDate__c,
                        Insertion__r.OpportunityProduct__r.Description__c
                    FROM InvoiceItems__r) 
                FROM Invoice__c 
                WHERE Id = :ApexPages.currentPage().getParameters().get('id')];

        Map<Id, Product__c> products = new Map<ID, Product__c>();
        
        for(InvoiceItem__c item : invoice.invoiceitems__r){
            products.put(item.Insertion__r.OpportunityProduct__c, item.Insertion__r.OpportunityProduct__r);
        }
        
        //[SELECT Id, StartDate__c, EndDate__c, Description__c, Name FROM Product__c WHERE Invoice__c =:invoice.Id]);

        for(AggregateResult ar : [SELECT Insertion__r.OpportunityProduct__c opportunityProduct__c, SUM(TotalExcludingVat__c) totalExcludingVat 
                                    FROM InvoiceItem__c 
                                    WHERE Invoice__c =: invoice.Id 
                                    GROUP BY Insertion__r.OpportunityProduct__c]){

            Product__c product = products.get((String) ar.get('opportunityProduct__c'));
            
            invoiceDetail invoiceDetail = new invoiceDetail();
            invoiceDetail.totalExcludingVat = (Double) ar.get('totalExcludingVat');
            if(product != null){
                invoiceDetail.opportunityProductName = product.Name;
                if(product.StartDate__c != null){
                    invoiceDetail.startDate = product.StartDate__c.format();
                }
                if(product.EndDate__c != null){
                    invoiceDetail.endDate = product.EndDate__c.format();
                }            
                invoiceDetail.description = product.Description__c;
            }
            invoiceDetails.add(invoiceDetail);
        }
    }

    public Invoice__c getInvoice(){
        return Invoice;
    }

    public List<invoiceDetail> getInvoiceDetails (){
        return invoiceDetails;
    }

    public class invoiceDetail{
        public String opportunityProductName {get; set;}
        public String description {get; set;}
        public String startDate {get; set;}
        public String endDate {get; set;}
        public Double totalExcludingVat {get; set;}
    }
}