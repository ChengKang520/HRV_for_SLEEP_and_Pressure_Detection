
# HRV for Sleep Scoring and Pressure Evaluating


1. [Using LSTM for SLEEP SCORING based on HRV](#sleep)
2. [Pressure Evaluation by HRV](#pressure)
3. [Contributors](#contributors)



# Using LSTM for SLEEP SCORING based on HRV <a name="sleep"></a>
 You can download the dataset from: http://www.ofai.at/siesta/. 
 (But I found someone emailed me that they cannot download this data. Actually, the reason is that this databse is not free. If you are doing nonprofit and rresearch projects, the better choise is to use [UCDDB](https://physionet.org/content/ucddb/1.0.0/)


The aim of this project is to develop a system to monitor SLEEP STAGEs. In order to improve the accuracy rate, I used two kinds of LSTM networks (regression and classification). The regression LSTM is used to follow the trend of the SLEEP STAGEs line, while due to a weakness of the above LSTM to accurately locate and predict the state of sleep, I applied the classification LSTM to assist the monitoring.

- Tips: you can arrage the list of SLEEP stage from {AWAKE REM S1 S2 S3 S4} to {AWAKE S1 S2 S3 S4 REM}, as REM is not a stable stage, and scoring the REM stage is a difficult task. 

The illustrated result:
<p align="center">
  <img src="image/figure 2.bmp">
</p>

# Pressure Evaluation by HRV <a name="pressure"></a>

Compared these two groups (healthy controls and depressive patiens), we can statistic the distribution of these HRV features by regions evaluation.

- (This project has been transformed to industrial application. You can find the products in http://www.qhrv.cn/dtr_ans_cn.htm
Therefore, we can provide the service of technical or educational aspects.)

<p align="center">
  <img src="image/figure 1.bmp">
</p>


# NOTEs:
either you can utilize these matab codes to simulate or test the performanc of these exteacted features, or you can develope some new features from HRV which has been proved to be effective for detecting SLEEP stages. BUT, this projects is just a simple framework. More practical SLEEP data should be added into this model. If you need any help, just email me via kangkangsome@gmail.com . 

## Contributors <a name="contributors"></a>

Contributor | Email
------------ | -------------
Cheng Kang | kangkangsome@gmail.com
Qingyun Yang| qingyunyang512@gmail.com
