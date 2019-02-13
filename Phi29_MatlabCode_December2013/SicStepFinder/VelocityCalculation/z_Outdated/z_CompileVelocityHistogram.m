function Bin=CompileVelocityHistogram()% This function was written specifically for processing HIP ATP titration% data. It loads several MAT files with processed Velocity data and% compiles Velocity Histograms.%% USE: Bin = HIP_CompileVelocityHistogram()%% Gheorghe Chistol, 18 Aug 2010%% Ask for the ParametersPrompt = {'Hist Lower Limit (bp/sec)','Hist Upper Lim (bp/sec)',...          'Hist Bin Width (bp/sec)','Length of Packaged DNA(bp)','DNA Length Bin Start (bp)',...          'DNA Length Bin End (bp)','DNA Length Bin Width (bp)'};Title = 'Enter the Following Parameters';Lines = 1;Default = {'-100','100','2','6000','2000','6000','2000'};Options.Resize='on'; Options.WindowStyle='normal'; Options.Interpreter='tex';Answer = inputdlg(Prompt, Title, Lines, Default, Options);%Hist parameters refer to the histogram display at the endHistLowerLim = str2num(Answer{1});HistUpperLim = str2num(Answer{2});HistBinWidth = str2num(Answer{3});LengthDNA    = str2num(Answer{4}); %the length of packaged DNABinStart     = str2num(Answer{5});BinEnd       = str2num(Answer{6});BinWidth     = str2num(Answer{7});%% Declare Global Variables for Folder Namesglobal velocityPath; %declare the folder where MAT files are savedglobal analysisPath;if isempty(velocityPath) && isempty(analysisPath)   velocityPath = uigetdir(pwd , 'Select the Folder with processed velocity MAT files');elseif isempty(velocityPath) && ~isempty(analysisPath)   velocityPath = uigetdir(analysisPath , 'Select the Folder with processed velocity MAT files');elseif velocityPath==0   velocityPath = uigetdir(pwd, 'Select the Folder with processed velocity MAT files');else   velocityPath = uigetdir(velocityPath, 'Select the Folder with processed velocity MAT files');end%Select original files, many files can be selected at once[VelFile] = uigetfile([ [velocityPath '\'] '*.mat'], 'MultiSelect', 'on');%process selected files one by oneif ~iscell(VelFile)%if there's only one file    temp=VelFile;    clear VelFile;    VelFile{1}=temp; %make it into a cellend%% Initialize the Data structure that organizes the Data in binstemp = BinStart:BinWidth:BinEnd; %make the bins for binning velocity data based on the length of DNA packagedBin.Start        = temp(1:end-1); %starting of each binBin.End          = temp(2:end);   %ending of each binfor i=1:length(Bin.Start);    Bin.Velocity{i}     = [];    Bin.PackagedDNA(i)  = 0;    Bin.SampleNumber(i) = 0;endBin.StdDev       = [];Bin.StdErr       = [];%% Put together all the datafor f=1:length(VelFile) %f stands for File    clear Bins;    load([velocityPath '\' VelFile{f}]);    disp(['Loaded velocity file ' VelFile]);    Vel.Location=LengthDNA-Vel.Location; %convert to the packaged DNA length    %Vel.Velocity    %Vel.Location    %Vel.Force    %Vel.Segment    L=length(Bin.Start);    for i=1:L        Ind = 1:length(Vel.Location); %the index of all data points from this file        Ind(Vel.Location < Bin.Start(i)) = [];        Ind(Vel.Location > Bin.End(i))   = []; %remove the points that are outside this bin                if ~isempty(Ind)            Bin.Velocity{i} = [Bin.Velocity{i} -mean(Vel.Velocity(Ind))];            Bin.SampleNumber(i) = length(Bin.Velocity{i});            Bin.PackagedDNA(i)  = Bin.PackagedDNA(i)+sum(Vel.Segment(Ind));        end    endend%% Plot the Results%close all;figure; hold on;for i=1:length(Bin.Start)    plot(ones(1,length(Bin.Velocity{i}))*(Bin.Start(i)+Bin.End(i))/2, Bin.Velocity{i},'.y');endfor i=1:length(Bin.Start)    %plot((Bin.Start(i)+Bin.End(i))/2, mean(Bin.Velocity{i}),'ok');    RectX = [Bin.Start(i)*[1 1] Bin.End(i)*[1 1] ];    Mean=mean(Bin.Velocity{i});    %StErr=std(Bin.Velocity{i})/sqrt(Bin.SampleNumber(i));    StErr=std(Bin.Velocity{i});    RectY = [Mean-StErr (Mean+StErr)*[1 1] Mean-StErr];    h     = patch(RectX,RectY,'r');    set(h,'FaceAlpha',0.2,'EdgeColor','none');    %errorbar((Bin.Start(i)+Bin.End(i))/2, mean(Bin.Velocity{i}), std(Bin.Velocity{i})/sqrt(Bin.SampleNumber(i)),'.k');end%     HistBins = HistLowerLim:HistBinWidth:HistUpperLim; %x coordinates for the histogram bins%     L=length(Bin.Start);%     for i=1:L%         figure;%         hist(Bin.Velocity{i},HistBins);%         MeanVel=mean(Bin.Velocity{i});%         StErr  = std(Bin.Velocity{i})/sqrt(length(Bin.Velocity{i}));%         title(['DNA packaged:' num2str(Bin.Start(i)) ' to ' num2str(Bin.End(i)) 'bp; Vel=' num2str(MeanVel) '\pm' num2str(StErr)]);%         xlabel(['Velocity (bp/sec)']);%         ylabel('Occurences');%         set(gca,'XLim',[HistLowerLim HistUpperLim]);%         set(gca,'YLimMode','auto');%     end