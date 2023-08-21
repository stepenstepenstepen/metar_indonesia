function UpdateMetarData(listAirport)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
%Declaring constants
RAW_DATA_PATH  = '../Raw Data/';
RAW_DATA_EXT   = '.txt';
WEB_ADDRESS    = 'https://aviation.bmkg.go.id/web/metar_speci.php?';
WEB_OPT        = weboptions('KeyName','Cookie',...
                            'KeyValue',fileread('cookie.txt'),...
                            'Timeout',300);
FORMAT_NUMSTR  = '%02.f';
DELIMITER_DASH = '%2F';
DATE_START     = datetime(2010,01,01);
HOUR_START     = [0,6,12,18];
MINUTE_START   = 0;
HOUR_END       = [5,11,17,23];
MINUTE_END     = 59;
% %Declaring default input arguments (for debugging)
% listAirport = {'WAHS'}
%Getting list of all airports in the raw database (if no input given)
if nargin ==0
    listDataRaw  = dir([RAW_DATA_PATH,'*',RAW_DATA_EXT]);
    listAirport  = cell(size(listDataRaw));
    for id = 1:numel(listDataRaw)
        listAirport{id}  = strtok(listDataRaw(id).name,'.');
    end
end
%Checking if the airport exists in the raw database & its lastest date
listDateLast = NaT(size(listAirport));
for id = 1:numel(listAirport)
    if exist([RAW_DATA_PATH,listAirport{id},RAW_DATA_EXT],'file')
        fileStruct = dir([RAW_DATA_PATH,listAirport{id},RAW_DATA_EXT]);
        listDateLast(id) = GetLastDate([fileStruct.folder,...
                                        filesep,...
                                        fileStruct.name]);
    else
        listDateLast(id) = DATE_START - days(1);
    end
end

%%
%Getting METAR data for each airport in the raw database
for id_airport = 1:numel(listAirport)
%Checking if the current airport data is already up-to-date
if (listDateLast(id_airport) < datetime('today'))
    %Opening airport raw data text file (for append)
    fileId      = fopen([RAW_DATA_PATH,...
                         listAirport{id_airport},...
                         RAW_DATA_EXT],...
                        'a');
    %Declaring the first date for data retrieval
    dateCursor = listDateLast(id_airport) + days(1);
    while dateCursor < datetime('today')
        %Displaying data retrieval progress
        disp(['Reading METAR for ',listAirport{id_airport},...
              ' at ',datestr(dateCursor)]);
        %Marking iteration time
        tic;
        %Parsing date of interest into individual time unit
        cursorYear  = year(dateCursor);
        cursorMonth = month(dateCursor);
        cursorDay   = day(dateCursor);
        %Preallocating cell for data_text string element
        dataRaw = cell(0,1);
        %Getting METAR data for every 6 hours interval
        for id = 1:numel(HOUR_START)
            %Sending http request
            htmlOutput = webread([WEB_ADDRESS,...
                                  'icao=',listAirport{id_airport},'&',...
                                  'sa=yes&',...
                                  'sp=yes&',...
                                  'fd=',num2str(cursorDay,...
                                                FORMAT_NUMSTR),...
                                        DELIMITER_DASH,...
                                        num2str(cursorMonth,...
                                                FORMAT_NUMSTR),...
                                        DELIMITER_DASH,...
                                        num2str(cursorYear),'&',...
                                  'fh=',num2str(HOUR_START(id)),'&'...
                                  'fm=',num2str(MINUTE_START),'&',...
                                  'ud=',num2str(cursorDay,...
                                                FORMAT_NUMSTR),...
                                        DELIMITER_DASH,...
                                        num2str(cursorMonth,...
                                                FORMAT_NUMSTR),...
                                        DELIMITER_DASH,...
                                        num2str(cursorYear),'&',...
                                  'uh=',num2str(HOUR_END(id)),'&'...
                                  'um=',num2str(MINUTE_END),'&',...
                                  'f=raw_format'],...
                                 WEB_OPT);
            %Checking for possible failed data retrieval due to cookie
            if contains(htmlOutput,'Saya setuju')
                error('Cookie rejected! Metar retrieval failed!');
            end
            %Parsing and storing data text string
            dataTemp = regexp(string(htmlOutput),...
                              ['<span class="data_text">',...
                               '(?<target>.*?)',...
                               '</span>'],...
                              'tokens')';
            if ~isempty(dataTemp)
                dataRaw = [dataRaw;dataTemp(end:-1:1)];
            end
        end
        %Displaying number of metar data retrieved
        disp(['Number of METAR string retrieved: ',...
              num2str(numel(dataRaw))]);
        %Writing metar string into output file
        for id = 1:numel(dataRaw)
            fprintf(fileId,'%s\n',...
                    strrep(strcat(datestr(dateCursor),'<br>',dataRaw{id}),...
                           '<br>',' '));
        end
        %Moving date of interest by one day
        dateCursor = dateCursor + days(1);
        %Counting iteration time
        toc;
    end
    %Closing text file
    fclose(fileId);
end
end

function dateLast = GetLastDate(textfile)
    %Opening text file
    fileId = fopen(textfile);
    %Getting the last line in the text file
    while 1
        lineCurrent = fgetl(fileId);
        if ~ischar(lineCurrent)
            break;
        end
        lineLast = lineCurrent;
    end
    if ~exist('lineLast','var')
        lineLast = '';
    end
    %Closing text file
    fclose(fileId);
    %Getting last date
    dateLast = datetime(strtok(lineLast,' '));
end

end