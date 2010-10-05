require 'pp'
def main(data)
  data = data.strip
  groups = data.split("\n").inject({}) do |hash, line|
    inode, size, name = line.strip.split(/\s+/)
    inode = inode.to_i
    size = size.to_i
    hash[inode] ||= {:size => size, :names => []}
    hash[inode][:names] << name
    hash
  end
  
  pp groups
  
  
  total_size = groups.inject(0){|s, (k,v)| s + v[:size] }
  puts "Total size: #{total_size / 1024.0 / 1024.0} Mb"
  
end

main(%{
5174358 1256368 git
5174358 1256368 git-add
5174345   35747 git-add--interactive
5174327   19036 git-am
5174358 1256368 git-annotate
5174358 1256368 git-apply
5174347   36978 git-archimport
5174358 1256368 git-archive
5174328   10021 git-bisect
5174358 1256368 git-bisect--helper
5174358 1256368 git-blame
5174358 1256368 git-branch
5174358 1256368 git-bundle
5174358 1256368 git-cat-file
5174358 1256368 git-check-attr
5174358 1256368 git-check-ref-format
5174358 1256368 git-checkout
5174358 1256368 git-checkout-index
5174358 1256368 git-cherry
5174358 1256368 git-cherry-pick
5174427     214 git-citool
5174358 1256368 git-clean
5174358 1256368 git-clone
5174358 1256368 git-commit
5174358 1256368 git-commit-tree
5174358 1256368 git-config
5174358 1256368 git-count-objects
5174348   12754 git-cvsexportcommit
5174349   29302 git-cvsimport
5174350  117775 git-cvsserver
5174322  590656 git-daemon
5174358 1256368 git-describe
5174358 1256368 git-diff
5174358 1256368 git-diff-files
5174358 1256368 git-diff-index
5174358 1256368 git-diff-tree
5174346    2727 git-difftool
5174329    1745 git-difftool--helper
5174358 1256368 git-fast-export
5174314  630200 git-fast-import
5174358 1256368 git-fetch
5174358 1256368 git-fetch-pack
5174330   12172 git-filter-branch
5174358 1256368 git-fmt-merge-msg
5174358 1256368 git-for-each-ref
5174358 1256368 git-format-patch
5174358 1256368 git-fsck
5174358 1256368 git-fsck-objects
5174358 1256368 git-gc
5174358 1256368 git-get-tar-commit-id
5174358 1256368 git-grep
5174427     214 git-gui
5174428    1289 git-gui--askpass
5174358 1256368 git-hash-object
5174358 1256368 git-help
5174319  585072 git-http-backend
5174320  610496 git-http-fetch
5174321  628016 git-http-push
5174315  604032 git-imap-send
5174358 1256368 git-index-pack
5174358 1256368 git-init
5174358 1256368 git-init-db
5174354  247989 git-instaweb
5174358 1256368 git-log
5174331     554 git-lost-found
5174358 1256368 git-ls-files
5174358 1256368 git-ls-remote
5174358 1256368 git-ls-tree
5174358 1256368 git-mailinfo
5174358 1256368 git-mailsplit
5174358 1256368 git-merge
5174358 1256368 git-merge-base
5174358 1256368 git-merge-file
5174358 1256368 git-merge-index
5174332    2068 git-merge-octopus
5174333    3814 git-merge-one-file
5174358 1256368 git-merge-ours
5174358 1256368 git-merge-recursive
5174334     944 git-merge-resolve
5174358 1256368 git-merge-subtree
5174358 1256368 git-merge-tree
5174335    6099 git-mergetool
5174355    9006 git-mergetool--lib
5174358 1256368 git-mktag
5174358 1256368 git-mktree
5174358 1256368 git-mv
5174358 1256368 git-name-rev
5174358 1256368 git-notes
5174358 1256368 git-pack-objects
5174358 1256368 git-pack-redundant
5174358 1256368 git-pack-refs
5174356    1941 git-parse-remote
5174358 1256368 git-patch-id
5174358 1256368 git-peek-remote
5174358 1256368 git-prune
5174358 1256368 git-prune-packed
5174336    8027 git-pull
5174358 1256368 git-push
5174337    3348 git-quiltimport
5174358 1256368 git-read-tree
5174339   14646 git-rebase
5174338   24915 git-rebase--interactive
5174358 1256368 git-receive-pack
5174358 1256368 git-reflog
5174351    4232 git-relink
5174358 1256368 git-remote
5174323  619112 git-remote-ftp
5174323  619112 git-remote-ftps
5174323  619112 git-remote-http
5174323  619112 git-remote-https
5174340    4492 git-repack
5174358 1256368 git-replace
5174358 1256368 git-repo-config
5174341    1592 git-request-pull
5174358 1256368 git-rerere
5174358 1256368 git-reset
5174358 1256368 git-rev-list
5174358 1256368 git-rev-parse
5174358 1256368 git-revert
5174358 1256368 git-rm
5174352   36412 git-send-email
5174358 1256368 git-send-pack
5174357    4013 git-sh-setup
5174316  576048 git-shell
5174358 1256368 git-shortlog
5174358 1256368 git-show
5174358 1256368 git-show-branch
5174317   14152 git-show-index
5174358 1256368 git-show-ref
5174358 1256368 git-stage
5174342    8838 git-stash
5174358 1256368 git-status
5174358 1256368 git-stripspace
5174343   17709 git-submodule
5174353  175375 git-svn
5174358 1256368 git-symbolic-ref
5174358 1256368 git-tag
5174358 1256368 git-tar-tree
5174358 1256368 git-unpack-file
5174358 1256368 git-unpack-objects
5174358 1256368 git-update-index
5174358 1256368 git-update-ref
5174358 1256368 git-update-server-info
5174358 1256368 git-upload-archive
5174318  585488 git-upload-pack
5174358 1256368 git-var
5174358 1256368 git-verify-pack
5174358 1256368 git-verify-tag
5174344    3961 git-web--browse
5174358 1256368 git-whatchanged
5174358 1256368 git-write-tree  
})
