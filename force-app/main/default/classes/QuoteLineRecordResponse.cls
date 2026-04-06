/***********************************************************************************************************
 * Class Name           : QuoteLineRecordResponse
 * Date Created/Modified: 06/22/2025
 * @description : To record the response from QCP and pass to DataDumping class                    
/**********************************************************************************************************/
public class QuoteLineRecordResponse {
    /**Product Code */
    public String prodCode;
    /**Quantity */
    public Decimal newQty;
    /**Product Level */
    public String pLvl;
    /**Product Type */
    public String ptyp;
    /**Required By Id */
    public String rqBy;
    /**Related Asset Total Capacity */
    public Decimal asCap;
    /**Add-On Level*/
    public String aoLvl;
    /**Product Family */
    public String pFam;
    /**Product SubType */
    public String pSt;
    /**Expected Default Quantity */
    public Decimal eQty;
    /**RWD Polaris SKUs Quantity Changed */
    public Boolean qtyC;
    /*Temp Appliance Count*/
    public Decimal apCt;
    /**Product Name */
    public String pNam;
    /**Usable Capacity */
    public Decimal uCap;
    /*Existing*/
    public Boolean ext;
    /**Number */
    public Decimal nbr;
    /**Product Id */
    public String prd;
    /**Line Type */
    public String lTyp;
    /**Total Usable Capacity */
    public Decimal tCap;
    /**Old Total Usable Capacity*/
    public Decimal oTCap;
    /**No of TBs Cloud */
    public Decimal tbCld;
    /**No of TBs Environment */
    public Decimal tbEnv;
    /**TPH Drive Size */
    public String dSize;
    /**TPH Quantity */
    public String tQty;
    /** Temp Node Count*/
    public Decimal nCt;
    /**Segment Label */
    public String sLbl;
    /**RWD Total Capacity */
    public Decimal totCap;
    /**RWD TB Per Appliance Ratio */
    public Decimal tbAp;
    /**Record Id */
    public String rcId;
    /*sP*/
    public String sP;//ARY-1079
    /*Parent Support Tier*/
    public String reqSupTier;
    /*Parent HW Support Tier*/
    public String reqHWSupTier;
    /*Support Tier*/
    public String supTier;
    /*HW Support Tier*/
    public String hWSupTier;
     /*SBQQ__Optional__c*/
    public Boolean optional;
    /*IP*/
    public Double lP;
    /*Replacement Details*/
    public String replacementDetails;
    /*Credit Calculation SD */
    public Date creditSD;
    /*List Total Price*/
    public Double listTotal;
    /*Replacement Motion*/
    public String replacementMotion;
    /*Subscription Term*/
    public Integer subsTerm;
    /*Subscription Pricing*/
    public String subsPrice;
    /*Wapper Line*/
    public Boolean wrapLine;
    /*convSubsAst*/ 
    public String convSubsAst; //MS CPQ22-5842
    /*startDate*/
    public Date startDate; //MS CPQ22-5842
    /**Constructor */
    /***********************************************************************************************************
   * Class Name           : QuoteLineRecordResponse
   * Date Created/Modified: 06/22/2025
   * @description : Constructor                
  /**********************************************************************************************************/
    public QuoteLineRecordResponse () {
      System.debug(LoggingLevel.DEBUG, 'Constructor');
 
    }
}