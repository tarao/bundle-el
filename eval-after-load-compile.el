;;; eval-after-load-compile.el --- Compiling version of eval-after-load

;; Author: INA Lintaro <tarao.gnn at gmail.com>
;; URL: https://github.com/tarao/bundle-el
;; Version: 0.1
;; Keywords: emacs compile

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
(require 'el-get-eval-after-load-compile)

;;;###autoload
(defalias 'eval-after-load-compile 'el-get-eval-after-load-compile)

(provide 'eval-after-load-compile)
;;; eval-after-load-compile.el ends here
