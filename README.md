# comint-fold: Fold input + output blocks in Emacs shells

`comint-fold` is a small Emacs global minor-mode which configures `hideshow` mode in comint buffers to allow *folding* (hiding and unhiding) blocks of input and associated output. 

It can optionally binding the `Tab` key to fold such blocks (when prior to the prompt), and add a fringe indicator for folded blocks.

<img width="449" alt="comint-fold with folded input blocks" src="https://github.com/jdtsmith/comint-fold/assets/93749/c7d768d9-117b-400a-ba79-153bbbf6c48d">

## Install/configure

Not in a package repo.  Simply `package-vc-install` or clone and:

```elisp
(use-package comint-fold
  :load-path "~/path/to/comint-fold/"
  :config
  (comint-fold-mode 1)
  ;; configure special modes 
  (add-hook 'ipy-mode-hook
            (comint-fold-configure-hook 1 'ipy-prompt-regexp)))
```

Normally it should *just work* for comint-derived shells.  Prompts are identified using `comint-prompt-regexp`.  Some comint-based modes do not configure this variable.  See `comint-fold-prompt-regexp` for configuring these. 

Some shells add an extra line or more before the prompt, and it can be nice to leave this line unhidden.  See `comint-fold-blank-lines`.  These two variables can be locally configured for a given mode at the same time by using the convenience function `comint-fold-configure-hook` to add to their hooks:

```elisp
(add-hook 'some-comint-derived-mode-hook
   (comint-fold-configure-hook num-extra-blanks 'prompt-regexp-var))
```
