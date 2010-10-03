#!/usr/bin/env ruby

prefix = "git-1.7.1.bundle/libexec/git-core"

binaries = %w[git-add
git-annotate
git-apply
git-archive
git-bisect--helper
git-blame
git-branch
git-bundle
git-cat-file
git-check-attr
git-check-ref-format
git-checkout
git-checkout-index
git-cherry
git-cherry-pick
git-clean
git-clone
git-commit
git-commit-tree
git-config
git-count-objects
git-describe
git-diff
git-diff-files
git-diff-index
git-diff-tree
git-fast-export
git-fetch
git-fetch-pack
git-fmt-merge-msg
git-for-each-ref
git-format-patch
git-fsck
git-fsck-objects
git-gc
git-get-tar-commit-id
git-grep
git-hash-object
git-help
git-index-pack
git-init
git-init-db
git-log
git-ls-files
git-ls-remote
git-ls-tree
git-mailinfo
git-mailsplit
git-merge
git-merge-base
git-merge-file
git-merge-index
git-merge-ours
git-merge-recursive
git-merge-subtree
git-merge-tree
git-mktag
git-mktree
git-mv
git-name-rev
git-notes
git-pack-objects
git-pack-redundant
git-pack-refs
git-patch-id
git-peek-remote
git-prune
git-prune-packed
git-push
git-read-tree
git-receive-pack
git-reflog
git-remote
git-replace
git-repo-config
git-rerere
git-reset
git-rev-list
git-rev-parse
git-revert
git-rm
git-send-pack
git-shortlog
git-show
git-show-branch
git-show-ref
git-stage
git-status
git-stripspace
git-symbolic-ref
git-tag
git-tar-tree
git-unpack-file
git-unpack-objects
git-update-index
git-update-ref
git-update-server-info
git-upload-archive
git-var
git-verify-pack
git-verify-tag
git-whatchanged
git-write-tree]



binaries.each do |bin|
  system("rm -v #{prefix}/#{bin}")
end

