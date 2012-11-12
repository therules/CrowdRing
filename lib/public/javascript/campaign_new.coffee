$ ->
  $('select.region-select').change (evt) ->
    index = $('option:selected', this).index() - 1
    region = window.numbers[index]
    console.log index
    console.log region
    $('#selected-regions').append("#{$(this).val()}<br>")
    $('#selected-regions').append("<input type='hidden' name='campaign[regions][]' value='#{region.country}|#{region.region || ''}' />")
    region.count -= 1
    if region.count == 0
      window.numbers.splice(index, 1)
      $('option:selected', this).remove()
    console.log window.numbers
    $(this).val('')

