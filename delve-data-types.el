;;; delve-data-types.el --- data types for the delve tool  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  

;; Author:  <joerg@joergvolbers.de>
;; Keywords: 

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

;;; Code:

(require 'cl-lib)

;; * Item data types

(cl-defstruct (delve-tag (:constructor delve-make-tag))
  tag
  count)

(cl-defstruct (delve-generic (:constructor delve-make-generic))
  title
  file
  tags
  mtime
  atime
  backlinks
  tolinks)

(cl-defstruct (delve-zettel
	       (:constructor delve-make-zettel)
	       (:include delve-generic)))

(cl-defstruct (delve-tolink 
	       (:constructor delve-make-tolink)
	       (:include delve-generic)))

(cl-defstruct (delve-backlink
	       (:constructor delve-make-backlink)
	       (:include delve-generic)))

;; Searches

(cl-defstruct (delve-generic-search (:constructor delve-make-search))
  name
  with-clause
  constraint
  args
  postprocess
  result-subtype)

(cl-defstruct (delve-search-for-zettel
	       (:constructor delve-make-search-for-zettel)
	       (:include delve-generic-search
			 (result-subtype 'delve-zettel))))

(provide 'delve-data-types)
;;; delve-data-types.el ends here
