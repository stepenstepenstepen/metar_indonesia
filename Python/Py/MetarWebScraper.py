import os
import _Session
from bs4 import BeautifulSoup
from datetime import datetime, timedelta

# define session for metar_speci.php #
ms = _Session.session()
ms.openSession()                                                                    # bypass aggrement session page

## function group ##
# local repo #
def rawDataPath():
    dir = "./Raw Data"                                                              
    if not os.path.exists(dir):
        os.makedirs(dir)
    os.chdir(dir)                                                                   # ../metar_indonesia/Raw Data

# create soup content page for parsing #
def createPageResult():
    return BeautifulSoup(ms.metarSession().content, features="lxml")

# parse metar_speci.php #
def parseMetarSpeci(soup: BeautifulSoup):
    if soup.find("span", {"class":"data_text"}):                                    # content returns data

        if soup.find("select", {"name":"page_number_1"}):                           # multiple page contents
            page = soup.select("option")[-1].text                                   #.CSS Selector <option> tag value -> string
            
            for number in reversed (range (int(page))):                             # descending order of page
                ms.update_params("pn", number)                                      # customize params["pn"]
                soup = createPageResult()
                fetchData(soup)
        else:
            fetchData(soup)
            
        print(f"{current_date}: fetch data finished")                               # terminal notification

    else:
        print(f"{current_date}: no data")                                           # content returns "Data tidak ditemukan"
        
# fetching contents #
def fetchData(soup: BeautifulSoup):
    fetch_date = current_date.strftime("%d-%b-%Y")                                  # current_date value -> string

    r_result=[]
    for span in soup.select("span.data_text"):                                      #.CSS Selector <span>
        span_lines = span.get_text(separator =" ")                                  
        result = (f"{fetch_date} {span_lines.strip()}")                             # fetch_date + .filter <br>
        r_result.insert(0, result)                                                  # insert contents after previous result
    for r in r_result:
        file.write(f"{r}\n")                                                        # loop list to write at opened file


## __main__ ##
start_date = datetime.strptime(ms.params["fd"], "%d/%m/%Y")                         # define start date value -> date type
end_date = datetime.now()                                                           # fetch until H-1

num_days = (end_date - start_date).days                                             # count days
print(ms.params["icao"] + f", {start_date}, {end_date}, {num_days}")

rawDataPath()

with open(ms.params["icao"]+".txt", "a+", encoding="utf-8") as file:                # open file in append mode, utf-8 encode (17/09/2023 issue)
    for i in range(num_days):                                                       # loop count from day 0
        current_date = start_date + timedelta(days=i)                               # current_date on ascending order
        
        ms.update_params("fd",current_date.strftime("%d/%m/%Y"))                    # start date for data-mining
        ms.update_params("ud",current_date.strftime("%d/%m/%Y"))                    # end date for data-mining
        
        soup = createPageResult()
        parseMetarSpeci(soup)
        
    print("finished fetching all data.")                                            # final state for data-mining

## EOF ##
