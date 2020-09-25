;;; delve-edit.el --- functions for remote editing org roam files  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  

;; Author:  <joerg@joergvolbers.de>
;; Keywords: convenience

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This is a library for "delve".

;;; Code:

;; * Dependencies:

(require 'org-element)
(require 'delve-db)
(require 'org-roam)

;; * Global Variables

(defvar delve-roam-tag-history nil
  "History of selected tags for remote editing of org roam files.")


;; TODO
;; Bug: "Value" enthält VIELE Tags, und BEGIN und END beziehen
;; sich auf die Gesamtzeile. Das ist gut for "new pose" und solte
;; daher auch so in eine Funktion gelegt werden.
;; Aber für das Holen der existierenden Tags ist das natürlich
;; Schwachsinn. Da nocht "splitten".

;; TODO
;; Diese ganzen sachen auslagern in "delve-edit", und mit tests
;; versehen


;; NEU angefügt
(defun delve-edit-tags-first-eol (org-tree)
  "Get end position of the first roam tag in ORG-TREE."
  (let (end)
    (org-element-map org-tree 'keyword
      (lambda (key)
	(when (and
	       (eq (org-element-type (org-element-property :parent key)) 'section)
	       (string= (org-element-property :key key) "ROAM_TAGS"))
	  (unless end
	    (setq end (org-element-property :end key))))))
    end))

;; GEÄNDERT, aufrufende Funktionen sind noch nicht angepasst
(defun delve-edit-parsed-tags (org-tree)
  "Return all ROAM_TAGs in ORG-TREE."
  (let ((tags ""))
    (org-element-map org-tree 'keyword
      (lambda (key)
	(when (and (eq (org-element-type (org-element-property :parent key)) 'section)
		   (string= (org-element-property :key key) "ROAM_TAGS"))
	  (setq tags (concat tags (org-element-property :value key))))))
    (unless (string-empty-p tags)
      (split-string tags " " t t))))

(defun delve-edit-parsed-title-end (org-tree)
  "Return the position after the TITLE keyword."
  (car 
   (org-element-map org-tree 'keyword
     (lambda (key)
       (when (string= (org-element-property :key key) "TITLE")
	 (org-element-property :end key))))))

(defun delve-edit-unused-tags (org-tree)
  "Return all tags known to the db, but not found in ORG-TREE."
  (let* ((buf-tags (mapcar (lambda (l) (plist-get l :value))
			   (delve-edit-parsed-tags org-tree)))
	 (db-tags  (delve-db-plain-roam-tags)))
    (cl-set-difference db-tags buf-tags :test #'string=)))

(defun delve-edit-do-add-tag (buf org-tree tag)
  "Add TAG as roam tag in BUF, using ORG-TREE."
  (with-current-buffer buf
    (let* ((existing-tags (delve-edit-parsed-tags org-tree))
	   (one-more-pos  (plist-get (car existing-tags) :end))
	   (new-keyword   (unless one-more-pos
			  (or (delve-edit-parsed-title-end org-tree)
			      (point-min)))))
      (goto-char (or new-keyword (1- one-more-pos)))
      (when new-keyword
	(insert "#+ROAM_TAGS:"))
      (insert " ")
      (insert (string-trim tag))
      (when new-keyword
	(insert "\n")))))

(defun delve-edit-do-remove-tag (buf org-tree tag)
  "Remove roam tags matching TAGS from BUF, using ORG-TREE."
  (with-current-buffer buf
    (let* ((existing-tags   (delve-edit-parsed-tags org-tree))
	   (tag-2b-removed  (car
			     (cl-member tag existing-tags
				      :test #'string=
				      :key (lambda (it)
					     (plist-get it :value))))))
      (unless tag-2b-removed
	(error "Tag not in use"))
      
      (delete-region (plist-get tag-2b-removed :begin)
		     (plist-get tag-2b-removed :end)))))

(defun delve-edit-prompt-add-tag (zettel)
  "Interactively add a tag to ZETTEL."
  (interactive (list buffer-file-name))
  (unless (org-roam--org-roam-file-p zettel)
    (error "File not an org roam file"))
  (let* ((loaded-p (get-file-buffer zettel))
	 (buf      (or loaded-p (find-file-noselect zettel))))
    (with-current-buffer buf
      (when (buffer-modified-p)
	(save-buffer))
      (let* ((org-tree (org-element-parse-buffer))
	     (new-tag (completing-read "Select tag to add: "
				       (delve-edit-unused-tags org-tree))))
	(delve-edit-do-add-tag buf org-tree new-tag)
	(save-buffer)))
    (unless loaded-p
      (kill-buffer buf))))

(defun delve-edit-prompt-remove-tag (zettel)
  "Interactively remove a tag from ZETTEL."
  (interactive (list buffer-file-name))
  (unless (org-roam--org-roam-file-p zettel)
    (error "File not an org roam file"))
  (let* ((loaded-p (get-file-buffer zettel))
	 (buf      (or loaded-p (find-file-noselect zettel))))
    (with-current-buffer buf
      (when (buffer-modified-p)
	(save-buffer))
      )))
  
    


(provide 'delve-edit)
;;; delve-edit.el ends here
