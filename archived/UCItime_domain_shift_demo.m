function UCItime_domain_shift_demo(pitchGender, isOnline, UCIF0, duration, myplot, varargin)
%% Offline and online demo for time-domain pitch shifting.  UCI lines ~103-107, ~130 (pause); lines ~38-40 (toPlay variable; play sound)
% Usage examples:
% - For offline demo:
%   time_domain_shift_demo('female', 0, '--wav', 'C:\speechres\samples\dante\Pilot22SF2Trial5_micIn.wav', '--play');
%   time_domain_shift_demo('male', 0, '--wav', 'C:\speechres\samples\dante\Pilot26SF3Trial4_micIn.wav', '--play');
%  
% - For online demo:
%   time_domain_shift_demo('female', 1);
%   time_domain_shift_demo('male', 1);

% Configurations    UCI: Added by UCI/KS Otherwise it reverts back to MOTO notebook    ********** KS
audioInterfaceName = 'Focusrite USB';

sRate = 48000;  % Hardware sampling rate (before downsampling)
downFact = 3;
frameLen = 64;  % Before downsampling

%%                             UCI added by ***********************************   KS
Audapter('deviceName', audioInterfaceName);
% Audapter('setParam', 'downFact', downFact, 0);
% Audapter('setParam', 'sRate', sRate / downFact, 0);
% Audapter('setParam', 'frameLen', frameLen / downFact, 0);



%% Input parameter sanity check and processing.
if isempty(fsic({'female', 'male'}, pitchGender))
    error('Invalid value in pitchGender: %s', pitchGender);
end

if ~isOnline
    if ~isempty(fsic(varargin, '--wav'))
        inputWav = varargin{fsic(varargin, '--wav') + 1};
    else
        error('--wav <WAV_FILE_PATH> not provided for online demo.');
    end
end

toPlay = ~isempty(fsic(varargin, '--play'));
%toPlay=1;
wavSaveDir = '';
if ~isempty(fsic(varargin, '--save_wav'))
    wavSaveDir = varargin{fsic(varargin, '--save_wav') + 1};
    if ~isdir(wavSaveDir)
        error('%s is not a directory', wavSaveDir);
    end
end

algorithm = '';
if ~isempty(fsic(varargin, '--pp_peaks'))
    algorithm = 'pp_peaks';
elseif ~isempty(fsic(varargin, '--pp_valleys'))
    algorithm = 'pp_valleys';
end

%% Get parameters for time-domain shifting.
params = getAudapterDefaultParams(pitchGender);
params
% Activate time-domain pitch shifting.
params.bTimeDomainShift = 1;

% Set the a priori pitch range.
% Adjust if necessary. You may even consider set this on a per-subject
% basis! The more accurate the a prior estimate, the lower the likelihood
% of incorrect real-time pitch tracking leading to occasional artifacts in
% the pitch shifted feedback.
if isequal(lower(pitchGender), 'female')
    params.pitchLowerBoundHz = 150;
    params.pitchUpperBoundHz = 300;
elseif isequal(lower(pitchGender), 'male')
    params.pitchLowerBoundHz = 80;
    params.pitchUpperBoundHz = 160;
end

% Use a long-enough frame length (and hence spectral/cepstral) window to
% ensure accurate real-time pitch tracking.
params.frameLen=32;  % %%%%%%%%%%%%%%%%%%%%%%%% ADDED BY KS
%params.frameLen=64;  % %%%%%%%%%%%%%%%%%%%%%%%% ADDED BY KS

params.nDelay = 7;
% Time-domain shift requires bCepsLift = 1.
params.bCepsLift = 1;

if isempty(algorithm)
    params.timeDomainPitchShiftAlgorithm = 'pp_none';
else
    params.timeDomainPitchShiftAlgorithm = algorithm;
end

% The following line specifies the time-domain pitch perturbation schedule.
% It is a 3x2 matrix. Each row corresponds to an "anchor point" in time.
% The 1st element of the row is the time relative to the crossing of the
% intensity threshold (i.e., params.rmsThresh below).
% The 2nd element is the pitch shift ratio. A pitch shift ratio value of
% 1.0 means unshifted. A value of 2 means an octave of up-shift. So 1.0595
% is approximately an upshift of 1 semitone (100 cents).
% For time points between the anchor points, the shift amount is calculated
% from linear intepolation. For time points after the last anchor point,
% the pitch shift value from the last anchor point is maintained.
%
% Therefore, the example below means "Exert no perturbation in the first
% second after the crossing of the intensity threshold; then linearly 
% ramp up the pitch-shift ratio from none to 100 cents in a period of 1
% sec; finally hold the 100-cent shift until the end of the supra-threshold
% event".

%KS: the last parameter in line above is percentage relative to 1.0, so 0.8 is 20% down
%params.timeDomainPitchShiftSchedule = [0, 1.0; 0.1, UCIF0];  %KS start shifting at 100ms after sound onset
%params.timeDomainPitchShiftSchedule = [0, 1.0; 0.1, 1.0; 0.1,UCIF0];  %op start shifting at 100ms after sound onset
%params.timeDomainPitchShiftSchedule = [0, 1.0; 1.0,UCIF0];  %op start shifting at 100ms after sound onset

params.rmsThresh = 0.011;
params.frameLen = 64;
%UCIF0 is variable added by KS to be able to change F0 in other programs
params.timeDomainPitchShiftSchedule = [0, UCIF0];  %no delay, shift immediately

