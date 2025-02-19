function [h_dur,success,vowel_dur] = plot_duration_feedback_circles(h_fig, data, params, ostTrigger, bConsiderBadtracks)
%add duration feedback to display for auditory compensation study. Inputs:
%   h_fig:          figure handle for plot
%   data:           Audapter data file for a single trial
%   params:         paramater struct including the following fields:
%      min_dur:     minimum allowable vowel duration (in s), default 0.25
%      max_dur:     maximum allowable vowel duration (in s), default 0.5
%      ons_thresh:  percentage of maximum amplitude for onset threshold
%                   (0-1), default 0.1
%      offs_thresh: percentage of maximum amplitude for offset threshold
%                   (0-1), default 0.4
%      bFirst_offs_thresh:  When searching for an offset threshold, whether
%                   to look for the first (1) or last (0) frame that drops
%                   below the offset threshold. Default 0.
%      bPrintDuration:  If 1, print vowel_dur for each trial, default 0.
%      bMeasureOst:     If 1, measure vowel length via duration of ost
%                       status specified in ostTrigger. Default 0.
%      badtrack_min_dur:    added for taimComp. Provides absolute minimum 
%                           duration to be considered an okay OST track (in s). 
%                           Defaults to 0.05 seconds
%      badtrack_max_dur:    added for taimComp. Provides absolute maximum 
%                           duration to be considered an okay OST track (in s). 
%                           Defaults to 1 second
%   ostTrigger:     The ost status used to measure duration. Only used if
%                   params.bMeasureOst==1. Default [].
% 
%   *** RPK addition for taimComp: 
%   bConsiderBadtracks:     flag to treat improbable values as the result of poor OST tracking rather than speech rate 
%                           issues. Defaults to 0 (compatible with other non-OST defaults). 
%                           If you flag this as 1, durations that are beyond what you specify in params.badtrack_min_dur and 
%                           params.badtrack_max_dur are not treated as too short/too long but rather as spoken unclearly. 
%                           This will only do anything if you have params.bMeasureOst set to 1. 
% 
%                           Note: this is distinct from the function performed by bOstStuck in the script proper, which just
%                           checks if the OST never advanced to the next stage at all. 
% 
% NC? initiated 2020
% CWN 02/2021 added functionality for using OSTs instead of amplitude thresholds 
% RPK 01/2022 added option to disregard probable bad OST tracking instead of giving duration feedback
% Minkyu Kim 02/2025 for Hickok Lab AAF study

if nargin < 3 || isempty(params), params = []; end
if nargin < 4, ostTrigger = []; end
if nargin < 5 || isempty (bConsiderBadtracks), bConsiderBadtracks = 0; end


%default duration tracking parameters
if ~isfield(params,'offs_thresh')
    params.offs_thresh = 0.55;
end
if ~isfield(params,'ons_thresh')
    params.ons_thresh = 0.15;
end
if ~isfield(params,'max_dur')
    params.max_dur = 0.6;
end
if ~isfield(params,'min_dur')
    params.min_dur = 0.4;
end
if ~isfield(params, 'circ_pos')
    params.circ_pos = [.45,.15,.1,.1];%define location and size of circle
end
if ~isfield(params, 'bFirst_offs_thresh')
    params.bFirst_offs_thresh = 1; %after max, find first instance below offs_thresh
end
if ~isfield(params, 'bPrintDuration')
    params.bPrintDuration = 0;
end
if ~isfield(params, 'bMeasureOst')
    params.bMeasureOst = 0;
end
% If you want to be more specific about badtracks (perhaps limit from the bottom as well) but don't have it specified
if bConsiderBadtracks
    if ~isfield(params, 'badtrack_max_dur')
        params.badtrack_max_dur = 1.000;                    % Using some pretty extreme durations 
    end
    if ~isfield(params, 'badtrack_min_dur')
        params.badtrack_min_dur = 0.05; 
    end
end
        


if params.bMeasureOst  %use OST statuses to find onset and offset
    onset = find(data.ost_stat == ostTrigger, 1);
    offset = find(data.ost_stat == ostTrigger+1, 1, 'last');
    if ~find(data.ost_stat == ostTrigger+2, 1)
        bOstStuck = 1; %ost didn't advance to the next "full" status
    else
        bOstStuck = 0;
    end
