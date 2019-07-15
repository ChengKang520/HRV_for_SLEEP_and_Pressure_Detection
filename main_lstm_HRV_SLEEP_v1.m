%% *********************************************
% Cheng Kang, 07,July,2019 
% the script to simulate the LSTM function for the evaluation of SLEEP 
% quality based on HRV  

%% *********************************************
clear all;
close all;
% clc;

% Load data 
Input_data = load('FeatureSample_old.mat');
XTrain = Input_data.FeatureSample(1:end-1, 1:3131);
YTrain = floor(Input_data.FeatureSample(end, 1:3131));
XTest = Input_data.FeatureSample(1:end-1, 3132:end);
YTest = floor(Input_data.FeatureSample(end, 3132:end));

% Visualize the data
figure;
plot(XTrain(:,100:120)');
xlabel("Time Step");
title("Training Observation 1");
% legend("Feature " + string(1:12),'Location','northeastoutside');
hold on;
plot(YTrain(100:120), 'k', 'linewidth',2);
legend('SLEEP SCORES');
hold off;

%% select the method 
% 'regression'
% 'classification'
% Select_mode = 1;  %  'classification'
Select_mode = 2;  %  'regression'

%%   *********************
% Using Catagorical to classify different items
%%   *********************
if Select_mode == 1

YTrain = categorical(YTrain);
YTest = categorical(YTest);

% Set the hyperparameters and Define the structure of LSTM 
inputSize = 29;
numHiddenUnits = 100;
numClasses = 7;
layers = [
    sequenceInputLayer(inputSize)
    bilstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    softmaxLayer
    classificationLayer
    ]

maxEpochs = 20;
miniBatchSize = 64;
options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',10, ...
    'InitialLearnRate',0.001,...    
    'GradientThreshold',1, ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest', ...
    'Shuffle','never', ...
    'Verbose',0, ...
    'Plots','training-progress');

%% Train LSTM Network
% Train the LSTM network with the specified training options by using trainNetwork.
Input_data_size = size(XTrain);
XTrain_cell = cell(1, Input_data_size(2));
for i = 1:Input_data_size(2)
    XTrain_cell(i) = {XTrain(:,i)};
end
net = trainNetwork(XTrain_cell',YTrain',layers,options);

% Test LSTM Network for Regression result
% The LSTM network net was trained using mini-batches of sequences of similar length. Ensure that the test data is organized in the same way. Sort the test data by sequence length.
XTest_size = size(XTest);
XTest_cell = cell(1,XTest_size(2));
for j = 1:XTest_size(2)
    XTest_cell(j) = {XTest(:,j)};
end

% Classify the test data. 
% To apply the same padding as the training data, specify the sequence length to be 'longest'.
YPred = classify(net,XTest, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest');

% Calculate the classification accuracy of the predictions.
acc = sum(YPred == YTest)./numel(YTest)






%%   *********************
% Using Regression
%%   *********************
else if Select_mode == 2
       
% Set the hyperparameters and Define the structure of LSTM 
inputSize = 14;
numHiddenUnits = 200;
numClasses = 1;
layers = [
    sequenceInputLayer(inputSize)
    bilstmLayer(numHiddenUnits,'OutputMode','last')
    fullyConnectedLayer(numClasses)
    regressionLayer
    ]

maxEpochs = 20;
miniBatchSize = 64;
options = trainingOptions('adam', ...
    'ExecutionEnvironment','cpu', ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',15, ...
    'InitialLearnRate',0.001,...
    'GradientThreshold',1, ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'SequenceLength','longest', ...
    'Shuffle','never', ...
    'Verbose',0, ...
    'Plots','training-progress');

%% Train LSTM Network
% Train the LSTM network with the specified training options by using trainNetwork.
mu = mean(XTrain);
sig = std(XTrain);

XTrainStandardized = (XTrain - mu) ./ sig;

Input_data_size = size(XTrainStandardized);
XTrainStandardized_cell = cell(1, Input_data_size(2));
XTrain_cell = cell(1, Input_data_size(2));
for i = 1:Input_data_size(2)
    XTrainStandardized_cell(i) = {XTrainStandardized(:,i)};
    XTrain_cell(i) = {XTrain(:,i)};
end
net = trainNetwork(XTrainStandardized_cell',YTrain',layers,options);

% Test LSTM Network for Regression result
net = predictAndUpdateState(net,XTrain_cell);
[net,YPred] = predictAndUpdateState(net,YTrain(end));

numTimeStepsTest = numel(XTest);
for i = 2:numTimeStepsTest
    [net,YPred(:,i)] = predictAndUpdateState(net,YPred(:,i-1),'ExecutionEnvironment','cpu');
end

YPred = sig*YPred + mu;

rmse = sqrt(mean((YPred-YTest).^2))

% Plot the training time series with the forecasted values.

figure
plot(dataTrain(1:end-1))
hold on
idx = numTimeStepsTrain:(numTimeStepsTrain+numTimeStepsTest);
plot(idx,[data(numTimeStepsTrain) YPred],'.-')
hold off
xlabel("Month")
ylabel("Cases")
title("Forecast")
legend(["Observed" "Forecast"])

        
    end
end
    
    
 





