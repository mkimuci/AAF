function [formantBins, pitchBins] = process_subject_data(subjectID, dataDir)
    % Define subject directory
    subjectDir = fullfile(dataDir, subjectID);
    
    % Process F1 experiments (formants)
    formantFiles = dir(fullfile(subjectDir, '*_F1.mat'));
    formantBins = struct();
    
    for fileIdx = 1:length(formantFiles)
        exptFile = fullfile(formantFiles(fileIdx).folder, formantFiles(fileIdx).name);
        load(exptFile, 'currExpt');
        
        words = currExpt.listWords;
        conds = currExpt.listConds;
        exptNum = str2double(extractBetween(formantFiles(fileIdx).name, '_', '_F1'));
        
        for trialIdx = 1:length(words)
            trialFile = fullfile(subjectDir, sprintf('trial_%d_%d.mat', exptNum, trialIdx));
            if exist(trialFile, 'file')
                load(trialFile, 'data');
                fmts = data.fmts;
                fmts = fmts(any(fmts > 0, 2), :);
                F1 = fmts(:, 1);
                F2 = fmts(:, 2);
                word = words{trialIdx};
                cond = conds{trialIdx};
                if ~isfield(formantBins, word)
                    formantBins.(word) = struct();
                end
                if ~isfield(formantBins.(word), cond)
                    formantBins.(word).(cond) = struct('F1', {{}}, 'F2', {{}});
                end
                formantBins.(word).(cond).F1{end+1} = F1;
                formantBins.(word).(cond).F2{end+1} = F2;
            end
        end
    end
    
    % Process F0 experiments (pitch)
    pitchFiles = dir(fullfile(subjectDir, '*_F0.mat'));
    pitchBins = struct();
    
    for fileIdx = 1:length(pitchFiles)
        exptFile = fullfile(pitchFiles(fileIdx).folder, pitchFiles(fileIdx).name);
        load(exptFile, 'currExpt');
        
        words = currExpt.listWords;
        conds = currExpt.listConds;
        exptNum = str2double(extractBetween(pitchFiles(fileIdx).name, '_', '_F0'));
        
        for trialIdx = 1:length(words)
            trialFile = fullfile(subjectDir, sprintf('trial_%d_%d.mat', exptNum, trialIdx));
            if exist(trialFile, 'file')
                load(trialFile, 'data');
                pitch = data.pitchHz;
                pitch = pitch(pitch > 0);
                word = words{trialIdx};
                cond = conds{trialIdx};
                if ~isfield(pitchBins, word)
                    pitchBins.(word) = struct();
                end
                if ~isfield(pitchBins.(word), cond)
                    pitchBins.(word).(cond) = {};
                end
                pitchBins.(word).(cond){end+1} = pitch;
            end
        end
    end
end
