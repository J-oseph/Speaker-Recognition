function g = getStoltenbergAudio(g, path, type)
if (strcmp(type,'test'))
    subpath = '/Data/Test_Data/stolt';

    for i = 1:6
        ext = strcat(num2str(i),'.wav');
        [audio,Rate] = audioread(strcat(path,subpath,ext));
        [Num,Den] = rat(12500/Rate);
        audio = resample(audio,Num,Den);
        g = [g, audio];
    end
elseif (strcmp(type,'train'))
    subpath = '/Data/Training_Data/stolt_train.wav';
    [audio,Rate] = audioread(strcat(path,subpath));
    [Num,Den] = rat(12500/Rate);
    audio = resample(audio,Num,Den);
    g = [g, audio];
end
end