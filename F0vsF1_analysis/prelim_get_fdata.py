import os
import numpy as np
import pandas as pd
from scipy.io import loadmat, savemat
import parselmouth

# Base directory and subjects
base_dir = "/Users/minkyu/experiments/F0vsF1"
subject_ids = [d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d))]
subject_ids = ["110"]
time_step = 0.002
max_samples = 150

# Load optimal ceiling values from the CSV file
ceiling_file = os.path.join(base_dir, 'optimal_ceilings.csv')
optimal_ceiling_df = pd.read_csv(ceiling_file)
optimal_ceiling = dict(zip(optimal_ceiling_df['Subject ID'].astype(str), optimal_ceiling_df['Optimal Ceiling']))

def detect_onset(signal, srate, gender):
    """Detect the onset time based on intensity and pitch."""
    snd = parselmouth.Sound(signal, srate)

    # Intensity threshold: highest - 10 dB
    intensity_obj = snd.to_intensity()
    intensity_values = intensity_obj.values.flatten()
    intensity_times = intensity_obj.xs()
    intensity_threshold = np.max(intensity_values) - 10
    intensity_onset_idx = np.argmax(intensity_values > intensity_threshold)
    intensity_onset_time = intensity_times[intensity_onset_idx] if intensity_onset_idx < len(intensity_times) else np.inf

    # Pitch onset
    if gender.lower() == 'male':
        pitch_floor, pitch_ceiling = 50, 250
    else:
        pitch_floor, pitch_ceiling = 100, 400

    pitch_obj = snd.to_pitch(time_step=None, pitch_floor=pitch_floor, pitch_ceiling=pitch_ceiling)
    pitch_values = pitch_obj.selected_array['frequency']
    pitch_times = pitch_obj.xs()
    pitch_onset_idx = np.argmax(pitch_values > 0)
    pitch_onset_time = pitch_times[pitch_onset_idx] if pitch_onset_idx < len(pitch_times) else np.inf

    # Onset is the later of the two
    onset_time = max(intensity_onset_time, pitch_onset_time)
    return onset_time

def extract_formants(signal, srate, gender):
    """Extract formants without masking for intensity or pitch."""
    snd = parselmouth.Sound(signal, srate)

    # Use the optimal ceiling from the CSV, defaulting to gender-based ceiling
    default_ceiling = 5000 if gender.lower() == 'male' else 5500
    ceiling = optimal_ceiling.get(subj_id, default_ceiling)

    formant = snd.to_formant_burg(
        time_step=time_step,
        max_number_of_formants=4,
        window_length=0.025,
        pre_emphasis_from=50,
        maximum_formant=ceiling
    )

    times = np.array([formant.get_time_from_frame_number(i) for i in range(1, formant.get_number_of_frames() + 1)])
    f1 = np.array([formant.get_value_at_time(1, t) for t in times])
    f2 = np.array([formant.get_value_at_time(2, t) for t in times])

    return times, f1, f2

def extract_pitch(signal, srate, gender):
    """Extract pitch without masking for intensity."""
    snd = parselmouth.Sound(signal, srate)

    # Pitch params
    if gender.lower() == 'male':
        pitch_floor, pitch_ceiling = 50, 250
    else:
        pitch_floor, pitch_ceiling = 100, 400

    pitch_obj = snd.to_pitch(
        time_step=time_step,
        pitch_floor=pitch_floor,
        pitch_ceiling=pitch_ceiling
    )
    times = pitch_obj.xs()
    pitch_values = pitch_obj.selected_array['frequency']
    return times, pitch_values

def process_trials_with_onset(subj_dir, i, expt_type, gender, f1_data, f0_data, trial_usage):
    """Process trials with onset detection and usability check."""
    listWords, listConds = load_experiment_trials(subj_dir, i, expt_type)
    if listWords is None or listConds is None:
        return

    trial_usage[expt_type] = []

    for trial_idx, (word, cond) in enumerate(zip(listWords, listConds)):
        trial_file = os.path.join(subj_dir, f"trial_{i}_{trial_idx+1}.mat")
        if not os.path.exists(trial_file):
            trial_usage[expt_type].append(False)
            continue

        trial_data = loadmat(trial_file, squeeze_me=True, struct_as_record=False)['data']
        signal = trial_data.signalIn
        srate = trial_data.params.sRate

        # Detect onset
        onset_time = detect_onset(signal, srate, gender)
        desired_samples = int(max_samples * srate * time_step)
        onset_idx = int(onset_time * srate)
        if onset_idx + desired_samples > len(signal):
            print(f"Subject {subj_id}, Experiment {i} {expt_type}, Trial {trial_idx + 1}: Excluded - Onset too late.")
            trial_usage[expt_type].append(False)
            continue

        # Check for NaNs in the pitch values
        end_idx = onset_idx + desired_samples
        limited_signal = signal[onset_idx:end_idx]
        _, pitch_values = extract_pitch(limited_signal, srate, gender)
        zero_count = np.sum(pitch_values == 0)
        if zero_count > 0:
            zero_ratio = zero_count / len(pitch_values)
            print(f"Subject {subj_id}, Experiment {i} {expt_type}, Trial {trial_idx + 1}: Excluded - Zeros in pitch data ({zero_count}/{len(pitch_values)} = {zero_ratio:.2%}).")
            trial_usage[expt_type].append(False)
            continue

        # Mark trial as usable
        trial_usage[expt_type].append(True)

        # Extract data
        signal = signal[onset_idx:]
        if expt_type == 'F1':
            t, f1_vals, f2_vals = extract_formants(signal, srate, gender)
            if word not in f1_data:
                f1_data[word] = {}
            if cond not in f1_data[word]:
                f1_data[word][cond] = []
            f1_data[word][cond].append({'time': t, 'F1': f1_vals, 'F2': f2_vals})
        elif expt_type == 'F0':
            t, pitch_vals = extract_pitch(signal, srate, gender)
            if word not in f0_data:
                f0_data[word] = {}
            if cond not in f0_data[word]:
                f0_data[word][cond] = []
            f0_data[word][cond].append({'time': t, 'pitch': pitch_vals})


