function dataStation = ParseMetarStation(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('../Raw Data/WIMM.txt','Delimiter','');
%Declaring constants
PATTERN = '(METAR|SPECI) (COR |)[A-Z]{4}';

%% Getting METAR string containing station data
%Finding main string pattern for station data in METAR string
strStation = regexp(strMetar,PATTERN,'match','once');
%Checking for failed matching attempt from regexp
indexEmpty = cellfun(@isempty,strStation);
if sum(indexEmpty)~=0
    warning(['Unable to find station data for ',...
             num2str(sum(indexEmpty)),...
             ' lines of METAR data!']);
    posEmpty = find(indexEmpty); %For crosscheck in debugging
end

%% Getting station data from matched station string
% station = cellfun(@(x) x(end-4:end),strStation,'UniformOutput',false);
%Preallocating array for station data
dataStation = cell(size(strMetar));
%Getting value from the designated positions in station string
for id_line = 1:numel(strStation)
    if ~isempty(strStation{id_line})
        dataStation{id_line} = strStation{id_line}(end-3:end);
    end
end

end