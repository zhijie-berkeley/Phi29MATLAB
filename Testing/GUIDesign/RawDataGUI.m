function RawDataGUI()
%PhageGUI, but now programmatic - GUIDE has bad limitations/bugs

%Add paths
thispath = fileparts(mfilename('fullpath'));
addpath (thispath)                      %PhageGUICrop
addpath ([thispath '\Helpers\'])        %Filename sorter
addpath ([thispath '\StepFind_KV\'])    %windowFilter

%Load settings file (or create one)
path = 'C:\Data';
file = 'phageMMDDYYN00.mat';
name = 'mmddyyN00';
if exist('GUIsettings.mat', 'file')
    load('GUIsettings.mat', 'path');
else
    c = 'Settings file for PhageGUI'; %#ok<*NASGU> - A lot of uicontrols will be unused, too - OK
    save('GUIsettings.mat', 'c');
end

%Declare variables for static workspace - or just shove everything in a struct
stepdata = [];
cropLines = {[] [] [] []};
stepLines = {[] []};
filtLine = [];
cropT = [];
conF = [];
timF = [];
forF = [];
fil = [];
dec = [];

%Construct figure
scrsz = get(0, 'ScreenSize');
%Default size is 3/4 of each dimension
fig = figure('Name', 'PhageGUIcrop', 'Position', [scrsz(3:4)/8 .75*scrsz(3:4)], 'Visible', 'off');

panaxs = uipanel('Position', [.1 0 .9 .95]);
mainAxis = axes('Parent', panaxs, 'Position', [.05 .31 .90 .68]);
hold(mainAxis,'on')
subAxis  = axes('Parent', panaxs, 'Position', [.05 .05 .90 .2]);
hold(subAxis, 'on')
linkaxes([mainAxis, subAxis], 'x')

%Top row of buttons
pantop = uipanel('Position', [0 .95 1 .05]);
loadFile = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [ 0, 0, .1, 1], 'String', 'Load File', 'Callback',@loadFile_callback);
loadCrop = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.1, 0, .1, 1], 'String', 'Load Crop', 'Callback',@loadCrop_callback);
permCrop = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.2, 0, .1, 1], 'String', 'Crop', 'Callback',@permCrop_callback);
measLine = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.3, 0, .1, 1], 'String', 'Measure', 'Callback',@measLine_callback);
trimTrace= uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.4, 0, .1, 1], 'String', 'Trim', 'Callback',@trimTrace_callback);
toWorksp = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.5, 0, .05, 1], 'String', 'ToWkspace' , 'Callback',@toWorksp_callback);
locNoise = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.55, 0, .05, 1], 'String', 'LocNoise' , 'Callback',@locNoise_callback);
customB1 = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.60, 0, .05, 1], 'String', 'But01', 'Callback',@custom01_callback);
customB2 = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.65, 0, .05, 1], 'String', 'But02', 'Callback',@custom02_callback);
trcNotes = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.7, 0, .2, 1], 'Style', 'text', 'String', 'Comment');
fixLimit = uicontrol('Parent', pantop, 'Units', 'normalized', 'Position', [.9, 0, .1, 1], 'String', 'Print' , 'Callback',@printFig_callback);

%Left bar of text inputs
panlef = uipanel('Position',[0 0 .1 .95]);
fileSlider= uicontrol('Parent', panlef, 'Style', 'slider', 'Units', 'normalized', 'Position', [0 .90 1 .1], 'Callback', @fileSlider_callback);
txtSlider = uicontrol('Parent', panlef, 'Style', 'text', 'Units', 'normalized', 'Position', [.15 .901 .7 .05], 'String', '1');
clrGraph  = uicontrol('Parent', panlef,                  'Units', 'normalized', 'Position', [0 .875 1 .025], 'String', 'Clear Graph', 'Callback', @clrGraph_callback);
filtFactT = uicontrol('Parent', panlef, 'Style', 'text', 'Units', 'normalized', 'Position', [0 .85 .5 .025], 'String', 'Filt Fact');
filtFact  = uicontrol('Parent', panlef, 'Style', 'edit', 'Units', 'normalized', 'Position', [0 .8 .5 .05], 'String', '[]', 'Callback', @refilter_callback);
deciFactT = uicontrol('Parent', panlef, 'Style', 'text', 'Units', 'normalized', 'Position', [.5 .85 .5 .025], 'String', 'Dec Fact');
deciFact  = uicontrol('Parent', panlef, 'Style', 'edit', 'Units', 'normalized', 'Position', [.5 .8 .5 .05], 'String', '1', 'Callback', @refilter_callback);

