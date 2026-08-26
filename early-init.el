;;; early-init.el --- Early startup config -*- lexical-binding: t; -*-

;;; Commentary:
;; Runs before package.el and the UI are initialized.  Kept small and
;; focused on startup speed, especially on Windows, where the default
;; `file-name-handler-alist' and subprocess IO settings are costly.

;;; Code:
(setq user-emacs-directory (expand-file-name "~/.emacs.d/"))
(setq package-user-dir (expand-file-name "elpa/" user-emacs-directory))
;; --- Garbage collection --------------------------------------------------
;; Raise the GC threshold to (near) infinity during startup so Emacs
;; doesn't pause to collect while loading packages.  `gcmh' (in init.el)
;; takes over with a sane idle-based policy once startup is done.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; --- file-name-handler-alist ----------------------------------------------
;; Consulted on every `require', `load', and file-path operation (TRAMP,
;; compressed files, etc).  Disabling it during startup and restoring it
;; afterward is one of the highest-leverage startup speedups, and it
;; matters more on Windows, where path handling is already slower.
(defvar my--file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 32 1024 1024)
                  gc-cons-percentage 0.1
                  file-name-handler-alist my--file-name-handler-alist)))

;; --- Windows-specific IO tuning --------------------------------------------
(when (eq system-type 'windows-nt)
  (setq w32-get-true-file-attributes nil    ; skip extra stat() calls
        w32-pipe-read-delay 0               ; don't sleep waiting on pipes
        w32-pipe-buffer-size (* 64 1024)))  ; bigger pipe buffer for LSP/git

;; Subprocesses (LSP servers, git, ripgrep) default to reading output in
;; tiny 4KB chunks.  1MB matches current recommendations and matters a lot
;; on Windows, where process IO is already the bottleneck.
(setq read-process-output-max (* 1024 1024))

;; --- Package system ---------------------------------------------------
;; init.el drives package.el + use-package explicitly, so skip
;; package.el's own startup scan here.
(setq package-enable-at-startup nil)

;; --- Native compilation -------------------------------------------------
;; Only takes effect on Emacs builds compiled with libgccjit support.
;; Harmless no-op otherwise (most stock Windows builds don't have it).
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-on-error nil
        native-comp-jit-compilation t)
  (startup-redirect-eln-cache
   (expand-file-name "eln-cache/" user-emacs-directory)))

(setq byte-compile-warnings nil
      warning-minimum-level :error)

;; --- UI: set frame parameters before the first frame is drawn -----------
;; Doing this in early-init avoids the visible flash/resize you get when
;; menu/tool/scroll bars are disabled later in init.el instead.
(push '(menu-bar-lines . 0)      default-frame-alist)
(push '(tool-bar-lines . 0)      default-frame-alist)
(push '(vertical-scroll-bars)    default-frame-alist)
(push '(horizontal-scroll-bars)  default-frame-alist)

(setq inhibit-startup-screen t
      ;; This only suppresses the echo-area message when set to your exact
      ;; username -- that's intentional Emacs behavior, not a typo.
      inhibit-startup-echo-area-message user-login-name
      frame-inhibit-implied-resize t
      frame-resize-pixelwise t
      inhibit-compacting-font-caches t)

;; UTF-8 everywhere (Windows likes to default to cp1252/cp437).
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(prefer-coding-system 'utf-8)

(provide 'early-init)
;;; early-init.el ends here
