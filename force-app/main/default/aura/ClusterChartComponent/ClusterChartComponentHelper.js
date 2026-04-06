({
	fillChart : function(component,helper,chartData,chartName,chartType) {
        var color=["#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#1abc9c","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#ecf0f1"];
        var colors=new Array();
        for (var i = 0; i < color.length; i++) {
            colors.push(color[i]);
        }
        var data = [];
        var bgColor = [];
        var labels = [];
        var chartResult = chartData;
        var chartKey = Object.keys(chartResult);
        var totalRec = 0;
        console.log(chartKey);
        for(var i in chartKey){
            labels.push(chartKey[i]);
            
            for(var j in chartResult[chartKey[i]]){
                totalRec = totalRec + parseInt(chartResult[chartKey[i]][j].clus);
            }
        }
        var j = 0;
        for(var i in chartKey){
            var total = 0;
            for(var k in chartResult[chartKey[i]]){
                console.log('clus',chartResult[chartKey[i]][k].clus);
                total = total + parseInt(chartResult[chartKey[i]][k].clus);
            }
            var percen = (total*100)/totalRec;
            data.push(Math.ceil(percen));
            if(color.length < j+1){
                j = 0;
            }
            bgColor.push(color[j]);
            j++;
        }
        console.log(data);
        var chartdata = {
            labels: labels,
            datasets: [
                {
                    data: data,
                    backgroundColor: bgColor,
                    fill: false,
                    borderColor : bgColor,
                    
                }
            ]
        }
        //Get the context of the canvas element we want to select
        var ctx = component.find(chartName).getElement();
        var lineChart = new Chart(ctx ,{
            type: chartType,
            data: chartdata,
            options: {
                onClick:function(event, legendItem){
                    /*var activeBars = lineChart.getElementAtEvent(event); 
                    console.log(chartType+'-----'+activeBars[0]._model.label);
                    console.log(chartResult[activeBars[0]._model.label]);
                    document.getElementById("childContainer").innerHTML = "";
                    document.getElementById("childContainer").innerHTML = '<canvas id="childChart"  style="width:1088px;"></canvas>';
                    helper.fillchildChart(component,helper,chartResult[activeBars[0]._model.label],"childChart",chartType);
                    */
                },
                legend: {
                    position: 'bottom',
                    padding: 10,
                },
                responsive: true,
                tooltips: {
                    callbacks: {
                        label: function (tooltipItem, data) {
                            return data.labels[tooltipItem.index] + ' (' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + '%)';
                        }
                    }
                }
            }
        });
	},
    fillchildChart : function(component,helper,chartData,chartName,chartType) {
        
        //console.log('########',cov.showChart);
        
        var color=["#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#1abc9c","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#ecf0f1"];
        var colors=new Array();
        for (var i = 0; i < color.length; i++) {
            colors.push(color[i]);
        }
        var data = [];
        var bgColor = [];
        var labels = [];
        var chartResult = chartData;
        var j = 0;
        var totalRec = 0;
        for(var i in chartResult){
            totalRec = totalRec +chartResult[i].clus;
        }
        for(var i in chartResult){
            labels.push(chartResult[i].version);
           
            var total = chartResult[i].clus;
            var percen = (total*100)/totalRec;
            data.push(percen.toFixed(2));
           // data.push(chartResult[i].clus);
            if(color.length <  j+1){
                j = 0;
            }
            bgColor.push(color[j]);
            j++;
        }
        
        var chartdata = {
            labels: labels,
            datasets: [
                {
                    data: data,
                    backgroundColor: bgColor,
                    fill: false,
                    borderColor : bgColor
                    
                }
            ]
        }
        //Get the context of the canvas element we want to select
        var ctx = document.getElementById(chartName);
        var lineChart = new Chart(ctx ,{
            type: chartType,
            data: chartdata,
            options: {
                legend: {
                    position: 'bottom',
                    padding: 10,
                    display: false
                },
                responsive: true,
                tooltips: {
                    callbacks: {
                        label: function (tooltipItem, data) {
                            return data.labels[tooltipItem.index] + ' (' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + '%)';
                        }
                    }
                }
            }
        });
        component.set("v.showChart",true);
        component.set("v.chartType",chartType);
        
	},
    
    fillMyChart : function(component,helper,chartData,chartName,chartType) {
        var color=["#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#1abc9c","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#ecf0f1"];
        var colors=new Array();
        for (var i = 0; i < color.length; i++) {
            colors.push(color[i]);
        }
        var data = [];
        var bgColor = [];
        var labels = [];
        var chartResult = chartData;
        var chartKey = Object.keys(chartResult);
        var totalRec = 0;
        console.log(chartKey);
        for(var i in chartKey){
            labels.push(chartKey[i]);
            console.log(chartKey[i]);
            console.log(chartResult[chartKey[i]]);
            totalRec = totalRec + parseInt(chartResult[chartKey[i]][0].clus);
        }
        var j = 0;
        for(var i in chartKey){
            var total = chartResult[chartKey[i]][0].clus;
            var percen = (total*100)/totalRec;
            data.push(Math.ceil(percen));
            if(color.length < j){
                j = 0;
            }
            bgColor.push(color[j]);
            j++;
        }
        console.log(data);
        var chartdata = {
            labels: labels,
            datasets: [
                {
                    data: data,
                    backgroundColor: bgColor,
                    fill: false,
                    borderColor : bgColor,
                    
                }
            ]
        }
        //Get the context of the canvas element we want to select
        var ctx = component.find(chartName).getElement();
        var lineChart = new Chart(ctx ,{
            type: chartType,
            data: chartdata,
            options: {
                onClick:function(event, legendItem){
                    var activeBars = lineChart.getElementAtEvent(event); 
                    console.log(chartType+'-----'+activeBars[0]._model.label);
                    console.log(chartResult[activeBars[0]._model.label]);
                    document.getElementById("childContainer").innerHTML = "";
                    document.getElementById("childContainer").innerHTML = '<canvas id="childChart" style="width:1088px;"></canvas>';
                    helper.fillchildChart(component,helper,chartResult[activeBars[0]._model.label],"childChart",chartType);
                    
                },
                legend: {
                    position: 'bottom',
                    padding: 10,
                },
                responsive: true,
                tooltips: {
                    callbacks: {
                        label: function (tooltipItem, data) {
                            return data.labels[tooltipItem.index] + ' (' + data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index] + '%)';
                        }
                    }
                }
            }
        });
	}
})