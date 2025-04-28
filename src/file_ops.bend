def cmd(command: String):
  with IO:
    file_ops <- IO/DyLib/open("./file_ops.so", 0)
    retbits <- IO/DyLib/call(file_ops, "cmd", command)
    retmsg = String/decode_utf8(retbits)

# maybe parse the return message afterward but im not doing anything with that yet (TODO)

    * <- IO/DyLib/close(file_ops)
    return retmsg

# open the lib for running bash commands from within bend
def open_bash() -> IO/Port:
  with IO:
    file_ops <- IO/DyLib/open("./file_ops.so", 0)
    return file_ops

# run bash commands once the lib is open
def bash(port: IO/Port, cmd: String) -> String:
  with IO:
    retbits <- IO/DyLib/call(port, "cmd", cmd)
    retmsg = String/decode_utf8(retbits)
    return retmsg

def close_bash(port: IO/Port):
  with IO:
    * <- IO/DyLib/close(port)
    return
