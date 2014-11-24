;;; bundle.el --- An el-get wrapper

;; Author: INA Lintaro <tarao.gnn at gmail.com>
;; URL: https://github.com/tarao/bundle-el
;; Version: 0.1
;; Keywords: emacs package install compile

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(let ((el-get-root-dir
       (file-name-as-directory
        (or (bound-and-true-p el-get-dir)
            (file-name-directory
             (directory-file-name
              (file-name-directory load-file-name)))))))
  (add-to-list 'load-path (expand-file-name "el-get" el-get-root-dir)))
(require 'el-get)

(defgroup bundle nil "bundle"
  :group 'convenience)

(defcustom bundle-byte-compile t
  "t means to automatically byte-compile init forms.

This variable is just an alias. If you want to modify the value
of this variable, set `el-get-bundle-byte-compile' instead."
  :set #'(lambda (sym value)
           (set-default 'el-get-bundle-byte-compile value)
           (set-default sym value))
  :type 'boolean
  :group 'bundle)

(defcustom bundle-init-directory (expand-file-name "bundle-init/" el-get-dir)
  "Directory to save auto generated init files.

This variable is just an alias. If you want to modify the value
of this variable, set `el-get-bundle-init-directory' instead."
  :set #'(lambda (sym value)
           (set-default 'el-get-bundle-init-directory value)
           (set-default sym value))
  :type 'directory
  :group 'bundle)

;;;###autoload
(defalias 'bundle 'el-get-bundle)

;;;###autoload
(defalias 'bundle! 'el-get-bundle!)

;;;###autoload
(defalias 'bundle-reload 'el-get-bundle-reload)

(provide 'bundle)
;;; bundle.el ends here
