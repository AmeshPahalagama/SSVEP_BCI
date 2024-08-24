function BioRadioData = BioRadio_Stream(myDevice, duration, BioRadio_Name)
    % function BioRadioData = BioRadio_Stream(myDevice, duration, BioRadio_Name)
    % BioRadio_Stream streams data from the BioRadio and imports it into MATLAB.
    % Saves a new CSV file every 3 seconds with 750 rows and appropriate number of columns.

    % modifications //////////////
    macID = int64(hex2dec('ECFE7E19AAA6'));
    deviceManager = GLNeuroTech.Devices.BioRadio.BioRadioDeviceManager;
    myDevice = deviceManager.GetBluetoothDevice(macID);
    duration = 99;
    % BioRadio_Name = "BioRadio ANM";

    %/////////////////

    % INPUTS:
    % - myDevice is a handle to a BioRadio device object
    % - duration is the data collection interval in seconds
    % - BioRadio_name is string containing the BioRadio name
    %
    % OUTPUTS:
    % - BioRadioData is a 3-element cell array of the data, where BioRadioData{1}
    %   contains the BioPotentialSignals, BioRadioData{2} contains the
    %   AuxiliarySignals, and BioRadioData{3} contains the PulseOxSignals. Each
    %   of those cells contains a cell array where the number of cells
    %   corresponds to the number of channels in that signal group. For
    %   example, if 4 biopotentials are configured, BioRadioData{1} will be a 4
    %   cell array, where each cell contains the data for a single channel.
    
    numEnabledBPChannels = double(myDevice.BioPotentialSignals.Count);
    numAuxChannels = double(myDevice.AuxiliarySignals.Count);
    numPOxChannels = double(myDevice.PulseOxSignals.Count);

    if numEnabledBPChannels == 0
        myDevice.Disconnect;
        BioRadioData = [];
        errordlg('No BioPotential Channels Programmed. Return to BioCapture to Configure.')
        return
    end

    sampleRate_BP = double(myDevice.BioPotentialSignals.SamplesPerSecond);
    sampleRate_Pod = 250;

    % Define path for CSV files
    csvPath = 'F:\Engineering\Semester 8\EE406 - Undergraduate Project 2\csv files';
    if ~exist(csvPath, 'dir')
        mkdir(csvPath);
    end

    % Calculate number of samples for 3 seconds
    numSamples_3Sec = 3 * sampleRate_BP;

    % Initialize data storage
    BioPotentialSignals = cell(1, numEnabledBPChannels);
    AuxiliarySignals = cell(1, numAuxChannels);
    PulseOxSignals = cell(1, numPOxChannels);

    % Prepare figure
    figure
    axis_handles = zeros(1, numEnabledBPChannels + numAuxChannels + numPOxChannels);
    for ch = 1:numEnabledBPChannels
        axis_handles(ch) = subplot(length(axis_handles), 1, ch);
        ylabel([char(myDevice.BioPotentialSignals.Item(ch-1).Name) ' (V)']);
        hold on
    end
    for ch = 1:numAuxChannels
        axis_handles(ch + numEnabledBPChannels) = subplot(length(axis_handles), 1, ch + numEnabledBPChannels);
        ylabel(char(myDevice.AuxiliarySignals.Item(ch-1).Name));
        ylim(double([myDevice.AuxiliarySignals.Item(ch-1).MinValue myDevice.AuxiliarySignals.Item(ch-1).MaxValue]))
        hold on
    end
    for ch = 1:numPOxChannels
        axis_handles(ch + numEnabledBPChannels + numAuxChannels) = subplot(length(axis_handles), 1, ch + numEnabledBPChannels + numAuxChannels);
        ylabel(char(myDevice.PulseOxSignals.Item(ch-1).Name));
        ylim(double([myDevice.PulseOxSignals.Item(ch-1).MinValue myDevice.PulseOxSignals.Item(ch-1).MaxValue]))
        hold on
    end
    xlabel('Time (s)')
    linkaxes(axis_handles, 'x')

    % Start data acquisition
    myDevice.StartAcquisition;

    plotWindow = 5;
    plotGain_BP = 1;
    elapsedTime = 0;
    tic;

    % Initialize file index
    fileIndex = 1;
    fileStartTime = tic;

    % Data collection
    while elapsedTime < duration
        pause(0.08)
        for ch = 1:numEnabledBPChannels
            BioPotentialSignals{ch} = [BioPotentialSignals{ch}; myDevice.BioPotentialSignals.Item(ch-1).GetScaledValueArray.double'];
        end

        for ch = 1:numAuxChannels
            AuxiliarySignals{ch} = [AuxiliarySignals{ch}; myDevice.AuxiliarySignals.Item(ch-1).GetScaledValueArray.double'];
        end

        for ch = 1:numPOxChannels
            PulseOxSignals{ch} = [PulseOxSignals{ch}; myDevice.PulseOxSignals.Item(ch-1).GetScaledValueArray.double'];
        end

        % Check if 3 seconds have passed
        if toc(fileStartTime) >= 3
            % Combine data into a single matrix
            combined_BP = [];
            for ch = 1:numEnabledBPChannels
                if length(BioPotentialSignals{ch}) >= 750
                    dataToSave_BP = BioPotentialSignals{ch}(end - 749:end, :);
                    combined_BP = [combined_BP, dataToSave_BP];
                end
            end

            combined_Aux = [];
            for ch = 1:numAuxChannels
                if length(AuxiliarySignals{ch}) >= 750
                    dataToSave_Aux = AuxiliarySignals{ch}(end - 749:end, :);
                    combined_Aux = [combined_Aux, dataToSave_Aux];
                end
            end

            combined_POx = [];
            for ch = 1:numPOxChannels
                if length(PulseOxSignals{ch}) >= 750
                    dataToSave_POx = PulseOxSignals{ch}(end - 749:end, :);
                    combined_POx = [combined_POx, dataToSave_POx];
                end
            end

            % Save combined data to unique files
            if ~isempty(combined_BP)
                filename = sprintf('BioPotentialSignals_%03d.csv', fileIndex);
                csvwrite(fullfile(csvPath, filename), combined_BP);
            end

            if ~isempty(combined_Aux)
                filename = sprintf('AuxiliarySignals_%03d.csv', fileIndex);
                csvwrite(fullfile(csvPath, filename), combined_Aux);
            end

            if ~isempty(combined_POx)
                filename = sprintf('PulseOxSignals_%03d.csv', fileIndex);
                csvwrite(fullfile(csvPath, filename), combined_POx);
            end

            % Reset the file start time and increment the file index
            fileStartTime = tic;
            fileIndex = fileIndex + 1;
        end

        % Update plots
        for ch = 1:numEnabledBPChannels
            if length(BioPotentialSignals{ch}) <= plotWindow * sampleRate_BP
                cla(axis_handles(ch))
                t = (0:(length(BioPotentialSignals{ch})-1)) * (1 / sampleRate_BP);
                plot(axis_handles(ch), t, plotGain_BP * BioPotentialSignals{ch});
                xlim([0 plotWindow])
            else
                t = ((length(BioPotentialSignals{ch}) - (plotWindow * sampleRate_BP - 1)):length(BioPotentialSignals{ch})) * (1 / sampleRate_BP);
                cla(axis_handles(ch))
                plot(axis_handles(ch), t, plotGain_BP * BioPotentialSignals{ch}(end - plotWindow * sampleRate_BP + 1:end));
                xlim([t(end) - plotWindow t(end)])
            end
        end

        for ch = 1:numAuxChannels
            if length(AuxiliarySignals{ch}) <= plotWindow * sampleRate_Pod
                cla(axis_handles(ch + numEnabledBPChannels))
                t = (0:(length(AuxiliarySignals{ch})-1)) * (1 / sampleRate_Pod);
                plot(axis_handles(ch + numEnabledBPChannels), t, AuxiliarySignals{ch});
                xlim([0 plotWindow])
            else
                t_pod = ((length(AuxiliarySignals{ch}) - (plotWindow * sampleRate_Pod - 1)):length(AuxiliarySignals{ch})) * (1 / sampleRate_Pod);
                cla(axis_handles(ch + numEnabledBPChannels))
                plot(axis_handles(ch + numEnabledBPChannels), t_pod, AuxiliarySignals{ch}(end - plotWindow * sampleRate_Pod + 1:end));
                xlim([t_pod(end) - plotWindow t_pod(end)])
            end
            hold on
        end

        for ch = 1:numPOxChannels
            if length(PulseOxSignals{ch}) <= plotWindow * sampleRate_Pod
                cla(axis_handles(ch + numEnabledBPChannels + numAuxChannels))
                t = (0:(length(PulseOxSignals{ch})-1)) * (1 / sampleRate_Pod);
                plot(axis_handles(ch + numEnabledBPChannels + numAuxChannels), t, PulseOxSignals{ch});
                xlim([0 plotWindow])
            else
                t_pod = ((length(PulseOxSignals{ch}) - (plotWindow * sampleRate_Pod - 1)):length(PulseOxSignals{ch})) * (1 / sampleRate_Pod);
                cla(axis_handles(ch + numEnabledBPChannels + numAuxChannels))
                plot(axis_handles(ch + numEnabledBPChannels + numAuxChannels), t_pod, PulseOxSignals{ch}(end - plotWindow * sampleRate_Pod + 1:end));
                xlim([t_pod(end) - plotWindow t_pod(end)])
            end
        end

        elapsedTime = elapsedTime + toc;
        tic;
    end

    % Stop data acquisition
    myDevice.StopAcquisition;

    % Final save of the last segment of data
    combined_BP = [];
    for ch = 1:numEnabledBPChannels
        BioPotentialSignals{ch} = [BioPotentialSignals{ch}; myDevice.BioPotentialSignals.Item(ch-1).GetScaledValueArray.double'];
        if length(BioPotentialSignals{ch}) >= 750
            dataToSave_BP = BioPotentialSignals{ch}(end - 749:end, :);
            combined_BP = [combined_BP, dataToSave_BP];
        end
    end

    combined_Aux = [];
    for ch = 1:numAuxChannels
        AuxiliarySignals{ch} = [AuxiliarySignals{ch}; myDevice.AuxiliarySignals.Item(ch-1).GetScaledValueArray.double'];
        if length(AuxiliarySignals{ch}) >= 750
            dataToSave_Aux = AuxiliarySignals{ch}(end - 749:end, :);
            combined_Aux = [combined_Aux, dataToSave_Aux];
        end
    end

    combined_POx = [];
    for ch = 1:numPOxChannels
        PulseOxSignals{ch} = [PulseOxSignals{ch}; myDevice.PulseOxSignals.Item(ch-1).GetScaledValueArray.double'];
        if length(PulseOxSignals{ch}) >= 750
            dataToSave_POx = PulseOxSignals{ch}(end - 749:end, :);
            combined_POx = [combined_POx, dataToSave_POx];
        end
    end

    % Save final segment data to unique files
    if ~isempty(combined_BP)
        filename = sprintf('BioPotentialSignals_Final_%03d.csv', fileIndex);
        csvwrite(fullfile(csvPath, filename), combined_BP);
    end

    if ~isempty(combined_Aux)
        filename = sprintf('AuxiliarySignals_Final_%03d.csv', fileIndex);
        csvwrite(fullfile(csvPath, filename), combined_Aux);
    end

    if ~isempty(combined_POx)
        filename = sprintf('PulseOxSignals_Final_%03d.csv', fileIndex);
        csvwrite(fullfile(csvPath, filename), combined_POx);
    end

    % Output data
    BioRadioData = cell(1, 3);
    BioRadioData{1} = BioPotentialSignals;
    BioRadioData{2} = AuxiliarySignals;
    BioRadioData{3} = PulseOxSignals;
end
