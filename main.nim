import net
import strutils
import json

import nimSHA2
import uuids

proc readLine(socket: Socket): string =
  var inString = socket.recv(1)
  while "\r\n" in inString == false:
    inString.add(socket.recv(1))
  result = inString

proc writeLine(socket: Socket, stringPayload: string): string =
  socket.send(stringPayload)
  socket.readLine()

type
  FaktoryClient = object
    host: string
    port: int
    password: string

proc connect(client: FaktoryClient): Socket =
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

proc push(client: FaktoryClient, id = $genUUID(), jobType: string, args: seq[string]) =
  let socket = client.connect()

  var argsJSON = %* []

  for item in args.pairs:
    let intEndIndex = item.val.rfind("|int")
    if intEndIndex > -1:
      argsJSON.add(%* parseInt(item.val.substr(0, intEndIndex - 1)))
    else:
      argsJSON.add(%* item.val)

  let outJSON = %* {"jid":id,"jobtype":jobType,"args":argsJSON}
  echo $outJSON
  let command = "PUSH " & $outJSON & "\r\n"
  discard socket.writeLine(command)

  socket.close()

# Run the code
var client = FaktoryClient(host: "localhost", port: 7419, password: "")
client.push(jobType = "nimjob", args = @["seq1", "12314|int"])