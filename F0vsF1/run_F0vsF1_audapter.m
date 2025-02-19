function expt = run_F0vsF1_audapter(expt, mode)
    if nargin < 1, error('Must pass in valid expt variable.'); end
    if nargin < 2, mode = 'main'; end
    
    % Setup figures
    h_fig = setup_exptFigs();
    get_figinds_audapter; % Subplot names: stim = 1, ctrl = 2, dup = 3
    h_sub = get_subfigs_audapter(h_fig(ctrl), 1);
    add_adjustOstButton(h_fig, {'settings'});

    % Setup Audapter
    audioInterfaceName = 'Focusrite USB'; % Example device name
    Audapter('deviceName', audioInterfaceName);

    Audapter('ost', '', 0); % Nullify online status tracking
    Audapter('pcf', '', 0); % Nullify perturbation config files
    
    % Set default and experiment-specific Audapter parameters
    p = getAudapterDefaultParams(expt.gender);

    if isfield(expt, 'audapterp')
        p = add2struct(p, expt.audapterp);
    end 

    if expt.bMaskingNoise
        [w, fs] = read_audio('mtbabble48k.wav');
        if fs ~= p.sr * p.downFact    % resample noise to recording rate
            w = resample(w, p.sr * p.downFact, fs);
        end
        maxPBSize = Audapter('getMaxPBLen');
        if length(w) > maxPBSize
            w = w(1 : maxPBSize);
        end
    
        Audapter('setParam', 'datapb', w, 1);
    
        % set feedback mode to speech + noise
        p.fb = 3;
        p.fb3Gain = 0.035;
    end
    
    if strcmp(mode, 'main')
        nSessions = 2 * expt.nF0vsF1expt; % Total sessions (F0 and F1)
        currentSession = expt.iExpt;
        sessionText = sprintf('Session %d of %d', ...
                              currentSession, nSessions);

        switch expt.shiftType
            case "F0"
                p.bShift = 1;
                p.bTimeDomainShift = 1;
                p.bRatioShift = 0;
                p.bMelShift = 0;

                if isequal(lower(expt.gender), 'female')
                    p.pitchLowerBoundHz = 150;
                    p.pitchUpperBoundHz = 300;
                elseif isequal(lower(expt.gender), 'male')
                    p.pitchLowerBoundHz = 75;
                    p.pitchUpperBoundHz = 200;
                end                
    
                % not sure what this does - MK
                p.nDelay = 7;
                p.bCepsLift = 1;
                p.rmsThresh = 0.011;
    
            case "F1"        
                p.bTrack = 1;
                p.bShift = 1;
                p.bTimeDomainShift = 0;
                p.bRatioShift = 0;
                p.bMelShift = 1;
            otherwise
                % do nothing
        end
    else
        expt.shiftType = "none";
        expt.iExpt = 0;
        sessionText = sprintf('Practice Session');
    end
    
    p.f1Min = 100;
    p.f1Max = 900;  
    p.f2Min = 1500;
    p.f2Max = 2500;  

    prepareText = ['Preparing ' sessionText '...'];
    h_sessionInfo = draw_exptText(h_fig, 0.5, 0.5, prepareText, ...
                                  'FontSize', 60, 'Color', 'white', ...
                                  'HorizontalAlignment', 'center');
    
    % Pause briefly to allow participant to read
    pause(3); % Adjust duration as needed
    
    % Remove the session info text
    delete_exptText(h_fig, h_sessionInfo);

    readyText = [sessionText ' will soon begin...'];
    % Give instructions and wait for keypress
    h_ready = draw_exptText(h_fig, 0.5, 0.5, ...
                            readyText, ...
                            'FontSize', 60, 'Color', 'white', ...
                            'HorizontalAlignment', 'center');

    % Enable all keys first
    DisableKeysForKbCheck([]);
    
    validTrigger = false;
    while ~validTrigger
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            % Check if '5%' was pressed
            if find(keyCode) == KbName('5%')
                % We got the MRI trigger once
                validTrigger = true;
                % Disable all further '5%' inputs so repeated triggers are ignored
                DisableKeysForKbCheck(KbName('5%'));
            end
        end
    end
    exptStartTime = GetSecs();

    delete_exptText(h_fig, h_ready);
    pause(3);

    firstTrial = 1;
    lastTrial = expt.ntrials;

    % Determine trial range
    if strcmp(mode, 'duration')
        fprintf('Starting duration practice...\n');
    else
        fprintf('Starting main experiment...\n');
    end

    % Run trials
    for itrial = firstTrial:lastTrial
        timestamps = struct();
        % trialStartTime = tic; % Start timing for the trial

        trialStartTime = GetSecs();
        timestamps.trialOnset = trialStartTime - exptStartTime;

        bGoodTrial = 0;
        while ~bGoodTrial
            % Pause controls
            if get_pause_state(h_fig, 'p'), pause_trial(h_fig); end
            if get_pause_state(h_fig, 'e')
                adjustments = {'trialdur', 'voweldur'};
                setting2change = askNChoiceQuestion('Change trial duration (1) or vowel properties (2)?', [1 2], 0);
                adjustment = adjustments{setting2change};
                expt = adjust_experimentSettings(expt, h_fig, adjustment);
            end
            if get_pause_state(h_fig, 'q')
                fprintf('Experiment aborted by the experimenter.\n'); 
                close(h_fig);
                return; % Gracefully exit the function
            end

            % Plot trial info
            cla(h_sub(1));
            ctrltxt = sprintf('Trial: %d/%d, Condition: %s', itrial, lastTrial, expt.listConds{itrial});
            text(h_sub(1), 0, 0.5, ctrltxt, 'Color', 'white', ...
                 'FontSize', 30, 'HorizontalAlignment', 'center');
            switch expt.shiftType
                case "F0"
                    % no delay, shift immediately
                    p.timeDomainPitchShiftAlgorithm = 'pp_none';
                    p.timeDomainPitchShiftSchedule = [0, expt.shiftMags(itrial); 2, expt.shiftMags(itrial)]; 
                case "F1"
                    % Set perturbation parameters
                    p.pertAmp = expt.shiftMags(itrial) * ones(1, 257);
                    p.pertPhi = expt.shiftAngles(itrial) * ones(1, 257);
                    Audapter('setParam', 'pertAmp', p.pertAmp);
                    Audapter('setParam', 'pertPhi', p.pertPhi);
                otherwise
                    % do nothing
            end

            AudapterIO('init', p);
            AudapterIO('reset');        
            % timestamps.audapterInit = toc(trialStartTime);

            % Display visual stimuli
            fprintf('Starting trial %d\n', itrial);
            txt2display = expt.listWords{itrial};
            h_text = draw_exptText(h_fig, 0.5, 0.5, txt2display, ...
                                   'Color', 'white', 'FontSize', 200, ...
                                   'HorizontalAlignment', 'center');
            % timestamps.stimDisplayed = toc(trialStartTime);

            % Start and stop Audapter
            Audapter('start');
            % timestamps.audapterStart = toc(trialStartTime);

            pause(expt.timing.stimdur);
            Audapter('stop');
            % timestamps.audapterStop = toc(trialStartTime);
            
            fprintf('Audapter ended for trial %d\n', itrial);
            data = AudapterIO('getData');
            
            % Remove displayed text
            delete_exptText(h_fig, h_text);

            % Plot shifted spectrogram
            subplot_expt_spectrogram(data, p, h_fig, h_sub);

            % Check if participant spoke loud enough
            subplot(h_sub(3));
            yyaxis right;
            hline(2, 'r', '-'); % Reference line

            % expectedSamples = round(expt.timing.stimdur * ...
            %     data.params.sRate);
            % actualSamples = length(data.signalIn);
            % 
            % if actualSamples < expectedSamples * 0.75
            %     bGoodTrial = 2;
            % else
                bGoodTrial = check_rmsThresh(data, expt.amplcalc, h_sub(3));
            % end

            % timestamps.feedbackStart = toc(trialStartTime);
            if bGoodTrial == 0
                % Display feedback to speak louder
                h_feedback = draw_exptText(h_fig, 0.5, 0.4, ...
                    '◯', ...  % 'Please speak a little louder.'
                    'FontSize', 120, 'Color', 'g', ...
                    'HorizontalAlignment', 'center');
                pause(expt.timing.visualfbdur);
                delete_exptText(h_fig, h_feedback);
            % elseif bGoodTrial == 2
            %     % Audapter didn't collect enough samples
            %     h_feedback = draw_exptText(h_fig, 0.5, 0.2, ...
            %         ' ', ...
            %         'FontSize', 40, 'Color', 'yellow', ...
            %         'HorizontalAlignment', 'center');
            %     pause(expt.timing.visualfbdur);
            %     delete_exptText(h_fig, h_feedback);
            %     bGoodTrial = 0;
            elseif expt.bDurFB(itrial)

                % Display duration feedback
                [h_dur, success] = plot_duration_feedback_circles(h_fig(stim), data, expt.durcalc);
                expt.success(itrial) = success;

                % Clone figure for duplication
                CloneFig(h_fig(stim), h_fig(dup));

                % Pause for viewing feedback
                pause(expt.timing.visualfbdur);

                % Remove feedback display
                delete_exptText(h_fig, h_dur);
            end
            % timestamps.feedbackEnd = toc(trialStartTime);

            % Add intertrial interval with jitter
            pause(expt.timing.interstimdur + rand * expt.timing.interstimjitter);
            % timestamps.jitterEnd = toc(trialStartTime);

            data.timestamps = timestamps;

            % -- Only log for the "main" experiment --
            if strcmp(mode, 'main')    
                % currentSession is the same as 'expt.iExpt' from your code
                fid = fopen(expt.csvPath, 'a');
                fprintf(fid, '%d,%d,%.4f,%s,%s\n', ...
                        expt.iExpt, ...               % currentSession
                        itrial, ...                  % iTrial
                        timestamps.trialOnset, ...   % trial onset from GetSecs
                        expt.shiftType, ...          % shiftType (e.g. "F0" or "F1")
                        expt.listConds{itrial});     % condition label
                fclose(fid);
            end

            % Save trial data
            trialFile = fullfile(expt.dataPath, sprintf('trial_%d_%d.mat', expt.iExpt, itrial));
            save(trialFile, 'data');

            % Define file names for signalIn and signalOut WAV files
            signalInFileName = fullfile(expt.dataPath, sprintf('trial%02d_%03d_signalIn.wav', expt.iExpt, itrial));
            signalOutFileName = fullfile(expt.dataPath, sprintf('trial%02d_%03d_signalOut.wav', expt.iExpt, itrial));
            
            % Save signalIn as a WAV file
            audiowrite(signalInFileName, data.signalIn, data.params.sRate);
            
            % Save signalOut as a WAV file
            audiowrite(signalOutFileName, data.signalOut, data.params.sRate);
        end
    end

    if strcmp(mode, 'main')
        sessionText = sprintf('Session %d of %d Complete', ...
                              currentSession, nSessions);
    else
        sessionText = sprintf('Practice Session Complete');
    end

    h_sessionInfo = draw_exptText(h_fig, 0.5, 0.5, sessionText, ...
                                  'FontSize', 60, 'Color', 'white', ...
                                  'HorizontalAlignment', 'center');
    
    validTrigger = false;
    while ~validTrigger
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            % Check if '6^' was pressed
            if find(keyCode) == KbName('6^')
                validTrigger = true;
                DisableKeysForKbCheck([]);
            end
        end
    end

    pause(1); % Adjust duration as needed
    
    % Remove the session info text
    delete_exptText(h_fig, h_sessionInfo);

    fprintf('%s complete.\n', mode);
    close(h_fig);
end
