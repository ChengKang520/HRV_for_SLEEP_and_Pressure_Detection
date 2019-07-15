

clear all;
close all;
saveaddr = 'C:\Users\hunter\Desktop\Demos\睡眠数据库ucddb Data\ucddb_Data\'
cd(saveaddr)
% the number of samlpe about learning

subject_name = [2 3 5 6 7 10 12 14 15 17 18 19 20 21 22 23 24 25 26 27 9 28 8]; % 去掉8 13  %去掉11 13 电极脱落
PSG_duration = [22470 26478 24798 24267 24405 27211....
    25941 23239 27488 23684 24685 25573 22586 27409 23640 25850....
    27250 21350 25160 26791 27759 21660 23041]; % 对应的数字 8-->23041 9--> 27759  13-->24333  28-->21660 % 去掉 8-->23041 11-->27030 13-->24333 脱落


for subject = 1:22
subject

ALL_num = 0;
FeatureSequence = [];

subject_num = subject_name(subject);
Fs = 128;
%% load ecgdata
if subject_num > 9
%     subject_nuame_edf = strcat('ucddb0',num2str(subject_num),'_lifecard');
    subject_nuame_edf = strcat('ucddb0',num2str(subject_num)); 
else
%     subject_nuame_edf = strcat('ucddb00',num2str(subject_num),'_lifecard');
    subject_nuame_edf = strcat('ucddb00',num2str(subject_num));
end

subject_filenuame_edf = strcat(subject_nuame_edf,'.rec');
[hdr, record] = edfread(subject_filenuame_edf);
ecg_data_all = record(6,:);

% figure;plot(ecg_data_all);

%% load Stages data
if subject_num > 9
    subject_name_stages = strcat('ucddb0',num2str(subject_num),'_stage');
else 
    subject_name_stages = strcat('ucddb00',num2str(subject_num),'_stage');
end

% define the time
Time_segment = 60*2;
Times = floor((length(ecg_data_all)/Fs)/Time_segment);

subject_filename_stages = strcat(subject_name_stages,'.txt');
Stages = load(subject_filename_stages);

dataLength = Times;
segMean = average_soft(Stages, dataLength, 1);
        
%     segMean1 = average_soft(Stages, dataLength, 0);
%     segMean2 = average_soft(Stages, dataLength, 1);
%     figure;
%     plot(mean(abs(segMean1)),'r', 'linewidth', 1);hold on;
%     plot(mean(abs(segMean2))+6,'b', 'linewidth', 2);hold off;

HRV_segments = cell(1, Times);
% note the empty
empty = 0; 

outputTime = cell(1,1);
outputFreq = cell(1,1);
outputNolinear = cell(1,1);
outputPoincare = cell(1,1);

for segments = 1:Times

segments

ecg_data = ecg_data_all(((segments-1)*Fs*Time_segment+1):segments*Fs*Time_segment) * 1000;

%%  滤波
    output1_IIR = filter(mybandpassfilterIIR_ECG_500(2,40),ecg_data);
    output2_IIR = flip(output1_IIR);
    output3_IIR = filter(mybandpassfilterIIR_ECG_500(2,40),output2_IIR);
    s = flip(output3_IIR);

%%  提取峰值
    peaks = [];
    peak_interval = [];
    ecg_detec = s(500:end);
    rate_type = 1;
    [window_width,peak_interval] = sample_results(Fs,rate_type);
    peaks = get_peak(ecg_detec,86,peak_interval,rate_type);

%%  找到 HRV的异常点；  也就是说，多检 漏检 早搏

    R_point_time_test = [];
    R_point_cor_Ectopic = zeros(4,50);  % 用来存放异位搏动点的位置，以便于后期HRV处理时，去除掉
    Ectopic_num = 0;  %   记录异位搏动点的个数
    R_point_time_test = peaks(2:end-2);
    
    rr_flag = gjcRR(R_point_time_test,Fs); %单位为ms
    if length(R_point_time_test)>floor(Time_segment/1.4) && length(find(rr_flag > 60/40)) == 0 && length(find(rr_flag < 60/250)) == 0
