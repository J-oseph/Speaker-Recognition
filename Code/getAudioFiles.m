function [g,fs] = getAudioFiles(path, type)
N = 1;
subpath = '';
ext = '.wav';
if (strcmp(type,'test'))
    subpath = '/Data/Test_Data/s';
    ext = '.wav';
%     ext = 'filt.wav';
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
if (strcmp(type,'test'))
    subpath1 = '/Data/Test_Data/';
    ext = '_test.wav';
    subpath2 = 'anson';

    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];

    subpath2 = 'joseph';

    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    %resample to 12500 hz
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];

elseif (strcmp(type,'train'))
    subpath1 = '/Data/Training_Data/';
    ext = '_train.wav';
    subpath2 = 'anson';

    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    %resample to 12500 hz
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];

    subpath2 = 'joseph';
    
    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    %resample to 12500 hz
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];
elseif (strcmp(type,'notched'))
    subpath1 = '/Data/Test_Data/';
    ext = '_notched.wav';
    subpath2 = 'anson';
    strcat(path,subpath1,subpath2,ext)
    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    %resample to 12500 hz
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];

    subpath2 = 'joseph';
    
    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    %resample to 12500 hz
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];
end