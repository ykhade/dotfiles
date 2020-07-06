from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options

options = Options()
options.binary_location = '/Applications/Brave Browser.app/Contents/MacOS/Brave Browser'
driver_path = '/usr/local/bin/chromedriver'
drvr = webdriver.Chrome(options = options, executable_path = driver_path)


drvr.get('https://login.live.com')

EMAILFIELD = (By.ID, "i0116")

# driver options = driver().setBinary("/Applications/Brave.app/Contents/MacOS/brave")
# WebDriver driver = new ChromeDriver(options)
# def site_login():
WebDriverWait(drvr, 10).until(EC.element_to_be_clickable(EMAILFIELD)).send_keys("email")

