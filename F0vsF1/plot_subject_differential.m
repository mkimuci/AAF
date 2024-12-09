function plot_subject_differential(subjectID, formantBins, pitchBins)
    % Define conditions and colors
    conditions = {'noShift', 'shiftUp', 'shiftDown'};
    formantColors = {"#77AC30", "#D95319"}; % Green for shiftUp, Orange for shiftDown
    pitchColors = {"#A2142F", "#0072BD"};        % Red for shiftUp, Blue for shiftDown
    x = (0:149) * 2; % Time axis (ms), truncated to 300 ms (150 samples)

    % Get all words and sort them alphabetically
    words = sort(fieldnames(formantBins));
    N = length(words);

    % Create figure
    tiledlayout(N, 3, 'TileSpacing', 'Compact'); % Create a tiled layout with N rows, 3 columns

    % Loop through each word to create subplots
    for wIdx = 1:N
        word = words{wIdx};
        
        % Left panel: First Formant (F1)
        nexttile;
        if isfield(formantBins, word)
            for cIdx = 2:3 % Only process shiftUp and shiftDown
                cond = conditions{cIdx};
                if isfield(formantBins.(word), cond) && isfield(formantBins.(word), 'noShift')
                    avg_F1_cond = truncate_series(mean_formants(formantBins.(word).(cond).F1));
                    avg_F1_noShift = truncate_series(mean_formants(formantBins.(word).noShift.F1));
                    plot(x, avg_F1_cond - avg_F1_noShift, 'Color', formantColors{cIdx - 1}, 'LineWidth', 1.5); hold on;
                end
            end
        end
        title([word ' F1 Differential']);
        xlabel('Time (ms)');
        ylabel('F1 Difference (Hz)');
        ylim([-100, 100]);
        grid on;

        % Middle panel: Second Formant (F2)
        nexttile;
        if isfield(formantBins, word)
            for cIdx = 2:3 % Only process shiftUp and shiftDown
                cond = conditions{cIdx};
                if isfield(formantBins.(word), cond) && isfield(formantBins.(word), 'noShift')
                    avg_F2_cond = truncate_series(mean_formants(formantBins.(word).(cond).F2));
                    avg_F2_noShift = truncate_series(mean_formants(formantBins.(word).noShift.F2));
                    plot(x, avg_F2_cond - avg_F2_noShift, 'Color', formantColors{cIdx - 1}, 'LineWidth', 1.5); hold on;
                end
            end
        end
        title([word ' F2 Differential']);
        xlabel('Time (ms)');
        ylabel('F2 Difference (Hz)');
        ylim([-100, 100]);
        grid on;

        % Right panel: Pitch
        nexttile;
        if isfield(pitchBins, word)
            for cIdx = 2:3 % Only process shiftUp and shiftDown
                cond = conditions{cIdx};
                if isfield(pitchBins.(word), cond) && isfield(pitchBins.(word), 'noShift')
                    avg_pitch_cond = truncate_series(mean_formants(pitchBins.(word).(cond)));
                    avg_pitch_noShift = truncate_series(mean_formants(pitchBins.(word).noShift));
                    plot(x, avg_pitch_cond - avg_pitch_noShift, 'Color', pitchColors{cIdx - 1}, 'LineWidth', 1.5); hold on;
                end
            end
        end
        title([word ' Pitch Differential']);
        xlabel('Time (ms)');
        ylabel('Pitch Difference (Hz)');
        ylim([-20, 20]);
        grid on;
    end

    % Add a super title for the subject
    sgtitle(['Subject ID: ' subjectID ' - Differential Data'], 'FontSize', 16, 'FontWeight', 'bold');

    % Helper function for time-series average
    function avg_series = mean_formants(cellArray)
        maxLen = 300; % Limit the series to 300 ms
        matrix = nan(length(cellArray), maxLen);
        for i = 1:length(cellArray)
            series = cellArray{i};
            matrix(i, :) = pad_or_truncate(series, maxLen);
        end
        avg_series = mean(matrix, 1, 'omitnan');
    end

    % Helper function for padding or truncating
    function y = pad_or_truncate(x, maxLen)
        if length(x) > maxLen
            y = x(1:maxLen);
        else
            y = [x; nan(maxLen - length(x), 1)];
        end
    end

    % Helper function to truncate series to 150 samples (0-300 ms)
    function truncated = truncate_series(series)
        truncated = series(1:150);
    end
end
