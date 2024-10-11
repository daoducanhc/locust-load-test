import requests

url = "http://localhost:8088/api/v1/agr"

# read tokens and ids from file

f = open('tokens.txt', 'r')
tokens = f.read().splitlines()
f.close()

for i in range(1000):
    id, token = tokens[i].split(" ")
    headers = {"Authorization": f"Bearer {token}"}

    # ip create form data
    payload = {
        "type": "Research Agreement",
        "status": "Aborted",
        "title": "Title",
        "created_by": id,
        "manager_id": id,
    }
    
    for _ in range(10):
        response = requests.post(url, data=payload, headers=headers)