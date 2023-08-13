function dataQnh = ParseMetarQnh(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('WIII.txt','Delimiter','');
%Declaring constants
PATTERN  = '(A|Q)(| )[0-9](| )[0-9](| )[0-9](| )[0-9]';
UNIT_SI  = 'hPa';
UNIT_IMP = 'inHg';

%% Getting METAR string containing temperature data
%Finding string pattern for temperature data in METAR string
strQnh = regexp(strMetar,PATTERN,'match','once');
%Checking for failed matching attempt from regexp
indexEmpty = cellfun(@isempty,strQnh);
if sum(indexEmpty)~=0
    warning(['Failed to find altimeter setting data for ',...
             num2str(sum(indexEmpty)),...
             ' lines of METAR data!']);
	posEmpty = find(indexEmpty);
end
%Cleaning up matched temperature string
strQnh = erase(strQnh,' ');

%% Getting QNH data from matched QNH string
%Preallocating array for QNH data
qnhValue = nan(size(strMetar));
qnhUnit  = cell(size(strMetar));
%Getting value from the designated positions in QNH string
for id_line = 1:numel(strMetar)
    qnhValue(id_line) = str2double(strQnh{id_line}(2:end));
    if ~isempty(strQnh{id_line})
        switch strQnh{id_line}(1)
            case 'Q'
                qnhUnit{id_line} = UNIT_SI;
            case 'A'
                qnhUnit{id_line} = UNIT_IMP;
        end
    end
end
%Concatenating data into one output table
dataQnh = table(qnhValue,qnhUnit);

end