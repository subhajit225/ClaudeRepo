public Class checkRecursive{ 
    private static boolean run= true;
    public static boolean runAfter = true;
    public static boolean AllowSupportPortalUserCreation =false;
    public static boolean stopOrderTriggerOnRMAInsert=false;
     public static boolean entitlementlinkcreation = false; // RWD-1375
    public static boolean runOnce(){
        if(run){
            run=false;
            return true;
        }else{
            return run;
        }
    }
     public static boolean runAfterOnce(){
        if(runAfter){
            runAfter=false;
            return true;
        }else{
            return runAfter ;
        }
    }
    public static boolean getRun(){
            return run;
    }
    public static void setRun(boolean vRun){
            run=vRun;
    }
}