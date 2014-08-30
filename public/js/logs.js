var servers = [];
var apiUrl = "/api/";

function element(tag, value, attr) {
	var e = document.createElement(tag);
	if (value) {
	    e.appendChild(document.createTextNode(value));
		// e.innerHTML = value;
	}
	if (typeof(attr) == "function") {
		attr(e);
	} else if (typeof(attr) == "object") {
		for (var key in attr) {
			e[key] = attr[key];
		}
	}
	return e;
}

window.addEventListener('load',(function(e){

	getJson(apiUrl + "logs",function(result) {
		if (result.status=='ok') {
			var e = document.getElementById('logs');
			e.innerHTML = "";
			for (var i = 0; i < result.logs.length; i++) {
			    var log = result.logs[i];
			    var li = document.createElement
			    document.createTextNode(log.message);
                e.appendChild(element("li", log.time + " " + log.message));
			}
		}
	});

}),false);

