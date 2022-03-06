function [g,fs] = getTestAudioFiles()
path = '/Users/ansongrover/Documents/GitHub/Speaker-Recognition';
% path is specific for each computer
% should be something like 'C:\....\Speaker-Recognition'
subpath = '/Data/Test_Data/s';
ext = '.wav';
[audio,fs] = audioread(strcat(path,subpath,int2str(1),ext));
g = {audio(:,1)};
for index = 2:1:8
    [audio,fs] = audioread(strcat(path,subpath,int2str(index),ext));
    g{end+1}=(audio(:,1));
end