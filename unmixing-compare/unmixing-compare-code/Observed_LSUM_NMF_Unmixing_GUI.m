function Observed_LSUM_NMF_Unmixing_GUI
% ============================================================
% Observed vs LSUM vs NMF Unmixing Viewer
%
% Required inputs:
%   1) animal merged raw txt/csv
%   2) LSUM full.csv
%   3) LSUM reference_spectra.csv
%   4) NMF full.csv
%   5) NMF spectra.csv
%
% What it shows:
%   - Observed mixed spectrum
%   - LSUM GCaMP contribution
%   - LSUM jRGECO contribution
%   - LSUM reconstruction
%   - NMF GCaMP contribution
%   - NMF jRGECO contribution
%   - NMF reconstruction
%   - All-overlaid plot
%   - Residual plot
% ============================================================

clear; clc;

%% State
app = struct();
app.mixedFile = "";
app.lsumFullFile = "";
app.lsumRefFile = "";
app.nmfFullFile = "";
app.nmfSpectraFile = "";

app.raw = [];
app.wavelengths = [];
app.lsum = table();
app.nmf = table();
app.lsumRef = table();
app.nmfSpec = table();

app.obs = [];
app.lsumG = [];
app.lsumR = [];
app.lsumRecon = [];
app.nmfG = [];
app.nmfR = [];
app.nmfRecon = [];
app.meta = table();

%% UI
fig = uifigure('Name','Observed vs LSUM vs NMF Unmixing Viewer', ...
    'Position',[80 60 1500 880]);

mainGrid = uigridlayout(fig,[1 2]);
mainGrid.ColumnWidth = {360,'1x'};
mainGrid.RowHeight = {'1x'};
mainGrid.Padding = [10 10 10 10];

%% Left
left = uipanel(mainGrid,'Title','Input / Controls','FontWeight','bold');
lg = uigridlayout(left,[16 1]);
lg.RowHeight = {36,24,36,24,36,24,36,24,36,24,36,32,32,32,'1x',32};
lg.Padding = [10 10 10 10];

