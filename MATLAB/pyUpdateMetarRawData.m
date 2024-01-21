function pyUpdateMetarRawData(airportIcao,dateEnd,dateStart)

%% Declaring constants and default input arguments
%Checking whether this m-file is run as script (for debugging) or function
isRunAsScript = false;
try
    nargin;
catch
    %Resetting MATLAB environment
    clear;
    clc;
    %Declaring that m-file is run as script
    isRunAsScript = true;
end
%Checking for installed Python & requests module
%[TODO]
%Declaring constants
RAW_DATA_PATH    = '../Raw Data/';
RAW_DATA_EXT     = '.txt';
DEFAULT_DATE  = datetime(2010,01,01);
%Processing input arguments based what the m-file is run as
if ~isRunAsScript
    %Checking & assigning default input arguments (function)
    switch nargin
        case 0
            %Throwing not enough input arguments error
            errorStruct.message = 'Not enough input arguments.';
            errorStruct.identifier = 'MATLAB:minrhs';
            error(errorStruct);
        case 1
            %Declaring default input argument for dateEnd
            dateEnd   = datetime('today');
            %Declaring default input argument for dateStart
            if exist([RAW_DATA_PATH,airportIcao,RAW_DATA_EXT],'file')
                fileStruct = dir([RAW_DATA_PATH,airportIcao,RAW_DATA_EXT]);
                dateLast   = GetLastDate([fileStruct.folder,...
                                          filesep,...
                                          fileStruct.name]);
                %Anticipating empty database
                if (dateLast == datetime(1,1,1))
                    dateStart  = DEFAULT_DATE;
                %Declaring starting date based on database content
                else
                    dateStart  = dateLast + days(1);
                end
            else
                dateStart  = DEFAULT_DATE;
            end
        case 2
            %Declaring default input argument for dateStart
            if exist([RAW_DATA_PATH,airportIcao,RAW_DATA_EXT],'file')
                fileStruct = dir([RAW_DATA_PATH,airportIcao,RAW_DATA_EXT]);
                dateLast   = GetLastDate([fileStruct.folder,...
                                          filesep,...
                                          fileStruct.name]);
                %Declaring starting date based on database content
                if (dateLast ~= datetime(1,1,1))
                    dateStart  = dateLast + days(1);
                end
            end
        case 3
            %Checking input argument dateEnd for correct data type
            %[TODO]
            %Checking input argument dateEnd for correct array size
            %[TODO]
            %Checking input argument dateEnd for consistency with dateStart
            %[TODO]
        otherwise
            %Throwing too input arguments error
            errorStruct.message = 'Too many input arguments.';
            errorStruct.identifier = 'MATLAB:maxrhs';
            error(errorStruct);
    end
    if nargin >= 1
        %Checking input argument airportIcao for correct data type
        %[TODO]
        %Checking input argument airportIcao for correct array size
        %[TODO]
    end
    if nargin >=2
        %Checking input argument dateStart for correct data type
        %[TODO]
        %Checking input argument dateStart for correct array size
        %[TODO]
    end
else
    %Assigning default inputs (script)
end

%% Preparing session for data extraction
% %Creating session object
% webSession = py.requests.session();
% %Displaying data retrieval progress
% disp('Initiating web session');
% %Sending HTML request to clear agreement page
% tic;
% post(webSession,WEB_ADDRESS,...
%     pyargs('data',RQ_PAYLOAD,...
%     'headers',RQ_HEADER));
% toc;
%

%% Performing iteration to extract METAR data daily
%Opening airport raw data text file in append mode
fileId     = fopen([RAW_DATA_PATH,airportIcao,RAW_DATA_EXT],'a');
%Initiating date cursor
dateCursor = dateStart;
%Performing loop
while dateCursor <= dateEnd
%     %Preallocating cell for daily data collection
%     strMetar   = cell(0,1);
%     %Displaying data retrieval progress
%     disp(['Reading METAR for ',airportIcao,' at ',datestr(dateCursor)]);
%     %Marking the start of iteration timer
%     tic;
%     %Updating request parameters
%     rqParam = RQ_PARAM_DEFAULT;
%     update(rqParam,...
%            py.dict(pyargs(RQ_PARAM_VARKEY{1},airportIcao)));
%     update(rqParam,...
%            py.dict(pyargs(RQ_PARAM_VARKEY{2},...
%                           datestr(dateCursor,FORMAT_DATESTR))));
%     update(rqParam,...
%            py.dict(pyargs(RQ_PARAM_VARKEY{3},...
%                           datestr(dateCursor,FORMAT_DATESTR))));
%     %Sending HTML request to get METAR data
%     response = get(webSession,WEB_ADDRESS,pyargs('params',rqParam));
% 	htmlOut  = char(response.content);
%     %Parsing HTML output and checking for multiple page output
%     dataTempFirst = regexp(htmlOut,...
%                            ['<span class="data_text">',...
%                             '(?<target>.*?)',...
%                             '</span>'],...
%                            'tokens');
%     nPage         = count(htmlOut,'<option value="/web/metar')/2;
%     %Converting nested cell to single layer cell & appending date text
%     for id = 1:numel(dataTempFirst)
%         dataTempFirst{id} = dataTempFirst{id}{1};
%     end
%     dataTempFirst = strrep(...
%                            strcat(datestr(dateCursor),'<br>',dataTempFirst),...
%                            '<br>',' ');
%     %Anticipating multiple page output
%     for id_page = nPage:-1:2
%         %Updating request parameters for multiple page output
%         update(rqParam,...
%                py.dict(pyargs(RQ_PARAM_VARKEY{4},...
%                               num2str(id_page-1))));
%         %Sending HTML request to get METAR data
%         response = get(webSession,WEB_ADDRESS,...
%                        pyargs('params',rqParam));
%         htmlOut  = char(response.content);
%         %Parsing HTML output
%         dataTemp = regexp(htmlOut,...
%                           ['<span class="data_text">',...
%                            '(?<target>.*?)',...
%                            '</span>'],...
%                           'tokens');
%         %Converting nested cell to single layer cell & appending date text
%         for id = 1:numel(dataTemp)
%             dataTemp{id} = dataTemp{id}{1};
%         end
%         dataTemp = strrep(strcat(datestr(dateCursor),'<br>',dataTemp),...
%                           '<br>',' ');
%         %Appending data collection cell
%         strMetar = [strMetar;dataTemp(end:-1:1)'];
%     end
%     %Appending the first data to data collection cell
%     strMetar = [strMetar;dataTempFirst(end:-1:1)'];
%     %Marking the end of iteration timer
%     toc;
    %Using pyGetMetar to get raw data string
    strMetar = pyGetMetarData(airportIcao,dateCursor,dateCursor);
    %Writing raw data into output file
    for id = 1:numel(strMetar)
        fprintf(fileId,'%s\n',strMetar{id});
    end
    %Advancing iteration variable
    dateCursor = dateCursor + days(1);
end
%Closing text file
fclose(fileId);

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
        dateLast = datetime(1,1,1); %Workaround
        %dateLast = NaT; %Reserved for MATLAB version with isnat function
    else
        dateLast = datetime(strtok(lineLast,' '));
    end
end