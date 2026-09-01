;; init.el --- Personal config -*- lexical-binding: t; -*-

;;; Commentary:
;; Barebones, Windows-tuned Emacs config: Doom-style evil + SPC-leader
;; keybindings, Org with org-modern (no bare asterisks), and Denote for
;; notes.  Uses stock package.el + use-package rather than straight.el,
;; specifically to avoid straight's symlink requirement, which needs
;; Developer Mode or admin rights on Windows.
;;
;; This is NOT a clone of Doom's full keybinding set (that's ~2000
;; bindings across dozens of modules) -- it covers the muscle-memory
;; ones: SPC f/b/w/p/g/s/n/o/t/q.  Extend the `my/leader' block below
;; as you find gaps.

;;; Code:
(setq package-check-signature nil)
;; ===========================================================================
;; Package management
;; ===========================================================================

(require 'package)
(setq package-archives
      '(("gnu"    . "https://elpa.gnu.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("melpa"  . "https://melpa.org/packages/"))
      package-archive-priorities
      '(("gnu" . 3) ("nongnu" . 2) ("melpa" . 1)))

(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t
      use-package-verbose nil
      use-package-expand-minimally t)

;; Smarter GC after startup: park at a high threshold while idle, drop it
;; while you're actively typing so collections stay small and unnoticeable.
(use-package gcmh
  :init (setq gcmh-idle-delay 5
              gcmh-high-cons-threshold (* 64 1024 1024))
  :config (gcmh-mode 1))

;; ===========================================================================
;; Sane defaults
;; ===========================================================================

(setq-default tab-width 4
              indent-tabs-mode nil
              fill-column 80)

(setq inhibit-startup-message t
      initial-scratch-message nil
      ring-bell-function 'ignore
      visible-bell nil
      scroll-margin 2
      scroll-conservatively 101
      scroll-preserve-screen-position t
      create-lockfiles nil
      make-backup-files nil
      auto-save-default nil
      use-short-answers t
      confirm-kill-emacs 'y-or-n-p)

(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t)
(global-so-long-mode 1)           ; degrade gracefully on minified/huge files
(electric-pair-mode 1)
(show-paren-mode 1)
(recentf-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(setq recentf-max-saved-items 200)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Windows-specific: keep backups/autosaves/history/etc in one cache folder
;; instead of scattering "~" and "#" files next to your source. On Windows
;; this also avoids OneDrive re-sync churn if your config or projects live
;; in a synced folder.
(let ((cache-dir (expand-file-name "cache/" user-emacs-directory)))
  (make-directory cache-dir t)
  (setq recentf-save-file (expand-file-name "recentf" cache-dir)
        savehist-file (expand-file-name "history" cache-dir)
        save-place-file (expand-file-name "places" cache-dir)
        auto-save-list-file-prefix (expand-file-name "auto-save-list/" cache-dir)))

;; If Cascadia Code (ships with Windows Terminal) or JetBrains Mono is
;; installed, use it -- both render org-modern's bullets/box glyphs cleanly.
(cond
 ((member "Cascadia Code" (font-family-list))
  (set-face-attribute 'default nil :font "Cascadia Code-11"))
 ((member "JetBrains Mono" (font-family-list))
  (set-face-attribute 'default nil :font "JetBrains Mono-11")))

;; ===========================================================================
;; UI
;; ===========================================================================

(use-package doom-themes
  :config
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t)
  (load-theme 'doom-material-dark t)
  (doom-themes-visual-bell-config)
  (doom-themes-org-config))

(use-package nerd-icons)
;; First run only: `M-x nerd-icons-install-fonts' downloads and installs
;; the icon font. Do this once, then restart Emacs.

(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :init (setq doom-modeline-height 25
              doom-modeline-icon t))

;; ===========================================================================
;; Minibuffer completion (Vertico stack -- the current Doom default)
;; ===========================================================================

(use-package vertico
  :init (vertico-mode 1)
  :custom (vertico-cycle t))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :init (marginalia-mode 1))

(use-package consult
  :bind (([remap switch-to-buffer]  . consult-buffer)
         ([remap goto-line]         . consult-goto-line)
         ([remap yank-pop]          . consult-yank-pop)))

(use-package embark
  :bind ("C-." . embark-act))

(use-package embark-consult
  :after (embark consult))

;; ===========================================================================
;; Evil + Doom-style keybindings
;; ===========================================================================

(use-package evil
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil   ; let evil-collection handle it
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil
        evil-respect-visual-line-mode t
        evil-undo-system 'undo-redo
        evil-search-module 'evil-search)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :init (setq evil-collection-want-find-usages-bindings t)
  :config (evil-collection-init))
