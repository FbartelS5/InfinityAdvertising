public with sharing class DynamicCategorieController {
    @AuraEnabled(cacheable=true)

    public static List<Categorie_reservee__c> getAllParentAccounts() {
        Id recordTypeIDRayon = Schema.SObjectType.Categorie_Reservee__c.getRecordTypeInfosByName().get('Rayon').getRecordTypeId();
        System.debug('recordTypeIDRayon'+ recordTypeIDRayon);
        return [SELECT Name FROM Categorie_reservee__c WHERE RecordTypeId=:recordTypeIDRayon AND IsActive__c = true];
    }

    @AuraEnabled
    public static List<Categorie_reservee__c> getChildAccounts(Id parentId) {
        return [
            SELECT Name
            FROM Categorie_reservee__c
            WHERE Univers__c = :parentId
        ];
    }

    @AuraEnabled
    public static List<parentwrapper> getuniversedetails() {

        Id recordTypeIDUnivers = Schema.SObjectType.Categorie_Reservee__c.getRecordTypeInfosByName().get('Univers').getRecordTypeId();
        List<Categorie_reservee__c> universelist = [SELECT Name,(Select Id,Name from Rayon__r ) FROM Categorie_reservee__c WHERE RecordTypeId=:recordTypeIDUnivers AND IsActive__c = true];
        System.debug('recordtypeIDUnivers'+ recordtypeIDUnivers);
        System.debug('universelist'+ universelist);

        List<parentwrapper> universewrapperlist = new List<parentwrapper>();

        for(Categorie_reservee__c c: universelist)
        {
            parentwrapper p=new parentwrapper();
            p.name=c.name;
            p.universeID=c.ID;

            system.debug('universe->'+c);
            List<childwrapper> rayonwrapperlist = new List<childwrapper>();
            for(Categorie_reservee__c b: c.Rayon__r)
            {
                childwrapper n=new childwrapper();
                system.debug('Rayonb->'+b);
                n.name=b.name;
                n.universeID=c.ID;
                n.rayonID=b.ID;
                n.isChecked=false;

                rayonwrapperlist.add(n);


            }
            p.isShown = false;
            p.rayonlist=rayonwrapperlist;

            universewrapperlist.add(p);

        }

        system.debug('universewrapperlist->'+universewrapperlist);

        return universewrapperlist;
    }

     public class parentwrapper{

        @AuraEnabled
        public String universeID {get; set;}

        @AuraEnabled
        public String name {get; set;}

        @AuraEnabled
        public Boolean isShown{ get; set; }

        @AuraEnabled
        public List<childwrapper> rayonlist {get; set;}
        

    }

    public class childwrapper{

        @AuraEnabled
        public String rayonID {get; set;}

        @AuraEnabled
        public String name {get; set;}

        @AuraEnabled
        public String universeID {get; set;}

        @AuraEnabled
        public Boolean isChecked { get; set; }
        

    }

}