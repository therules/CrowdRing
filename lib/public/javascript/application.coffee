new_supporter = (data) ->
  $("#campaign-supporters .count").text(data.supporter_count + " Supporter" + (if data.supporter_count != 1 then "s" else ""))
                         .effect("highlight", {color: '#63DB00'}, 500)
  $(".all-label .ui-button-text").text('All ' + data.supporter_count)
  $(".new-label .ui-button-text").text(data.new_supporter_count + ' New')
  
  delete_last = -> 
    if $('#supporters-numbers li').length > 10
      $('#supporters-numbers li').last().remove()
  
  $("<li>#{data.number}</li>").hide()
                              .css('opacity', 0.0)
                              .prependTo("ul.supporters")
                              .slideDown(250)
                              .animate({opacity: 1.0}, 250, delete_last)



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
        character_limit = 160
        $("#campaign").hide()
                      .html(data)
                      .slideDown(200)
        $('#broadcast-text-area').bind('input', -> 
          if $.trim($(this).val()) == "" || $(this).val().length > character_limit
            $('#broadcastbutton').attr('disabled', 'disabled')
          else
            $('#broadcastbutton').removeAttr('disabled'))
        $('#broadcast-text-area').charCount({
          allowed: character_limit,
          warning: 20,
        })
        $('#receivers1').buttonset()
        $('#receivers2').buttonset()
    ).error(-> window.location.replace '/')

    channel_name = campaign.replace('+','')
    channel = pusher.subscribe(channel_name)
    channel.bind 'new', new_supporter
  window.onhashchange = -> loadCampaign(pusher, document.location.hash[1..-1], channel_name)


$ ->
  $('select').chosen()
  setTimeout((->$('.notice').slideUp('medium')), 3000)

  pusher = new Pusher(window.pusher_key)
  $("#campaign").empty()
  window.onhashchange = -> loadCampaign(pusher, document.location.hash[1..-1], null)
  window.onhashchange()
  $("select.campaign-select").change (evt) ->
    document.location.hash = $(this).val()



