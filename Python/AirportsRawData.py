import os, csv, time, json
import Session
from bs4 import BeautifulSoup

# define session for skyvector airports information data #
ms = Session.AirportSession()
soup = BeautifulSoup(ms.pageSession().content, features="lxml")


## function group ##
# ---directory-functions--- #
# define Raw Data dirpath #
def rawDataPath():                                                                  
    dir = "../Raw Data"                                                                                # path folder: metar_indonesia/Raw Data
    if not os.path.exists(dir):
        while True:
            print("<Raw Data> folder not found. Exit run. ")
            time.sleep(1.5)
            exit()
    os.chdir(dir)
    print("<Raw Data> folder exists. Change directory...")
    time.sleep(1)

# ---JSON-functions--- #
# define airports data #
def createJSONdata(airport_data:dict):
    airport_data["ICAO"] = title_icao.text
    airport_data["Name"] = title_name.text.strip()
    airport_data["Province"] = title_prov.text.replace("Airports in ","").replace(", Indonesia","")
    airport_data["Source"] = update_time.text
    airport_data["Coordinates"] = apt_loc.text.replace("Coordinates: ","").replace("\n","")
    airport_data["Elevation"] = apt_elev.text.replace(" Elevation is ","").replace("MSL.","MSL").replace("\n","").strip()
    airport_data["AirportUse"] = apt_use
    if apt_runway != []:
        airport_data["Runway"] = apt_runway
    return airport_data

# ---CSV-functions--- #
# create airports data header and row (CSV) #
def flattenJSONtoCSV(json:dict):
    def processValue(keys, value, flattened):
        if isinstance(value, dict):
            for key in value.keys():
                processValue(keys + [key], value[key], flattened)
        elif isinstance(value, list):
            for idx, v in enumerate(value):
                processValue(keys + [str(idx)], v, flattened)
        else:
            flattened['/'.join(keys)] = value

    flattened = {}
    for key in json.keys():
        processValue([key], json[key], flattened)
    return flattened

# define airports data header #
def headerCSV(data):
    header_fields = list() 
    for item in data:
        flat = flattenJSONtoCSV(dict(item))
        for i in flat.keys():
            if i not in header_fields:
                header_fields.append(i)
    return header_fields


## __main__ ##
rawDataPath()
print(f"Start fetching Indonesia's airports data...")
time.sleep(1)

url_province = []
url_airport = []
for items in soup.select("span.views-summary.views-summary-unformatted a[href]"):
    url_province.append(f"{ms.url}{items.text}")

count_url = 0
for url in url_province:
    ms.updateURL(url)
    soup = BeautifulSoup(ms.pageSession().content, features="lxml")
    for items in soup.select("td.views-field.views-field-title a[href]"):
        if (items.text).startswith("WA") or (items.text).startswith("WI"):
            count_url += 1
            item = "https://skyvector.com"+items["href"]
            url_airport.append(item)
            print(f"Found {count_url:0>3} airports in {len(url_province)} provinces.", end='\r')
print(f"Found {count_url:0>3} airports in {len(url_province)} provinces.")
time.sleep(1)


count = 0
output = []
for url in url_airport:
    ms.updateURL(url)
    soup = BeautifulSoup(ms.pageSession().content, features="lxml")

    title_icao = soup.select_one("div#titleouter > div#titlebgleftg")
    title_name = soup.select_one("div#titleouter > div.titlebgrighta")
    title_prov = soup.select("div.aptdata")[2].find("a")
    update_time =  soup.select_one("div#aptdata > div#apt_effective")
    apt_loc = soup.select("div.aptdata")[2].contents[2]
    apt_elev = soup.select("div.aptdata")[2].contents[8]
    opt_data = soup.select("div.aptdata")[3]
    apt_use = opt_data.select_one("tr").find(string="Airport Use:").findNext('td').contents[0]

    apt_runway = []
    for result in soup.select("div.aptdata"):
        r_name = result.select_one("div.aptdatatitle")
        if r_name.text.startswith("Runway "):
            r_detail = []
            r_dict_1 = {}
            r_dict_2 = {}
            runway_array = []
            runway_dict = {}
            if (r_name.text) != "Runway ":
                runway_dict["Name"] = r_name.text

            for row in result.select("table tr"):
                for th in row.select("th"):
                    match th.text:
                        case "Dimensions:":
                            runway_dict["Dimensions"] = th.find_next("td").text.strip()
                        case "Surface:":
                            runway_dict["Surface"] = th.find_next("td").text
                        case x if 'Runway' in x and 'Heading' not in x:
                            r_detail.append(x)
                        case "Coordinates:":
                            for td in row.select("td"):
                                r_detail.append(td.text)
                        case "Elevation:":
                            for td in row.select("td"):
                                r_detail.append(td.text)
                        case "Runway Heading:":
                            for td in row.select("td"):
                                r_detail.append(td.text)
                        case "Displaced Threshold:":
                            for td in row.select("td"):
                                r_detail.append(td.text)                           
                        case _:
                            print("FALSE")
            
                try:
                    r_dict_1["Path"] = r_detail[0]
                    r_dict_2["Path"] = r_detail[1]
                    r_dict_1["Coordinates"] = r_detail[2]
                    r_dict_2["Coordinates"] = r_detail[3]
                    r_dict_1["Elevation"] = r_detail[4]
                    r_dict_2["Elevation"] = r_detail[5]
                    r_dict_1["RunwayHeading"] = r_detail[6]
                    r_dict_2["RunwayHeading"] = r_detail[7] 
                    r_dict_1["DisplacedThreshold"] = r_detail[8]
                    r_dict_2["DisplacedThreshold"] = r_detail[9]
                except(IndexError):
                    pass

            if r_detail != []:
                runway_array.append(r_dict_1)
                runway_array.append(r_dict_2)
                runway_dict["Details"] = runway_array
                apt_runway.append(runway_dict)
                
    count += 1
    print(f"({count:0>3}/{count_url}) FETCH {title_icao.text} | {update_time.text}", end='\r')

    apt_data = {}
    airport_data = createJSONdata(apt_data)
    output.append(airport_data)

print(f"({count:0>3}/{count_url})  COMPLETE  | {update_time.text}")


with open("airports.json", "w", encoding="utf-8") as outfile:
    json.dump(output, outfile, indent=2, ensure_ascii=False)
    print(f"Saving data into JSON format.")
    time.sleep(1)
    outfile.close()

file = open('airports.json')
json_file = json.load(file)
file.close()    

header = headerCSV(json_file)
with open('airports.csv', 'w', newline='') as csvfile:
    writer = csv.DictWriter(csvfile, fieldnames=header)
    writer.writeheader()
    for item in json_file:
        row = flattenJSONtoCSV(dict(item))
        new_row = dict()
        for sub in row:
            new_row[sub] = str(row[sub]).replace("Â","")
        writer.writerow(new_row)
    csvfile.close()
print(f"Saving data into CSV format.")
time.sleep(1)
print(f"Completed.")

## EOF ##