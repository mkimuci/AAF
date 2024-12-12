import os
import numpy as np
import scipy.io as sio
import matplotlib.pyplot as plt
from scipy.io.matlab import mat_struct


def mat_struct_to_dict(mat_obj):
    if isinstance(mat_obj, mat_struct):
        d = {}
        for f in mat_obj._fieldnames:
            d[f] = mat_struct_to_dict(mat_obj.__dict__[f])
        return d
    elif isinstance(mat_obj, np.ndarray):
        if mat_obj.dtype.names is not None:
            # It's a structured array
            d = {}
            for n in mat_obj.dtype.names:
                d[n] = mat_struct_to_dict(mat_obj[n])
            return d
        else:
            # It's a normal numpy array.
            if mat_obj.size == 1:
                return mat_struct_to_dict(mat_obj[0])
            else:
                return [mat_struct_to_dict(elem) for elem in mat_obj]
    else:
        return mat_obj

def plot_mean_data(ax, time, stats_dict, word, measure_key, title, xlim, ylim, color_map, x_label="Time (s)", y_label="Frequency (Hz)"):
    """Plot mean data (F1, F2, or Pitch) for a given word with different conditions."""
    if word in stats_dict:
        if 'noShift' in stats_dict[word]:
            ax.plot(time, stats_dict[word]['noShift'][measure_key], color=color_map['noShift'], label='noShift')
        if 'shiftUp' in stats_dict[word]:
            ax.plot(time, stats_dict[word]['shiftUp'][measure_key], color=color_map['shiftUp'], label='shiftUp')
        if 'shiftDown' in stats_dict[word]:
            ax.plot(time, stats_dict[word]['shiftDown'][measure_key], color=color_map['shiftDown'], label='shiftDown')

    ax.set_title(title)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_xlabel(x_label)
    ax.set_ylabel(y_label)
    ax.legend()

def plot_all_trials(ax, time, data_dict, stats_dict, word, measure_key, title, xlim, ylim, color_map, max_samples, x_label="Time (s)", y_label="Frequency (Hz)"):
    # Map raw data measure keys to stats measure keys
    stats_key_map = {
        'F1': 'F1_mean',
        'F2': 'F2_mean',
        'pitch': 'pitch_mean'
    }

    if word in data_dict:
        for cond, trial_list in data_dict[word].items():
            c = color_map.get(cond, 'gray')
            for tr in trial_list:
                if len(tr[measure_key]) >= max_samples:
                    ax.plot(time, tr[measure_key][:max_samples], color=c, linewidth=0.5, alpha=0.3)

    # Overplot mean data if available
    if word in stats_dict and word in data_dict:
        stats_key = stats_key_map[measure_key]
        if 'noShift' in stats_dict[word] and stats_key in stats_dict[word]['noShift']:
            ax.plot(time, stats_dict[word]['noShift'][stats_key], color=color_map['noShift'], label='noShift (mean)')
        if 'shiftUp' in stats_dict[word] and stats_key in stats_dict[word]['shiftUp']:
            ax.plot(time, stats_dict[word]['shiftUp'][stats_key], color=color_map['shiftUp'], label='shiftUp (mean)')
        if 'shiftDown' in stats_dict[word] and stats_key in stats_dict[word]['shiftDown']:
            ax.plot(time, stats_dict[word]['shiftDown'][stats_key], color=color_map['shiftDown'], label='shiftDown (mean)')

    ax.set_title(title)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_xlabel(x_label)
    ax.set_ylabel(y_label)
    ax.legend()

def plot_diff_data(ax, time, diff_dict, word, measure_key, title, xlim, ylim, color_map):
    # Derive the std key from the mean key
    std_key = measure_key.replace('mean_diff', 'std_diff')

    # Draw a horizontal line at y=0
    ax.axhline(y=0, color='k', linestyle='--', linewidth=1, alpha=0.7)
    
    if word in diff_dict:
        for cond in ['shiftUp', 'shiftDown']:
            if cond in diff_dict[word] and measure_key in diff_dict[word][cond]:
                mean_diff = np.array(diff_dict[word][cond][measure_key])
                c = color_map[cond]

                # Plot the mean diff line
                ax.plot(time, mean_diff, color=c, label=f'{cond} - noShift')

                # If std data is available, plot shaded area
                if std_key in diff_dict[word][cond]:
                    std_diff = np.array(diff_dict[word][cond][std_key])
                    ax.fill_between(time, mean_diff - std_diff, mean_diff + std_diff, 
                                    color=c, alpha=0.2)

    ax.set_title(title)
    ax.set_xlim(xlim)
    ax.set_ylim(ylim)
    ax.set_xlabel("Time (s)")
    ax.set_ylabel("Frequency Diff (Hz)")
    ax.legend()


base_dir = "/Users/minkyu/experiments/F0vsF1"
subject_ids = [d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d))]
subject_ids = ["101", "103", "104", "105", "108", "109", "111", "112", "117", "118", "122", "123"]
subject_ids = ["110"]
time_step = 0.002
max_samples = 150
time = np.arange(max_samples) * time_step

# Define y-limits
t_xlim = (0, 0.300)
f1_ylim = (0, 1200)
f2_ylim = (1200, 2400)
pitch_ylim = (75, 375)

# Define condition colors
condition_colors = {
    'noShift': 'k',
    'shiftUp': '#77AC30',
    'shiftDown': '#D95319'
}

pitch_condition_colors = {
    'noShift': 'k',
    'shiftUp': '#A2142F',
    'shiftDown': '#0072BD'
}

