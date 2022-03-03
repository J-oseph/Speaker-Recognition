%code
clc;
clear;
close;
N = 256;
M = 100;
P = 20;

[s1_audio,fs] = audioread('C:\Users\joe\Documents\GitHub\Speaker-Recognition\Speaker-Recognition\Data\Training_Data\s1.wav');

m = melfb(P, N, fs);
mel_n = 1 + floor(N/2);

n1 = 1:N-M:length(s1_audio)-N;
n2 = n1+N;
window = 0.54-0.46.*cos(2*pi*[0:1:N-1]./(N-1));
%plot(window)
for i = 1:1:length(n1)
    s1_frames{i} = s1_audio(n1(i):n2(i)-1,:); %get the frames
    s1_frames1{i} = downsample(conv(s1_frames{i},window),2); % window each frame (downsample bc its too long)
    s1_frames2{i} = abs(fft(s1_frames1{i},N)); % take the fft
    for j = 1:1:P
        z{i,j} = m .* abs(s1_frames2{i}(1:mel_n)).^2;
    end
end
subplot(3,1,1)
plot(s1_frames{40})
subplot(3,1,2)
plot(s1_frames1{40})
subplot(3,1,3)
plot(s1_frames2{40})
close;
% z = melfb(P, N, fs);
%  plot(linspace(0, (12500/2), 129), z'),
%  title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');