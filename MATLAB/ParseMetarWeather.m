function dataWeather = ParseMetarWeather(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('WIII.txt','Delimiter','');
%Declaring constants
DICTIONARY_INTENSITY     = {'-','Light';...
                            '+','Heavy'};
DICTIONARY_PROXIMITY     = {'VC','InVicinity';...
                            'DSNT','Distant'};
DICTIONARY_DESCRIPTION   = {'BC','Patches';...
                            'BL','Blowing';...
                            'DR','LowDrifting';...
                            'FZ','Freezing';...
                            'MI','Shallow';...
                            'PR','Partial';...
                            'SH','Shower';...
                            'TS','Thunderstorm'};
DICTIONARY_PRECIPITATION = {'DZ','Drizzle';...
                            'GR','Hail';...
                            'GS','SmallHail';...
                            'IC','IceCrystal';...
                            'PL','IcePellet';...
                            'RA','Rain';...
                            'SG','SnowGrain';...
                            'SN','Snow';...
                            'UP','UnknownPrecipitation'};
DICTIONARY_OBSCURATION   = {'BR','Mist';...
                            'DU','WidespreadDust';...
                            'FG','Fog';...
                            'FU','Smoke';...
                            'HZ','Haze';...
                            'PY','Spray';...
                            'SA','Sand';...
                            'VA','VolcanicAsh'};
DICTIONARY_OTHER         = {'DS','DustStorm';...
                            'FC','FunnelCloud';...
                            'PO','SandWhirl';...
                            'SQ','Squall';...
                            'SS','Sandstorm'};
DICTIONARY_ALL = {DICTIONARY_INTENSITY;...
                  DICTIONARY_PROXIMITY;...
                  DICTIONARY_DESCRIPTION;...
                  DICTIONARY_PRECIPITATION;...
                  DICTIONARY_OBSCURATION;...
                  DICTIONARY_OTHER};
%Stitching dictionary for regular expression (regexp) pattern
PATTERN = '';
for id_dictionary = 1:numel(DICTIONARY_ALL)
    PATTERN = strcat(PATTERN,'(');
    for id_element = 1:size(DICTIONARY_ALL{id_dictionary},1)
        PATTERN = strcat(PATTERN,'|');
        PATTERN = strcat(PATTERN,DICTIONARY_ALL{id_dictionary}{id_element,1});
    end
    PATTERN = strcat(PATTERN,')');
end
PATTERN = [' ',PATTERN,' '];
%Generating lookup cell
N_WEATHER    = (numel(DICTIONARY_DESCRIPTION) + ...
                numel(DICTIONARY_PRECIPITATION) + ...
                numel(DICTIONARY_OBSCURATION) + ...
                numel(DICTIONARY_OTHER))/2;
DICTIONARY_LOOKUP = cell(N_WEATHER,2);
id_wx = 1;
for id_dictionary = 3:numel(DICTIONARY_ALL)
    for id_element = 1:size(DICTIONARY_ALL{id_dictionary},1)
        DICTIONARY_LOOKUP{id_wx,1} = DICTIONARY_ALL{id_dictionary}...
                                                   {id_element,1};
        DICTIONARY_LOOKUP{id_wx,2} = DICTIONARY_ALL{id_dictionary}...
                                                   {id_element,2};
        id_wx = id_wx + 1;
    end
end

%% Getting METAR string containing weather data
%Removing prefix in front of METAR/SPECI text and suffix after RMK text
startIndex = regexp(strMetar,'METAR|SPECI','once');
endIndex   = regexp(strMetar,'RMK','once');
for id = 1:numel(strMetar)
    if isempty(endIndex{id})
        strMetar{id} = strMetar{id}(startIndex{id}:end);
    else
        strMetar{id} = strMetar{id}(startIndex{id}:endIndex{id}-1);
    end
end
%Finding main string pattern for weather data in METAR string
strWeather = regexp(strMetar,PATTERN,'match','once');
%Cleaning up matched wind string
strWeather = erase(strWeather,' ');
%Checking for failed matching attempt from regexp
indexEmpty = cellfun(@isempty,strWeather);
if sum(indexEmpty)~=0
    warning(['Unable to find weather data for ',...
             num2str(sum(indexEmpty)),...
             ' lines of METAR data!']);
    posEmpty = find(indexEmpty);
end

%% Getting weather data from matched weather string
%Preallocating array for weather data
weatherBool = false(numel(strMetar),N_WEATHER);
weatherIntensity = cell(size(strMetar));
weatherProximity = cell(size(strMetar));
%Getting value from the designated positions in weather string
for id_line = 1:numel(strWeather)
    if ~isempty(strWeather{id_line})
        for id_wx = 1:N_WEATHER
            weatherBool(id_line,id_wx) = ...
                contains(strWeather{id_line},DICTIONARY_LOOKUP{id_wx,1});
        end
        weatherIntensity{id_line} = 'Moderate';
        for id = 1:size(DICTIONARY_INTENSITY,1)
            if contains(strWeather{id_line},DICTIONARY_INTENSITY{id,1})
                weatherIntensity{id_line} = DICTIONARY_INTENSITY{id,2};
            end
        end
        for id = 1:size(DICTIONARY_PROXIMITY,1)
            if contains(strWeather{id_line},DICTIONARY_PROXIMITY{id,1})
                weatherProximity{id_line} = DICTIONARY_PROXIMITY{id,2};
            end
        end
    end
end
%Concatenating data into output table
dataWeather = [array2table(weatherBool),weatherIntensity,weatherProximity];
%Renaming output table field name
label = DICTIONARY_LOOKUP(:,2);
label{end+1,1} = 'Proximity';
label{end+1,1} = 'Intensity';
dataWeather.Properties.VariableNames = label;

end