%Load first file
loadFile_callback

fig.Visible = 'on';

%%%%Callbacks
    function loadFile_callback(~,~, f, p)
        if nargin < 4
            %Prompt the user to select a file
            [f, p] = uigetfile([path filesep '*.dat'], 'MultiSelect','off','Pick a Phi29 Trace');
            if ~p; %No file selected, do nothing
                return
            end
            file = f;
            path = p;
            save('GUIsettings.mat', 'path', '-append')
            %Format the slider
            d = dir([path filesep '*.dat']);
            d = {d.name};
            len = length(d);
            %Sort, so it's by day then by N##
            d = sort_phage(d);
            fileSlider.Min = 1;
            fileSlider.Max = len;
            fileSlider.String = d;
            fileSlider.Enable = 'on';
            if len ==1
                fileSlider.Enable = 'off';
            else
                fileSlider.SliderStep = [1 10] ./ (len-1);
            end
        else
            file = f;
            path = p;
        end
        %Load the file
        load([path file],'stepdata');
        name = file(6:end-4);
        cla(mainAxis)
        fig.Name = sprintf('PhageGUIcrop %s', name);
        
        %Load comment
        if isfield(stepdata,'comment')
            trcNotes.String = stepdata.comment;
        else
            trcNotes.String = '';
        end
        
        fileSlider.Value = find(cellfun(@(x) strcmp(x, file),fileSlider.String),1);
        txtSlider.String = sprintf('%s\n%d/%d', name, round(fileSlider.Value), fileSlider.Max);
        
        %Plot
        refilter_callback
        fixLimit_callback
        loadCrop_callback
        locNoise_callback
    end

    function loadCrop_callback(~,~)
        %Create path of crop file
        cropfp = sprintf('%s\\CropFiles\\%s.crop', path, name);
        fid = fopen(cropfp);
        if fid == -1
            %fprintf('Crop not found for %s\n', name)
            return
        end
        
        ts = textscan(fid, '%f');
        fclose(fid);
        ts = ts{1};
        
        %Delete old lines
        if ~isempty(cropLines{1})
            cellfun(@delete, cropLines)
        end
        
        %Draw a line at the start/end crop bdys
        mainYLim = mainAxis.YLim;
        subYLim = subAxis.YLim;
        cropLines{1} = line(mainAxis,ts(1) * [1 1], mainYLim);
        cropLines{2} = line(mainAxis,ts(2) * [1 1], mainYLim);
        cropLines{3} = line(subAxis ,ts(1) * [1 1], subYLim);
        cropLines{4} = line(subAxis ,ts(2) * [1 1], subYLim);
        
        if mainAxis.XLim(1) > ts(1)
            mainAxis.XLim = [ts(1)-.5 mainAxis.XLim(2)];
        end
        if mainAxis.XLim(2) < ts(2)
            mainAxis.XLim = [mainAxis.XLim(1) ts(2)+0.5];
        end
    end

    function fileSlider_callback(~,~)
        file = fileSlider.String{round(fileSlider.Value)};
        loadFile_callback([], [], file, path)
    end

    function refilter_callback(~,~)
        %Filter
        fil = str2num(filtFact.String); %#ok<ST2NM>
        dec = str2double(deciFact.String);
        if ~isempty(fil) || dec ~= 1
            conF = cellfun(@(x)windowFilter(@mean, x, fil, dec),stepdata.contour,'UniformOutput',0);
            timF = cellfun(@(x)windowFilter(@mean, x, fil, dec),stepdata.time,'UniformOutput',0);
            forF = cellfun(@(x)windowFilter(@mean, x, fil, dec),stepdata.force,'UniformOutput',0);
        else
            conF = stepdata.contour;
            timF = stepdata.time;
            forF = stepdata.force;
        end
        
        %Plot force on bottom. Don't use cla to keep current window.
        arrayfun(@delete,subAxis.Children)
        cellfun(@(x,y)plot(subAxis, x, y, 'Color', [.7 .7 .7]), stepdata.time, stepdata.force)
        plotCell(subAxis, timF, forF)
        
        %Plot contour on top
        arrayfun(@delete,mainAxis.Children)
        %Hijacked for Moffit POV
        fulconF = cellfun(@(x)windowFilter(@mean, x, [], 2),stepdata.contour,'UniformOutput',0);
        fultimF = cellfun(@(x)windowFilter(@mean, x, [], 2),stepdata.time,'UniformOutput',0);
        cellfun(@(x,y)plot(mainAxis, x, y, 'Color', [.7 .7 .7]), fultimF, fulconF, 'UniformOutput', false);
        %/Hijack
