import net
import strutils
import json
import nimSHA2

proc readLine(socket: Socket): string =
  var inString = socket.recv(1)
  while "\r\n" in inString == false:
    inString.add(socket.recv(1))
  inString

proc writeLine(socket: Socket, stringPayload: string): string =
  socket.send(stringPayload)
  socket.readLine()

type
  FaktoryClient = object
    host: string
    port: int
    password: string

proc connect(client: var FaktoryClient): Socket =
  var socket = newSocket()
  socket.connect(client.host, Port(client.port))
  let response = socket.readLine()
  let responseJSONString = response[response.find("{") .. response.rfind("}")]

  # Parse JSON response
  let responseJSON = parseJson(responseJSONString)
  var outJSON = %* {"v":2}

  # Submit password if needed
  if not isNil(responseJSON{"i"}) and not isNil(responseJSON{"s"}):
    let iter = responseJSON["i"].getInt()
    let seed = responseJSON["s"].getStr()
    var initAuthData = client.password & seed
    var authData = computeSHA256(initAuthData)

    for i in 1 ..< iter:
      authData = computeSHA256($authData)

    let finalHex = toLowerAscii(authData.toHex())
    outJSON["pwdhash"] = %finalHex

  let echoString = "HELLO " & $outJSON & "\r\n"
  echo socket.writeLine(echoString)
  result = socket

var fakClient = FaktoryClient(host: "localhost", port: 7419, password: "")
let fakSocket = fakClient.connect()
fakSocket.close()