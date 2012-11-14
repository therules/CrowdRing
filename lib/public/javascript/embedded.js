var new_ringer = function(data) { 
  $('#progress-inner').css('width', (5 + (data.ringer_count / data.goal) * 100) + "%")
  $('#progress-inner .count').html(data.ringer_count)
}

$(document).ready(function() {
  var pusher = new Pusher(window.pusher_key)
  var channel = pusher.subscribe(window.campaign_id)
  channel.bind('new', new_ringer)
})
