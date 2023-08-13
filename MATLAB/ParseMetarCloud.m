function dataCloud = ParseMetarCloud(strMetar)

%% Declaring default input arguments and constants
% %Resetting MATLAB environment (for debugging)
% clear;
% clc;
% %Declaring default input arguments (for debugging)
% strMetar = readcell('WIII.txt','Delimiter','');
%Declaring constants
DICTIONARY = {'SKC',0;...
              'CLR',0;...
              'FEW',2;...
              'SCT',4;...
              'BKN',7;...
              'OVC',8};
N_CLOUDDATA = 10;
%Stitching dictionary for regular expression (regexp) pattern
PATTERN = '(';
for id_element = 1:size(DICTIONARY,1)
    PATTERN = strcat(PATTERN,DICTIONARY{id_element,1});
    if id_element ~= size(DICTIONARY,1)
        PATTERN = strcat(PATTERN,'|');
    end
end
PATTERN = strcat(PATTERN,')[0-9]{3}(CB|)');
%TODO: pattern for NCD and NSC
%TODO: anticipation for CAVOK tag

%% Getting METAR string containing visibility data
%Removing prefix in front of METAR/SPECI text and suffix after RMK text
startIndex = regexp(strMetar,'METAR|SPECI','once');
endIndex   = regexp(strMetar,'(RMK|TEMPO|BECMG)','once');
for id = 1:numel(strMetar)
    if isempty(endIndex{id})
        strMetar{id} = strMetar{id}(startIndex{id}:end);
    else
        strMetar{id} = strMetar{id}(startIndex{id}:endIndex{id}-1);
    end
end
%Finding main string pattern for cloud data in METAR string
strCloud = regexp(strMetar,PATTERN,'match');
%Checking for failed matching attempt from regexp
indexEmpty = cellfun(@isempty,strCloud);
if sum(indexEmpty)~=0
    warning(['Unable to find wind data for ',...
             num2str(sum(indexEmpty)),...
             ' lines of METAR data!']);
    posEmpty = find(indexEmpty); %For crosscheck in debugging
end

%% Getting cloud data from matched cloud string
%Checking for maximum number of cloud data (for debugging)
nCloudData = (cellfun(@numel,strCloud));
%Preallocating array for cloud data
cloudOcta = nan(size(strMetar,1),N_CLOUDDATA);
cloudBase = nan(size(strMetar,1),N_CLOUDDATA);
cloudCb   = false(size(strMetar,1),N_CLOUDDATA);
%Getting value from the designated positions in weather string
for id_line = 1:numel(strCloud)
    for id_cloud = 1:numel(strCloud{id_line})
        %Getting cloud coverage in octas from dictionary
        for id_dictionary = 1:size(DICTIONARY,1)
            if strcmp(strCloud{id_line}{id_cloud}(1:3),...
                    DICTIONARY{id_dictionary,1})
                cloudOcta(id_line,id_cloud) = DICTIONARY{id_dictionary,2};
                break;
            end
        end
        %Getting cloud base
        cloudBase(id_line,id_cloud) = ...
            str2double(strCloud{id_line}{id_cloud}(4:6))*100;
        %Checking for CB mark
        if numel(strCloud{id_line}{id_cloud})==8
            cloudCb(id_line,id_cloud) = true;
        end
    end
end
%Concatenating data into one output table
dataTempo = cell(N_CLOUDDATA,1);
for id_cloud = 1:N_CLOUDDATA
    dataTempo{id_cloud} = table(cloudOcta(:,id_cloud),...
                                cloudBase(:,id_cloud),...
                                cloudCb(:,id_cloud));
	dataTempo{id_cloud}.Properties.VariableNames = ...
        {['cloudOcta',num2str(id_cloud)],...
         ['cloudBase',num2str(id_cloud)],...
         ['cloudCb',num2str(id_cloud)]};
end
dataCloud = horzcat(dataTempo{:});

end