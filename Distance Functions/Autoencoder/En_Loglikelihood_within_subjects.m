% En_Loglikelihood_within_subjects: uses autoencoder neural network to reduce the dimensionality of raw data, 
% and afterward calculates loglikelihood on the low-dimension data for the within-subject case

clear; close; clc;

%% Load the data 
load('../../Data for Distance Functions/M1_Reduced-DeepSquat.mat');

% timesteps
T1 = size(Train_Data_Reduced{1},1);
% repetitions
T2=length(Train_Data_Reduced);
% repetion for subject
rt=[9 9 9 9 9 10 8 9 8 10];

%% Create a row for the time indices of correct data
Data_Train=cell(1,10);
Data_Train_position=cell(1,10);
M=0;
for s=1:10   
    Data_Train{s}=repmat(1:T1,1,rt(1,s));
    % Concatenate the data
    for i=1:rt(1,s)
        Data_Train_position{s}=[Data_Train_position{s},Train_Data_Reduced{M+i}'];
    end
    Data_Train{s}=[Data_Train{s};Data_Train_position{s}];
    M=M+rt(1,s);
end

% Create a row for the time indices of incorrect data
Data_Test=cell(1,10);
Data_Test_position=cell(1,10);
N=0;
for s=1:10
    Data_Test{s} = repmat(1:T1,1,rt(1,s));
    % Concatenate the data
    for i=1:rt(1,s)
        Data_Test_position{s}=[Data_Test_position{s},Test_Data_Reduced{N+i}'];
    end
    Data_Test{s} = [Data_Test{s};Data_Test_position{s}];
    N=N+rt(1,s);
end

%% Train GMM model
% Define the number of states for GMM
nbStates = 6;
nbVar=zeros(1,10);
Priors=cell(1,10);
Mu=cell(1,10);
Sigma=cell(1,10);

for s=1:10
    nbVar(1,s) = size(Data_Train{s},1);
    if nbVar(1,s)>1
       % Training by EM algorithm, initialized by k-means clustering.
       % [Priors, Mu, Sigma] = EM_init_kmeans(Data, nbStates);
       [Priors{1,s}, Mu{1,s}, Sigma{1,s}] = EM_init_regularTiming...
       (Data_Train{s},nbStates);
       % [Priors, Mu, Sigma] = EM(Data, Priors, Mu, Sigma);
       [Priors{s}, Mu{s}, Sigma{s}] = EM_boundingCov(Data_Train{s},...
                               Priors{s}, Mu{s}, Sigma{s});
    end
end

disp(['GMM modeling has been completed!',char(10)]);


%% Calculate loglikelihood (Part 4)
% correct sequences
loglikelihood_train=zeros(1,T2);
M=0;
for s=1:10
    for j=1:rt(1,s)
        loglikelihood_train(M+j) = loglik(Data_Train{s}(:,...
        (j-1)*T1+1:j*T1),...
        nbStates, Priors{1,s}, Mu{1,s}, Sigma{1,s});
    end
    M=M+rt(1,s);
end

% incorrect sequences
loglikelihood_test=zeros(1,T2);
N=0;
for s=1:10
    for j=1:rt(1,s)
        loglikelihood_test(N+j) = loglik(Data_Test{s}(:,...
        (j-1)*T1+1:j*T1),...
         nbStates, Priors{1,s}, Mu{1,s}, Sigma{1,s});
    end
    N=N+rt(1,s);
end

%% scale data and plot it
loglikelihood_train = -loglikelihood_train;
loglikelihood_test = -loglikelihood_test;

% plot
h=figure;
plot(loglikelihood_train,'bo');
hold on;
plot(loglikelihood_test,'r*');
title('M1');
legend('Correct sequences','Incorrect sequences')