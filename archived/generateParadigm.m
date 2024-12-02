function [nTrials, seqWord, seqCond, seqF0shift, seqF1shift, ...
    seqF2angle] = generateParadigm(varargin)
    
    % Initialize the random number generator (MATLAB R2011a or later)
    rng('default');
    rng('shuffle');
    
    wordset = {'beck', 'bet', 'yyy'};
    % wordset = {'beck', 'bet', 'dek', 'debt', ...
    %            'peck', 'pep', 'ted', 'tek', 'yyy'};
    condset = repmat({'control'}, 1, 8);
    condset{1} = 'F0 up'; condset{2} = 'F0 down'; 
    condset{3} = 'F1 up'; condset{4} = 'F1 down'; 
    
    F0upShift = 6;
    F0downShift = (-1) * F0upShift;
    F1upShift = 50;
    F1downShift = (-1) * F1upShift;
    F2angle = 315;
    
    nWord = size(wordset, 2);
    nCond = size(condset, 2);
    nTrials = nWord * nCond;
    
    [idxWord, idxCond] = pseudorandomize_trials(nCond, nWord);
    
    seqWord = wordset(idxWord);
    seqCond = condset(idxCond);
    
    mapCondtoF0Shift = @(x) isequal(x, 'F0 up') * F0upShift + ...
                            isequal(x, 'F0 down') * F0downShift;
    
    mapCondtoF1Shift = @(x) isequal(x, 'F1 up') * F1upShift + ...
                            isequal(x, 'F1 down') * F1downShift;

    mapCondtoF2angle = @(x) isequal(x, 'F1 up') * F2angle + ...
                            isequal(x, 'F1 down') * F2angle;
    
    seqF0shift = cellfun(mapCondtoF0Shift, seqCond, 'UniformOutput', false);
    seqF1shift = cellfun(mapCondtoF1Shift, seqCond, 'UniformOutput', false);
    seqF2angle = cellfun(mapCondtoF2angle, seqCond, 'UniformOutput', false);
end

function [stimuli, conditions] = pseudorandomize_trials(M, N)
    % Initialize matrices
    stimuli = repmat(1:N, M, 1);
    conditions = repmat((1:M)', 1, N);

    % Combine into a tuple matrix
    combined = cat(3, stimuli, conditions);
    
    % Shuffle columns (conditions)
    combined = shuffleColumns(combined, M, N);
    
    % Shuffle rows (stimuli)
    combined = shuffleRows(combined, M, N);
    
    % Split the matrix back into stimuli and conditions
    stimuli = combined(:,:,1);
    conditions = combined(:,:,2);
    
    % % Save to text files
    % dlmwrite('stimuli.txt', stimuli, 'delimiter', ' ');
    % dlmwrite('conditions.txt', conditions, 'delimiter', ' ');

    stimuli = reshape(stimuli.', M * N, 1);
    conditions = reshape(conditions.', M * N, 1);
end

function combined = shuffleColumns(combined, M, N)
    for col = 1:N
        column = combined(:, col, :);
        combined(:, col, :) = column(randperm(M), :, :);
    end
end

function combined = shuffleRows(combined, M, N)
    for row = 1:M
        newRow = combined(row, :, :);
        if row == 1            
            success = false;
            while ~success
                newRow = newRow(:, randperm(N), :);
                if newRow(1, 1, 1) ~= N
                    success = true;
                end
            end
        else
            prevRow = combined(row-1, :, :);
            success = false;
            while ~success
                newRow = newRow(:, randperm(N), :);
                if all(newRow(1, 1, :) ~= prevRow(1, 1, :))
                    success = true;
                end
            end
        end
        combined(row, :, :) = newRow;
    end
end


