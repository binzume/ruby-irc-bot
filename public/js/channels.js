var apiUrl = "/api/";


function displayServer(id) {
    var s = servers[id];
    document.getElementById('irc_id').innerText = s.id;
    document.getElementById('irc_server').value = s.server;
    document.getElementById('irc_nick').value = s.nick;
    document.getElementById('irc_name').value = s.name;
    document.getElementById('irc_user').value = s.user;
    document.getElementById('irc_pass').value = s.pass || "";
}

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
