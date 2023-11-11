;;; comint-fold-.el --- Fold comint-input -*- lexical-binding: t; -*-
;; Copyright (C) 2023  J.D. Smith

;; Author: J.D. Smith
;; Homepage: https://github.com/jdtsmith/comint-fold
;; Package-Requires: ((emacs "27.1") (compat "29.1.4.3"))
;; Version: 0.0.1
;; Keywords: convenience
;; Prefix: comint-fold
;; Separator: -

;; comint-fold is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; comint-fold is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; comint-fold configures hideshow mode to fold comint input + output
;; blocks, optionally binding the Tab key to fold such blocks prior
;; to the prompt, and with a fringe indicator for folded blocks.

;; Configuration:
;; 
;; Normally, `comint-prompt-regexp' is used to identify the input
;; prompts, but this can be altered; see `comint-fold-prompt-regexp'.
;; In addition, blank lines prior to the prompt can be preserved
;; outside of the hidden block; see `comint-fold-blank-lines'.  The
;; easiest way to configure these variables locally for some comint
;; mode is to add the lambda returned by `comint-fold-configure-hook'
;; to the relevant mode hook.

;;; Code:
;;;; Requires
(require 'hideshow)
(require 'comint)

;;;; Customization
(defgroup comint-fold nil
  "Fold comint input."
  :group 'comint
  :prefix "comint-fold-")

(defcustom comint-fold-prompt-regexp nil
  "Prompt regexp, anchored to line beginning.
Defaults to the value of `comint-prompt-regexp', if
`comint-use-prompt-regexp' is non-nil."
  :local t
  :type '(choice (const :tag "Use default" nil)
		 (regexp :tag "Prompt regexp"))
  :group 'comint-fold)

(defcustom comint-fold-blank-lines 0
  "Blank lines prior to the prompt to preserve outside the hidden block."
  :local t
  :type 'integer
  :group 'comint-fold)

(defcustom comint-fold-fringe-indicator 'top-left-angle
  "If non-nil, indicate folded blocks in the fringe with this bitmap."
  :type 'symbol
  :group 'comint-fold)

(defcustom comint-fold-remap-tab t
  "Remap the tab key to fold blocks prior to the current prompt."
  :type 'boolean
  :group 'comint-fold)

;;;; Folding
(defun comint-fold-looking-at-block-p ()
  "Return t if looking at a foldable block.
Note that the current input prompt (which has no subsequent
prompts) is not a valid block for folding."
  (and (hs-looking-at-block-start-p)
       (save-excursion
	 (goto-char (match-end 0))
	 (when (< (line-end-position) (comint-next-prompt 1))
	   (forward-line 0)
	   (looking-at-p hs-block-start-regexp)))))

(defun comint-fold-forward-sexp (n)
  "Move forward to the N'th input past this line."
  (end-of-line)
  (comint-next-prompt n))

(defun comint-fold-do-fold (&optional arg)
  "Toggle block fold, if point is before the process mark.
ARG is passed to `indent-for-tab-command' otherwise."
  (interactive "P")
  (let ((proc (get-buffer-process (current-buffer))))
    (if (or (not proc) (< (point) (process-mark proc)))
	(hs-toggle-hiding)
      (indent-for-tab-command arg))))

(defun comint-fold-overlay-fringe (ov)
  "Add fringe indicator to the hideshow overlay OV.
Enabled if `comint-fold-fringe-indicator' is non-nil."
  (overlay-put ov 'before-string
	       (propertize "*" 'display
			   `(left-fringe
			     ,comint-fold-fringe-indicator
			     (face :foreground
				   ,(face-background 'highlight))))))

;;;; Setup
;;;###autoload
(defun comint-fold-configure-hook (lines &optional prompt-regexp)
  "Return a lambda which configures comint-fold variables locally.
LINES, if non-nil is an integer used to set the custom variable
`comint-fold-blank-lines' locally, and PROMPT-REGEXP is either a
string or a symbol whose value is used when the lambda is called
to configure `comint-fold-prompt-regexp'.  Useful when
configuring comint-fold in specific mode hooks, if necessary."
  (lambda ()
    (when lines
      (setq-local comint-fold-blank-lines lines))
    (when prompt-regexp
      (setq-local comint-fold-prompt-regexp
		  (if (symbolp prompt-regexp)
		      (symbol-value prompt-regexp)
		    prompt-regexp)))))

(defun comint-fold-setup ()
  "Setup folding for the local comint mode.
This is placed on the `after-change-major-mode-hook'."
  (when (derived-mode-p 'comint-mode)
    (if-let ((re (or comint-fold-prompt-regexp comint-prompt-regexp)))
	(let ((re-end (rx-to-string `(and (= ,(1+ comint-fold-blank-lines) ?\n)
					  (regexp ,re))))
	      (comment-start (or comment-start "# "))) ; HS needs this
	  (setf (alist-get major-mode hs-special-modes-alist)
		(list re re-end comment-start #'comint-fold-forward-sexp
		      nil nil nil #'comint-fold-looking-at-block-p))
	  (hs-minor-mode 1)
	  (setq-local hs-hide-comments-when-hiding-all nil)
	  (when comint-fold-remap-tab
	    (define-key (current-local-map) (kbd "<tab>")
			#'comint-fold-do-fold))
	  (when comint-fold-fringe-indicator
	    (setq-local hs-set-up-overlay #'comint-fold-overlay-fringe))
	  (hs-grok-mode-type))
      (warn "No prompt regexp defined for %S, set `comint-fold-prompt-regexp' locally"
	    major-mode))))

(defvar comint-fold-mode)
;;;###autoload
(define-minor-mode comint-fold-mode
  "Fold input/output in comint modes."
  :global t
  :group 'comint-fold
  (if comint-fold-mode
      ;; We put this on the after-change-major-mode-hook so normal
      ;; derived mode hooks (e.g. python-mode) can be used to
      ;; pre-configure comint-fold variables in advance of setup.
      (add-hook 'after-change-major-mode-hook #'comint-fold-setup)
    (remove-hook 'after-change-major-mode-hook #'comint-fold-setup)))

(provide 'comint-fold)
;;; comint-fold.el ends here
