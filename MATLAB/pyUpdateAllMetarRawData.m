%%

%Resetting MATLAB environment
clear;
clc;

%Declaring constants
RAW_DATA_PATH    = '../Raw Data/';
RAW_DATA_TRACKER = '_tracker.csv';

%Getting list of all airports & the last updated information
listAirports = dir([RAW_DATA_PATH,'*.txt']);

%Declaring target date
dateUpdate = datetime(2023,10,31);

%%

fileId = fopen([RAW_DATA_PATH,RAW_DATA_TRACKER],'a');
for id = 1:numel(listAirports)
    dateLast = GetLastDate([RAW_DATA_PATH,listAirports(id).name(1:4),...
                            '.txt']);
    if dateLast < dateUpdate
        disp(['Raw data for ',listAirports(id).name(1:4),...
              ' is not up-to-date.']);
        %Checking for any available data to update
        disp(['Checking for available update for ',...
              listAirports(id).name(1:4)]);
        nData = pyCheckMetarData(listAirports(id).name(1:4),...
                                 dateLast,dateUpdate);
        if nData > 10
            pyUpdateMetarRawData(listAirports(id).name(1:4),dateUpdate);
        else
            disp(['No update available for ',listAirports(id).name(1:4),...
                  '.']);
        end
    else
        disp(['Raw data for ',listAirports(id).name(1:4),...
              ' is up-to-date.']);
    end
end

%% Declaring local functions
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
    if isempty(lineLast)
        %dateLast = datetime(1,1,1); %Workaround
        dateLast = NaT; %Reserved for MATLAB version with isnat function
    else
        dateLast = datetime(strtok(lineLast,' '));
    end
end