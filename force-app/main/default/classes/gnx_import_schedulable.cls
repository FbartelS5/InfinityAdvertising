global class gnx_import_schedulable implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        List<String> fileToImport = new List<String>();
        String fileName ='ENC_WR-'+String.valueOf(DateTime.newInstance(Date.today(),Time.newInstance(0,0,0,0)).format('YYYYMMDD'))+'.xls';
        fileToImport.add(fileName);
        gnx_import.importFromAPI(fileToImport);
    }
}