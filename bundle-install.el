(progn
  ;; Add `el-get' to the load path
  (unless (boundp 'bundle-no-el-get-load-path)
    (add-to-list 'load-path (locate-user-emacs-file "el-get/el-get")))

  ;; Install `el-get'
  (unless (require 'el-get nil 'noerror)
    (with-current-buffer
        (url-retrieve-synchronously
         "http://raw.github.com/dimitri/el-get/master/el-get-install.el")
      (goto-char (point-max))
      (eval-print-last-sexp)))

  ;; Install `bundle'
  (add-to-list 'el-get-sources
               '(:name bundle :type github :pkgname "tarao/bundle-el"))
  (el-get 'sync 'bundle))
