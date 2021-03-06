function PlotMultipleCroppedTraces(F,TimeShift)
% This function plots multiple (or just one) phage traces using the crops
% defined in the *.crop files. This allows us to view only the useful
% portions of traces. Note that only the traces that have a corresponding
% *.crop file will be plotted.
%
% USE: PlotMultipleCroppedTraces(F,TimeShift)
%
% Gheorghe Chistol, 23 Aug 2010

PlotOption='none';
global analysisPath;
if isempty(analysisPath)
    disp('analysisPath was not previously defined. Please define it and try again.');
    return;
end

%% Define Parameters
Bandwidth     = 2500;
if nargin==0
    %no filtering frequency was specified
    F=100; %set the filtering frequency to 100Hz by default
    disp('No Filter Frequency was specified, F=50Hz by default');
end

if nargin<2
    TimeShift = 10;
end

% Make sure that the Filter Frequency is positive, integer, round if neccessary
if rem(Bandwidth,F)~=0 || ~isinteger(F)
    N=round(Bandwidth/F); %this is the filtering factor
    %this is done to make sure that Bandwidth is divisible by N
    disp(['Filtering data to ' num2str(Bandwidth/N) ' Hz']);
else
    disp('The Filter Frequency has to be a positive, integer number');
    return;
end

%% Select the phage files of interest
File = uigetfile([ [analysisPath '\'] 'phage*.mat'], 'MultiSelect', 'on');
if isempty(File) %if no files were selected
    disp('No *.mat phage files were selected');
    return;
end

if ~iscell(File) %if there is only one file, make it into a cell, for easier processing later
    temp=File; clear File; File{1}=temp;
end
PlotCount=0; %number of traces plotted

FigureHandle=figure; hold on;
xlabel('Time (sec)');
ylabel('Force(pN)');
for i=1:length(File)
    CropFile = [analysisPath '\CropFiles\' File{i}(6:end-4) '.crop']; % this is the complete address of the crop file that should 
                                                         % correspond to the current phage *.mat file
    if exist(CropFile,'file') %check if the crop file exists, if it doesn't, don't process the phage file at all
        PlotCount=PlotCount+1;
        load([analysisPath '\' File{i}]); %load a single specified phage file
        Trace = stepdata; clear stepdata; %load the data and clear intermediate data
        
        FID = fopen(CropFile); %open the *.crop file
        Tstart = sscanf( fgetl(FID),'%f'); %parse the first line, which is the start time
        Tstop  = sscanf( fgetl(FID),'%f'); %parse the second line, which is the stop time
        fclose(FID);
        
        %go through each subtrace and filter it
        Extension = []; %unified data - one vector for the entire trace
        Time    = []; %unified time - one vector for the entire trace
        Force   = []; %unified force - one vector for the entire trace
        for n=1:length(Trace.time)
            TempTime    = FilterAndDecimate(Trace.time{n}, N); %filter the time and the other important values
            TempExtension = FilterAndDecimate(Trace.extension{n}, N);
            TempForce   = FilterAndDecimate(Trace.force{n}, N);
            
            Time    = [Time    TempTime];
            TempSize=size(TempExtension);
            if TempSize(1)==1
                Extension = [Extension TempExtension]; %#ok<*AGROW>
                Force   = [Force   TempForce];
            else
                Extension = [Extension TempExtension']; %#ok<*AGROW>
                Force   = [Force   TempForce'];
            end
        end
        TimeLimits=[Tstart Tstop];
        Ind = 1:length(Time); %original index
        Ind(Time>Tstop)  =[]; %delete the index outside the defined crop time-window
        Ind(Time<Tstart) =[];
        
        %these are the filtered and cropped data vectors
        Time    = Time(Ind);
        Time    = Time-Time(1);  
        Extension = Extension(Ind);
        Force   = Force(Ind);
                
    C1 = Extension(1); %work to fit a line to the first 10% of the data
    C2 = Extension(1)-0.1*range(Extension);
    T1 = Time(1);
    T2 = Time(find(Extension<C2,1,'first'));
    tempInd = Time>T1 & Time<T2;
    tempT   = Time(tempInd);
    tempC   = Extension(tempInd);
    tempFit = polyfit(tempT,tempC,1);
    TimeOffset(PlotCount) = -tempFit(2)/tempFit(1);
        
        if PlotCount>1 %the very first plot is not affected
            Offset = TimeOffset(1)-TimeOffset(PlotCount)+TimeShift*(PlotCount-1);
            Time = Time+Offset;
        end
        
        %plot the trace with an offset in time, for better viewing
        plot(Time, Force,'b','MarkerSize',1);%,'MarkerSize',3);
        TextY=double(Extension(1));
        TextX=double(Time(1));

        Text=File{i}(6:end-4);
        text(TextX,TextY,Text,'FontSize',8,'Color','k');
        set(gca,'Color','w');
        %set(h,'FontSize',8);
    else
        %the Crop *.crop file doesn't exist, skip the corresponding trace
        disp([File{i} ' was skipped because it has no crop (*.crop) file']);
    end %end of IF
end %end of FOR

%% If no traces were plotted, close the figure since it's empty
if PlotCount==0;
    close(FigureHandle);
end