%%%%%%%%%%%%%%% NEXT 3 LINES ADDED BY KS TO GET CORRECT FRAME LENGTH WHEN
%%%%%%%%%%%%%%% SWITCHING BETWEEN F0 AND F1
% Audapter('setParam', 'downFact', downFact, 0);              %%%%%%%%%% ADDED BY KS
% Audapter('setParam', 'sRate', sRate / downFact, 0);       %%%%%%%%%% ADDED BY KS
% Audapter('setParam', 'frameLen', frameLen / downFact, 0);  %%%%%%%%%% ADDED BY KS


  
AudapterIO('init', params);
AudapterIO('reset');   % Reset;

if ~isOnline
    %% Offline demo: load and process input sound from wav file.
    fsNoDownsample = params.sr * params.downFact;
    frameLenNoDownsample = params.frameLen * params.downFact;

    [w, wfs] = audioread(inputWav);
    sigIn = resample(w, fsNoDownsample, wfs);
    sigIn = sigIn - mean(sigIn);
    sigInCell = makecell(sigIn, frameLenNoDownsample);

    tic;
    for n = 1 : length(sigInCell)
        Audapter('runFrame', sigInCell{n});
    end
    elapsed = toc;
    fprintf( ...
        'Offline demo: Processing %.3f s of input audio took %.3f s.\n', ...
        length(w) / wfs, elapsed);
else
    %% Online demo.
    global recordDuration;
    Audapter('start');
    pause(recordDuration);  %%%%%%%%%%%%%%%%%%%%%  ADDED BY OP
    Audapter('stop');
end

%% Visualize data.
data = AudapterIO('getData');

frameDur = data.params.frameLen / data.params.sr;
tAxis = 0 : frameDur : frameDur * (size(data.fmts ,1) - 1);
% get the formant plot bounds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%ADDED BY KS
if myplot==1

%figure('Position', [200, 200, 800, 400]);
figure('units','normalized','pos',[0.005    0.05    0.25    0.35]);  %%%%%%%%%%%KS
[s, f, t] = spectrogram(data.signalIn, 64, 48, 1024, data.params.sr);
[s2, f2, t2] = spectrogram(data.signalOut, 64, 48, 1024, data.params.sr);

subplot(211);
imagesc(t, f, 10 * log10(abs(s))); 
axis xy;
colormap jet;
hold on;
plot(tAxis, data.fmts(:, 1 : 2), 'w', 'LineWidth', 2);
set(gca, 'YLim', [0, 4000]);
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Original');

subplot(212);
imagesc(t2, f2, 10 * log10(abs(s2)));
axis xy;
colormap jet;
hold on;
plot(tAxis, data.fmts(:, 1 : 2), 'w', 'LineWidth', 2);
plot(tAxis, data.sfmts(:, 1 : 2), 'g--', 'LineWidth', 2);
set(gca, 'YLim', [0, 4000]);
xlabel('Time (s)');
ylabel('Frequency (Hz)');
title('Shifted');
%set(2,'units','normalized','pos',[0.005    0.05    0.25    0.35])


% figure;    %%%%%%%%%%%%%%%%%%%%% FIGURES 2 AND 3 TAKEN OUT BY KS
% hold on;
% sigTAxis1 = 0 : 1 / data.params.sr : ...
%     1 / data.params.sr * (length(data.signalIn) - 1);
% plot(sigTAxis1, data.signalIn, 'b-');
% ylabel('Input waveform');
% xlabel('Time (s)');
% 
% sigTAxis2 = 0 : 1 / data.params.sr : ...
%     1 / data.params.sr * (length(data.signalOut) - 1);
% plot(sigTAxis2, data.signalOut, 'r-');
% legend({'Input', 'Output'});
% ylabel('Output waveform');
% xlabel('Time (s)');
% 
% figure;
% hold on;
% plot(sigTAxis1(1 : end - 1), diff(data.signalIn), 'b-');
% ylabel('d Input waveform');
% xlabel('Time (s)');
% plot(sigTAxis2(1 : end - 1), diff(data.signalOut), 'r-');
% legend({'Input', 'Output'});
% ylabel('d Output waveform');
% xlabel('Time (s)');

% When time-domain pitch shifting is activated, data.pitchHz and
% data.shfitedPitchHz record the tracked and shifted pitch values in Hz,
% for supra-threshold frames.
%figure;
figure('units','normalized','pos',[0.005    0.5    0.25    0.35]);  %%%%%%%%%%%%%%% KS
plot(tAxis, data.pitchHz, 'b-');
hold on;
plot(tAxis, data.shiftedPitchHz, 'r-');
legend({'Input', 'Output'});
xlabel('Time (s)');
ylabel('Pitch (Hz)');

end; %if my plot %%%%%%%%%%%%%%%%%%%%%%% ADDED BY KS



%% Play input and output sound.
if toPlay
    drawnow;
%     play_audio(data.signalIn, data.params.sr);
    play_audio(data.signalOut, data.params.sr);
end

% Optional: save wav files.
if wavSaveDir
    if isOnline
        error('Wav files saving is not implemented for online demo yet.');
    end
    [~, fileName, ~] = fileparts(inputWav);
    
    saveInputWavPath = fullfile(wavSaveDir, [fileName, '_input.wav']);
    saveOutputWavPath = fullfile(wavSaveDir, [fileName, '_output.wav']);
    audiowrite(saveInputWavPath, data.signalIn, data.params.sr);
    fprintf('Saved input waveform to %s\n', saveInputWavPath);
    audiowrite(saveOutputWavPath, data.signalOut, data.params.sr);
    fprintf('Saved output waveform to %s\n', saveOutputWavPath);
end

end