else  %use general amplitude thresholds to find onset and offset
    %get amplitude data from Audapter data structure
    ampl = data.rms(:,1);
    
    %find maximum amplitude
    [max_a,imax] = max(ampl);
    
    %find first point above amplitude threshold
    above_thresh = find(ampl>max_a*params.ons_thresh);
    if ~isempty(above_thresh)
        onset = above_thresh(1);
    else
        onset = [];
    end
    
    if params.bFirst_offs_thresh
        %find first point after amplitude max below amplitude threshold
        below_thresh = find(ampl(imax:end)<max_a*params.offs_thresh);
    else
        % find last point after max that's at or above the amplitude threshold.
        % Add 1 to find the frame right after.
        below_thresh = find(ampl(imax:end)>=max_a*params.offs_thresh, 1, 'last') + 1;
    end
    
    if ~isempty(below_thresh)
        offset = below_thresh(1)+imax;
    else
        offset = length(ampl); % Set to the last frame if no offset is found
    end 
end
    
%find vowel duration in frames
if ~isempty(offset) && ~isempty(onset)
    vowel_dur_frames = offset-onset;
else
    vowel_dur_frames = 0;
end

%convert from frames to s
vowel_dur = vowel_dur_frames*data.params.frameLen/data.params.sr;

% center = [params.circ_pos(1)+0.05 params.circ_pos(2)];

%plot feedback
figure(h_fig)
if vowel_dur <= params.max_dur && vowel_dur >= params.min_dur
    % TWO GREEN CIRCLES if correct duration
    h_dur(1) = draw_exptText(h_fig, 0.5, 0.4, ...
                    '⬤ ⬤', ...  
                    'FontSize', 120, 'Color', 'g', ...
                    'HorizontalAlignment', 'center');
    success = 1;

elseif vowel_dur > params.max_dur
    % THREE GREEN CIRCLES if too long
    h_dur(1) = draw_exptText(h_fig, 0.5, 0.4, ...
                    '⬤ ⬤ ⬤', ...  
                    'FontSize', 120, 'Color', 'g', ...
                    'HorizontalAlignment', 'center');
    success = 0;

elseif vowel_dur < params.min_dur
    % ONE GREEN CIRCLE if too short
    h_dur(1) = draw_exptText(h_fig, 0.5, 0.4, ...
                    '⬤', ...  
                    'FontSize', 120, 'Color', 'g', ...
                    'HorizontalAlignment', 'center');
    success = 0;
end
% if params.bMeasureOst && bOstStuck
%     h_dur(1) = viscircles(center,.05,'Color',[1 0.5 0]); %orange
%     h_dur(2) = text(params.circ_pos(1)+0.05,params.circ_pos(2)-0.1,{'Say it a little clearer'}, 'Color', [1 0.5 0], 'FontSize', 30,'HorizontalAlignment','Center');
%     success = 0;
% elseif params.bMeasureOst && bConsiderBadtracks && (vowel_dur < params.badtrack_min_dur || vowel_dur > params.badtrack_max_dur)
%     % taimComp addition for probable OST problems INCLUDING rushing (not just OST getting stuck) 
%     h_dur(1) = viscircles(center,.05,'Color',[1 0.5 0]); %orange
%     h_dur(2) = text(params.circ_pos(1)+0.05,params.circ_pos(2)-0.1,{'Say it a little clearer'}, 'Color', [1 0.5 0], 'FontSize', 30,'HorizontalAlignment','Center');
%     success = 0;
% elseif vowel_dur <= params.max_dur && vowel_dur >= params.min_dur
%     % Change: Color updated to Green for "okay" duration, and circle filled.
%     h_dur(1) = rectangle('Position', [center - 0.05, 0.1, 0.1], 'Curvature', [1, 1], 'FaceColor', 'g', 'EdgeColor', 'g');
%     success = 1;
% elseif vowel_dur > params.max_dur
%     % Change: Color updated to Red for "too long" duration, and circle filled.
%     h_dur(1) = rectangle('Position', [center - 0.05, 0.1, 0.1], 'Curvature', [1, 1], 'FaceColor', 'r', 'EdgeColor', 'r');
%     h_dur(2) = text(params.circ_pos(1) + 0.05, params.circ_pos(2) - 0.1, {'Say it a little shorter'}, ...
%         'Color', 'r', 'FontSize', 30, 'HorizontalAlignment', 'Center');
%     success = 0;
% elseif vowel_dur < params.min_dur
%     % Change: Color updated to Yellow for "too short" duration, and circle filled.
%     h_dur(1) = rectangle('Position', [center - 0.05, 0.1, 0.1], 'Curvature', [1, 1], 'FaceColor', 'y', 'EdgeColor', 'y');
%     h_dur(2) = text(params.circ_pos(1) + 0.05, params.circ_pos(2) - 0.1, {'Say it a little longer'}, ...
%         'Color', 'y', 'FontSize', 30, 'HorizontalAlignment', 'Center');
%     success = 0;
% end

if params.bPrintDuration 
    fprintf('vowel_dur was %.3f \n', vowel_dur);
end