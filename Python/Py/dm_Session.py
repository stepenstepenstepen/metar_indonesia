import requests

class Session :

    def __init__(self) -> None:
        self.__session = requests.session()
        self.__url = "https://aviation.bmkg.go.id/web/metar_speci.php"
        self.__headers = {
            "User Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36"
            }
        self.__payload = {
            "agreement": "agree",
            "submit": "Serahkan"
            }
        self.__default_params = {
            "icao": "W%25",              # W%25 (all airport)                           <input>
            "sa": "yes",                 # METAR
            "sp": "yes",                 # SPECI
            "fd": "1/1/2010",            # start date                                   <input>
            "fh": "0",                   # start hour
            "fm": "00",                  # start minute
            "ud": "1/1/2010",            # end date                                     <input>
            "uh": "23",                  # end hour
            "um": "59",                  # end minute
            "f": "raw_format",           # raw_format / translated (radio button)
            "pn": "0",                   # default page = 0                             <input default>
            }
        self.params = self.__default_params.copy()
    
    def updateParams(self, key, value):
        if key in self.params:
            self.params[key] = str(value)
        return self.params 

    def webSession(self):
        return self.__session.post(self.__url, data=self.__payload, headers=self.__headers)
    
    def metarSession(self):
        return self.__session.get(self.__url, params=self.params)                       
        #sample url-path: <url>?icao=W%25&sa=yes&sp=yes&fd=17%2F08%2F2023&fh=10&fm=15&ud=17%2F08%2F2023&uh=16&um=15&f=raw_format&pn=0