def load_experiment_data(subj_dir):
    expt_path = os.path.join(subj_dir, 'expt.mat')
    expt_data = loadmat(expt_path, squeeze_me=True, struct_as_record=False)['expt']
    gender = expt_data.gender
    exptOrder = expt_data.exptOrder
    return gender, exptOrder

def load_experiment_trials(subj_dir, i, expt_type):
    expt_file = os.path.join(subj_dir, f"expt_{i}_{expt_type}.mat")
    if not os.path.exists(expt_file):
        return None, None
    curr_expt = loadmat(expt_file, squeeze_me=True, struct_as_record=False)['currExpt']
    listWords = curr_expt.listWords
    listConds = curr_expt.listConds
    if isinstance(listWords, str):
        listWords = [listWords]
    if isinstance(listConds, str):
        listConds = [listConds]
    return listWords, listConds

def process_trials(subj_dir, i, expt_type, gender, f1_data, f0_data):
    listWords, listConds = load_experiment_trials(subj_dir, i, expt_type)
    if listWords is None or listConds is None:
        return

    for trial_idx, (word, cond) in enumerate(zip(listWords, listConds)):
        trial_file = os.path.join(subj_dir, f"trial_{i}_{trial_idx+1}.mat")
        if not os.path.exists(trial_file):
            continue
        trial_data = loadmat(trial_file, squeeze_me=True, struct_as_record=False)['data']
        signal = trial_data.signalIn
        srate = trial_data.params.sRate

        if expt_type == 'F1':
            t, f1_vals, f2_vals = extract_formants(signal, srate, gender)
            if t is None:
                continue
            if word not in f1_data:
                f1_data[word] = {}
            if cond not in f1_data[word]:
                f1_data[word][cond] = []
            f1_data[word][cond].append({
                'time': t,
                'F1': f1_vals,
                'F2': f2_vals
            })

        elif expt_type == 'F0':
            t, pitch_vals = extract_pitch(signal, srate, gender)
            if t is None:
                continue
            if word not in f0_data:
                f0_data[word] = {}
            if cond not in f0_data[word]:
                f0_data[word][cond] = []
            f0_data[word][cond].append({
                'time': t,
                'pitch': pitch_vals
            })

def compute_stats_f1(f1_data, max_samples):
    f1_stats = {}
    for word, cond_dict in f1_data.items():
        f1_stats[word] = {}
        for cond, trials in cond_dict.items():
            F1_list, F2_list = [], []
            for tr in trials:
                F1_trial = tr['F1']
                F2_trial = tr['F2']

                # Pad or truncate F1
                F1_padded = np.full(max_samples, np.nan)
                F1_len = min(len(F1_trial), max_samples)
                F1_padded[:F1_len] = F1_trial[:F1_len]

                # Pad or truncate F2
                F2_padded = np.full(max_samples, np.nan)
                F2_len = min(len(F2_trial), max_samples)
                F2_padded[:F2_len] = F2_trial[:F2_len]

                F1_list.append(F1_padded)
                F2_list.append(F2_padded)

            if len(F1_list) > 0:
                F1_array = np.vstack(F1_list)
                F2_array = np.vstack(F2_list)
                f1_stats[word][cond] = {
                    'F1_mean': np.nanmean(F1_array, axis=0),
                    'F1_std': np.nanstd(F1_array, axis=0),
                    'F2_mean': np.nanmean(F2_array, axis=0),
                    'F2_std': np.nanstd(F2_array, axis=0)
                }
    return f1_stats

