function Linear_Spectral_Unmixing_Algorithm_v2_batch
    fig = uifigure('Name','Linear Spectral Unmixing Model v2 Batch','Position',[100,100,1150,720]);

    sidebar = uipanel(fig,'Title','설정 및 입력','Position',[20,20,330,680]);

    tabGroup = uitabgroup(fig,'Position',[370,20,760,680],'SelectionChangedFcn',@tab_change_callback);
    tab1 = uitab(tabGroup,'Title','Panel 1','Tag','1');
    tab2 = uitab(tabGroup,'Title','Panel 2','Tag','2');

    %% Fixed output path
    outputRoot = "/Users/rnlghdb/NDL/MATLAB/unmixing-compare/LSUM-result";

    %% Sidebar Panel 1
    lblPanel1 = uilabel(sidebar,'Position',[10,635,300,22], ...
        'Text','Panel 1: Raw TXT Unmixing','FontAngle','italic');

    lblMixed = uilabel(sidebar,'Position',[10,605,300,22], ...
        'Text','Upload mixed raw TXT file(s)');

    btnMixed = uibutton(sidebar,'Position',[10,580,300,24], ...
        'Text','Browse mixed TXT...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('mixed'));

    txtMixedName = uilabel(sidebar,'Position',[10,555,300,22], ...
        'Text','No file selected','FontColor',[0.5 0.5 0.5]);

    lblName1 = uilabel(sidebar,'Position',[10,525,130,22], ...
        'Text','Component 1 Name:');

    txtName1 = uieditfield(sidebar,'text', ...
        'Position',[145,525,160,22], ...
        'Value','');

    lblColor1 = uilabel(sidebar,'Position',[10,495,130,22], ...
        'Text','Component 1 Color:');

    ddColor1 = uidropdown(sidebar,'Position',[145,495,160,22], ...
        'Items',{'Blue','Red','Green','Orange','Black'}, ...
        'Value','Blue');

    btnRef1 = uibutton(sidebar,'Position',[10,465,300,24], ...
        'Text','Browse Component 1 refs TXT...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('ref1'));

    txtRef1Name = uilabel(sidebar,'Position',[10,440,300,22], ...
        'Text','No ref selected','FontColor',[0.5 0.5 0.5]);

    lblName2 = uilabel(sidebar,'Position',[10,400,130,22], ...
        'Text','Component 2 Name:');

    txtName2 = uieditfield(sidebar,'text', ...
        'Position',[145,400,160,22], ...
        'Value','');

    lblColor2 = uilabel(sidebar,'Position',[10,370,130,22], ...
        'Text','Component 2 Color:');

    ddColor2 = uidropdown(sidebar,'Position',[145,370,160,22], ...
        'Items',{'Blue','Red','Green','Orange','Black'}, ...
        'Value','Red');

    btnRef2 = uibutton(sidebar,'Position',[10,340,300,24], ...
        'Text','Browse Component 2 refs TXT...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('ref2'));

    txtRef2Name = uilabel(sidebar,'Position',[10,315,300,22], ...
        'Text','No ref selected','FontColor',[0.5 0.5 0.5]);

    lblWavelength = uilabel(sidebar,'Position',[10,280,300,22], ...
        'Text','Wavelength range: 450–700 nm fixed', ...
        'FontWeight','bold');

    btnRun = uibutton(sidebar,'Position',[10,240,300,32], ...
        'Text','Run single selected file', ...
        'ButtonPushedFcn',@(btn,e) run_analysis());

    btnBatchRun = uibutton(sidebar,'Position',[10,200,300,32], ...
        'Text','Run selected mixed files batch', ...
        'ButtonPushedFcn',@(btn,e) run_selected_files_batch());

    lblOutput = uilabel(sidebar,'Position',[10,160,300,22], ...
        'Text','Output file name for single save:');

    txtOutputName = uieditfield(sidebar,'text', ...
        'Position',[10,135,300,22], ...
        'Value','');

    btnDownload = uibutton(sidebar,'Position',[10,95,300,30], ...
        'Text','Download single dataset', ...
        'ButtonPushedFcn',@(btn,e) download_data());

    %% Sidebar Panel 2
    lblPanel2 = uilabel(sidebar,'Position',[10,635,300,22], ...
        'Text','Panel 2: Timepoint Fit Check', ...
        'FontAngle','italic', ...
        'Visible','off');

    lblTimePoint = uilabel(sidebar,'Position',[10,605,300,22], ...
        'Text','Enter time point:', ...
        'Visible','off');

    txtTimePoint = uieditfield(sidebar,'numeric', ...
        'Position',[10,580,150,22], ...
        'Value',0, ...
        'LowerLimit',0, ...
        'RoundFractionalValues','on', ...
        'Visible','off', ...
        'ValueChangedFcn',@(txt,e) update_panel2());

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

    txtInfo = uitextarea(tab2, ...
        'Position',[40,40,680,180], ...
        'Editable','off', ...
        'FontName','FixedWidth');

    %% App state
    appState = struct();
    appState.mixed_file = '';
    appState.mixed_files = {};
    appState.ref1_files = {};
    appState.ref2_files = {};
    appState.df1 = [];
    appState.df2 = [];

    wl_min = 450;
    wl_max = 700;

    panel1Controls = [ ...
        lblPanel1, lblMixed, btnMixed, txtMixedName, ...
        lblName1, txtName1, lblColor1, ddColor1, btnRef1, txtRef1Name, ...
        lblName2, txtName2, lblColor2, ddColor2, btnRef2, txtRef2Name, ...
        lblWavelength, btnRun, btnBatchRun, lblOutput, txtOutputName, btnDownload ...
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
            [files,path] = uigetfile({'*.txt','TXT files'}, ...
                'Select mixed raw TXT file(s)', ...
                'MultiSelect','on');

            if isequal(files,0)
                return;
            end

            if ischar(files)
                files = {files};
            end

            appState.mixed_files = fullfile(path,files);
            appState.mixed_file = appState.mixed_files{1};

            if numel(files) == 1
                txtMixedName.Text = files{1};
            else
                txtMixedName.Text = sprintf('%d mixed files selected',numel(files));
            end

        elseif strcmp(type,'ref1')
            [files,path] = uigetfile({'*.txt','TXT files'}, ...
                'Select Component 1 reference TXT files', ...
                'MultiSelect','on');

            if isequal(files,0)
                return;
            end

            if ischar(files)
                files = {files};
            end

            appState.ref1_files = fullfile(path,files);
            txtRef1Name.Text = sprintf('%d files selected',numel(files));

        elseif strcmp(type,'ref2')
            [files,path] = uigetfile({'*.txt','TXT files'}, ...
                'Select Component 2 reference TXT files', ...
                'MultiSelect','on');

            if isequal(files,0)
                return;
            end

            if ischar(files)
                files = {files};
            end

            appState.ref2_files = fullfile(path,files);
            txtRef2Name.Text = sprintf('%d files selected',numel(files));
        end
    end

    function run_analysis()
        if isempty(appState.mixed_file)
            uialert(fig,'Mixed TXT 파일을 먼저 선택해주세요.','Mixed 파일 누락');
            return;
        end

        if isempty(appState.ref1_files) || isempty(appState.ref2_files)
            uialert(fig,'Component 1/2 reference TXT들을 모두 선택해주세요.','Reference 파일 누락');
            return;
        end

        [comp1, comp2, color1, color2, ok] = get_user_components();

        if ~ok
            return;
        end

        d = uiprogressdlg(fig, ...
            'Title','Please Wait', ...
            'Message','Running single-file unmixing...', ...
            'Value',0.1);

        try
            [df1, df2, comp1_list, comp2_list, comp1_z, comp2_z] = analyze_one_file( ...
                appState.mixed_file, ...
                appState.ref1_files, ...
                appState.ref2_files, ...
                comp1, comp2, color1, color2, ...
                wl_min, wl_max);

            d.Value = 1;
            close(d);

            appState.df1 = df1;
            appState.df2 = df2;

            time_axis = 1:numel(comp1_list);

            plot_main_results(time_axis, comp1_list, comp2_list, comp1_z, comp2_z, ...
                comp1, comp2, color1, color2);

            uialert(fig,'분석 완료. Download single dataset으로 저장할 수 있습니다.','완료');

        catch ME
            close(d);
            uialert(fig,ME.message,'분석 오류');
        end
    end

    function run_selected_files_batch()
        if isempty(appState.mixed_files)
            uialert(fig,'Mixed TXT 파일들을 먼저 선택해주세요.','Mixed 파일 누락');
            return;
        end

        if isempty(appState.ref1_files) || isempty(appState.ref2_files)
            uialert(fig,'Component 1/2 reference TXT들을 모두 선택해주세요.','Reference 파일 누락');
            return;
        end

        [comp1, comp2, color1, color2, ok] = get_user_components();

        if ~ok
            return;
        end

        if ~isfolder(outputRoot)
            mkdir(outputRoot);
        end

        d = uiprogressdlg(fig, ...
            'Title','Batch Running', ...
            'Message','Processing selected mixed files...', ...
            'Value',0);

        referenceSaved = false;
        successList = strings(0,1);
        failList = strings(0,1);

        numFiles = numel(appState.mixed_files);

        last_comp1_list = [];
        last_comp2_list = [];
        last_comp1_z = [];
        last_comp2_z = [];

        for n = 1:numFiles
            mixedFile = appState.mixed_files{n};
            [~, rawName, ~] = fileparts(mixedFile);

            d.Value = (n-1) / numFiles;
            d.Message = sprintf('Processing %s...',rawName);

            try
                [df1, df2, comp1_list, comp2_list, comp1_z, comp2_z] = analyze_one_file( ...
                    mixedFile, ...
                    appState.ref1_files, ...
                    appState.ref2_files, ...
                    comp1, comp2, color1, color2, ...
                    wl_min, wl_max);

                resultFile = fullfile(outputRoot, sprintf('LSUM-%s-result.txt',rawName));

                writetable(df1, resultFile, ...
                    'FileType','text', ...
                    'Delimiter','tab');

                if ~referenceSaved
                    refFile = fullfile(outputRoot, 'LSUM-reference_spectra.txt');

                    refTable = table( ...
                        df2.wavelengths(:), ...
                        df2.color1(:), ...
                        df2.color2(:), ...
                        'VariableNames', { ...
                            'Wavelength_nm', ...
                            [df2.comp1 '_reference'], ...
                            [df2.comp2 '_reference'] ...
                        });

                    writetable(refTable, refFile, ...
                        'FileType','text', ...
                        'Delimiter','tab');

                    referenceSaved = true;
                end

                appState.df1 = df1;
                appState.df2 = df2;

                last_comp1_list = comp1_list;
                last_comp2_list = comp2_list;
                last_comp1_z = comp1_z;
                last_comp2_z = comp2_z;

                successList(end+1,1) = string(rawName);

            catch ME
                failList(end+1,1) = string(rawName) + " : " + string(ME.message);
                warning('%s failed: %s',rawName,ME.message);
            end
        end

        d.Value = 1;
        close(d);

        if ~isempty(last_comp1_list)
            time_axis = 1:numel(last_comp1_list);

            plot_main_results(time_axis, last_comp1_list, last_comp2_list, ...
                last_comp1_z, last_comp2_z, comp1, comp2, color1, color2);
        end

        msg = sprintf('Selected files batch 완료\n\n저장 위치:\n%s\n\n성공: %d개\n실패: %d개', ...
            outputRoot, numel(successList), numel(failList));

        if ~isempty(successList)
            msg = msg + newline + newline + "성공 목록:" + newline + strjoin(successList,newline);
        end

        if ~isempty(failList)
            msg = msg + newline + newline + "실패 목록:" + newline + strjoin(failList,newline);
        end

        uialert(fig,msg,'Batch 완료');
    end

    function [comp1, comp2, color1, color2, ok] = get_user_components()
        ok = false;

        if strlength(strtrim(txtName1.Value)) == 0 || strlength(strtrim(txtName2.Value)) == 0
            uialert(fig,'Component 이름을 입력해주세요.','Component name missing');
            comp1 = '';
            comp2 = '';
            color1 = '';
            color2 = '';
            return;
        end

        comp1 = matlab.lang.makeValidName(txtName1.Value);
        comp2 = matlab.lang.makeValidName(txtName2.Value);

        if strcmp(comp1,comp2)
            uialert(fig,'Component 1과 Component 2 이름이 같습니다. 서로 다른 이름을 입력해주세요.', ...
                'Component name error');
            comp1 = '';
            comp2 = '';
            color1 = '';
            color2 = '';
            return;
        end

        color1 = getColorHex(ddColor1.Value);
        color2 = getColorHex(ddColor2.Value);

        ok = true;
    end

    function [df1, df2, comp1_list, comp2_list, comp1_z, comp2_z] = analyze_one_file( ...
            mixedFile, ref1_files, ref2_files, comp1, comp2, color1, color2, wl_min_local, wl_max_local)

        [wavelengths,mixed_spectra,~] = readMixedTxt(mixedFile);

        mask = wavelengths >= wl_min_local & wavelengths <= wl_max_local;
        wavelengths_crop = wavelengths(mask);

        if isempty(wavelengths_crop)
            error('Mixed file has no wavelength data within %d-%d nm: %s', ...
                wl_min_local, wl_max_local, mixedFile);
        end

        mixed_data = mixed_spectra(:,mask)';

        [ref1_wl,ref1] = makeAverageReference(ref1_files,wl_min_local,wl_max_local);
        [ref2_wl,ref2] = makeAverageReference(ref2_files,wl_min_local,wl_max_local);

        color1_ref = interp1(ref1_wl,ref1,wavelengths_crop,'linear','extrap');
        color2_ref = interp1(ref2_wl,ref2,wavelengths_crop,'linear','extrap');

        X = [color1_ref(:), color2_ref(:)];

        if any(isnan(X(:)))
            error('Reference interpolation produced NaN values.');
        end

        num_cols = size(mixed_data,2);

        r_sq_list = zeros(num_cols,1);
        intercept_list = zeros(num_cols,1);
        comp1_list = zeros(num_cols,1);
        comp2_list = zeros(num_cols,1);
        ratio_list = zeros(num_cols,1);

        for i = 1:num_cols
            y = double(mixed_data(:,i));

            if any(isnan(y))
                error('Mixed spectrum contains NaN values at timepoint %d in file: %s',i,mixedFile);
            end

            mdl = fitlm(X,y);

            r_sq_list(i) = mdl.Rsquared.Ordinary;
            intercept_list(i) = mdl.Coefficients.Estimate(1);
            comp1_list(i) = mdl.Coefficients.Estimate(2);
            comp2_list(i) = mdl.Coefficients.Estimate(3);

            if comp2_list(i) == 0
                ratio_list(i) = NaN;
            else
                ratio_list(i) = comp1_list(i) / comp2_list(i);
            end
        end

        comp1_z = safe_zscore(comp1_list);
        comp2_z = safe_zscore(comp2_list);

        df1 = table();
        df1.(['Coeff_of_' comp1]) = comp1_list;
        df1.(['Coeff_of_' comp2]) = comp2_list;
        df1.Intercept = intercept_list;
        df1.(['Ratio_of_' comp1 '_to_' comp2]) = ratio_list;
        df1.R_Squared = r_sq_list;
        df1.([comp1 '_z']) = comp1_z;
        df1.([comp2 '_z']) = comp2_z;

        df2 = struct();
        df2.color1 = color1_ref(:);
        df2.color2 = color2_ref(:);
        df2.wavelengths = wavelengths_crop(:);
        df2.mixed_data = mixed_data;
        df2.comp1 = comp1;
        df2.comp2 = comp2;
        df2.color1_hex = color1;
        df2.color2_hex = color2;
    end

    function plot_main_results(time_axis, comp1_list, comp2_list, comp1_z, comp2_z, comp1, comp2, color1, color2)
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
                    summary_cells{k} = sprintf('%-35s: %.4f',names{k},vals(k));
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

                if ss_tot == 0
                    reg_R2 = NaN;
                else
                    reg_R2 = 1 - ss_res/ss_tot;
                end

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

        default_file = char(baseName + ".txt");

        [file, path] = uiputfile({'*.txt','Text files (*.txt)'}, ...
            '결과 TXT 저장', default_file);

        if isequal(file,0)
            return;
        end

        resultFile = fullfile(path, file);

        writetable(appState.df1, resultFile, ...
            'FileType','text', ...
            'Delimiter','tab');

        uialert(fig, sprintf('저장 완료:\n\n결과 데이터:\n%s',resultFile), 'TXT 저장 완료');
    end
end

%% Helper functions

function z = safe_zscore(x)
    x = double(x(:));

    valid = ~isnan(x);

    if sum(valid) <= 1
        z = zeros(size(x));
        return;
    end

    mu = mean(x(valid));
    sigma = std(x(valid));

    if isnan(sigma) || sigma == 0
        z = zeros(size(x));
    else
        z = (x - mu) ./ sigma;
    end
end

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

function [wavelengths,spectra,time_info] = readMixedTxt(filename)
    lines = readlines(filename);

    start_idx = find(contains(lines,'>>>>>Begin Spectral Data<<<<<'),1);

    if isempty(start_idx)
        error('Cannot find Begin Spectral Data marker in file: %s',filename);
    end

    data_lines = lines(start_idx+1:end);
    data_lines = data_lines(strlength(strtrim(data_lines)) > 0);

    if isempty(data_lines)
        error('No spectral data lines found after Begin Spectral Data marker in file: %s',filename);
    end

    parsed = cell(length(data_lines),1);

    for i = 1:length(data_lines)
        parsed{i} = split(strtrim(data_lines(i)));
    end

    wavelengths = str2double(parsed{1});
    wavelengths = wavelengths(~isnan(wavelengths));

    if isempty(wavelengths)
        error('Cannot parse wavelength row in mixed TXT file: %s',filename);
    end

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

    if isempty(spectra)
        error('No valid spectral rows found in mixed TXT file: %s',filename);
    end

    if isempty(date_list)
        time_info = [];
    else
        time_info = [date_list,time_list,timestamp_list];
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

        if isempty(wl_c)
            error('Reference file has no valid data within %d-%d nm: %s', ...
                wl_min, wl_max, ref_files{k});
        end

        y = y - min(y);
        maxY = max(y);

        if maxY == 0
            error('Reference intensity becomes all zero after baseline subtraction: %s',ref_files{k});
        end

        y = y / maxY;

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

    if size(raw,2) < 2
        error('Reference TXT must have at least two columns: wavelength and intensity. File: %s',filename);
    end

    wavelength = raw(:,1);
    intensity = raw(:,2);

    wavelength = double(wavelength);
    intensity = double(intensity);
end