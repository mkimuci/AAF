function expt = generate_paradigm(expt)

    % Initialize parameters
    nWords = length(expt.words); % Number of words (3)
    uniquePerts = 2; % Number of perturbation types (e.g., shiftUp, shiftDown)
    nTrialsPerPert = 1; % Number of trials per perturbation
    nTrialsPerNonpert = 4; % Number of non-perturbed trials per word
    
    % Total trials per block and experiment
    expt.nblocks = 5;
    expt.ntrials_per_block = nWords * (nTrialsPerPert * uniquePerts ...
                            + nTrialsPerNonpert); % 90 trials/block
    expt = randomize_stimuli(expt,nTrialsPerPert,nTrialsPerNonpert);
    expt.ntrials = expt.nblocks * expt.ntrials_per_block;
    
    % Assign words and conditions
    expt.listWords = expt.words(expt.allWords);
    expt.listConds = expt.conds(expt.allConds);
    
    % Set shift directions, magnitudes, and names
    expt.listShiftDirs = [expt.shiftDirs{expt.allConds}];
    expt.listShiftNames = expt.conds(expt.allConds);

    if strcmp(expt.shiftType, 'F1')
        expt.shiftMag = 125;
        expt.shiftMags = expt.shiftMag * expt.listShiftDirs;
        expt.shiftAngle = 3 * pi / 4; % F1 up F2 down
        expt.shiftAngles = expt.shiftAngle * abs(expt.listShiftDirs);
    elseif strcmp(expt.shiftType, 'F0')
        expt.shiftMag = 6;
        expt.shiftMags = 1 + (expt.listShiftDirs * (expt.shiftMag / 100));
    end

    % Break trials setup
    expt.breakFrequency = expt.ntrials_per_block * 2; % Break every 2 blocks
    expt.breakTrials = expt.breakFrequency:expt.breakFrequency:expt.ntrials;
    
    % Duration feedback setup
    expt.bDurFB = ones(1, expt.ntrials); % Feedback for all trials
    
    % Finalize experiment structure
    expt = set_exptDefaults(expt);
end
