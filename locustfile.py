from locust import HttpUser, TaskSet, task, between
import random

# class User10kOnly(TaskSet):
#     # Load tokens from a file
#     with open('tokens.txt') as f:
#         tokens = f.read().splitlines()

#     def on_start(self):     
#         # Assign a unique token to each user
#         self.id, self.token = User10kOnly.tokens.pop().split(" ")
#         self.headers = {"Authorization": f"Bearer {self.token}"}
#     @task
#     def get_apis(self):
#         APIs = [
#             "/api/v1/org?page=1&condition=undefined&value=undefined",
#             "/api/v1/dashboard/manager/upcoming_event",
#             "/api/v1/dashboard/manager/ip/count",
#             "/api/v1/dashboard/manager/patent/count",
#             "/api/v1/dashboard/manager/agr/count",
#             "/api/v1/dashboard/manager/agr/revenue",
#             "/api/v1/dashboard/manager/ip/expense",
#             "/api/v1/dashboard/manager/ip/tag/count",
#             "/api/v1/dashboard/manager/patent/count_by_country",
#             "/api/v1/dashboard/manager/patent/count_by_type",
#             "/api/v1/dashboard/manager/trl_chart",
#             "/api/v1/dashboard/manager/crl_chart"
#         ]

#         for api in APIs:
#             self.client.get(api, headers=self.headers)

#         # get IPs
#         api = "/api/v1/ip?page=1&page_size=5&condition=ManagerId,SortedBy,SortOrder&value={},modified_on,desc".format(self.id)
#         self.client.get(api, headers=self.headers)

class FullDatabaseUserBehavior(TaskSet):
     # Load tokens from a file
    with open('tokens.txt') as f:
        tokens = f.read().splitlines()

    def on_start(self):     
        # Assign a unique token to each user
        self.id, self.token = FullDatabaseUserBehavior.tokens.pop(0).split(" ")
        self.headers = {"Authorization": f"Bearer {self.token}"}

        

    
    @task
    def update_patent(self):
        # get patents by created_by
        api = "/api/v1/patent?page=1&page_size=30&condition=CreatedBy&value={}".format(self.id)
        response = self.client.get(api, headers=self.headers)

        # random patent_id
        random_index = random.randint(0, len(response.json()['list']) - 1)
        patent_id = response.json()['list'][random_index]['patent_id']

        # update patent
        api = "/api/v1/patent/{}".format(patent_id)
        payload = {
            "title": "Updated Title",
            "modified_by": self.id
        }
        self.client.put(api, data=payload, headers=self.headers)

    @task(9)
    def get_patent(self):
        # get patents by created_by
        api = "/api/v1/patent?page=1&page_size=20&condition=CreatedBy&value={}".format(self.id)
        response = self.client.get(api, headers=self.headers)

        # random patent_id
        random_index = random.randint(0, len(response.json()['list']) - 1)
        patent_id = response.json()['list'][random_index]['patent_id']
        
        # get patent
        api = "/api/v1/patent/{}".format(patent_id)
        self.client.get(api, headers=self.headers)
        

class WebsiteUser(HttpUser):
    tasks = [FullDatabaseUserBehavior]
    wait_time = between(2, 5)