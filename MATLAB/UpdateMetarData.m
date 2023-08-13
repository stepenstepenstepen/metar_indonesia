% function metarCollector = UpdateMetarDatabase()

%Declaring constants
FORMAT_NUMSTR  = '%02.f';
DELIMITER_DASH = '%2F';
WEB_ADDRESS    = 'https://aviation.bmkg.go.id/web/metar_speci.php?';
WEB_OPT        = weboptions('KeyName','Cookie',...
                            'KeyValue',fileread('cookie.txt'),...
                            'Timeout',300);
LIST_AIRPORT   = ReadLines('airport.txt');
DATE_START     = datetime(2010,01,01);
HOUR_START     = [0,6,12,18];
MINUTE_START   = 0;
HOUR_END       = [5,11,17,23];
MINUTE_END     = 59;



function cellString = ReadLines(textfile)

    %Opening access to given text file
    fileId = fopen(textfile);
    %Counting number of lines in given text file
    nLine = 0;
    while 1
        lineCurrent = fgetl(fileId);
        if ~ischar(lineCurrent)
            break;
        else
            nLine = nLine + 1;
        end
    end
    %Preallocating cell
    cellString = cell (nLine,1);
    %Reading string content on each line
    frewind;
    lineId = 0;
    while 1
        lineCurrent = fgetl(fileId);
        if ~ischar(lineCurrent)
            break;
        else
            lineId = lineId + 1;
            cellString{lineId} = lineCurrent;
        end
    end
    %Closing access to given text file
    fclose(fileId);

end
% end