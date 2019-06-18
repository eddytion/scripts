import requests
from bs4 import BeautifulSoup
import sys

word = ""

if len(sys.argv) < 2:
    print("Usage: " + str(sys.argv[0]) + " IBM")
    sys.exit(1)
else:
    word = sys.argv[1]


def acrobot():
    url = 'https://acronyms.thefreedictionary.com/' + str(word)
    resp = requests.get(url)
    if resp.status_code == 200:
        soup = BeautifulSoup(resp.text, 'html.parser')
        l = soup.find("div", {"id": "Definition"})
        for i in l.findAll("td"):
            print(i.text)
    else:
        print("Error")


acrobot()
