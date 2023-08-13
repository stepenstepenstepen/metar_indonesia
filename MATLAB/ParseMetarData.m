%Resetting MATLAB environment
close all;
clear;
clc;

%Declaring constant
% PREFIX = {'RRA';'RRB';'RRC';'CCA';'CC}

inputFile = 'WAAA.txt';

fileId    = fopen(inputFile);


id = 1;
while 1
    lineAll      = fgetl(fileId);
    if lineAll == -1
        break
    end
    elementWindInfo = regexp(lineAll,'.....KT','match');
    infoWind{id} = elementWindInfo{1};
    
    id = id + 1;
end