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
    if not os.path.exists(dir):                                                                 # <Raw Data> folder not found
        while True:
            dir_input = input("<Raw Data> folder not found. Continue to create? (y/n): ")       # consent for creating folder
            if dir_input.lower() == 'y':                                                        # continue
                os.makedirs(dir)                                                                # create <Raw Data> folder 
                print("<Raw Data> folder created...")
                time.sleep(1)
            elif dir_input.lower() == 'n':                                                      # drop
                print("No folder created. Exit run.")                                           # exit: terminal notification
                time.sleep(1.5)
                exit()                                                                          # exit program
            else:
                continue                                                                        # wrong input loop
    os.chdir(dir)                                                                               # folder exists -> change directory
    print("<Raw Data> folder exists. Change directory...")                                      
    removeBlankFile()
    time.sleep(1)
    return list(map(lambda st: str.replace(st, ".txt", ""), os.listdir()))                      # create local_list

# remove blank files #
def removeBlankFile():
    for file in os.listdir():                                                                   # file list on <Raw Data>
        if os.path.isfile(file) and os.stat(file).st_size == 0:                                 # file exists & empty files
                os.remove(file)                                                                 # remove file
        else:
            pass

# list of airports on metar_speci.php #
def metarAirportList(alist:list):
    soup = createPageResult()
    for items in soup.select("ul.icao_code_list li a"):                                         #.CSS Selector
        item = (items.text)[:4]                                                                 # ICAO codename format
        if item not in alist:                                                                   # remove duplicate W%
            alist.append(item)                                                                  # list of icao_airport (online)
    return alist                                                                                # create metar_list

# count added-files plan #
def countAddedFiles():
    count_add = len(metar_alist) - len(local_alist)                                             # (metar - local) deviation
    if len(local_alist) < len(metar_alist):                                                     # default: metar > local
        print (f"{count_add} files will be added. Start scraping...")
        time.sleep(1)
        return count_add
    else:                                                                                       # TODO: elif -> local > metar (?)
        print("No files will be added. Exit run.")                                              # empty folder, no files -> exit
        time.sleep(1.5)
        exit()

# ---add functions--- #
# create soup #
def createPageResult():
    return BeautifulSoup(ms.metarSession().content, features="lxml")                            # HTML page for scraping                                     

# parse metar_speci.php #
def parseMetarSpeci(soup: BeautifulSoup):
    if soup.find("span", {"class":"data_text"}):                                                # content returns data

        if soup.find("select", {"name":"page_number_1"}):                                       # multiple page contents
            page = soup.select("option")[-1].text                                               #.CSS Selector <option> tag value -> string                                   
            
            for number in reversed (range (int(page))):                                         # descending order of page
                ms.updateParams("pn", number)                                                   # customize params["pn"]                                       
                soup = createPageResult()
                fetchData(soup)
        else:
            fetchData(soup)                                                                     # single page contents
            
        print(template, f"{items}: FETCH    | {current_date.strftime('%d/%m/%Y')}", end='\r')   # fetch state: terminal notification
        time.sleep(.5)

    else:
        print(template, f"{items}: NO-DATA  | {current_date.strftime('%d/%m/%Y')}", end='\r')   # content returns "Data tidak ditemukan"   
        time.sleep(.5)

# fetching contents #
def fetchData(soup:BeautifulSoup):
    fetch_date = current_date.strftime("%d-%b-%Y")                                              # current_date value -> string

    r_result=[]
    for span in soup.select("span.data_text"):                                                  #.CSS Selector <span>                                      
        span_lines = span.get_text(separator =" ")
        result = (f"{fetch_date} {span_lines.strip()}")                                         # fetch_date + .filter <br>                             
        r_result.insert(0, result)                                                              # insert contents after previous result
    for r in r_result:
        file.write(f"{r}\n")                                                                    # loop list to write at opened file

## __main__ ##
local_alist = rawDataPath()
metar_alist = []
metarAirportList(metar_alist)

count_current = 0
count_added = countAddedFiles()

for items in metar_alist:                                                                       # loop list of metar_speci.php airport list
    if items not in local_alist:                                                                # files not existing in local repo
        ms.updateParams("icao", items)                                                          # state current icao files for fetching
        ms.updateParams("fd", "1/1/2010")                                                       # reset to default start date

        start_date = datetime.strptime(ms.params["fd"], "%d/%m/%Y")                             # define start date value -> date type
        end_date = datetime.now()                                                               # fetch until H-1
        num_days = (end_date - start_date).days                                                 # count days
        
        with open(ms.params["icao"]+".txt", "a+", encoding="utf-8") as file:                    # append mode, utf-8 encoding; WARE: 01/10/2022
            count_current += 1
            template = f"({count_current:0>3}/{count_added:0>3})"                               # terminal display for counting list
            print(template, f"{items}: START    | {start_date.strftime('%d/%m/%Y')}", end='\r') # start state of scraping
            
            for i in range(num_days):                                                           # loop count from day 0
                current_date = start_date + timedelta(days=i)                                   # current_date on ascending order
                ms.updateParams("fd",current_date.strftime("%d/%m/%Y"))                         # change start date of daily scraping
                ms.updateParams("ud",current_date.strftime("%d/%m/%Y"))                         # change end date of daily scraping
                
                soup = createPageResult()
                parseMetarSpeci(soup)
            
            file.close()                                                                        # close file <append mode>
            print(template, f"{items}: COMPLETE | {current_date.strftime('%d/%m/%Y')}")         # end state of scraping
            
## EOF ##
