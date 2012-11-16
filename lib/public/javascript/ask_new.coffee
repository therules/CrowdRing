$ ->
  $('select.ask-type').change (evt) ->
    $('#voice-prompt').remove()
    if $(this).val() == 'voicemail_ask'
      $('#selected-ask-type').append("<div id='voice-prompt'><h3>What should the ringer hear when they call?</h3>
        <textarea class='msg-text-area' name='prompt' 
          placeholder='Please leave a message of peace after the beep.'/></div>")