


%% **********************************
% Sequence-to-Sequence Regression Using Deep Learning (LSTM)
% The HRV-SLEEP datacontains 45 columns,and the columns correspond to the following:
% Column 1-44: features
% Column 45: values
% Author: Cheng Kang, kangkangsome@gmail.com, 2019/07/11

% http://www.dpmi.tu-graz.ac.at/~schloegl/
%% **********************************

function [net, idxConstant, mu, sig] = lstm_regression(XTrain, YTrain)


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

% avoid more horizontal lines
% thr = 150;
% for i = 1:numel(YTrain)
%     YTrain{i}(YTrain{i} > thr) = thr;
% end

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


%% Define Network Architecture
numResponses = size(YTrain{1},1);
featureDimension = size(XTrain{1},1);
numHiddenUnits = 300;

layers = [ ...
    sequenceInputLayer(featureDimension)
    lstmLayer(numHiddenUnits,'OutputMode','sequence')
    fullyConnectedLayer(100)
    fullyConnectedLayer(numResponses)
    regressionLayer];

maxEpochs = 100;
miniBatchSize = 30;

options = trainingOptions('adam', ...
    'MaxEpochs',maxEpochs, ...
    'MiniBatchSize',miniBatchSize, ...
    'InitialLearnRate',0.01, ...
    'LearnRateDropFactor',0.1, ...
    'LearnRateDropPeriod',60, ...
    'GradientThreshold',1, ...
    'SequenceLength','longest', ...
    'Shuffle','never', ...
    'Plots','training-progress',...
    'Verbose',0);

% Train the Network
net = trainNetwork(XTrain,YTrain,layers,options);




%% Example Functions
% The function prepareDataTrain extracts the data from filenamePredictors and returns the cell arrays XTrain and YTrain which contain the training predictor and response sequences, respectively.
% The data contains zip-compressed text files with 26 columns of numbers, separated by spaces. Each row is a snapshot of data taken during a single operational cycle, and each column is a different variable. The columns correspond to the following:
    function [XTrain,YTrain] = prepareDataTrain(filenamePredictors)
        
        dataTrain = dlmread(filenamePredictors);
        
        numObservations = max(dataTrain(:,1));
        
        XTrain = cell(numObservations,1);
        YTrain = cell(numObservations,1);
        for i = 1:numObservations
            idx = dataTrain(:,1) == i;
            
            X = dataTrain(idx,3:end)';
            XTrain{i} = X;
            
            timeSteps = dataTrain(idx,2)';
            Y = fliplr(timeSteps);
            YTrain{i} = Y;
        end
        
    end

% The function prepareDataTest extracts the data from filenamePredictors and filenameResponses and returns the cell arrays XTest and YTest, which contain the test predictor and response sequences. In filenamePredictors, the time series ends some time prior to system failure. The data in filenameResponses provides a vector of true RUL values for the test data.
    function [XTest,YTest] = prepareDataTest(filenamePredictors,filenameResponses)
        
        XTest = prepareDataTrain(filenamePredictors);
        
        RULTest = dlmread(filenameResponses);
        
        numObservations = numel(RULTest);
        
        YTest = cell(numObservations,1);
        for i = 1:numObservations
            X = XTest{i};
            sequenceLength = size(X,2);
            
            rul = RULTest(i);
            YTest{i} = rul+sequenceLength-1:-1:rul;
        end
        
    end


end
