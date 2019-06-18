import requests
from bs4 import BeautifulSoup
import datetime

urls = [
    'https://www.emag.ro/laptop-asus-cu-procesor-intelr-coretm-i5-8250u-pana-la-3-40-ghz-kaby-lake-r-15-6-full-hd-4gb-1tb-dvd-rw-nvidiar-geforcer-mx130-2gb-endless-os-matt-silver-a542uf-dm119/pd/DC69VVBBM/',
    'https://www.emag.ro/laptop-dell-inspiron-3576-cu-procesor-intelr-coretm-i5-8250u-pana-la-3-40-ghz-kaby-lake-r-15-6-full-hd-4gb-1tb-dvd-rw-amd-radeon-520-2gb-ubuntu-linux-16-04-black-di3576i541520ubud/pd/DDTTGVBBM/',
    'https://www.emag.ro/laptop-ultraportabil-lenovo-thinkpad-x1-carbon-6th-cu-procesor-intelr-coretm-i7-8550u-pana-la-4-00-ghz-kaby-lake-r-14-full-hd-ips-16gb-512gb-ssd-intelr-uhd-graphics-620-microsoft-windows-10-pro-black-/pd/D650SSBBM/',
    'https://www.emag.ro/laptop-gaming-lenovo-legion-y520-cu-procesor-intelr-coretm-i5-7300hq-pana-la-3-50-ghz-kaby-lake-15-6-full-hd-ips-8gb-256gb-nvidia-geforcer-gtx-1050-ti-4gb-free-dos-red-80wk0140ri/pd/DQ7J1HBBM/',
    'https://www.emag.ro/laptop-lenovo-v330-15ikb-cu-procesor-intelr-coretm-i7-8550u-pana-la-4-00-ghz-kaby-lake-r-15-6-full-hd-8gb-256gb-ssd-amd-radeon-530-2gb-free-dos-iron-gray-81ax00dvri/pd/DR5W2JBBM/',
    'https://www.emag.ro/laptop-asus-cu-procesor-intelr-coretm-i3-7100u-2-40-ghz-kaby-lake-15-6-4gb-1tb-nvidiar-geforcer-920mx-2gb-windows-10-chocolate-black-x541uv-go1047t/pd/D5KR9NBBM/',
    'https://www.emag.ro/card-de-memorie-sandisk-micro-sd-ultra-128gb-class-10-full-hd-sdsquar-128g-gn6ma/pd/D074XNBBM/?ref=hp_prod_widget_live_asp_1_3&recid=rec_2_rec_2_9a375ce30ab1109ced5b06b88997a79f_1542359561',
    'https://www.emag.ro/ceas-smartwatch-garmin-fenix-5-hr-gps-silver-silicone-black-010-01688-03/pd/DJVB8JBBM/']

csv = []
runDate = datetime.datetime.now().isoformat()


def acrobot():
    for url in urls:
        resp = requests.get(url)
        if resp.status_code == 200:
            soup = BeautifulSoup(resp.text, 'html.parser')
            l = soup.find("p", {"class": "product-new-price"})
            x = l.get_text()
            price = "".join(str(x).split())[:-5]
            print(url + ' => ' + price)
            csv.append(url + ',' + price)
        else:
            print("Error")


acrobot()

with open('emag.csv', mode='at', encoding='utf-8') as f:
    for i in csv:
        f.writelines(str(runDate) + ',' + '"' + i + '"' + '\n')
