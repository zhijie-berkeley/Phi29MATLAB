% This script finds the steps and dwells in the High Internal Pressure data
% This script takes off where the 052410 script left and adds a method of
% comparing old dwells (shorter t-test window) and the new dwells (longer
% t-test window). Sometimes shorter t-test windows actually detect steps
% that longer windows miss. The goal is to retain the good dwells
% identified by the previous rounds of t-test analysis.

% Gheorghe Chistol: May 28, 2010
close all; clear all;
%% Add the Path where most files are stored
path('C:\Documents and Settings\Phi29\Desktop\MatlabCode\MatlabFilesGhe\MatlabGeneral\NewAnalysisCode\',path);
%the step finding scripts and functions are stored in a separate folder

%% Load Phages, calculate velocities, and index appropriately
load('./SampleDataHIP/phage051510N20.mat'); %for now work with a sample trace
phages = stepdata;
clear stepdata;
phageData = PhageVelocity(phages);
phageDataInd = LoadPhageList(phageData); %loads the index of the sub-traces that are good

%% Set Parameters
fsamp = 2500;     %sampling frequency
band = 100;       %bandwidth (after downsampling)?
av = fsamp/band;  %averaging number,
tWin = 10;        %time window size (number of points used to calculate the Ttest)  
thresh = 1e-2;    %tresholod for the T-Test
col = 'b';        %plot color
binMult = 1;

%% Initial round of Step Finding
%the steps were found using the Ttest algorythm with a very large window
%size, three times the original window size 3*tWin
%[trans, phageData] = GhePhageTTest(phages, [av tWin thresh], phageDataInd, 'nothing');
IndexedData=phages(1);
IndexedData.time = IndexedData.time(phageDataInd(1).stID);
IndexedData.contour = IndexedData.contour(phageDataInd(1).stID);
IndexedData.force = IndexedData.force(phageDataInd(1).stID);
IndexedData.forceX_err = '';
IndexedData.forceY_err = '';
IndexedData.trapX = '';
IndexedData.trapY = '';


%figure; hold on;
%plot(phageData(1).time, phageData(1).contour,'b');
%plot(phageData(1).timeFit, phageData(1).contourFit,'k');



%%
clear dwells;
NRound = 20;
BinThr = 0.005; %binomial threshold, half a percent
tWinIncrement = 1; %increment in Window size for each round of TTest analysis
%run NRound rounds of Ttest step analysis with gradually increasing window
%size. After each round go through the tentative steps and do a consistency check with binomial analysis 
phageDataPrev = phageData; %save the phageData from the previous round of analysis
tWin=5;
[trans, phageData] = GhePhageTTest(phages, [av tWin thresh], phageDataInd, 'nothing'); %run this round of TTest

%keep the data about all the rounds of t0test analysis in this cell
Dwells{1} = GheConvertTransToDwells(trans);
%UpdatedDwells{1}=Dwells{1};
%RevisedDwells{1}=Dwells{1};

clear Progress;
Progress(1)=1; %this is a measure of the progress which allows us to stop the step finding if several consecutive cycles provide no improvement

traceID=1; %ID of the current phage trace
r=2;
LoopStatus='continue';

%%
while r<=NRound && strcmp(LoopStatus,'continue') %continue until Nround is reached, or convergence is achieved
    tWinCurrent = tWin+(r-1)*tWinIncrement; 
    [trans, phageData] = GhePhageTTest(phages, [av tWinCurrent thresh], phageDataInd, 'nothing'); %run this round of TTest
    Dwells{r} = GheConvertTransToDwells(trans);

    %consider each step identified in the previous round
    %look inside and see how many substeps were identified in the current round
    %ps = previous round step index
    %cs = current round step index within the ps, 
    %each ps contains one or more cs
    %for now the specified transitions are only tentative
    %perform binomial consistency analysis 
    
    ShortestDwell = 0.03; %set the shortest dwell to 20 msec
    Nmin = round(ShortestDwell*band); %the minimum number of points in a dwell, this helps get rid of very short dwells identified by the algorythm
    MinStep = 2.5; %the smallest step is 2.5bp, to avoid fractured dwells due to flukes
    Dwells{r} = GheResolveShortDwells(phageData(traceID), Dwells{r}, Nmin, MinStep);
    %RevisedDwells{r} = GheResolveShortDwells(phageData(traceID), RevisedDwells{r}, Nmin, MinStep);
    
    %compare every single "new" dwell against the old dwells, keep the old
    %dwells if they are better.
    %Dwells{r} = GheCompareNewVersusOldDwells(phageData(traceID), Dwells{r-1}, Dwells{r}, BinThr, Nmin);
    Dwells{r}=GheCompareAgainstOldDwells(phageData, Dwells{r-1}, Dwells{r}, BinThr);
    Dwells{r} = GheResolveShortDwells(phageData(traceID), Dwells{r}, Nmin, MinStep);

    %RevisedDwells{r} = GheCheckAllCurrentDwells(phageData(traceID), RevisedDwells{r-1}, RevisedDwells{r}, BinThr);     
    figure; hold on;
    set(gca,'Color',[1 1 1]);
    plot(phageData(1).time, phageData(1).contour,'Color',[0.5 0.5 0.5]);
    grid off;
    GhePlotDwells(Dwells{r},phageData);
    title([phageDataInd.file '; subtrace #' num2str(phageDataInd.stID) '; round #' num2str(r)]);
    set(gcf, 'Position',[1 31 1920 1096]); %full screen figure
    
    %'Progress' is a measure of the progress which allows us to stop the step finding if several consecutive cycles provide no improvement
    Progress(r)=GheAssessProgress(Dwells{r-1},Dwells{r});
    if Progress(r)==1
        disp(['Progress has been made in round #' num2str(r)]);
    else
        disp(['No Progress has been made in round #' num2str(r)]);
    end
    %Progress is 0 if nothing changed, or 1 if the detected steps changed
    N=4;
    if length(Progress)>N
        if sum(Progress(end-N+1:end))==0
            LoopStatus='stop'; %this tells the main loop when to stop trying to find more steps
            disp(['Convergence has been achieved after ' num2str(r) ' rounds of analysis']);
        else
            r=r+1;
        end
    else
        r=r+1;
    end
end

if r>NRound
    r=NRound; %in case we ran over
end

%%     %% After the step finding is finished, look at the Std
%     figure; hold on;
%     set(gca,'Color',[1 1 1]);
%     plot(phageData(1).time, phageData(1).contour,'Color',[0.5 0.5 0.5]);
%     grid off;
%     GhePlotDwells(RevisedDwells{r},phageData);
%     set(gcf, 'Position',[1 31 1920 1096]); %full screen figure
%     %write the std value next to each 
%     for i=1:length(RevisedDwells{r}.mean)
%         x=phageData(1).time(RevisedDwells{r}.end(i))+0.05;
%         y=RevisedDwells{r}.mean(i);
%         std = num2str(RevisedDwells{r}.std(i));
%         std = std(1:3); %keep two significant figures
% 
%         %look at the overall slope of the dwell
%         start  = RevisedDwells{r}.start(i);
%         finish = RevisedDwells{r}.end(i);
%         time   = phageData(1).time(start:finish); %time data
% 
%         cont  = phageData(1).contour(start:finish); %contour data
%         p     = polyfit(time,cont,1); %fit a straight line to the data
%         slope = abs(p(1))*length(time);
%         RevisedDwells{r}.slope(i) = slope; %save this to the data structure
%         slope = num2str(round(slope)); %convert to string for display
% 
%         text(x,y,[std '[' slope ']']); %write to the plot
%     end
%     title([phageDataInd.file '; subtrace #' num2str(phageDataInd.stID) '; round #' num2str(r)]);


%%     %% Look at the troubled dwells (large slope, or large standar deviation)
%     % identify the troubled steps given the threshold slope and std. Then try
%     % to resolve the issue by looking inside the dwell for the lowest sgn value
%     % (as calculated by the T-test).
%     SlopeThr = 600; %the threshold for the slope coefficient (it's not the slope, but the slope*Npts)
%     StdThr   = 2.6; %the standard deviation theshold (regular Std)
%     %close all;
%     FinalDwells = GheReviewAbnormalDwells(phageData, RevisedDwells{end}, SlopeThr, StdThr, BinThr);
%     figure; hold on;
%     set(gca,'Color',[1 1 1]);
%     plot(phageData.time, phageData.contour,'Color',[0.5 0.5 0.5]);
%     grid off;
%     GhePlotDwells(FinalDwells,phageData);
%     title('Before Reviewing Abnormal Dwells');
%     set(gcf, 'Position',[1 31 1920 1096]); %full screen figure
%     % The revised dwells should be compliant with all the thresholds we set
%     % before: Nmin, MinStep, and BinThr (for binomial analysis)
%     BamDwells = GheResolveShortDwells(phageData(traceID), FinalDwells, Nmin, MinStep); %resolve minor discrepancies
%     figure; hold on;
%     set(gca,'Color',[1 1 1]);
%     plot(phageData.time, phageData.contour,'Color',[0.5 0.5 0.5]);
%     grid off;
%     GhePlotDwells(BamDwells,phageData);
%     title('After Reviewing Abnormal Dwells');
%     set(gcf, 'Position',[1 31 1920 1096]); %full screen figure