%     [R_point_time_test, flag_Ectopic, R_point_cor_Ectopic] = HRV_optimizing(ecg_detec, R_point_time_test, R_point_cor_Ectopic, Fs, 1);
    %%%%     记录异位搏动点个数
%     Ectopic_num = Ectopic_num + flag_Ectopic;
    %%%%  用以保存四个状态的峰值点
    four_state_R_point_time(1,1) = {R_point_time_test(5:end-5)};

%     figure;
%     plot(ecg_detec,'b-');hold on;
%     plot(peaks, ecg_detec(peaks), 'ro');hold on;
%     plot(round(R_point_time_test), ecg_detec(round(R_point_time_test)), 'k*');hold off;
%     legend('心电波形','原始的峰值点','修正之后的峰值点');
%%  经过修正之后的HRV曲线
    rr_correct = [];
    rr = [];
    rr_correct = gjcRR(R_point_time_test,Fs); %单位为ms
    rr = gjcRR(peaks,Fs); %单位为ms
%     figure(10);
%     % subplot(2,2,state_select);
%     plot(rr_correct,'r-');hold on;
%     plot(rr,'b-');hold off;
%     legend('修正HRV曲线','HRV曲线');

    HRV_segments(segments) = {rr_correct};

%%  计算 HRV 特征

HRV_mode = [];
HRV_mode(:,1) = R_point_time_test / Fs;
HRV_mode(:,2) = [ mean(diff(R_point_time_test / Fs)) diff(R_point_time_test) / Fs ];
%%% import the time domin parameter 
SDNNi= 1;
pNNx = 50;
Window = 30;
Overlap = 15;

%%% import the freq domin parameter
VLF = [0 0.04];
LF = [0.04 0.15];
HF = [0.15 0.4];
AR_Order = 16;
window_length = 256;
window_overlap = 128;
nfft = 256;
reFs = 2;
methods = {'ar','lomb'};  % 'ar','lomb','welch','wavelet'
flagPlot = 0; % plot the figure

%%% import the nolinear parameter
m = 2;
r = 0.1;
% it is very important to set this kind of parameters: n1 and n2
n1 = 4;
n2 = 60;
breakpoint = 13;

%%  calculate the features of HRV
outputTime(segments) = {timeDomainHRV(HRV_mode, 120, 50)};
outputFreq(segments) = {freqDomainHRV(HRV_mode, VLF, LF, HF, AR_Order, window_length, window_overlap, nfft, reFs, methods, flagPlot)};
outputNolinear(segments) = {nonlinearHRV(HRV_mode,m,r,n1,n2,breakpoint)};
outputPoincare(segments) = {poincareHRV(HRV_mode)};

% save HRV_mode.txt -ascii HRV_mode

%%  *****************
%  select acialable  time domain features
max_plotTime = outputTime{segments}.max;      
min_plotTime = outputTime{segments}.min;
mean1_plotTime = outputTime{segments}.mean;
median_plotTime= outputTime{segments}.median;
SDNN_plotTime = outputTime{segments}.SDNN;
SDANN_plotTime = outputTime{segments}.SDANN;
NNx_plotTime	= outputTime{segments}.NNx;
pNNx_plotTime = outputTime{segments}.pNNx;
RMSSD_plotTime = outputTime{segments}.RMSSD;
% SDNNi_plotTime = outputTime{segments}.SDNNi;
meanHR_plotTime = outputTime{segments}.meanHR;
sdHR_plotTime = outputTime{segments}.sdHR;
HRVTi_plotTime = outputTime{segments}.HRVTi;
% TINN_plotTime = outputTime{segments}.TINN;

