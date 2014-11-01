# el-get-bundle.el --- an [el-get][] wrapper

* Wrap [el-get][] with easy syntax.
  * Avoiding long lines of el-get recipes.
* A package requirement and its configuration are put at the same
  place in your Emacs init file.
* Configurations are automatically byte-compiled when they are loaded
  for the first time.
  * This gives you a chance to find errors in your configuration.

### Just install some package

To install a package whose recipe is already defined, use `el-get-bundle`
macro with the package name in your init file.
```lisp
(el-get-bundle color-moccur)
```

This is essentially equivalent to the following code.
```lisp
(el-get 'sync 'color-moccur)
```

If you also want to `require` the package, use `el-get-bundle!` macro.
```lisp
(el-get-bundle! color-moccur)
```

### Install some package and configure it

You can write configurations after the package name.
```lisp
(el-get-bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files))
```

Configurations are automatically compiled when they are evaluated for
the first time (after you modified the file enclosing the
configurations).  The configurations are saved to a file in
`el-get-bundle-init-directory` together with a compiled version.

Note that you should not call functions or refer to variables defined
in the package if the package is going to be autoloaded.  In such
case, you should use `eval-after-load` function.
```lisp
(el-get-bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files)
  (eval-after-load 'anything
    '(progn
       ;; referring to `anything-map' requires "anything.el" to be loaded
       (define-key anything-map (kbd "M-n") #'anything-next-source)
       (define-key anything-map (kbd "M-p") #'anything-previous-source))))
```

If you want the form passed to `eval-after-load` to be compiled, use
`el-get-eval-after-load-compile` macro instead.
```lisp
(el-get-bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files)
  (el-get-eval-after-load-compile 'anything
    ;; referring to `anything-map' requires "anything.el" to be loaded
    (define-key anything-map (kbd "M-n") #'anything-next-source)
    (define-key anything-map (kbd "M-p") #'anything-previous-source)))
```

Unlike `eval-after-load`, you don't have to quote the configuration
form in `el-get-eval-after-load-compile`.  When `el-get-eval-after-load-compile`
macro call is compiled, the package is loaded only for that time to
make sure that functions and variables in the package are defined.
Don't put anything which should not be in a function body because the
form is compiled as a function body.

### Pass options to package source definitions

If you want to override a package source definition or define a new
definition, you can pass keyword list after the package name.

For example, if you want to install `zenburn-theme` but want to use
other version than el-get's default recipe, you can reuse the default
recipe with overriding `:url` option.
```lisp
(el-get-bundle zenburn-theme
  :url "http://raw.github.com/bbatsov/zenburn-emacs/master/zenburn-theme.el"
  (load-theme 'zenburn t))
```

If you want to define a new package source, then supply full options.
```lisp
(el-get-bundle! zlc
  :type github :pkgname "mooz/emacs-zlc"
  :description "Provides zsh like completion for minibuffer in Emacs"
  :website "http://d.hatena.ne.jp/mooz/20101003/p1")
```

The keyword `:type` is required if the package source is already
defined but you don't reuse it.  Otherwise, if the package source is
not defined yet, you can omit `:type` keyword as long as it can be
guessed from `:url`.
```lisp
(el-get-bundle! zlc :url "http://github.com/mooz/emacs-zlc.git")
;; equivalent to
;; (el-get-bundle! zlc :type git :url "http://github.com/mooz/emacs-zlc.git")
```

### Syntax sugars for package source definitions

There are some ways to specify package source options by package name
modifiers.

`<owner>/` modifier
: specifies a github owner name

`gist:<id>:` modifier
: specifies a gist ID

`<type>:` modifier
: specifies a type for the package

```lisp
(el-get-bundle tarao/tab-group)
;; equivalent to
;; (el-get-bundle tab-group :type github :pkgname "tarao/tab-group")

(el-get-bundle! gist:4362564:init-loader)
;; equivalent to
;; (el-get-bundle! init-loader :type git :url "http://gist.github.com/4362564.git")

(el-get-bundle elpa:undo-tree)
;; equivalent to
;; (el-get-bundle undo-tree :type elpa)
```

### Customization

- `el-get-bundle-byte-compile` : boolean

  `t` means to automatically byte-compile configuration forms.

  Unless this option is set to `t`, nothing is saved to
  `el-get-bundle-init-directory` and configuration forms are passed as
  `:after` script of the package source definition.

  The default value is `t`.

- `el-get-bundle-init-directory` : directory

  Directory to save auto generated files for configurations.

  The default value is `~/.emacs.d/el-get-/bundle-init/`.

- `el-get-bundle-reload-user-init-file` : boolean

  `t` means to reload `user-init-file` (such as `~/.emacs` or
  `~/.emacs.d/init.el`) when a package is updated by `el-get-bundle-update` or
  `el-get-bundle-update-all`.

  The default value is `t`.

### Macros

- `el-get-bundle` ( *package* [ *keywords* ] [ *form*... ] )

  Install *package* with options *keywords* and run configuration
  *form*.

  *keywords* are elements of a property list whose keys are symbols
  whose names start with `:`.  See the documentation of `el-get-sources`
  for the meanings of the keys.

  After the *package* is installed, the *form* is evaluated.  When
  `el-get-bundle-byte-compile` is `t`, the *form* is saved to a file in
  `el-get-bundle-init-directory` and compiled.

- `el-get-bundle!` ( *package* [ *keywords* ] [ *form*... ] )

  Install and `require` *package* with options *keywords* and run
  configuration *form*.  It is equivalent to `el-get-bundle` except that it
  `require`s the *package*.

- `el-get-eval-after-load-compile` ( *package* *form*... )

  Arrange that if *package* is loaded, *form* will be run immediately
  afterwards.  This is equivalent to `eval-after-load` except two
  differences:
  * You don't have to quote *form*.
  * *form* is compiled when `el-get-eval-after-load-compile` macro is compiled.

  *form* is compiled as a function body by the following code.
  ```lisp
  (byte-compile `(lambda () ,@form))
  ```

  When `el-get-eval-after-load-compile` macro call is compiled, the *package*
  is loaded only for that time to make sure that functions and variables
  in the *package* are defined.

### Commands

- `el-get-bundle-update` ( *package*... )

  Update *package*.  If `el-get-bundle-reload-user-init-file` is `t`,
  `user-init-file` (such as `~/.emacs` or `~/.emacs.d/init.el`) is
  reloaded after the *package* update.

- `el-get-bundle-update-all` ( )

  Update all installed packages.  If `el-get-bundle-reload-user-init-file` is
  `t`, `user-init-file` (such as `~/.emacs` or `~/.emacs.d/init.el`) is
  reloaded after all package updates.

### Functions

- `el-get-bundle-register-callsite` ( *package* [ *callsite* ] )

  Declare that *package* update causes *callsite* (a file) to require
  being loaded again.

  This **DOES NOT** mean that `el-get-bundle-update` reload the *callsite* but
  configuration forms in the *callsite* will be recompiled next time
  they are evaluated.

  The registration is automatically done in `el-get-bundle` macro.  You have to
  use this function if you want to recompile your configuration when
  some other package installed in some other file is updated.

### Acknowledgment

The technique of byte-compiling version of `eval-after-load` is taken
from [eval-after-load-q][].

[eval-after-load-q]: http://hke7.wordpress.com/2012/02/28/eval-after-load-%e3%82%92%e5%b0%91%e3%81%97%e6%94%b9%e9%80%a0/
