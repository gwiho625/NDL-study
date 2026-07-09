function LSUM_share_v2
    % =====================================================================
    % LSUM_share_v2
    % ---------------------------------------------------------------------
    % Purpose:
    %   기존 LSUM 방식으로 mixed spectral TXT를 unmixing한 뒤,
    %   원본 mixed TXT와 같은 spectral-data 구조의 output TXT를
    %   Component 1 / Component 2 각각 따로 저장합니다.
    %
    % Output:
    %   1) <base>_<Component1>_share.txt
    %      - timepoint x wavelength 구조
    %      - 값: coeff_component1(t) * reference_component1(lambda)
    %   2) <base>_<Component2>_share.txt
    %      - timepoint x wavelength 구조
    %      - 값: coeff_component2(t) * reference_component2(lambda)
    %
    % Fixed wavelength range:
    %   450–700 nm
    % =====================================================================

    fig = uifigure('Name','LSUM share v2','Position',[100,100,1150,720]);

    sidebar = uipanel(fig,'Title','설정 및 입력','Position',[20,20,330,680]);

    tabGroup = uitabgroup(fig,'Position',[370,20,760,680],'SelectionChangedFcn',@tab_change_callback);
    tab1 = uitab(tabGroup,'Title','Panel 1','Tag','1');
    tab2 = uitab(tabGroup,'Title','Panel 2','Tag','2');

    %% Sidebar Panel 1
    lblPanel1 = uilabel(sidebar,'Position',[10,635,300,22], ...
        'Text','Panel 1: LSUM Share Output','FontAngle','italic');

    lblMixed = uilabel(sidebar,'Position',[10,605,300,22], ...
        'Text','Upload mixed raw TXT file');
    btnMixed = uibutton(sidebar,'Position',[10,580,300,24], ...
        'Text','Browse mixed TXT...', ...
        'ButtonPushedFcn',@(btn,e) uigetfile_callback('mixed'));
    txtMixedName = uilabel(sidebar,'Position',[10,555,300,22], ...
        'Text','No file selected','FontColor',[0.5 0.5 0.5]);

    lblName1 = uilabel(sidebar,'Position',[10,525,130,22], ...
        'Text','Component 1 Name:');
    txtName1 = uieditfield(sidebar,'text','Position',[145,525,160,22], ...
        'Value','GCaMP');

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
    txtName2 = uieditfield(sidebar,'text','Position',[145,400,160,22], ...
        'Value','jRGECO');

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
        'Text','Wavelength range: 450–700 nm fixed','FontWeight','bold');

    btnRun = uibutton(sidebar,'Position',[10,240,300,32], ...
        'Text','Run LSUM', ...
        'ButtonPushedFcn',@(btn,e) run_analysis());

    lblOutput = uilabel(sidebar,'Position',[10,195,300,22], ...
        'Text','Output base file name:');
    txtOutputName = uieditfield(sidebar,'text','Position',[10,170,300,22], ...
        'Value','LSUM_share_output');

    btnDownload = uibutton(sidebar,'Position',[10,130,300,30], ...
        'Text','Save GCaMP & jRGECO share TXT', ...
        'ButtonPushedFcn',@(btn,e) download_share_data());

    %% Sidebar Panel 2
    lblPanel2 = uilabel(sidebar,'Position',[10,635,300,22], ...
        'Text','Panel 2: Timepoint Fit Check','FontAngle','italic','Visible','off');

    lblTimePoint = uilabel(sidebar,'Position',[10,605,300,22], ...
        'Text','Enter time point:','Visible','off');

    txtTimePoint = uieditfield(sidebar,'numeric','Position',[10,580,150,22], ...
        'Value',0,'LowerLimit',0,'RoundFractionalValues','on', ...
        'Visible','off','ValueChangedFcn',@(txt,e) update_panel2());

    lblPlotType = uilabel(sidebar,'Position',[10,545,300,22], ...
        'Text','Select plot type:','Visible','off');

    ddPlotType = uidropdown(sidebar,'Position',[10,520,250,22], ...
        'Items',{'Observed vs Fitted','Component Share Spectra','Reference Overlay','R2 Histogram'}, ...
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
    appState.result_table = [];
    appState.share = [];

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
            [file,path] = uigetfile({'*.txt','TXT files'},'Select mixed raw TXT');
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
            uialert(fig,'Mixed TXT와 reference TXT들을 모두 선택해주세요.','파일 누락');
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

        d = uiprogressdlg(fig,'Title','Please Wait','Message','Reading mixed raw TXT...');

        [wavelengths,mixed_spectra,time_info,header_lines] = readMixedTxtWithHeader(appState.mixed_file);

        mask = wavelengths >= wl_min & wavelengths <= wl_max;
        wavelengths_crop = wavelengths(mask);

        if isempty(wavelengths_crop)
            close(d);
            uialert(fig,'450–700 nm 범위에 해당하는 wavelength가 없습니다.','Wavelength error');
            return;
        end

        % mixed_data: wavelength x timepoint
        mixed_data = mixed_spectra(:,mask)';

        d.Message = 'Building Component 1 reference...';
        [ref1_wl,ref1] = makeAverageReference(appState.ref1_files,wl_min,wl_max);

        d.Message = 'Building Component 2 reference...';
        [ref2_wl,ref2] = makeAverageReference(appState.ref2_files,wl_min,wl_max);

        comp1_ref = interp1(ref1_wl,ref1,wavelengths_crop,'linear','extrap');
        comp2_ref = interp1(ref2_wl,ref2,wavelengths_crop,'linear','extrap');

        X = [comp1_ref(:), comp2_ref(:)];

        num_timepoints = size(mixed_data,2);

        r_sq_list = zeros(num_timepoints,1);
        intercept_list = zeros(num_timepoints,1);
        comp1_coeff = zeros(num_timepoints,1);
        comp2_coeff = zeros(num_timepoints,1);
        ratio_list = zeros(num_timepoints,1);

        comp1_share = zeros(num_timepoints,length(wavelengths_crop));
        comp2_share = zeros(num_timepoints,length(wavelengths_crop));
        fitted_share = zeros(num_timepoints,length(wavelengths_crop));

        d.Message = 'Running linear unmixing...';

        for i = 1:num_timepoints
            d.Value = i / num_timepoints;

            y = mixed_data(:,i);
            mdl = fitlm(X,y);

            intercept_list(i) = mdl.Coefficients.Estimate(1);
            comp1_coeff(i) = mdl.Coefficients.Estimate(2);
            comp2_coeff(i) = mdl.Coefficients.Estimate(3);
            r_sq_list(i) = mdl.Rsquared.Ordinary;
            ratio_list(i) = comp1_coeff(i) / comp2_coeff(i);

            % 핵심 share output:
            % 각 timepoint의 coefficient x reference spectrum
            comp1_share(i,:) = comp1_coeff(i) .* comp1_ref(:)';
            comp2_share(i,:) = comp2_coeff(i) .* comp2_ref(:)';

            % 참고용 fitted spectrum: intercept 포함
            fitted_share(i,:) = intercept_list(i) + comp1_share(i,:) + comp2_share(i,:);
        end

        close(d);

        comp1_z = zscore(comp1_coeff);
        comp2_z = zscore(comp2_coeff);

        result_table = table();
        result_table.(['Coeff_of_' comp1]) = comp1_coeff;
        result_table.(['Coeff_of_' comp2]) = comp2_coeff;
        result_table.Intercept = intercept_list;
        result_table.(['Ratio_of_' comp1 '_to_' comp2]) = ratio_list;
        result_table.R_Squared = r_sq_list;
        result_table.([comp1 '_z']) = comp1_z;
        result_table.([comp2 '_z']) = comp2_z;

        appState.result_table = result_table;

        appState.share = struct();
        appState.share.comp1 = comp1;
        appState.share.comp2 = comp2;
        appState.share.color1_hex = color1;
        appState.share.color2_hex = color2;
        appState.share.wavelengths = wavelengths_crop(:);
        appState.share.mixed_crop = mixed_data';        % timepoint x wavelength
        appState.share.comp1_ref = comp1_ref(:);
        appState.share.comp2_ref = comp2_ref(:);
        appState.share.comp1_share = comp1_share;      % timepoint x wavelength
        appState.share.comp2_share = comp2_share;      % timepoint x wavelength
        appState.share.fitted_share = fitted_share;    % timepoint x wavelength
        appState.share.time_info = time_info;
        appState.share.header_lines = header_lines;
        appState.share.source_file = appState.mixed_file;

        time_axis = 1:num_timepoints;

        plot(axColor1,time_axis,comp1_coeff,'Color',color1,'LineWidth',1.2);
        title(axColor1,[comp1 ' coefficient trace']);
        xlabel(axColor1,'Timepoint');
        ylabel(axColor1,['Coeff of ' comp1]);

        plot(axColor2,time_axis,comp2_coeff,'Color',color2,'LineWidth',1.2);
        title(axColor2,[comp2 ' coefficient trace']);
        xlabel(axColor2,'Timepoint');
        ylabel(axColor2,['Coeff of ' comp2]);

        plot(axZ,time_axis,comp1_z,'Color',color1,'LineWidth',1.2);
        hold(axZ,'on');
        plot(axZ,time_axis,comp2_z,'Color',color2,'LineWidth',1.2);
        hold(axZ,'off');
        title(axZ,'Z-score trace');
        xlabel(axZ,'Timepoint');
        ylabel(axZ,'Z-score');
        legend(axZ,{comp1,comp2},'Location','best');

        uialert(fig,'분석 완료. Save 버튼을 누르면 원본 구조와 같은 share TXT 2개가 저장됩니다.','완료');
    end

    function update_panel2()
        if isempty(appState.share)
            cla(axReg);
            txtInfo.Value = '분석이 수행되지 않았습니다. Panel 1에서 Run을 먼저 눌러주세요.';
            return;
        end

        cla(axReg);
        plotType = ddPlotType.Value;

        comp1 = appState.share.comp1;
        comp2 = appState.share.comp2;
        color1 = appState.share.color1_hex;
        color2 = appState.share.color2_hex;

        switch plotType
            case 'Observed vs Fitted'
                t_idx = txtTimePoint.Value + 1;
                max_time = size(appState.share.mixed_crop,1);

                if t_idx < 1 || t_idx > max_time
                    uialert(fig,sprintf('0부터 %d 사이의 정수를 입력하세요.',max_time-1),'범위 오류');
                    return;
                end

                obs = double(appState.share.mixed_crop(t_idx,:));
                pred = double(appState.share.fitted_share(t_idx,:));

                plot(axReg,appState.share.wavelengths,obs,'Color','#000000','LineWidth',1.2);
                hold(axReg,'on');
                plot(axReg,appState.share.wavelengths,pred,'Color',color1,'LineWidth',1.2);
                hold(axReg,'off');

                xlabel(axReg,'Wavelength (nm)');
                ylabel(axReg,'Intensity');
                title(axReg,sprintf('Observed vs Fitted at Timepoint %d',txtTimePoint.Value));
                legend(axReg,{'Observed','Fitted'},'Location','best');

                row_table = appState.result_table(t_idx,:);
                names = row_table.Properties.VariableNames;
                vals = row_table{1,:};
                summary_cells = cell(length(vals),1);
                for k = 1:length(vals)
                    summary_cells{k} = sprintf('%-35s: %.4f',names{k},vals(k));
                end
                txtInfo.Value = [{['[Time Point = ',num2str(txtTimePoint.Value),' Result Summary]']}; ''; summary_cells];

            case 'Component Share Spectra'
                t_idx = txtTimePoint.Value + 1;
                max_time = size(appState.share.comp1_share,1);

                if t_idx < 1 || t_idx > max_time
                    uialert(fig,sprintf('0부터 %d 사이의 정수를 입력하세요.',max_time-1),'범위 오류');
                    return;
                end

                s1 = appState.share.comp1_share(t_idx,:);
                s2 = appState.share.comp2_share(t_idx,:);

                plot(axReg,appState.share.wavelengths,s1,'Color',color1,'LineWidth',1.5);
                hold(axReg,'on');
                plot(axReg,appState.share.wavelengths,s2,'Color',color2,'LineWidth',1.5);
                hold(axReg,'off');

                xlabel(axReg,'Wavelength (nm)');
                ylabel('Unmixed component intensity');
                title(axReg,sprintf('Unmixed component spectra at Timepoint %d',txtTimePoint.Value));
                legend(axReg,{comp1,comp2},'Location','best');

                txtInfo.Value = {
                    '[Component Share Spectra]'
                    ''
                    '이 그래프가 저장되는 share TXT의 한 row와 같은 의미입니다.'
                    ['Component 1 file value = Coeff_of_', comp1, '(t) × ', comp1, '_reference(lambda)']
                    ['Component 2 file value = Coeff_of_', comp2, '(t) × ', comp2, '_reference(lambda)']
                };

            case 'Reference Overlay'
                plot(axReg,appState.share.wavelengths,appState.share.comp1_ref,'Color',color1,'LineWidth',2);
                hold(axReg,'on');
                plot(axReg,appState.share.wavelengths,appState.share.comp2_ref,'Color',color2,'LineWidth',2);
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

            case 'R2 Histogram'
                histogram(axReg,appState.result_table.R_Squared,50);

                xlabel(axReg,'R^2');
                ylabel(axReg,'Count');
                title(axReg,'Unmixing R^2 Distribution');

                txtInfo.Value = {
                    '[R2 Histogram]'
                    ''
                    sprintf('Mean R^2 : %.6f',mean(appState.result_table.R_Squared))
                    sprintf('Min R^2  : %.6f',min(appState.result_table.R_Squared))
                    sprintf('Max R^2  : %.6f',max(appState.result_table.R_Squared))
                };
        end

        grid(axReg,'on');
    end

    function download_share_data()
        if isempty(appState.share)
            uialert(fig,'결과 데이터가 없습니다. 먼저 Run을 실행하세요.','저장 불가');
            return;
        end

        if strlength(strtrim(txtOutputName.Value)) == 0
            [~, sourceBase, ~] = fileparts(appState.share.source_file);
            baseName = string(sourceBase) + "_LSUM_share";
        else
            [~, nameOnly, ~] = fileparts(char(strtrim(txtOutputName.Value)));
            baseName = string(nameOnly);
        end

        default_file = char(baseName + "_folder_selector.txt");

        [file, path] = uiputfile({'*.txt','Text files (*.txt)'}, ...
            '저장 위치 선택: 선택한 파일 이름의 base만 사용됩니다', default_file);

        if isequal(file,0)
            return;
        end

        [~, savedBaseName, ~] = fileparts(file);
        savedBaseName = erase(string(savedBaseName), "_folder_selector");

        comp1File = fullfile(path, char(savedBaseName + "_" + appState.share.comp1 + "_share.txt"));
        comp2File = fullfile(path, char(savedBaseName + "_" + appState.share.comp2 + "_share.txt"));
        coeffFile = fullfile(path, char(savedBaseName + "_coefficients.txt"));
        refFile   = fullfile(path, char(savedBaseName + "_reference_spectra.txt"));

        writeShareTxtSameStructure(comp1File, appState.share.header_lines, ...
            appState.share.wavelengths, appState.share.comp1_share, appState.share.time_info, ...
            ['LSUM share output: ' appState.share.comp1]);

        writeShareTxtSameStructure(comp2File, appState.share.header_lines, ...
            appState.share.wavelengths, appState.share.comp2_share, appState.share.time_info, ...
            ['LSUM share output: ' appState.share.comp2]);

        % 분석 검증용 coefficient / reference도 같이 저장
        writetable(appState.result_table, coeffFile, ...
            'FileType','text','Delimiter','\t');

        refTable = table( ...
            appState.share.wavelengths(:), ...
            appState.share.comp1_ref(:), ...
            appState.share.comp2_ref(:), ...
            'VariableNames', { ...
                'Wavelength_nm', ...
                [appState.share.comp1 '_reference'], ...
                [appState.share.comp2 '_reference'] ...
            });

        writetable(refTable, refFile, ...
            'FileType','text','Delimiter','\t');

        uialert(fig, sprintf(['저장 완료:\n\n' ...
            'Share output 1:\n%s\n\n' ...
            'Share output 2:\n%s\n\n' ...
            '검증용 coefficient:\n%s\n\n' ...
            '검증용 reference:\n%s'], ...
            comp1File, comp2File, coeffFile, refFile), 'TXT 저장 완료');
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

function [wavelengths,spectra,time_info,header_lines] = readMixedTxtWithHeader(filename)
    lines = readlines(filename);

    start_idx = find(contains(lines,'>>>>>Begin Spectral Data<<<<<'),1);

    if isempty(start_idx)
        error('Cannot find Begin Spectral Data marker.');
    end

    % marker 포함 전까지의 원본 header 보존
    header_lines = lines(1:start_idx);

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
                spectra = [spectra; numeric_part']; %#ok<AGROW>

                date_list(end+1,1) = string(row(1)); %#ok<AGROW>
                time_list(end+1,1) = string(row(2)); %#ok<AGROW>
                timestamp_list(end+1,1) = string(row(3)); %#ok<AGROW>
            end
        end
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

        y = y - min(y);
        maxY = max(y);
        if maxY == 0
            error('Reference file has zero dynamic range after baseline subtraction: %s', ref_files{k});
        end
        y = y / maxY;

        if isempty(base_wl)
            base_wl = wl_c;
        end

        y_interp = interp1(wl_c,y,base_wl,'linear','extrap');
        all_refs{end+1} = y_interp(:); %#ok<AGROW>
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

function writeShareTxtSameStructure(filename, header_lines, wavelengths, share_matrix, time_info, title_line)
    % share_matrix: timepoint x wavelength

    fid = fopen(filename,'w');
    if fid == -1
        error('Cannot open file for writing: %s', filename);
    end

    cleaner = onCleanup(@() fclose(fid));

    % 원본 header를 최대한 유지하되, share output임을 한 줄 추가
    for i = 1:length(header_lines)
        fprintf(fid,'%s\n', header_lines(i));
    end
    fprintf(fid,'# %s\n', title_line);
    fprintf(fid,'# Wavelength cropped to 450-700 nm\n');
    fprintf(fid,'# Values = coefficient(t) * normalized_reference(lambda)\n');

    % wavelength header row
    for j = 1:length(wavelengths)
        if j == 1
            fprintf(fid,'%.6g', wavelengths(j));
        else
            fprintf(fid,'\t%.6g', wavelengths(j));
        end
    end
    fprintf(fid,'\n');

    nTime = size(share_matrix,1);

    for i = 1:nTime
        if ~isempty(time_info) && size(time_info,1) >= i
            fprintf(fid,'%s\t%s\t%s', time_info(i,1), time_info(i,2), time_info(i,3));
        else
            fprintf(fid,'%d\t%d\t%d', i-1, i-1, i-1);
        end

        for j = 1:length(wavelengths)
            fprintf(fid,'\t%.10g', share_matrix(i,j));
        end
        fprintf(fid,'\n');
    end
end
