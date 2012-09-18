new_supporter = (data) ->
  $("#supporters .count").text(data.count + " Supporter" + (if data.count != 1 then "s" else ""))
                         .effect("highlight", {color: '#63DB00'}, 500)
  $("<li>#{data.number}</li>").hide()
                              .appendTo("ul.supporters")
                              .slideDown('fast', -> $(this).css("display", "list-item"))


loadCampaign = (pusher, campaign, prev_channel) ->
  if prev_channel?
    pusher.unsubscribe(prev_channel)

  $("#campaign").empty()
  $("select.campaign-select").val(campaign)
  $("select").trigger("liszt:updated")

  channel_name = null
  if campaign != ""
    $.get("/campaign/#{campaign}",
      (data) ->
        $("#campaign").hide()
                      .html(data)
                      .slideDown(200)
    )  
    channel_name = campaign.replace('+','')
    channel = pusher.subscribe(channel_name)
    channel.bind 'new', new_supporter
  window.onhashchange = -> loadCampaign(pusher, document.location.hash[1..-1], channel_name)


$ ->
  $('select').chosen()
  setTimeout((->$('.notice').fadeOut('medium')), 3000)

  pusher = new Pusher(window.pusher_key)
  $("#campaign").empty()
  window.onhashchange = -> loadCampaign(pusher, document.location.hash[1..-1], null)
  window.onhashchange()
  $("select.campaign-select").change (evt) ->
    document.location.hash = $(this).val()

