import requests
import paramiko
import datetime
from bs4 import BeautifulSoup

requests.packages.urllib3.disable_warnings()

current_date = datetime.date.today()
ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

HMC = "hmc01"

csv = []
mslist = []
asmips = []


def get_asmip(hmc):
    ssh.connect(hostname=hmc, username='hscroot', password='abc1234', timeout=120)
    ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command('lssyscfg -r sys -F name,ipaddr')
    output = ssh_stdout.readlines()
    for i in output:
        if len(i) > 0 and "No results were found." not in i:
            mslist.append(str(i).strip('\n'))
    if len(mslist) > 0:
        for i in mslist:
            asmips.append(str(i).split(',')[1])


def get_events(hmc, asmip, formid, msname):
    events = []
    login_values = {
        'user': 'admin',
        'password': 'abcd',
        'CSRF_TOKEN': '0',
        'asmip': asmip,
        'login': 'Log in'
    }

    logout_values = {
        'CSRF_TOKEN': '0',
        'submit': 'Log out',
        'asmip': asmip
    }

    login_headers = {
        'User-Agent': 'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:64.0) Gecko/20100101 Firefox/64.0',
        'Content-Type': 'application/x-www-form-urlencoded',
        'Connection': 'keep-alive',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept-Language': 'en-US,en;q=0.5',
        'Cache-Control': 'no-cache',
        'Content-Length': '79',
        'DNT': '1',
        'Host': hmc + ':443',
        'Pragma': 'no-cache',
        'Referer': 'https://' + hmc + '/asmproxy/AsmProxy/cgi?form=2',
        'Upgrade-Insecure-Requests': '1',
        'Cookie': 'asm_session=0',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8',
        'Origin': 'https://' + hmc,
        'Expires': '0'
    }

    login_url = "https://" + hmc + "/asmproxy/AsmProxy/cgi"
    events_url = "https://" + hmc + "/asmproxy/AsmProxy/cgi?asmip=" + asmip + "&form=" + str(formid)
    # deconfig_url = "https://" + hmc + "/asmproxy/AsmProxy/cgi?asmip=" + asmip + "&form=102"
    logout_url = "https://" + hmc + "/asmproxy/AsmProxy/cgi"
    try:
        # print("Login url: " + login_url)
        print("Events url: " + events_url)
        session = requests.session()
        session.verify = False
        r = session.post(login_url, data=login_values, verify=False, headers=login_headers)
        print(r.cookies)
        print(r.cookies.get_dict())
        print(
            "######################################################################################################")
        x = session.get(events_url, verify=False)

        if x.status_code == 200:
            soup = BeautifulSoup(x.text, 'html.parser')
            elem = soup.find("div", {"class": "div-box"})
            for i in elem.findAll("td"):
                if i:
                    events.append(str(i.text).strip())
        result = range(1, len(events), 6)
        for num, lines in enumerate(events):
            if num in result:
                print(hmc + ';' + msname + ';' + ';'.join(events[num:num + 6]).rstrip(';'))
                csv.append('DEFAULT;' + hmc + ';' + msname + ';' + ';'.join(events[num:num + 6]).rstrip(';'))
        print(
            "#####################################################################################################")
        logout_headers = {
            'Host': hmc,
            'User-Agent': 'Mozilla/5.0 (X11; Fedora; Linux x86_64; rv:64.0) Gecko/20100101 Firefox/64.0',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.5',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://' + hmc + '/asmproxy/AsmProxy/cgi?form=1',
            'Content-Type': 'application/x-www-form-urlencoded',
            'Content-Length': '55',
            'DNT': '1',
            'Connection': 'keep-alive',
            'Cookie': 'asm_session=' + r.cookies.get_dict().get('asm_session'),
            'Upgrade-Insecure-Requests': '1',
            'Expires': '0'
        }
        print("logout: ")
        print(logout_headers)
        session.post(logout_url, data=logout_values, verify=False, headers=logout_headers)
        r.cookies.clear_session_cookies()
        session.close()
        with open("/tmp/asmi_events_" + str(msname) + ".csv", mode='wt', encoding='latin-1') as f:
            for i in csv:
                f.writelines(str(i) + "\n")
    except:
        pass


get_asmip(HMC)
for x in mslist:
    if "9117" in x:
        asm = str(x).split(',')[1].rstrip('\n')
        ms = str(x).split(',')[0].rstrip('\n')
        get_events(HMC, asm, 30, ms)
    elif "8284" in x:
        asm = str(x).split(',')[1].rstrip('\n')
        ms = str(x).split(',')[0].rstrip('\n')
        get_events(HMC, asm, 31, ms)
# get_events(HMC, '172.16.255.254', 30)
