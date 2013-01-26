;;; bundle.el --- An el-get wrapper

;; Author: INA Lintaro <tarao.gnn at gmail.com>
;; URL: https://gist.github.com/4414297
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

(require 'el-get)
(eval-when-compile (require 'cl))

;; customization

(defgroup bundle nil "bundle"
  :group 'convenience)

(defcustom bundle-byte-compile t
  "t means to automatically byte-compile init forms."
  :type 'boolean
  :group 'bundle)

(defcustom bundle-init-directory
  (concat (file-name-as-directory user-emacs-directory) "bundle/init/")
  "Directory to save auto generated init files."
  :type 'directory
  :group 'bundle)

(defcustom bundle-reload-user-init-file t
  "Reload `user-init-file' when a package is updated."
  :type 'boolean
  :group 'bundle)

(defvar bundle-inits nil)
(defvar bundle-loader-alist nil)
(defvar bundle-updates nil)

(defconst bundle-gist-url-type-plist
  (list 'http "http://gist.github.com/%s.git"
        'https "https://gist.github.com/%s.git"
        'git "git://gist.github.com/%s.git"
        'ssh "git@gist.github.com:%s.git")
  "Plist mapping Gist types to their URL format strings.")

;; patches

;; patch for el-get
(defadvice el-get-update-autoloads
  (around bundle-respect-autoloads (package) activate)
  "Suppress generating autoloads if \":autoloads nil\" is specified.
This is a bug in el-get and will be fixed in 5.0. See
https://github.com/dimitri/el-get/issues/810 for details."
  (let ((def (el-get-package-def package)))
    (unless (and (plist-member def :autoloads)
                 (not (plist-get def :autoloads)))
      ad-do-it)))

;; patch for init-loader
(defun bundle-silent-load (file)
  (let ((inits bundle-inits))
    (load file t)
    (setq bundle-inits inits)))
(add-hook 'init-loader-before-compile-hook #'bundle-silent-load)

;; internals

(defsubst bundle-gist-url (id &optional src)
  (let* ((type (or (plist-get src :url-type) el-get-github-default-url-type))
         (str (or (plist-get bundle-gist-url-type-plist type)
                  (plist-get bundle-gist-url-type-plist 'http))))
    (format str id)))

(defsubst bundle-load-file-el (&optional file)
  (let ((file (or file load-file-name)))
    (and file
         (replace-regexp-in-string "\\.elc$" ".el" (expand-file-name file)))))

(defun bundle-package-def (src)
  (condition-case nil
      (el-get-package-def (if (listp src) (el-get-source-name src) src))
    (error nil)))
(defalias 'bundle-defined-p (symbol-function 'bundle-package-def))

(defun bundle-guess-type (src)
  (cond
   ((plist-member src :url)
    (let ((url (plist-get src :url)))
      (cond
       ((or (string-match-p "^git:" url) (string-match-p "\\.git$" url))
        'git)
       ((or (string-match-p "^bzr:" url) (string-match-p "^lp:" url))
        'bzr)
       ((string-match-p "^svn:" url)
        'svn)
       ((string-match-p ":pserver:" url)
        'cvs)
       ((string-match-p "ftp://" url)
        'ftp)
       ((or (string-match-p "https?://" url) (string-match-p "\\.el$" url))
        'http))))
   (t 'elpa)))

(defun bundle-parse-name (sym)
  (let ((spec (split-string (format "%s" sym) ":")) s)
    (when (string= (or (nth 0 spec) "") "github") (setq spec (cdr spec)))
    (cond
     ((and (> (length spec) 2) (string= (car spec) "gist"))
      ;; gist:12345:name
      (let* ((id (nth 1 spec))
             (name (intern (or (nth 2 spec) id)))
             (type 'git) (url (bundle-gist-url id)))
        (plist-put (plist-put (plist-put s :name name) :type type) :url url)))
     ((> (length spec) 1)
      ;; type:name
      (let ((name (intern (nth 1 spec))) (type (intern (nth 0 spec))))
      (plist-put (plist-put s :name name) :type type)))
     ((= (length (split-string (or (nth 0 spec) "") "/")) 2)
      ;; user/repository
      (let ((name (intern (replace-regexp-in-string "^.*/" "" (nth 0 spec))))
            (type 'github) (pkgname (nth 0 spec)))
        (plist-put (plist-put (plist-put s :name name) :type type)
                   :pkgname pkgname)))
     (t (plist-put s :name sym)))))

(defun bundle-merge-source (src)
  (let* ((name (el-get-source-name src))
         (source (if (plist-get src :type) nil (el-get-package-def name))))
    (while (keywordp (nth 0 src))
      (setq source (plist-put source (nth 0 src) (nth 1 src))
            src (cdr-safe (cdr src))))
    source))

(defun bundle-init-id (&rest args)
  (let* ((key (mapconcat #'(lambda (x) (format "%s" x)) args ";"))
         (pair (assoc key bundle-inits)))
    (if pair
        (setcdr pair (1+ (cdr pair)))
      (push (cons key 1) bundle-inits)
      1)))

(defun bundle-load-init (el)
  (let ((lib (file-name-sans-extension el))
        (elc (concat el "c")))
    (when (or (not (file-exists-p elc))
              (file-newer-than-file-p el elc))
      (byte-compile-file el))
    (load (expand-file-name lib))))

(defun bundle-make-init (src)
  (when (and bundle-byte-compile
             (plist-get src :after)
             load-file-name
             (condition-case nil
                 (or (file-exists-p bundle-init-directory)
                     (make-directory bundle-init-directory t) t)
               (error nil)))
    (let* ((path (file-name-sans-extension (expand-file-name load-file-name)))
           (path (split-string path "/"))
           (call-site (mapconcat #'identity path "_"))
           (package (plist-get src :name))
           (id (bundle-init-id package call-site))
           (init-file (concat bundle-init-directory
                              (format "%s_%s-%d" package call-site id)))
           (el (concat init-file ".el"))
           (form (plist-get src :after))
           (loader load-file-name))
      (let ((loader-el (concat (file-name-sans-extension loader) ".el")))
        (when (and (string-match-p "\\.elc$" loader)
                   (file-exists-p loader-el))
          (setq loader loader-el)))
      ;; generate .el file
      (when (or (not (file-exists-p el))
                (file-newer-than-file-p loader el))
        (with-temp-buffer
          (if (listp form)
              (dolist (exp form) (pp exp (current-buffer)))
            (pp form (current-buffer)))
          (write-region nil nil el)))

      ;; loader
      `((bundle-load-init ,el)))))

;;;###autoload
(defun bundle-el-get (src)
  (let ((package (plist-get src :name)) (def (bundle-package-def src))
        (fs (plist-get src :features)) (sync 'sync))
    ;; merge features
    (when (plist-member def :features)
      (let* ((old (plist-get def :features))
             (old (or (and (listp old) old) (list old))))
        (dolist (f old) (add-to-list 'fs f))
        (setq src (plist-put src :features fs))))
    ;; merge src with the oriiginal definition
    (setq def (bundle-merge-source src))

    ;; entering password via process-filter only works in async mode
    (when (or (and (eq (plist-get def :type) 'cvs)
                   (eq (plist-get def :options) 'login)
                   (not (string-match-p "^:pserver:.*:.*@.*:.*$"
                                        (or (plist-get def :url) ""))))
              (eq (plist-get def :type) 'apt)
              (eq (plist-get def :type) 'fink)
              (eq (plist-get def :type) 'pacman))
      (setq sync nil))

    ;; byte-compile :after script
    (let ((form  (or (bundle-make-init def) (plist-get def :after))))
      (when form
        (setq def (plist-put def :after `(progn ,@form)))))

    ;; record dependencies of init files
    (bundle-register-callsite package)

    ;; get
    (add-to-list 'el-get-sources def)
    (prog1 (el-get sync package)
      ;; prevent :after from running twice
      (plist-put def :after nil))))

(defun bundle-post-update (package)
  "Post update process for PACKAGE.
Touch files that contain \"(bundle PACKAGE ...)\" so that the
file becomes newer than its byte-compiled version."
  (dolist (file (cdr (assoc-string package bundle-loader-alist)))
    (when (and file (file-exists-p file))
      (call-process "touch" nil nil nil file)))
  (when bundle-updates
    (setq bundle-updates (delq package bundle-updates))
    (when (and (null bundle-updates) bundle-reload-user-init-file)
      (setq bundle-inits nil bundle-loader-alist nil)
      (when (stringp user-init-file)
        (load user-init-file)
        (run-hooks 'after-init-hook)))))
(add-hook 'el-get-post-update-hooks #'bundle-post-update)

;; commands

;;;###autoload
(defmacro bundle (feature &rest form)
  "Install FEATURE and run init script specified by FORM.

FORM may be started with a property list. In that case, the
property list is pushed to `el-get-sources'.

The rest of FORM is evaluated after FEATURE is loaded."
  (declare (indent defun) (debug t))
  (let* ((feature (or (and (listp feature) (nth 1 feature)) feature))
         (src (bundle-parse-name feature)) require)
    ;; set parsed name
    (setq feature (plist-get src :name))
    ;; (bundle FEATURE in PACKAGE ...) form
    (when (eq (nth 0 form) 'in)
      (let* ((name (nth 1 form))
             (name (or (and (listp name) (nth 1 name)) name)))
        (setq src (bundle-parse-name name)))
      (setq form (nthcdr 2 form) require t))
    ;; parse keywords
    (while (keywordp (nth 0 form))
      (setq src (plist-put src (nth 0 form) (nth 1 form))
            form (cdr-safe (cdr form))))
    ;; put default type
    (unless (or (plist-member src :type) (bundle-defined-p src))
      (setq src (plist-put src :type (bundle-guess-type src))))
    ;; features
    (when (plist-member src :features)
      (let* ((fs (plist-get src :features))
             (fs (or (and (listp fs) fs) (list fs))))
        (setq src (plist-put src :features fs))))
    (when (and require (or (not (plist-member src :features))
                           (plist-get src :features)))
      ;; put the feature into the features list
      (let ((fs (plist-get src :features)))
        (add-to-list 'fs feature)
        (setq src (plist-put src :features fs))))
    ;; init script
    (setq src (plist-put src :after form))

    `(bundle-el-get ',src)))

;;;###autoload
(defmacro bundle! (feature &rest args)
  "Install FEATURE and run init script.
It is the same as `bundle' except that FEATURE is explicitly
required."
  (declare (indent defun) (debug t))
  (if (eq (nth 0 args) 'in)
      `(bundle ,feature ,@args)
    (let* ((feature (or (and (listp feature) (nth 1 feature)) feature))
           (name (plist-get (bundle-parse-name feature) :name)))
      `(bundle ,name ,@(list* 'in feature args)))))

;;;###autoload
(defun bundle-update (&rest packages)
  "Update PACKAGES.
If PACKAGES is nil, then update all installed packages.  If
`bundle-reload-user-init-file' is non-nil, then `user-init-file'
is reloaded after all the updates."
  (interactive)
  (setq bundle-updates packages)
  (if packages
      (mapc #'el-get-update packages)
    (setq bundle-updates (el-get-list-package-names-with-status "installed"))
    (el-get-update-all t)))

;;;###autoload
(defun bundle-register-callsite (package &optional callsite)
  "Declare that PACKAGE update causes CALLSITE to require being loaded again."
  (let* ((pair (or (assoc package bundle-loader-alist) (cons package nil)))
         (loaders (cdr pair))
         (loader (bundle-load-file-el callsite)))
    (when (and loader (file-exists-p loader))
      (add-to-list 'loaders loader))
    (setcdr pair loaders)
    (add-to-list 'bundle-loader-alist pair)))

(provide 'bundle)
;;; bundle.el ends here
