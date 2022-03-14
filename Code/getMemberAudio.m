function g = getMemberAudio(g, path, type)
if (strcmp(type,'test'))
    subpath1 = '/Data/Test_Data/';
    ext = '_test.wav';
    subpath2 = 'anson';

    [audio,Rate] = audioread(strcat(path,subpath1,subpath2,ext));
    strcat(path,subpath1,subpath2,ext)
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
end