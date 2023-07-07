import json, strformat, xmlparser, xmltree, tables
import chronos, chronos/apps/http/httpserver, chronos/apps/http/httpclient


proc configureMsgReceive =
    var config = %*{"isEnable":"1","url":"http://localhost:9001"}
    var session = HttpSessionRef.new({HttpClientFlag.Http11Pipeline}, maxRedirections = HttpMaxRedirections)
    var req = HttpClientRequestRef.new(session, url="http://localhost:30001/ConfigureMsgRecive", meth=MethodPost, body = toOpenArrayByte($config, 0, len($config) - 1))
    if req.isOk:
        var request = req.get()
        var response = waitFor request.send()
        if response.status == 200:
            var res = waitFor response.getBodyBytes()
            echo parseJson cast[string](res)
    waitFor req.get.closeWait()
    waitFor session.closeWait()

template sendImgNoSrc(data:string) {.dirty.} = 
    echo "SendImgMsg_NoSrc:", data
    var session = HttpSessionRef.new({HttpClientFlag.Http11Pipeline}, maxRedirections = HttpMaxRedirections)
    var req = HttpClientRequestRef.new(session, url="http://127.0.0.1:30001/SendImgMsg_NoSrc", meth=MethodPost, body= toOpenArrayByte(data, 0, len(data) - 1))
    if req.isOk:
        var response = await send(req.get)
        echo response.status
        if response.status == 200:
            var body = await response.getBodyBytes()
            var res = cast[string](body)
            echo parseJson res
        else:
            echo response.status
        await response.closeWait()
        await req.get.closeWait()
    else:
        echo req.error()
    await session.closeWait

template forward(data:string) {.dirty.} = 
    echo "ForwardAllMsg:", data
    var session = HttpSessionRef.new({HttpClientFlag.Http11Pipeline}, maxRedirections = HttpMaxRedirections)
    var req = HttpClientRequestRef.new(session, url="http://127.0.0.1:30001/ForwardAllMsg", meth=MethodPost, body= toOpenArrayByte(data, 0, len(data) - 1))
    if req.isOk:
        var response = await send(req.get)
        echo response.status
        if response.status == 200:
            var body = await response.getBodyBytes()
            var res = cast[string](body)
            echo parseJson res
        else:
            echo response.status
        await response.closeWait()
        await req.get.closeWait()
    else:
        echo req.error()
    await session.closeWait

proc process(r: RequestFence): Future[HttpResponseRef] {.async.} =
    {.gcsafe.}:
        try:
            if r.isOk():
                let request = r.get()
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
                var fromgname = if msglist.hasKey"fromgname": msglist["fromgname"].getStr else: ""
                var fromgid = if msglist.hasKey"fromgid": msglist["fromgid"].getStr else: ""
                var fromUser = false
                var realmsgsvrid = if msglist.hasKey"realmsgsvrid":msglist["realmsgsvrid"].getStr else:""
                
                if  msgType == "1" and msgsvrid != "" :
                    if fromgname == "测试二" :
                        if msg == "PC发文本消息成功": return
                        if isHttps or isContractAddress or fromUser:
                            var data = %*{"wxid":"19622860062@chatroom","msg": &"{fromgname}\n{msg}"}
                            var session = HttpSessionRef.new({HttpClientFlag.Http11Pipeline}, maxRedirections = HttpMaxRedirections)
                            var req = HttpClientRequestRef.new(session, url="http://localhost:30001/SendTextMsg", meth=MethodPost, body= toOpenArrayByte($data, 0, len($data) - 1))
                            if req.isOk:
                                var response = await send(req.get)
                                if response.status == 200:
                                    var body = await response.getBodyBytes()
                                    var res = cast[string](body)
                                    echo parseJson res
                                else:
                                    echo response.status
                                await response.closeWait()
                                await req.get.closeWait()
                            else:
                                echo req.error()
                            await session.closeWait
                elif msgType == "3" and msgsvrid != "":
                    if fromgname == "测试二":
                        var doc = parseXml(msg)
                        var imgChild = doc.child("img")
                        var length = imgChild.attrs["length"]
                        var md5 = imgChild.attrs["md5"]
                        var cdnthumburl= imgChild.attrs["cdnthumburl"]
                        var aeskey= imgChild.attrs["aeskey"]

                        var data = %*{"wxidorgid":"19622860062@chatroom","fileid": cdnthumburl, "authkey": aeskey,"filemd5": md5 ,"filesize": length,"filecrc32":""}
                        # forward($data)
                        sendImgNoSrc($data)
            else: echo r.error()
        except HttpCriticalError as e:
            echo e.msg
            raise e
       

configureMsgReceive()

let socketFlags = {ServerFlags.TCP_NODELAY, ServerFlags.ReuseAddr}
let res = HttpServerRef.new(initTAddress("127.0.0.1:9001"), process, serverFlags={HttpServerFlags.NotifyDisconnect}, socketFlags = socketFlags)
if res.isErr():
    echo getCurrentExceptionMsg()
    quit 1

let server = res.get()
server.start()
waitFor server.join()