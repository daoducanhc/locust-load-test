import requests

url = "http://localhost:8088/api/v1/ip"

# read tokens and ids from file

f = open('tokens.txt', 'r')
tokens = f.read().splitlines()
f.close()

for i in range(1000):
    id, token = tokens[i].split(" ")
    headers = {"Authorization": f"Bearer {token}"}

    # ip create form data
    payload = {
        "title": "Title",
        "disclosure_date": 666666669,
        "created_by": id,
    }
    
    for _ in range(5):
        response = requests.post(url, data=payload, headers=headers)