;;; org.el --- Outline-based notes management and organizer -*- lexical-binding: t; -*-

;; Rafał's org-mode for keeping track of everything.
;; Copyright (C) 2017 Rafał Piątkowski
;;
;; Author: Rafał Piątkowski <crecca at krutt dot org>
;; Maintainer: Rafał Piątkowski <carsten at orgmode dot org>
;; Keywords: outlines, hypermedia, calendar, wp, org
;; Homepage: http://orgmode.org
;;
;; This file is NOT part of GNU Emacs.
;;
;;; Commentary:
;;
;; Eno is a free/libre personal information management system centered
;; around the idea of notes. It aims to help in getting the right
;; information at the right time, in the right place, in the right
;; form, and of sufficient completness and quality to perform the
;; current activity.
;;
;; Eno mode is a crucial part of Eno system, and is largely a
;; derivative of Emacs' Org mode.
;;
;; Development of Eno is in early alpha stage, although some of its
;; functionalities are already working.
;;
;; Installation and Activation
;; ---------------------------
;; See README at
;;
;;   https://github.com/crecca-krutt/eno-mode
;;
;; Documentation
;; -------------
;;
;; Not yet available, besides README file that comes with Eno
;; distribution available at
;;
;;    https://github.com/crecca-krutt/eno-mode

