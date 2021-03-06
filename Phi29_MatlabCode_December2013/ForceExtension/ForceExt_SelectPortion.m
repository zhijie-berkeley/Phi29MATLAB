function ForceExt_SelectPortion(Scenario)
% This function allows you to select a
% portion of a force-extension curve and fit the WormLikeChain to it.
%
% USE: ForceExt_SelectPortion(fcn)
%
% Gheorghe Chistol, 10 Feb 2012

if (nargin==0)
   Scenario = 0;
   Data = guidata(gcf); %get the shared data from the figure
   Data.LeftHandle  = [];
   Data.RightHandle = [];
   guidata(gcf,Data); %save the modified shared data to the figure
end

    
switch Scenario
   case 0
        subplot(2,1,1); hold on; zoom on;

        button1 = uicontrol('Style', 'PushButton','Units','normalized',...
                          'Position',[0.13 0.94 0.16 0.04],...
                          'BackgroundColor',0.7*[1 1 1], ...
                          'String','Set Left Boundary','CallBack',...
                          'ForceExt_SelectPortion(1)');
        button2 = uicontrol('Style', 'PushButton','Units','normalized',...
                          'Position',[0.13+0.17 0.94 0.16 0.04],...
                          'BackgroundColor',0.7*[1 1 1], ...
                          'String','Set Right Boundary','CallBack',...
                          'ForceExt_SelectPortion(2)');
        button3 = uicontrol('Style', 'PushButton','Units','normalized',...
                          'Position',[0.13+0.17*2 0.94 0.16 0.04],...
                          'BackgroundColor',0.7*[1 1 1], ...
                          'String','Apply Limits','CallBack',...
                          'ForceExt_SelectPortion(3)');
        button4 = uicontrol('Style', 'PushButton','Units','normalized',...
                          'Position',[0.80 0.94 0.10 0.04],...
                          'BackgroundColor',0.7*[1 1 1], ...
                          'String','Close Fits','CallBack',...
                          'ForceExt_SelectPortion(4)');
   case 1 % Set left boundary
        Data = guidata(gcf);      
        but = 1;
        while but == 1
            [xi,~,but] = ginput(1);
            if ~isempty(Data.LeftHandle)
                delete(Data.LeftHandle);
            end
            YLim=get(gca,'YLim');
            
            Data.LeftHandle = plot(xi*[1 1],YLim,'k:');
            Data.LeftLimit  = xi; 
            but=0;
        end
        guidata(gcf,Data); %save guidata
        zoom on;
   case 2 % Set the right boundary
          Data = guidata(gcf);
          but = 1;
          while but == 1
            [xi,~,but] = ginput(1);
            if ~isempty(Data.RightHandle)
                delete(Data.RightHandle);
            end
            YLim=get(gca,'YLim');
            Data.RightHandle = plot(xi*[1 1],YLim,'k:');
            Data.RightLimit = xi;
            but=0;
          end
          guidata(gcf,Data); %save guidata
          zoom on;
    case 3 %apply limits
        Data = guidata(gcf);
        %disp(['Tstart = ' num2str(Data.LeftLimit,  '%3.3f')]);
        %disp(['Tstop  = ' num2str(Data.RightLimit, '%3.3f')]);
        Data.Index   = Data.Time<Data.RightLimit & Data.Time>Data.LeftLimit;
        guidata(gcf,Data); %save guidata
        
        CropForce     = Data.Force(Data.Index);
        CropExtension = Data.Extension(Data.Index);
        
        ForceExt_FitCropData(CropForce,CropExtension,Data.FileName,Data.LeftLimit,Data.RightLimit);
    case 4 %close the figures generated by fitting cropped portions of F(x)
        FigToClose = findobj('Tag','ForceExtFitFigure');
        if ~isempty(FigToClose)
            delete(FigToClose);
        end
end
