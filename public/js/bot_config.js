var servers = [];
var apiUrl = "/api/";


function load_schedules() {
	var ul = document.getElementById('cron_list');
	getJson(apiUrl + "schedules",function(result) {
		if (result.status=='ok') {
			ul.innerHTML = "";
			for (var i = 0; i < result.schedules.length; i++) {
				var sch = result.schedules[i];
				var li = element('li', "" + sch.message);
				ul.appendChild(li);
			}
		}
	});

}

window.addEventListener('load',(function(e){

	// schedule
	document.getElementById('add_schedule_button').addEventListener('click',(function(e){
		document.getElementById('add_schedule').reset();
		new Dialog(document.getElementById('add_schedule_dialog')).
			onClick('add_schedule_dialog_add',function(){
		        var xhr = getxhr();
		        xhr.open('POST', apiUrl + "schedules/-create");
		        xhr.send(new FormData(document.getElementById('add_schedule')));
		        console.log(data);
		}).show();
	}),false);


	// keyword
	document.getElementById('add_keyword_button').addEventListener('click',(function(e){
		document.getElementById('add_keyword').reset();
		new Dialog(document.getElementById('add_keyword_dialog')).
			onClick('add_keyword_dialog_add',function(){
				alert(document.getElementById('add_keyword').word.value);
		}).show();
	}),false);

	load_schedules();


}),false);
