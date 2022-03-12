%clc;
clear;
close;

%% Get mel coeffs for training data
% declare variables
N = 256;
M = 100;
P = 20;

% import the training data from data files
[training_audio,fs] = getAudioFiles('train');

%normalize audio signals - this may not be best way to normalize
for i = 1:length(training_audio)
    training_audio_norm{i} = training_audio{i}/max(training_audio{i});
end

% get the filterband coeff's
filterbank_coeff = melfb(P, N, fs);
mel_n = 1 + floor(N/2);

% precompute the Hamming window
window = 0.54-0.46.*cos(2*pi*[0:1:N-1]./(N-1));

for i = 1:1:length(training_audio)
    % i is the index of each speaker
    % calculate frame beg, end, and amount
    frame_beginning = 1:M:length(training_audio{i})-N;
    frame_end       = frame_beginning + N;
    frame_amount(i) = length(frame_beginning);

    for j = 1:1:frame_amount(i)
        %create the frames
        frames1{i,j} = training_audio_norm{i}(frame_beginning(j):frame_end(j)-1,:)';
        % window each frame
        frames2{i,j} = window.*frames1{i,j};
        % take FFT and absolute value
        frames3{i,j} = abs(fft(frames2{i,j},N));
        % get the mel spectrum coeff (P amount per frame)
        frames4{i,j} = filterbank_coeff * frames3{i,j}(1:mel_n).^2';
        % get mel cepstrum: DCT of the LOG of each spectrum coeff
        frames5{i,j} = dct(log10(frames4{i,j})); 
        % ignore the first element (P-1 amount per frame)
        frames5{i,j} = frames5{i,j}(2:end);
    end
end

%% LBG

%Parameters
thresh = .001; %thresh*100 is allowed percent error change 
epsilon = .01; %splitting parameter
codeword_lim = 8; %maximum number of centroids

for i = 1:length(training_audio) %loop thru speakers
    % convert cell array to matrix, index 1 is mel coeff number, index 2 is frame
    mel_mat = cell2mat(frames5(i,:)); 
    % column vector, each entry is sum of mel coeffs across frames
    mel_avg = sum(mel_mat,2)/frame_amount(i);
    %define centroid cell array, indexed by speaker, contains matrix with 
    %1st index mel coeff number, and 2nd index is centroid number
    centroids{i} = mel_avg;
    
    while size(centroids{i},2) < codeword_lim
        % split centroids 
        centroids{i} = [centroids{i}*(1+epsilon), centroids{i}*(1-epsilon)];
       
        %reset error 
        err_new = 999;
        err_old = 1; 
        
        while abs((err_old-err_new)/err_old) > thresh %recompute centroids until error threshold is met
        
        %store previous error
        err_old = err_new;    
        
        %initialize cell array to store frame ids for each centroid/empty old data
        for k = 1:size(centroids{i},2)%for each centroid
            centroid_frames{k} = [];
        end
        
        %compute distance of each frame vector to centroids and determine closer centroid     
        d = disteu(mel_mat,centroids{i}); %d is array giving distance with 1st index frame id and second index centroid id
        [~,I] = min(d,[],2); %I is column vector indexed by frame id, value stored is id of the nearest centroid to that frame
         
        %assign to each centroid, frames which are closest
        for  j = 1:frame_amount(i) %for each frame
              centroid_frames{I(j)} = [centroid_frames{I(j)};j]; 
              %go to index I(j) (centroid id) and append j (frame id) to what is stored there
        end
        
        %take assigned frames and recompute each centroid
        for k = 1:size(centroids{i},2) %for each centroid
            for n = 1:P-1 %for each mel coefficient
                running_total = 0; %initialize variable to find sum
                for m = 1:size(centroid_frames{k},1)%for each frame assigned to that centroid
                    running_total = mel_mat(n,centroid_frames{k}(m))+running_total;
                end
                centroids{i}(n,k) = running_total/size(centroid_frames{k},1);
            end
        end
        
        %find average distance to determine error
        d = disteu(mel_mat,centroids{i});
        err_new = sum(min(d,[],2));%total distance between all frames
        %and their nearest centroid
        end
    end
end

%Key output is centroids{i} indexed by speaker, each entry is 
%a 8 x 19 set of centroids which represents the 19 coordinates of each of
%8 codewords for each speaker
%% Get mel coeffs for test audio

[test_audio, fs] = getAudioFiles('test');

%normalize audio signals - this may not be best way to normalize
for i = 1:length(test_audio)
    test_audio_norm{i} = test_audio{i}/max(test_audio{i});
end

for i = 1:1:length(test_audio)
    % i is the index of each speaker
    % calculate frame beg, end, and amount
    frame_beginning = 1:M:length(test_audio{i})-N;
    frame_end       = frame_beginning + N;
    frame_amount(i) = length(frame_beginning);

    for j = 1:1:frame_amount(i)
        %create the frames
        framest1{i,j} = test_audio_norm{i}(frame_beginning(j):frame_end(j)-1,:)';
        % window each frame
        framest2{i,j} = window.*framest1{i,j};
        % take FFT and absolute value
        framest3{i,j} = abs(fft(framest2{i,j},N));
        % get the mel spectrum coeff (P amount per frame)
        framest4{i,j} = filterbank_coeff * framest3{i,j}(1:mel_n).^2';
        % get mel cepstrum: DCT of the LOG of each spectrum coeff
        framest5{i,j} = dct(log10(framest4{i,j})); 
        % ignore the first element (P-1 amount per frame)
        framest5{i,j} = framest5{i,j}(2:end);
    end
end

%% Compare test audio to training audio

 for j = 1:8 %pick which test audio file 1-8
     mel_mat = cell2mat(framest5(j,:)); %mel coeffs for speaker i converted to array
     for i = 1:length(training_audio) %loop thru training set
        d = disteu(mel_mat,centroids{i});
        distortion(i) = sum(min(d,[],2));
     end
     [~,I] = min(distortion);
     disp(I) %displays which training audio that corresponds to
 end
  
%sound(training_audio{3},12500)
%sound(test_audio{3})

%TEST 1 
%75% accuracy

%TEST2
%fs =12500
%256/12500 = 20.48 ms
%plot(training_audio{1})
periodogram = cell2mat(frames3(1,:));

pcolor(periodogram)
%plot
%spectrogram(training_audio{1},256,156)
%spectrogram(training_audio{1},128,80)
%spectrogram(training_audio{1},512,380)


%TEST3
% z = melfb(P, N, fs);
%  plot(linspace(0, (12500/2), 129), z'),
%  title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');

% mel_mat = cell2mat(frames5(1,:));
% pcolor(mel_mat)


%TEST5
%  mel_mat1 = cell2mat(frames5(1,:));
%  mel_mat2 = cell2mat(frames5(2,:));
%  scatter(mel_mat1(6,:),mel_mat1(4,:))
%  hold on
%  scatter(mel_mat2(6,:),mel_mat2(4,:))
