import net
import strutils

proc readLine(socket: Socket): string =
  var inString = socket.recv(1)
  while "\r\n" in inString == false:
    inString.add(socket.recv(1))
  inString

var socket = newSocket()
socket.connect("localhost", Port(7419))
echo socket.readLine()
socket.close()