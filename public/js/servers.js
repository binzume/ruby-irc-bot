var servers = [];
var apiUrl = "/api/";


function displayServer(id) {
    var s = servers[id];
    document.getElementById('status').innerText = s.connected ? "CONNECTED" : "CLOSED";
    document.getElementById('irc_id').innerText = s.id;
    document.getElementById('irc_use_ssl').checked = s.use_ssl;
    document.getElementById('irc_server').value = s.server;
    document.getElementById('irc_nick').value = s.nick;
    document.getElementById('irc_name').value = s.name;
    document.getElementById('irc_user').value = s.user;
    document.getElementById('irc_pass').value = s.pass || "";
}

function getData() {
    return new FormData(document.getElementById('irc_server_form'));
}

window.addEventListener('load',(function(e){


    document.getElementById("delete_button").addEventListener('click',(function(e){
        var xhr = getxhr();
        xhr.open('DELETE', apiUrl + "servers/" + document.getElementById('irc_id').innerText);
        xhr.send();
	}),false);

    document.getElementById("create_button").addEventListener('click',(function(e){
        var data = getData();
        var xhr = getxhr();
        xhr.open('POST', apiUrl + "servers/-create");
        xhr.send(data);
	}),false);

    document.getElementById("update_button").addEventListener('click',(function(e){
        var data = getData();
        console.log(data);
        var xhr = getxhr();
        xhr.open('POST', apiUrl + "servers/" + document.getElementById('irc_id').innerText);
        xhr.send(data);
	}),false);

    document.getElementById("disconnect_button").addEventListener('click',(function(e){
        var xhr = getxhr();
        xhr.open('POST', apiUrl + "servers/" + document.getElementById('irc_id').innerText + "/-disconnect");
        xhr.send();
	}),false);

    document.getElementById("connect_button").addEventListener('click',(function(e){
        var xhr = getxhr();
        xhr.open('POST', apiUrl + "servers/" + document.getElementById('irc_id').innerText + "/-connect");
        xhr.send();
	}),false);

    document.getElementById("servers").addEventListener('change',(function(e){
        displayServer(e.target.value);
	}),false);

	getJson(apiUrl + "servers",function(result) {
		if (result.status=='ok') {
			servers = [];
			var html = '';
			for (var i = 0; i < result.servers.length; i++) {
			    var s = result.servers[i];
				servers[s.id] = s;
				html += "<option value='" + s.id +"'>" + s.nick + " (" + s.server + ")</option>";
			}
			document.getElementById('servers').innerHTML = html;
			if (result.servers.length > 0) {
    			displayServer(result.servers[0].id);
    		}
		}
	});

}),false);
