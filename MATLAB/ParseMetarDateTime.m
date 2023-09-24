function dataDateTime = ParseMetarDateTime(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('../Raw Data/WIII.txt','Delimiter','');
%Declaring constants
PATTERN = ' [0-9]{6}Z ';

%% Getting METAR string containing datetime data
%Finding main string pattern for date & time data in METAR string
strDate = strtok(strMetar,' ');
strTime = regexp(strMetar,PATTERN,'match','once');
%Checking for failed matching attempt from regexp
indexEmpty1 = cellfun(@isempty,strDate);
if sum(indexEmpty1)~=0
    warning(['Unable to find date data for ',...
             num2str(sum(indexEmpty1)),...
             ' lines of METAR data!']);
    posEmpty1 = find(indexEmpty1); %For crosscheck in debugging
end
indexEmpty2 = cellfun(@isempty,strTime);
if sum(indexEmpty2)~=0
    warning(['Unable to find time data for ',...
             num2str(sum(indexEmpty2)),...
             ' lines of METAR data!']);
    posEmpty2 = find(indexEmpty2); %For crosscheck in debugging
end

%% Getting datetime data from matched station string
%Getting value from the designated positions in date & time string
dataDate = datetime(strDate,'InputFormat','dd-MMM-yyyy');
for id_line = 1:numel(strMetar)
    if ~isempty(strTime{id_line})
        strTime{id_line} = [strTime{id_line}(end-5:end-4),...
                            ':',...
                            strTime{id_line}(end-3:end-2)];
    else
        strTime{id_line} = '';
    end
end
dataTime = duration(strTime,'InputFormat','hh:mm');
%Concatenating data into one variable
dataDateTime = dataDate + dataTime;

end