public class io_controller {
    
    public class IoException extends Exception {}
    
    public io_controller(ApexPages.StandardController std) {}
    
    @AuraEnabled
    public static User getUserProfile() {
        return [select id,profile.name, bu__c from user where id = :UserInfo.getUserId() LIMIT 1];
    }
    
    @auraEnabled
    public static List<Insertion__c> getOppInsertions(Id recordId){
        system.debug('recordId->'+recordId);
        List<Insertion__c> insertionList = [select Id,StartDate__c,EndDate__c,volume__c,revenue__c,Status__c,OpportunityProduct__c,Opportunity__c,Product__c, CampaignNumber__c, OrderReference__c,
                OpportunityProduct__r.Name,OpportunityProduct__r.UnitPrice__c,OpportunityProduct__r.PricingModel__c, NewInsertion__c,
                product__r.Devices__c, product__r.Targeting__c,product__r.Medium__c, product__r.Type_Promogaming__c, product__r.Format__c, product__r.Type__c,product__r.PricingModel__c,canDelete__c,UnitPrice__c, Free__c 
                from insertion__c
                where Opportunity__c = :recordId
                and status__c in ('Signé','Signé/contrôlé','Clôturé','OI facturé')];
        system.debug('insertionList->'+insertionList);
        return insertionList;
    }
    
    @AuraEnabled
    public static void updateInsertions(String data) {
        List<Insertion__c> insertions = (List<Insertion__c>) JSON.deserialize(data, List<Insertion__c>.class);
        try{
            upsert insertions;
            system.debug('insertions->'+insertions);
        }catch (Exception e){
            throw new IoException(e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static void deleteInsertion(Id recordId) {
        delete new Insertion__c(Id = recordId);
    }
    
    @AuraEnabled
    public static String getClosingOpp(String recordId){
        Opportunity opp = [SELECT id, RecordType.Name FROM Opportunity WHERE Id =: recordId];
        return opp.RecordType.Name; 
    }

    @auraEnabled
    public static String getFilters(){
        String userBU = [select bu__c from user where id=:UserInfo.getUserId()].bu__c;
        Map<String,List<Map<String,String>>> filterMap = new Map<String,List<Map<String,String>>>();
        Schema.DescribeSobjectResult p = Schema.describeSObjects(new List<String>{'Product2'})[0];
        
        for(String f : new List<String>{'BU__c','Medium__c', 'Type_Promogaming__c','Format__c', 'Type__c','Category__c','Targeting__c','PricingModel__c','Devices__c'}) {
            List<Map<String,String>> vals = new List<Map<String,String>>();
            Map<String,String> v = new Map<String,String>();
            v.put('label','');
            v.put('value','');
            vals.add(v); 
            
            for (Schema.PicklistEntry entry : p.fields.getMap().get(f).getDescribe().getPicklistValues()) {
                if (entry.isActive()) { 
                    v = new Map<String,String>();
                    v.put('label',entry.getLabel());
                    v.put('value',entry.getValue());
                    v.put('selected',(f == 'BU__c' && userBU == entry.getValue()) ? 'true' : 'false');
                    vals.add(v); 
                }
            }
            filterMap.put(f,vals);
        }
        system.debug(JSON.serialize(filterMap));
        return JSON.serialize(filterMap);
    }
    
    @auraEnabled
    public static Map<String,list<Product2>> getProducts(String BU){
        Map<String,list<Product2>> productMap = new Map<String,list<Product2>>();
        for(product2 p  :[SELECT Id,Name,Medium__c, Type_Promogaming__c, Discount__c, Type__c, Category__c, Targeting__c, Format__c, Devices__c, PricingModel__c, RecordType.developerName,
                (select id, ChildProduct__r.Medium__c, ChildProduct__r.Type_Promogaming__c, ChildProduct__r.Discount__c, ChildProduct__r.Type__c, ChildProduct__r.Category__c, ChildProduct__r.Targeting__c, ChildProduct__r.Format__c,
                ChildProduct__r.Devices__c, ChildProduct__r.PricingModel__c from packageProducts__r)
                FROM Product2 where isactive = true and bu__c INCLUDES (:BU) order by recordtypeid,Name]) {
            list<Product2> typeProducts = productMap.get(p.RecordType.developerName);
            if(typeProducts == NULL) typeProducts = new list<Product2>();
            typeProducts.add(p);
            productMap.put(p.RecordType.developerName,typeProducts);
        }
        return productMap;
    }
    
    @auraEnabled
    public static Map<String, String> getStatsPromoValues(){
        Map<String, String> values = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Product__c.StatsPromoUnit__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            values.put(f.getLabel(), f.getValue());
        }
        return values;
    }
    
    @auraEnabled
    public static Map<String, String> getBrandNameValues(){
        Map<String, String> values = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = Product__c.BrandName__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple){
            values.put(f.getLabel(), f.getValue());
        }
        return values;
    }
    
    
    @RemoteAction
    public static void save(Id recordId, String namePrefix, String pageName) {
        system.debug(recordId+' '+namePrefix+' '+pageName);
        Datetime dt = Datetime.now();
        PageReference pdfPage = new PageReference(pageName);
        pdfPage.getParameters().put('Id',recordId);
        pdfPage.getParameters().put('rendered','false');
        Blob pdfBlob = Test.isRunningTest() ? Blob.valueOf('Unit Test') : pdfPage.getContent();
     
        system.debug(EncodingUtil.base64Encode(pdfBlob));
        String name = namePrefix + dt.format('dd/MM/yyyy HH:mm:ss');
        List<ContentVersion> lcv = new List<ContentVersion>();
        
        ContentVersion conVer = new ContentVersion();
        conVer.ContentLocation = 'S'; 
        conVer.Title = name;
        conVer.PathOnClient = name + '.pdf';
        conVer.VersionData = pdfBlob; 
        lcv.add(conVer);
        
        List<String> alreadyAddDocs = new List<String>();
        String testAndRemove = 'Frais technique Web to store';
        List<Integer> docsToRemove = new List<Integer>();
        Integer counter = 0;
        Opportunity opport = [select id, 
                              (select id, name, package__r.Name, 
                               package__r.DocumentTemplate__r.Id,
                               package__r.DocumentTemplate__r.TemplateBodyHTML__c,
                               package__r.DocumentTemplate__r.isHTML__c from Products__r) 
                              from opportunity 
                              where id = :recordId];
        
        List<AssociationDocumentTemplate__mdt> ladt = [select id, Masterlabel, Template_to_use__c, Master_object__c, Vfp_used__c, order__c from AssociationDocumentTemplate__mdt order by order__c asc];
        for(AssociationDocumentTemplate__mdt adt : ladt){
            if(adt.MasterLabel == 'Telemarketing'){
				docsToRemove.add(counter);            
        	}
            counter++;
        }
        for(Integer docRef : docsToRemove) ladt.remove(docRef);
        for(AssociationDocumentTemplate__mdt adt : ladt) {
            for(Product__c p : opport.Products__r) {
                system.debug(p.Package__r.Name);
                if(alreadyAddDocs.contains(p.Package__r.Name)) continue;
                String templateBody = p.package__r.DocumentTemplate__r.isHtml__c ? p.package__r.DocumentTemplate__r.TemplateBodyHTML__c : p.package__r.DocumentTemplate__r.TemplateBody__c;
                if(adt.Template_to_use__c == p.package__r.DocumentTemplate__r.Id) { 
                    PageReference page = new PageReference('/apex/DocumentTemplatePage?id='+recordId+
                                                           '&masterObject='+adt.Master_object__c+
                                                           '&relatedObject='+'Product__c'+
                                                           '&relatedId='+p.Id+
                                                           '&templateId='+p.package__r.DocumentTemplate__r.Id);
                    
                    ContentVersion conVer2 = new ContentVersion();
                    conVer2.ContentLocation = 'S';
                    if(testAndRemove.contains(p.name)) p.name= 'Contrat d’application Web to Store';
                    conVer2.Title = namePrefix + p.name + '_' + dt.format('dd/MM/yyyy HH:mm:ss');
                    conVer2.PathOnClient = name + '.pdf';
                    conVer2.VersionData = page.getContent(); 
                    lcv.add(conVer2);
                    
                    alreadyAddDocs.add(p.Package__r.Name);
                }
            }
        } 
        
        insert lcv;
        
        
        Set<Id> setCv = new Set<Id>();
        for(ContentVersion cv : lcv) setCv.add(cv.Id);
        
        // First get the content document Id from ContentVersion
        List<ContentVersion> listContentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN :setCv];
        
        List<ContentDocumentLink> lcdl = new List<ContentDocumentLink>();
        
        for(ContentVersion cv : listContentVersion){
            ContentDocumentLink cDe = new ContentDocumentLink();
            cDe.ContentDocumentId = cv.ContentDocumentId;
            cDe.LinkedEntityId = recordId;
            cDe.ShareType = 'I'; // Inferred permission
            cDe.Visibility = 'AllUsers'; // 'SharedUsers'; //
            lcdl.add(cDe);
        }
        insert lcdl;        
    }
    