%         cellfun(@(x,y)plot(mainAxis, x, y, 'Color', [.7 .7 .7]), stepdata.time, stepdata.contour, 'UniformOutput', false);
        filtLine = plotCell(mainAxis, timF, conF);
        
        %If cut segments are saved, plot in gray
        if isfield(stepdata, 'cut')
            cconF = cellfun(@(x)windowFilter(@mean, x, fil, dec),stepdata.cut.contour,'UniformOutput',0);
            ctimF = cellfun(@(x)windowFilter(@mean, x, fil, dec),stepdata.cut.time,'UniformOutput',0);
            cforF = cellfun(@(x)windowFilter(@mean, x, fil, dec),stepdata.cut.force,'UniformOutput',0);
            cellfun(@(x,y)plot(mainAxis,x,y,'Color',[.7 .7 .7]), stepdata.cut.time, stepdata.cut.contour)
            cellfun(@(x,y)plot(subAxis,x,y,'Color',[.7 .7 .7]), stepdata.cut.time, stepdata.cut.force)
            cellfun(@(x,y)plot(mainAxis,x,y,'Color',[.2 .2 .2]), ctimF, cconF)
            cellfun(@(x,y)plot(subAxis,x,y,'Color',[.2 .2 .2]), ctimF, cforF)
        end
    end

    function toWorksp_callback(~,~)
        assignin('base','guiCf',conF);
        assignin('base','guiTf',timF);
        assignin('base','guistepdata',stepdata);
    end

    function clrGraph_callback(~,~)
        %Delete all lines, text objects
        len = length(mainAxis.Children);
        %Is it faster to grab all of mainAxis.Children and index the reference?~~~~~~~~~~~~~
        toDel = false(1,len);
        for i = 1:len
            gobj = mainAxis.Children(i);
            if isgraphics(gobj, 'Text')
                toDel(i)=true;
            elseif isgraphics(gobj, 'Line') && length(gobj.XData) == 2;
                toDel(i)=true;
            end
        end
        arrayfun(@delete, mainAxis.Children(toDel))
    end

    function measLine_callback(~,~)
        [x, y] = ginput(2);
        dx = abs(diff(x));
        dy = abs(diff(y));
        
        line(x,y)
        text(x(end),y(end),sprintf('(dx,dy,m) = (%0.2f, %0.2f, %0.2f)\n',dx,dy,dy/dx), 'Clipping', 'on')
    end

    function permCrop_callback(~,~)
        [x, ~] = ginput(2);

        cropfp = sprintf('%s\\CropFiles\\%s.crop', path, name);
        cropp = fileparts(cropfp);
        if ~exist(cropp, 'dir')
            mkdir(cropp)
        end
        if ~issorted(x)
            if exist(cropfp, 'file')
                fprintf('Deleted crop for %s\n',name)
                delete(cropfp)
            end
            return
        end
        fid = fopen(cropfp, 'w');
        fwrite(fid, sprintf('%f\n%f', x));
        fclose(fid);
        loadCrop_callback
    end

    function trimTrace_callback(~,~)
        [x,~] = ginput(2);
        x = sort(x);
        
        ln1 = line([1 1]*x(1), [0 1e4]);
        ln2 = line([1 1]*x(2), [0 1e4]);
        drawnow
        switch questdlg('Trim here?','Trim?','Yes','No', 'No');
            case 'Yes'
                %Find index of first greater than start, last less than end
                cellfind = @(ce) (find(ce > x(1),1));
                cellfind2 = @(ce) (find(ce < x(2),1, 'last'));
                inds = cellfun(cellfind, stepdata.time, 'UniformOutput', false); 
                inds2 = cellfun(cellfind2, stepdata.time, 'UniformOutput', false);
                %Act on every field that is a cell
                fnames = fieldnames(stepdata);
                %Probably better to reverse j and k loops, but negligible performance difference
                for j = 1:length(fnames)
                    if iscell(stepdata.(fnames{j}))
                        temp = stepdata.(fnames{j});
                        for k = length(inds):-1:1 %process in reverse so cell removal, e.g. a(3) = [], doesn't disrupt indicies
                            %Check that there exists a min and a max - i.e. is within inds
                            st = inds{k};
                            en = inds2{k};
                            if ~isempty(st) && ~isempty(en)
                                temp2 = temp{k};
                                ln = length(temp2);
                                %Check for entire removal
                                if st ==1 && en == ln
                                    temp(k) = [];
                                    continue
                                    %Check for middle removal (both indicies not at bdy - then need to segment in two)
                                elseif st ~= 1 && en ~= ln
                                    left = temp2(1:st);
                                    right = temp2(en:end);
                                    temp = [temp(1:k-1) {left right} temp(k+1:end)];
                                    %Half removal
                                else
                                    temp2(st:en) = [];
                                    temp{k} = temp2;
                                end
                            end
                        end
                        stepdata.(fnames{j}) = temp;
                    end
                end
                %Remove cut bits that no longer are necessary
                if isfield(stepdata, 'cut')
                    fnames = fieldnames(stepdata.cut);
                    keepind = ~cellfun(@(x) any(x<stepdata.time{1}(1) | x>stepdata.time{end}(end)), stepdata.cut.time);
                    for j = 1:length(fnames)
                        stepdata.cut.(fnames{j}) = stepdata.cut.(fnames{j})(keepind);
                    end
                end
                
                switch questdlg('Edit comment?','Comment?','Yes','No', 'No');
                    case 'Yes'
                        resp = inputdlg('Comment', 'Enter new comment', [1,80], {trcNotes.String});
                        if ~isempty(resp)
                            trcNotes.String = resp{1};
                            stepdata.comment = trcNotes.String;
                        end
                end
                save([path file], 'stepdata')
                loadFile_callback([], [], file, path)
            case 'No'
                delete(ln1)
                delete(ln2)
        end
    end

    function fixLimit_callback(~,~)
        tlim = [stepdata.time{1}(1) stepdata.time{end}(end)];
