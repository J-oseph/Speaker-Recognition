clc;
clear;
close;

%% Parameters

% path is specific for each computer. Needs to go to the Repo folder
% should be something like 'C:\....\Speaker-Recognition'
path = getPath(); % REPLACE THIS!!!!

notched = false;

% MFCC
N = 256;
M = 100;
P = 20;

window = 0.54-0.46.*cos(2*pi*[0:1:N-1]./(N-1));

%LBG 
thresh = .001; %thresh*100 is allowed percent error change 
epsilon = .01; %splitting parameter
codeword_lim = 8; %maximum number of centroids


%% Get mel coeffs for training data
% import the training data from data files
[training_audio,fs] = getAudioFiles(path,'train');

%normalize audio signals - this may not be best way to normalize
for i = 1:length(training_audio)
    training_audio{i} = training_audio{i}/max(training_audio{i});
end

% get the filterband coeff's
filterbank_coeff = melfb(P, N, fs);
mel_n = 1 + floor(N/2);

for i = 1:length(training_audio)
    % i is the index of each speaker
    % calculate frame beg, end, and amount
    frame_beginning = 1:M:length(training_audio{i})-N;
    frame_end       = frame_beginning + N;
    frame_amount(i) = length(frame_beginning);

    for j = 1:frame_amount(i)
        %create the frames
        frames1{i,j} = training_audio{i}(frame_beginning(j):frame_end(j)-1,:)';
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
        
        %initialize cell array to store frame ids for each centroid/empty out old data
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
%a Codeword Num x Mel Coeff Num Minus 1 set of centroids which represents the coordinates of each of
% codewords for each speaker

%% Get mel coeffs for test audio
if (notched)
    param = 'notched';
else
    param = 'test';
end
[test_audio, fs] = getAudioFiles(path,param);

%normalize audio signals - this may not be best way to normalize
for i = 1:length(test_audio)
    test_audio{i} = test_audio{i}/max(test_audio{i});
end

for i = 1:length(test_audio)
    % i is the index of each speaker
    % calculate frame beg, end, and amount
    frame_beginning = 1:M:length(test_audio{i})-N;
    frame_end       = frame_beginning + N;
    frame_amount(i) = length(frame_beginning);

    for j = 1:frame_amount(i)
        %create the frames
        framest1{i,j} = test_audio{i}(frame_beginning(j):frame_end(j)-1,:)';
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
guesses = [];
 for j = 1:length(test_audio) %loop thur test audio files 
     mfcc_mat = cell2mat(framest6(j,:)); %mel coeffs for speaker i converted to array
     for i = 1:length(training_audio) %loop thru training set
        d = disteu(mfcc_mat,centroids{i});
        distortion(i) = sum(min(d,[],2));
     end
     [~,I] = min(distortion);
     guesses = [guesses I];
 end

 num_correct = 0;
 disp('Original Audio: ')
 for j = 1:8
    txt = '';
    if (guesses(j) == j)
        num_correct = num_correct + 1;
        txt = '  Correct';
    end
    txt = ['    ','Guess #',num2str(j),': ',num2str(guesses(j)),' ',txt];
    disp(txt)
 end
 disp(['    ','Accuracy: ',num2str(num_correct/8 * 100),'%'])
 disp("Member Audio: ")
 for j = 12:13
    txt = '';
    if (guesses(j-3) == j)
        num_correct = num_correct + 1;
        txt = 'Correct';
    end
    txt = ['    ','Guess #',num2str(j),': ',num2str(guesses(j-3)),' ',txt];
    disp(txt)
 end
 disp('Mandela Audio: ')
 for j = 11:16
    txt = '';
    if (guesses(j) == 14)
        num_correct = num_correct + 1;
        txt = ' Correct';
    end
    txt = ['    ','Guess #',num2str(j-10),': ',num2str(guesses(j)),' ',txt];
    disp(txt)
 end
 disp('Thatcher Audio: ')
 for j = 17:22
    txt = '';
    if (guesses(j) == 15)
        num_correct = num_correct + 1;
        txt = ' Correct';
    end
    txt = ['    ','Guess #',num2str(j-16),': ',num2str(guesses(j)),' ',txt];
    disp(txt)

 end
 disp('Stoltenberg Audio: ')
 for j = 23:28
    txt = '';
    if (guesses(j) == 16)
        num_correct = num_correct + 1;
        txt = ' Correct';
    end
    txt = ['    ','Guess #',num2str(j-22),': ',num2str(guesses(j)),' ',txt];
    disp(txt)

 end
 disp(['Overall Accuracy: ',num2str(num_correct/length(guesses) * 100),'%'])

%% Project Tasks

% % % TEST 1 
% 75 percent accuracy

% % % TEST2 4 plots
% % sampling frequency = 12.5 KHz;
% %number of ms
% %256/12500 = 20.48 ms
% %plot time domain signal
% plot(training_audio{1})
% title('Time Domain Signal')
% %plot stft using mfcc code directly, plot on log scale
% figure;
% stft_mat = (cell2mat(frames3(1,:)'));
% pcolor(log10(stft_mat(:,floor(1:N/2)))') %plot 0 to pi
% title('Periodogram')
% %(run again with different N, and M)

% % % TEST3 2 plots
% plot mel spaced filterbank responses
% compare to theoretical? maybe we're supposed to say it looks a little 
% jagged in some places due to discretization error of N = 256?
% z = melfb(P, N, fs);
% plot(linspace(0, (12500/2), 129), z'),
% title('Mel-spaced filterbank'), xlabel('Frequency (Hz)');
% % before cepstrum, after mel applied, plot on log scale
% mel_bins = (cell2mat(frames4(i,:)));
% figure;
% pcolor(log10(mel_bins))

% % % TEST4 1 plot
%after cepstrum step, 1st coefficient removed, linear scale
% mfcc_mat = (cell2mat(frames6(1,:)));
% pcolor(mfcc_mat)

% % % TEST5 1 plot
%  mfcc_mat1 = cell2mat(frames6(1,:));
%  mfcc_mat2 = cell2mat(frames6(2,:));
%  mfcc_mat3 = cell2mat(frames6(3,:));
%  scatter(mfcc_mat1(1,:),mfcc_mat1(3,:))
%  hold on
%  scatter(mfcc_mat2(1,:),mfcc_mat2(3,:))
% hold on
%  scatter(mfcc_mat3(1,:),mfcc_mat3(3,:))

% % % TEST6 1 plot
%  mfcc_mat1 = cell2mat(frames6(1,:));
%  mfcc_mat2 = cell2mat(frames6(2,:));
%  scatter(mfcc_mat1(1,:),mfcc_mat1(3,:))
%  hold on
%  scatter(mfcc_mat2(1,:),mfcc_mat2(3,:))
%  hold on 
%  scatter(centroids{1}(1,1:8),centroids{1}(3,1:8),'filled')

% % % TEST7
%With parameters, 256,100,20,.001,.01, and 8 code gets %100 correct,
%much better than human 75% correct

% % TEST8
%design notch filter, apply to signals, save as different test audio
% f = [0,500,600,6250];
% a = [1,0,1];
% dev = [.001,.001,.001];
% n = firpmord(f,a,dev,fs);
% n=150;
% f = [0,.49,.5,.51,.52,1];
% a = [1,1,0,0,1,1];
% b = firpm(n,f,a);
% freqz(b,1000)
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

% TEST9
%Guesses our voices correctly

%TEST10
%82.14% overall accuracy on 28 test samples, and 16 different training 
%voices