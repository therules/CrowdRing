new_supporter = (data) ->
  $("#supporters .count").text(data.count + " Supporter" + (if data.count != 1 then "s" else ""))
                         .effect("highlight", {color: '#63DB00'}, 500)
  $("<li>#{data.number}</li>").hide()
                              .appendTo("ul.supporters")
                              .slideDown('fast', -> $(this).css("display", "list-item"))

$ ->
  $("select.number").change (evt) ->
    if $(this).val() != ""
      $.get("/campaign/#{$(this).val()}",
        (data) ->
          $("#campaign").hide()
                        .html(data)
                        .slideDown(200)
      )  

      pusher = new Pusher('7d1fec0e2c3c41c94f4b')
      channel = pusher.subscribe($(this).val().replace('+',''))
      channel.bind 'new', new_supporter


