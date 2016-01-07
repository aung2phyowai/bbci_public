#!/usr/bin/env python
""" Manage git subtree dependencies. """

import argparse
import collections
import os
import subprocess

Dependency = collections.namedtuple('Dependency', ['directory', 'repository', 'default_branch'])

PROJECT_DEPENDENCIES = {
    'bbci_public' : Dependency('deps/bbci_public', 'git@github.com:bsdlab/bbci_public.git', 'master'),
    'bsdlab_toolbox' : Dependency('deps/bsdlab_toolbox', 'git@github.com:bsdlab/bsdlab_toolbox.git', 'master'),
    'pyff' : Dependency('deps/pyff', 'git@github.com:bsdlab/pyff.git', 'windows_x64')
    }

def init_dependency(dep_name, branch_name, squash):
    """Initialize dependency with git subtree add"""
    dep_dir = PROJECT_DEPENDENCIES[dep_name].directory
    if not os.path.isdir(dep_dir):
        #assume that we have to initialize it
        parent_dir = os.path.dirname(dep_dir)
        if not os.path.isdir(parent_dir):
            os.makedirs(parent_dir)
        if branch_name is None:
            branch_name = PROJECT_DEPENDENCIES[dep_name].default_branch
        #relay work to git
        subtree_add_cmd = ' '.join([
            'git subtree add',
            '--prefix', dep_dir,
            PROJECT_DEPENDENCIES[dep_name].repository,
            branch_name
            ])
        if squash:
            subtree_add_cmd += ' --squash'
        print "executing %s" % subtree_add_cmd
        return subprocess.call(subtree_add_cmd, shell=True)
    else:
        return 0 #success

def pull_dependency(dep_name, branch_name, squash):
    """Update dependency with git subtree pull"""
    if branch_name is None:
        branch_name = PROJECT_DEPENDENCIES[dep_name].default_branch
    #relay work to git
    subtree_pull_cmd = ' '.join([
        'git subtree pull',
        '--prefix', PROJECT_DEPENDENCIES[dep_name].directory,
        PROJECT_DEPENDENCIES[dep_name].repository,
        branch_name
        ])
    if squash:
        subtree_pull_cmd += ' --squash'
    print "executing %s" % subtree_pull_cmd
    return subprocess.call(subtree_pull_cmd, shell=True)
   
def push_dependency(dep_name, branch_name):
    """Push local changes in dependency to origin repository"""
    if branch_name is None:
        print "Please specify an upstream branch name with -b.\nDefault branch for this repository during update is %s" % PROJECT_DEPENDENCIES[dep_name].default_branch
        exit(1)
    subtree_push_cmd = ' '.join([
        'git subtree push',
        '--prefix', PROJECT_DEPENDENCIES[dep_name].directory,
        PROJECT_DEPENDENCIES[dep_name].repository,
        branch_name
        ])
    print "executing %s" % subtree_push_cmd
    return subprocess.call(subtree_push_cmd, shell=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='update code of dependencies managed by git subtree; location and default branch of dependencies is managed within this script')
    parser.add_argument('operation', choices=['init', 'pull', 'push'], help='operation to be performed (analogous to git subtree add/pull/push)')
    parser.add_argument('dep_name', choices=PROJECT_DEPENDENCIES.keys(), help='dependency to update')
    parser.add_argument('-b', '--branch', help='remote branch to use')
    parser.add_argument('-s', '--squash', type=bool, default=True, help='squash commits (combine all dependency commits into a single new one)')

    args = parser.parse_args()

    if args.operation == 'init':
        ret_code = init_dependency(args.dep_name, args.branch, args.squash)
    elif args.operation == 'pull':
        ret_code = pull_dependency(args.dep_name, args.branch, args.squash)
    elif args.operation == 'push':
        ret_code = push_dependency(args.dep_name, args.branch)
    else:
        print "unknown command"
        exit(1)
    exit(ret_code)
