function LSUM_merge_v2
    fig = uifigure('Name','LSUM v2 - Animal Merged + Trial Column Split', ...
        'Position',[100,100,1150,720]);

    sidebar = uipanel(fig,'Title','설정 및 입력','Position',[20,20,330,680]);

    tabGroup = uitabgroup(fig,'Position',[370,20,760,680], ...
        'SelectionChangedFcn',@tab_change_callback);
    tab1 = uitab(tabGroup,'Title','Panel 1','Tag','1');
    tab2 = uitab(tabGroup,'Title','Panel 2','Tag','2');

    %% Sidebar Panel 1
    lblPanel1 = uilabel(sidebar,'Position',[10,635,300,22], ...
        'Text','Panel 1: Animal Merged Raw Unmixing','FontAngle','italic');

    lblMixed = uilabel(sidebar,'Position',[10,605,300,22], ...
        'Text','Upload animal merged TXT/CSV file');

    btnMixed = uibutton(sidebar,'Position',[10,580,300,24], ...
        'Text','Browse animal merged file...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('mixed'));

    txtMixedName = uilabel(sidebar,'Position',[10,555,300,22], ...
        'Text','No file selected','FontColor',[0.5 0.5 0.5]);

    lblName1 = uilabel(sidebar,'Position',[10,525,130,22],'Text','Component 1 Name:');
    txtName1 = uieditfield(sidebar,'text','Position',[145,525,160,22],'Value','GCaMP');

    lblColor1 = uilabel(sidebar,'Position',[10,495,130,22],'Text','Component 1 Color:');
    ddColor1 = uidropdown(sidebar,'Position',[145,495,160,22], ...
        'Items',{'Blue','Red','Green','Orange','Black'}, ...
        'Value','Blue');

    btnRef1 = uibutton(sidebar,'Position',[10,465,300,24], ...
        'Text','Browse Component 1 refs TXT...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('ref1'));

    txtRef1Name = uilabel(sidebar,'Position',[10,440,300,22], ...
        'Text','No ref selected','FontColor',[0.5 0.5 0.5]);

    lblName2 = uilabel(sidebar,'Position',[10,400,130,22],'Text','Component 2 Name:');
    txtName2 = uieditfield(sidebar,'text','Position',[145,400,160,22],'Value','jRGECO');

    lblColor2 = uilabel(sidebar,'Position',[10,370,130,22],'Text','Component 2 Color:');
    ddColor2 = uidropdown(sidebar,'Position',[145,370,160,22], ...
        'Items',{'Blue','Red','Green','Orange','Black'}, ...
        'Value','Red');

    btnRef2 = uibutton(sidebar,'Position',[10,340,300,24], ...
        'Text','Browse Component 2 refs TXT...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('ref2'));

    txtRef2Name = uilabel(sidebar,'Position',[10,315,300,22], ...
        'Text','No ref selected','FontColor',[0.5 0.5 0.5]);

    lblWavelength = uilabel(sidebar,'Position',[10,280,300,22], ...
        'Text','Wavelength range: 450–700 nm fixed','FontWeight','bold');

    btnRun = uibutton(sidebar,'Position',[10,240,300,32], ...
        'Text','Run', ...
        'ButtonPushedFcn',@(btn,e) run_analysis());

    lblOutput = uilabel(sidebar,'Position',[10,195,300,22], ...
        'Text','Output base name:');

    txtOutputName = uieditfield(sidebar,'text','Position',[10,170,300,22], ...
        'Value','');

    btnDownload = uibutton(sidebar,'Position',[10,130,300,30], ...
        'Text','Download full + trial data', ...
        'ButtonPushedFcn',@(btn,e) download_data());

    %% Sidebar Panel 2
    lblPanel2 = uilabel(sidebar,'Position',[10,635,300,22], ...
        'Text','Panel 2: Timepoint Fit Check', ...
        'FontAngle','italic','Visible','off');

    lblTimePoint = uilabel(sidebar,'Position',[10,605,300,22], ...
        'Text','Enter time point:', ...
        'Visible','off');

    txtTimePoint = uieditfield(sidebar,'numeric','Position',[10,580,150,22], ...
        'Value',0,'LowerLimit',0,'RoundFractionalValues','on', ...
        'Visible','off','ValueChangedFcn',@(txt,e) update_panel2());

    lblPlotType = uilabel(sidebar,'Position',[10,545,300,22], ...
        'Text','Select plot type:', ...
        'Visible','off');

    ddPlotType = uidropdown(sidebar,'Position',[10,520,250,22], ...
        'Items',{'Observed vs Fitted','Reference Overlay','Scatter + Regression','R2 Histogram'}, ...
        'Value','Observed vs Fitted', ...
        'Visible','off', ...
        'ValueChangedFcn',@(dd,e) update_panel2());

    %% Main panel axes
    axColor1 = uiaxes(tab1,'Position',[40,470,680,170]);
    axColor2 = uiaxes(tab1,'Position',[40,260,680,170]);
    axZ      = uiaxes(tab1,'Position',[40,50,680,170]);

    axReg = uiaxes(tab2,'Position',[40,260,680,370]);
    txtInfo = uitextarea(tab2,'Position',[40,40,680,180], ...
        'Editable','off','FontName','FixedWidth');

    %% App state
    appState = struct();
    appState.mixed_file = '';
    appState.ref1_files = {};
    appState.ref2_files = {};
    appState.df1 = [];
    appState.df2 = [];
    appState.time_info = [];
    appState.trial_info = [];

    wl_min = 450;
    wl_max = 700;

    panel1Controls = [ ...
        lblPanel1, lblMixed, btnMixed, txtMixedName, ...
        lblName1, txtName1, lblColor1, ddColor1, btnRef1, txtRef1Name, ...
        lblName2, txtName2, lblColor2, ddColor2, btnRef2, txtRef2Name, ...
        lblWavelength, btnRun, lblOutput, txtOutputName, btnDownload ...
    ];

    panel2Controls = [ ...
        lblPanel2, lblTimePoint, txtTimePoint, lblPlotType, ddPlotType ...
    ];

    %% CALLBACKS

    function tab_change_callback(~,event)
        if strcmp(event.NewValue.Tag,'1')
            set(panel1Controls,'Visible','on');
            set(panel2Controls,'Visible','off');
        else
            set(panel1Controls,'Visible','off');
            set(panel2Controls,'Visible','on');
            update_panel2();
        end
    end

    function uigetfile_callback(type)
        if strcmp(type,'mixed')
            [file,path] = uigetfile({'*.txt;*.csv','Merged TXT/CSV files (*.txt, *.csv)'}, ...
                'Select animal merged data');

            if isequal(file,0), return; end

            appState.mixed_file = fullfile(path,file);
            txtMixedName.Text = file;

        elseif strcmp(type,'ref1')
            [files,path] = uigetfile({'*.txt','TXT files'}, ...
                'Select Component 1 reference TXT files','MultiSelect','on');

            if isequal(files,0), return; end
            if ischar(files), files = {files}; end

            appState.ref1_files = fullfile(path,files);
            txtRef1Name.Text = sprintf('%d files selected',numel(files));

        elseif strcmp(type,'ref2')
            [files,path] = uigetfile({'*.txt','TXT files'}, ...
                'Select Component 2 reference TXT files','MultiSelect','on');

            if isequal(files,0), return; end
            if ischar(files), files = {files}; end

            appState.ref2_files = fullfile(path,files);
            txtRef2Name.Text = sprintf('%d files selected',numel(files));
        end
    end

    function run_analysis()
        if isempty(appState.mixed_file) || isempty(appState.ref1_files) || isempty(appState.ref2_files)
            uialert(fig,'Animal merged file 1개와 Component 1/2 reference TXT를 선택해주세요.','파일 누락');
            return;
        end

        if strlength(strtrim(txtName1.Value)) == 0 || strlength(strtrim(txtName2.Value)) == 0
            uialert(fig,'Component 이름을 입력해주세요.','Component name missing');
            return;
        end

        comp1 = matlab.lang.makeValidName(txtName1.Value);
        comp2 = matlab.lang.makeValidName(txtName2.Value);

        color1 = getColorHex(ddColor1.Value);
        color2 = getColorHex(ddColor2.Value);

        d = uiprogressdlg(fig,'Title','Please Wait','Message','Reading mixed data...');

        [wavelengths,mixed_spectra,time_info,trial_info] = readMixedTxt(appState.mixed_file);
        appState.time_info = time_info;
        appState.trial_info = trial_info;

        mask = wavelengths >= wl_min & wavelengths <= wl_max;
        wavelengths_crop = wavelengths(mask);
        mixed_data = mixed_spectra(:,mask)';

        d.Message = 'Building Component 1 reference...';
        [ref1_wl,ref1] = makeAverageReference(appState.ref1_files,wl_min,wl_max);

        d.Message = 'Building Component 2 reference...';
        [ref2_wl,ref2] = makeAverageReference(appState.ref2_files,wl_min,wl_max);

        color1_ref = interp1(ref1_wl,ref1,wavelengths_crop,'linear','extrap');
        color2_ref = interp1(ref2_wl,ref2,wavelengths_crop,'linear','extrap');

        X = [color1_ref(:), color2_ref(:)];

        num_cols = size(mixed_data,2);

        r_sq_list = zeros(num_cols,1);
        intercept_list = zeros(num_cols,1);
        comp1_list = zeros(num_cols,1);
        comp2_list = zeros(num_cols,1);
        ratio_list = zeros(num_cols,1);

        d.Message = 'Running linear unmixing...';

        for i = 1:num_cols
            d.Value = i / num_cols;

            y = mixed_data(:,i);

            mdl = fitlm(X,y);

            r_sq_list(i) = mdl.Rsquared.Ordinary;
            intercept_list(i) = mdl.Coefficients.Estimate(1);
            comp1_list(i) = mdl.Coefficients.Estimate(2);
            comp2_list(i) = mdl.Coefficients.Estimate(3);
            ratio_list(i) = comp1_list(i) / comp2_list(i);
        end

        close(d);

        comp1_z = zscore(comp1_list);
        comp2_z = zscore(comp2_list);

        appState.df1 = table();

        if ~isempty(trial_info)
            appState.df1.Trial = trial_info(:);
        end

        appState.df1.Timepoint = (0:num_cols-1)';
        appState.df1.(['Coeff_of_' comp1]) = comp1_list;
        appState.df1.(['Coeff_of_' comp2]) = comp2_list;
        appState.df1.Intercept = intercept_list;
        appState.df1.(['Ratio_of_' comp1 '_to_' comp2]) = ratio_list;
        appState.df1.R_Squared = r_sq_list;
        appState.df1.([comp1 '_z']) = comp1_z;
        appState.df1.([comp2 '_z']) = comp2_z;

        appState.df2 = struct();
        appState.df2.color1 = color1_ref(:);
        appState.df2.color2 = color2_ref(:);
        appState.df2.wavelengths = wavelengths_crop(:);
        appState.df2.mixed_data = mixed_data;
        appState.df2.comp1 = comp1;
        appState.df2.comp2 = comp2;
        appState.df2.color1_hex = color1;
        appState.df2.color2_hex = color2;

        time_axis = 0:num_cols-1;

        plot(axColor1,time_axis,comp1_list,'Color',color1,'LineWidth',1.2);
        title(axColor1,[comp1 ' coefficient trace']);
        xlabel(axColor1,'Timepoint');
        ylabel(axColor1,['Coeff of ' comp1]);
        grid(axColor1,'on');

        plot(axColor2,time_axis,comp2_list,'Color',color2,'LineWidth',1.2);
        title(axColor2,[comp2 ' coefficient trace']);
        xlabel(axColor2,'Timepoint');
        ylabel(axColor2,['Coeff of ' comp2]);
        grid(axColor2,'on');

        plot(axZ,time_axis,comp1_z,'Color',color1,'LineWidth',1.2);
        hold(axZ,'on');
        plot(axZ,time_axis,comp2_z,'Color',color2,'LineWidth',1.2);
        hold(axZ,'off');
        title(axZ,'Z-score trace');
        xlabel(axZ,'Timepoint');
        ylabel(axZ,'Z-score');
        legend(axZ,{comp1,comp2},'Location','best');
        grid(axZ,'on');

        uialert(fig,'분석 완료. Download full + trial data로 저장할 수 있습니다.','완료');
    end

    function update_panel2()
        if isempty(appState.df2)
            cla(axReg);
            txtInfo.Value = '분석이 수행되지 않았습니다. Panel 1에서 Run을 먼저 눌러주세요.';
            return;
        end

        cla(axReg);
        plotType = ddPlotType.Value;

        comp1 = appState.df2.comp1;
        comp2 = appState.df2.comp2;

        color1 = appState.df2.color1_hex;
        color2 = appState.df2.color2_hex;

        switch plotType
            case 'Observed vs Fitted'
                t_idx = txtTimePoint.Value + 1;
                max_time = size(appState.df2.mixed_data,2);

                if t_idx < 1 || t_idx > max_time
                    uialert(fig,sprintf('0부터 %d 사이의 정수를 입력하세요.',max_time-1),'범위 오류');
                    return;
                end

                obs = double(appState.df2.mixed_data(:,t_idx));
                X = [appState.df2.color1, appState.df2.color2];

                mdl = fitlm(X,obs);
                pred = mdl.Fitted;

                plot(axReg,appState.df2.wavelengths,obs,'Color','#000000','LineWidth',1.2);
                hold(axReg,'on');
                plot(axReg,appState.df2.wavelengths,pred,'Color',color1,'LineWidth',1.2);
                hold(axReg,'off');

                xlabel(axReg,'Wavelength (nm)');
                ylabel(axReg,'Intensity');
                title(axReg,sprintf('Observed vs Fitted at Timepoint %d',txtTimePoint.Value));
                legend(axReg,{'Observed','Fitted'},'Location','best');

                row_table = appState.df1(t_idx,:);
                names = row_table.Properties.VariableNames;
                vals = row_table{1,:};

                summary_cells = cell(length(vals),1);

                for k = 1:length(vals)
                    if isnumeric(vals(k))
                        summary_cells{k} = sprintf('%-35s: %.4f',names{k},vals(k));
                    else
                        summary_cells{k} = sprintf('%-35s: %s',names{k},string(vals(k)));
                    end
                end

                txtInfo.Value = [{['[Time Point = ',num2str(txtTimePoint.Value),' Result Summary]']}; ''; summary_cells];

            case 'Reference Overlay'
                plot(axReg,appState.df2.wavelengths,appState.df2.color1,'Color',color1,'LineWidth',2);
                hold(axReg,'on');
                plot(axReg,appState.df2.wavelengths,appState.df2.color2,'Color',color2,'LineWidth',2);
                hold(axReg,'off');

                xlabel(axReg,'Wavelength (nm)');
                ylabel(axReg,'Normalized intensity');
                title(axReg,'Reference Overlay');
                legend(axReg,{comp1,comp2},'Location','best');

                txtInfo.Value = {
                    '[Reference Overlay]'
                    ''
                    ['Component 1: ', comp1]
                    ['Component 2: ', comp2]
                    'References were baseline-subtracted, peak-normalized, and averaged.'
                };

            case 'Scatter + Regression'
                z1_col = [comp1 '_z'];
                z2_col = [comp2 '_z'];

                x = appState.df1.(z1_col);
                y = appState.df1.(z2_col);

                [R,P] = corr(x,y,'Type','Pearson');

                coeff = polyfit(x,y,1);
                xfit = linspace(min(x),max(x),100);
                yfit = polyval(coeff,xfit);

                y_pred = polyval(coeff,x);
                ss_res = sum((y - y_pred).^2);
                ss_tot = sum((y - mean(y)).^2);
                reg_R2 = 1 - ss_res/ss_tot;

                scatter(axReg,x,y,10,'filled', ...
                    'MarkerFaceColor',color1, ...
                    'MarkerEdgeColor',color1);
                hold(axReg,'on');
                plot(axReg,xfit,yfit,'Color','#000000','LineWidth',2);
                hold(axReg,'off');

                xlabel(axReg,[comp1 ' Z-score']);
                ylabel(axReg,[comp2 ' Z-score']);
                title(axReg,sprintf('Scatter + Regression: r = %.3f, R^2 = %.3f',R,reg_R2));

                txtInfo.Value = {
                    '[Scatter + Regression]'
                    ''
                    sprintf('Pearson r      : %.4f',R)
                    sprintf('p-value        : %.4e',P)
                    sprintf('Regression R^2 : %.4f',reg_R2)
                    sprintf('Slope          : %.4f',coeff(1))
                    sprintf('Intercept      : %.4f',coeff(2))
                };

            case 'R2 Histogram'
                histogram(axReg,appState.df1.R_Squared,50);

                xlabel(axReg,'R^2');
                ylabel(axReg,'Count');
                title(axReg,'Unmixing R^2 Distribution');

                txtInfo.Value = {
                    '[R2 Histogram]'
                    ''
                    sprintf('Mean R^2 : %.6f',mean(appState.df1.R_Squared))
                    sprintf('Min R^2  : %.6f',min(appState.df1.R_Squared))
                    sprintf('Max R^2  : %.6f',max(appState.df1.R_Squared))
                };
        end

        grid(axReg,'on');
    end

    function download_data()
        if isempty(appState.df1)
            uialert(fig,'결과 데이터가 없습니다. 먼저 Run을 실행하세요.','저장 불가');
            return;
        end

        if isempty(appState.df2)
            uialert(fig,'Reference spectrum 데이터가 없습니다. 먼저 Run을 실행하세요.','저장 불가');
            return;
        end

        if strlength(strtrim(txtOutputName.Value)) == 0
            baseName = "LSUM_output";
        else
            [~, nameOnly, ~] = fileparts(char(strtrim(txtOutputName.Value)));
            baseName = string(nameOnly);
        end

        saveFolder = uigetdir(pwd, 'LSUM 결과 저장 폴더 선택');

        if isequal(saveFolder,0)
            return;
        end

        %% 1) 전체 결과 저장
        fullTxtFile = fullfile(saveFolder, baseName + "_full.txt");
        fullCsvFile = fullfile(saveFolder, baseName + "_full.csv");

        writetable(appState.df1, fullTxtFile, ...
            'FileType','text', ...
            'Delimiter','\t');

        writetable(appState.df1, fullCsvFile);

        %% 2) Reference spectra 저장
        refTable = table( ...
            appState.df2.wavelengths(:), ...
            appState.df2.color1(:), ...
            appState.df2.color2(:), ...
            'VariableNames', { ...
                'Wavelength_nm', ...
                [appState.df2.comp1 '_reference'], ...
                [appState.df2.comp2 '_reference'] ...
            });

        refTxtFile = fullfile(saveFolder, baseName + "_reference_spectra.txt");
        refCsvFile = fullfile(saveFolder, baseName + "_reference_spectra.csv");

        writetable(refTable, refTxtFile, ...
            'FileType','text', ...
            'Delimiter','\t');

        writetable(refTable, refCsvFile);

        %% 3) trial별 결과 저장
        if ismember('Trial', appState.df1.Properties.VariableNames)

            trialFolder = fullfile(saveFolder, baseName + "_trials");

            if ~exist(trialFolder, 'dir')
                mkdir(trialFolder);
            end

            trialNums = unique(appState.df1.Trial);

            for i = 1:length(trialNums)

                trialNum = trialNums(i);

                trialData = appState.df1(appState.df1.Trial == trialNum, :);

                trialData.TrialTimepoint = (0:height(trialData)-1)';
                trialData = movevars(trialData, 'TrialTimepoint', 'After', 'Trial');

                trialTxtFile = fullfile(trialFolder, ...
                    sprintf('%s_trial%02d.txt', baseName, trialNum));

                trialCsvFile = fullfile(trialFolder, ...
                    sprintf('%s_trial%02d.csv', baseName, trialNum));

                writetable(trialData, trialTxtFile, ...
                    'FileType','text', ...
                    'Delimiter','\t');

                writetable(trialData, trialCsvFile);
            end

            msg = sprintf(['저장 완료:\n\n전체 결과:\n%s\n%s\n\nTrial별 결과 폴더:\n%s\n\nReference spectra도 저장됨.'], ...
                fullTxtFile, fullCsvFile, trialFolder);

        else
            msg = sprintf(['저장 완료:\n\n전체 결과:\n%s\n%s\n\n주의: Trial 컬럼이 없어서 trial별 분할 저장은 안 됨.'], ...
                fullTxtFile, fullCsvFile);
        end

        uialert(fig, msg, 'LSUM 저장 완료');
    end
