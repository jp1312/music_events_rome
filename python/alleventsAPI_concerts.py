# -*- coding: utf-8 -*-
"""
Created on Fri Mar 10 09:45:58 2017

@author: pc
"""

import http.client, urllib.request, urllib.parse, urllib.error, base64

# Headers are extra information that we want to pass to the server we are trying to fetch
# In this case we need to let the server know the subscription key for the API usage
headers = {
    # Request headers
    'Ocp-Apim-Subscription-Key': '4909f3eeb34540e987e7bebf21a9abcb',
}

# Another information we need to pass to the server are the details of our request
params = urllib.parse.urlencode({
    # Request parameters
    'city': 'Rome',
    'state': 'Lazio',
    'country': 'Italy',
    'page': '0',
    'sdate': '20-03-2017',
    'edate': '27-03-2017',
    'category': 'Concerts',
})

# Try to fetch allevents API URL
try:
    # open connection to the URL
    conn = http.client.HTTPSConnection('api.allevents.in')
    # make a request to the URL using method .request() for connection objects
    # while we make a request we also want to send to the server extra information about the request itself (headers)
    # To send data to server POST statement is used. params and headers previously defined are passed then
    conn.request("POST", "/events/list/?%s" % params, "{body}", headers)
    # get response from server
    response = conn.getresponse()
    # response are file-like object so you can use .read() method on that
    concerts = response.read()
    # print response (if any)
    # print(data)
    # close connection
    conn.close()
except Exception as e:
    print("[Errno {0}] {1}".format(e.errno, e.strerror))

####################################





# decode data to simple string
concerts_json = concerts.decode('utf-8')
# convert python object to json strings
concerts_dict = json.loads(concerts_json)
print(concerts_dict['count'])

with open('rm_concerts_2003_2703_pg0.json', 'w') as f:
    json.dump(concerts_dict, f)
