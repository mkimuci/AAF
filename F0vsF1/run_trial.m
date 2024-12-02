function expt = run_trial(expt, shiftType, shiftRate, shiftAngle, itrial)
    p = getAudapterDefaultParams(expt.gender);

    % Set Audapter parameters based on shift type
    if strcmp(shiftType, 'F1')
        p.pertAmp = shiftRate * ones(1, 257);
        p.pertPhi = shiftAngle * ones(1, 257);
        p.bShift = 1;
        p.bMelShift = 1;
    elseif strcmp(shiftType, 'F0')
        p.bTimeDomainShift = 1;
        p.timeDomainPitchShiftSchedule = [0, shiftRate];
    end

    % Initialize Audapter
    AudapterIO('init', p);

    % Display visual stimulus
    h_fig = setup_exptFigs();
    h_text = draw_exptText(h_fig, 0.5, 0.5, expt.trials{itrial}.word, ...
        'FontSize', 40, 'HorizontalAlignment', 'center');
    pause(expt.timing.stimdur);
    delete_exptText(h_fig, h_text);

    % Start Audapter trial
    Audapter('start');
    pause(expt.timing.stimdur);
    Audapter('stop');

    % Save trial data
    trialFile = fullfile(expt.dataPath, sprintf('trial_%d.mat', itrial));
    save(trialFile, 'p');

    % Close figure
    close(h_fig);
end
