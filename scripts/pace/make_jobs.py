# Writes one "env seed" line per run, used by run_mrq.sbatch as a Slurm array.
#   python scripts/pace/make_jobs.py --benchmarks gym dmc --seeds 10 --out jobs_gym_dmc.txt
import argparse
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'MRQ'))
import utils  # noqa: E402

# results/atari_results.txt has 57 games, but utils.atari lists only 55.
ATARI_MISSING = ['Atari-Defender-v5', 'Atari-Surround-v5']

BENCHMARKS = {
    'gym': utils.gym,
    'dmc': utils.dmc,
    'dmc-visual': utils.dmc_visual,
    'atari': sorted(utils.atari + ATARI_MISSING),
}

parser = argparse.ArgumentParser()
parser.add_argument('--benchmarks', nargs='+', default=list(BENCHMARKS), choices=list(BENCHMARKS))
parser.add_argument('--seeds', type=int, default=10)
parser.add_argument('--envs', nargs='*', default=None, help='Optional explicit env subset (overrides benchmarks).')
parser.add_argument('--out', default='jobs.txt')
args = parser.parse_args()

envs = args.envs if args.envs else [e for b in args.benchmarks for e in BENCHMARKS[b]]
lines = [f'{env} {seed}' for env in envs for seed in range(args.seeds)]

with open(args.out, 'w', newline='\n') as f:
    f.write('\n'.join(lines) + '\n')

print(f'Wrote {len(lines)} runs ({len(envs)} envs x {args.seeds} seeds) to {args.out}')
print(f'Submit with: sbatch --array=1-{len(lines)}%50 scripts/pace/run_mrq.sbatch {args.out}')
