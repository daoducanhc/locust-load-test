import requests

url = "http://localhost:8088/api/v1/patent"

# read tokens and ids from file

f = open('tokens.txt', 'r')
tokens = f.read().splitlines()
f.close()

for i in range(0,1000):
    id, token = tokens[i].split(" ")
    headers = {"Authorization": f"Bearer {token}"}

    # ip create form data
    payload = {
        "ip": "2e2f9e08-b85d-468d-8267-ea32e4d8a921",
        "type": "Design",
        "status": "Pending",
        "title": "Title",
        "created_by": id,
        "patent_priority_date": 666666669,
    }
    
    for _ in range(20):
        response = requests.post(url, data=payload, headers=headers)