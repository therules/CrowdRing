removeOutsideCountry = (country, select) ->
  numRemoved = 0
  $(select).children().each (index) ->
    actualIndex = index - 1 - numRemoved
    if index != 0 && window.numbers[actualIndex].country != country
      console.log window.numbers[actualIndex]
      window.numbers.splice(actualIndex, 1)
      $(this).remove()
      numRemoved += 1

$ ->
  $('select.region-select').change (evt) ->
    index = $('option:selected', this).index() - 1
    region = window.numbers[index]
    $('#selected-regions').append("#{$(this).val()}<br>")
    $('#selected-regions').append("<input type='hidden' name='campaign[regions][]' value='#{region.country}|#{region.region || ''}' />")
    region.count -= 1
    if region.count == 0
      window.numbers.splice(index, 1)
      $('option:selected', this).remove()
    removeOutsideCountry(region.country, this)
    $('option:first', this).html('Need another number?')
    $(this).val('')

