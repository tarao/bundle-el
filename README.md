# bundle.el --- an [El-Get][] wrapper

* Wrap [El-Get][] with easy syntax.
  * Avoiding long lines of El-Get recipes.
* A package requirement and its initialization code are put at the same
  place in your Emacs init file.
* Initialization code is automatically byte-compiled when they are
  evaluated for the first time.
  * This gives you a chance to find errors in your configuration.

## Installation

```lisp
(add-to-list 'load-path (locate-user-emacs-file "el-get/bundle"))
(unless (require 'bundle nil 'noerror)
  (with-current-buffer
      (url-retrieve-synchronously
       "http://raw.github.com/tarao/bundle-el/master/bundle-install.el")
    (goto-char (point-max))
    (eval-print-last-sexp)))
```

## Case Studies

### Just install some package

To install a package whose source is already defined in a recipe file,
use `bundle` macro with the package name.

```lisp
(bundle color-moccur)
```

This is essentially equivalent to the following code.
```lisp
(el-get 'sync 'color-moccur)
```

If you also want to `require` the package, use `bundle!` macro.
```lisp
(bundle! color-moccur)
```

When the name of the feature you require is different from the package
name (the recipe name), use `FEATURE in PACKAGE` form.
```lisp
(bundle! yaicomplete in github:tarao/elisp)
```

### Install some package and configure it

You can write initialization code after the package name.
```lisp
(bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files))
```

You can provide multiple initialization code for a single package by
writing `bundle` macro call may times. Each initialization code
is evaluated when the corresponding `bundle` macro call is
evaluated.

Initialization code is automatically compiled when they are evaluated
for the first time (after you modified the file enclosing the code) if
`bundle-byte-compile` is non-nil.  The initialization code is
saved to a file in `bundle-init-directory` together with a
compiled version.

Note that you should not call functions or refer to variables defined
in the package if the package is going to be autoloaded.  In such
case, you should use `with-eval-after-load` macro.
```lisp
(bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files))
(with-eval-after-load 'anything
  ;; referring to `anything-map' requires "anything.el" to be loaded
  (define-key anything-map (kbd "M-n") #'anything-next-source)
  (define-key anything-map (kbd "M-p") #'anything-previous-source))
```

If you want the form passed to `with-eval-after-load` to be compiled
together with the initialization code, you can use
[tarao's `with-eval-after-load-feature`][with-eval-after-load-feature]
instead or you will get "reference to free variable" warnings during
the compilation.
```lisp
(bundle! with-eval-after-load-feature
                :url "http://github.com/tarao/with-eval-after-load-feature-el.git")
(bundle anything
  (global-set-key (kbd "C-x b") #'anything-for-files)
  (with-eval-after-load-feature 'anything
    ;; referring to `anything-map' requires "anything.el" to be loaded
    (define-key anything-map (kbd "M-n") #'anything-next-source)
    (define-key anything-map (kbd "M-p") #'anything-previous-source)))
```

### Pass options to package source definitions

If you want to override a package source definition in a recipe file
or define a new definition, you can pass a property list after the
package name.

For example, if you want to install `zenburn-theme` but want to use
other version than El-Get's default recipe, you can reuse the default
recipe with overriding `:url` option.
```lisp
(bundle zenburn-theme
  :url "http://raw.github.com/bbatsov/zenburn-emacs/master/zenburn-theme.el"
  (load-theme 'zenburn t))
```

If you want to define a new package source, then supply full options.
```lisp
(bundle! zlc
  :type github :pkgname "mooz/emacs-zlc"
  :description "Provides zsh like completion for minibuffer in Emacs"
  :website "http://d.hatena.ne.jp/mooz/20101003/p1")
```

The property `:type` is required if the package source is already
defined but you don't reuse it.  Otherwise, if the package source is
not defined yet, you can omit `:type` property as long as it can be
guessed from `:url`.
```lisp
(bundle! zlc :url "http://github.com/mooz/emacs-zlc.git")
;; equivalent to
;; (bundle! zlc :type git :url "http://github.com/mooz/emacs-zlc.git")
```

### Syntax sugars for package source definitions

There are some ways to specify package source options by package name
modifiers.  With these modifiers, you can omit `:type` property.

`<owner>/` modifier
: specifies a github owner name

`gist:<id>:` modifier
: specifies a gist ID

`<type>:` modifier
: specifies a type for the package

```lisp
(bundle tarao/tab-group)
;; equivalent to
;; (bundle tab-group :type github :pkgname "tarao/tab-group")

(bundle! gist:4362564:init-loader)
;; equivalent to
;; (bundle! init-loader :type git :url "http://gist.github.com/4362564.git")

(bundle elpa:undo-tree)
;; equivalent to
;; (bundle undo-tree :type elpa)
```

## Reference

### Customization

- `bundle-byte-compile` : boolean

  Whether to compile initialization code in a `bundle` macro
  call.  Defaults to `t`.

- `bundle-init-directory` : directory

  Directory where a copy of initialization code specified in a
  `bundle` macro call and its byte-compiled version are saved.
  Defaults to `~/.emacs.d/el-get/bundle-init/`.

### Macros

- `bundle` ( *package* [ *keywords* ] [ *form*... ] )

  Install *package* with options *keywords* and run configuration
  *form*.

  *keywords* are elements of a property list whose keys are symbols
  whose names start with `:`.  See the documentation of `el-get-sources`
  for the meanings of the keys.

  After the *package* is installed, the *form* is evaluated.  When
  `bundle-byte-compile` is `t`, the *form* is saved to a file in
  `bundle-init-directory` and compiled.

- `bundle!` ( [*feature* in] *package* [ *keywords* ] [ *form*... ] )

  Install and `require` *package* with options *keywords* and run
  configuration *form*.  It is equivalent to `bundle` except that it
  `require`s the *package*.

  If *feature* followed by `in` is specified, then *feature* is
  `require`d even though the target of package installation is
  *package*.

## Acknowledgment

The [original implementation][original] of this package is merged to
[El-Get][]. While the merged versions are renamed to `el-get-bundle*`,
this package provides the original interface (`bundle*`), which are
just aliases to the merged versions.

[El-Get]: http://github.com/dimitri/el-get
[original]: https://github.com/tarao/bundle-el/tree/original
[with-eval-after-load-feature]: http://github.com/tarao/with-eval-after-load-feature-el
