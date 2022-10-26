import os
import subprocess

def pull_source_code(repo_url: str, src_path: str):
  subprocess.run(
    '$(mkdir {} || true) && cd {} && git clone {}'.format(src_path, src_path, repo_url),
    shell=True,
  )
