function [g,fs] = getAudioFiles(type)
path = getPath();
% path is specific for each computer. Needs to go to the Repo folder
% should be something like 'C:\....\Speaker-Recognition'
N = 1;
subpath = '';
ext = '.wav';
if (strcmp(type,'test'))
    subpath = '/Data/Test_Data/s';
    N = 8;
elseif (strcmp(type,'train'))
    subpath = '/Data/Training_Data/s';
    N = 11;
end
[audio,fs] = audioread(strcat(path,subpath,int2str(1),ext));
g = {audio(:,1)};
for index = 2:1:N
    [audio,fs] = audioread(strcat(path,subpath,int2str(index),ext));
    g{end+1}=(audio(:,1));
end