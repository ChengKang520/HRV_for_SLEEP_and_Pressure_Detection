
%% **********************************
% Sequence-to-Sequence Classification Using Deep Learning (LSTM)
% The HRV-SLEEP datacontains 45 columns,and the columns correspond to the following:
% Column 1-44: features
% Column 45: values
% Author: Cheng Kang, kangkangsome@gmail.com, 2019/07/11

% http://www.dpmi.tu-graz.ac.at/~schloegl/
%% **********************************


function [net, idxConstant, mu, sig] = lstm_classification(XTrain, YTrain)

% Remove Features with Constant Values
m = min([XTrain{:}],[],2);
M = max([XTrain{:}],[],2);
idxConstant = M == m;
for i = 1:numel(XTrain)
    XTrain{i}(idxConstant,:) = [];
end

% Normalize Training Predictors
TrainData_length = length(XTrain);
mu = 0;
sig = 0;
for l = 1:TrainData_length
    mu = mu + mean([XTrain{l}], 2);
    sig = sig + std([XTrain{l}], 0, 2);
end
mu = mu / TrainData_length;
sig = sig / TrainData_length;

for i = 1:numel(XTrain)
    XTrain{i} = (XTrain{i} - mu) ./ sig;
end

% Prepare Data for Padding
for i=1:numel(XTrain)
    sequence = XTrain{i};
    sequenceLengths(i) = size(sequence,2);
end

[sequenceLengths,idx] = sort(sequenceLengths,'descend');
XTrain = XTrain(idx);
YTrain = YTrain(idx);
figure;
bar(sequenceLengths);
xlabel("Sequence");
ylabel("Length");
title("Sorted Data");
miniBatchSize = 20;


%% Define network architechture
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

% Train the LSTM network with the specified training options by using trainNetwork.

net = trainNetwork(XTrain',YTrain',layers,options);


end