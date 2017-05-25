clear all;

%SVM
%PriceRawData = xlsread('Stk_prices.xlsm',2);
PriceRawData = xlsread('Last_Price.xlsx',1);
SP500RawData = xlsread('Last_Price.xlsx',3,'A:A');
RfRawData = xlsread('Last_Price.xlsx',3,'B:B');
ReturnRawData = price2ret(PriceRawData);
RmRawData = price2ret(SP500RawData);
RfRawData = RfRawData(2,end);


%[Month,Num_Stock] = size(PriceRawData);
[Time,Num_Stock] = size(PriceRawData);
Precalculate_Time = 14;
Forecast_Time = 252;
Training_Time = Time-Precalculate_Time-Forecast_Time;
%Training_Time = Month-Precalculate_Time-Forecast_Time;
disp(Time);
disp(Num_Stock);

%ReturnRawData = price2ret(PriceRawData);
%VolumnRawData = xlsread('Stk_prices.xlsm',3);
%LeverageRawData = xlsread('Stk_prices.xlsm',4);
%RoeRawData = xlsread('Stk_prices.xlsm',5);
%ValueRawData = xlsread('Stk_prices.xlsm',6);
%for i=1:Month
%    for j=1:Num_Stock
%        if(isnan(VolumnRawData(i,j)))
%            VolumnRawData(i,j)=0;
%        end
%        if(isnan(LeverageRawData(i,j)))
%            LeverageRawData(i,j)=0;
%        end
%        if(isnan(RoeRawData(i,j)))
%            RoeRawData(i,j)=0;
%        end
%        if(isnan(ValueRawData(i,j)))
%            ValueRawData(i,j)=0;
%        end
%    end
%end

%calculate technical indicators and fundamental indicators
%SP500RawData = xlsread('Macro.xlsx',1,'B:B');
%CpiRawData = xlsread('Macro.xlsx',1,'E:E');
%GoldRawData = xlsread('Macro.xlsx',1,'H:H');
%RfRawData = xlsread('Macro.xlsx',1,'K:K');
MomentunRawData = tsmom(PriceRawData, Precalculate_Time);
%RSIRawData = zeros(Time-Precalculate_Time,Num_Stock);
RSIRawData = [];
BetaRawData = zeros(Time-Precalculate_Time,Num_Stock);
MARawData = zeros(Time-Precalculate_Time,Num_Stock);
%RmRawData = price2ret(SP500RawData);
%RfRawData = RfRawData(2,end);
for stock=1:Num_Stock
    %Rsi = rsindex(PriceRawData(i:i+Precalculate_Time-1,stock:stock), Precalculate_Time);
    Rsi = rsindex(PriceRawData(:,stock), Precalculate_Time);
    RSIRawData = [RSIRawData Rsi];
    for i=1:Time-Precalculate_Time
        RiRfVector = ReturnRawData(:,stock)-RfRawData;
        RmRfVector = RmRawData-RfRawData;
        BetaRawData(i,stock) = regress(RiRfVector(i:i+Precalculate_Time-2),RmRfVector(i:i+Precalculate_Time-2));
        MARawData(i,stock) = mean(PriceRawData(i:i+Precalculate_Time-1,stock:stock));
    end
end
ReturnRawData = ReturnRawData(Precalculate_Time:end,:);
%VolumnRawData = VolumnRawData(Precalculate_Time+1:end,:);
%LeverageRawData = LeverageRawData(Precalculate_Time+1:end,:);
%RoeRawData = RoeRawData(Precalculate_Time+1:end,:);
%ValueRawData = ValueRawData(Precalculate_Time+1:end,:);
%CpiRawData = CpiRawData(Precalculate_Time+1:end,:);
%GoldRawData = GoldRawData(Precalculate_Time+1:end,:);
MomentunRawData = MomentunRawData(Precalculate_Time+1:end,:);
RSIRawData = RSIRawData(Precalculate_Time+1:end,:);
%RawData = xlsread('Testdata.xlsx');


Num_Feature = 4;
Stock_Index = 0;
PredictLabelMatrix = zeros(Forecast_Time,Num_Stock);
PredictReturnMatrix = zeros(Forecast_Time,Num_Stock);
PredictReturn = zeros(1,Num_Stock);

for stock=1:Num_Stock

    Stock_Index = stock;

    ReturnData = ReturnRawData(:,stock);%Y
    
    %VolumnData = VolumnRawData(:,stock);%X
    %LeverageData = LeverageRawData(:,stock);
    %RoeData = RoeRawData(:,stock);
    %ValueData = ValueRawData(:,stock);
    BetaData = BetaRawData(:,stock);
    RSIData = RSIRawData(:,stock);
    %CpiData = CpiRawData;
    %GoldData = GoldRawData;
    MomentunData = MomentunRawData(:,stock);
    MAData = MARawData(:,stock);
    
    %build data
    Label = zeros(size(ReturnData));
    Label(find(ReturnData > 0)) = 1;
    Label(find(ReturnData <= 0 )) = -1;
    %Import single stock data

    for i=1:Forecast_Time
        %Build training data and forecast data
        %trainData = [VolumnData(i:i+Training_Time-1) LeverageData(i:i+Training_Time-1) RoeData(i:i+Training_Time-1) ...
        %    ValueData(i:i+Training_Time-1) BetaData(i:i+Training_Time-1) CpiData(i:i+Training_Time-1) ...
        %    GoldData(i:i+Training_Time-1) MomentunData(i:i+Training_Time-1) MAData(i:i+Training_Time-1)];
        trainData = [BetaData(i:i+Training_Time-1) RSIData(i:i+Training_Time-1) ...
            MomentunData(i:i+Training_Time-1) MAData(i:i+Training_Time-1)];
        
        trainLabel = Label(i:i+Training_Time-1,:);
        %predictData = [VolumnData(i+Training_Time) LeverageData(i+Training_Time) RoeData(i+Training_Time) ...
        %    ValueData(i+Training_Time) BetaData(i+Training_Time) CpiData(i+Training_Time) ...
        %    GoldData(i+Training_Time) MomentunData(i+Training_Time) MAData(i+Training_Time)];
        predictData = [BetaData(i+Training_Time) RSIData(i+Training_Time) ...
            MomentunData(i+Training_Time) MAData(i+Training_Time)];
       
        %Training
        struct = svmtrain(trainData, trainLabel, 'ShowPlot',true);
        %struct = fitcsvm(X,Y,'KernelFunction','rbf','Standardize',true,'ClassNames',{'negClass','posClass'});
        %disp(struct);
        alpha = struct.Alpha;
        bias = struct.Bias;
        SupportVectorIndex = struct.SupportVectorIndices;
        SupportVectors = struct.SupportVectors;
        %Forecast label
        predictLabel = svmclassify(struct, predictData);
        PredictLabelMatrix(i,stock) = predictLabel;
        PredictReturnMatrix(i,stock) = PredictLabelMatrix(i,stock)*ReturnData(i+Training_Time);

    end
    %Back Test
    PredictReturn(stock) = mean(PredictReturnMatrix(:,stock));
    
end
disp(PredictReturn);
AvgReturn = mean(PredictReturn);
disp(AvgReturn);
%SharpeRatio = sharpe();




