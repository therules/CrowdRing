newKeyOption = ->
  id = $('.ivr-key-option-template').length
  newDiv = $('#original-ivr-key-option-template-container div:first-child').clone()
  $('input[name="KEY"]', newDiv).attr('name', "ivr[keyoption][#{id}][key]")
  $('input[name="OPTION"]', newDiv).attr('name', "ivr[keyoption][#{id}][option]")
  $('#key-options').append(newDiv)

  $('#remove-key-option', newDiv).click ->
      removeKeyOption($(this))
removeKeyOption = (btn) ->
    btn.parent().remove()
$ ->
  window.addKeyOption = -> newKeyOption()
  window.removeKeyOption = (btn) -> removeKeyOption(btn)
