import requests
import gzip


def upload_data():
    url = 'http://localhost/cloud/upload.php'
    myfile = '/tmp/testfile.txt'

    with open(myfile, 'rb') as f:
        content = f.read()

    paylod = {'content': content, 'submit': 'SUBMIT', 'source_server': 'deehisd021ccpr1',
              'file_name': 'deehisd021ccpr1_scan_2018-12-27.tar.gz'}
    r = requests.post(url=url, data=paylod)

    print(r.text)
