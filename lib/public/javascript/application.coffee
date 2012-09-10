$ ->
  $("select.number").change (evt) ->
    $("#campaign").empty()
    if $(this).val() != ""
      $.get("/campaign/#{$(this).val()}",
        (data) ->
          $("#campaign").hide()
          $("#campaign").append(data)
          $("#campaign").slideToggle(200)
      )  
      pusher = new Pusher('7d1fec0e2c3c41c94f4b')
      channel = pusher.subscribe($(this).val().replace('+',''))
      channel.bind 'new', (data) -> 
        $("#supporters .message").empty()
        $("<li>#{data.number}</li>").hide().appendTo("ul.supporters").slideDown()


