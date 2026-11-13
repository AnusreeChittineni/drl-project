#!/bin/bash
# One-time environment setup on PACE (run on a login node, or better an interactive GPU node).
#   bash scripts/pace/setup_env.sh
# Put the conda env in project storage, not $HOME (small quota).
set -euo pipefail

ENV_PREFIX=${ENV_PREFIX:-$HOME/p-CHANGE_ME-0/envs/mrq}   # <-- set to your project storage path

module load anaconda3
conda create -y -p "$ENV_PREFIX" python=3.11
source activate "$ENV_PREFIX" 2>/dev/null || conda activate "$ENV_PREFIX"

# CUDA build of torch (the bundled CUDA runtime works with the cluster drivers; no module needed).
pip install "torch>=2.3.0" --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt "gymnasium[mujoco]"

python - <<'EOF'
import torch, gymnasium, dm_control, ale_py, mujoco
print('torch', torch.__version__, 'cuda available:', torch.cuda.is_available())
print('gymnasium', gymnasium.__version__, '| mujoco', mujoco.__version__, '| ale_py', ale_py.__version__)
EOF
