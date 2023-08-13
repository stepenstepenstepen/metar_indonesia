function dataWind = ParseMetarWind(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('WIII.txt','Delimiter','');
%Declaring constants
PATTERN_1     = '([0-9]{3}|VRB)(|/|//)[0-9]{2}(|G[0-9]{2})(KT|MPS)';
PATTERN_2     = '[0-9]{3}.[0-9]{3}';
PATTERN_DLM   = '/';
PATTERN_GUST  = 'G';
PATTERN_UNIT1 = 'KT';
PATTERN_UNIT2 = 'MPS';
UNIT_WIND_SI  = 'knots';
UNIT_WIND_IMP = 'm/s';

%% Getting METAR string containing wind data
%Finding main string pattern for wind data in METAR string
strWind1 = regexp(strMetar,PATTERN_1,'match','once');
strWind2 = regexp(strMetar,PATTERN_2,'match','once');
%Cleaning up matched wind string (removing delimiter)
strWind1 = erase(strWind1,PATTERN_DLM);
%Checking for failed matching attempt from regexp
indexEmpty1 = cellfun(@isempty,strWind1);
if sum(indexEmpty1)~=0
    warning(['Unable to find wind data for ',...
             num2str(sum(indexEmpty1)),...
             ' lines of METAR data!']);
    posEmpty1 = find(indexEmpty1); %For crosscheck in debugging
end
indexEmpty2 = cellfun(@isempty,strWind2);
if sum(indexEmpty2)~=0
    warning(['Unable to find wind variability data for ',...
             num2str(sum(indexEmpty2)),...
             ' lines of METAR data!']);
    posEmpty2 = find(indexEmpty2); %For crosscheck in debugging
end

%% Getting wind data from matched wind string
%Preallocating array for wind data
windDirAvg = nan(size(strMetar));
windSpeed  = nan(size(strMetar));
windGust   = nan(size(strMetar));
windDirMin = nan(size(strMetar));
windDirMax = nan(size(strMetar));
windUnit   = cell(size(strMetar));
%Getting value from the designated positions in wind string
for id_line = 1:numel(strWind1)
    if ~isempty(strWind1{id_line})
        windDirAvg(id_line) = str2double(strWind1{id_line}(1:3));
        windSpeed(id_line)  = str2double(strWind1{id_line}(4:5));
        if contains(strWind1{id_line},PATTERN_GUST)
            windGust(id_line) = str2double(strWind1{id_line}(7:8));
        end
        if contains(strWind1{id_line},PATTERN_UNIT1)
            windUnit{id_line} = UNIT_WIND_SI;
        elseif contains(strWind1{id_line},PATTERN_UNIT2)
            windUnit{id_line} = UNIT_WIND_IMP;
        end
    end
    if ~isempty(strWind2{id_line})
        windDirMin(id_line) = str2double(strWind2{id_line}(1:3));
        windDirMax(id_line) = str2double(strWind2{id_line}(5:7));
    end
end
% %Getting value from the designated positions in wind string
% indexEmpty = cellfun(@isempty,windString1);
% windDirAvg(~indexEmpty) = cellfun(@(x) str2double(x(1:3)),...
%                                   windString1(~indexEmpty),...
%                                   'UniformOutput',1);
% windSpeed(~indexEmpty)  = cellfun(@(x) str2double(x(4:5)),...
%                                   windString1(~indexEmpty),...
%                                   'UniformOutput',1);
%Concatenating data into one output table
dataWind = table(windDirAvg,windSpeed,windGust,...
                 windDirMin,windDirMax,windUnit);

end