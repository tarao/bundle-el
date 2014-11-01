(let ((el-get-root-dir
       (file-name-as-directory
        (or (bound-and-true-p el-get-dir)
            (expand-file-name "el-get"
                              (file-name-as-directory user-emacs-directory))))))
  ;; Install `el-get`
  (add-to-list 'load-path (expand-file-name "el-get" el-get-root-dir))
  (unless (require 'el-get nil 'noerror)
    (with-current-buffer
        (url-retrieve-synchronously
         "http://raw.github.com/dimitri/el-get/master/el-get-install.el")
      (goto-char (point-max))
      (eval-print-last-sexp)))

  ;; Install `bundle`
  (let ((source '(:name bundle :type github :pkgname "tarao/bundle-el")))
    (when (bound-and-true-p bundle-install-branch)
      (plist-put source :branch bundle-install-branch))
    (add-to-list 'el-get-sources source)
    (el-get 'sync 'bundle)))
