var apiUrl = "/api/";



window.addEventListener('load',(function(e){

	getJson(apiUrl + "channels",function(result) {
		if (result.status=='ok') {
			var html = '';
			for (var i = 0; i < result.channels.length; i++) {
			    var ch = result.channels[i];
				html += "<li>[" + ch.type + "] " + ch.name + (ch.connected?" (Connected)":"") + "</li>";
			}
			document.getElementById('channels').innerHTML = html;
		}
	});

}),false);
