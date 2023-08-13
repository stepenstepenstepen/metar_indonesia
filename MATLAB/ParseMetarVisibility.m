function dataVisibility = ParseMetarVisibility(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('WIII.txt','Delimiter','');
%Declaring constants
PATTERN_SI    = ' ([0-9]{4}) ';
PATTERN_IMP   = ' (|([0-9])|([0-9]{2}))(|-)(|([0-9]/(2|4|8|16)))SM ';
PATTERN_CAVOK = ' CAVOK ';
PATTERN_DLM1  = '-';
PATTERN_DLM2  = '/';
UNIT_SI       = 'meter';
UNIT_IMP      = 'statute mile';

%% Getting METAR string containing visibility data
%Checking for CAVOK message
isCavok = contains(strMetar,PATTERN_CAVOK);
%Finding main string pattern for visibility data in METAR string
strVisSi  = regexp(strMetar,PATTERN_SI,'match','once');
strVisImp = regexp(strMetar,PATTERN_IMP,'match','once');
%Cleaning up matched visibility string
strVisSi  = erase(strVisSi,' ');
strVisImp = erase(strVisImp,' ');
%Checking for failed matching attempt from regexp
indexEmpty  = ~isCavok & ...
              cellfun(@isempty,strVisSi) & ...
              cellfun(@isempty,strVisImp);
if sum(indexEmpty)~=0
    warning(['Unable to find visibility data for ',...
             num2str(sum(indexEmpty)),...
             ' lines of METAR data!']);
    posEmpty = find(indexEmpty);
end

%% Getting visibility data from matched visibility string
%Preallocating array for visibility data
visValue = nan(size(strMetar));
visUnit  = cell(size(strMetar));
%Getting value from the designated positions in visibility string
for id_line = 1:numel(strMetar)
    %Overwriting data in case of CAVOK
    if isCavok(id_line)
        visUnit{id_line}  = UNIT_SI;
        visValue(id_line) = 9999;
    %Getting non-CAVOK value
    else
        if ~isempty(strVisSi{id_line})
            visUnit{id_line}  = UNIT_SI;
            visValue(id_line) = str2double(strVisSi{id_line}(1:4));
        elseif ~isempty(strVisImp{id_line})
            visUnit{id_line}  = UNIT_IMP;
            [head,strDenum] = strtok(strVisImp{id_line}(1:end-2),...
                                     PATTERN_DLM2);
            if isempty(strDenum)
                visValue(id_line) = str2double(head);
            else
                [head,tail] = strtok(head,PATTERN_DLM1);
                if isempty(tail)
                    visValue(id_line) = str2double(head)/...
                                       str2double(strDenum(2:end));
                else
                    visValue(id_line) = str2double(head) + ...
                                       (str2double(tail(2:end))/...
                                        str2double(strDenum(2:end)));
                end
            end
        end
    end
end
%Concatenating data into output table
dataVisibility = table(visValue,visUnit);

end