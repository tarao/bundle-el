(progn
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
