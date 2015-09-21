#Git Annex

All data underneath *data/kitti/images* is handled by git-annex and *must not* be added directly to git

## Install

``sudo apt-get install git-annex`` or get it from <https://git-annex.branchable.com/>

## Basic data setup

Where is the data:

* complete repo on blbt-fs1 fileserver (under ``projects/visual_complexity``)
* backup on ``cake.informatik.uni-freiburg.de``
* on local dev machines...

## Hook to prevent adding binary data to the repo

add the following to your *pre-commit* hook (``.git/hooks/pre-commit
``)

```
# stops you from adding binaries file
allow_binaries=$(git config --bool --get hooks.allowbinaries)

if [ "$allow_binaries" != "true" ]; then
    echo "checking for binary files..."
    EMPTY_TREE=$(git hash-object -t tree /dev/null)

    if git rev-parse --verify HEAD >/dev/null 2>&1
    then
        against=HEAD
    else
        # Initial commit: diff against an empty tree object
        against=4b825dc642cb6eb9a060e54bf8d69288fbee4904
    fi

    # add --diff-filter=A to check only new files
#    if git diff --cached --numstat $EMPTY_TREE | grep -e '^-' >/dev/null; then
    if git diff --cached --numstat $against | grep -e '^-' >/dev/null; then
        echo Error: commit would add binary files:
        git diff --cached --numstat $against | grep -e '^-' | cut -f3-
        echo Use git-annex instead
        exit 1
    fi
fi
```

and add the following to your ``.git/config``:

```
[hooks]
        allowbinaries = false
```


## Initial Setup

This is just for reference and shouldn't be needed again

### On dev machine (aislap78)
```
	git annex init aislap78
	cd data/kitti
	git annex add images
	git add images/combined #symbolic links, no files
	git add meta seqs #textual data
	git commit -m "..."
	git push -u origin master git-annex
	#now, init the blbt folder and continue afterwards
	git remote add blbtfs1-samba-mount /mnt/blbt-fs1/projects/visual_complexity/repo/
	git annex sync
	git annex numcopies 2
	git-annex copy data/kitti/images/ --to=blbtfs1-samba-mount
	#now, init the cake repo and continue afterwards
	git remote add cake cake.informatik.uni-freiburg.de:/export/backup/henkolk/repos/visual_complexity_observation
	git annex sync
	git-annex copy data/kitti/images/ --to=cake
```

### In blbt folder

```
	cd /mnt/blbt-fs1/projects/visual_complexity
	git clone git@github.com:bsdlab/visual_complexity_observation.git repo
	git annex init blbtfs1-samba-mount
	git annex sync
	git remote add aislap78 ~/repos/visual_complexity_observation/
```


### on cake

```
	ssh cake.informatik.uni-freiburg.de
	cd /export/backup/henkolk/repos
	git clone git@github.com:bsdlab/visual_complexity_observation.git
	cd visual_complexity_observation/
	git annex init cake
	git annex sync
```
