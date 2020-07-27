import net
import strutils

proc fakReadLine(socket: Socket): string =
  var fakString = socket.recv(1)
  while "\r\n" in fakString == false:
    fakString.add(socket.recv(1))
  fakstring

var socket = newSocket()
socket.connect("localhost", Port(7419))
echo socket.fakReadLine()
socket.close()