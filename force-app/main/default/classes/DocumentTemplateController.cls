public class DocumentTemplateController {
    
    class listDefinition {
        String objectname;
        String lookup;
        String fields;
        String labels;
        String filter;
        String sortby;
        String typelist;
    }
    
    class imageDefinition{
        String resource;
        String path;
        String width;
    }
    
    class lookupDefinition {
        String objectname;
        String lookup;
        String field;
        String paramNameId;
    }
    
    public static String getLabels(String masterObject, String f){
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> fieldMap;
        String errorString ='';
        if(f.contains('.') == true){
            String objectName = f.split('\\.')[0];
            if(objectName == 'Account') objectName = 'AccountId';
            if(objectName == 'Contact') objectName = 'ContactId';
            if(objectName.endsWith('__r'))objectName = objectName.replace('__r', '__c');
            String fieldName =  f.split('\\.')[1];
            system.debug(Schema.getGlobalDescribe()
                         .get(masterObject) 
                         .getDescribe()
                         .fields
                         .getMap());
            for(Integer i = 1; i< f.split('\\.').size(); i++) {
                Schema.DescribeFieldResult df = Schema.getGlobalDescribe()
                    .get(masterObject) 
                    .getDescribe()
                    .fields
                    .getMap()
                    .get(objectName)
                    .getDescribe();
                masterObject = df.getReferenceTo()[0].getDescribe().getName();
                objectName = f.split('\\.')[i];
            }
            errorString = masterObject;
            
        }else if(f != null){
            system.debug(masterObject + ' '+ f);
            Schema.SObjectType leadSchema=schemaMap.get(masterObject); 
            fieldMap = leadSchema.getDescribe().fields.getMap();
            errorString = fieldMap.get(f).getDescribe().getLabel();
        }
        system.debug(errorString);
        return errorString;
    }
    
    public static String docBody{get;set;}
    
    private static String getFieldValue(String objectJson, string field) {
        Map<String, Object> o = (Map<String, Object>)JSON.deserializeUntyped(objectJson);
        String fieldData;
        if(field.contains('.')) {
            List<String> parts = field.split('\\.');
            Integer i = 0;
            while(i < field.countMatches('.')) {
                o = (Map<String, Object>)o.get(parts[i]);
                i++;
            }
            fieldData = String.valueOf(o.get(parts[field.countMatches('.')]));
        } else fieldData = String.valueOf(o.get(field));
        if(Pattern.matches('^[0-9]*\\.?[0-9]*',fieldData) && fieldData != '.' ) fieldData = decimal.valueOf(fieldData).format();
        else if(Pattern.matches('^(?:[0-9][0-9])?[0-9][0-9]-[0-3][0-9]-[0-3][0-9]$',fieldData)) fieldData = date.valueOf(fieldData).format();
        if(field == 'CustomerReference__c') fieldData = String.valueOf(o.get(field)).trim();
        return fieldData;
    }
    
    public static string generateBody(string templateBody, string relatedObject, string documentBody, string masterObject, string relatedId, string recordId){
        Set<String> fields = new Set<String>();
        Set<String> relatedObjFields = new Set<String>();
        fields.add('Id');
        relatedObjFields.add('Id');
        
        
        // FIELD RELATED
        Matcher lookupMatcher = Pattern.compile('\\({3}(.*?)\\){3}').matcher(templateBody);
        while(lookupMatcher.find()) relatedObjFields.add(lookupMatcher.group(1));
        
        String relatedQuery = 'SELECT ' + String.join(new List<String>(relatedObjFields) ,',') + ' FROM '+relatedObject+' WHERE Id = :relatedId ';
        
        String relatedObj = JSON.serialize(database.query(relatedQuery)[0]);
        lookupMatcher = Pattern.compile('\\({3}(.*?)\\){3}').matcher(templateBody);
        Map<String, Object> relatedObjectRef = (Map<String, Object>)JSON.deserializeUntyped(relatedObj);
        List<Object> relatedobjectNameList = relatedObjectRef.values();
        system.debug(relatedobjectNameList);
        while(lookupMatcher.find()) {
            String f = lookupMatcher.group(1).trim();
            try {
                documentBody = documentBody.replace('((('+f+')))', getFieldValue(relatedObj,f));
            } catch (Exception e) {
                system.debug('Error on realtedObj field: '+f);
                String sObjType = Schema.describeSObjects(new String[]{String.valueOf(relatedobjectNameList[0]).split(',')[0].replace('{type=', '')})[0].getLabel().toUpperCase();
                
                
                
                documentBody = documentBody.replace('((('+f+')))', '<span style="font-weight:bold;color:white;background-color:red;height:10px;">'
                                                    +sObjType+' – '+getLabels(relatedObject, f)+'</span>');
            }
        }
        
        // FIELD MASTER OBJECT       
        Matcher fieldMatcher = Pattern.compile('(?<=\\{{3}).*?(?=\\}{3})').matcher(templateBody);
        while(fieldMatcher.find()) fields.add(fieldMatcher.group());
        
        String mainQuery = 'SELECT ' + String.join(new List<String>(fields) ,',') + ' FROM '+masterObject+' WHERE Id = :recordId ';
        
        String obj = JSON.serialize(database.query(mainQuery)[0]);
        fieldMatcher = Pattern.compile('(?<=\\{{3}).*?(?=\\}{3})').matcher(templateBody);
        Map<String, Object> objectRef = (Map<String, Object>)JSON.deserializeUntyped(obj);
        List<Object> objectNameList = objectRef.values();
        system.debug(objectNameList);
        while(fieldMatcher.find()) {
            String f = fieldMatcher.group().trim();
            try {
                documentBody = documentBody.replace('{{{'+f+'}}}', getFieldValue(obj,f));
            } catch (Exception e) {
                system.debug('Error on field: '+f);
                String sObjType = Schema.describeSObjects(new String[]{String.valueOf(objectNameList[0]).split(',')[0].replace('{type=', '')})[0].getLabel().toUpperCase();
                
                
                documentBody = documentBody.replace('{{{'+f+'}}}', '<span style="font-weight:bold;color:white;background-color:red;height:10px;padding-left;4px;padding:right:4px;">'
                                                    +sObjType+' – '+getLabels(masterobject, f)+'</span>');
            }
        }
        
        fieldMatcher = Pattern.compile('(?<=\\{{3}).*?(?=\\}{3})').matcher(templateBody);
        
        while(fieldMatcher.find()) {
            String f = fieldMatcher.group().trim();
            try {
                documentBody = documentBody.replace('{{{'+f+'}}}', getFieldValue(obj,f));
            } catch (Exception e) {
                system.debug('Error on field: '+objectNameList[0]);
                String sObjType = Schema.describeSObjects(new String[]{String.valueOf(objectNameList[0]).split(',')[0].replace('{type=', '')})[0].getLabel().toUpperCase();
                
                documentBody = documentBody.replace('{{{'+f+'}}}', '<span style="font-weight:bold;color:white;background-color:red;height:10px;padding-left;4px;padding:right:4px;">'
                                                    +sObjType+' – '+getLabels(masterobject, f)+'</span>');
            }
        }
        
        //DATE 
        Matcher dateMatcher = Pattern.compile('TODAY()').matcher(templateBody);
        while(dateMatcher.find()) {
            Date d = system.today();
            documentBody = documentBody.replace('TODAY()', d.format());
        }
        
        // LISTs
        List<listDefinition> lists = new List<listDefinition>();
        Matcher listMatcher = Pattern.compile('(?<=\\[{3}).*?(?=\\]{3})').matcher(templateBody);
        while(listMatcher.find()) {
            system.debug(listMatcher.group());
            listDefinition listdef = (listDefinition)JSON.deserialize(listMatcher.group().unescapeHtml4(), listDefinition.class);
            String query = 'SELECT ' + listdef.fields.trim() + ' FROM '+listdef.objectname+' WHERE '+ listdef.lookup +' = :recordId';
            if(listdef.filter != null) query += 'AND '+ listdef.filter;
            if(listdef.sortby != null) query += 'ORDER BY '+ listdef.sortby;
            system.debug(query);
            
            List<Sobject> listobj = database.query(query);
            if(listobj.size() > 0) {
                String ret = '';
                switch on listDef.typelist {
                    when 'table' {
                        ret = '<table>';
                        if(listDef.labels != null) {
                            ret += '<thead>';
                            for(String h : listDef.labels.split(',')) ret += '<th>'+h+'</th>';
                            ret += '</thead>';
                        }
                        for(Sobject o : listobj) {
                            ret += '<tr>';
                            String oJson = JSON.serialize(o);
                            for(String f : listDef.fields.split(',')) {
                                try {
                                    ret += '<td>'+getFieldValue(oJson,f)+'</td>';
                                } catch (Exception e) {
                                    ret += '<td></td>';
                                    system.debug('Error on field: '+f);
                                }
                            }
                            ret += '</tr>';
                        }
                        ret += '</table>';
                    }
                    when 'list' { 
                        ret = '<ul>';
                        for(Sobject o : listobj) {
                            ret += '<li>';
                            String oJson = JSON.serialize(o);
                            for(String f : listDef.fields.split(',')) {
                                try {
                                    ret += getFieldValue(oJson,f);
                                } catch (Exception e) {
                                    ret += '';
                                    system.debug('Error on field: '+f);
                                }
                            }
                            ret += '</li>';
                        }
                        ret += '</ul>';
                    }
                }        
                system.debug(ret);
                documentBody = documentBody.replace('[[['+listMatcher.group()+']]]', ret);
                
            } else documentBody = documentBody.replace('[[['+listMatcher.group()+']]]',
                                                       '<span style="font-weight:bold;color:white;background-color:red;height:10px;padding-left;4px;padding:right:4px;">List Error</span>');
            
        }
        
        //IMAGE
        Matcher imageMatcher = Pattern.compile('(\\#{3})(.*?)(\\#{3})').matcher(templateBody);
        while(imageMatcher.find()) {
            imageDefinition imageDef = (imageDefinition)JSON.deserialize(imageMatcher.group(2).unescapeHtml4(), imageDefinition.class);
            system.debug(imageDef);
            system.debug(imageDef.resource);
            system.debug(PageReference.forResource(imageDef.resource).getUrl());
            String ret = '';
            String myUrl = PageReference.forResource(imageDef.resource).getUrl();
            system.debug(imageDef.resource);
            if(myUrl.contains('?')) myUrl = myUrl.subString(0, myUrl.indexOf('?'));
            if(imageDef.path != '' && imageDef.path != null && imageDef.path != 'none')ret = '<img src="'+ myUrl + imageDef.path +'" width="'+imageDef.width+'"/>';
            else ret = '<img src="'+ myUrl +'" width="'+imageDef.width+'"/>';
            documentBody = documentBody.replace('###'+imageMatcher.group(2)+'###', ret);
        }
        return documentBody;
    }
    
    public static string getDocumentBody() {
        String recordId = Apexpages.currentpage().getParameters().get('id');
        String masterObject = Apexpages.currentpage().getParameters().get('masterObject');
        String relatedId = Apexpages.currentpage().getParameters().get('relatedId');
        String relatedObject = Apexpages.currentpage().getParameters().get('relatedObject');
        String templateId = Apexpages.currentpage().getParameters().get('templateId');
        DocumentTemplate__c dt = [select id, isHTML__c, TemplateBodyHTML__c, TemplateBody__c from DocumentTemplate__c where id = :templateId];
        String templateBody = dt.isHtml__c ? dt.TemplateBodyHTML__c : dt.TemplateBody__c;
        String documentBody = templateBody;
        
        return generateBody(templateBody, relatedObject, documentBody, masterObject, relatedId, recordId);
    }
    
    public static string getDocumentBody(string templateBody, PageReference page) {
        String recordId = page.getParameters().get('id');
        String masterObject = page.getParameters().get('masterObject');
        String relatedId = page.getParameters().get('relatedId');
        String relatedObject = page.getParameters().get('relatedObject');
        String documentBody = templateBody;
        return generateBody(templateBody, relatedObject, documentBody, masterObject, relatedId, recordId);
    }
}