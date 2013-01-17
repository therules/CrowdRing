newKeyOption = ->
  id = $('.ivr-key-option-template').length
  newDiv = $('#original-ivr-key-option-template-container div:first-child').clone()
  $('input[name="KEY"]', newDiv).attr('name', "ivr[key_options][#{id}][press]")
  $('input[name="OPTION"]', newDiv).attr('name', "ivr[key_options][#{id}][for]")
  $('#key-options').append(newDiv)

  $('#remove-key-option', newDiv).click ->
      removeKeyOption($(this))
removeKeyOption = (btn) ->
    btn.parent().remove()
$ ->
  window.addKeyOption = -> newKeyOption()
  window.removeKeyOption = (btn) -> removeKeyOption(btn)