(use-package evil-org
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(use-package general
  :after evil
  :config
  ;; SPC is the leader in normal/visual/motion states; M-SPC reaches it
  ;; from insert/emacs state without eating a literal space.
  (general-create-definer my/leader
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC"
    :non-normal-prefix "M-SPC")

  ;; Doom's "localleader", for major-mode-specific commands (mainly org).
  (general-create-definer my/local-leader
    :states '(normal visual motion insert emacs)
    :keymaps 'override
    :prefix "SPC m"
    :non-normal-prefix "M-SPC m")

  (general-def 'normal "SPC w" evil-window-map)
 
  (my/leader
    "SPC" '(find-file :wk "Find file")
    ":"   '(execute-extended-command :wk "M-x")
    ";"   '(pp-eval-expression :wk "Eval expression")

    "f"   '(:ignore t :wk "file")
    "f f" '(find-file :wk "Find file")
    "f s" '(save-buffer :wk "Save file")
    "f r" '(consult-recent-file :wk "Recent files")
    "f d" '(dired :wk "Dired")
    "f e" '((lambda () (interactive) (find-file user-init-file)) :wk "Edit init.el")

    "b"   '(:ignore t :wk "buffer")
    "b b" '(consult-buffer :wk "Switch buffer")
    "b n" '(next-buffer :wk "Next buffer")
    "b p" '(previous-buffer :wk "Previous buffer")
    "b d" '(kill-current-buffer :wk "Kill buffer")
    "b r" '(revert-buffer :wk "Revert buffer")

    "p"   '(:ignore t :wk "project")
    "p p" '(project-switch-project :wk "Switch project")
    "p f" '(project-find-file :wk "Find file in project")
    "p g" '(project-find-regexp :wk "Grep in project")
    "p b" '(project-switch-to-buffer :wk "Switch buffer in project")

    "g"   '(:ignore t :wk "git")
    "g g" '(magit-status :wk "Magit status")

    "s"   '(:ignore t :wk "search")
    "s s" '(consult-line :wk "Search buffer")
    "s g" '(consult-ripgrep :wk "Grep (ripgrep)")
    "s d" '(consult-fd :wk "Find file (fd)")

    "j"   '(:ignore t :wk "jump")
    "j j" '(avy-goto-char-timer :wk "Jump to char")
    "j l" '(avy-goto-line :wk "Jump to line")

    "n"   '(:ignore t :wk "notes")
    "n n" '(org-toggle-narrow-to-subtree :wk "Toggle Narrow/Widen")
    "n f" '(org-roam-node-find :wk "Find/create note")
    "n i" '(org-roam-node-insert :wk "Insert link to note")
    "n I" '(org-id-get-create :wk "Create ID")
    "n b" '(org-roam-buffer-toggle :wk "Show backlinks")
    "n B" '(org-roam-buffer-display-dedicated :wk "Show dedicated Backlinks")
    "n r" '(org-refile :wk "Refile Tree")
    "n d" '(:ignore t :wk "date")
    "n d t" '(org-timestamp-inactive :wk "Timestamp inactive")
    "n d T" '(org-timestamp :wk "Timestamp")
    "n e" '(org-export-dispatch :wk "Export Current Selection")
    "n t" '(org-todo :wk "Insert TODO at point")

    "o"   '(:ignore t :wk "open")
    "o a" '(org-agenda :wk "Agenda")
    "o c" '(org-capture :wk "Capture")

    "t"   '(:ignore t :wk "toggle")
    "t l" '(display-line-numbers-mode :wk "Line numbers")
    "t w" '(visual-line-mode :wk "Visual line wrap")
    "t t" '(consult-theme :wk "Theme")
    "t o" '(olivetti-mode :wk "Olivetti mode")

    "h"   '(:ignore t :wk "help")
    "h f" '(describe-function :wk "Describe function")
    "h v" '(describe-variable :wk "Describe variable")
    "h k" '(describe-key :wk "Describe key")

    "q"   '(:ignore t :wk "quit")
    "q q" '(save-buffers-kill-terminal :wk "Quit Emacs")
    "q r" '(restart-emacs :wk "Restart Emacs")))

(define-key evil-insert-state-map(kbd "C-g") 'evil-normal-state)

(use-package which-key
  :init (setq which-key-idle-delay 0.3)
  :config (which-key-mode 1))

(use-package avy
  :commands (avy-goto-char-timer avy-goto-line))

(use-package restart-emacs
  :commands restart-emacs)

(use-package olivetti
  :commands olivetti-mode)

;; ===========================================================================
;; Project + git
;; ===========================================================================

;; `project.el' is built in (Emacs 28+) -- lighter than projectile, and
;; one less thing to install/index on Windows.
(require 'project)

(use-package magit
  :commands magit-status)
;; Note: Magit shells out to git for most operations, so on Windows its
;; snappiness is mostly bounded by how fast Git for Windows spawns
;; processes -- not much to tune from the Emacs side beyond that.

;; ===========================================================================
;; Org
;; ===========================================================================

;; Uses whatever Org ships with your Emacs build rather than forcing a
;; second copy from GNU ELPA. On most builds -- especially recent or
;; native-comp ones -- the bundled Org is already new enough for
;; org-modern, and installing a second copy on top causes a "mixed Org
;; versions" conflict: folding still works, but font-lock/highlighting
;; breaks and `org-mode' can throw `wrong-type-argument: sequencep, t'.
;; If `M-x org-version' ever shows a path under `elpa/org-9.x' instead
;; of your Emacs install directory, that's this conflict -- run
;; `M-x package-delete RET org RET' and restart to clear it.
(use-package org
  :ensure nil
  :custom
  (org-directory "~/Org/")
  (org-agenda-files (list org-directory))
  (org-id-track-globally t)
  (org-id-locations-file(expand-file-name ".orgids" org-directory))
  (org-ellipsis "▾")
  (org-refile-targets '((nil :maxlevel . 9)
                        (org-agenda-files :maxlevel . 9)))
  (org-refile-use-outline-path 'file)
  (org-outline-path-complete-in-steps nil)
  (org-hide-emphasis-markers t)     ; hide the *bold*/_underline_ markers
  (org-pretty-entities t)
  (org-startup-indented t)
  (org-startup-folded 'content)
  (org-adapt-indentation nil)
  (org-src-tab-acts-natively t)
  (org-edit-src-content-indentation 0)
  (org-fontify-quote-and-verse-blocks t)
  (org-fontify-whole-heading-line t)
  (org-todo-keywords
   '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
     (sequence "WAIT(w)" "|" "CANCELLED(c)")))
  (org-capture-templates
   '(("t" "Todo" entry
      (file+headline (lambda () (expand-file-name "notes.org" org-directory)) "Inbox")
      "* TODO %?\n%U\n%a" :empty-lines 1)))
  (org-return-follows-link t))
(with-eval-after-load 'evil-maps
  (define-key evil-motion-state-map (kbd "RET") nil)
  (define-key evil-normal-state-map (kbd "RET") 'org-return))
(with-eval-after-load 'org
  (require 'org-id))
(add-hook 'org-mode-hook 'visual-line-mode)
;; Reveals raw markup (*, _, [[links]]) only around point, and hides it
;; again everywhere else -- the pairing that makes `org-hide-emphasis-markers'
;; livable, since you can still edit the markup when your cursor is on it.
(use-package org-appear
  :hook (org-mode . org-appear-mode)
  :custom
  (org-appear-autoemphasis t)
  (org-appear-autolinks t)
  (org-appear-autosubmarkers t))

;; The actual "no bunch of damn asterisks" package: replaces heading stars
;; with clean bullets, and re-styles tables/checkboxes/priorities/blocks.
(use-package org-modern
  :after org
  :config (global-org-modern-mode 1)
  :hook ((org-mode . org-modern-mode)
         (org-agenda-finalize . org-modern-agenda))
  :custom
  (org-modern-star '("◉" "○" "●" "◦" "◆" "◇"))
  (org-modern-hide-stars t)
  (org-modern-table-vertical 1)
  (org-modern-table-horizontal 0.2)
  (org-modern-list '((?- . "•") (?+ . "◦"))))

;; --- Alternative: org-roam instead of Denote -------------------------------
;; If you try Denote and end up wanting org-roam's graph/backlink buffer
;; instead, delete the `denote' and `consult-notes' blocks above and use
;; this. Emacs 29+ ships a built-in SQLite (`sqlite-builtin'), so unlike
;; older guides you don't need a C compiler on Windows to build emacsql.
;;
 (use-package org-roam
   :after org
   :custom
   (org-roam-directory (expand-file-name "~/Org/"))
   (org-roam-database-connector 'sqlite-builtin)
   :config
   (org-roam-db-autosync-mode 1)
   (setq org-id-extra-files (directory-files-recursively org-roam-directory "\\.org$")))

(add-to-list 'display-buffer-alist
             '(\\"*org-roam\\"
               (display-buffer-in-side-window)
               (side . right)
               (window-widgth . 0.33)
               (window-parameters . ((no-other-window . t)
                                     (no-delete other-windows . t)))))

(with-eval-after-load 'org-roam
  (set-face-attribute 'org-roam-olp nil :foreground "#61afef"))

(setq org-roam-capture-templates
      '(("d" "default" plain "%?"
         :if-new (file+head "${slug}.org"
                            "#+title: ${title}\n")
         :unnarrowed t)))

(provide 'init)
;;; init.el ends here
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(org-agenda-files
   '("~/Org/notes.org" "c:/Users/Ben Galloway/Org/Dystopia.org"
     "c:/Users/Ben Galloway/Org/chain_vs_circle.org"
     "c:/Users/Ben Galloway/Org/dear diary.org"
     "c:/Users/Ben Galloway/Org/grit.org"
     "c:/Users/Ben Galloway/Org/paradigms.org"
     "c:/Users/Ben Galloway/Org/personal.org"
     "c:/Users/Ben Galloway/Org/range.org"
     "c:/Users/Ben Galloway/Org/shouting_into_the_void_lessons_from_a_space_opera.org") nil nil "Customized with use-package org")
 '(package-selected-packages nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
