wire = require './wire'

module.exports = (wit) ->
  wit.on 'wire_send', ({entities}) ->
    console.log "SENDING A MESSAGE", entities

    channel = if entities.channel then wire[entities.channel] else wire.fallback

    channel entities.contact[0].value, body: entities.message_body[0].value

