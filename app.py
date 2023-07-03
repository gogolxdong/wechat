import itchat
from itchat.content import TEXT
import openai
# @itchat.msg_register(TEXT)
# def simple_reply(msg):
#     return 'I received: %s' % msg['Text']

apikey="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"
# 带对象参数注册，对应消息对象将调用该方法
@itchat.msg_register(TEXT, isFriendChat=True, isGroupChat=True, isMpChat=False)
def text_reply(msg):
    msg.user.send('%s: %s' % (msg.type, msg.text))

itchat.auto_login(hotReload=True)
itchat.run()