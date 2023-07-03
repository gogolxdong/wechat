import asyncdispatch, asynchttpserver ,json, httpclient, ws, re

proc cb(req: asynchttpserver.Request) {.async.} =
    var body = req.body.parseJson()
    echo body
    var client = newHttpClient()
    defer: client.close()
    var isHttps = body.contains "https://"
    var isContractAddress = re".*0x[a-fA-F0-9]{40}.*"
    var msg = body["msglist"][0]
    var msgId = msg["msgsvrid"].getStr

    if msg["msgtype"].getStr == "1" and msgId != "":
        var content = msg["msg"].getStr
        if content == "PC发文本消息成功": return
        var data = %*{"wxid":"39127246200@chatroom","msg": content}
        var response = client.post("http://localhost:30001/SendTextMsg", body= $data)
        echo response.body
    elif msg["msgtype"].getStr == "3" and msgId != "":
        if msg["fromgid"].getStr == "34966788124@chatroom":
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