    @AuraEnabled
    public static Id cloneWithProducts(Id recordId, String fields, Date startDate, Date endDate) {
        Id recId = recordId;
        Opportunity oldOpportunity = database.query('SELECT '+fields+' FROM Opportunity WHERE Id = :recId');
        Opportunity newOpportunity = oldOpportunity.clone(false);
        newOpportunity.Name = 'Copie de '+ newOpportunity.Name;
        newOpportunity.CampaignStartDate__c = startDate;
        newOpportunity.CampaignEndDate__c = endDate;
        newOpportunity.CloseDate = Date.today();
        newOpportunity.StageName = 'Proposition push';
        insert newOpportunity;
        
        List<Product__c> items = new List<Product__c>();
        for (Product__c p : [ SELECT Id, Name, Targeting__c, Type_Promogaming__c, Format__c, PricingModel__c, Package__c, UnitPrice__c,Total__c,Quantity__c,Device__c,Opportunity__c,Medium__c,Type__c,StartDate__c,EndDate__c,TechnicalProductIds__c, EAN__c, Amount_Excl_taxes__c FROM Product__c WHERE Opportunity__c = :recordId]) {
            Product__c newP = p.clone(false);
            newP.Opportunity__c = newOpportunity.id;
            newP.StartDate__c = startDate;
            newP.EndDate__c = endDate;
            items.add(newP);
        }
        insert items;
        
        return newOpportunity.Id;
    }
}