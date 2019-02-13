function BurstSize_RetroactivelyRedoCalculation()
% This function allows you to load old results files generated by
% BurstSize__Main and use their indexing to re-calculate the Kernel Density
% and the steps, then save in a new folder. the function was written to
% help retroactively apply hydrodynamic corrections after all the tedious
% manual work of selection has already been done.
%
% USE: BurstSize_RetroactivelyRedoCalculation()
%
% Gheorghe Chistol, 07 Jan 2013

    StartPath = 'C:\aPhi29_Files\_ANALYSIS\HIP_Paper_2012';
    OldPath = uigetdir('C:\aPhi29_Files\_ANALYSIS\HIP_Paper_2012\BurstSizeResults_NoCorrection\','Select folder where old results are stored');
    
    NewResultsPath=[OldPath '_HC' filesep]; % NewResultsPath is the folder where the new results will be saved
    if ~exist(NewResultsPath,'dir')
        mkdir(NewResultsPath); %create new folder
    end
    temp = what(OldPath);
    OldFile = temp.mat; clear temp; %we want all the mat files there
    
    analysisPath = OldPath(end-20:end);
    if analysisPath(1)=='_';
        analysisPath(1)='';
    end
    analysisPath = [StartPath filesep analysisPath '_HC'];

%     [OldFile OldPath] = uigetfile([OldResultsPath filesep '*N*FC*s*s*.mat'], 'MultiSelect','on','Pick the Old Results Files of Interest');
%     if ~iscell(OldFile) %if there is only one file, make it into a cell, for easier processing later
%         temp=OldFile; clear OldFile; OldFile{1}=temp; clear temp;
%     end
    
    %open the analysis window
    BurstSize__Main;
    for f = 1:length(OldFile)
        load([OldPath filesep OldFile{f}]); %the data structure is called Trace
        Trace.FilePath = analysisPath; %in case the old path is outdated
        % Check what file has been loaded, if it's the same phage file do
        % not reload again
        CurrFigName = get(gcf,'Name');
        if ~strcmp(CurrFigName,Trace.FileName) %if they are not the same, load the new trace into guidata
            temp = load([Trace.FilePath filesep Trace.FileName],'stepdata');
            PhageData   = temp.stepdata; clear temp;
            set(gcf,'Name',Trace.FileName);
            set(gcf,'UserData',PhageData); %save the raw data to the 'UserData'
        end
        %clear the axes, set the feedback cycle
        axes(findobj(gcf,'Tag','KernelAxes')); cla; set(gca,'YTick',[],'XTick',[]);
        set(findobj(gcf,'Tag','EditFeedbackCycle'),'String',num2str(Trace.FeedbackCycle)); %set the feedback cycle of interest
        set(findobj(gcf,'Tag','EditFiltFreq'),'String',num2str(Trace.FiltFreq)); %display the filter frequency on the figure
        
        PhageData = get(gcf,'UserData');
        FC = Trace.FeedbackCycle;
        if FC>=1 && FC<=length(PhageData.time) && ~isnan(FC)
            %load the raw data, and filter it
            Trace.Time     = PhageData.time{FC};
            Trace.Force    = PhageData.force{FC};
            Trace.Contour  = PhageData.contour{FC};
            axes(findobj(gcf,'Tag','PlotAxes')); cla; hold on; %focus on the PlotAxes, clear it, hold plots
            h = plot(Trace.Time,Trace.Contour,'-','Color',0.85*[1 1 1]); set(h,'Tag','RawDataPlot'); axis tight;
            Trace.FiltTime    = BurstSize_FilterAndDecimate(Trace.Time,   Trace.FiltFact);
            Trace.FiltForce   = BurstSize_FilterAndDecimate(Trace.Force,  Trace.FiltFact);
            Trace.FiltContour = BurstSize_FilterAndDecimate(Trace.Contour,Trace.FiltFact);
            h = plot(Trace.FiltTime,Trace.FiltContour,'-','Color','k'); set(h,'Tag','FiltDataPlot');
            
            %set the right and left bounds using the existing index
            InitialYLim=get(gca,'YLim');
            Trace.LeftBoundH  = plot(Trace.LeftBoundT*[1 1], [min(Trace.Contour)-range(Trace.Contour) max(Trace.Contour)+range(Trace.Contour)],'b:','LineWidth',2);
            Trace.RightBoundH = plot(Trace.RightBoundT*[1 1],[min(Trace.Contour)-range(Trace.Contour) max(Trace.Contour)+range(Trace.Contour)],'r:','LineWidth',2);
            set(gca,'YLim',InitialYLim); %in case plotting the boundary changed the axis 
            
            %%%% set the axis limits according to the selected left/right boundaries
            IndKeep     = Trace.Time>Trace.LeftBoundT & Trace.Time<Trace.RightBoundT;
            CropTime    = Trace.Time(IndKeep);
            CropContour = Trace.Contour(IndKeep);
            DeltaCrop = 0.3; %how much extra to show for cropping
            TimeLim = [min(CropTime)-DeltaCrop*range(CropTime) max(CropTime)+DeltaCrop*range(CropTime)];
            DeltaCrop = 0;
            ContLim = [min(CropContour)-DeltaCrop*range(CropContour) max(CropContour)+DeltaCrop*range(CropContour)];
            axis([TimeLim ContLim]);

            %%%%% Calculate the kernel density and Plot it on the 'KernelAxes'
            [Trace.KernelGrid Trace.KernelValue] = BurstSize_CalculateKernelDensity(CropContour,Trace.FiltFact);
            axes(findobj(gcf,'Tag','KernelAxes')); cla; hold on; %focus on the KernelAxes, hold plots clear old figures
            h=plot(-Trace.KernelValue, Trace.KernelGrid,'m','LineWidth',2); set(h,'Tag','KernelPlot');
            set(gca,'XLim',[-1.1 0]);
            set(gca,'YLim',ContLim);
            legend(Trace.FileName,'Location','N');

            axes(findobj(gcf,'Tag','PlotAxes')); hold on; %focus on the PlotAxes, hold plots
            NumDwells = length(Trace.Dwells.DwellDuration); %using the old structure
            set(findobj(gcf,'Tag','EditNumberOfDwells'),'String',num2str(NumDwells)); %display the filter frequency on the figure

            IndKeep = Trace.FiltTime>=Trace.LeftBoundT & Trace.FiltTime<=Trace.RightBoundT;
            Trace.FiltTime    = Trace.FiltTime(IndKeep);
            Trace.FiltForce   = Trace.FiltForce(IndKeep);
            Trace.FiltContour = Trace.FiltContour(IndKeep);
            Dwells = BurstSize_SIC_FindSteps(Trace.FiltTime,Trace.FiltContour,Trace.FiltForce,NumDwells);
            Trace.Dwells = Dwells; %save the new dwells to the Trace Structure
            h = plot(Dwells.StaircaseTime,Dwells.StaircaseContour,'-','Color','b','LineWidth',2); set(h,'Tag','StaircasePlot');

            for d=1:length(Dwells.DwellLocation) %for each dwell, write the dwell duration
                XLim = get(gca,'XLim'); %first plot horizontal dashed lines to mark dwell location
                x = [Dwells.FinishTime(d) XLim(2)]; y = Dwells.DwellLocation(d)*[1 1];
                h = plot(x,y,':k'); set(h,'Tag','DwellLocationMark');
                x = double(Dwells.FinishTime(d)+0.2); y = double(Dwells.DwellLocation(d)); %now write the dwell duration next to each dwell
                DwellDuration = sprintf('%3.2f',Dwells.DwellDuration(d));
                h = text(x,y,[' ' DwellDuration ' s']); set(h,'Tag','DwellDurationLabel','FontWeight','bold','Color','b','BackgroundColor','w','EdgeColor','b','FontSize',12);
            end
        
            axes(findobj(gcf,'Tag','KernelAxes')); hold on;
            for d=1:length(Dwells.DwellLocation)-1 %diplay burst size labels
                x = -1.05; y = double(mean(Dwells.DwellLocation(d:(d+1))));
                BurstSize = sprintf('%2.2f',range(Dwells.DwellLocation(d:d+1)));
                h = text(x,y,[BurstSize ' bp']); set(h,'Tag','BurstSizeLabel','FontWeight','bold','FontSize',12);
            end

            for d=1:length(Dwells.DwellLocation) %plot error bar marks at 2 sigma
                x = get(gca,'XLim'); y = Dwells.DwellLocation(d)*[1 1];
                yerr = Dwells.DwellLocationErr(d)*[1 1]; 
                h = plot(x,y+yerr,'-','Color',0.8*[1 1 1]); set(h,'Tag','ErrorBarMark');
                h = plot(x,y,'-','Color',0*[1 1 1]); set(h,'Tag','ErrorBarMark');
                h = plot(x,y-yerr,'-','Color',0.8*[1 1 1]); set(h,'Tag','ErrorBarMark');
            end
            
            %%% prepare to save the results
            IndKeep = Trace.Time>=Trace.LeftBoundT & Trace.Time<=Trace.RightBoundT;
            Trace.Time    = Trace.Time(IndKeep);
            Trace.Force   = Trace.Force(IndKeep);
            Trace.Contour = Trace.Contour(IndKeep);
        
            %for a little change the background to white, then back to gray
            set(findobj(gcf,'Tag','TextFilterFrequency'),'BackgroundColor','w');
        
            SaveFolder = NewResultsPath;
            SaveFileName = [Trace.FileName(6:end-4) '_FC' num2str(Trace.FeedbackCycle) '_' sprintf('%3.2f',Trace.LeftBoundT) 's-' sprintf('%3.2f',Trace.RightBoundT) 's_HC' '.mat'];
            SaveImgName  = [Trace.FileName(6:end-4) '_FC' num2str(Trace.FeedbackCycle) '_' sprintf('%3.2f',Trace.LeftBoundT) 's-' sprintf('%3.2f',Trace.RightBoundT) 's_HC' '.png'];
            save([SaveFolder filesep SaveFileName],'Trace');
            saveas(gcf,[SaveFolder filesep SaveImgName]);
            %change background color back to gray
            set(findobj(gcf,'Tag','TextFilterFrequency'),'BackgroundColor',get(gcf,'Color'));
            axes(findobj(gcf,'Tag','PlotAxes')); cla; 
            axes(findobj(gcf,'Tag','KernelAxes')); cla; set(gca,'XTick',[],'YTick',[]);
        end
    end
    close(gcf);
end