new_supporter = (data) ->
  $("#supporters .count").text(data.count + " Supporter" + (if data.count != 1 then "s" else ""))
                         .effect("highlight", {color: '#63DB00'}, 500)
  $("<li>#{data.number}</li>").hide()
                              .appendTo("ul.supporters")
                              .slideDown('fast', -> $(this).css("display", "list-item"))

loadCampaign = (campaign) ->
  $("#campaign").empty()
  $("select.number").val(campaign)
  if campaign != ""
    $.get("/campaign/#{campaign}",
      (data) ->
        $("#campaign").hide()
                      .html(data)
                      .slideDown(200)
    )  
    pusher = new Pusher('7d1fec0e2c3c41c94f4b')
    channel = pusher.subscribe(campaign.replace('+',''))
    channel.bind 'new', new_supporter

$ ->
  $("#campaign").empty()
  window.onhashchange = -> loadCampaign(document.location.hash[1..-1])
  if document.location.hash != ""
    loadCampaign(document.location.hash[1..-1])
  $("select.number").change (evt) ->
    document.location.hash = $(this).val()

