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
        frames4{i,j} = filterbank_coeff * abs(frames3{i,j}(1:mel_n)).^2'; %check .^2
        % get mel cepstrum: DCT of the LOG of each spectrum coeff
        frames5{i,j} = dct(log10(frames4{i,j})); 
        % ignore the first element (P-1 amount per frame)
        frames5{i,j} = frames5{i,j}(2:end);
    end
end



%% LBG

%Parameters
%it's tough to come up with good error metric since a "low" total
%distance error is dependent on how many centroids there
%i've based the error on how much it changes between iterations
thresh = .001; %thresh*100 is allowed error percent change 
epsilon = .01; %splitting parameter
codeword_lim = 32; %maximum number of centroids

for i = 1:length(training_audio) %loop thru speakers
    % convert to matrix, index 1 is mel coeff coordinate, index 2 is frame
    row_mat = cell2mat(frames5(i,:)); 
    % column vector, each entry is sum of mel coeffs
    row_sum = sum(row_mat,2);
    % divide by number of frames
    row_avg = row_sum/frame_amount(i); 
    %define centroid matrix
    centroids{i} = row_avg;
    
    while size(centroids{i},2) < codeword_lim
        
        
        % split centroids,index 1 is the mel coeff  index 2 is the centroid 
        %number, , index 3 is the speaker number
        centroids{i} = [centroids{i}*(1+epsilon), centroids{i}*(1-epsilon)];
        
        
        %reset error 
        err_new = 999;
        err_old = 1;
        
        while abs((err_old-err_new)/err_old) > thresh %
        err_old = err_new;    
            
        %compute distance of each frame vector to centroids and determine closer centroid     
        d = disteu(row_mat,centroids{i}); %d has centroid# 2nd index
        [~,I] = min(d,[],2); 
        
        
        %initialize cell array to store frames after centroid splitting
        for k =1:size(centroids{i},2)
            centroid_frames{i,k} = [];
        end
      
        
        %assign frames to each centroid
        for  j = 1:frame_amount(i) %loop thru frames in I
              centroid_frames{i,I(j)} = [centroid_frames{i,I(j)};j]; 
        end
      
        
        %take assigned frames and recompute each centroid
        for k = 1:size(centroids{i},2) %loop thru centroids
            for n = 1:P-1 %loop thru mel coefficients
                running_total = 0;
                for m = 1:size(centroid_frames{i,k},1)%loop thru centroid frame entries
                    running_total = row_mat(n,centroid_frames{i,k}(m))+running_total;
                end
                centroids{i}(n,k) = running_total/size(centroid_frames{i,k},1);
            end
        end
        
        %find average distance
        d = disteu(row_mat,centroids{i});
        err_new = sum(min(d,[],2));     
        end
    end
end

%Key output is centroids{i} indexed by speaker, each entry is 
%a 16 x 19 set of centroids which represents the 19 coordinates of each of
%16 codewords for each speaker


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
        framest4{i,j} = filterbank_coeff * abs(framest3{i,j}(1:mel_n)).^2'; %check .^2
        % get mel cepstrum: DCT of the LOG of each spectrum coeff
        framest5{i,j} = dct(log10(framest4{i,j})); 
        % ignore the first element (P-1 amount per frame)
        framest5{i,j} = framest5{i,j}(2:end);
    end
end


%% Compare test audio to training audio

 for j = 1:8; %pick which test audio file 1-8
     row_mat = cell2mat(framest5(j,:)); %mel coeffs for speaker i converted to array
     for i = 1:length(training_audio) %loop thru training set
        d = disteu(row_mat,centroids{i});
        distortion(i) = sum(min(d,[],2));
     end
     [~,I] = min(distortion);
     disp(I) %displays which training audio that corresponds to
 end
 
%sound(training_audio{3})
%sound(test_audio{3})

    
%LBG summary
%sum over each mel coeff across all frames(~140-270) of
%each speaker, divide the total by the number of frames, this vector is the
%cetroid of all data for that speaker, then take each vector component and
%multiply it by 1+epsilon, and then take each component and multiply it by
%1-epsilon, compute the distance between each vector and each new centroid,
%assign each vector to the closer centroid, recompute the centroids by
%finding the centroid of all the vectors assigned to it, repeat process
%until below threshold,once happy with error, split centroids again by 
%multiplying each by 1+epsilon, and 1-epsilon


% z = melfb(P, N, fs);
%  plot(linspace(0, (12500/2), 129), z'),
%  title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');