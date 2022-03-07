clc;
clear;
close;

% declare variables
N = 256;
M = 100;
P = 20;

% import the training data from data files
[training_audio,fs] = getAudioFiles('train');

%normalize audio signals
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
        frames4{i,j} = filterbank_coeff * abs(frames3{i,j}(1:mel_n)).^2'; %check .^2
        % get mel cepstrum: DCT of the LOG of each spectrum coeff
        frames5{i,j} = dct(log10(frames4{i,j}));
        % ignore the first element (P-1 amount per frame)
        frames5{i,j} = frames5{i,j}(2:end);
    end
end

[test_audio, fs] = getAudioFiles('test');

%normalization step?
%abs
%.^2
%log10
%struct
%N-M

epsilon = .01;
thresh = .01;
codeword_lim = 64;
%need a centroid matrix

% for i = 1:length(training_audio)
%make code book for speaker 1
i=1;
    %take all mel coeffs of all frames of ith speaker
    temp_row = frames5(i,:); 
    % convert to matrix, index 1 is mel coeff coordinate, index 2 is frame
    row_mat = cell2mat(temp_row); 
    % each column is a speaker, each row is sum of mel coeffs
    row_sum(:,i) = sum(row_mat,2);
    % divide by number of frames
    row_avg(:,i) = row_sum(:,i)/frame_amount(i); 
    %define centroid matrix
    centroids(:,:,i) = row_avg(:,i);
    while size(centroids,2) < codeword_lim
        % split centroids,  index 2 is the centroid number, index 1 is the
        % mel coeff coordinate, index 3 is the speaker number
        centroids = [centroids(:,:,i)*(1+epsilon), centroids(:,:,i)*(1-epsilon)];
        %reset error 
        err = 100;
        while err > thresh
        %compute distance of each vector to centroids and assign vector to
        %closer
        %recompute centroids
        d = disteu(row_mat,centroids(:,:,i));
        err = .005;
        [~,I] = min(d,[],2);
        end
    end
            
            

 



 %sum over each mel coeff across all frames(~140-270) of
%each speaker, divide the total by the number of frames, this vector is the
%cetroid of all data for that speaker, then take each vector component and
%multiply it by 1+epsilon, and then take each component and multiply it by
%1-epsilon, compute the distance between each vector and each centroid,
%assign each vector to the closer centroid, recompute the centroids by
%finding the centroid of all the vectors assigned to it, repeat process
%until below threshold,once happy with error, split centroids again by 
%multiplying each by 1+epsilon, and 1-epsilon

tot = 0;
i = 1;%test on speaker one

%to be able to sum across the same mel coeffs on multiple frames
%need it to not be struct
% for mel_coef = 1:19;
%     for frame = 1:(floor((length(training_audio{i})-N)/M))
%          tot = sum(frames{i,j}(mel_coef))
%     end
% 
%     centr = tot/(floor((length(training_audio{i})-N)/M))
%         
%         
    



% z = melfb(P, N, fs);
%  plot(linspace(0, (12500/2), 129), z'),
%  title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');