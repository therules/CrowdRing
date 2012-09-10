$ ->
  $("select.number").change (evt) ->
    $("ul.subscribers").empty()
    if $(this).val() != ""
      $.getJSON(
          "http://localhost:5000/subscribers/#{$(this).val()}",
          (data) -> 
            items = []
            $.each(data, (key, val) -> items.push("<li>#{val}</li>"))
            $("ul.subscribers").append(items.join(''))
      )

      pusher = new Pusher('f7c247ce97e5bc97930c')
      channel = pusher.subscribe($(this).val().replace('+',''))
      channel.bind 'new', (data) -> $("ul.subscribers").append("<li>#{data.number}</li>")


