function bRunTraining = run_F0vsF1_durationTraining(expt)
    % Ask if duration practice should be run
    duration_response = askNChoiceQuestion('Run duration practice?', {'run', 'skip'});
    if strcmp(duration_response, 'skip')
        bRunTraining = 1;
        return; % Exit if training is skipped
    end

    % Initialize duration practice structure
    exptDur = expt;
    exptDur.session = 'dur';
    exptDur.dataPath = fullfile(expt.dataPath, exptDur.session);
    if ~exist(exptDur.dataPath, 'dir')
        mkdir(exptDur.dataPath);
    end

    % Set up duration practice parameters
    exptDur.ntrials = 10;
    exptDur.shiftMags = zeros(1, exptDur.ntrials);
    exptDur.shiftAngles = zeros(1, exptDur.ntrials);

    % Practice words and conditions
    exptDur.words = {'head', 'dead', 'bed'};
    exptDur.allWords = randomize_wordOrder(length(exptDur.words), exptDur.ntrials);
    exptDur.listWords = exptDur.words(exptDur.allWords);

    exptDur.conds = {'noShift'};
    exptDur.allConds = ones(1, exptDur.ntrials);
    exptDur.listConds = exptDur.conds(exptDur.allConds);

    % Feedback and timing
    exptDur.bDurFB = ones(1, exptDur.ntrials);
    exptDur.timing = get_timing_params();
    exptDur.durcalc = get_durcalc_params();
    
    exptDur.bMaskingNoise = true;

    % Set defaults and save practice data
    exptDur = set_exptDefaults(exptDur);
    save(fullfile(exptDur.dataPath, 'expt.mat'), 'exptDur');

    % Run duration practice loop
    bRunTraining = 1; % Initialize training flag
    while bRunTraining
        exptDur.success = zeros(1, exptDur.ntrials);
        exptDur = run_F0vsF1_audapter(exptDur, 'duration');

        % Ask if the participant needs to redo training or abort
        rerun_response = askNChoiceQuestion(sprintf( ...
            'Participant was successful on: %d/%d trials. Redo training or abort?', ...
            sum(exptDur.success), length(exptDur.success)), ...
            {'redo', 'move on', 'abort'});
        if strcmp(rerun_response, 'move on')
            bRunTraining = 1; % Exit training loop
        elseif strcmp(rerun_response, 'abort')
            fprintf('Training aborted by the experimenter.\n');
            bRunTraining = 0; % Exit training and return false
            return;
        end
    end
end
