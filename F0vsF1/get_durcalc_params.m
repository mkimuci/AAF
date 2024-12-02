function durcalc = get_durcalc_params()
    durcalc.min_dur = 0.4;         % Minimum allowable vowel duration (seconds)
    durcalc.max_dur = 0.65;        % Maximum allowable vowel duration (seconds)
    durcalc.ons_thresh = 0.15;     % Percentage of max amplitude for onset threshold
    durcalc.offs_thresh = 0.4;     % Percentage of max amplitude for offset threshold
end
