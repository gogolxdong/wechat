import asyncdispatch, asynchttpserver ,json, httpclient, ws, strutils

proc cb(req: asynchttpserver.Request) {.async.} =
    var body = req.body.parseJson()
    echo body
    var client = newHttpClient()
    defer: client.close()
    var isHttps = body.contains "https://"
    var isContractAddress = false
    var msglist = body["msglist"][0]
    var msg = msglist["msg"].getStr
    for i in 0..len(msg) - 42:
        var substr = msg[i ..< i+42]
        if substr.startsWith("0x") and substr[2..^1].allCharsInSet(HexDigits):
            isContractAddress = true
    var msgId = msglist["msgsvrid"].getStr
    var msgType = msglist["msgtype"].getStr
    # var fromgid = msglist["fromgid"].getStr
    # var fromgname = msglist["fromgname"].getStr
    if msgType == "1" and msgId != "":
        # if msg["fromgid"].getStr == "34966788124@chatroom":
            if msg == "PC发文本消息成功": return
            var data = %*{"wxid":"39127246200@chatroom","msg": msg}
            var response = client.post("http://localhost:30001/SendTextMsg", body= $data)
            echo response.body
    elif msgType == "3" and msgId != "":
        # if msg["fromgid"].getStr == "34966788124@chatroom":
            var data = %*{"wxid":"39127246200@chatroom","msgid": msgId}
            echo "ForwardAllMsg:", data
            var response = client.post("http://localhost:30001/ForwardAllMsg", body= $data)
            echo response.body

var client = newHttpClient()
var config = %*{"isEnable":"1","url":"http://localhost:9001"}
var reponse = client.post("http://localhost:30001/ConfigureMsgRecive", body= $ config)
# var reponse = post("http://localhost:30001/ConfigureMsgRecive", body= $ config)
echo reponse.code
var server = newAsyncHttpServer()
waitFor server.serve(Port(9001), cb)