%  select acialable  frequency domain features
aVLF_plotLomb = outputFreq{segments}.lomb.hrv.aVLF;
aLF_plotLomb = outputFreq{segments}.lomb.hrv.aLF;
aHF_plotLomb = outputFreq{segments}.lomb.hrv.aHF;
aTotal_plotLomb = outputFreq{segments}.lomb.hrv.aTotal;
pVLF_plotLomb = outputFreq{segments}.lomb.hrv.pVLF;
pLF_plotLomb = outputFreq{segments}.lomb.hrv.pLF;
pHF_plotLomb = outputFreq{segments}.lomb.hrv.pHF;
nLF_plotLomb = outputFreq{segments}.lomb.hrv.nLF;
nHF_plotLomb = outputFreq{segments}.lomb.hrv.nHF;
peakVLF_plotLomb = outputFreq{segments}.lomb.hrv.peakVLF;
peakLF_plotLomb = outputFreq{segments}.lomb.hrv.peakLF;
peakHF_plotLomb = outputFreq{segments}.lomb.hrv.peakHF;

aVLF_plotAR = outputFreq{segments}.ar.hrv.aVLF;
aLF_plotAR = outputFreq{segments}.ar.hrv.aLF;
aHF_plotAR = outputFreq{segments}.ar.hrv.aHF;
aTotal_plotAR = outputFreq{segments}.ar.hrv.aTotal;
pVLF_plotAR = outputFreq{segments}.ar.hrv.pVLF;
pLF_plotAR = outputFreq{segments}.ar.hrv.pLF;
pHF_plotAR = outputFreq{segments}.ar.hrv.pHF;
nLF_plotAR = outputFreq{segments}.ar.hrv.nLF;
nHF_plotAR = outputFreq{segments}.ar.hrv.nHF;
peakVLF_plotAR = outputFreq{segments}.ar.hrv.peakVLF;
peakLF_plotAR = outputFreq{segments}.ar.hrv.peakLF;
peakHF_plotAR = outputFreq{segments}.ar.hrv.peakHF;

%  select acialable  nonlinear features
alpha_plot = outputNolinear{segments}.dfa.alpha;
alpha1_plot = outputNolinear{segments}.dfa.alpha1;
alpha2_plot = outputNolinear{segments}.dfa.alpha2;
sampen_plot = outputNolinear{segments}.sampen;

%  select acialable  Poincar features
SD1_plotPoincare = outputPoincare{segments}.SD1;
SD2_plotPoincare = outputPoincare{segments}.SD2;

ALL_num = ALL_num + 1;
FeatureSequence(:,ALL_num) = [
    % time domain features  delete TINN
    max_plotTime, min_plotTime, mean1_plotTime, median_plotTime,....
    SDNN_plotTime, SDANN_plotTime, NNx_plotTime, pNNx_plotTime, RMSSD_plotTime,....
    meanHR_plotTime, sdHR_plotTime, HRVTi_plotTime,....
    aVLF_plotLomb, aLF_plotLomb, aHF_plotLomb, aTotal_plotLomb, pVLF_plotLomb, pLF_plotLomb, pHF_plotLomb, nLF_plotLomb, nHF_plotLomb, peakVLF_plotLomb, peakLF_plotLomb, peakHF_plotLomb,....
    aVLF_plotAR, aLF_plotAR, aHF_plotAR, aTotal_plotAR, pVLF_plotAR, pLF_plotAR, pHF_plotAR, nLF_plotAR, nHF_plotAR, peakVLF_plotAR, peakLF_plotAR, peakHF_plotAR,....    
    alpha_plot, alpha1_plot, alpha2_plot....
    SD1_plotPoincare, SD2_plotPoincare....
    mean(segMean(:,segments))];

    close all;
    else 
        
        empty = empty + 1;
        
    end

end

FeatureSample(subject) = {FeatureSequence};
    
close all;

end

save FeatureSample45_2min_smooth5 FeatureSample

%% set the labels
% set(gca,'XTick',20:20:110); 
% set(gca,'XTicklabel',20:20:110);
% set(gca,'YTick',0:1:5); 
% set(gca,'YTicklabel',{'Wake','REM','S1','S2','S3','S4'});
% set(gca, 'FontSize',16)
% xlabel('Age(yr)', 'FontSize',16);
% ylabel('Sympathetic(LFa)', 'FontSize',16);
% grid on;
% xlim([20 110]);
% ylim([0 4]);
% hold on;



