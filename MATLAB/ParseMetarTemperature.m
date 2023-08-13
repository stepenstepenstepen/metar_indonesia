function dataTemperature = ParseMetarTemperature(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('WIII.txt','Delimiter','');
%Declaring constants
PATTERN     = '((|M)[0-9]{2}|//)(| )/(| )((|M)[0-9]{2}|//)(?![KMG])';
PATTERN_DLM = '/';

%% Getting METAR string containing temperature data
%Finding string pattern for temperature data in METAR string
strTemperature = regexp(strMetar,PATTERN,'match','once');
%Checking for failed matching attempt from regexp
indexEmpty = cellfun(@isempty,strTemperature);
if sum(indexEmpty)~=0
    warning(['Failed to find temperature data for ',...
             num2str(sum(indexEmpty)),...
             ' lines of METAR data!']);
    posEmpty = find(indexEmpty); %For crosscheck in debugging
end
%Cleaning up matched temperature string
strTemperature = erase(strTemperature,' ');

%% Getting temperature data from matched temperature string
%Preallocating array for temperature data
temperatureAmbient  = nan(size(strMetar));
temperatureDewPoint = nan(size(strMetar));
%Getting value from the designated positions in temperature string
for id_line = 1:numel(strTemperature)
    if ~isempty(strTemperature{id_line})
        %Splitting string for ambient temperature and dew point
        [strAmbient,remain] = strtok(strTemperature{id_line},PATTERN_DLM);
        strDewPoint         = remain(2:end);
        %Getting ambient temperature value
        if (numel(strAmbient) == 3) && (strAmbient(1) == 'M')
            temperatureAmbient(id_line) = ...
                str2double(strAmbient(2:end)) * -1;
        else
            temperatureAmbient(id_line) = ...
                str2double(strAmbient(1:end));
        end
        if (numel(strDewPoint) == 3) && (strDewPoint(1) == 'M')
            temperatureDewPoint(id_line) = ...
                str2double(strDewPoint(2:end)) * -1;
        else
            temperatureDewPoint(id_line) = ...
                str2double(strDewPoint(1:end));
        end
    end
end
%Concatenating data into output table
dataTemperature = table(temperatureAmbient,temperatureDewPoint);

end