public with sharing class HeatMapColumn {
    public String name { get; private set; }
    public String category { get; private set; }//TODO: change to ENUM
    public String columnId { get; private set; }
    public Boolean isSortable { get; private set; }
    public Boolean isReadOnly { get; private set; }
    public String sortingTypeDefinition { get; private set; }
    public String columnAlignment { get; private set; }
    public Boolean isHeaderFilter { get; private set; }
    //public Map<String, String> colorCodesByValues { get; private set; }
    //public List<ColumnModalAttribute> modalAttributes { get; private set; }
    public String sortDirection;
    //public String displayType; //picklist, text, number, date, etc.
    public String type { get; private set; }
    public String reportUrl { get; set; }
    public Boolean isTelemetryAvailable { get; set; }

    public HeatMapColumn(HeatMap_Column__c column) {
        this.name = column.Name;
        this.category = column.Column_Filter__c;
        this.isSortable = column.Sortable__c;
        this.isReadOnly = column.Read_Only__c;
        this.sortDirection = null;
        this.columnId = column.Id;
        this.sortingTypeDefinition = column.Sorting_Datatype_Definition__c;
        this.columnAlignment = column.Column_Alignment__c;
        this.isHeaderFilter = column.Header_Filter__c;
        /*if(column.Color_Coding__c != null) {
            this.colorCodesByValues = new Map<String, String>();
            for(String keyValue : column.Color_Coding__c.split(';')) {
                List<String> key = keyValue.split('=>');
                this.colorCodesByValues.put(key[0], key[1]);
            }
        }*/
        if(column.Manual_Entry__c){
            this.type = 'Manual';
        } else{
            this.type = 'Workload';
        }

        this.reportUrl = column.Report_URL__c;
        this.isTelemetryAvailable = String.isNotBlank(column.Telemetry_Workload_Name__c);

        /*if(this.type == 'Workload') {
            this.modalAttributes = new List<ColumnModalAttribute>();
            this.modalAttributes.add(new ColumnModalAttribute('Object Count', 'number'));
        }*/
    }

    public List<HeatMapAttribute> sort(List<HeatMapAttribute> attributes) {
        return null;
    }

    /*class ColumnModalAttribute {
        public String label;
        public String displaytype; //TODO: change to ENUM, picklist, text, number, date, etc.
        ColumnModalAttribute(String label, String displaytype){
            this.label = label;
            this.displaytype = displaytype; 
        }
    }*/
}