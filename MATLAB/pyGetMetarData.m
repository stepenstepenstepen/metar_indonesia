function metarStr = pyGetMetarData(airportIcao,dateStart,dateEnd)

%% Declaring constants and default input argument
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
WEB_ADDRESS      = ['https://aviation.bmkg.go.id/web/metar_speci.php',...
                    '?old=v1'];
RQ_HEADER        = py.dict(...
                       pyargs('User Agent',...
                              ['Mozilla/5.0',...
                               ' (Windows NT 10.0; Win64; x64)',...
                               ' AppleWebKit/537.36',...
                               ' (KHTML, like Gecko)',...
                               ' Chrome/116.0.0.0 Safari/537.36']));
RQ_PAYLOAD       = py.dict(pyargs('agreement','agree',...
                                  'submit','Serahkan'));
RQ_PARAM_VARKEY  = {'icao','fd','ud','pn'};
RQ_PARAM_DEFAULT = py.dict(pyargs(RQ_PARAM_VARKEY{1}, 'WXXX',...
                                  'sa', 'yes',...
                                  'sp', 'yes',...
                                  RQ_PARAM_VARKEY{2}, '01/01/2010',...
                                  'fh', '00',...
                                  'fm', '00',...
                                  RQ_PARAM_VARKEY{3}, '01/01/2010',...
                                  'uh', '23',...
                                  'um', '59',...
                                  'f', 'raw_format',...
                                  RQ_PARAM_VARKEY{4},'0'));
DEFAULT_AIRPORT  = 'WIII';
DEFAULT_TIME     = datetime('now','TimeZone','UTC');
FORMAT_DATESTR   = 'dd/mm/yyyy';
%Processing input arguments based what the m-file is run as
if ~isRunAsScript
    %Checking & assigning default input arguments (function)
    switch nargin
        case 0
%             %Throwing not enough input arguments error
%             errorStruct.message = 'Not enough input arguments.';
%             errorStruct.identifier = 'MATLAB:minrhs';
%             error(errorStruct);
            airportIcao = DEFAULT_AIRPORT;
            dateStart   = dateshift(DEFAULT_TIME,'start','day');
            dateEnd     = DEFAULT_TIME;
        case 1
            dateStart = dateshift(DEFAULT_TIME,'start','day');
            dateEnd   = DEFAULT_TIME;
        case 2
            dateStart = dateshift(dateStart,'start','day');
            dateEnd   = dateStart;
        case 3
            dateStart = dateshift(dateStart,'start','day');
            dateEnd   = dateshift(dateEnd,'start','day');
            %Checking input argument dateEnd for correct data type
            %[TODO]
            %Checking input argument dateEnd for correct array size
            %[TODO]
            %Checking input argument dateEnd for consistency with dateStart
            %[TODO]
        otherwise
            %Throwing too many input arguments error
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
    airportIcao = DEFAULT_AIRPORT;
    dateStart   = dateshift(DEFAULT_TIME,'start','day');
    dateEnd     = DEFAULT_TIME;
end

%% Preparing session for data extraction
%Checking if a web session is already exists in the workspace
try
    metarWebSession = evalin('base','metarWebSession');
catch
    %[TODO]
end
%Creating session object and initiating connection
if ~exist('metarWebSession','var')
    %Creating session object
    metarWebSession = py.requests.session();
    %Displaying data retrieval progress
    disp('Initiating web session');
    %Sending HTML request to clear agreement page
    tic;
    post(metarWebSession,WEB_ADDRESS,...
        pyargs('data',RQ_PAYLOAD,...
        'headers',RQ_HEADER));
    toc;
    %Sending session object to workspace to be reused
    assignin('base','metarWebSession',metarWebSession);
end

%% Performing iteration to extract METAR data daily
%Preallocating cell for data collection
metarStr = cell(0,1);
%Getting METAR data for each single day
dateCursor = dateStart;
while dateCursor <= dateEnd
    %Displaying data retrieval progress
    disp(['Reading METAR for ',airportIcao,' at ',datestr(dateCursor)]);
    %Marking the start of iteration timer
    tic;
    %Updating request parameters
    rqParam = RQ_PARAM_DEFAULT;
    update(rqParam,...
           py.dict(pyargs(RQ_PARAM_VARKEY{1},airportIcao)));
    update(rqParam,...
           py.dict(pyargs(RQ_PARAM_VARKEY{2},...
                          datestr(dateCursor,FORMAT_DATESTR))));
    update(rqParam,...
           py.dict(pyargs(RQ_PARAM_VARKEY{3},...
                          datestr(dateCursor,FORMAT_DATESTR))));
	update(rqParam,...
           py.dict(pyargs(RQ_PARAM_VARKEY{4},...
                          0)));
    %Sending HTML request to get METAR data
    response = get(metarWebSession,WEB_ADDRESS,pyargs('params',rqParam));
	htmlOut  = char(response.content);
    %Parsing HTML output and checking for multiple page output
    dataTempFirst = regexp(htmlOut,...
                           ['<span class="data_text">',...
                            '(?<target>.*?)',...
                            '</span>'],...
                           'tokens');
    nPage         = count(htmlOut,'<option value="/web/metar')/2;
    %Converting nested cell to single layer cell & appending date text
    for id = 1:numel(dataTempFirst)
        dataTempFirst{id} = dataTempFirst{id}{1};
    end
    dataTempFirst = strrep(...
                        strcat(datestr(dateCursor),'<br>',...
                               dataTempFirst),...
                        '<br>',' ');
    %Anticipating multiple page output
    for id_page = nPage:-1:2
        %Updating request parameters for multiple page output
        update(rqParam,...
               py.dict(pyargs(RQ_PARAM_VARKEY{4},...
                              num2str(id_page-1))));
        %Sending HTML request to get METAR data
        response = get(metarWebSession,WEB_ADDRESS,...
                       pyargs('params',rqParam));
        htmlOut  = char(response.content);
        %Parsing HTML output
        dataTemp = regexp(htmlOut,...
                          ['<span class="data_text">',...
                           '(?<target>.*?)',...
                           '</span>'],...
                          'tokens');
        %Converting nested cell to single layer cell & appending date text
        for id = 1:numel(dataTemp)
            dataTemp{id} = dataTemp{id}{1};
        end
        dataTemp = strrep(strcat(datestr(dateCursor),'<br>',dataTemp),...
                          '<br>',' ');
        %Appending data collection cell
        metarStr = [metarStr;dataTemp(end:-1:1)'];
    end
    %Advancing iteration variable
    dateCursor = dateCursor + days(1);
    %Appending the first data to data collection cell
    metarStr = [metarStr;dataTempFirst(end:-1:1)'];
    %Marking the start of iteration timer
    toc;
end

end