%         clim = [min(cellfun(@min, stepdata.contour)), max(cellfun(@max, stepdata.contour))];
        flim = [min(cellfun(@min, stepdata.force)), max(cellfun(@max, stepdata.force))];
%         clim = [2500 5000];
        clim = [min(cellfun(@grabmin, stepdata.contour, stepdata.force)), max(cellfun(@grabmax, stepdata.contour, stepdata.force))];
        if length(clim) ~= 2
            clim = [0 6000];
        end
        zoom out
        xlim(mainAxis, tlim)
        ylim(mainAxis, clim)
        ylim(subAxis, flim)
        zoom reset
    end

    function m = grabmin(c, f)
        m = double(min(c(f>5)));
        if isempty(m)
            m = 1e4;
        end
    end

    function m = grabmax(c, f)
        m = double(max(c(f>5)));
        if isempty(m)
            m = 0;
        end
    end

    function locNoise_callback(~,~)
        %Plot the local noise levels every so-and-so points
        netlen = sum(cellfun(@length, stepdata.time));
        if netlen > 1e5
            noiwin = 1e3;
        else
            noiwin = 500;
        end
        szs = cellfun(@length, stepdata.time);
        szs = floor(szs/noiwin);
        for i = 1:length(stepdata.time)
            cfil = stepdata.contour{i} - smooth(stepdata.contour{i},125)';
            for j = 1:szs(i)
                %Estimate noise, annotate with text
                ran = (j-1)*noiwin+1:j*noiwin;
                textt = double(mean(stepdata.time{i}(ran([1 end]))));
                textc = double(mean(stepdata.contour{i}(ran)));
                textv = std(cfil(ran));
                %textv = sqrt(estimateNoise(stepdata.contour{i}(ran)));
                text(mainAxis, textt, textc+20, sprintf('%0.2f',textv), 'Rotation', 90, 'Clipping', 'on')
            end
        end
    end

    function custom01_callback(~,~)
        %{
        customB1.String = 'ConSec';
        a = ginput(2);
        a = sort(a(1:2));
        %find feedback cycle
        tstart = a(1);
        tend = a(2);
        inds = cellfun(@(x) ~isempty(find(x>tstart,1)) , stepdata.time);
        fcyc = find(inds,1);
        guiConSec = stepdata.contour{fcyc}( stepdata.time{fcyc} > tstart & stepdata.time{fcyc} < tend );
        assignin('base', 'guiConSec', guiConSec);
        %}
