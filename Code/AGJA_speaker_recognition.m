%clc;
clear;
close;

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

[test_audio, fs] = getAudioFiles('test');


%Parameters
epsilon = .01;
%its tough to come up with good error metric since a "low" total
%distance error is dependent on how many centroids there
%i've based the error on how much it changes between iterations
thresh = .001;
codeword_lim = 16;


%currently only works for one speaker at a time since i didn't use cells
%i need to rewrite everything in terms of cells


 %for i = 1:length(training_audio) %loop thru speakers
 i = 1;
    %make code books
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
        
        
        % split centroids,index 1 is the mel coeff  index 2 is the centroid 
        %number, , index 3 is the speaker number
        centroids = [centroids(:,:,i)*(1+epsilon), centroids(:,:,i)*(1-epsilon)];
        
        
        %reset error 
        err_new = 999;
        err_old = 1;
        
        while abs((err_old-err_new)/err_old) > thresh %
        err_old = err_new;    
            
        %compute distance of each frame vector to centroids and determine closer centroid     
        d = disteu(row_mat,centroids(:,:,i)); %d has centroid# 2nd index
        [~,I] = min(d,[],2);
        
        
        %initialize cell array to store frames after centroid splitting
        for k =1:size(centroids,2)
            centroid_frames{i,k} = [];
        end
      
        
        %assign frames to each centroid
        for  j = 1:frame_amount(i) %loop thru frames in I
              centroid_frames{i,I(j)} = [centroid_frames{i,I(j)};j]; 
        end
      
        
        %take assigned frames and recompute each centroid
        for k = 1:size(centroids,2) %loop thru centroids
            for n = 1:P-1 %loop thru mel coefficients
                running_total = 0;
                for m = 1:size(centroid_frames{i,k},1)%loop thru centroid frame entries
                    running_total = row_mat(n,centroid_frames{i,k}(m))+running_total;
                end
                centroids(n,k,i) = running_total/size(centroid_frames{i,k},1);
            end
        end
        
        %find average distance
        d = disteu(row_mat,centroids(:,:,i));
        [~,I] = min(d,[],2);
        err_new = sum(min(d,[],2));     
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



% z = melfb(P, N, fs);
%  plot(linspace(0, (12500/2), 129), z'),
%  title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');