function LSUM_NMF_Compare_GUI
% ============================================================
% LSUM vs NMF-RI Compare GUI
%
% Inputs:
%   1) LSUM full.csv
%   2) NMF full.csv
%
% Main comparison:
%   - GCaMP trace overlay
%   - jRGECO trace overlay
%   - Method correlation per trial
%   - Internal GCaMP-jRGECO correlation
%   - Peak time / peak amplitude comparison
%   - Summary CSV export
% ============================================================

clear; clc;

%% App state
app = struct();
app.lsumFile = "";
app.nmfFile = "";
app.lsum = table();
app.nmf = table();
app.merged = table();
app.summary = table();

%% UI
fig = uifigure('Name','LSUM vs NMF-RI Compare GUI', ...
    'Position',[80 60 1400 820]);

mainGrid = uigridlayout(fig,[1 2]);
mainGrid.ColumnWidth = {360,'1x'};
mainGrid.RowHeight = {'1x'};
mainGrid.Padding = [10 10 10 10];

%% Left panel
leftPanel = uipanel(mainGrid,'Title','Input / Controls','FontWeight','bold');
leftGrid = uigridlayout(leftPanel,[10 1]);
leftGrid.RowHeight = {45,30,45,30,45,35,35,35,'1x',40};
leftGrid.Padding = [10 10 10 10];

