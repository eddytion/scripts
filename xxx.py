from selenium import webdriver

browser = webdriver.PhantomJS()
#options.add_argument('headless')

#browser = webdriver.Chrome(chrome_options=options)
url = "https://deehhmc011ccpxa/asmproxy/AsmProxy/cgi?form=2"
browser.get(url)

username = browser.find_element_by_name("user")
password = browser.find_element_by_name("password")

username.send_keys("admin")
password.send_keys("admin")

submitButton = browser.find_element_by_name("login")
submitButton.click()

browser.get("https://deehhmc011ccpxa/asmproxy/AsmProxy/cgi?asmip=172.17.254.255&form=30")
innerHTML = browser.execute_script("return document.body.innerHTML")
