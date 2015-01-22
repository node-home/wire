# First up:
#
# Browser
# Twilio

# A user configures wire channels and sets status on them

io         = require 'socket.io'
redis      = require 'then-redis'
Q          = require 'q'
express    = require 'express'
twilio     = require 'twilio'
http       = require 'http'
bodyParser = require 'body-parser'
cors       = require 'cors'

app     = express()
server  = http.createServer app
io      = io server

app.use bodyParser.json()
app.use cors()

port    = process.env.PORT ? 1337

TWILIO =
  SID: process.env.TWILIO_SID
  TOKEN: process.env.TWILIO_TOKEN

class ChannelInterface
  # Return a
  register: (id, options) ->

  # A promise that rejects early if message can or may not be sent
  send: (id, message) ->

class Browser
  @connections: {}

  @register: (id) =>
    @connections[id] =
      config: null
      socket: null

  @connect: (id, socket) =>
    console.log "Browser.connect", id
    @connections[id] ?= {}
    @connections[id].socket = socket

  @disconnect: (id) =>
    console.log "Browser.disconnect", id
    return unless @connections[id]
    @connections[id].socket = null

  @configure: (id, config) =>
    console.log "Browser.config", id
    @connections[id] ?= {}
    @connections[id].config = config

  @send: (id, message) =>
    console.log "Browser.send", id, message
    console.log @connections
    socket = @connections[id]?.socket

    return Q.reject 'not connected' unless socket

    socket.emit 'message', message

    Q()

# Manage browser connections
io.of '/wire'
  .on 'connection', (socket) ->
    console.log "CONNECTION"
    socket.on 'auth', ({token}) ->
      console.log 'auth with', token

      user = User.findByToken(token)

      user
        .then (user) ->
          Browser.connect user.id, socket
        .fail (e) ->
          console.log "MISCONNECT", e
          socket.emit 'misconnect'

      socket.on 'config', (config) ->
        console.log "CONFIG"
        user.then (id) ->
          Browser.config id, config

      socket.on 'disconnect', ->
        console.log "DISCONNECT"
        user.then (user) ->
          Browser.disconnect user.id



class Phone
  @twilio = twilio TWILIO.SID, TWILIO.TOKEN

  @send = (id, message) ->
    dfd = Q.defer()

    params =
      to: id
      from: '+442033223509'
      body: message.body

    console.log "SENDING TWILIO", params

    @twilio.sendMessage params, (err, responseData) ->
      console.log "TWILIO", err, responseData
      return dfd.reject err if err
      dfd.resolve responseData

    return dfd.promise

    Q.nfcall @client.sendMessage,
      to: id
      from: '+44203322350'
      body: message.body

class Log
  @send = (id, message) ->
    console.log "[INFO] Log.send(", id, ",", message, ")"
    Q.reject()


class User
  @findByToken: (token) ->
    Q id: token

channelClasses =
  browser: Browser
  phone: Phone
  log: Log

wires =
  jesse: [
    {channel: 'log', uid: 'jesse'}
    {channel: 'browser', uid: 'jesse'}
    # {channel: 'phone', uid: '+447806606306'}
  ]

  josh: [
    {channel: 'log', uid: 'josh'}
    {channel: 'browser', uid: 'josh'}
    {channel: 'phone', uid: '+447783360556'}
  ]

class Fallback
  # Try all given until one succeeds
  @send: (id, message) ->
    dfd = Q.defer()

    do recurse = (index=0) ->
      wire = wires[id]?[index]

      return dfd.reject "All failed" unless wire

      {channel, uid} = wire

      console.log "send to #{uid} over #{channel}"

      channelClasses[channel]
        .send uid, message
        .then (data) ->
          dfd.resolve {channel, data}
        .fail ->
          recurse (index + 1)

    dfd.promise


server.listen port, ->
  console.log "Wired up on #{port}"


app.post '/wire/users/:id', (req, res) ->
  Fallback.send req.params.id, req.body
    .then ({channel, data}) ->
      res.json success: true, channel: channel, data: data
    .fail (reason) ->
      res.status(400).json error: "Could not send", reason: reason

