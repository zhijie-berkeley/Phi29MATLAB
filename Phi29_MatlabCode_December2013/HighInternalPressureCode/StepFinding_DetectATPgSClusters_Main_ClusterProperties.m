function [ClusterDuration ClusterSpan Packaged_DNA_kb]= StepFinding_DetectATPgSClusters_Main_ClusterProperties()
    % This function loads the *_ResultsKV_DetectATPgSClusters_Main.mat file
    % that was generated by StepFinding_DetectATPgSClusters_Main.
    % This gives you: 
    %                 ClusterDuration (list of all durations)
    %                 ClusterSpan     (list of all spans)
    %                 PackagedDNA     (the total amount of DNA packaged, in kb)
    %
    % Gheorghe Chistol, 28 Sep 2011
    ClusterDuration = [];
    ClusterSpan     = [];
    Packaged_DNA_kb = 0; %in kb
    
    global analysisPath;
    [DataFile DataPath] = uigetfile([ [analysisPath filesep ] '*.mat'], 'Please select the Step Finding Results file','MultiSelect', 'on');
    if ~iscell(DataFile)
        temp=DataFile; clear DataFile; DataFile{1} = temp;
    end
    
    %load one file at a time
    for df=1:length(DataFile)
        clear PauseClusters FinalDwells;
        load([DataPath filesep DataFile{df}]);

        %go through all the elements of PauseClusters{phage}{feedbackcycle}
        for ph=1:length(PauseClusters) %ph is the PhageFile index
            for fc=1:length(PauseClusters{ph}) %fc is the FeedbackCycle index

                if ~isempty(FinalDwells{ph}{fc})
                    Packaged_DNA_kb = Packaged_DNA_kb + range(FinalDwells{ph}{fc}.FiltCont);
                end
                
                if ~isempty(PauseClusters{ph}{fc})
                    for c=1:length(PauseClusters{ph}{fc}) %c is the Cluster index
                        ClusterDuration(end+1) = PauseClusters{ph}{fc}.ClusterDuration; 
                        ClusterSpan(end+1)     = PauseClusters{ph}{fc}.ClusterSpan;
                    end
                end
            end
        end
    end
    
    Packaged_DNA_kb = Packaged_DNA_kb/1000; %convert bp to kb
    
end