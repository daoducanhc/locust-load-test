
# login and get 1000 tokens

import requests

url = "http://137.132.92.226:4088/auth/login"

f = open('tokens.txt', 'w')


for i in range(1, 10001):
    # body form data
    
    payload = {
        "account_name": str(i) + "@gmail.com",
        "password": i
    }
    response = requests.post(url, data=payload)

    id = response.json()['id']
    token = response.json()['token']

    # save id and token to file
    f.write(str(id))
    f.write(' ')
    f.write(token)
    f.write('\n')

f.close()