;; needed by `eno-version'
(require 'org-compat)

;; similar check is done by `org-mode'
(or (eq this-command 'eval-buffer)
    (condition-case nil
	(load (concat (file-name-directory load-file-name)
		      "eno-loaddefs.el")
	      nil t t t)
      (error
       (message "WARNING: No eno-loaddefs.el file could be found from where eno.el is loaded.")
       (sit-for 3)
       (message "You need to run \"make\" or \"make autoloads\" from Eno lisp directory")
       (sit-for 3))))

;;;###autoload
(defun eno-version (&optional here full message)
  "Show the Eno version. This function is a version of `org-version' for Eno.
Show interactively, or when MESSAGE is non-nil, show it in echo
area.  With prefix argument, or when HERE is non-nil, insert it
at point.  In non-interactive uses, a reduced version string is
output unless FULL is given."
  (interactive (list current-prefix-arg t (not current-prefix-arg)))
  (let ((org-dir (ignore-errors (org-find-library-dir "eno")))
	(save-load-suffixes (when (boundp 'load-suffixes) load-suffixes))
	(load-suffixes (list ".el"))
	(org-install-dir
	 (ignore-errors (org-find-library-dir "eno-loaddefs"))))
    (unless (and (fboundp 'eno-release) (fboundp 'eno-git-version))
      (org-load-noerror-mustsuffix (concat org-dir "eno-version")))
    (let* ((load-suffixes save-load-suffixes)
	   (release (eno-release))
	   (git-version "none")
	   (version (format "eno mode version %s (%s @ %s)"
			    release
			    git-version
			    (if org-install-dir
				(if (string= org-dir org-install-dir)
				    org-install-dir
				  (concat "mixed installation! "
					  org-install-dir
					  " and "
					  org-dir))
			      "eno-loaddefs.el can not be found!")))
	   (version1 (if full version release)))
      (when here (insert version1))
      (when message (message "%s" version1))
      version1)))

(defconst eno-version (eno-version))

;; Categories

(defvar eno-cat-tree nil
  "Plist where each key is a category existing in the system, and
  their values is a list of their direct subcategories, or a list
  of nil, if it has no subcategories.")

(defvar eno-cat-tree-reverse nil
  "Plist of categories and their parents.")

(defun eno-cat-path-to-list (cat)
  "Interpret string category path CAT, and return a list of
categories as symbols."
  (when cat
    (mapcar #'intern
	    (split-string cat "\\(/\\)"))))

;; rework of `eno-cat-get-create' (incomplete)
;; (defun eno-cat-get-create (catpath &optional parent)
;;   "Get a unique name of category given by string CATPATH. If
;; there is no such category on `eno-cat-tree', create it."
;;   (when (not (equal catpath ""))
;;     (let* ((catlist (if (consp catpath) catpath (eno-cat-path-to-list catpath)))
;; 	   (category (car catlist))
;; 	   (restpath (cdr catlist)))
;;       (if (not restpath)
;; 	  (cond ((plist-member eno-cat-tree category)
;; 		 (if (or (not parent) (eq (plist-get eno-cat-tree-reverse category) parent))
;; 		     category
;; 		   (eno-cat-get-create (concat (symbol-name parent) "-" (symbol-name category)) parent)))
;; 		(category (setq eno-cat-tree (plist-put eno-cat-tree category nil))
;; 			  (when parent (setq eno-cat-tree (plist-put eno-cat-tree parent (cons category (plist-get eno-cat-tree parent)))))
;; 		   (setq eno-cat-tree-reverse (plist-put eno-cat-tree-reverse category parent))
;; 		   category))
;; 	(eno-cat-get-create restpath (eno-cat-get-create (list category) parent))))))

(defun eno-cat-get-create (catstring)
  (eno-cat-get--create (krttk-get-category-path catstring)))

(defun eno-cat-get--create (catpath)
  "CATPATH is a relative category path"
  (when catpath				                                    ;I guess at some point this function will be called with empty path
    (let* ((cat (intern (car catpath)))                                     ;effective or parent cat
	   (child (if (cadr catpath) (intern (cadr catpath)) nil))          ;if cat is parent, child is the next cat on the path
	   (existing (plist-get eno-cat-tree cat))		    ;for checking if cat is already on the tree
	   (childuniq						            ;rename cat?
	    (if (and child (plist-member eno-cat-tree-reverse child) ;if there is a cat on the tree of the same name
		     (not (eq cat (plist-get eno-cat-tree-reverse child)))) ;and it has a different parent
		(intern (concat (symbol-name cat) "/" (symbol-name child))) ; cat must have a surname
	      child))			                                     ;otherwise, dont do anything with its name
	   ;; make a list of cats remaining on the path
	   (remain (if (and child (not (eq child childuniq))) ;if there is a child and its name was uniquified
		       (progn (pop catpath) (pop catpath) (push (symbol-name childuniq) catpath)) ;replace ("parent" "child"...) with
					;("parent/child"..) on the catpath
		     (cdr catpath))))
      (when (not (seq-contains (plist-get eno-cat-tree cat) childuniq))
	(setq eno-cat-tree
	      (plist-put eno-cat-tree cat
			 (if existing (and (push childuniq existing) (delq nil existing)) (list childuniq))))
	(setq eno-cat-tree-reverse
	      (plist-put eno-cat-tree-reverse childuniq cat)))
      (if remain (eno-cat-get--create remain) (or childuniq cat)))))


(defun eno-set-regexps-and-options (&optional tags-only)
  "Precompute regular expressions used in the current buffer.
When optional argument TAGS-ONLY is non-nil, only compute tags
related expressions."
  (when (derived-mode-p 'org-mode)
    (let ((alist (org--setup-collect-keywords
		  (org-make-options-regexp
		   (append '("FILETAGS" "TAGS" "SETUPFILE")
			   (and (not tags-only)
				'("ARCHIVE" "CATEGORY" "COLUMNS" "CONSTANTS"
				  "LINK" "OPTIONS" "PRIORITIES" "PROPERTY"
				  "SEQ_TODO" "STARTUP" "TODO" "TYP_TODO")))))))
      ;; Startup options.  Get this early since it does change
      ;; behavior for other options (e.g., tags).
      (let ((startup (cdr (assq 'startup alist))))
	(dolist (option startup)
	  (let ((entry (assoc-string option org-startup-options t)))
	    (when entry
	      (let ((var (nth 1 entry))
		    (val (nth 2 entry)))
		(if (not (nth 3 entry)) (set (make-local-variable var) val)
		  (unless (listp (symbol-value var))
		    (set (make-local-variable var) nil))
		  (add-to-list var val)))))))
      (setq-local org-file-tags
		  (mapcar #'org-add-prop-inherited
			  (cdr (assq 'filetags alist))))
      (setq org-current-tag-alist
	    (append org-tag-persistent-alist
		    (let ((tags (cdr (assq 'tags alist))))
		      (if tags (org-tag-string-to-alist tags)
			org-tag-alist))))
      (setq org-tag-groups-alist
	    (org-tag-alist-to-groups org-current-tag-alist))
      (unless tags-only
	;; File properties.
	(setq-local org-file-properties (cdr (assq 'property alist)))
	;; Archive location.
	(let ((archive (cdr (assq 'archive alist))))
	  (when archive (setq-local org-archive-location archive)))
	;; Category.
	(let ((cat (org-string-nw-p
		    (symbol-name (eno-cat-get-create (cdr (assq 'category alist)))))))
	  (when cat
	    (setq-local org-category (intern cat))
	    (setq-local org-file-properties
			(org--update-property-plist
			 "CATEGORY" cat org-file-properties))))
	;; Columns.
	(let ((column (cdr (assq 'columns alist))))
	  (when column (setq-local org-columns-default-format column)))
	;; Constants.
	(setq org-table-formula-constants-local (cdr (assq 'constants alist)))
	;; Link abbreviations.
	(let ((links (cdr (assq 'link alist))))
	  (when links (setq org-link-abbrev-alist-local (nreverse links))))
	;; Priorities.
	(let ((priorities (cdr (assq 'priorities alist))))
	  (when priorities
	    (setq-local org-highest-priority (nth 0 priorities))
	    (setq-local org-lowest-priority (nth 1 priorities))
	    (setq-local org-default-priority (nth 2 priorities))))
	;; Scripts.
	(let ((scripts (assq 'scripts alist)))
	  (when scripts
	    (setq-local org-use-sub-superscripts (cdr scripts))))
	;; TODO keywords.
	(setq-local org-todo-kwd-alist nil)
	(setq-local org-todo-key-alist nil)
	(setq-local org-todo-key-trigger nil)
	(setq-local org-todo-keywords-1 nil)
	(setq-local org-done-keywords nil)
	(setq-local org-todo-heads nil)
	(setq-local org-todo-sets nil)
	(setq-local org-todo-log-states nil)
	(let ((todo-sequences
	       (or (nreverse (cdr (assq 'todo alist)))
		   (let ((d (default-value 'org-todo-keywords)))
		     (if (not (stringp (car d))) d
		       ;; XXX: Backward compatibility code.
		       (list (cons org-todo-interpretation d)))))))
	  (dolist (sequence todo-sequences)
	    (let* ((sequence (or (run-hook-with-args-until-success
				  'org-todo-setup-filter-hook sequence)
				 sequence))
		   (sequence-type (car sequence))
		   (keywords (cdr sequence))
		   (sep (member "|" keywords))
		   names alist)
	      (dolist (k (remove "|" keywords))
		(unless (string-match "^\\(.*?\\)\\(?:(\\([^!@/]\\)?.*?)\\)?$"
				      k)
		  (error "Invalid TODO keyword %s" k))
		(let ((name (match-string 1 k))
		      (key (match-string 2 k))
		      (log (org-extract-log-state-settings k)))
		  (push name names)
		  (push (cons name (and key (string-to-char key))) alist)
		  (when log (push log org-todo-log-states))))
	      (let* ((names (nreverse names))
		     (done (if sep (org-remove-keyword-keys (cdr sep))
			     (last names)))
		     (head (car names))
		     (tail (list sequence-type head (car done) (org-last done))))
		(add-to-list 'org-todo-heads head 'append)
		(push names org-todo-sets)
		(setq org-done-keywords (append org-done-keywords done nil))
		(setq org-todo-keywords-1 (append org-todo-keywords-1 names nil))
		(setq org-todo-key-alist
		      (append org-todo-key-alist
			      (and alist
				   (append '((:startgroup))
					   (nreverse alist)
					   '((:endgroup))))))
		(dolist (k names) (push (cons k tail) org-todo-kwd-alist))))))
	(setq org-todo-sets (nreverse org-todo-sets)
	      org-todo-kwd-alist (nreverse org-todo-kwd-alist)
	      org-todo-key-trigger (delq nil (mapcar #'cdr org-todo-key-alist))
	      org-todo-key-alist (org-assign-fast-keys org-todo-key-alist))
	;; Compute the regular expressions and other local variables.
	;; Using `org-outline-regexp-bol' would complicate them much,
	;; because of the fixed white space at the end of that string.
	(unless org-done-keywords
	  (setq org-done-keywords
		(and org-todo-keywords-1 (last org-todo-keywords-1))))
	(setq org-not-done-keywords
	      (org-delete-all org-done-keywords
			      (copy-sequence org-todo-keywords-1))
	      org-todo-regexp (regexp-opt org-todo-keywords-1 t)
	      org-not-done-regexp (regexp-opt org-not-done-keywords t)
	      org-not-done-heading-regexp
	      (format org-heading-keyword-regexp-format org-not-done-regexp)
	      org-todo-line-regexp
	      (format org-heading-keyword-maybe-regexp-format org-todo-regexp)
	      org-complex-heading-regexp
	      (concat "^\\(\\*+\\)"
		      "\\(?: +" org-todo-regexp "\\)?"
		      "\\(?: +\\(\\[#.\\]\\)\\)?"
		      "\\(?: +\\(.*?\\)\\)??"
		      "\\(?:[ \t]+\\(:[[:alnum:]_@#%:]+:\\)\\)?"
		      "[ \t]*$")
	      org-complex-heading-regexp-format
	      (concat "^\\(\\*+\\)"
		      "\\(?: +" org-todo-regexp "\\)?"
		      "\\(?: +\\(\\[#.\\]\\)\\)?"
		      "\\(?: +"
		      ;; Stats cookies can be stuck to body.
		      "\\(?:\\[[0-9%%/]+\\] *\\)*"
		      "\\(%s\\)"
		      "\\(?: *\\[[0-9%%/]+\\]\\)*"
		      "\\)"
		      "\\(?:[ \t]+\\(:[[:alnum:]_@#%%:]+:\\)\\)?"
		      "[ \t]*$")
	      org-todo-line-tags-regexp
	      (concat "^\\(\\*+\\)"
		      "\\(?: +" org-todo-regexp "\\)?"
		      "\\(?: +\\(.*?\\)\\)??"
		      "\\(?:[ \t]+\\(:[[:alnum:]:_@#%]+:\\)\\)?"
		      "[ \t]*$"))
	(org-compute-latex-and-related-regexp)))))

(defun org-refresh-category-properties ()
  "Refresh category text properties in the buffer."
  (let ((case-fold-search t)
	(inhibit-read-only t)
	(default-category
	  (cond ((null org-category)
		 (if buffer-file-name
		     (file-name-sans-extension
		      (file-name-nondirectory buffer-file-name))
		   "???"))
		((symbolp org-category) (symbol-name org-category))
		(t org-category))))
    (org-with-silent-modifications
     (org-with-wide-buffer
      ;; Set buffer-wide category.  Search last #+CATEGORY keyword.
      ;; This is the default category for the buffer.  If none is
      ;; found, fall-back to `org-category' or buffer file name.
      (put-text-property
       (point-min) (point-max)
       'org-category
       (symbol-name
	(eno-cat-get-create
	 (catch 'buffer-category
	   (goto-char (point-max))
	   (while (re-search-backward "^[ \t]*#\\+CATEGORY:" (point-min) t)
	     (let ((element (org-element-at-point)))
	       (when (eq (org-element-type element) 'keyword)
		 (throw 'buffer-category
			(org-element-property :value element)))))
	   default-category))))
      ;; Set sub-tree specific categories.
      (goto-char (point-min))
      (let ((regexp (org-re-property "CATEGORY")))
	(while (re-search-forward regexp nil t)
	  (let ((value (symbol-name (eno-cat-get-create (match-string-no-properties 3)))))
	    (when (org-at-property-p)
	      (put-text-property
	       (save-excursion (org-back-to-heading t) (point))
	       (save-excursion (org-end-of-subtree t t) (point))
	       'org-category
	       value)))))))))

;; Category Clock Table

(defun eno-cat-get-toplevel ()
  "List all top-level categories."
  ;; category is top level if it's on the list `eno-category-tree', but not in any sublist of this list
  ;; in other words, it appears only once on the list
  ;; BUT! Maybe it makes sense to make `eno-cat-tree'... a tree?? no it doesn't, nesting of categories doesn't go very deep
    (let* ((all-cats nil) (subcats nil) (result nil))
      ;; get all cats
      (dolist (tree-cat eno-cat-tree)
	(when tree-cat
	  (if (not (listp tree-cat))
	      (push tree-cat all-cats)
	    (setq subcats (append subcats tree-cat)))))
      ;; for each cat
      (dolist (cat all-cats result)
	;; check if it's a child of any cat
	(when (not (member cat subcats))
	  (push cat result)))))

(defun eno-cat-to-fqcn (cat)
  "Get Fully Qualified Category Name from its shortened name"
  (when (and (intern cat) (plist-member eno-cat-tree (intern cat)))
    (let ((top-level (eno-cat-get-toplevel)))
      (if (member (intern (substring cat 0 (string-match "/" cat))) top-level)
	  cat
	(concat (eno-cat-to-fqcn
		 (symbol-name (plist-get
			       eno-cat-tree-reverse
			       (intern cat))))
		"/"
		(substring cat (1+ (or (string-match "/" cat) -1))))))))

(defun eno--cat-files-flat (files)
  "Takes a list of files and returns a sorted list of elements of the form:

  (FQ-CATEGORY FILENAME)"
    (let* (result temp (catfiles
	 (when (consp files)
	   (dolist (file files result)
;	     (setq current nil)
	     (with-current-buffer (find-buffer-visiting file)
	       (save-excursion
		 (save-restriction
		   (widen)
		   (let* ((pos (point-min))
			  (cat (get-text-property pos 'org-category))
			  (fqcat (when cat (intern (eno-cat-to-fqcn cat))))
			  (current (list fqcat)))
		     (push (cons fqcat file) result)
		     (goto-char pos)
		     (while (setq pos (next-single-property-change (point) 'org-category))
		       (goto-char pos)
		       (when (looking-at "^\\*")
			 (setq cat (get-text-property (point) 'org-category))
			 (when (and cat (not (member (setq fqcat (intern (eno-cat-to-fqcn cat))) current)))
			   (push fqcat current)
			   (push (cons fqcat file) result))))))))))))
      (sort catfiles (lambda (x y)
		       (string< (symbol-name (car x)) (symbol-name (car y)))))))

(defun krttk-get-category-path (cat)
  (when cat
    (let ((cats (split-string cat "\\(\\\\\\)\\|\\(/\\)")))
      (if (match-string 1)
	  (reverse cats)
	cats))))

(defun eno-cat-files (files)
  "Takes a list of files and returns a sorted list of lists
  called `sections', one list per top-level category. Those lists
  contain elements of the form:

  (FQ-CATEGORY FILENAME) or (FQ-CATEGORY (FILENAME1 FILENAME2...))"
  (org-agenda-prepare-buffers files)
  (mapcar #'eno-cat-consolidate-catfiles
	  (mapcar (lambda (x) (cdr x))
		  (seq-group-by (lambda (x)
				  (intern (car (eno-get-cat-path-new (symbol-name (car x))))))
				(eno--cat-files-flat files)))))

(defun eno-cat-consolidate-catfiles (catlist)
  (let (result)
    (while (cadr catlist)
      (let* ((first-catfile (car catlist))
	     (second-catfile (cadr catlist))
	     (first-catfile-cat (car first-catfile))
	     (second-catfile-cat (car second-catfile))
	     (first-catfile-file (if (consp (cdr first-catfile)) (cadr first-catfile) (cdr first-catfile)))
	     (second-catfile-file (cdr second-catfile)))
	(pop catlist)
	(if (equal first-catfile-cat second-catfile-cat)
	    (progn (pop catlist)
		   (push (list first-catfile-cat (cons second-catfile-file (if (consp first-catfile-file) first-catfile-file (list first-catfile-file)))) catlist))
	  (push first-catfile result))))
    (push (car catlist) result)
    (nreverse result)))

(defun org-dblock-write:catclocktable (params)
    "Write the standard clocktable."
    (setq params (org-combine-plists org-clocktable-defaults params))
    (catch 'exit
      (let* ((scope (plist-get params :scope))
	     (files (pcase scope
		      (`agenda
		       (org-agenda-files t))
		      (`agenda-with-archives
		       (org-add-archive-files (org-agenda-files t)))
		      (`file-with-archives
		       (and buffer-file-name
			    (org-add-archive-files (list buffer-file-name))))
		      ((pred functionp) (funcall scope))
		      ((pred consp) scope)
		      (_ (or (buffer-file-name) (current-buffer)))))
	     (catfiles (when (consp files) (eno-cat-files files)))
	     (block (plist-get params :block))
	     (ts (plist-get params :tstart))
	     (te (plist-get params :tend))
	     (ws (plist-get params :wstart))
	     (ms (plist-get params :mstart))
	     (step (plist-get params :step))
	     (formatter (or (plist-get params :formatter)
			    ;; org-clock-clocktable-formatter
			    'eno-cat-clocktable-write-default))
	     cc)
	;; Check if we need to do steps
	(when block
	  ;; Get the range text for the header
	  (setq cc (org-clock-special-range block nil t ws ms)
		ts (car cc)
		te (nth 1 cc)))
	(when step
	  ;; Write many tables, in steps
	  (unless (or block (and ts te))
	    (error "Clocktable `:step' can only be used with `:block' or `:tstart,:end'"))
	  (org-clocktable-steps params)
	  (throw 'exit nil))

	(org-agenda-prepare-buffers (if (consp files) files (list files)))

	(let ((origin (point))
	      (tables
	       (if (consp files)
		   (mapcar (lambda (catfile)
			     (eno--get-table-data-wrapper catfile params))
			   catfiles)
		 ;; Get the right restriction for the scope.
		 (save-restriction
		   (cond
		    ((not scope))	     ;use the restriction as it is now
		    ((eq scope 'file) (widen))
		    ((eq scope 'subtree) (org-narrow-to-subtree))
		    ((eq scope 'tree)
		     (while (org-up-heading-safe))
		     (org-narrow-to-subtree))
		    ((and (symbolp scope)
			  (string-match "\\`tree\\([0-9]+\\)\\'"
					(symbol-name scope)))
		     (let ((level (string-to-number
				   (match-string 1 (symbol-name scope)))))
		       (catch 'exit
			 (while (org-up-heading-safe)
			   (looking-at org-outline-regexp)
			   (when (<= (org-reduced-level (funcall outline-level))
				     level)
			     (throw 'exit nil))))
		       (org-narrow-to-subtree))))
		   (list (org-clock-get-table-data nil params)))))
	      (multifile
	       ;; Even though `file-with-archives' can consist of
	       ;; multiple files, we consider this is one extended file
	       ;; instead.
	       (and (consp files) (not (eq scope 'file-with-archives)))))

	  (funcall formatter
		   origin
		   tables
		   (org-combine-plists params `(:multifile ,multifile)))))))

;; some of the filtering functions need to be specified with a short
;; category name, so we provide a translating function

(defun eno-cat-fqcn-to-short (cat)
  "Translate Fully Qualified Category Name to its shortened
name. It doesn't check correctness of the whole path – only its
last component."
  (let ((cats (reverse (split-string (if (sequencep cat) cat (symbol-name cat)) "/")))
	(uniqcat nil) shortcat)
    (while (progn
	     (car cats)
	     (setq shortcat (intern (concat (pop cats) (when uniqcat (concat "/" uniqcat)))))
	     (if (plist-member eno-cat-tree shortcat)
		 (setq uniqcat (symbol-name shortcat))
	       (and (not uniqcat) (car cats)))))
    (if uniqcat
	(intern uniqcat)
      (error "No such category"))))

;; we will also often need to check whether a given category is
;; subcategory of another
(defun eno-cat> (cat1 &optional cat2)
  "return true if CAT2 is subcategory of CAT1. Return all
subcategories of category CAT1 if only one category is
specified."
  (let* ((interncat1 (if (stringp cat1) (intern cat1) cat1))
	 (interncat2 (if (stringp cat2) (intern cat2) cat2))
	 (subcats (-flatten (eno-cat-get-tree interncat1))))
    (if cat2 (member interncat2 subcats) subcats)))

;;; A note contributes to table if is:
;;; 1. Of section's category (type 3)
(defun eno-cat= (cat1 cat2)
  "return true if the same category. Categories should be FQCN."
  (let ((interncat1 (if (stringp cat1) (intern cat1) cat1))
	(interncat2 (if (stringp cat2) (intern cat2) cat2)))
    (eq interncat1 interncat2)))

;;; 2. Of any subcategory of section's category (type 4)
(defun eno-cat-get-tree (cat)
  "Get all subcategories of category CAT as a category tree."
  (let* (second-level (intcat (if (sequencep cat) (intern cat) cat)))
    (setq second-level (plist-get eno-cat-tree intcat))
    (if (not (car second-level))
	intcat
      (list intcat (mapcar #'eno-cat-get-tree second-level)))))

;; 3. Of supercategory of section's category, and has at least one
;;    descendant of section's category or its subcategory (type 5)
;;    This implies that a note of type 3 or type 4 follows it in the
;;    table
(defun eno-cat-ascending-tree (cat1 cat2)
  "Determines if heading at point should be included in a
category clock table section because of it being part of a path
to a note of section's category or subcategory."
  (let* ((icat1 (if (stringp cat1) (intern cat1) cat1))
	 (icat2 (if (stringp cat2) (intern cat2) cat2))
	 ;; we will need to look at the tree and see if it has any descendants of cat1 (section) or its subcategory
	 (subcats (-flatten (eno-cat-get-tree icat1))))
    (and (eno-cat> icat2 icat1)		;cat1 (section) is a subcategory of cat2 (note tree)
	 ;; now we need to find an appropriade descendant
	 ;; we need to look at each branch, at discard any branch that is not of category in subcats.
	 (save-excursion
	   (save-restriction
	     (org-narrow-to-subtree)
	     (while (progn
		      (goto-char (or (next-single-property-change (point) 'org-category) (point-max)))
		      ;; this is simplified, but should do the job
		      ;; it doesn't skip branches that are known to be invalid (for example mixed branches)
		      ;; if it becomes a problem it should be easy to change
		      (not (or (eq (point) (point-max)) (eno-cat> cat1 (get-text-property (point) 'org-category))))))
	     (unless (eq (point) (point-max)) t))))))

;; 4. Of any category, if it has at least one ancestor of section's
;;    category or its subcategory (type 6). This implies that a note
;;    of type 3 or type 4 preceeds it in the tree, and thus in the
;;    table.
(defun eno-cat-mixed-tree (cat1 cat2)
  "Return true if cat2 is not related to cat1, but the note at
point has ascendants that are a subcategory of cat1."
  (and (not (eno-cat> cat1 cat2))
       (save-excursion
	 (save-restriction
	   (while (progn
		    (org-up-heading-safe)
		    (not (or (eq (org-current-level) 1)
			     (eno-cat> cat1 (get-text-property (point) 'org-category))))))
	   (not (eq (org-current-level) 1))))))

(defun eno-cat-clock-table-matcher (section &optional plus)
  "Return true if note at point should contribute. If optional
PLUS argument is present, calculate times for the `Time+' column
in the category clock table. Otherwise calculate for the more
restrictive `Time' column."

  (let ((cat (get-text-property (point) 'org-category))
	(short-section (eno-cat-fqcn-to-short section)))
    ;; 1. Of section's category
    (or (eno-cat= section (eno-cat-to-fqcn cat))

	;; 2. Of any subcategory of section's category
	(eno-cat> short-section cat)

	;; 3. Of supercategory of section's category, and has at least
	;; one descendant of section's category or its subcategory
	(if plus (eno-cat-ascending-tree short-section cat))

	;; 4. Of any category, if it has at least one ancestor of
	;; section's category or its subcategory
	(if plus (eno-cat-mixed-tree short-section cat)))))

(defun eno-catclock-get-table-data (section params)
  "Get the clocktable data for file FILE, with parameters PARAMS.
FILE is only for identification - this function assumes that
the correct buffer is current, and that the wanted restriction is
in place.
The return value will be a list with the file name and the total
file time (in minutes) as 1st and 2nd elements.  The third element
of this list will be a list of headline entries.  Each entry has the
following structure:

  (LEVEL HEADLINE TIMESTAMP TIME PROPERTIES)

LEVEL:      The level of the headline, as an integer.  This will be
	    the reduced level, so 1,2,3,... even if only odd levels
	    are being used.
HEADLINE:   The text of the headline.  Depending on PARAMS, this may
	    already be formatted like a link.
TIMESTAMP:  If PARAMS require it, this will be a time stamp found in the
	    entry, any of SCHEDULED, DEADLINE, NORMAL, or first inactive,
	    in this sequence.
TIME:       The sum of all time spend in this tree, in minutes.  This time
	    will of cause be restricted to the time block and tags match
	    specified in PARAMS.
PROPERTIES: The list properties specified in the `:properties' parameter
	    along with their value, as an alist following the pattern
	    (NAME . VALUE)."
  (let* ((maxlevel (or (plist-get params :maxlevel) 3))
	 (timestamp (plist-get params :timestamp))
	 (catclock (equal "catclocktable" (plist-get params :name)))
	 (ts (plist-get params :tstart))
	 (te (plist-get params :tend))
	 (ws (plist-get params :wstart))
	 (ms (plist-get params :mstart))
	 (block (plist-get params :block))
	 (link (plist-get params :link))
	 (tags (plist-get params :tags))
	 (properties (plist-get params :properties))
	 (inherit-property-p (plist-get params :inherit-props))
	 (matcher (and tags (cdr (org-make-tags-matcher tags))))
	 cc st p tbl)

    (setq org-clock-file-total-minutes nil)
    (when block
      (setq cc (org-clock-special-range block nil t ws ms)
	    ts (car cc)
	    te (nth 1 cc)))
    (when (integerp ts) (setq ts (calendar-gregorian-from-absolute ts)))
    (when (integerp te) (setq te (calendar-gregorian-from-absolute te)))
    (when (and ts (listp ts))
      (setq ts (format "%4d-%02d-%02d" (nth 2 ts) (car ts) (nth 1 ts))))
    (when (and te (listp te))
      (setq te (format "%4d-%02d-%02d" (nth 2 te) (car te) (nth 1 te))))
    ;; Now the times are strings we can parse.
    (if ts (setq ts (org-matcher-time ts)))
    (if te (setq te (org-matcher-time te)))
    (save-excursion
      (org-clock-sum ts te
		     (if matcher
			 `(lambda ()
			    (let* ((tags-list (org-get-tags-at))
				   (org-scanner-tags tags-list)
				   (org-trust-scanner-tags t))
			      (funcall ,matcher nil tags-list nil)))
		       (if catclock
			   `(lambda()
			      (funcall 'eno-cat-clock-table-matcher section t))))
		     :eno-cat-clock-plus)
      (setq org-time-plus-total-minutes org-clock-file-total-minutes)
      (if catclock
	  (org-clock-sum ts te `(lambda() (funcall 'eno-cat-clock-table-matcher section)) :eno-cat-clock))
      (goto-char (point-min))
      (setq st t)
      (while (or (and (bobp) (prog1 st (setq st nil))
		      (get-text-property (point) :eno-cat-clock-plus)
		      (setq p (point-min)))
		 (setq p (next-single-property-change
			  (point) :eno-cat-clock-plus)))
	(goto-char p)
	(let ((time+ (get-text-property p :eno-cat-clock-plus)))
	  (when (and time+ (> time+ 0) (org-at-heading-p))
	    (let ((level (org-reduced-level (org-current-level))))
	      (when (<= level maxlevel)
		(let* ((headline (org-get-heading t t t t))
		       (hdl
			(if (not link) headline
			  (let ((search
				 (org-make-org-heading-search-string headline)))
			    (org-make-link-string
			     (if (not (buffer-file-name)) search
			       (format "file:%s::%s" (buffer-file-name) search))
			     ;; Prune statistics cookies.  Replace
			     ;; links with their description, or
			     ;; a plain link if there is none.
			     (org-trim
			      (org-link-display-format
			       (replace-regexp-in-string
				"\\[[0-9]+%\\]\\|\\[[0-9]+/[0-9]+\\]" ""
				headline)))))))
		       (tsp
			(and timestamp
			     (cl-some (lambda (p) (org-entry-get (point) p))
				      '("SCHEDULED" "DEADLINE" "TIMESTAMP"
					"TIMESTAMP_IA"))))
		       (time
			(get-text-property p :eno-cat-clock))
		       (category (symbol-name (eno-cat-get-create (org-entry-get (point) "CATEGORY" t))))
		       (type
			    (cond ((eno-cat= section (eno-cat-to-fqcn category)) 3)
				  ((eno-cat-ascending-tree (eno-cat-fqcn-to-short section) category) 5)
				  ((not (eno-cat> (eno-cat-fqcn-to-short section) category)) 6)
				  ((and (eno-cat> (eno-cat-fqcn-to-short section) category) (= (org-current-level) 1)) 4)
				  ((eno-cat> (eno-cat-fqcn-to-short section) category)
				   (save-excursion
				     (save-restriction
				       (if (and (org-up-heading-safe)
						(eno-cat= section (symbol-name (eno-cat-get-create (org-entry-get (point) "CATEGORY" t)))))
					   (if (and (org-goto-first-child) (org-goto-first-child)) 4 8)
					 7)))))))
		  (push (list level hdl tsp (or time 0) time+ category type) tbl)))))))
      (list section org-clock-file-total-minutes org-time-plus-total-minutes (nreverse tbl)))))

(defun eno--get-table-data-wrapper (catfiles params)
  "Create a multi-table for a top-level section (containing subsections)"
  ;; skip lets me peek into multi-tables until
  ;; I can implement displaying all of them
  (let ((start catfiles) result)
    (dolist (catfile catfiles result)
      (let ((rest start) (total-time 0) (total-time+ 0) checked-files total-table result-inner)
	(while (and rest (eno-cat> (eno-cat-fqcn-to-short (car catfile)) (eno-cat-fqcn-to-short (caar rest))))
	  (let* ((subcatfile (pop rest)) (sub-cat (car subcatfile)) (sub-file (cdr subcatfile)))
	    (if (consp sub-file)
		(dolist (file (car sub-file) result-inner)
		  (unless (member file checked-files)
		    (push file checked-files)
		    (with-current-buffer (find-buffer-visiting file)
		      (save-excursion
			(save-restriction
			  (push (eno-catclock-get-table-data (symbol-name (car catfile)) params) result-inner))))))
	      (unless (member sub-file checked-files)
		(push sub-file checked-files)
		(with-current-buffer (find-buffer-visiting sub-file)
		  (save-excursion
		    (save-restriction
		      (push (eno-catclock-get-table-data (symbol-name (car catfile)) params) result-inner))))))))
	(pcase-dolist (`(,cat-name ,cat-time ,cat-time+ ,table) result-inner)
	  (setq total-time (+ total-time cat-time))
	  (setq total-time+ (+ total-time+ cat-time+))
	  (setq total-table (append total-table table)))
	(push (list (car catfile) total-time total-time+ total-table) result))
      (pop start))
    (nreverse result)))

(defun eno-cat-clocktable-write-default (ipos tables params)
  "Write out a clock table at position IPOS in the current buffer.
TABLES is a list of tables with clocking data as produced by
`org-clock-get-table-data'.  PARAMS is the parameter property list obtained
from the dynamic block definition."
  ;; This function looks quite complicated, mainly because there are a
  ;; lot of options which can add or remove columns.  I have massively
  ;; commented this function, the I hope it is understandable.  If
  ;; someone wants to write their own special formatter, this maybe
  ;; much easier because there can be a fixed format with a
  ;; well-defined number of columns...
  (let* ((lang (or (plist-get params :lang) "en"))
	 (multifile (plist-get params :multifile))
	 (block (plist-get params :block))
	 (sort (plist-get params :sort))
	 (header (plist-get params :header))
	 (link (plist-get params :link))
	 (maxlevel (or (plist-get params :maxlevel) 3))
	 (emph (plist-get params :emphasize))
	 (compact? (plist-get params :compact))
	 (narrow (or (plist-get params :narrow) (and compact? '40!)))
	 (level? (and (not compact?) (plist-get params :level)))
	 (timestamp (plist-get params :timestamp))
	 (properties (plist-get params :properties))
	 (time-columns 1)
	 (indent (or compact? (plist-get params :indent)))
	 (formula (plist-get params :formula))
	 (case-fold-search t)
	 (total-time (apply #'+ (mapcar #'cl-cadar tables)))
	 recalc narrow-cut-p section-category)

    (when (and narrow (integerp narrow) link)
      ;; We cannot have both integer narrow and link.
      (message "Using hard narrowing in clocktable to allow for links")
      (setq narrow (intern (format "%d!" narrow))))

    (pcase narrow
      ((or `nil (pred integerp)) nil)	;nothing to do
      ((and (pred symbolp)
	    (guard (string-match-p "\\`[0-9]+!\\'" (symbol-name narrow))))
       (setq narrow-cut-p t)
       (setq narrow (string-to-number (symbol-name narrow))))
      (_ (error "Invalid value %s of :narrow property in clock table" narrow)))

    ;; Now we need to output this table stuff.
    (goto-char ipos)

    ;; Insert the text *before* the actual table.
    (insert-before-markers
     (or header
	 ;; Format the standard header.
	 (format "#+CAPTION: %s %s%s\n"
		 (org-clock--translate "Clock summary at" lang)
		 (format-time-string (org-time-stamp-format t t))
		 (if block
		     (let ((range-text
			    (nth 2 (org-clock-special-range
				    block nil t
				    (plist-get params :wstart)
				    (plist-get params :mstart)))))
		       (format ", for %s." range-text))
		   ""))))

    ;; Insert the narrowing line
    (when (and narrow (integerp narrow) (not narrow-cut-p))
      (insert-before-markers
       "|"				;table line starter
       (if multifile "|" "")		;file column, maybe
       (if level? "|" "")		;level column, maybe
       (if timestamp "|" "")		;timestamp column, maybe
       (if properties			;properties columns, maybe
	   (make-string (length properties) ?|)
	 "")
       (format "<%d>| |\n" narrow)))	;headline and time columns

    ;; Insert the table header line
    (insert-before-markers
     "|"				;table line starter
     (if multifile			;file column, maybe
	 (concat (org-clock--translate "File" lang) "|")
       "")
     (if level?				;level column, maybe
	 (concat (org-clock--translate "L" lang) "|")
       "")
     (if timestamp			;timestamp column, maybe
	 (concat (org-clock--translate "Timestamp" lang) "|")
       "")
     (if properties			;properties columns, maybe
	 (concat (mapconcat #'identity properties "|") "|")
       "")
     (concat (org-clock--translate "Headline" lang)"|")
     (concat (org-clock--translate "Time" lang) "|")
     (concat (org-clock--translate "Time" lang) "+" "|")
     (make-string (max 0 (1- time-columns)) ?|) ;other time columns
     (if (eq formula '%) "%|\n" "\n"))

    ;; Insert the total time in the table
    (insert-before-markers
     "|-\n"				;a hline
     "|"				;table line starter
     (if multifile (format "| %s " (org-clock--translate "ALL" lang)) "")
					;file column, maybe
     (if level? "|" "")			;level column, maybe
     (if timestamp "|" "")		;timestamp column, maybe
     (make-string (length properties) ?|) ;properties columns, maybe
     (concat (format org-clock-total-time-cell-format
		     (org-clock--translate "Total time" lang))
	     "| ")
     (format org-clock-total-time-cell-format
	     (org-duration-from-minutes (or total-time 0))) ;time
     "|"
     (make-string (max 0 (1- time-columns)) ?|)
     (cond ((not (eq formula '%)) "")
	   ((or (not total-time) (= total-time 0)) "0.0|")
	   (t  "100.0|"))
     "\n")

    ;; Now iterate over the tables and insert the data but only if any
    ;; time has been collected.
    (when (and total-time (> total-time 0))
      (dolist (table tables)
	(setq section-category (1- (eno-cat-get-level (caar table))))
	(pcase-dolist (`(,fqcategory ,file-time ,file-time+ ,entries) table)
	(when (or (and file-time+ (> file-time+ 0))
		  (not (plist-get params :fileskip0)))
	  (when (equal (caar table) fqcategory) (insert-before-markers "|-\n")) ;hline at new top-level section
	  ;; First the file time, if we have multiple files.
	  (when multifile
	    ;; Summarize the time collected from this file.
	    (insert-before-markers
	     (format (concat "| %s %s | %s%s"
			     (format org-clock-file-time-cell-format
				     "Category time")
			     " | *%s*| *%s*|\n")
		     (if compact?
			 (concat
			  (eno-cat-clocktable-indent-string (- (eno-cat-get-level fqcategory)
								 section-category))
			  (symbol-name (eno-cat-fqcn-to-short fqcategory)))
		       fqcategory)
		     (if level?   "| " "")  ;level column, maybe
		     (if timestamp "| " "") ;timestamp column, maybe
		     (if properties	    ;properties columns, maybe
			 (make-string (length properties) ?|)
		       "")
		     (org-duration-from-minutes file-time)
		     (org-duration-from-minutes file-time+)))) ;time

	  ;; Get the list of node entries and iterate over it
	  (when (> maxlevel 0)
	    (pcase-dolist (`(,level ,headline ,ts ,time ,time+ ,props ,type) entries)
	      (when (not (= type 7))
		(when  narrow-cut-p
		  (setq headline
			(if (and (string-match
				  (format "\\`%s\\'" org-bracket-link-regexp)
				  headline)
				 (match-end 3))
			    (format "[[%s][%s]]"
				    (match-string 1 headline)
				    (org-shorten-string (match-string 3 headline)
							narrow))
			  (org-shorten-string headline narrow))))
		(cl-flet ((format-field (f) (format (cond ((= type 6) "=%s= |")
							  ((= type 5) "~%s~ |")
							  (t "%s |"))
						    f)))
		  (insert-before-markers
		   "|"		       ;start the table line
		   (if multifile "|" "") ;free space for file name column?
		   (if level? (format "%s|" level) "") ;level, maybe
		   (if timestamp (concat ts "|") "")   ;timestamp, maybe
		   (if properties		;properties columns, maybe
		       (concat (mapconcat (lambda (p) (or (cdr (assoc p props)) ""))
					  properties
					  "|")
			       "|")
		     "")
		   (if indent		;indentation
		       (eno-cat-clocktable-indent-string level)
		     "")
		   (format-field (concat (when (= type 4) "> ") headline))
		   ;; Empty fields for higher levels.
		   (make-string (max 0 (1- (min time-columns level))) ?|)
		   (format-field (org-duration-from-minutes time))
		   (if (not (equal time time+)) (format-field (org-duration-from-minutes time+)) "")
		   (make-string (max 0 (- time-columns level)) ?|)
		   (if (eq formula '%)
		       (format "%.1f |" (* 100 (/ time (float total-time))))
		     "")
		   "\n")))))
	  (insert-before-markers "|\n"))))) ;empty line at the end of subsection
    (delete-char -1)
    (cond
     ;; Possibly rescue old formula?
     ((or (not formula) (eq formula '%))
      (let ((contents (org-string-nw-p (plist-get params :content))))
	(when (and contents (string-match "^\\([ \t]*#\\+tblfm:.*\\)" contents))
	  (setq recalc t)
	  (insert "\n" (match-string 1 contents))
	  (beginning-of-line 0))))
     ;; Insert specified formula line.
     ((stringp formula)
      (insert "\n#+TBLFM: " formula)
      (setq recalc t))
     (t
      (user-error "Invalid :formula parameter in clocktable")))
    ;; Back to beginning, align the table, recalculate if necessary.
    (goto-char ipos)
    (skip-chars-forward "^|")
    (org-table-align)
    (when org-hide-emphasis-markers
      ;; We need to align a second time.
      (org-table-align))
    (when sort
      (save-excursion
	(org-table-goto-line 3)
	(org-table-goto-column (car sort))
	(org-table-sort-lines nil (cdr sort))))
    (when recalc (org-table-recalculate 'all))
    total-time))

(defun eno-cat-clocktable-indent-string (level)
  "Return indentation string according to LEVEL.
LEVEL is an integer. Indent by two spaces per level above 1.
This is also used for indenting category names in category
column."
  (if (= level 1) ""
    (concat "  " (make-string (* 2 (- level 2)) ?\s))))

(defun eno-cat-get-level (cat)
  "Return level of category. CAT must be fully qualified category name."
  (let ((strcat (if (stringp cat) cat (symbol-name cat))))
    (length (eno-get-cat-path-new strcat))))

(defun eno-get-cat-path-new (cat)
  "There is also `eno-get-cat-path' but it breaks cat
clock tables for some reason, while being instrumental in other
cases. FIXME."
  (when cat
    (split-string cat "/")))

;;;###autoload
(define-derived-mode eno-mode org-mode "Eno"
  "Eno is a free/libre personal information management system
centered around the idea of notes. It aims to help in getting the
right information at the right time, in the right place, in the
right form, and of sufficient completness and quality to perform
the current activity. 

eno-mode is part of Eno, and is a slight modification of org-mode."
  (eno-set-regexps-and-options)
  (org-refresh-category-properties))

(provide 'eno)

(run-hooks 'eno-load-hook)

;;; eno.el ends here
