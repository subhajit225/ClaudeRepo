global class AssetCountUnderAccountSchedular implements Schedulable {
   global void execute(SchedulableContext sc) {
      AssetCountUnderAccountBatch b = new AssetCountUnderAccountBatch(); 
      database.executebatch(b,Integer.valueOf(System.Label.BAtch_Size));
   }
}