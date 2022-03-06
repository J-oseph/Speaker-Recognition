function [g,fs] = getAudioFiles()
path = getPath();
% path is specific for each computer
% should be something like 'C:\....\Speaker-Recognition'
subpath = '/Data/Training_Data/s';
ext = '.wav';
[audio,fs] = audioread(strcat(path,subpath,int2str(1),ext));
g = {audio(:,1)};
for index = 2:1:11
    [audio,fs] = audioread(strcat(path,subpath,int2str(index),ext));
    g{end+1}=(audio(:,1));
end