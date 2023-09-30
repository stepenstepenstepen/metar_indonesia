import os
import time
import dm_Session
from bs4 import BeautifulSoup
from datetime import datetime, timedelta

# define session for metar_speci.php #
ms = dm_Session.Session()
ms.webSession()                                                                                 # bypassing aggrement page

## function group ##
# ---directory-functions--- #
# define Raw Data dirpath #
def rawDataPath():                                                                  
    dir = "./Raw Data"                                                                          # path folder: metar_indonesia/Raw Data
    if not os.path.exists(dir):
        while True:
            print("<Raw Data> folder not found. Exit run. ")                                    # no target folder -> exit
            time.sleep(1.5)
            exit()
    os.chdir(dir)
    print("<Raw Data> folder exists. Change directory...")                                      # change dir to target folder
    time.sleep(1)

# define list of airports in local repo #
def defineLocalFiles():
    local_alist = list(map(lambda st: str.replace(st, ".txt", ""), os.listdir()))               # create local list for update-loop

    if len(local_alist) != 0:
        print(f"{len(local_alist)} existing files. Updating contents...")                       # count existing files
        time.sleep(1)
        return local_alist                                                           
    else:
        print("No files in <Raw Data> folder. Exit run.")                                       # empty folder, no files -> exit
        time.sleep(1.5)
        exit()

# ---update functions--- #
# get last date on local files #
def getDateEOF():                                                                               # TODO: tracing backward with valid format date
    with open(items + '.txt', 'rb') as file:                                                    # read binary mode
        try: 
            file.seek(-2, os.SEEK_END)                                                          # seek cursor for read lines from EOF
            while file.read(1) != b'\n':
                file.seek(-2, os.SEEK_CUR)                                                      # move current cursor to valid EOF
        except OSError:                                                                         # OSError in case of a one line file
            file.seek(0)
        last_date = file.readline(11).decode("UTF-8")                                           # catch initial lines for EOF_date
        file.close()
    return last_date

# check validity of local files contents #
def checkDateEOF(filename, EOF_date):
    try:                                                                                        # check EOF datetime format
        EOF_date = datetime.strptime(EOF_date, "%d-%b-%Y")                                      # EOF_date -> last_date
    except ValueError:                                                                          # invalid EOF datetime
        with open(filename + '.txt', 'w') as file:
            file.truncate()                                                                     # invalid EOF datetime -> erase all contents
            file.close()
            EOF_date = datetime.strptime("01/01/2010", "%d/%m/%Y")                              # EOF_date -> 01/01/2010
    return EOF_date

# remove last date lines  #
def removeLinesEOF(filename, last_date):                                                        # TODO: remove last_date vs last_month (?)
    with open(filename + '.txt', 'r+') as file:                                                 # read and write mode
        if os.stat(file.name).st_size != 0:                                                     # non-empty files
            EOF_lines = 0
            lines = file.readlines()
            for line in lines:
                if line.startswith(last_date):                                                  # catch every lines start with last_date
                    EOF_lines += 1
            file.seek(0)
            file.truncate()
            file.writelines(lines[:-(EOF_lines)])                                               # overwrite lines w/o last_date lines
        else:
            file.truncate()                                                                     # empty files -> erase all contents
        file.close()

# ---add functions--- #
# create soup #
def createPageResult():
    return BeautifulSoup(ms.metarSession().content, features="lxml")                

# parse metar_speci.php #
def parseMetarSpeci(soup: BeautifulSoup):
    if soup.find("span", {"class":"data_text"}):

        if soup.find("select", {"name":"page_number_1"}):
            page = soup.select("option")[-1].text                                   
            
            for number in reversed (range (int(page))):
                ms.updateParams("pn", number)                                       
                soup = createPageResult()
                fetchData(soup)
        else:
            fetchData(soup)
            
        print(template, f"{items}: FETCH    | {current_date.strftime('%d/%m/%Y')}", end='\r')
        time.sleep(.5)

    else:
        print(template, f"{items}: NO-DATA  | {current_date.strftime('%d/%m/%Y')}", end='\r')
        time.sleep(.5)

# fetching contents #
def fetchData(soup:BeautifulSoup):
    fetch_date = current_date.strftime("%d-%b-%Y")

    r_result=[]
    for span in soup.select("span.data_text"):                                      
        span_lines = span.get_text(separator =" ")
        result = (f"{fetch_date} {span_lines.strip()}")                             
        r_result.insert(0, result)
    for r in r_result:
        file.write(f"{r}\n")

## __main__ ##
rawDataPath()
local_alist = defineLocalFiles()

count = 0
for items in local_alist:
    ms.updateParams("icao", items)                                                              # customize params["icao"] -> items
        
    EOF_date = checkDateEOF(items, getDateEOF())                                                # define EOF_date
    ms.updateParams("fd",EOF_date.strftime("%d/%m/%Y"))                                         # customize params["fd"] -> EOF_date

    removeLinesEOF(items, getDateEOF())                                                         # remove last_date lines                        

    start_date = EOF_date
    end_date = datetime.now()
    num_days = (end_date - start_date).days

    with open(ms.params["icao"]+".txt", "a+") as file:
        count += 1
        template = f"({count:0>3}/{(len(local_alist)):0>3})"
        print(template, f"{items}: START    | {start_date.strftime('%d/%m/%Y')}", end='\r')

        for i in range(num_days):
            current_date = start_date + timedelta(days=i)
                
            ms.updateParams("fd",current_date.strftime("%d/%m/%Y"))
            ms.updateParams("ud",current_date.strftime("%d/%m/%Y"))
                
            soup = createPageResult()
            parseMetarSpeci(soup)

        file.close()
        print(template, f"{items}: COMPLETE | {current_date.strftime('%d/%m/%Y')}")

## EOF ##