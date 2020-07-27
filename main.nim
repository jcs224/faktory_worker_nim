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
socket.connect("localhost", Port(7421))
# Get initial connection response
let response = socket.readLine()
let responseJSONString = response[response.find("{") .. response.rfind("}")]
echo responseJSONString

# Parse JSON response
let responseJSON = parseJson(responseJSONString)

# Submit password if needed
echo responseJSON["s"].getStr()
echo responseJSON["i"].getInt()
let iter = responseJSON["i"].getInt()
let seed = responseJSON["s"].getStr()
var data = "password" & seed

# for i in 0 ..< iter:
  # something here
  
let finalHex = "12345"
echo finalHex

let echoString = "HELLO {\"v\":2,\"pwdhash\":\"" & finalHex & "\"}\r\n"
echo echoString
echo socket.writeLine(echoString)

socket.close()