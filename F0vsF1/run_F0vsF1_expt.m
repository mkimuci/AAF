function expt = run_F0vsF1_expt(expt, bTestMode)
    addpath(genpath("C:\Users\mkkim\AAF"));

    if nargin < 1, expt = []; end
    if nargin < 2 || isempty(bTestMode), bTestMode = 0; end

    expt.name = 'F0vsF1';
    if ~isfield(expt, 'snum'), expt.snum = get_snum; end
    expt.dataPath = get_acoustSavePath(expt.name, expt.snum);
    if ~exist(expt.dataPath, 'dir'), mkdir(expt.dataPath); end

    expt.csvPath = fullfile(expt.dataPath, 'expt_log.csv');
    % If the CSV doesn't exist yet, write a header row
    if ~exist(expt.csvPath, 'file')
        fid = fopen(expt.csvPath, 'a');
        fprintf(fid, 'currentSession,iTrial,trialOnset,shiftType,condition\n');
        fclose(fid);
    end

    % General experiment parameters
    if ~isfield(expt, 'gender'), expt.gender = get_height; end

    % If training is aborted, save the date and exit the experiment
    if ~run_F0vsF1_durationTraining(expt)
        save(fullfile(expt.dataPath, 'expt.mat'), 'expt');
        fprintf('Experiment ended.\n');
        return;
    end

    expt.nF0vsF1expt = 3; % Number of iteration of each F0 or F1 expt
    if bTestMode, expt.nF0vsF1expt = 1; end % just once if test mode

    % Determine experiment order based on participant number parity
    if mod(str2double(expt.snum(end)), 2) == 0
        expt.exptOrder = repmat({'F0', 'F1'}, 1, expt.nF0vsF1expt);
    else
        expt.exptOrder = repmat({'F1', 'F0'}, 1, expt.nF0vsF1expt);
    end

    % Words and conditions
    expt.shiftDirs  = {0, -1, 1}; % No shift, down, up
    expt.shiftNames = {'noShift', 'shiftDown', 'shiftUp'};
    expt.words      = {'head', 'dead', 'bed'};
    expt.conds      = expt.shiftNames;

    % Timing and duration feedback parameters
    expt.timing  = get_timing_params();
    expt.durcalc = get_durcalc_params();

    expt.bMaskingNoise = true;

    % Save experiment order into expt variable (preliminary)
    save(fullfile(expt.dataPath, 'expt.mat'), 'expt');
    
    % Generate and save paradigms for each experiment
    for iExpt = 1:length(expt.exptOrder)
        shiftType = expt.exptOrder{iExpt}; % 'F0' or 'F1'
    
        fprintf('Generating paradigm for %s Experiment %d...\n', ...
            shiftType, iExpt);

        % Create a fresh copy of the main expt structure
        currExpt = expt; 
        currExpt.shiftType = shiftType;
        currExpt.iExpt = iExpt;
    
        fprintf('Generating paradigm for %s Experiment %d...\n', ...
            currExpt.shiftType, iExpt);
    
        % Generate paradigm for the current experiment
        currExpt = generate_paradigm(currExpt);

        % Save experiment data with type in the filename
        save(fullfile(currExpt.dataPath, ...
            sprintf('expt_%d_%s.mat', iExpt, shiftType)), 'currExpt');

        % Run current experiment
        currExpt = run_F0vsF1_audapter(currExpt, 'main');

        % Save experiment data (final)
        save(fullfile(currExpt.dataPath, ...
            sprintf('expt_%d_%s.mat', iExpt, shiftType)), 'currExpt');
    end
end
