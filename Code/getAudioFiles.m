function [g,fs] = getAudioFiles(path, type)
N = 1;
subpath = '';
ext = '.wav';
if (strcmp(type,'test'))
    subpath = '/Data/Test_Data/s';
    ext = '.wav';
    N = 8;
elseif (strcmp(type,'train'))
    subpath = '/Data/Training_Data/s';
    ext = '.wav';
    N = 11;
elseif (strcmp(type,'notched'))
    subpath = '/Data/Test_Data/s';
    ext = 'filt.wav';
    N = 8;    
end
[audio,fs] = audioread(strcat(path,subpath,int2str(1),ext));
g = {audio(:,1)};
for index = 2:1:N
    [audio,fs] = audioread(strcat(path,subpath,int2str(index),ext));
    g{end+1}=(audio(:,1));
end

% adding our voices
g = getMemberAudio(g, path,type);
% adding extra voices   FROM https://www.kaggle.com/kongaevans/speaker-recognition-dataset
g = getMandelaAudio(g, path,type);
g = getThatcherAudio(g, path,type);
g = getStoltenbergAudio(g, path,type);
end