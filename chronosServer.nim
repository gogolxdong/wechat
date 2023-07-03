import chronos, chronos/apps/http/httpserver, chronos/apps/http/httpclient
import json


var session = HttpSessionRef.new({HttpClientFlag.Http11Pipeline}, maxRedirections = HttpMaxRedirections)
proc configureMsgReceive =
    var config = %*{"isEnable":"1","url":"http://localhost:9001"}
    var req = HttpClientRequestRef.new(session, url="http://localhost:30001/ConfigureMsgRecive", meth=MethodPost, body = toOpenArrayByte($config, 0, len($config) - 1))
    if req.isOk:
        var request = req.get()
        var response = waitFor request.send()
        if response.status == 200:
            var res = waitFor response.getBodyBytes()
            echo cast[string](res)


proc process(r: RequestFence): Future[HttpResponseRef] {.async.} =
    {.gcsafe.}:
        if r.isOk():
            let request = r.get()
            try:
                let body = await request.getBody()
                var message = parseJson cast[string](body)
                echo message
                var msglist = message["msglist"][0]
                var msg = msglist["msg"].getStr
                var isHttps = msg.contains "https://"
                var isContractAddress = false
                # var isContractAddress = re".*0x[a-fA-F0-9]{40}.*"
                for i in 0..len(msg) - 42:
                    let substr = msg[i ..< i+42]
                    if substr.startsWith("0x") and substr[2..^1].allCharsInSet(HexDigits):
                        isContractAddress = true
                var msgsvrid = msglist["msgsvrid"].getStr
                var msgType = msglist["msgtype"].getStr
                var fromgid = msglist["fromgid"].getStr
                var fromgname = msglist["fromgname"].getStr
                if  msgType == "1" and msgsvrid != "":
                    if fromgname == "测试二":
                        if msg == "PC发文本消息成功": return
                        var data = %*{"wxid":"39127246200@chatroom","msg": msg}
                        var req = HttpClientRequestRef.new(session, url="http://localhost:30001/SendTextMsg", meth=MethodPost, body= toOpenArrayByte($data, 0, len($data) - 1))
                        if req.isOk:
                            var response = await send(req.get)
                            if response.status == 200:
                                var res = cast[string](response.getBodyBytes())
                                echo res
                            else:
                                echo response.status
                elif msgType == "3" and msgsvrid != "":
                    if fromgname == "测试二":
                        var data = %*{"wxid":"39127246200@chatroom","msgid": msgsvrid}
                        echo "ForwardAllMsg:", data
                        var req = HttpClientRequestRef.new(session, url="http://localhost:30001/ForwardAllMsg", meth=MethodPost, body= toOpenArrayByte($data, 0, len($data) - 1))
                        if req.isOk:
                            var response = await send(req.get)
                            if response.status == 200:
                                var res = cast[string](response.getBodyBytes())
                                echo res
                            else:
                                echo response.status

            except HttpCriticalError as e:
                echo e.msg
                raise e
        else:
            echo r.error()

configureMsgReceive()

let socketFlags = {ServerFlags.TCP_NODELAY, ServerFlags.ReuseAddr}
let res = HttpServerRef.new(initTAddress("127.0.0.1:9001"), process, serverFlags={HttpServerFlags.NotifyDisconnect}, socketFlags = socketFlags)
if res.isErr():
    echo getCurrentExceptionMsg()
    quit 1

let server = res.get()
server.start()
waitFor server.join()