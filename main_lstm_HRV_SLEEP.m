
%% **********************************
% Sequence-to-Sequence Regression Using Deep Learning
% The HRV-SLEEP datacontains 45 columns,and the columns correspond to the following:
% Column 1-44: features
% Column 45: values
% Author: Cheng Kang, kangkangsome@gmail.com, 2019/07/11

% http://www.dpmi.tu-graz.ac.at/~schloegl/
%% **********************************

clear all;
close all;
% clc;

select_mode = 2

% Load data
Input_data = load('FeatureSample45_2min_smooth5.mat');

Train_sample = [1:7, 10:22];
Test_sample = (8:11);
TrainData = Input_data.FeatureSample(Train_sample);
TestData = Input_data.FeatureSample(Test_sample);
TrainData_size = size(TrainData);
TestData_size = size(TestData);
clear Input_data


if select_mode == 1

%% To calculate the LSTM of Regrassion value

for i = 1:TrainData_size(2)
    TrainData_seg = [];
    TrainData_seg = TrainData{i};
    XTrain(i) = {TrainData_seg(1:end-1,:)};
    
    % add noise of 0.3*(+-1)
    length_i = length(TrainData_seg(end,:));
%     residual_err = -3 + (3 + 3) * rand(1, length_i);    
%     YTrain(i) = {TrainData_seg(end,:) * 10 + residual_err}; 
    YTrain(i) = {TrainData_seg(end,:) * 10};
%     YTrain(i) = {floor(TrainData_seg(end,:))};
%     YTrain(i) = {categorical(floor(TrainData_seg(end,:)))};
end
for j = 1:TestData_size(2)
    TestData_seg = [];
    TestData_seg = TestData{j};
        
    XTest(j) = {TestData_seg(1:end-1,:)};
    YTest(j) = {TestData_seg(end,:) * 10};
%     YTest(j) = {floor(TestData_seg(end,:))};
    %     YTest(j) = {categorical(floor(TestData_seg(end,:)))};
end

% Start of Train
[net_regression, idxConstant, mu, sig] = lstm_regression(XTrain, YTrain);


% Test the Network
for i = 1:numel(XTest)
    XTest{i}(idxConstant,:) = [];
    XTest{i} = (XTest{i} - mu) ./ sig;
%     YTest{i}(YTest{i} > thr) = thr;
end

YPred = predict(net_regression, XTest, 'MiniBatchSize',1);

length_category = 4;
length_wholeTime = 300;
close all;
for i = 1:length(YPred)
    % combine S3 and S4
    
    YTest_seg = [];
    YPred_seg = [];
    YTest_seg = YTest{i};
    YPred_seg = YPred{i};
    
    YTest_seg(find(YTest_seg >40)) = 40;
    YTest(i) = {YTest_seg};
    YPred_seg(find(YPred_seg >40)) = 40;
    YPred(i) = {YPred_seg};
    
    figure;
    plot(YTest{i}, 'k-', 'linewidth', 1);hold on;
    plot(smooth(YTest{i}, 5), 'k.-', 'linewidth', 2);hold on;
    plot(YPred{i}, 'r-', 'linewidth', 1);hold on;
    plot(smooth(YPred{i}, 5), 'r.-', 'linewidth', 2);hold off;
    
    xlim([0 300])
    ylim([0 40])
    title("Subject " + i)
    xlabel('Hours(h)', 'FontSize',16);
    ylabel('Sleep stage', 'FontSize',16);
    
    set(gca,'XTick',0:30:240,'XTicklabel',0:1:8,...
       'YTick',0:10:40, 'YTickLabel',{'Wake','REM','NREM1', 'NREM2', 'NREM3'},...
        'TickLength',[0 0], 'FontSize',16);
end
legend(["Test Data" "Predicted"],'Location','southeast');


% for i = 1:numel(YTest)
%     YTestLast(i) = YTest{i}(end);
%     YPredLast(i) = YPred{i}(end);
% end
% figure
% rmse = sqrt(mean((YPredLast - YTestLast).^2))
% histogram(YPredLast - YTestLast)
% title("RMSE = " + rmse)
% ylabel("Frequency")
% xlabel("Error")

% calculate the correlation coefficients
for i = 1:length(YTest)
    YTest_element = [];
    YPred_element = [];
    YTest_element = floor(YTest{i})/10;
    YPred_element = floor(YPred{i})/10;
    Cor_value = corrcoef(YTest_element, YPred_element);
    Cor_Test_Pred(i) = Cor_value(1,2);
end
% show the correlation coefficients
Cor_Test_Pred

clear XTrain
clear YTrain
clear XTest
clear YTest


%% To calculate the LSTM for Classification
else if select_mode == 2

for i = 1:TrainData_size(2)
    TrainData_seg = [];
    TrainData_seg = TrainData{i};
    XTrain(i) = {TrainData_seg(1:end-1,:)};
    
    YTrain(i) = {floor(TrainData_seg(end,:))};
    YTrain(i) = {categorical(floor(TrainData_seg(end,:)))};
end
for j = 1:TestData_size(2)
    TestData_seg = [];
    TestData_seg = TestData{j};
    
    YTest(j) = {floor(TestData_seg(end,:))};
    YTest(j) = {categorical(floor(TestData_seg(end,:)))};
end


[net_classification, idxConstant, mu, sig] = lstm_classification(XTrain, YTrain);



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





clear TrainData
clear TestData
clear TrainData_seg
clear TestData_seg



    end 
end