%         customB1.String = 'Recalc Contour';
%         %XWLC fcn
%         function outXpL = XWLC(F, P, S, kT)
%             %Simplification var.s
%             C1 = F*P/kT;
%             C2 = exp(nthroot(900./C1,4));
%             outXpL = 4/3 ...
%                 + -4./(3.*sqrt(C1+1)) ...
%                 + -10*C2 ./sqrt(C1) ./(C2-1).^2 ...
%                 + C1.^1.62 ./ (3.55+ 3.8* C1.^2.2) ...
%                 + F./S;
%         end
%         %Recalc XWLC
%         %DNA: PL=60, SM=550,nm/bp = 0.34
%         %GheD: 30, 1200
%         %RNA: 60 , 400, 0.27
%         %One on new: 43, 845
%         pl = 61;
%         sm = 500;
%         npb = 0.34;
%         stepdata.contour = cellfun(@(x,y) x ./ XWLC(y, pl, sm, 4.14)./ npb, stepdata.extension, stepdata.force, 'uni', 0);
%         refilter_callback


        customB1.String = 'AspectRatio';
        xl = mainAxis.XLim;
        yl = mainAxis.YLim;
        %Aspect ratio is 80px = 5bp, 50px = 200ms -> 1bp for 64ms on a square axis
        %Keep 
        yr = diff(yl);
        
        %get axes size from sizes of containing panels
        fgps = fig.Position(3:4);
        pnsz = panaxs.Position(3:4);
        axsz = mainAxis.Position(3:4);
        axdim = fgps.*pnsz.*axsz;
        %
        xr = yr * .064 * axdim(1)/axdim(2);
        mainAxis.XLim = xl(1) + [0 xr];
        cellfun(@(x)set(x,'LineWidth',2), filtLine)
    end

    function custom02_callback(~,~)
        addpath([thispath '\PairwiseDist']); %PWD code
        customB2.String = 'Take PWD';
        %plot PWD in separate window
        a = ginput(2);
        a = a(1:2);
        a = sort(a);
        cropfcn = @(x, y, z) x(y>z(1) & y<z(2) ); %cropfcn(con, tim, a) = con(tim>a(1) & tim<a(2))
        concrop = cellfun(@(x,y)cropfcn(x,y,a), stepdata.contour, stepdata.time, 'uni', 0);
%         concrop = [concrop{:}];
        concrop = concrop(~cellfun(@isempty, concrop));
        sumPWDV1b(concrop, 25, .1, 5);
        %sumPWD(concrop);
%         sumPWD(concrop, 50, 0.2);
%         sumPWD(concrop, 30, 0.2);
%         sumPWD(concrop, 10, 0.2);
    end

    function printFig_callback(~,~)
        print(fig, sprintf('.\\PhagePrtSc%s', datestr(now, 'yymmddHHMMSS')),'-dpng',sprintf('-r%d',96))
    end

%%%%Helpers
    function varargout = plotCell(ax, x, y)
        out = cell(1,length(x));
        for i = 1:length(x)
            out{i} = plot(ax, x{i}, y{i}, 'Color', getColor(i));
        end
        if nargout
            varargout{1} = out;
        end
    end

    function outColor = getColor(i)
        col0 = 2/3; %blue
        dcol = .1; %10 color cycle, enough to tell apart & slider fast-move is 10 segments
        h = mod(col0 + (i-1)*dcol,1); %Color wheel
        s = 1; %1 for bold colors, .25 for pastel-y colors
        v = .6; % too high makes yellow difficult to see, too low and everything is muddy
        outColor = hsv2rgb( h, s, v);
    end
end