end

%% Helper functions

function colorHex = getColorHex(colorName)
    switch colorName
        case 'Blue'
            colorHex = '#0000FF';
        case 'Red'
            colorHex = '#FF0000';
        case 'Green'
            colorHex = '#008000';
        case 'Orange'
            colorHex = '#FFA500';
        case 'Black'
            colorHex = '#000000';
        otherwise
            colorHex = '#000000';
    end
end

function [wavelengths,spectra,time_info,trial_info] = readMixedTxt(filename)

    lines = readlines(filename);
    start_idx = find(contains(lines,'>>>>>Begin Spectral Data<<<<<'),1);

    %% Case 1: original raw TXT format
    if ~isempty(start_idx)

        data_lines = lines(start_idx+1:end);
        data_lines = data_lines(strlength(strtrim(data_lines)) > 0);

        parsed = cell(length(data_lines),1);

        for i = 1:length(data_lines)
            parsed{i} = split(strtrim(data_lines(i)));
        end

        wavelengths = str2double(parsed{1});
        wavelengths = wavelengths(~isnan(wavelengths));

        nPix = length(wavelengths);

        spectra = [];
        date_list = strings(0,1);
        time_list = strings(0,1);
        timestamp_list = strings(0,1);

        for i = 2:length(parsed)
            row = parsed{i};

            if length(row) >= nPix + 3
                numeric_part = str2double(row(end-nPix+1:end));

                if sum(isnan(numeric_part)) == 0
                    spectra = [spectra; numeric_part'];

                    date_list(end+1,1) = string(row(1));
                    time_list(end+1,1) = string(row(2));
                    timestamp_list(end+1,1) = string(row(3));
                end
            end
        end

        time_info = [date_list,time_list,timestamp_list];
        trial_info = [];
        return;
    end

    %% Case 2: merged TXT/CSV table format
    firstLine = char(lines(1));

    if contains(firstLine, ',')
        delim = ',';
    else
        delim = '\t';
    end

    T = readtable(filename, ...
        'FileType','text', ...
        'Delimiter',delim, ...
        'VariableNamingRule','preserve');

    varNames = string(T.Properties.VariableNames);

    %% Trial info
    trial_info = [];

    if ismember("Trial", varNames)
        trial_info = T.("Trial");
        trial_info = double(trial_info);
    end

    %% Wavelength columns
    wl = nan(size(varNames));

    for k = 1:numel(varNames)
        name = varNames(k);

        temp = str2double(name);

        if isnan(temp)
            name2 = erase(name, "wl_");
            name2 = erase(name2, "x");
            name2 = replace(name2, "_", ".");
            temp = str2double(name2);
        end

        wl(k) = temp;
    end

    wavelengthMask = ~isnan(wl);
    wavelengths = wl(wavelengthMask);

    if isempty(wavelengths)
        disp("Detected variable names:");
        disp(varNames(1:min(20,numel(varNames))));
        error('No wavelength columns found. Check merged file format.');
    end

    spectra = T{:, wavelengthMask};

    if ~isnumeric(spectra)
        spectra = str2double(string(spectra));
    end

    spectra = double(spectra);

    %% Time info
    time_info = [];

    if all(ismember(["Date","Time","Timestamp"], varNames))
        time_info = [string(T.("Date")), string(T.("Time")), string(T.("Timestamp"))];
    end
end

function [wl_crop,mean_ref] = makeAverageReference(ref_files,wl_min,wl_max)
    all_refs = {};
    base_wl = [];

    for k = 1:length(ref_files)
        [wl,intensity] = readReferenceTxt(ref_files{k});

        mask = wl >= wl_min & wl <= wl_max;

        wl_c = wl(mask);
        y = intensity(mask);

        valid = ~isnan(wl_c) & ~isnan(y);
        wl_c = wl_c(valid);
        y = y(valid);

        y = y - min(y);
        y = y / max(y);

        if isempty(base_wl)
            base_wl = wl_c;
        end

        y_interp = interp1(wl_c,y,base_wl,'linear','extrap');

        all_refs{end+1} = y_interp(:);
    end

    M = cell2mat(all_refs);

    wl_crop = base_wl;
    mean_ref = mean(M,2);
end

function [wavelength,intensity] = readReferenceTxt(filename)
    raw = readmatrix(filename,'FileType','text');

    wavelength = raw(:,1);
    intensity = raw(:,2);

    wavelength = double(wavelength);
    intensity = double(intensity);
end