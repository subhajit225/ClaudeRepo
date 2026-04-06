document.addEventListener('DOMContentLoaded', function () {
var url = window.location.href;
var tabUrl = "https://rubrikinc--parsandbox.cs1.my.salesforce.com/006/o";
if(url.indexOf(tabUrl) !== -1){
    var x = document.getElementsByName("new");
    var i;
    var newBtn;
    for (i = 0; i < x.length; i++) {
        if (x[i].type == "button") {
            newBtn = x[i];
        }
    }
    console.log('bingo');
    newBtn.style.display = 'none';
}});
/*
<script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.0/jquery.min.js"></script>
<script>$j = jQuery.noConflict();$j(document).ready(function hideButton(){
  var url = window.location.href;var tabUrl = "https://cs13.salesforce.com/006/o";if(url.indexOf(tabUrl) !== -1){var newBtn = $j('[name="new"]');newBtn.css({"white-space":"normal","display":"none"});}});
</script>*/
