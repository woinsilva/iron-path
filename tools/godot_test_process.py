"""Bounded execution of a test process and its Windows child process tree."""
import subprocess,os

def run_test(command, *, cwd, timeout=180):
 process=subprocess.Popen(command,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8')
 try:
  output,_=process.communicate(timeout=timeout)
  return subprocess.CompletedProcess(command,process.returncode,output)
 except subprocess.TimeoutExpired:
  if process.poll() is None:
   if os.name=='nt': subprocess.run(['taskkill','/PID',str(process.pid),'/T','/F'],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,check=False)
   else: process.kill()
  output,_=process.communicate(timeout=10)
  return subprocess.CompletedProcess(command,-1,output+'\nTEST_PROCESS_TIMEOUT\n')

if __name__=='__main__':
 import argparse,sys
 from pathlib import Path
 parser=argparse.ArgumentParser()
 parser.add_argument('--timeout',type=float,default=180)
 parser.add_argument('command',nargs=argparse.REMAINDER)
 args=parser.parse_args()
 command=args.command[1:] if args.command and args.command[0]=='--' else args.command
 if not command: parser.error('A test command is required')
 result=run_test(command,cwd=Path.cwd(),timeout=args.timeout)
 sys.stdout.write(result.stdout)
 raise SystemExit(result.returncode)
