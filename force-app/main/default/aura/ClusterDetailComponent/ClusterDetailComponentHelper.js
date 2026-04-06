({
	fillChart : function(component,helper,chartData,chartName,chartType,ResultKey,label,color,allData) {
        var data = [];
        var data1 = [];
        if(chartData == null){
            var canvas = document.getElementById(chartName);
            var ctx = canvas.getContext("2d");
            ctx.font = "18px normal 'Gotham-light'";
            ctx.fillText("No data to display",110,50);
            ctx.textAlign = 'center';
            
            return;
        }
        for(var k in label){
            var count = parseFloat(chartData[label[k]]);
            if(chartName == 'ObjectsData' || chartName == 'TotalData'){
                count = count.toFixed(0);
            }else{count = count.toFixed(2);}
            data1.push({
                x: "labelX",
                y: count
            });
        }
        
        
        var lineData = {
            labels: label,
            datasets: [
                {
                    label : ResultKey,
                    data: data1,
                    borderColor: "rgba(0, 123, 255, 0.9)",
                    borderWidth: "0",
                    backgroundColor: color
                }
            ]
        }        
        if(chartName == 'storageData'){
            console.log(allData.predLabels);
            var dataRes = [];
            var datalow = [];
            var datahigh = [];
            allData.predLabels.reverse();
            var predLabels = allData.predLabels;
            var totalCap = [];
            for(var k in label){
                totalCap.push({
                    x: "labelX",
                    y: allData.totalStorage
                });
                if(allData.clusMap['pred_storage_usage__c'] != null){
                    var count = parseFloat(allData.clusMap['pred_storage_usage__c'][label[k]]);
                    if(count != null){
                         count = parseFloat(chartData[label[k]]);
                    }
                    count = count.toFixed(2);
                    dataRes.push({
                        x: "labelX",
                        y: count
                    });
                }
                if(allData.clusMap['pred_low_storage_usage__c'] != null){
                    var count = parseFloat(allData.clusMap['pred_low_storage_usage__c'][label[k]]);
                    if(count != null){
                        count = parseFloat(chartData[label[k]]);
                    }
                    count = count.toFixed(2);
                    datalow.push({
                        x: "labelX",
                        y: count
                    });
                }
                if(allData.clusMap['pred_high_storage_usage__c'] != null){
                    var count = parseFloat(allData.clusMap['pred_high_storage_usage__c'][label[k]]);
                    if(count != null){
                        count = parseFloat(chartData[label[k]]);
                    }
                    count = count.toFixed(2);
                    datahigh.push({
                        x: "labelX",
                        y: count
                    });
                }
                
            }
            for(var j in predLabels){
                if(!label.includes(predLabels[j])){
                    totalCap.push({
                        x: "labelX",
                        y: allData.totalStorage
                    });
                    label.push(predLabels[j]);
                    if(allData.clusMap['pred_storage_usage__c'] != null){
                        var count = parseFloat(allData.clusMap['pred_storage_usage__c'][predLabels[j]]);
                        count = count.toFixed(2);
                        dataRes.push({
                            x: "labelX",
                            y: count
                        });
                    }
                    if(allData.clusMap['pred_low_storage_usage__c'] != null){
                        var count = parseFloat(allData.clusMap['pred_low_storage_usage__c'][predLabels[j]]);
                        count = count.toFixed(2);
                        datalow.push({
                            x: "labelX",
                            y: count
                        });
                    }
                    if(allData.clusMap['pred_high_storage_usage__c'] != null){
                        var count = parseFloat(allData.clusMap['pred_high_storage_usage__c'][predLabels[j]]);
                        count = count.toFixed(2);
                        datahigh.push({
                            x: "labelX",
                            y: count
                        });
                    }
                }
            }
            var dataSet = [];
            if(data1.length > 0){
                dataSet.push({
                        label : ResultKey,
                        data: data1,
                        borderColor: "rgba(0, 123, 255, 0.9)",
                        borderWidth: "0",
                        backgroundColor: color
                    });
            }
            console.log('dataRes',dataRes);
            if(dataRes.length > 0){
                dataSet.push({
                        label : 'Predicted',
                        data: dataRes,
                        borderColor: 'rgba(255, 99, 132, 1)',
                        borderWidth: "2",
                        backgroundColor: 'rgba(255, 99, 132, 1)',
                        pointRadius: 1,
                        fill : false
                    });
            }
            if(datahigh.length > 0){
                dataSet.push({
                        label : 'Predicted High',
                        data: datahigh,
                        borderColor: "rgba(255, 206, 86, 1)",
                        borderWidth: "2",
                        backgroundColor: "rgba(255, 206, 86, 1)",
                        pointRadius: 1,
                        fill : false
                    });
            }
            if(datalow.length > 0){
                dataSet.push({
                        label : 'Predicted Low',
                        data: datalow,
                        borderColor: "rgba(54, 162, 235, 1)",
                        borderWidth: "2",
                        backgroundColor: 'rgba(54, 162, 235, 1)',
                        pointRadius: 1,
                        fill : false
                    });
            }
            console.log('totalCap111',allData.totalStorage);
            if(allData.totalStorage != ''){
                dataSet.push({
                        label : 'Total Capacity',
                        data: totalCap,
                        borderColor: "rgba(153, 102, 255, 1)",
                        borderWidth: "2",
                        backgroundColor: 'rgba(153, 102, 255, 1)',
                        pointRadius: 1,
                        fill : false
                    });
            }
            lineData = {
                labels: label,
                datasets:dataSet
            }    
        }
        
        
        
        //Create Line chart
        var ctx = component.find(chartName).getElement();
        Chart.defaults.global.defaultFontSize = 16;
        var myNewChart1 = new Chart(ctx, {
            type: 'line',
            data: lineData,
            options: {
                pointDot: true,
                scaleOverride : true,
                scaleShowGridLines : false,
                scaleShowLabels : true,
                scaleSteps :10,
                scaleStepWidth : 25,
                scaleStartValue : 0,
                scales: {
                    xAxes: [{
                        stacked: true,
                        ticks: {
                            fontSize: 15
                        }
                    }],
                    yAxes: [{
                        ticks: {
                            fontSize: 15
                        }
                    }]
                },
                legend: {
                    labels: {
                        // This more specific font property overrides the global property
                        fontSize: 20
                    }
                },
                tooltips: { bodyFontSize: 20 },
                'onClick' : function (event, legendItem) {
                    /*var activeBars = myNewChart1.getElementAtEvent(event); 
                    var spinner = component.find("clusSpinner");
                    $A.util.removeClass(spinner,'slds-hide');
                    var labelse = activeBars[0]._xScale.ticks
                    var index = activeBars[0]._index;
                    var action = component.get("c.getChartsWeekly");
                    action.setParams({
                        'clusterId' : component.get("v.recordId"),
                        'chartName' : chartName,
                        'dateString' : labelse[index]
                    });
                    action.setCallback(this, function(response){
                         $A.util.addClass(spinner,'slds-hide');
                        console.log('in');
                        console.log(response.getReturnValue());
                       
                    });
                    $A.enqueueAction(action);*/
                }
                
            }
        });
        
    },
    fillGCharts  : function(component,helper){
        google.charts.load('current', {'packages':['timeline']});
        var container = document.getElementById('timelineChart');
        var chart = new google.visualization.Timeline(container);
        var dataTable = new google.visualization.DataTable();
        
        dataTable.addColumn({ type: 'string', id: 'President' });
        dataTable.addColumn({ type: 'date', id: 'Start' });
        dataTable.addColumn({ type: 'date', id: 'End' });
        dataTable.addRows([
            [ 'Washington', new Date(1789, 3, 30), new Date(1797, 2, 4) ],
            [ 'Adams',      new Date(1797, 2, 4),  new Date(1801, 2, 4) ],
            [ 'Jefferson',  new Date(1801, 2, 4),  new Date(1809, 2, 4) ]]);
        
        chart.draw(dataTable);
    },
    reloadData  : function(component,helper,chartData,chartName,chartType,ResultKey,label,color) {
        
    }
 })