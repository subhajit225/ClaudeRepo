({
    afterScriptsLoaded : function(component, event, helper) {
        if(component.get("v.chartName") != 'gauage'){
            var color=["#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#ecf0f1","#1abc9c","#2ecc71","#3498db","#9b59b6","#34495e","#f1c40f","#e67e22","#e74c3c","#ecf0f1"];
            
            var colors=new Array();
            
            
            for (var i = 0; i < color.length; i++) {
                colors.push(color[i]);
            }
            var data = [];
            var bgColor = [];
            var labels = [];
            var chartResult = component.get("v.ChartData");
           
            
            if(component.get("v.chartName") == 'doughnut'){
                for (var key in chartResult) {
                    data.push(chartResult[key]);  
                }
                bgColor.push("#D7C575");
                bgColor.push("#67CC33");
                bgColor.push("#FFB40E");
                bgColor.push("#e74c3c");
                
                
                for (var key in data) {
                    labels.push(data[key]+'%');  
                }
                
            }else{
                data.push(chartResult);
                labels.push(chartResult+'%');
                var unhappy = (100 - chartResult).toFixed(1);
                data.push(unhappy);
                labels.push(unhappy+'%');
                bgColor.push("#2ecc71");
                bgColor.push("#e74c3c");
            }
            
            var chartdata = {
                labels: labels,
                datasets: [
                    {
                        label:'Rating',
                        data: data,
                        backgroundColor: bgColor,
                        fill: false
                        
                    }
                ]
            }
            //Get the context of the canvas element we want to select
            var ctx = component.find("linechart").getElement();
            var lineChart = new Chart(ctx ,{
                type: component.get("v.chartName"),
                data: chartdata,
                options: {	
                    legend: {
                        position: 'bottom',
                        padding: 10,
                    },
                    responsive: true
                }
            });
        }else{
            var chartResult = component.get("v.ChartData");
            console.log(chartResult);
            console.log(component.get("v.ChartData"));
            var opts = {
                currval : chartResult,
                angle: 0, // The span of the gauge arc
                lineWidth: 0.44, // The line thickness
                radiusScale: 1, // Relative radius
                pointer: {
                    length: 0.6, // // Relative to gauge radius
                    strokeWidth: 0.035, // The thickness
                    color: '#000000' // Fill color
                },
                fontSize : 33,
                limitMax: false,     // If false, max value increases automatically if value > maxValue
                limitMin: false,     // If true, the min value of the gauge will be fixed
                // to see which ones work best for you
                generateGradient: true,
                highDpiSupport: true,  
                staticZones: [
                    {strokeStyle: "#D7C575", min: 75, max: 100}, // Red from 100 to 130
                    {strokeStyle: "#67CC33", min: 50, max: 75}, // Yellow
                    {strokeStyle: "#FFB40E", min: 25, max: 50}, // Green
                    {strokeStyle: "#e74c3c", min: 0, max: 25}, // Yellow
                ]// High resolution support
                    
                    };
                    var target = document.getElementById('gauageChart');// your canvas element
                    var gauge = new Gauge(target).setOptions(opts); // create sexy gauge!
                    gauge.maxValue = 100; // set max gauge value
                    gauge.setMinValue(0);  // Prefer setter over gauge.minValue = 0
                    gauge.animationSpeed = 32; // set animation speed (32 is default value)
                    gauge.set(chartResult); // set actual value
                    document.getElementById('res').innerHTML = chartResult+"%";
        }
        
	}
})