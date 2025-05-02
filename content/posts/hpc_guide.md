+++
title = "Accessing GPUs on an HPC Cluster (Paramganga)"
description = "A guide to accessing GPUs, using SLURM, and running jobs on Paramganga."
tags = ["HPC", "SLURM", "Paramganga"]
+++

To start gpu session from terminal right away

`srun -p gpu --ntasks=1 --cpus-per-gpu=20 --gres=gpu:2 --time=1-00:00:00 -n 1 --pty bash -i`

# HPC and Slurm

```bash
srun --nodes=1 --gres=gpu:1 --partition=gpu --ntasks-per-node=16 --time=1-00:00:00 --pty bash -i
```

use tmux sessions and remember login node

allocate gpu in a tmux session

then in other tmux windows ssh into that gpu to get multiple bash instances open

`ssh gpu020`

### Transfer Files

use `rsync`  instead of `scp` (faster and more efficient)

`rsync -avz ~/Downloads/hwd_df.csv jarvis:/home/amz_ml_2024/`

`rsync -avz bet:/scratch/be205_29/images_test jarvis:/home/imgs_tst`

`rsync -avz bet:/home/be205_29/workplace/amz_ml_2024/rprt Downloads`

`scp` to copy files from local to hpc or hpc to local

`scp –r /home/testuser testuser@<local IP>:/dir/dir/file`to copy the files to your system

or use `scp ssh_name:/path/to/remote/file /path/to/local/file` instead in your terminal (given that ssh key is set, if not use `remote_user@remote_host` and enter pass)

### access using terminal

1. run `ssh {username}@paramganga.iitr.ac.in` . add port `-p 4422` if not on the IITR network or use vscode. optionally add `-o UserKnownHostsFile=/dev/null`
2. enter password
3. start tmux session `tmux new -s my_session` or simply `tmux`
4. get gpu node alloted by `srun --nodes=1 --gres=gpu:2 --partition=gpu --ntasks-per-node=16 --time=1-00:00:00 --pty bash -i`  you may use `--exclusive` in the tmux session
5. exit tmux session and remember the login node
6. after the process is run go to that login node and attach to that tmux session. use `squeue` to list the running jobs
7. enter `exit` to logout
8. make sure to remove refs from .ssh/known_hosts using `ssh-keygen -R [paramganga.iitr.ac.in](http://paramganga.iitr.ac.in)` or by specifying `-o UserKnownHostsFile=/dev/null` or modify in config file

### GPU

Old NVIDIA drivers of CUDA toolkit 11.6

install pytorch and cuda relevant libraries for cu118 version (backward compatible for 116)

pin that version in conda - don’t tamper your conda env again and again

### Shell Script runs

run.sh

```bash
#!/bin/bash
#SBATCH --job-name=j1
#SBATCH --nodes=1
#SBATCH --partition=gpu
#SBATCH --gres=gpu:2
#SBATCH --ntasks-per-node=4
#SBATCH --cpus-per-task=8
#SBATCH --time=10:00:00
#SBATCH --mail-type=BEGIN
#SBATCH --mail-user=
#SBATCH --output=%x-%j.out

# sleep 100
# papermill notebook.ipynb notebook_o.ipynb
# CUDA_VISIBLE_DEVICES=0,1 python main.py
```

`sbatch run.sh`

### module

`module avail`to list all available pkgs, be it on spack

### slurm and other account mgmt

`passwd` to change the password

`sinfo -a`

`squeue -u $USER --start` list the user’s jobs with approx time after which it’d start

`squeue -p gpu` view all gpu jobs

`sacct` your job status / history

`scancel` to terminate queued or running jobs

https://curc.readthedocs.io/en/latest/running-jobs/slurm-commands.html

### TMUX

1. On the command prompt, type `tmux`, (`tmux new -s my_session` for a named session)
2. Run the desired program.
3. Use the key sequence `Ctrl-b + d`to detach from the session.
4. use `tmux ls` to list all sessions
5. Reattach to the Tmux session by typing `tmux attach-session -t 0`.
6. `tmux kill-session -t 0` to kill that session


### Passwordless Login

follow this https://wynton.ucsf.edu/hpc/howto/log-in-without-pwd.html
use passwd to change password

### 1st time setup hpc

add the following script in `/home/aakash_ks.iitr/.bashrc`

```bash
module load spack
source /home/apps/spack/share/spack/setup-env.sh
spack load tmux
```

follow https://docs.excl.ornl.gov/quick-start-guides/conda-and-spack-installation to setup miniconda in /home/$USER/miniconda3

[ssh using rsa id (passwordless)](https://wynton.ucsf.edu/hpc/howto/log-in-without-pwd.html)

### 1st time setup local

add this in your .bashrc `ssh-keygen -f "/c/Users/msing/.ssh/known_hosts" -R "[paramganga.iitr.ac.in](http://paramganga.iitr.ac.in/)" &> /dev/null`

`ssh-keygen -R '[[paramganga.iitr.ac.in](http://paramganga.iitr.ac.in/)]:4422'`

```bash
Host paramganga.iitr.ac.in
  HostName paramganga.iitr.ac.in
  User <your_username>
  IdentityFile ~/.ssh/mac_to_pgiitr
  UserKnownHostsFile /dev/null
```

Add Port 4422 

“””if showing error go to known_hosts file in .ssh and remove paramganga references or directly run the script “””

generate ssh key and copy the public key on pc

make sure to use comment to hide name of your laptop

`ssh-keygen -m PEM -f ~/.ssh/mykey -C "local@default"`

and without passphrase

for .pem files sometimes this need to be done → `chmod 400 file.pem`

### More References

1. https://docs.excl.ornl.gov/quick-start-guides/conda-and-spack-installation
2. https://uvadlc-notebooks.readthedocs.io/en/latest/tutorial_notebooks/tutorial1/Lisa_Cluster.html
3. https://rc-docs.northeastern.edu/en/latest/software/packagemanagers/spack.html
4. https://hpc.nmsu.edu/discovery/slurm/gpu-jobs/
5. [Dask - run slurm jobs within python only](https://docs.dask.org/en/stable/deploying-hpc.html) , [submitit (alternative, perhaps better with gpus)](https://github.com/facebookincubator/submitit)
6. [mount remote file system locally](https://stackoverflow.com/questions/3407287/how-do-you-edit-files-over-ssh)
7. [iterm2 tmux support](https://iterm2.com/documentation-tmux-integration.html)
8. https://sites.google.com/nyu.edu/nyu-hpc/training-support/tutorials/slurm-tutorial

### FairShare / Priority

Regular use will decrease your fairshare, increasing wait time for next allocation. Hence, use the gpus responsibly

1. https://curc.readthedocs.io/en/latest/running-jobs/slurm-commands.html
2. https://hpcf.umbc.edu/ada/slurm/priority/
3. https://docs.rc.fas.harvard.edu/kb/fairshare/
4. https://docs.crc.ku.edu/how-to/fairshare-priority/
