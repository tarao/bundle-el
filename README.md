# el-get-bundle.el --- an El-Get wrapper

* Wrap El-Get with easy syntax.
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

When the name of the feature you require is different from the package
name (the recipe name), use `FEATURE in PACKAGE` form.
```lisp
(el-get-bundle! yaicomplete in github:tarao/elisp)
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
case, you should use `with-eval-after-load` macro.
```lisp
(el-get-bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files))
(with-eval-after-load 'anything
  ;; referring to `anything-map' requires "anything.el" to be loaded
  (define-key anything-map (kbd "M-n") #'anything-next-source)
  (define-key anything-map (kbd "M-p") #'anything-previous-source))
```

If you want the form passed to `with-eval-after-load` to be compiled
together with the configurations, you can use
[tarao's `with-eval-after-load-feature`][with-eval-after-load-feature]
instead or you will get "reference to free variable" warnings during
the compilation.
```lisp
(el-get-bundle! with-eval-after-load-feature
                :url "http://github.com/tarao/with-eval-after-load-feature-el.git")
(el-get-bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files)
  (with-eval-after-load-feature 'anything
    ;; referring to `anything-map' requires "anything.el" to be loaded
    (define-key anything-map (kbd "M-n") #'anything-next-source)
    (define-key anything-map (kbd "M-p") #'anything-previous-source)))
```

### Pass options to package source definitions

If you want to override a package source definition or define a new
definition, you can pass keyword list after the package name.

For example, if you want to install `zenburn-theme` but want to use
other version than El-Get's default recipe, you can reuse the default
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

- `el-get-bundle!` ( [*feature* in] *package* [ *keywords* ] [ *form*... ] )

  Install and `require` *package* with options *keywords* and run
  configuration *form*.  It is equivalent to `el-get-bundle` except that it
  `require`s the *package*.

  If *feature* followed by `in` is specified, then *feature* is
  `require`d even though the target of package installation is
  *package*.

### Commands

- `el-get-bundle-reload` ( )

  Reload `user-init-file` (such as `~/.emacs` or `~/.emacs.d/init.el`)
  with maintaining information of `el-get-bundle` configurations.

[with-eval-after-load-feature]: http://github.com/tarao/with-eval-after-load-feature-el
