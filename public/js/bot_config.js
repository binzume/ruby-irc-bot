var servers = [];
var apiUrl = "/api/";
var token = "";


function load_schedules() {
	var ul = document.getElementById('cron_list');
	getJson(apiUrl + "schedules",function(result) {
		if (result.status=='ok') {
			ul.innerHTML = "";
			for (var i = 0; i < result.schedules.length; i++) {
				var sch = result.schedules[i];
				var delete_button = element('button', 'X');
				var li = element('li', [sch.year + " - " + sch.month + " - " + sch.day + " " + sch.hour + " : " + sch.min + " => " + sch.message, delete_button]);
				ul.appendChild(li);
				(function(item){
					delete_button.addEventListener('click', (function(e){
						var xhr = getxhr();
						xhr.open('DELETE', apiUrl + "schedules/" + item.id);
						xhr.setRequestHeader("X-CSRFToken", token);
						xhr.onreadystatechange = function() {
							if (xhr.readyState != 4) return;
							alert(xhr.responseText);
						};
						xhr.send();
					}),false);
				})(sch);
			}
		}
	});
}

function load_keywords() {
	var ul = document.getElementById('keywords');
	getJson(apiUrl + "keywords",function(result) {
		if (result.status=='ok') {
			ul.innerHTML = "";
			for (var i = 0; i < result.keywords.length; i++) {
				var item = result.keywords[i];
				var delete_button = element('button', 'X');
				var li = element('li', ["" + item.word + " => " + item.message, delete_button]);
				ul.appendChild(li);
				(function(item){
					delete_button.addEventListener('click', (function(e){
						var xhr = getxhr();
						xhr.open('DELETE', apiUrl + "keywords/" + item.id);
						xhr.setRequestHeader("X-CSRFToken", token);
						xhr.onreadystatechange = function() {
							if (xhr.readyState != 4) return;
							alert(xhr.responseText);
						};
						xhr.send();
					}),false);
				})(item);
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
		        var xhr = getxhr();
		        xhr.open('POST', apiUrl + "keywords/-create");
		        xhr.send(new FormData(document.getElementById('add_keyword')));
		        console.log(data);
		}).show();
	}),false);

	load_schedules();
	load_keywords();


}),false);
