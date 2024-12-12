import os
import glob
import numpy as np
import pandas as pd
import parselmouth
from parselmouth.praat import call
from scipy.io import loadmat

base_dir = "/Users/minkyu/experiments/F0vsF1"
subject_ids = [d for d in os.listdir(base_dir) if os.path.isdir(os.path.join(base_dir, d))]
subject_ids = ["101", "103", "104", "105", "108", "109", "111", "112", "117", "118", "122", "123"]
subject_ids = ["113", "116", "121"]

ceilings = list(range(4000, 6201, 200))  # [4800, 5000, 5200, 5400, 5600, 5800, 6000]
intensity_threshold = 60.0

rows = []
optimal_rows = []

for subject_id in sorted(subject_ids):
    print(f"Analyzing {subject_id}...")
    subject_path = os.path.join(base_dir, subject_id)
    mat_files = sorted(glob.glob(os.path.join(subject_path, "trial_*_*.mat")))

    # If no mat files found, skip this subject
    if not mat_files:
        continue

    # For each ceiling, we will accumulate formant deviations across trials
    ceiling_deviations = {}
    for ceiling in ceilings:
        f1_devs = []
        f2_devs = []
        f3_devs = []
        f4_devs = []

        for mat_file in mat_files[:60]:
            mat_data = loadmat(mat_file, squeeze_me=True, struct_as_record=False)
            data = mat_data['data']

            # Extract signal and sampling rate
            signal = data.signalIn
            srate = data.params.sRate

            # Create a Sound object from the signal
            snd = parselmouth.Sound(signal, sampling_frequency=srate)

            # Compute intensity
            intensity_obj = snd.to_intensity(time_step=0.025)
            num_frames = call(intensity_obj, "Get number of frames")
            times = [call(intensity_obj, "Get time from frame number", i+1) for i in range(num_frames)]
            intensities = np.array([call(intensity_obj, "Get value in frame", i+1) for i in range(num_frames)])
            
            # Track formants
            formant = snd.to_formant_burg(
                time_step=0.025,
                max_number_of_formants=4,
                window_length=0.025,
                pre_emphasis_from=50,
                maximum_formant=ceiling
            )

            # Extract formants at the same times as intensity frames
            f1_vals = []
            f2_vals = []
            f3_vals = []
            f4_vals = []

            for t_idx, t in enumerate(times):
                # Only consider frames above intensity threshold
                if intensities[t_idx] > intensity_threshold:
                    # Retrieve formant frequency values
                    # Note: Formant numbering starts at 1 in Praat
                    f1 = call(formant, "Get value at time", 1, t, 'Hertz', 'Linear')
                    f2 = call(formant, "Get value at time", 2, t, 'Hertz', 'Linear')
                    f3 = call(formant, "Get value at time", 3, t, 'Hertz', 'Linear')
                    f4 = call(formant, "Get value at time", 4, t, 'Hertz', 'Linear')

                    # Sometimes Praat returns undefined values (NaN) if no formant is found
                    # Filter them out
                    if not np.isnan(f1):
                        f1_vals.append(f1)
                    if not np.isnan(f2):
                        f2_vals.append(f2)
                    if not np.isnan(f3):
                        f3_vals.append(f3)
                    if not np.isnan(f4):
                        f4_vals.append(f4)

            # Compute deviations (standard deviations) for each formant if we have data
            if len(f1_vals) > 1:
                f1_devs.append(np.std(f1_vals)/np.mean(f1_vals))
            if len(f2_vals) > 1:
                f2_devs.append(np.std(f2_vals)/np.mean(f2_vals))
            if len(f3_vals) > 1:
                f3_devs.append(np.std(f3_vals)/np.mean(f3_vals))
            if len(f4_vals) > 1:
                f4_devs.append(np.std(f4_vals)/np.mean(f4_vals))

        # Average deviations across all trials for this ceiling
        # If no values, set to NaN or 0
        mean_f1_dev = np.mean(f1_devs) if len(f1_devs) > 0 else np.nan
        mean_f2_dev = np.mean(f2_devs) if len(f2_devs) > 0 else np.nan
        mean_f3_dev = np.mean(f3_devs) if len(f3_devs) > 0 else np.nan
        mean_f4_dev = np.mean(f4_devs) if len(f4_devs) > 0 else np.nan
        
        sum_dev = np.nansum([mean_f1_dev, mean_f2_dev, mean_f3_dev, mean_f4_dev])
        ceiling_deviations[ceiling] = (mean_f1_dev, mean_f2_dev, mean_f3_dev, mean_f4_dev, sum_dev)

        print(f"    Ceiling {ceiling} Hz - Mean Deviations: F1={mean_f1_dev:.2f}, F2={mean_f2_dev:.2f}, F3={mean_f3_dev:.2f}, F4={mean_f4_dev:.2f}, Sum={sum_dev:.2f}")

        # Store row for CSV
        rows.append({
            "Subject ID": subject_id,
            "Ceiling": ceiling,
            "F1 deviation": mean_f1_dev,
            "F2 deviation": mean_f2_dev,
            "F3 deviation": mean_f3_dev,
            "F4 deviation": mean_f4_dev,
            "Sum of deviation": sum_dev
        })


    # Determine optimal ceiling for this subject based on minimal sum of deviations
    valid_ceilings = [(c, vals[4]) for c, vals in ceiling_deviations.items() if not np.isnan(vals[4])]
    if valid_ceilings:
        optimal_ceiling = min(valid_ceilings, key=lambda x: x[1])[0]
        print(f"  Optimal Ceiling for {subject_id}: {optimal_ceiling} Hz\n")
    else:
        optimal_ceiling = np.nan
        print(f"  [Warning] No valid ceilings found for {subject_id}. Optimal Ceiling set to NaN.\n")

    optimal_rows.append({
        "Subject ID": subject_id,
        "Optimal Ceiling": optimal_ceiling
    })

# Save the CSV files
output_deviation_csv = os.path.join(base_dir, "formant_deviations.csv")
output_optimal_csv = os.path.join(base_dir, "optimal_ceilings.csv")

print(f"Saving formant deviations to {output_deviation_csv}")
df = pd.DataFrame(rows)
df.to_csv(output_deviation_csv, index=False)

print(f"Saving optimal ceilings to {output_optimal_csv}")
opt_df = pd.DataFrame(optimal_rows)
opt_df.to_csv(output_optimal_csv, index=False)