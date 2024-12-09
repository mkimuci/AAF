function plot_subject_data(subjectID, formantBins, pitchBins)
    % Define conditions and colors
    conditions = {'shiftUp', 'shiftDown', 'noShift'};
    colors = {'r', 'b', 'k'}; % Black for noShift, Red for shiftUp, Blue for shiftDown
    x = (0:299) * 2; % Time axis (ms)

    % Get all words and sort them alphabetically
    words = sort(fieldnames(formantBins));
    N = length(words);

    % Create figure
    figure('Name', ['Subject: ' subjectID], 'NumberTitle', 'off');

    % Loop through each word to create a subplot
    for wIdx = 1:N
        word = words{wIdx};
        subplot(N, 2, 2*wIdx-1); % Left panel: Formants
        for cIdx = 1:length(conditions)
            cond = conditions{cIdx};
            if isfield(formantBins.(word), cond)
                avg_F1 = mean_formants(formantBins.(word).(cond).F1);
                avg_F2 = mean_formants(formantBins.(word).(cond).F2);
                plot(x, avg_F1, 'Color', colors{cIdx}, 'LineWidth', 1.5); hold on;
                plot(x, avg_F2, 'Color', colors{cIdx}, 'LineWidth', 1.5);
            end
        end
        title([word ' Formants']);
        xlabel('Time (ms)');
        ylabel('Frequency (Hz)');
        ylim([200, 2200]);
        grid on;

        subplot(N, 2, 2*wIdx); % Right panel: Pitch
        for cIdx = 1:length(conditions)
            cond = conditions{cIdx};
            if isfield(pitchBins.(word), cond)
                avg_pitch = mean_formants(pitchBins.(word).(cond));
                plot(x, avg_pitch, 'Color', colors{cIdx}, 'LineWidth', 1.5); hold on;
            end
        end
        title([word ' Pitch']);
        xlabel('Time (ms)');
        ylabel('Pitch (Hz)');
        ylim([50, 400]);
        grid on;
    end

    % Add a super title for the subject
    sgtitle(['Subject ID: ' subjectID], 'FontSize', 16, 'FontWeight', 'bold');

    % Helper function for time-series average
    function avg_series = mean_formants(cellArray)
        maxLen = 300;
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
end
