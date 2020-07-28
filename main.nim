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

var socket = newSocket()
socket.connect("localhost", Port(7419))
# Get initial connection response
let response = socket.readLine()
let responseJSONString = response[response.find("{") .. response.rfind("}")]

# Parse JSON response
let responseJSON = parseJson(responseJSONString)

# Submit password if needed

var outJSON = %* {"v":2}

if isNil(responseJSON{"i"}) == false and isNil(responseJSON{"s"}) == false:
  let iter = responseJSON["i"].getInt()
  let seed = responseJSON["s"].getStr()
  var initAuthData = "password" & seed
  var authData = computeSHA256(initAuthData)

  for i in 1 ..< iter:
    authData = computeSHA256($authData)

  let finalHex = toLowerAscii(authData.toHex())
  outJSON["pwdhash"] = %finalHex

let echoString = "HELLO " & $outJSON & "\r\n"
echo socket.writeLine(echoString)

socket.close()