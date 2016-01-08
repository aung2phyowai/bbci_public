#!/usr/bin/env python
""" Initialize all data for an experiment and tag the corresponding code base"""

import argparse
import datetime
import re
import shutil
import subprocess
import tempfile

def print_and_call(cmd):
    print cmd
    return subprocess.call(cmd, shell=True)

def sed_inplace(filename, pattern_compiled, replacement):
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as tmp_file:
        with open(filename) as src_file:
            for line in src_file:
                tmp_file.write(pattern_compiled.sub(replacement, line))
    shutil.copystat(filename, tmp_file.name)
    shutil.move(tmp_file.name, filename)

def check_clean_working_dir():
    """checks whether there are any uncommitted changes"""
    status_cmd = 'git status -s'
    changes = subprocess.check_output(status_cmd, shell=True)
    return not bool(changes.strip())

def checkout_branch(branch_name):
    cmd_checkout = 'git checkout ' + branch_name
    ret_code = print_and_call(cmd_checkout)
    if ret_code != 0:
        #try to create the branch
        cmd_checkout = 'git checkout -b ' + branch_name
        ret_code = print_and_call(cmd_checkout)
        if ret_code != 0:
            print "could not checkout experiments branch, exiting"
            exit(ret_code)

def override_branch_with_commit(commit_id, branch_name, commit_changes=False):
    #we want to preserver the parent commit on the target branch
    # but ignore all of it contents
    #Since git only has a "ours" and not a "theirs" merge-strategy, we use a temp branch
    print_and_call('git branch %s' % branch_name) #to assure it exists, command itself might fail
    tmp_branch_name = 'tmp_%d' % datetime.datetime.now().toordinal()
    checkout_branch(tmp_branch_name)
    ret_code = print_and_call('git reset --hard %s' % commit_id)
    if ret_code != 0:
        print "resetting failed, please delete temporary branch %s" % tmp_branch_name
        exit(ret_code)
    if commit_changes:
        commit_all_changes("Auto-commit of changed and untracked files")
    #now we merge the target branch pro forma, so that we have a fast-forward later
    commit_message = "virtual merge of branch %s, discarding all its changes. Automatically created from script to connect the histories" % branch_name
    merge_cmd = 'git merge -s ours -m "%s" %s ' % (commit_message, branch_name)
    ret_code = print_and_call(merge_cmd)
    if ret_code != 0:
        print "pro forma (discarding) merge with branch %s failed" % branch_name
        exit(ret_code)
    checkout_branch(branch_name)
    merge_cmd = 'git merge --ff-only %s' % tmp_branch_name
    ret_code = print_and_call(merge_cmd)
    if ret_code != 0:
        print "could not fast-forward changes into target branch %s" % tmp_branch_name
        exit(ret_code)
    print_and_call('git branch -d %s' % tmp_branch_name)

def commit_all_changes(commit_msg, include_untracked=True):
    if not check_clean_working_dir():
        if include_untracked:
            cmd = "git add $(git ls-files -o -m  --exclude-standard)"
            ret_code = print_and_call(cmd)
            if ret_code != 0:
                print "could not add files to index"
                exit(ret_code)
        ret_code = print_and_call('git commit -a -m "%s"' % commit_msg)
        if ret_code != 0:
            print "auto-commit failed"
            exit(ret_code)

subject_config_file = "config/subject_config.m"
vpcode_pattern = re.compile(r'EXPERIMENT_CONFIG.VPcode = \'(.*)\'')
vpdate_pattern = re.compile(r'EXPERIMENT_CONFIG.date = (.*);')
            
def configure_vp_code(vp_code, date_value="datestr(now, 'yy-mm-dd')"):
    vpcode_replacement = "EXPERIMENT_CONFIG.VPcode = '%s'" % vp_code
    sed_inplace(subject_config_file, vpcode_pattern, vpcode_replacement)
    date_replacement = "EXPERIMENT_CONFIG.date = %s;" % date_value
    sed_inplace(subject_config_file, vpdate_pattern, date_replacement)

def get_vp_code():
    vpcode = None
    vpdate = None
    with open(subject_config_file) as src_file:
        for line in src_file:
            m_vpcode = vpcode_pattern.search(line)
            if m_vpcode:
                vpcode = m_vpcode.group(1)
            m_vpdate = vpdate_pattern.search(line)
            if m_vpdate:
                vpdate = m_vpdate.group(1)
    return (vpcode, vpdate)

def init_experiment(vp_code, date_str, tag_name, commit, branch):
    old_head = subprocess.check_output("git rev-parse HEAD", shell=True)
    if not check_clean_working_dir() and not commit:
        print "there are uncommitted changes in the repository; call git status for details. Use -c to auto-commit them."
        exit(-1)
    override_branch_with_commit(old_head, branch, commit_changes=commit)
    configure_vp_code(vp_code, "'%s'" % date_str)
    commit_msg = "Auto-commit before experiment %s" % tag_name
    commit_all_changes(commit_msg)
    print "ready to run experiment; don't forget to call the script with finish to tag the results"

def finish_experiment(tag_name, message):
    commit_msg = "Auto-commit after experiment %s" % tag_name
    commit_all_changes(commit_msg)
    tag_cmd = "git tag -a %s" % tag_name
    if message is not None:
        tag_cmd += ' -m "%s"' % message
    ret_code = print_and_call(tag_cmd)
    if ret_code != 0:
        print "tagging failed"
        exit(ret_code)
    configure_vp_code("VPtest")
    commit_msg = "Auto-commit: Reset VP code"
    commit_all_changes(commit_msg)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="initialize repository for experiment and tag current codebase")
    parser.add_argument('mode', choices=['init', 'finish'], help="mode of operation: initialize or finalize experiment")
    parser.add_argument('-vp', '--vp_code', help="VP code of current experiment")
    parser.add_argument('-t', '--tag_name', help="name of git tag to create")
    parser.add_argument('-c', '--commit', action='store_true', help="automatically commit all changes")
    parser.add_argument('-b', '--branch', default='experiments', help="branch to commit to for experiments")
    parser.add_argument('-m', '--message', help="message for tag (finish only)")

    args = parser.parse_args()

    if args.mode == "init":
        if args.vp_code is None:
            args.vp_code = raw_input("Please enter the VPcode (VPxyz):\n> ")
            if raw_input("Is '%s' correct? (y/n)" % args.vp_code) != "y":
                exit(-1)
            cur_date_str = datetime.datetime.now().strftime("%y-%m-%d")
            if args.tag_name is None:
                args.tag_name = args.vp_code + "_" + cur_date_str
            init_experiment(args.vp_code, cur_date_str, args.tag_name, args.commit, args.branch)
    elif args.mode == "finish":
        if args.tag_name is None:
            (vp_code, vp_date) = get_vp_code()
            args.tag_name = vp_code + "_" + vp_date.replace("'", "")
        finish_experiment(args.tag_name, args.message)