uibutton(leftGrid,'Text','Browse LSUM full.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseLSUM());
lblLSUM = uilabel(leftGrid,'Text','No LSUM file selected','WordWrap','on');

uibutton(leftGrid,'Text','Browse NMF full.csv','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) browseNMF());
lblNMF = uilabel(leftGrid,'Text','No NMF file selected','WordWrap','on');

uibutton(leftGrid,'Text','Run comparison','FontWeight','bold', ...
    'ButtonPushedFcn',@(b,e) runComparison());

uilabel(leftGrid,'Text','Select trial:','FontWeight','bold');
ddTrial = uidropdown(leftGrid,'Items',{'-'}, ...
    'ValueChangedFcn',@(dd,e) updateTrialPlots());

uibutton(leftGrid,'Text','Save summary CSV', ...
    'ButtonPushedFcn',@(b,e) saveSummary());

txtStatus = uitextarea(leftGrid,'Editable','off', ...
    'Value',{'Status: select LSUM and NMF full.csv files.'});

uibutton(leftGrid,'Text','Save current figure tab', ...
    'ButtonPushedFcn',@(b,e) saveCurrentTab());

%% Right panel tabs
tabGroup = uitabgroup(mainGrid);

tabTrace = uitab(tabGroup,'Title','1. Trace overlay');
tabCorr  = uitab(tabGroup,'Title','2. Correlation summary');
tabPeak  = uitab(tabGroup,'Title','3. Peak comparison');
tabTable = uitab(tabGroup,'Title','4. Summary table');

%% Trace tab
g = uigridlayout(tabTrace,[2 1]);
g.Padding = [10 10 10 10];

axGCaMP = uiaxes(g);
title(axGCaMP,'GCaMP z-trace: LSUM vs NMF');
xlabel(axGCaMP,'TrialTimepoint');
ylabel(axGCaMP,'Z-score');
grid(axGCaMP,'on');

axJR = uiaxes(g);
title(axJR,'jRGECO z-trace: LSUM vs NMF');
xlabel(axJR,'TrialTimepoint');
ylabel(axJR,'Z-score');
grid(axJR,'on');

%% Corr tab
g = uigridlayout(tabCorr,[2 1]);
g.Padding = [10 10 10 10];

axMethodCorr = uiaxes(g);
title(axMethodCorr,'Method correlation per trial');
xlabel(axMethodCorr,'Trial');
ylabel(axMethodCorr,'Correlation');
ylim(axMethodCorr,[-1 1]);
grid(axMethodCorr,'on');

axInternalCorr = uiaxes(g);
title(axInternalCorr,'Internal GCaMP-jRGECO correlation per trial');
xlabel(axInternalCorr,'Trial');
ylabel(axInternalCorr,'Correlation');
ylim(axInternalCorr,[-1 1]);
grid(axInternalCorr,'on');

%% Peak tab
g = uigridlayout(tabPeak,[2 1]);
g.Padding = [10 10 10 10];

axPeakTime = uiaxes(g);
title(axPeakTime,'Peak timepoint comparison');
xlabel(axPeakTime,'Trial');
ylabel(axPeakTime,'Peak TrialTimepoint');
grid(axPeakTime,'on');

axPeakAmp = uiaxes(g);
title(axPeakAmp,'Peak amplitude comparison');
xlabel(axPeakAmp,'Trial');
ylabel(axPeakAmp,'Peak z-score');
grid(axPeakAmp,'on');

%% Table tab
g = uigridlayout(tabTable,[1 1]);
summaryTableUI = uitable(g);

%% Callbacks
    function browseLSUM()
        [file,path] = uigetfile({'*.csv','CSV files'},'Select LSUM full.csv');
        if isequal(file,0), return; end
        app.lsumFile = string(fullfile(path,file));
        lblLSUM.Text = file;
    end

    function browseNMF()
        [file,path] = uigetfile({'*.csv','CSV files'},'Select NMF full.csv');
        if isequal(file,0), return; end
        app.nmfFile = string(fullfile(path,file));
        lblNMF.Text = file;
    end

    function runComparison()
        try
            if strlength(app.lsumFile)==0 || strlength(app.nmfFile)==0
                error('LSUM full.csv와 NMF full.csv를 모두 선택하세요.');
            end

            app.lsum = readtable(app.lsumFile,'VariableNamingRule','preserve');
            app.nmf  = readtable(app.nmfFile,'VariableNamingRule','preserve');

            app.lsum = standardizeResultTable(app.lsum,'LSUM');
            app.nmf  = standardizeResultTable(app.nmf,'NMF');

            keyVars = {'Trial','TrialTimepoint'};
            app.merged = innerjoin(app.lsum,app.nmf,'Keys',keyVars);

            if isempty(app.merged)
                error('Trial / TrialTimepoint 기준으로 두 파일이 매칭되지 않습니다.');
            end

            app.summary = computeSummary(app.merged);

            trials = unique(app.merged.Trial);
            ddTrial.Items = cellstr(string(trials));
            ddTrial.Value = ddTrial.Items{1};

            summaryTableUI.Data = app.summary;
            summaryTableUI.ColumnName = app.summary.Properties.VariableNames;

            updateTrialPlots();
            drawSummaryPlots();

            txtStatus.Value = {
                'Status: comparison complete.'
                sprintf('LSUM rows: %d',height(app.lsum))
                sprintf('NMF rows : %d',height(app.nmf))
                sprintf('Merged rows: %d',height(app.merged))
                sprintf('Trials: %d',numel(trials))
                };

        catch ME
            txtStatus.Value = {'Status: error', ME.message};
            uialert(fig,ME.message,'Comparison error');
        end
    end

    function updateTrialPlots()
        if isempty(app.merged) || strcmp(ddTrial.Value,'-')
            return;
        end

        tr = str2double(ddTrial.Value);
        T = app.merged(app.merged.Trial==tr,:);

        cla(axGCaMP);
        plot(axGCaMP,T.TrialTimepoint,T.LSUM_GCaMP_z,'LineWidth',1.2);
        hold(axGCaMP,'on');
        plot(axGCaMP,T.TrialTimepoint,T.NMF_GCaMP_z,'LineWidth',1.2);
        hold(axGCaMP,'off');
        title(axGCaMP,sprintf('Trial %d | GCaMP z-trace',tr));
        xlabel(axGCaMP,'TrialTimepoint');
        ylabel(axGCaMP,'Z-score');
        legend(axGCaMP,{'LSUM','NMF'},'Location','best');
        grid(axGCaMP,'on');

        cla(axJR);
        plot(axJR,T.TrialTimepoint,T.LSUM_jRGECO_z,'LineWidth',1.2);
        hold(axJR,'on');
        plot(axJR,T.TrialTimepoint,T.NMF_jRGECO_z,'LineWidth',1.2);
        hold(axJR,'off');
        title(axJR,sprintf('Trial %d | jRGECO z-trace',tr));
        xlabel(axJR,'TrialTimepoint');
        ylabel(axJR,'Z-score');
        legend(axJR,{'LSUM','NMF'},'Location','best');
        grid(axJR,'on');
    end

    function drawSummaryPlots()
        S = app.summary;
        trials = S.Trial;

        cla(axMethodCorr);
        plot(axMethodCorr,trials,S.GCaMP_LSUM_vs_NMF_corr,'-o','LineWidth',1.5);
        hold(axMethodCorr,'on');
        plot(axMethodCorr,trials,S.jRGECO_LSUM_vs_NMF_corr,'-o','LineWidth',1.5);
        hold(axMethodCorr,'off');
        ylim(axMethodCorr,[-1 1]);
        xlabel(axMethodCorr,'Trial');
        ylabel(axMethodCorr,'Correlation');
        title(axMethodCorr,'Method correlation: LSUM vs NMF');
        legend(axMethodCorr,{'GCaMP','jRGECO'},'Location','best');
        grid(axMethodCorr,'on');

        cla(axInternalCorr);
        plot(axInternalCorr,trials,S.LSUM_internal_corr,'-o','LineWidth',1.5);
        hold(axInternalCorr,'on');
        plot(axInternalCorr,trials,S.NMF_internal_corr,'-o','LineWidth',1.5);
        hold(axInternalCorr,'off');
        ylim(axInternalCorr,[-1 1]);
        xlabel(axInternalCorr,'Trial');
        ylabel(axInternalCorr,'Correlation');
        title(axInternalCorr,'Internal GCaMP-jRGECO correlation');
        legend(axInternalCorr,{'LSUM','NMF'},'Location','best');
        grid(axInternalCorr,'on');

        cla(axPeakTime);
        plot(axPeakTime,trials,S.LSUM_GCaMP_peak_t,'-o','LineWidth',1.3);
        hold(axPeakTime,'on');
        plot(axPeakTime,trials,S.NMF_GCaMP_peak_t,'-o','LineWidth',1.3);
        plot(axPeakTime,trials,S.LSUM_jRGECO_peak_t,'-o','LineWidth',1.3);
        plot(axPeakTime,trials,S.NMF_jRGECO_peak_t,'-o','LineWidth',1.3);
        hold(axPeakTime,'off');
        xlabel(axPeakTime,'Trial');
        ylabel(axPeakTime,'Peak TrialTimepoint');
        title(axPeakTime,'Peak timing comparison');
        legend(axPeakTime,{'LSUM GCaMP','NMF GCaMP','LSUM jRGECO','NMF jRGECO'}, ...
            'Location','best');
        grid(axPeakTime,'on');

        cla(axPeakAmp);
        plot(axPeakAmp,trials,S.LSUM_GCaMP_peak_z,'-o','LineWidth',1.3);
        hold(axPeakAmp,'on');
        plot(axPeakAmp,trials,S.NMF_GCaMP_peak_z,'-o','LineWidth',1.3);
        plot(axPeakAmp,trials,S.LSUM_jRGECO_peak_z,'-o','LineWidth',1.3);
        plot(axPeakAmp,trials,S.NMF_jRGECO_peak_z,'-o','LineWidth',1.3);
        hold(axPeakAmp,'off');
        xlabel(axPeakAmp,'Trial');
        ylabel(axPeakAmp,'Peak z-score');
        title(axPeakAmp,'Peak amplitude comparison');
        legend(axPeakAmp,{'LSUM GCaMP','NMF GCaMP','LSUM jRGECO','NMF jRGECO'}, ...
            'Location','best');
        grid(axPeakAmp,'on');
    end

    function saveSummary()
        if isempty(app.summary)
            uialert(fig,'먼저 Run comparison을 실행하세요.','No summary');
            return;
        end

        [file,path] = uiputfile('LSUM_NMF_compare_summary.csv','Save summary CSV');
        if isequal(file,0), return; end

        writetable(app.summary,fullfile(path,file));
        uialert(fig,'Summary CSV saved.','Saved');
    end

    function saveCurrentTab()
        if isempty(app.summary)
            uialert(fig,'먼저 Run comparison을 실행하세요.','No results');
            return;
        end

        folder = uigetdir(pwd,'Select save folder');
        if isequal(folder,0), return; end

        selectedTab = tabGroup.SelectedTab;
        tabTitle = matlab.lang.makeValidName(selectedTab.Title);

        f = figure('Visible','off','Color','w','Position',[100 100 1300 800]);

        if selectedTab == tabTrace
            tiledlayout(f,2,1);
            ax1 = nexttile;
            copyAxesContent(axGCaMP,ax1);
            ax2 = nexttile;
            copyAxesContent(axJR,ax2);

        elseif selectedTab == tabCorr
            tiledlayout(f,2,1);
            ax1 = nexttile;
            copyAxesContent(axMethodCorr,ax1);
            ax2 = nexttile;
            copyAxesContent(axInternalCorr,ax2);

        elseif selectedTab == tabPeak
            tiledlayout(f,2,1);
            ax1 = nexttile;
            copyAxesContent(axPeakTime,ax1);
            ax2 = nexttile;
            copyAxesContent(axPeakAmp,ax2);

        else
            close(f);
            uialert(fig,'Table tab은 CSV 저장 버튼을 사용하세요.','Info');
            return;
        end

        exportgraphics(f,fullfile(folder,[tabTitle '.png']),'Resolution',300);
        close(f);

        uialert(fig,'Current tab figure saved.','Saved');
    end
end

%% Helper functions

function T = standardizeResultTable(T, methodName)
    vars = string(T.Properties.VariableNames);

    if ~ismember("Trial", vars)
        error('%s 파일에 Trial 컬럼이 없습니다.', methodName);
    end

    % TrialTimepoint는 trial 안에서 0부터 다시 시작하는 시간축만 사용
    % LSUM의 Timepoint는 global timepoint라서 TrialTimepoint로 쓰면 안 됨
    if ismember("TrialTimepoint", vars)
        trialTimeCol = "TrialTimepoint";
    elseif ismember("Timepoint_Trial", vars)
        trialTimeCol = "Timepoint_Trial";
    elseif ismember("Trial_Timepoint", vars)
        trialTimeCol = "Trial_Timepoint";
    elseif ismember("TimePoint_Trial", vars)
        trialTimeCol = "TimePoint_Trial";
    else
        trialTimeCol = "";
    end

    gRaw = findColumn(vars, ["Coeff_of_GCaMP","GCaMP"], ...
        ["z","ratio","intercept","r_squared","timepoint","trial"]);

    rRaw = findColumn(vars, ["Coeff_of_jRGECO","jRGECO"], ...
        ["z","ratio","intercept","r_squared","timepoint","trial"]);

    if strlength(gRaw) == 0
        error('%s 파일에서 GCaMP coefficient 컬럼을 찾지 못했습니다.', methodName);
    end

    if strlength(rRaw) == 0
        error('%s 파일에서 jRGECO coefficient 컬럼을 찾지 못했습니다.', methodName);
    end

    gZTrial = findColumn(vars, ["GCaMP_z_trial","GCaMP_z","GCaMP_Z"], []);
    rZTrial = findColumn(vars, ["jRGECO_z_trial","jRGECO_z","jRGECO_Z"], []);

    T2 = table();
    T2.Trial = double(T.Trial);

    if strlength(trialTimeCol) > 0
        T2.TrialTimepoint = double(T.(trialTimeCol));
    else
        T2.TrialTimepoint = makeTrialTimepointFromTrial(T2.Trial);
    end

    if ismember("Timepoint_Global", vars)
        T2.Timepoint_Global = double(T.Timepoint_Global);
    elseif ismember("TimePoint_Global", vars)
        T2.Timepoint_Global = double(T.TimePoint_Global);
    elseif ismember("Timepoint", vars)
        T2.Timepoint_Global = double(T.Timepoint);
    elseif ismember("TimePoint", vars)
        T2.Timepoint_Global = double(T.TimePoint);
    else
        T2.Timepoint_Global = (0:height(T)-1)';
    end

    T2.([methodName '_GCaMP_raw']) = double(T.(gRaw));
    T2.([methodName '_jRGECO_raw']) = double(T.(rRaw));

    if strlength(gZTrial) > 0
        T2.([methodName '_GCaMP_z']) = double(T.(gZTrial));
    else
        T2.([methodName '_GCaMP_z']) = makeTrialZ(T2.Trial, T2.([methodName '_GCaMP_raw']));
    end

    if strlength(rZTrial) > 0
        T2.([methodName '_jRGECO_z']) = double(T.(rZTrial));
    else
        T2.([methodName '_jRGECO_z']) = makeTrialZ(T2.Trial, T2.([methodName '_jRGECO_raw']));
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

function z = makeTrialZ(trialVec,x)
    trialVec = trialVec(:);
    x = double(x(:));
    z = zeros(size(x));

    trials = unique(trialVec);

    for i = 1:numel(trials)
        idx = trialVec == trials(i);
        xi = x(idx);

        s = std(xi,'omitnan');

        if s==0 || isnan(s)
            z(idx) = 0;
        else
            z(idx) = (xi - mean(xi,'omitnan')) ./ s;
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

function S = computeSummary(M)
    trials = unique(M.Trial);
    n = numel(trials);

    S = table();
    S.Trial = trials;

    S.GCaMP_LSUM_vs_NMF_corr = nan(n,1);
    S.jRGECO_LSUM_vs_NMF_corr = nan(n,1);
    S.LSUM_internal_corr = nan(n,1);
    S.NMF_internal_corr = nan(n,1);

    S.LSUM_GCaMP_peak_t = nan(n,1);
    S.NMF_GCaMP_peak_t = nan(n,1);
    S.LSUM_jRGECO_peak_t = nan(n,1);
    S.NMF_jRGECO_peak_t = nan(n,1);

    S.LSUM_GCaMP_peak_z = nan(n,1);
    S.NMF_GCaMP_peak_z = nan(n,1);
    S.LSUM_jRGECO_peak_z = nan(n,1);
    S.NMF_jRGECO_peak_z = nan(n,1);

    for i = 1:n
        tr = trials(i);
        T = M(M.Trial==tr,:);

        S.GCaMP_LSUM_vs_NMF_corr(i) = safeCorr(T.LSUM_GCaMP_z,T.NMF_GCaMP_z);
        S.jRGECO_LSUM_vs_NMF_corr(i) = safeCorr(T.LSUM_jRGECO_z,T.NMF_jRGECO_z);

        S.LSUM_internal_corr(i) = safeCorr(T.LSUM_GCaMP_z,T.LSUM_jRGECO_z);
        S.NMF_internal_corr(i) = safeCorr(T.NMF_GCaMP_z,T.NMF_jRGECO_z);

        [S.LSUM_GCaMP_peak_z(i),idx] = max(T.LSUM_GCaMP_z);
        S.LSUM_GCaMP_peak_t(i) = T.TrialTimepoint(idx);

        [S.NMF_GCaMP_peak_z(i),idx] = max(T.NMF_GCaMP_z);
        S.NMF_GCaMP_peak_t(i) = T.TrialTimepoint(idx);

        [S.LSUM_jRGECO_peak_z(i),idx] = max(T.LSUM_jRGECO_z);
        S.LSUM_jRGECO_peak_t(i) = T.TrialTimepoint(idx);

        [S.NMF_jRGECO_peak_z(i),idx] = max(T.NMF_jRGECO_z);
        S.NMF_jRGECO_peak_t(i) = T.TrialTimepoint(idx);
    end
end

function c = safeCorr(x,y)
    x = x(:);
    y = y(:);

    valid = isfinite(x) & isfinite(y);
    x = x(valid);
    y = y(valid);

    if numel(x)<3 || std(x)==0 || std(y)==0
        c = NaN;
        return;
    end

    C = corrcoef(x,y);
    c = C(1,2);
end

function copyAxesContent(srcAx,dstAx)
    children = allchild(srcAx);
    copyobj(children,dstAx);

    title(dstAx,srcAx.Title.String);
    xlabel(dstAx,srcAx.XLabel.String);
    ylabel(dstAx,srcAx.YLabel.String);
    grid(dstAx,'on');

    try
        legend(dstAx,'show','Location','best');
    catch
    end
end