new_ringer = (data) ->
  $("#campaign-ringers .total_count").text(
    data.ring_count + " Total Ring" + (if data.ring_count != 1 then "s" else ""))
  $("#campaign-ringers .unique_count").text(
    data.ringer_count + " Unique Ringer" + (if data.ringer_count != 1 then "s" else ""))
  $("#campaign-ringers .counts").effect("highlight", {color: '#63DB00'}, 500)
  $(".all-label .ui-button-text").text('All ' + data.ringer_count)
  $(".new-label .ui-button-text").text(data.new_ringer_count + ' New')
  
  delete_last = -> 
    if $('#ringers-numbers li').length > 10
      $('#ringers-numbers li').last().remove()
  
  $("<li>#{data.number}</li>").hide()
                              .css('opacity', 0.0)
                              .prependTo("ul.ringers")
                              .slideDown(250)
                              .animate({opacity: 1.0}, 250, delete_last)


setupBroadcastTextArea = ->
  character_limit = 160
  $('#broadcast-text-area').bind('input', -> 
    if $.trim($(this).val()) == "" || $(this).val().length > character_limit
      $('#broadcastbutton').attr('disabled', 'disabled')
    else
      $('#broadcastbutton').removeAttr('disabled'))
  $('#broadcast-text-area').charCount({
    allowed: character_limit,
    warning: 20,
  })
setupTabs = ->
  $( "#tabs" ).tabs()

setupFilters = (buttons) ->
  $(buttons).buttonset()
  $("#{buttons} :radio").change ->
    context = $(buttons).parent().parent()
    $("#filter-options", context).slideUp()
    clicked = $(this)
    id = $(this).attr('id')
    id = id.substr(0, id.length-1)
    if $("##{id}-options").length == 1
      $("#filter-options", context).html($("##{id}-options").html()).slideDown()

      $("#filter-options :checkbox", context).change(->
        str = 'country:' + $("#filter-options :checked", context).map((_, c) -> c.value).toArray().join('|')
        clicked.val(str)
      )

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
        setupBroadcastTextArea()
        setupFilters('#broadcast-filter')
        setupFilters('#export-filter')
        setupTabs()
    ).error(-> window.location.replace '/')

    channel_name = campaign
    channel = pusher.subscribe(channel_name)
    channel.bind 'new', new_ringer
  window.onhashchange = -> loadCampaign(pusher, document.location.hash[1..], channel_name)


tagFor = (tagname, id) ->
  $("<div>#{tagname} <input type='hidden' name='campaign[introductory_response][filtered_messages][#{id}]tags[]' value='#{tagname}' /> <button type='button'>Remove</button></div>")

removeFilter = (btn) ->
  btn.parent().remove()

removeTag = (btn) ->
  btn.parent().remove()

addTag = (parent, item, id) ->
  fullTagName = item.label
  newTag = tagFor(fullTagName, id)
  $('button', newTag).click ->
    removeTag($(this))
  newTag.appendTo($('#tag-filters', parent))
  $('.tag-name', parent).val('')

newFilterMessage = ->
  id = $('.filtered-message-template').length
  newDiv = $('#original-filtered-message-template-container div:first-child').clone()
  $('textarea[name="MESSAGE"]', newDiv).attr('name', "campaign[introductory_response][filtered_messages][#{id}][message]")
  $('#filtered-messages').append(newDiv)

  $('#add-tag-button', newDiv).click ->
    addTag(newDiv, id)
    
  $('.tag-name', newDiv).keypress (evt) ->
    if evt.which == 13
      $('#add-tag-button', newDiv).click()
      return false
  $('#remove-filter-button', newDiv).click ->
    removeFilter($(this))

  $.getJSON('/tags/tags.json', (data) ->
    $('.tag-name', newDiv).catcomplete({
      delay: 0, 
      source: data,
      autoFocus: true,
      minLength: 0,
      select: (evt, ui) ->
        addTag($(this).parent(), ui.item, id)
        return false
    }))


$ ->
  $('select.campaign-select').chosen()
  setTimeout((->$('.notice').slideUp('medium')), 3000)

  pusher = new Pusher(window.pusher_key)
  $("#campaign").empty()
  window.onhashchange = -> loadCampaign(pusher, document.location.hash[1..], null)
  window.onhashchange()
  $("select.campaign-select").change (evt) ->
    document.location.hash = $(this).val()
  
  
  $.getJSON('/tags/tags.json', (data) ->
    $('.tag-name').catcomplete({
      delay: 0, 
      source: data,
      autoFocus: true,
      minLength: 0,
      select: (evt, ui) ->
        addTag($(this).parent(), ui.item, $(this).parent().index())
        return false
    }))

  window.removeTag = (btn) -> removeTag(btn)
  window.addTag = (div, id) -> addTag(div, id)
  window.removeFilter = (btn) -> removeFilter(btn)
  window.addFilter = -> newFilterMessage()




