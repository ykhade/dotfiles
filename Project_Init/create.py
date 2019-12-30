import sys
import os
from github import Github

path = "/[PATH]"

username = "<USERNAME>" #Insert your github username
password = "<PASSWORD>" #Insert your github password

def create():
    folderName = str(sys.argv[1])
    os.makedirs(path + str(sys.argv[1]))
    user = Github(username, password).get_user()
    repo = user.create_repo(sys.argv[1])
    print("Success{}".format(sys.argv[1]))

if __name__ == "__main__":
    create()
