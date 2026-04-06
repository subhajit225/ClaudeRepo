import { LightningElement, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import PartnerCommunityResource from '@salesforce/resourceUrl/PartnerCommunityResource';
import getFiscalYear from '@salesforce/apex/PC_PortalNavigationApexController.getFiscalYear';
import getAllData from '@salesforce/apex/PC_PortalNavigationApexController.getAllData';
import getAccountHierarchy from '@salesforce/apex/PC_PortalNavigationApexController.getAccountHierarchy';
export default class Pc_partnerDashboard_lwc extends LightningElement {
    showSpinner = true;
    @track fiscalList;
    @track fiscalYearOptions = [];
    @track fiscalYear = null;
    @track startDate = null;
    @track endDate = null;
    @track accountIds = [];
    @track accountIdsMaster = [];
    @track currentStartDate = null;
    @track currentEndDate = null;
    @track currentFiscalYear = null;
    @track toggleValue = false;
    @track url;
    @track navigate;
    @track fromToggle = false;
    @track dealinitiatedType = null;

    //added to pass data to child component
    @track widgetData = [];
    openDeals = [];
    closedDeals = [];
    psnlOpenDeals = [];
    psnlClosedDeals = [];
    psExpOpenDeals = [];
    psExpClosedDeals = [];
    approvedDR = [];
    approvedPSNLDR = [];
    approvedMDF = [];
    activeCert = [];
    approvedSPIFF = [];
    rebateAchieved = [];
    programPoints = [];
    clickedTile = null;

    disableReset = true;
    disableExport = true;

    //Card Details
    @track cardList = [];

    connectedCallback()
    {
        Promise.all([loadStyle( this, PartnerCommunityResource + '/PartnerCommunityResource/Stylesheets/PartnerCommunityCSS.css')])
            .then(() => {
                console.log("File path-->"+ PartnerCommunityResource);
            })
            .catch(error => {
                console.log( error.body.message );
            });

        let today = new Date();
        let currentfiscalyear = '';
        if(today.getMonth() >= 1){
            currentfiscalyear = today.getFullYear() + 1;
        }else{
            currentfiscalyear = today.getFullYear();
        }
        this.currentFiscalYear = currentfiscalyear;
        this.fiscalYear = currentfiscalyear;
        getFiscalYear()
        .then(result=>{
            this.fiscalList = result;
            let options = [];
            for(let i = 0; i < result.length; i++){
                options.push({label : result[i].Name, value : result[i].Name});
                if(currentfiscalyear == result[i].Name){
                    this.startDate = result[i].StartDate;
                    this.currentStartDate = result[i].StartDate;
                    this.endDate = result[i].EndDate;
                    this.currentEndDate = result[i].EndDate;
                }
            }
            this.fiscalYearOptions = options;
            this.getAccountHierarchy();
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
    }

    getAccountHierarchy(){
        getAccountHierarchy()
        .then(result=>{
            console.log('result->'+JSON.stringify(result));
            if(result.accList != undefined && result.accList.length > 0){
                let accIds = [];
                for(let i = 0; i < result.accList.length; i++){
                    accIds.push(result.accList[i].Id);
                }
                this.accountIds = accIds;
                this.accountIdsMaster = accIds;
            }else{
                this.accountIds.push(result.userRec.Contact.AccountId);
                this.accountIdsMaster.push(result.userRec.Contact.AccountId);
            }
            this.fetchData();
        })
        .catch(error=>{
            console.log('error Acc hierarchy method->'+error);
        });
    }


    fetchData(){
        getAllData({ startDate : this.startDate, endDate : this.endDate, accIds : this.accountIds, fiscalYear : this.fiscalYear})
        .then(result=>{
            this.showSpinner = true;
            this.cardList = [];
            this.activeWidgets = result.activeWidgetList;
            this.iterateOpportunities(result.oppList, result.psnlOppList, result.psExpOppList);
            this.iterateDealRegistrations(result.dealRegList);
            this.iterateContacts(result.conList);
            this.iteratePartnerFundRequests(result.pfrList);
            this.iterateMIPs(result.mipContractList);
            this.iterateProgramPoints(result.programPointsList);
            this.iterateCCRs(result.ccrList);
            console.log('in fetch data');
            this.showSpinner = false;
            if(this.clickedTile != null && this.widgetData && this.navigate == 'navigatePage'){

                //To avoid showing/navigating to report (on fiscal year change) if the data is non-clickable
                var result = this.cardList.filter(obj => {
                    return obj.data === this.clickedTile
                });
                if(!result[0].classStyle.includes('noHoverpipelineReportCard')){
                    this.loadPage();
                }
            }
        })
        .catch(error=>{
            console.log('error->'+JSON.stringify(error));
        });
        
    }

    iterateOpportunities(oppList, psnlOppList, psExpOppList){
        let openOppCount = 0;
        let openOppAmount = 0;
        let closedWonOppCount = 0;
        let closedWonOppAmount = 0;
        let widget1 = 'Closed Deals';
        let widget2 = 'Open Deals';

        for(let i=0; i < oppList.length; i++){
            let amount = 0;
            if(this.toggleValue){
                amount = oppList[i].ACV_Amount__c;
            }else{
                amount = oppList[i].Amount;
            }
            if(oppList[i].StageName != '7 Closed Won' && oppList[i].StageName !='7 Closed Lost' &&  oppList[i].StageName !='7 Closed Admin'){
                this.openDeals.push(oppList[i]);
                openOppCount = openOppCount + 1;
                if(amount != undefined && amount != null)
                openOppAmount = Math.round((openOppAmount + Math.round(amount))* 1e12) / 1e12;
            }else if(oppList[i].StageName == '7 Closed Won'){
                this.closedDeals.push(oppList[i]);
                closedWonOppCount = closedWonOppCount + 1;
                if(amount != undefined && amount != null)
                closedWonOppAmount = Math.round((closedWonOppAmount + Math.round(amount))* 1e12) / 1e12;
            }
        }
        let navigate1 = 'stopNavigate';
        let class1 = 'pipelineReportCard noHoverpipelineReportCard';
        if(closedWonOppCount > 0){
            navigate1 = 'navigatePage';
            class1 = 'pipelineReportCard';
        }
        let navigate2 = 'stopNavigate';
        let class2 = 'pipelineReportCard noHoverpipelineReportCard';
        if(openOppCount > 0){
            navigate2 = 'navigatePage';
            class2 = 'pipelineReportCard';
        }

        //PSNL Opps
        let openPSNLOppCount = 0;
        let openPSNLOppAmount = 0;
        let closedPSNLOppCount = 0;
        let closedPSNLOppAmount = 0;
        let widget3 = 'PSNL Closed Deals';
        let widget4 = 'PSNL Open Deals';

        for(let i = 0; i < psnlOppList.length; i++){
            let amount = 0;
            if(this.toggleValue){
                amount = psnlOppList[i].ACV_Amount__c;
            }else{
                amount = psnlOppList[i].Amount;
            }
            if(psnlOppList[i].StageName != '7 Closed Won' && psnlOppList[i].StageName !='7 Closed Lost' &&  psnlOppList[i].StageName !='7 Closed Admin'){
                this.psnlOpenDeals.push(psnlOppList[i]);
                openPSNLOppCount = openPSNLOppCount + 1;
                if(amount != undefined && amount != null)
                openPSNLOppAmount = Math.round((openPSNLOppAmount + Math.round(amount))* 1e12) / 1e12;
            }else if(psnlOppList[i].StageName == '7 Closed Won'){
                this.psnlClosedDeals.push(psnlOppList[i]);
                closedPSNLOppCount = closedPSNLOppCount + 1;
                if(amount != undefined && amount != null)
                closedPSNLOppAmount = Math.round((closedPSNLOppAmount + Math.round(amount))* 1e12) / 1e12;
            }
        }

        let navigate3 = 'stopNavigate';
        let class3 = 'pipelineReportCard noHoverpipelineReportCard';
        if(closedPSNLOppCount > 0){
            navigate3 = 'navigatePage';
            class3 = 'pipelineReportCard';
        }
        let navigate4 = 'stopNavigate';
        let class4 = 'pipelineReportCard noHoverpipelineReportCard';
        if(openPSNLOppCount > 0){
            navigate4 = 'navigatePage';
            class4 = 'pipelineReportCard';
        }

        //PSExpandOpp
        let openPSExpOppCount = 0;
        let openPSExpOppAmount = 0;
        let closedPSExpOppCount = 0;
        let closedPSExpOppAmount = 0;
        let widget5 = 'PS Expand Closed Deals';
        let widget6 = 'PS Expand Open Deals';

        for(let i = 0; i < psExpOppList.length; i++){
            let amount = 0;
            if(this.toggleValue){
                amount = psExpOppList[i].ACV_Amount__c;
            }else{
                amount = psExpOppList[i].Amount;
            }
            if(psExpOppList[i].StageName != '7 Closed Won' && psExpOppList[i].StageName !='7 Closed Lost' &&  psExpOppList[i].StageName !='7 Closed Admin'){
                this.psExpOpenDeals.push(psExpOppList[i]);
                openPSExpOppCount = openPSExpOppCount + 1;
                if(amount != undefined && amount != null)
                openPSExpOppAmount = Math.round((openPSExpOppAmount + Math.round(amount))* 1e12) / 1e12;
            }else if(psExpOppList[i].StageName == '7 Closed Won'){
                this.psExpClosedDeals.push(psExpOppList[i]);
                closedPSExpOppCount = closedPSExpOppCount + 1;
                if(amount != undefined && amount != null)
                closedPSExpOppAmount = Math.round((closedPSExpOppAmount + Math.round(amount))* 1e12) / 1e12;
            }
        }

        let navigate5 = 'stopNavigate';
        let class5 = 'pipelineReportCard noHoverpipelineReportCard';
        if(closedPSExpOppCount > 0){
            navigate5 = 'navigatePage';
            class5 = 'pipelineReportCard';
        }
        let navigate6 = 'stopNavigate';
        let class6 = 'pipelineReportCard noHoverpipelineReportCard';
        if(openPSExpOppCount > 0){
            navigate6 = 'navigatePage';
            class6 = 'pipelineReportCard';
        }


        if(this.activeWidgets.includes(widget1)){
            this.cardList.push({id :'1', count: closedWonOppCount, amount : '$'+closedWonOppAmount.toLocaleString(), data : widget1, url : 'partner-opportunity-pipeline', navigate : navigate1, classStyle : class1});
        }
        if(this.activeWidgets.includes(widget3)){
            this.cardList.push({id :'2', count: closedPSNLOppCount, amount : '$'+closedPSNLOppAmount.toLocaleString(), data : widget3, url : 'partner-opportunity-pipeline', navigate : navigate3, classStyle : class3});
        }
        if(this.activeWidgets.includes(widget5)){
            this.cardList.push({id :'3', count: closedPSExpOppCount, amount : '$'+closedPSExpOppAmount.toLocaleString(), data : widget5, url : 'partner-opportunity-pipeline', navigate : navigate5, classStyle : class5});
        }
        
        if(this.activeWidgets.includes(widget2)){
            this.cardList.push({id :'4', count: openOppCount, amount : '$'+openOppAmount.toLocaleString(), data : widget2, url : 'partner-opportunity-pipeline', navigate :navigate2, classStyle : class2});
        }
        if(this.activeWidgets.includes(widget4)){
            this.cardList.push({id :'5', count: openPSNLOppCount, amount : '$'+openPSNLOppAmount.toLocaleString(), data : widget4, url : 'partner-opportunity-pipeline', navigate :navigate4, classStyle : class4});
        }
        if(this.activeWidgets.includes(widget6)){
            this.cardList.push({id :'6', count: openPSExpOppCount, amount : '$'+openPSExpOppAmount.toLocaleString(), data : widget6, url : 'partner-opportunity-pipeline', navigate : navigate6, classStyle : class6});
        }
    }

    iterateContacts(conList){
        this.activeCert = conList;

        // Count all properties in each element of activeCert, excluding Id, Name, and Account_Name__c
        let totalActiveCerts = 0;
        const excludedProperties = ['Id', 'Name', 'Account_Name__c'];

        if (this.activeCert && Array.isArray(this.activeCert)) {
            this.activeCert.forEach((element, index) => {
                if (element && typeof element === 'object') {
                    const allProperties = Object.keys(element);
                    const filteredProperties = allProperties.filter(prop => !excludedProperties.includes(prop));
                    totalActiveCerts += filteredProperties.length;
                }
            });
        }

        let navigate = 'stopNavigate';
        let classStyle = 'pipelineReportCard noHoverpipelineReportCard';
        let widget3 = 'Active Certifications';
        if((totalActiveCerts) > 0){
            navigate = 'navigatePage';
            classStyle = 'pipelineReportCard';
        }

        if(this.activeWidgets.includes(widget3)){
            this.cardList.push({id :'7', count: totalActiveCerts, amount : null , data : widget3, url : 'active-certification', navigate : navigate, classStyle : classStyle});
        }
    }

    iterateDealRegistrations(dealRegList){
        let approvedDealRegCount = 0;
        let approvedPSNLDealReg = 0;
        let approvedPSNLDealRegPercentage = 0;
        let approvedAmount = 0;
        let approvedPSNLAmount = 0;
        let widget4 = 'Approved Deal Registrations';
        let widget5 = 'Approved Partner Sourced Deal Registrations';
        let widget6 = 'Approved Partner Sourced Registration Percentage';

        for(let i = 0; i < dealRegList.length; i++){
            let amount = 0;
            if(this.toggleValue){
                amount = dealRegList[i].PID_Meeting_Task__c;
            }else{
                amount = dealRegList[i].Opportunity_Amount_TVC__c;
            }

            this.approvedDR.push(dealRegList[i]);
            approvedDealRegCount = approvedDealRegCount + 1;

            if(amount != undefined && amount != null)
            approvedAmount = Math.round((approvedAmount + amount)* 1e12) / 1e12;

            if(dealRegList[i].Deal_Registration_Type__c == 'Partner Initiated Deal' || dealRegList[i].Deal_Registration_Type__c == 'Partner Sourced New Logo (PSNL)' || dealRegList[i].Deal_Registration_Type__c == 'Partner Sourced Expand'){//prit25-10
                this.approvedPSNLDR.push(dealRegList[i]);
                approvedPSNLDealReg = approvedPSNLDealReg + 1;

                if(amount != undefined && amount != null)
                approvedPSNLAmount = Math.round((approvedPSNLAmount + amount)* 1e12) / 1e12;
            }
        }
        if(approvedDealRegCount != 0 ){
            approvedPSNLDealRegPercentage = (approvedPSNLDealReg/approvedDealRegCount)*100;
        }
        let navigate1 = 'stopNavigate';
        let class1 = 'pipelineReportCard noHoverpipelineReportCard';
        if(approvedDealRegCount > 0){
            navigate1 = 'navigatePage';
            class1 = 'pipelineReportCard';
        }
        let navigate2 = 'stopNavigate';
        let class2 = 'pipelineReportCard noHoverpipelineReportCard';
        if(approvedPSNLDealReg > 0){
            navigate2 = 'navigatePage';
            class2 = 'pipelineReportCard';
        }

        if(this.activeWidgets.includes(widget4)){
            this.cardList.push({id :'8', count: approvedDealRegCount, amount : '$'+approvedAmount.toLocaleString() , data : widget4, url : 'dealreglist', navigate : navigate1, classStyle : class1});
        }
        if(this.activeWidgets.includes(widget5)){
            this.cardList.push({id :'9', count: approvedPSNLDealReg, amount : '$'+approvedPSNLAmount.toLocaleString(), data : widget5, url : 'dealreglist', navigate : navigate2, classStyle : class2}); //prit25-10
        }
        if(this.activeWidgets.includes(widget6)){
            this.cardList.push({id :'10', count: approvedPSNLDealRegPercentage.toFixed(2) + '%', amount : null , data : widget6, url : 'dealreglist', navigate : navigate1, classStyle : class2}); //prit25-10
        }
    }

    iteratePartnerFundRequests(pfrList){
        let approvedAmount = 0;
		let widget7 = 'Approved Development Fund Requests';
        for(let i = 0; i < pfrList.length; i++){
            this.approvedMDF.push(pfrList[i]);
            if(pfrList[i].Amount != undefined && pfrList[i].Amount != null){
                approvedAmount = Math.round((approvedAmount + pfrList[i].Amount)* 1e12) / 1e12;
            }
        }
        let navigate = 'stopNavigate';
        let classStyle = 'pipelineReportCard noHoverpipelineReportCard';
        if((pfrList.length) > 0){
            navigate = 'navigatePage';
            classStyle = 'pipelineReportCard';
        }
		
		if(this.activeWidgets.includes(widget7)){
			this.cardList.push({id :'11', count: pfrList.length, amount : '$' + approvedAmount.toLocaleString() , data : widget7, url : 'marketingfunds', navigate : navigate, classStyle : classStyle});
		}
    }

    iterateMIPs(mipContractList){
        let totalActualPayout = 0;
        let totalMaxPayout = 0;
        let nearestThousand = 0;
		let widget8 = 'Rebates Achieved';
        
        for(let i=0; i < mipContractList.length; i++){
            this.rebateAchieved.push(mipContractList[i]);
            if(mipContractList[i].Actual_Rebate_Payout__c != undefined && mipContractList[i].Actual_Rebate_Payout__c != null){
                totalActualPayout = Math.round(( totalActualPayout + mipContractList[i].Actual_Rebate_Payout__c)* 1e12) / 1e12;
                if(mipContractList[i].Actual_Total_Milestone_Payout__c != undefined && mipContractList[i].Actual_Total_Milestone_Payout__c != null){
                    totalActualPayout = Math.round((totalActualPayout + mipContractList[i].Actual_Total_Milestone_Payout__c)* 1e12) / 1e12;
                    nearestThousand =  Math.round(totalActualPayout/1000)*1000;
                    totalActualPayout = nearestThousand;
                }
            }

            if(mipContractList[i].Max_Rebate_Payout__c != undefined && mipContractList[i].Max_Rebate_Payout__c != null){
                totalMaxPayout = Math.round((totalMaxPayout + mipContractList[i].Max_Rebate_Payout__c)* 1e12) / 1e12;
                if(mipContractList[i].Max_Total_Milestone_Payout__c != undefined && mipContractList[i].Max_Total_Milestone_Payout__c != null){
                    totalMaxPayout = Math.round((totalMaxPayout + mipContractList[i].Max_Total_Milestone_Payout__c)* 1e12) / 1e12;
                }
            }
        }
        let navigate = 'stopNavigate';
        let classStyle = 'pipelineReportCard noHoverpipelineReportCard';
        if((Math.trunc(totalActualPayout)) > 0){
            navigate = 'navigatePage';
            classStyle = 'pipelineReportCard';
        }

		if(this.activeWidgets.includes(widget8)){
			this.cardList.push({ id : '12', count : '$' +Math.trunc(totalActualPayout).toLocaleString(), amount : 'of $' + Math.trunc(totalMaxPayout).toLocaleString() + ' planned', data : widget8, url : 'rebate-report', navigate : navigate, classStyle : classStyle});
		}

    }

    iterateProgramPoints(programPointsList){
        let totalPoints = 0;
		let widget9 = 'Program Points';
        for(let i = 0; i < programPointsList.length; i++){
            this.programPoints.push(programPointsList[i]);
            if(programPointsList[i].Total__c != undefined && programPointsList[i].Total__c != null){
                totalPoints = Math.round((totalPoints + programPointsList[i].Total__c)* 1e12) / 1e12;
            }
        }
        let navigate = 'stopNavigate';
        let classStyle = 'pipelineReportCard noHoverpipelineReportCard';
        if(totalPoints > 0){
            navigate = 'navigatePage';
            classStyle = 'pipelineReportCard';
        }
		
		if(this.activeWidgets.includes(widget9)){
			this.cardList.push({ id :'13', count:totalPoints, amount : null, data : widget9, url : '', navigate : navigate, classStyle : classStyle});
		}

    }

    iterateCCRs(ccrList){
        let approvedPayeeAmount = 0;
        let approvedSEAmount = 0;
		let widget10 = 'Approved SPIFF Claims';
        this.approvedSPIFF = ccrList;

        for(let i = 0; i < ccrList.length; i++){
            if(ccrList[i].Partner_REP_Amount__c != undefined && ccrList[i].Partner_REP_Amount__c != null){
                approvedPayeeAmount = Math.round((approvedPayeeAmount + ccrList[i].Partner_REP_Amount__c)* 1e12) / 1e12;
            }
            if(ccrList[i].Partner_SE_Amount__c != undefined && ccrList[i].Partner_SE_Amount__c != null){
                approvedSEAmount = Math.round((approvedSEAmount + ccrList[i].Partner_SE_Amount__c)* 1e12) / 1e12;
            }
        }
        let navigate = 'stopNavigate';
        let classStyle = 'pipelineReportCard noHoverpipelineReportCard';
        if((ccrList.length) > 0){
            navigate = 'navigatePage';
            classStyle = 'pipelineReportCard';
        }
		
		if(this.activeWidgets.includes(widget10)){
			this.cardList.push({id :'14', count: ccrList.length, amount : '$'+(approvedPayeeAmount + approvedSEAmount).toLocaleString() , data : widget10, url : 'incentives', navigate : navigate, classStyle : classStyle});
		}
        //console.log('Json cardList->'+JSON.stringify(this.cardList));
    }


    handlefiscalYearChange(event){
        this.showSpinner = true;
        this.resetReportSection();
        this.disableFilter = false;
        this.disableReset = false;
        let fiscalY = event.detail.value;
        let fiscalListOptions = this.fiscalList;
        for(let i = 0; i < fiscalListOptions.length; i++){
            if(fiscalListOptions[i].Name == fiscalY){
                this.fiscalYear = fiscalListOptions[i].Name;
                this.startDate = fiscalListOptions[i].StartDate;
                this.endDate = fiscalListOptions[i].EndDate;
            }
        }

        
        this.fetchData();
    }

    handleAccountFilter(event){
        this.showSpinner = true;
        this.resetReportSection();
        if(event.detail.length > 0){
            this.accountIds = event.detail;
        }else{
            this.accountIds = this.accountIdsMaster;
        }
        this.disableReset = false;
        this.fetchData();
    }

    handleReset(){
        this.showSpinner = true;
        this.resetReportSection();
        this.disableReset = true;
        this.fiscalYear = this.currentFiscalYear;
        this.template.querySelectorAll('lightning-combobox').forEach(each => {
            each.value = '';
        });
        this.startDate = this.currentStartDate;
        this.endDate = this.currentEndDate;
        this.accountIds = this.accountIdsMaster;
        this.dealinitiatedType = null;
        this.template.querySelector('c-pc_account-Hierarchy').reset();

        //Commenting below line to avoid duplicate data
        //Above line calls this.fetchData() indirectly
        
        //this.fetchData();
    }

    handleFilter(event){
        //call filtered data
        
    }

    stopNavigate(event){
        console.log('no records');
    }

    navigatePage(event){
        let address = window.location.origin + '/s/';
        let value = event.currentTarget.id;
        let url = address + value.slice(0,value.lastIndexOf('-'));
        this.url = url;
        this.clickedTile = event.currentTarget.dataset.id;
        let naviagte = event.currentTarget.dataset.navigate;
        this.navigate = naviagte;
        console.log('naviagte->'+this.navigate);
        console.log('this.clickedTile->'+this.clickedTile);
        console.log('this.url',this.url);

        this.loadPage();
    }

    loadPage(){
        this.widgetData = [];
        switch(this.clickedTile){
            case "Open Deals":
                this.widgetData = this.openDeals;
                break;
            case "PSNL Open Deals":
                this.widgetData = this.psnlOpenDeals;
                break;
            case "PS Expand Open Deals":
                this.widgetData = this.psExpOpenDeals;
                break;
            case "Closed Deals":
                this.widgetData = this.closedDeals;
                break;
            case "PSNL Closed Deals":
                this.widgetData = this.psnlClosedDeals;
                break;
            case "PS Expand Closed Deals":
                this.widgetData = this.psExpClosedDeals;
                break;
            case "Approved Deal Registrations":
                this.widgetData = this.approvedDR;
                break;
            case "Approved Partner Sourced Deal Registrations":
                this.widgetData = this.approvedPSNLDR;
                break;
            case "Active Certifications":
                this.widgetData = this.activeCert;
                break;
            case "Approved SPIFF Claims":
                this.widgetData = this.approvedSPIFF;
                break;
            case "Approved Development Fund Requests":
                this.widgetData = this.approvedMDF;
                break;
            case "Rebates Achieved":
                this.widgetData = this.rebateAchieved;
                break;
            case "Program Points":
                this.widgetData = this.programPoints;
                break;
            default:
                this.clickedTile = null;
                this.widgetData = null;
        }
        console.log('this.navigate'+this.navigate);
        if(this.clickedTile && this.widgetData && this.navigate == 'navigatePage'){
            const reportSection = this.template.querySelector('c-pc_partner-report_lwc');
            reportSection.sendReportData(this.clickedTile,this.widgetData,this.url, this.toggleValue);
            if(!this.fromToggle){
                setTimeout(function(){reportSection.scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"})},50);
            }else{
                this.fromToggle = false;
            }
        }
    }

    resetReportSection(){
        this.openDeals = [];
        this.psnlOpenDeals = [];
        this.psExpOpenDeals = [];
        this.closedDeals = [];
        this.psnlClosedDeals = [];
        this.psExpClosedDeals = [];
        this.approvedDR = [];
        this.approvedPSNLDR = [];
        this.approvedMDF = [];
        this.activeCert = [];
        this.approvedSPIFF = [];
        this.rebateAchieved = [];
        this.programPoints = [];
        this.widgetData = [];
        this.template.querySelector('c-pc_partner-report_lwc').sendReportData(null,null,null);
    }

    handleToggleChange(event){
        this.showSpinner = true;
        this.fromToggle = true;
        if(event.target.checked){
            this.toggleValue = true;
        }else{
            this.toggleValue = false;
        }
        this.resetReportSection();
        this.fetchData();
    }

    get displayCardList(){
        return this.cardList.length > 0;
    }

}