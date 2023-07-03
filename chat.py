import openai


openai.api_key = ''
# openai.organization = "org-RgKQmJEzmxCD6gCMx0Z7FngL"
# print(openai.Model.list())

# response = openai.Image.create(
#   prompt="create nounlish",
#   n=1,
#   size="1024x1024"
# )
# image_url = response['data'][0]['url']
# print(image_url)

# try:
#   openai.Image.create_variation(
#     open("C:\Users\lxdon\Pictures\diffusion/1.gif","rb"),
#     n=1,
#     size="1024x1024"
#   )
#   print(response['data'][0]['url'])
# except openai.error.OpenAIError as e:
#   print(e.http_status)
#   print(e.error)

# openai.api_key = ''
model_id = 'gpt-4'

def ChatGPT_conversation(conversation):
    response = openai.ChatCompletion.create(
        model=model_id,
        messages=conversation
    )
    # api_usage = response['usage']
    # print('Total token consumed: {0}'.format(api_usage['total_tokens']))
    # stop means complete
    # print(response['choices'][0].finish_reason)
    # print(response['choices'][0].index)
    conversation.append({'role': response.choices[0].message.role, 'content': response.choices[0].message.content})
    return conversation

conversation = []
# conversation.append({'role': 'system', 'content': '你是samczsun'})
# conversation = ChatGPT_conversation(conversation)
# print('{0}: {1}\n'.format(conversation[-1]['role'].strip(), conversation[-1]['content'].strip()))

while True:
    prompt = input('User:')
    conversation.append({'role': 'user', 'content': prompt})
    conversation = ChatGPT_conversation(conversation)
    print('{0}: {1}\n'.format(conversation[-1]['role'].strip(), conversation[-1]['content'].strip()))