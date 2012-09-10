$(document).ready(function(){
  function debug(str){ $("#debug").append("<p>"+str+"</p>"); };

  ws = new WebSocket("ws:0.0.0.0:8080");
  ws.onmessage = function(evt) { $("#subscribers").append("<li>"+evt.data+"</li>"); };
  ws.onopen = function() {
    ws.send("+18143894106");
  };
});