uibutton(lg,'Text','Browse mixed merged txt/csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseMixed());
lblMixed = uilabel(lg,'Text','No mixed file','WordWrap','on');

uibutton(lg,'Text','Browse LSUM full.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseLSUMFull());
lblLSUMFull = uilabel(lg,'Text','No LSUM full','WordWrap','on');

uibutton(lg,'Text','Browse LSUM reference_spectra.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseLSUMRef());
lblLSUMRef = uilabel(lg,'Text','No LSUM reference','WordWrap','on');

uibutton(lg,'Text','Browse NMF full.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseNMFFull());
lblNMFFull = uilabel(lg,'Text','No NMF full','WordWrap','on');

uibutton(lg,'Text','Browse NMF spectra.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseNMFSpectra());
lblNMFSpectra = uilabel(lg,'Text','No NMF spectra','WordWrap','on');

uibutton(lg,'Text','Load / Build Reconstructions','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) loadAll());

uibutton(lg,...
    'Text','Export all metrics CSV',...
    'ButtonPushedFcn',@(b,e) exportAllMetrics());

uilabel(lg,'Text','Select trial:','FontWeight','bold');
ddTrial = uidropdown(lg,'Items',{'-'}, ...
    'ValueChangedFcn',@(dd,e) updateTrialRange());

uilabel(lg,'Text','Select TrialTimepoint:','FontWeight','bold');
spTime = uispinner(lg,'Limits',[0 1],'Value',0,'Step',1, ...
    'ValueChangedFcn',@(s,e) updatePlots());

txtStatus = uitextarea(lg,'Editable','off', ...
    'Value',{'Status: select files.'});

uibutton(lg,'Text','Save current tab PNG', ...
    'ButtonPushedFcn',@(b,e) saveCurrentTab());

%% Right tabs
tabs = uitabgroup(mainGrid);

tabOverlay = uitab(tabs,'Title','1. Overlay');
tabStack   = uitab(tabs,'Title','2. Contributions');
tabResid   = uitab(tabs,'Title','3. Residual');
tabMetric  = uitab(tabs,'Title','4. Peak metrics');

%% Overlay tab
g = uigridlayout(tabOverlay,[1 1]);
g.Padding = [10 10 10 10];
axOverlay = uiaxes(g);
title(axOverlay,'Observed vs LSUM reconstruction vs NMF reconstruction');
xlabel(axOverlay,'Wavelength (nm)');
ylabel(axOverlay,'Intensity');
grid(axOverlay,'on');

%% Stack tab
g = uigridlayout(tabStack,[7 1]);
g.Padding = [10 10 10 10];
g.RowHeight = {'1x','1x','1x','1x','1x','1x','1x'};

axObs = uiaxes(g);
title(axObs,'Observed mixed spectrum');
xlabel(axObs,'Wavelength (nm)');
ylabel(axObs,'Intensity');
grid(axObs,'on');

axLSUMG = uiaxes(g);
title(axLSUMG,'LSUM - GCaMP contribution');
xlabel(axLSUMG,'Wavelength (nm)');
ylabel(axLSUMG,'Intensity');
grid(axLSUMG,'on');

axLSUMR = uiaxes(g);
title(axLSUMR,'LSUM - jRGECO contribution');
xlabel(axLSUMR,'Wavelength (nm)');
ylabel(axLSUMR,'Intensity');
grid(axLSUMR,'on');

axLSUMRecon = uiaxes(g);
title(axLSUMRecon,'LSUM - Reconstruction');
xlabel(axLSUMRecon,'Wavelength (nm)');
ylabel(axLSUMRecon,'Intensity');
grid(axLSUMRecon,'on');

axNMFG = uiaxes(g);
title(axNMFG,'NMF - GCaMP contribution');
xlabel(axNMFG,'Wavelength (nm)');
ylabel(axNMFG,'Intensity');
grid(axNMFG,'on');

axNMFR = uiaxes(g);
title(axNMFR,'NMF - jRGECO contribution');
xlabel(axNMFR,'Wavelength (nm)');
ylabel(axNMFR,'Intensity');
grid(axNMFR,'on');

axNMFRecon = uiaxes(g);
title(axNMFRecon,'NMF - Reconstruction');
xlabel(axNMFRecon,'Wavelength (nm)');
ylabel(axNMFRecon,'Intensity');
grid(axNMFRecon,'on');

%% Residual tab
g = uigridlayout(tabResid,[2 1]);
g.Padding = [10 10 10 10];

axResid = uiaxes(g);
title(axResid,'Residual spectrum: Observed - Reconstruction');
xlabel(axResid,'Wavelength (nm)');
ylabel(axResid,'Residual');
grid(axResid,'on');

axAbsResid = uiaxes(g);
title(axAbsResid,'Absolute residual comparison');
xlabel(axAbsResid,'Wavelength (nm)');
ylabel(axAbsResidualLabel());
grid(axAbsResid,'on');

%% Peak metric tab
g = uigridlayout(tabMetric,[2 1]);
g.Padding = [10 10 10 10];
g.RowHeight = {'1.2x','1x'};

axMetricBar = uiaxes(g);
title(axMetricBar,'Peak-region RMSE comparison');
xlabel(axMetricBar,'Region');
ylabel(axMetricBar,'RMSE');
grid(axMetricBar,'on');

metricTableUI = uitable(g);

%% Callbacks
    function browseMixed()
        [file,path] = uigetfile({'*.txt;*.csv','TXT/CSV files'},'Select mixed merged raw file');
        if isequal(file,0), return; end
        app.mixedFile = string(fullfile(path,file));
        lblMixed.Text = file;
    end

    function browseLSUMFull()
        [file,path] = uigetfile({'*.csv','CSV files'},'Select LSUM full.csv');
        if isequal(file,0), return; end
        app.lsumFullFile = string(fullfile(path,file));
        lblLSUMFull.Text = file;
    end

    function browseLSUMRef()
        [file,path] = uigetfile({'*.csv','CSV files'},'Select LSUM reference_spectra.csv');
        if isequal(file,0), return; end
        app.lsumRefFile = string(fullfile(path,file));
        lblLSUMRef.Text = file;
    end

    function browseNMFFull()
        [file,path] = uigetfile({'*.csv','CSV files'},'Select NMF full.csv');
        if isequal(file,0), return; end
        app.nmfFullFile = string(fullfile(path,file));
        lblNMFFull.Text = file;
    end

    function browseNMFSpectra()
        [file,path] = uigetfile({'*.csv','CSV files'},'Select NMF spectra.csv');
        if isequal(file,0), return; end
        app.nmfSpectraFile = string(fullfile(path,file));
        lblNMFSpectra.Text = file;
    end

    function loadAll()
        try
            requireFile(app.mixedFile,'mixed merged file');
            requireFile(app.lsumFullFile,'LSUM full.csv');
            requireFile(app.lsumRefFile,'LSUM reference_spectra.csv');
            requireFile(app.nmfFullFile,'NMF full.csv');
            requireFile(app.nmfSpectraFile,'NMF spectra.csv');

            [wlRaw, rawSpectra] = readMixedFile(app.mixedFile);
            mask = wlRaw >= 450 & wlRaw <= 700;
            wl = wlRaw(mask);
            raw = rawSpectra(:,mask);

            app.lsum = readtable(app.lsumFullFile,'VariableNamingRule','preserve');
            app.nmf = readtable(app.nmfFullFile,'VariableNamingRule','preserve');
            app.lsumRef = readtable(app.lsumRefFile,'VariableNamingRule','preserve');
            app.nmfSpec = readtable(app.nmfSpectraFile,'VariableNamingRule','preserve');

            app.lsum = standardizeFull(app.lsum,'LSUM');
            app.nmf  = standardizeFull(app.nmf,'NMF');

            if height(app.lsum) ~= size(raw,1)
                error('Mixed raw timepoints와 LSUM rows가 다릅니다.');
            end
            if height(app.nmf) ~= size(raw,1)
                error('Mixed raw timepoints와 NMF rows가 다릅니다.');
            end

            app.wavelengths = wl(:);
            app.raw = raw;
            app.meta = app.nmf(:,{'Trial','TrialTimepoint','Timepoint_Global'});

            buildReconstructions();

            trials = unique(app.meta.Trial);
            ddTrial.Items = cellstr(string(trials));
            ddTrial.Value = ddTrial.Items{1};
            updateTrialRange();

            txtStatus.Value = {
                'Status: loaded successfully.'
                sprintf('Timepoints: %d',height(app.meta))
                sprintf('Wavelengths: %d',numel(app.wavelengths))
                sprintf('Trials: %d',numel(trials))
                };

        catch ME
            txtStatus.Value = {'Status: error', ME.message};
            uialert(fig,ME.message,'Load error');
        end
    end

    function buildReconstructions()
        wl = app.wavelengths;
        app.obs = app.raw;

        lsumWL = getColumn(app.lsumRef,["Wavelength_nm","Wavelength"]);
        lsumGRef = getColumn(app.lsumRef,["GCaMP_reference","GCaMP"]);
        lsumRRef = getColumn(app.lsumRef,["jRGECO_reference","jRGECO"]);

        lsumGRef = interp1(lsumWL,lsumGRef,wl,'linear',0);
        lsumRRef = interp1(lsumWL,lsumRRef,wl,'linear',0);

        gCoef = app.lsum.LSUM_GCaMP_raw;
        rCoef = app.lsum.LSUM_jRGECO_raw;
        intercept = app.lsum.Intercept;

        app.lsumG = gCoef(:) * lsumGRef(:)';
        app.lsumR = rCoef(:) * lsumRRef(:)';
        app.lsumRecon = app.lsumG + app.lsumR + intercept(:);

        nmfWL = getColumn(app.nmfSpec,["Wavelength_nm","Wavelength"]);
        nmfGSpec = getColumn(app.nmfSpec,["GCaMP_spectrum","GCaMP"]);
        nmfRSpec = getColumn(app.nmfSpec,["jRGECO_spectrum","jRGECO"]);

        nmfGSpec = interp1(nmfWL,nmfGSpec,wl,'linear',0);
        nmfRSpec = interp1(nmfWL,nmfRSpec,wl,'linear',0);

        app.nmfG = app.nmf.NMF_GCaMP_raw(:) * nmfGSpec(:)';
        app.nmfR = app.nmf.NMF_jRGECO_raw(:) * nmfRSpec(:)';
        app.nmfRecon = app.nmfG + app.nmfR;
    end

    function updateTrialRange()
        if isempty(app.meta) || strcmp(ddTrial.Value,'-')
            return;
        end

        tr = str2double(ddTrial.Value);
        idx = app.meta.Trial == tr;
        tt = app.meta.TrialTimepoint(idx);

        spTime.Limits = [min(tt), max(tt)];
        spTime.Value = min(tt);
        updatePlots();
    end

    function updatePlots()
        if isempty(app.obs) || strcmp(ddTrial.Value,'-')
            return;
        end

        tr = str2double(ddTrial.Value);
        tt = round(spTime.Value);

        idx = find(app.meta.Trial==tr & app.meta.TrialTimepoint==tt,1);
        if isempty(idx), return; end

        wl = app.wavelengths;

        obs = app.obs(idx,:);
        lsumG = app.lsumG(idx,:);
        lsumR = app.lsumR(idx,:);
        lsumRecon = app.lsumRecon(idx,:);
        nmfG = app.nmfG(idx,:);
        nmfR = app.nmfR(idx,:);
        nmfRecon = app.nmfRecon(idx,:);

        globalT = app.meta.Timepoint_Global(idx);

        cla(axOverlay);
        plot(axOverlay,wl,obs,'k','LineWidth',1.6);
        hold(axOverlay,'on');
        plot(axOverlay,wl,lsumRecon,'b--','LineWidth',1.4);
        plot(axOverlay,wl,nmfRecon,'r--','LineWidth',1.4);
        hold(axOverlay,'off');
        title(axOverlay,sprintf('Observed vs Reconstruction | Trial %d | TrialTimepoint %d | Global %d', ...
            tr, tt, globalT));
        xlabel(axOverlay,'Wavelength (nm)');
        ylabel(axOverlay,'Intensity');
        legend(axOverlay,{'Observed','LSUM reconstruction','NMF reconstruction'},'Location','best');
        grid(axOverlay,'on');

        plotOne(axObs,wl,obs,[0 0 0],'-','Observed mixed spectrum',{'Observed'});
        plotOne(axLSUMG,wl,lsumG,[0 0.2 1],'-','LSUM - GCaMP contribution',{'GCaMP'});
        plotOne(axLSUMR,wl,lsumR,[1 0.3 0],'-','LSUM - jRGECO contribution',{'jRGECO'});
        plotOne(axLSUMRecon,wl,lsumRecon,[0 0.2 1],'--','LSUM - Reconstruction',{'LSUM recon'});
        plotOne(axNMFG,wl,nmfG,[0 0.55 0],'-','NMF - GCaMP contribution',{'GCaMP'});
        plotOne(axNMFR,wl,nmfR,[1 0.3 0],'-','NMF - jRGECO contribution',{'jRGECO'});
        plotOne(axNMFRecon,wl,nmfRecon,[0 0.55 0],'--','NMF - Reconstruction',{'NMF recon'});

        lsumResid = obs - lsumRecon;
        nmfResid = obs - nmfRecon;

        cla(axResid);
        plot(axResid,wl,lsumResid,'b','LineWidth',1.2);
        hold(axResid,'on');
        plot(axResid,wl,nmfResid,'r','LineWidth',1.2);
        yline(axResid,0,'k--');
        hold(axResid,'off');
        title(axResid,'Residual: Observed - Reconstruction');
        xlabel(axResid,'Wavelength (nm)');
        ylabel(axResid,'Residual');
        legend(axResid,{'Observed-LSUM','Observed-NMF'},'Location','best');
        grid(axResid,'on');

        cla(axAbsResid);
        plot(axAbsResid,wl,abs(lsumResid),'b','LineWidth',1.2);
        hold(axAbsResid,'on');
        plot(axAbsResid,wl,abs(nmfResid),'r','LineWidth',1.2);
        hold(axAbsResid,'off');
        title(axAbsResid,sprintf('Absolute residual | LSUM mean %.4g | NMF mean %.4g', ...
            mean(abs(lsumResid),'omitnan'), mean(abs(nmfResid),'omitnan')));
        xlabel(axAbsResid,'Wavelength (nm)');
        ylabel(axAbsResidualLabel());
        legend(axAbsResid,{'|Observed-LSUM|','|Observed-NMF|'},'Location','best');
        grid(axAbsResid,'on');

        peakInfo = getPeakRegions(wl,nmfG,nmfR,15);

        metricTbl = [
            makeMetricRow(tr,tt,globalT,"Full",peakInfo.Full_range, ...
                obs,lsumRecon,nmfRecon,peakInfo.Full_mask);

            makeMetricRow(tr,tt,globalT,"GCaMP_peak",peakInfo.GCaMP_range, ...
                obs,lsumRecon,nmfRecon,peakInfo.GCaMP_mask);

            makeMetricRow(tr,tt,globalT,"jRGECO_peak",peakInfo.jRGECO_range, ...
                obs,lsumRecon,nmfRecon,peakInfo.jRGECO_mask)
        ];

        metricTableUI.Data = metricTbl;
        metricTableUI.ColumnName = metricTbl.Properties.VariableNames;

        cla(axMetricBar);
        bar(axMetricBar,categorical(metricTbl.Region), ...
            [metricTbl.LSUM_RMSE metricTbl.NMF_RMSE]);

        ylabel(axMetricBar,'RMSE');
        title(axMetricBar,sprintf('Peak-region RMSE | Trial %d | Timepoint %d',tr,tt));
        legend(axMetricBar,{'LSUM','NMF'},'Location','best');
        grid(axMetricBar,'on');
    end


    function exportAllMetrics()
        if isempty(app.obs)
            uialert(fig,'먼저 Load / Build Reconstructions를 실행하세요.','No data');
            return;
        end

        folder = uigetdir(pwd,'Save all metrics CSV');
        if isequal(folder,0), return; end

        wl = app.wavelengths;
        peakInfo = getPeakRegions(wl, app.nmfG(1,:), app.nmfR(1,:), 15);

        All = table();

        for i = 1:height(app.meta)
            tr = app.meta.Trial(i);
            tt = app.meta.TrialTimepoint(i);
            gt = app.meta.Timepoint_Global(i);

            obs = app.obs(i,:);
            lsumRecon = app.lsumRecon(i,:);
            nmfRecon = app.nmfRecon(i,:);

            rows = [
                makeMetricRow(tr,tt,gt,"Full",peakInfo.Full_range, ...
                obs,lsumRecon,nmfRecon,peakInfo.Full_mask);

                makeMetricRow(tr,tt,gt,"GCaMP_peak",peakInfo.GCaMP_range, ...
                obs,lsumRecon,nmfRecon,peakInfo.GCaMP_mask);

                makeMetricRow(tr,tt,gt,"jRGECO_peak",peakInfo.jRGECO_range, ...
                obs,lsumRecon,nmfRecon,peakInfo.jRGECO_mask)
                ];

            All = [All; rows];
        end

        writetable(All, fullfile(folder,'all_timepoint_peak_metrics.csv'));

        Summary = groupsummary(All, {'Region'}, 'mean', ...
            {'LSUM_RMSE','NMF_RMSE','LSUM_MAE','NMF_MAE','LSUM_R2','NMF_R2'});

        writetable(Summary, fullfile(folder,'overall_region_summary.csv'));

        TrialSummary = groupsummary(All, {'Trial','Region'}, 'mean', ...
            {'LSUM_RMSE','NMF_RMSE','LSUM_MAE','NMF_MAE','LSUM_R2','NMF_R2'});

        writetable(TrialSummary, fullfile(folder,'trial_region_summary.csv'));

        uialert(fig,'전체 timepoint metrics 저장 완료.','Saved');
    end

    function saveCurrentTab()
        folder = uigetdir(pwd,'Select save folder');
        if isequal(folder,0), return; end

        f = figure('Visible','off','Color','w','Position',[100 100 1300 850]);
        selected = tabs.SelectedTab;

        if selected == tabOverlay
            ax = axes(f);
            copyAxes(axOverlay,ax);
            out = 'overlay_observed_lsum_nmf.png';

        elseif selected == tabStack
            tiledlayout(f,7,1,'Padding','compact','TileSpacing','compact');
            axs = [axObs axLSUMG axLSUMR axLSUMRecon axNMFG axNMFR axNMFRecon];
            for k = 1:numel(axs)
                ax = nexttile;
                copyAxes(axs(k),ax);
            end
            out = 'contribution_stack.png';

        elseif selected == tabResid
            tiledlayout(f,2,1,'Padding','compact','TileSpacing','compact');
            ax = nexttile; copyAxes(axResid,ax);
            ax = nexttile; copyAxes(axAbsResid,ax);
            out = 'residual_comparison.png';

        elseif selected == tabMetric
            ax = axes(f);
            copyAxes(axMetricBar,ax);
            out = 'peak_region_metrics.png';
        end

        exportgraphics(f,fullfile(folder,out),'Resolution',300);
        close(f);
        uialert(fig,'Saved.','Save complete');
    end
end

%% Helper functions

function requireFile(f,label)
    if strlength(f)==0
        error('Missing file: %s',label);
    end
end

function y = axAbsResidualLabel()
    y = 'Absolute residual';
end

function plotOne(ax,wl,y,colorSpec,lineStyle,titleStr,legendStr)
    cla(ax);
    plot(ax,wl,y, ...
        'Color',colorSpec, ...
        'LineStyle',lineStyle, ...
        'LineWidth',1.3);

    title(ax,titleStr);
    xlabel(ax,'Wavelength (nm)');
    ylabel(ax,'Intensity');
    legend(ax,legendStr,'Location','best');
    grid(ax,'on');
end

function T = standardizeFull(T,methodName)
    vars = string(T.Properties.VariableNames);

    if ~ismember("Trial",vars)
        error('%s file has no Trial column.',methodName);
    end

    T2 = table();
    T2.Trial = double(T.Trial);

    if ismember("TrialTimepoint",vars)
        T2.TrialTimepoint = double(T.TrialTimepoint);
    else
        T2.TrialTimepoint = makeTrialTimepointFromTrial(T2.Trial);
    end

    if ismember("Timepoint_Global",vars)
        T2.Timepoint_Global = double(T.Timepoint_Global);
    elseif ismember("TimePoint_Global",vars)
        T2.Timepoint_Global = double(T.TimePoint_Global);
    elseif ismember("Timepoint",vars)
        T2.Timepoint_Global = double(T.Timepoint);
    elseif ismember("TimePoint",vars)
        T2.Timepoint_Global = double(T.TimePoint);
    else
        T2.Timepoint_Global = (0:height(T)-1)';
    end

    gRaw = findColumn(vars,["Coeff_of_GCaMP","GCaMP"], ...
        ["z","ratio","intercept","r_squared","timepoint","trial"]);
    rRaw = findColumn(vars,["Coeff_of_jRGECO","jRGECO"], ...
        ["z","ratio","intercept","r_squared","timepoint","trial"]);

    if strlength(gRaw)==0
        error('%s file: cannot find GCaMP coefficient.',methodName);
    end
    if strlength(rRaw)==0
        error('%s file: cannot find jRGECO coefficient.',methodName);
    end

    T2.([methodName '_GCaMP_raw']) = double(T.(gRaw));
    T2.([methodName '_jRGECO_raw']) = double(T.(rRaw));

    if ismember("Intercept",vars)
        T2.Intercept = double(T.Intercept);
    else
        T2.Intercept = zeros(height(T),1);
    end

    T = T2;
end

function col = findColumn(vars,includeList,excludeList)
    col = "";
    lowerVars = lower(vars);

    for i = 1:numel(includeList)
        hit = contains(lowerVars,lower(includeList(i)));

        for j = 1:numel(excludeList)
            hit = hit & ~contains(lowerVars,lower(excludeList(j)));
        end

        idx = find(hit,1);
        if ~isempty(idx)
            col = vars(idx);
            return;
        end
    end
end

function trialTimepoint = makeTrialTimepointFromTrial(trialVec)
    trialVec = trialVec(:);
    trialTimepoint = zeros(size(trialVec));
    trials = unique(trialVec);

    for i = 1:numel(trials)
        idx = trialVec == trials(i);
        trialTimepoint(idx) = (0:sum(idx)-1)';
    end
end

function c = getColumn(T,candidates)
    vars = string(T.Properties.VariableNames);

    for i = 1:numel(candidates)
        idx = find(strcmpi(vars,candidates(i)),1);
        if ~isempty(idx)
            c = double(T.(vars(idx)));
            c = c(:);
            return;
        end
    end

    for i = 1:numel(candidates)
        idx = find(contains(lower(vars),lower(candidates(i))),1);
        if ~isempty(idx)
            c = double(T.(vars(idx)));
            c = c(:);
            return;
        end
    end

    error('Cannot find column: %s',strjoin(candidates,", "));
end

function [wavelengths,spectra] = readMixedFile(filename)
    filename = string(filename);
    lines = readlines(filename);
    start_idx = find(contains(lines,'>>>>>Begin Spectral Data<<<<<'),1);

    if ~isempty(start_idx)
        data_lines = lines(start_idx+1:end);
        data_lines = data_lines(strlength(strtrim(data_lines)) > 0);

        header = split(strtrim(data_lines(1)));
        wavelengths = str2double(header);
        wavelengths = wavelengths(~isnan(wavelengths));
        nPix = numel(wavelengths);

        spectra = [];

        for i = 2:numel(data_lines)
            row = split(strtrim(data_lines(i)));
            if numel(row) >= nPix + 3
                numeric_part = str2double(row(end-nPix+1:end));
                if all(~isnan(numeric_part))
                    spectra = [spectra; numeric_part']; %#ok<AGROW>
                end
            end
        end
        return;
    end

    T = readtable(filename,'VariableNamingRule','preserve');
    vars = string(T.Properties.VariableNames);

    wl = nan(size(vars));
    for k = 1:numel(vars)
        name = vars(k);
        temp = str2double(name);

        if isnan(temp)
            name2 = erase(name,"wl_");
            name2 = erase(name2,"x");
            name2 = replace(name2,"_",".");
            temp = str2double(name2);
        end

        wl(k) = temp;
    end

    mask = ~isnan(wl);
    wavelengths = wl(mask);
    spectra = double(T{:,mask});
end

function peakInfo = getPeakRegions(wl,gSpec,rSpec,halfWidthNm)
    wl = wl(:);
    gSpec = gSpec(:);
    rSpec = rSpec(:);

    [~,idxG] = max(gSpec);
    [~,idxR] = max(rSpec);

    gPeak = wl(idxG);
    rPeak = wl(idxR);

    gMask = wl >= gPeak-halfWidthNm & wl <= gPeak+halfWidthNm;
    rMask = wl >= rPeak-halfWidthNm & wl <= rPeak+halfWidthNm;
    fullMask = true(size(wl));

    peakInfo = struct();
    peakInfo.GCaMP_peak_nm = gPeak;
    peakInfo.jRGECO_peak_nm = rPeak;

    peakInfo.GCaMP_mask = gMask;
    peakInfo.jRGECO_mask = rMask;
    peakInfo.Full_mask = fullMask;

    peakInfo.GCaMP_range = [gPeak-halfWidthNm, gPeak+halfWidthNm];
    peakInfo.jRGECO_range = [rPeak-halfWidthNm, rPeak+halfWidthNm];
    peakInfo.Full_range = [min(wl), max(wl)];
end

function metrics = calcFitMetrics(y,yhat)
    y = y(:);
    yhat = yhat(:);

    valid = isfinite(y) & isfinite(yhat);
    y = y(valid);
    yhat = yhat(valid);

    residual = y - yhat;

    metrics = struct();
    metrics.MAE = mean(abs(residual),'omitnan');
    metrics.RMSE = sqrt(mean(residual.^2,'omitnan'));
    metrics.MeanResidual = mean(residual,'omitnan');
    metrics.MeanAbsResidual = metrics.MAE;

    ssRes = sum(residual.^2,'omitnan');
    ssTot = sum((y - mean(y,'omitnan')).^2,'omitnan');

    if ssTot == 0
        metrics.R2 = NaN;
    else
        metrics.R2 = 1 - ssRes/ssTot;
    end
end

function rowTbl = makeMetricRow(trialNum,trialTimepoint,globalTimepoint,regionName,regionRange, ...
    obs,lsumRecon,nmfRecon,mask)

    L = calcFitMetrics(obs(mask),lsumRecon(mask));
    N = calcFitMetrics(obs(mask),nmfRecon(mask));

    if L.RMSE < N.RMSE
        better = "LSUM";
    elseif N.RMSE < L.RMSE
        better = "NMF";
    else
        better = "Tie";
    end

    rowTbl = table( ...
        trialNum, ...
        trialTimepoint, ...
        globalTimepoint, ...
        string(regionName), ...
        regionRange(1), ...
        regionRange(2), ...
        L.R2, ...
        N.R2, ...
        L.RMSE, ...
        N.RMSE, ...
        L.MAE, ...
        N.MAE, ...
        L.MeanResidual, ...
        N.MeanResidual, ...
        string(better), ...
        'VariableNames', { ...
            'Trial', ...
            'TrialTimepoint', ...
            'Timepoint_Global', ...
            'Region', ...
            'RegionStart_nm', ...
            'RegionEnd_nm', ...
            'LSUM_R2', ...
            'NMF_R2', ...
            'LSUM_RMSE', ...
            'NMF_RMSE', ...
            'LSUM_MAE', ...
            'NMF_MAE', ...
            'LSUM_MeanResidual', ...
            'NMF_MeanResidual', ...
            'BetterByRMSE' ...
        });
end

function copyAxes(src,dst)
    children = allchild(src);
    copyobj(children,dst);

    title(dst,src.Title.String);
    xlabel(dst,src.XLabel.String);
    ylabel(dst,src.YLabel.String);
    grid(dst,'on');

    try
        legend(dst,'show','Location','best');
    catch
    end
end