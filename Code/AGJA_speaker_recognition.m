%clc;
clear;
close;

%% Parameters

% MFCC
N = 256;
M = 100;
P = 20;

%LBG 
thresh = .001; %thresh*100 is allowed percent error change 
epsilon = .01; %splitting parameter
codeword_lim = 8; %maximum number of centroids
%% Get mel coeffs for training data
Desired_Rate = 12500;
% import the training data from data files
[training_audio,fs] = getAudioFiles('train');

%add new audio
path = getPath();
subpath = '/Data/Training_Data/anson_train.wav';
[audio,Rate] = audioread(strcat(path,subpath));
%resample to 12500 hz
[Num,Den] = rat(Desired_Rate/Rate);
audio = resample(audio,Num,Den);
%append to rest of training data
training_audio = [training_audio, audio];

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
        frames6{i,j} = frames5{i,j}(2:end);
    end
end

%% LBG


for i = 1:length(training_audio) %loop thru speakers
    % convert cell array to matrix, index 1 is mel coeff number, index 2 is frame
    mfcc_mat = cell2mat(frames6(i,:)); 
    % column vector, each entry is sum of mel coeffs across frames
    mel_avg = sum(mfcc_mat,2)/frame_amount(i);
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
        d = disteu(mfcc_mat,centroids{i}); %d is array giving distance with 1st index frame id and second index centroid id
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
                    running_total = mfcc_mat(n,centroid_frames{k}(m))+running_total;
                end
                centroids{i}(n,k) = running_total/size(centroid_frames{k},1);
            end
        end
        
        %find average distance to determine error
        d = disteu(mfcc_mat,centroids{i});
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

path = getPath();
subpath = '/Data/Test_Data/anson_test.wav';
[audio,Rate] = audioread(strcat(path,subpath));
%resample to 12500 hz 
[Num,Den] = rat(Desired_Rate/Rate);
audio = resample(audio,Num,Den);
%append to test audio
test_audio = [test_audio, audio];

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
        framest6{i,j} = framest5{i,j}(2:end);
    end
end

%% Compare test audio to training audio

 for j = 1:9 %pick which test audio file 1-8
     mfcc_mat = cell2mat(framest6(j,:)); %mel coeffs for speaker i converted to array
     for i = 1:length(training_audio) %loop thru training set
        d = disteu(mfcc_mat,centroids{i});
        distortion(i) = sum(min(d,[],2));
     end
     [~,I] = min(distortion);
     disp(I) %displays which training audio that corresponds to
 end
  
%sound(training_audio{3},12500)
%sound(test_audio{3})

%TEST 1 
%75% accuracy

%TEST2 4 plots
%fs =12500
%number of ms
%256/12500 = 20.48 ms
%plot time domain signal
%plot(training_audio{1})
%plot stft using mfcc code directly, plot on log scale
% figure;
% stft_mat = (cell2mat(frames3(1,:)'));
% pcolor(log10(stft_mat(:,floor(1:N/2)))) %plot 0 to pi
%(run again with different N, and M)

%TEST3 2 plots
%plot mel spaced filterbank responses
%compare to theoretical? maybe we're supposed to say it looks a little 
%jagged in some places due to discretization error of N = 256?
% z = melfb(P, N, fs);
% plot(linspace(0, (12500/2), 129), z'),
% title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');
%before cepstrum, after mel applied, plot on log scale
%mel_bins = (cell2mat(frames4(i,:)));
%figure;
%pcolor(log10(mel_bins))


%TEST4 1 plot
%after cepstrum step, 1st coefficient removed, linear scale
% mfcc_mat = (cell2mat(frames6(1,:)));
% pcolor(mfcc_mat)

%TEST5 1 plot
%  mfcc_mat1 = cell2mat(frames6(1,:));
%  mfcc_mat2 = cell2mat(frames6(2,:));
%  mfcc_mat3 = cell2mat(frames6(3,:));
%  scatter(mfcc_mat1(1,:),mfcc_mat1(3,:))
%  hold on
%  scatter(mfcc_mat2(1,:),mfcc_mat2(3,:))
% hold on
%  scatter(mfcc_mat3(1,:),mfcc_mat3(3,:))

%TEST6 1 plot
%  mfcc_mat1 = cell2mat(frames6(1,:));
%  mfcc_mat2 = cell2mat(frames6(2,:));
%  scatter(mfcc_mat1(1,:),mfcc_mat1(3,:))
%  hold on
%  scatter(mfcc_mat2(1,:),mfcc_mat2(3,:))
%  hold on 
%  scatter(centroids{1}(1,1:8),centroids{1}(3,1:8),'filled')

%TEST7
%With parameters, 256,100,20,.001,.01, and 8 code gets %100 correct,
%much better than human 75% correct
% works on my test and training data, need to get joe's voice

%TEST8
%design notch filter, apply to signals, save as different test audio
% f = [0,500,600,6250];
% a = [1,0,1];
% dev = [.01,.01,.01];
% [n,fo,ao,w] = firpmord(f,a,dev,fs);
% b = firpm(n,fo,ao,w);
% %apply filter to audio signals
% path = getPath();
% subpath = '/Data/Test_Data/s';
% ext = 'filt.wav';
% for i = 1:length(test_audio)
%     TEST_AUDIO{i} = fft(test_audio{i});
%     B = fft(b,length(TEST_AUDIO{i}));
%     TEST_AUDIO_FILT{i} = B'.*TEST_AUDIO{i};
%     test_audio_filt{i} = ifft(TEST_AUDIO_FILT{i});
%     audiowrite(strcat(path,subpath,int2str(i),ext),test_audio_filt{i},fs)
% end
%still need to test the code on these and see if it can still match 
%them to training data

%TEST9
%record two more people? replace existing speakers with those people,
%test again and compare accuracy?

%TEST10
%test the system with other datasets, remember to change everything to the 
%same sampling frequency