%clc;
clear;
close;
% declare variables
N = 256;
M = 100;
P = 20;
% import the training data from data files
[training_audio,fs] = getAudioFiles();

% get the filterband coeff's
filterbank_coeff = melfb(P, N, fs);
mel_n = 1 + floor(N/2);

% precompute the Hamming window
window = 0.54-0.46.*cos(2*pi*[0:1:N-1]./(N-1));
for i = 1:1:length(training_audio)
    
    frame_beginning = 1:N-M:length(training_audio{i})-N;
    frame_end = frame_beginning + N;
    %plot(window)
    for j = 1:1:length(frame_beginning)
        %create the frames
        frames1{i,j} = training_audio{i}(frame_beginning(j):frame_end(j)-1,:)';
        % window each frame
        frames2{i,j} =window.*frames1{i,j};
        % take FFT and absolute value
        frames3{i,j} = abs(fft(frames2{i,j},N));
        % get the mel spectrum coeff (P amount per frame)
        frames4{i,j} = filterbank_coeff * abs(frames3{i,j}(1:mel_n)).^2';
        % get mel cepstrum: DCT of the LOG of each spectrum coeff
        % ignore the first element (P-1 amount per frame)
        frames5{i,j} = dct(log10(frames4{i,j}));
        frames5{i,j} = frames5{i,j}(2:end);


    end

end
    % average
% subplot(2,1,1)
% stem(frames2{1,40})
% subplot(2,1,2)
% stem(frames3{1,40})

% subplot(3,1,1)
% plot(frames1{40})
% subplot(3,1,2)
% plot(frames2{40})
% subplot(3,1,3)
% plot(frames3{40})
% z = melfb(P, N, fs);
%  plot(linspace(0, (12500/2), 129), z'),
%  title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');