for subject_id in sorted(subject_ids):
    f1_data_path = os.path.join(base_dir, f"{subject_id}_f1_data.mat")
    f0_data_path = os.path.join(base_dir, f"{subject_id}_f0_data.mat")
    f1_stats_path = os.path.join(base_dir, f"{subject_id}_f1_stats.mat")
    f0_stats_path = os.path.join(base_dir, f"{subject_id}_f0_stats.mat")
    f1_diff_path = os.path.join(base_dir, f"{subject_id}_f1_diff.mat")
    f0_diff_path = os.path.join(base_dir, f"{subject_id}_f0_diff.mat")

    f1_data = {}
    f0_data = {}
    f1_stats = {}
    f0_stats = {}
    f1_diff = {}
    f0_diff = {}

    if os.path.exists(f1_data_path):
        f1_data_raw = sio.loadmat(f1_data_path, squeeze_me=True, struct_as_record=False)['f1_data']
        f1_data = mat_struct_to_dict(f1_data_raw)

    if os.path.exists(f0_data_path):
        f0_data_raw = sio.loadmat(f0_data_path, squeeze_me=True, struct_as_record=False)['f0_data']
        f0_data = mat_struct_to_dict(f0_data_raw)
        
    if os.path.exists(f1_stats_path):
        f1_stats_raw = sio.loadmat(f1_stats_path, squeeze_me=True, struct_as_record=False)['f1_stats']
        f1_stats = mat_struct_to_dict(f1_stats_raw)

    if os.path.exists(f0_stats_path):
        f0_stats_raw = sio.loadmat(f0_stats_path, squeeze_me=True, struct_as_record=False)['f0_stats']
        f0_stats = mat_struct_to_dict(f0_stats_raw)

    if os.path.exists(f1_diff_path):
        f1_diff_raw = sio.loadmat(f1_diff_path, squeeze_me=True, struct_as_record=False)['f1_diff']
        f1_diff = mat_struct_to_dict(f1_diff_raw)

    if os.path.exists(f0_diff_path):
        f0_diff_raw = sio.loadmat(f0_diff_path, squeeze_me=True, struct_as_record=False)['f0_diff']
        f0_diff = mat_struct_to_dict(f0_diff_raw)

    all_words_f1 = sorted(f1_stats.keys()) if f1_stats else []
    all_words_f0 = sorted(f0_stats.keys()) if f0_stats else []
    all_words = sorted(set(all_words_f1).union(all_words_f0))

    # Plot original data
    fig, axs = plt.subplots(len(all_words), 3, figsize=(15, 5*len(all_words)))
    if len(all_words) == 1:
        axs = np.array([axs])  # ensure 2D if one word

    for row, word in enumerate(all_words):
        # F1 mean
        plot_mean_data(axs[row, 0], time, f1_stats, word, 'F1_mean', f"{word} - F1", t_xlim, f1_ylim, condition_colors)
        # F2 mean
        plot_mean_data(axs[row, 1], time, f1_stats, word, 'F2_mean', f"{word} - F2", t_xlim, f2_ylim, condition_colors)
        # Pitch mean
        plot_mean_data(axs[row, 2], time, f0_stats, word, 'pitch_mean', f"{word} - Pitch", t_xlim, pitch_ylim, pitch_condition_colors)

    plt.tight_layout()
    plt.savefig(os.path.join(base_dir, f"plot_avg_{subject_id}.png"))
    plt.close(fig)


    # Plot difference data with std
    fig_diff, axs_diff = plt.subplots(len(all_words), 3, figsize=(15, 5*len(all_words)))
    if len(all_words) == 1:
        axs_diff = np.array([axs_diff])

    for row, word in enumerate(all_words):
        # F1 diff
        plot_diff_data(axs_diff[row, 0], time, f1_diff, word, 'F1_mean_diff', f"{word} - F1 diff", t_xlim, (-200, 200), condition_colors)
        # F2 diff
        plot_diff_data(axs_diff[row, 1], time, f1_diff, word, 'F2_mean_diff', f"{word} - F2 diff", t_xlim, (-200, 200), condition_colors)
        # Pitch diff
        plot_diff_data(axs_diff[row, 2], time, f0_diff, word, 'pitch_mean_diff', f"{word} - Pitch diff", t_xlim, (-50, 50), pitch_condition_colors)

    plt.tight_layout()
    plt.savefig(os.path.join(base_dir, f"plot_diff_{subject_id}.png"))
    plt.close(fig_diff)


    # Plot all trials
    fig_all, axs_all = plt.subplots(len(all_words), 3, figsize=(15, 5*len(all_words)))
    if len(all_words) == 1:
        axs_all = np.array([axs_all])

    for row, word in enumerate(all_words):
        # F1 All
        plot_all_trials(axs_all[row, 0], time, f1_data, f1_stats, word, 'F1', f"{word} - F1 All Trials", t_xlim, f1_ylim, condition_colors, max_samples)
        # F2 All
        plot_all_trials(axs_all[row, 1], time, f1_data, f1_stats, word, 'F2', f"{word} - F2 All Trials", t_xlim, f2_ylim, condition_colors, max_samples)
        # Pitch All
        plot_all_trials(axs_all[row, 2], time, f0_data, f0_stats, word, 'pitch', f"{word} - Pitch All Trials", t_xlim, pitch_ylim, pitch_condition_colors, max_samples)

    plt.tight_layout()
    plt.savefig(os.path.join(base_dir, f"plot_all_{subject_id}.png"))
    plt.close(fig_all)
    
    print(f"Plot: Subject {subject_id} complete!")