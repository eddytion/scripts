import json
import requests

URL = "https://www14.software.ibm.com/webapp/set2/flrt/report?pageNm=home&reportType=power&plat=power&p0.mtm=9119-MME&p0.fw=SC860_160&btnGo=SUBMIT&format=json"
x = requests.get(URL)
j = x.json()
inputVersion = j["flrtReport"][0]["System"]["fw"]["input"]["version"]
inputReleaseDate = j["flrtReport"][0]["System"]["fw"]["input"]["releaseDate"]
latestVersion = j["flrtReport"][0]["System"]["fw"]["input"]["latest"]["version"]
latestReleaseDate = j["flrtReport"][0]["System"]["fw"]["input"]["latest"]["releaseDate"]
print(inputVersion)
print(inputReleaseDate)
print(latestVersion)
print(latestReleaseDate)