def compute_stats_f0(f0_data, max_samples):
    f0_stats = {}
    for word, cond_dict in f0_data.items():
        f0_stats[word] = {}
        for cond, trials in cond_dict.items():
            pitch_list = []
            for tr in trials:
                pitch_trial = tr['pitch']

                # Pad or truncate pitch
                pitch_padded = np.full(max_samples, np.nan)
                p_len = min(len(pitch_trial), max_samples)
                pitch_padded[:p_len] = pitch_trial[:p_len]

                pitch_list.append(pitch_padded)

            if len(pitch_list) > 0:
                pitch_array = np.vstack(pitch_list)
                f0_stats[word][cond] = {
                    'pitch_mean': np.nanmean(pitch_array, axis=0),
                    'pitch_std': np.nanstd(pitch_array, axis=0)
                }
    return f0_stats

def compute_diff_f1(f1_stats):
    f1_diff = {}
    for word, cond_dict in f1_stats.items():
        f1_diff[word] = {}
        if 'noShift' in cond_dict:
            noShift_f1_mean = cond_dict['noShift']['F1_mean']
            noShift_f1_std  = cond_dict['noShift']['F1_std']
            noShift_f2_mean = cond_dict['noShift']['F2_mean']
            noShift_f2_std  = cond_dict['noShift']['F2_std']

            for cond in ['shiftUp', 'shiftDown']:
                if cond in cond_dict:
                    f1_diff[word][cond] = {
                        'F1_mean_diff': cond_dict[cond]['F1_mean'] - noShift_f1_mean,
                        'F1_std_diff': np.sqrt(cond_dict[cond]['F1_std']**2 + noShift_f1_std**2),
                        'F2_mean_diff': cond_dict[cond]['F2_mean'] - noShift_f2_mean,
                        'F2_std_diff': np.sqrt(cond_dict[cond]['F2_std']**2 + noShift_f2_std**2)
                    }
    return f1_diff

def compute_diff_f0(f0_stats):
    f0_diff = {}
    for word, cond_dict in f0_stats.items():
        f0_diff[word] = {}
        if 'noShift' in cond_dict:
            noShift_pitch_mean = cond_dict['noShift']['pitch_mean']
            noShift_pitch_std  = cond_dict['noShift']['pitch_std']

            for cond in ['shiftUp', 'shiftDown']:
                if cond in cond_dict:
                    f0_diff[word][cond] = {
                        'pitch_mean_diff': cond_dict[cond]['pitch_mean'] - noShift_pitch_mean,
                        'pitch_std_diff': np.sqrt(cond_dict[cond]['pitch_std']**2 + noShift_pitch_std**2)
                    }
    return f0_diff

def save_results(subj_id, f1_data, f0_data, f1_stats, f0_stats, f1_diff, f0_diff):
    # Save data
    if len(f1_data) > 0:
        savemat(os.path.join(base_dir, f"{subj_id}_f1_data.mat"), {'f1_data': f1_data})
    if len(f0_data) > 0:
        savemat(os.path.join(base_dir, f"{subj_id}_f0_data.mat"), {'f0_data': f0_data})

    # Save stats
    if len(f1_stats) > 0:
        savemat(os.path.join(base_dir, f"{subj_id}_f1_stats.mat"), {'f1_stats': f1_stats})
    if len(f0_stats) > 0:
        savemat(os.path.join(base_dir, f"{subj_id}_f0_stats.mat"), {'f0_stats': f0_stats})

    # Save diffs
    if len(f1_diff) > 0:
        savemat(os.path.join(base_dir, f"{subj_id}_f1_diff.mat"), {'f1_diff': f1_diff})
    if len(f0_diff) > 0:
        savemat(os.path.join(base_dir, f"{subj_id}_f0_diff.mat"), {'f0_diff': f0_diff})

# ---------------- MAIN SCRIPT ----------------
for subj_id in sorted(subject_ids):
    subj_dir = os.path.join(base_dir, subj_id)
    gender, exptOrder = load_experiment_data(subj_dir)

    f1_data = {}
    f0_data = {}
    trial_usage = {}

    # Process each experiment in exptOrder
    for i, expt_type in enumerate(exptOrder, start=1):
        process_trials_with_onset(subj_dir, i, expt_type, gender, f1_data, f0_data, trial_usage)

        # Save trial usage information
        usage_file = os.path.join(subj_dir, f"expt_{i}_{expt_type}_data.mat")
        savemat(usage_file, {'trial_usage': trial_usage[expt_type]})

    # Compute stats
    f1_stats = compute_stats_f1(f1_data, max_samples)
    f0_stats = compute_stats_f0(f0_data, max_samples)

    # Compute differences
    f1_diff = compute_diff_f1(f1_stats)
    f0_diff = compute_diff_f0(f0_stats)

    # Save all results
    save_results(subj_id, f1_data, f0_data, f1_stats, f0_stats, f1_diff, f0_diff)
    print(f"Subject {subj_id} complete!")
