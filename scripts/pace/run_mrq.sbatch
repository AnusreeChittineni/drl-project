#!/bin/bash
# Slurm array job: one MR.Q run (env, seed) per array task, read from a job list.
#   sbatch --array=1-N%50 scripts/pace/run_mrq.sbatch jobs.txt
# Resumable: if a valid checkpoint exists it is loaded, so the same command can be resubmitted
# after a timeout or preemption (e.g. on the free 'embers' QOS).
#
# Fill in --account (e.g. gts-<PI username>) and pick a QOS. Check `pace-quota` for your accounts.
#SBATCH --job-name=mrq
#SBATCH --account=CHANGE_ME
#SBATCH --qos=inferno
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --gres=gpu:1
#SBATCH --time=12:00:00
#SBATCH --output=slurm_logs/%x_%A_%a.out

set -euo pipefail

JOB_LIST=${1:-jobs.txt}
ENV_PREFIX=${ENV_PREFIX:-$HOME/p-CHANGE_ME-0/envs/mrq}   # same path used in setup_env.sh
OUT_ROOT=${OUT_ROOT:-$HOME/scratch/mrq}                   # scratch: big + fast, but purged; copy evals out

read -r ENV SEED < <(sed -n "${SLURM_ARRAY_TASK_ID}p" "$JOB_LIST")
NAME="MRQ+${ENV}+${SEED}"
echo "Task ${SLURM_ARRAY_TASK_ID}: ${ENV} seed ${SEED} on $(hostname)"

module load anaconda3
source activate "$ENV_PREFIX" 2>/dev/null || conda activate "$ENV_PREFIX"

export MUJOCO_GL=egl          # headless rendering for Dmc-visual (try osmesa if egl fails)
export PYOPENGL_PLATFORM=egl
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK

mkdir -p "$OUT_ROOT"/{evals,logs,checkpoint}
CKPT="$OUT_ROOT/checkpoint/$NAME"

# save_experiment writes exp_var.npy first and the replay buffer last, so only treat the
# checkpoint as valid if buffer_var.npy exists and is newer than exp_var.npy.
RESUME=--no-load_experiment
if [[ -f "$CKPT/buffer_var.npy" && "$CKPT/buffer_var.npy" -nt "$CKPT/exp_var.npy" ]]; then
    RESUME=--load_experiment
    echo "Resuming from checkpoint $CKPT"
fi

cd "$SLURM_SUBMIT_DIR/MRQ"
python main.py \
    --env "$ENV" --seed "$SEED" --device cuda \
    --eval_folder "$OUT_ROOT/evals" \
    --log_folder "$OUT_ROOT/logs" \
    --save_folder "$OUT_ROOT/checkpoint" \
    --save_experiment --save_freq 100000 \
    $RESUME
