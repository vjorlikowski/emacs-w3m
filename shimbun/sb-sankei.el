;;; sb-sankei.el --- shimbun backend for the Sankei News

;; Copyright (C) 2003-2011, 2013-2019, 2021 Katsumi Yamaoka

;; Author: Katsumi Yamaoka <yamaoka@jpl.org>
;; Keywords: news

;; This file is a part of shimbun.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'shimbun)

(luna-define-class shimbun-sankei (shimbun-japanese-newspaper shimbun) ())

(defvar shimbun-sankei-url "https://www.sankei.com/")

(defvar shimbun-sankei-top-level-domain "www.sankei.com")

(defvar shimbun-sankei-server-name "産経ニュース")

(defvar shimbun-sankei-group-table
  '(("top" "ニュース"
     "https://www.sankei.com/")
    ("flash" "速報"
     "https://www.sankei.com/flash/")
    ("affairs" "社会"
     "https://www.sankei.com/affairs/")
    ("politics" "政治"
     "https://www.sankei.com/politics/")
    ("world" "国際"
     "https://www.sankei.com/world/")
    ("economy" "経済"
     "https://www.sankei.com/economy/")
    ("sports" "スポーツ"
     "https://www.sankei.com/sports/")
    ("entertainments" "エンタメ"
     "https://www.sankei.com/entertainments/")
    ("life" "ライフ"
     "https://www.sankei.com/life/")
    ("column" "コラム"
     "https://www.sankei.com/column/")
    ("column.editorial" "主張"
     "https://www.sankei.com/column/editorial/")
    ("column.seiron" "正論"
     "https://www.sankei.com/column/seiron/")
    ("column.sankeisyo" "産経抄"
     "https://www.sankei.com/column/sankeisyo/")
    ("column.naniwa" "浪速風"
     "https://www.sankei.com/column/naniwa/")
    ("west" "産経WEST"
     "https://www.sankei.com/west/")
    ("west.essay" "朝晴れエッセー"
     "https://www.sankei.com/tag/series/etc_21/")))

(defvar shimbun-sankei-x-face-alist
  ;; Faces used for the light background display.
  '(("default" . "\
Face: iVBORw0KGgoAAAANSUhEUgAAABsAAAAbBAMAAAB/+ulmAAAAD1BMVEX8/PwAAAD///+G
 d3j/AADv136FAAAAAXRSTlMAQObYZgAAAKtJREFUGNNNkN0VAiAIhfW4QMgEXhpAtA1y/5kS0
 IoHD59w+UvJLD/StdlT0n4p834o/NJTMeRA6hHhXwXTBbrEsmnOcOyzKBFxP92UWIcon26Z0S
 qgtzxBBtCiea4KMyVP1uEEEi9F232tIQwXMyBrvWVCfQoLrmVqwxpotfsvetC0zz/UwKP1vh4
 ExVTNh4ScBVvM1e6C1UjO/fZKxnpvXYjnJP5efucf+gA+DB8q52OUwwAAAABJRU5ErkJggg=="))
;;  ;; Faces used for the dark background display.
;;  '(("default" . "\
;;Face: iVBORw0KGgoAAAANSUhEUgAAABsAAAAbAgMAAADwuhzGAAAADFBMVEUAAAD///95
;; iIf/AACrdmo+AAAAAXRSTlMAQObYZgAAAJ9JREFUCNcdjzEOwjAMRb8jJZJhYEGcoKoQC
;; 0cgjGyASNWxI9zC4g5FnKGX4FqdgO9ESp4s5/9vA5AMnoWpOTeIfLdokcieVapf1Ei2wh
;; AnNoHrWO5rcnw8X28XStaBLMHkTMkJ0J6XrrFx6XJuaZGw/+4UtPj8QDakidXamXCoVNL
;; 7aqvZc+UYrOZeaFhzMwJzEG9Q3yB0U+cLQAvH+AOYXSEFLdF2GAAAAABJRU5ErkJggg=="))
  )

(defvar shimbun-sankei-expiration-days 7)

(defvar shimbun-sankei-login-url "https://special.sankei.com/login"
  "*Url to login to special.sankei.com.")

(defvar shimbun-sankei-logout-url "https://special.sankei.com/logout"
  "*Url to logout from special.sankei.com.")

(defcustom shimbun-sankei-login-name nil
  "Login name used to login to special.sankei.com.
To use this, set both `w3m-use-cookies' and `w3m-use-form' to t."
  :group 'shimbun
  :type '(choice (const :tag "None" nil) (string :tag "User name")))

(defcustom shimbun-sankei-login-password nil
  "Password used to login to special.sankei.com.
To use this, set both `w3m-use-cookies' and `w3m-use-form' to t."
  :group 'shimbun
  :type '(choice (const :tag "None" nil) (string :tag "Password")))

(luna-define-method shimbun-groups ((shimbun shimbun-sankei))
  (mapcar 'car shimbun-sankei-group-table))

(luna-define-method shimbun-current-group-name ((shimbun shimbun-sankei))
  (nth 1 (assoc (shimbun-current-group-internal shimbun)
		shimbun-sankei-group-table)))

(luna-define-method shimbun-index-url ((shimbun shimbun-sankei))
  (nth 2 (assoc (shimbun-current-group-internal shimbun)
		shimbun-sankei-group-table)))

(defvar shimbun-sankei-retry-fetching 1)

(luna-define-method shimbun-get-headers :around ((shimbun shimbun-sankei)
						 &optional range)
  (shimbun-sankei-get-headers shimbun range))

(defun shimbun-sankei-get-headers (shimbun range)
  "Get headers for the group that SHIMBUN specifies in RANGE."
  (let ((group (shimbun-current-group-internal shimbun))
	nd url id st ids date subject names tem headers)
    (goto-char (point-min))
    (while (re-search-forward
	    "\"website_url\":\"\\([^\"]+-\\([0-9A-Z]\\{26\\}\\)[^\"]*\\)"
	    nil t)
      (setq nd (match-end 0)
	    url (match-string 1)
	    id (match-string 2))
      (when (and (search-backward (concat "{\"_id\":\"" id "\"") nil t)
		 (progn
		   (setq st (match-beginning 0))
		   (or (ignore-errors (forward-sexp 1) (setq nd (point)))
		       (progn (goto-char nd) nil))))
	(setq id (concat "<" id "."
			 (mapconcat #'identity
				    (nreverse (split-string group "\\."))
				    ".")
			 "%" shimbun-sankei-top-level-domain ">"))
	(or (member id ids)
	    (progn (push id ids)
		   (shimbun-search-id shimbun id))
	    (save-restriction
	      (narrow-to-region (goto-char st) nd)
	      (setq date (decode-time ;; Default to the current time.
			  (and (re-search-forward "\"display_date\":\"\
\\(20[2-9][0-9]-[01][0-9]-[0-3][0-9]T[0-5][0-9]:[0-5][0-9]:[^\"]+\\)" nil t)
			       (ignore-errors
				 (encode-time
				  (parse-time-string (match-string 1)))))))
	      (goto-char st)
	      (when (re-search-forward "\"headlines\":{\"basic\":\"\\([^\"]+\\)"
				       nil t)
		(setq subject (match-string 1))
		(goto-char st)
		(setq names nil)
		(when (and (search-forward "\"taxonomy\":" nil t)
			   (eq (following-char) ?{)
			   (ignore-errors (forward-sexp 1) t))
		  (save-restriction
		    (narrow-to-region (1- (match-end 0)) (point))
		    (goto-char (point-min))
		    (while (re-search-forward "\"name\":\"\\([^\"]+\\)\"" nil t)
		      (push (match-string 1) names))))
		(when (or (not names)
			  (not (setq
				tem
				(cdr (assoc
				      group
				      '(("column.editorial" . "主張")
					("column.seiron" . "正論")
					("column.sankeisyo" . "産経抄")
					("column.naniwa" . "浪速風")
					("west.essay" . "朝晴れエッセー"))))))
			  (member tem names))
		  (push (shimbun-create-header
			 0 subject
			 (concat shimbun-sankei-server-name
				 (if names
				     (concat " (" (mapconcat #'identity
							     (last names 2)
							     " ")
					     ")")
				   ""))
			 (shimbun-make-date-string
			  (nth 5 date) (nth 4 date) (nth 3 date)
			  (format "%02d:%02d:%02d"
				  (nth 2 date) (nth 1 date) (nth 0 date)))
			 id "" 0 0
			 (shimbun-expand-url url shimbun-sankei-url))
			headers)))
	      (goto-char nd)))))
    (shimbun-sort-headers headers)))

(luna-define-method shimbun-clear-contents :around ((shimbun shimbun-sankei)
						    header)
  (shimbun-sankei-clear-contents shimbun header))

(defun shimbun-sankei-clear-contents (shimbun header)
  "Collect contents and create an html page in the current buffer."
  (let (st nd ids simgs id caption tem img contents eimgs maxwidth fn)
    (goto-char (point-min))
    (when (and (search-forward "Fusion.globalContent=" nil t)
	       (eq (following-char) ?{)
	       (progn
		 (setq st (point))
		 (ignore-errors (forward-sexp 1) (setq nd (point)))))
      (goto-char (point-min))
      (setq ids (shimbun-sankei-extract-images st nil)
	    simgs (car ids)
	    ids (cadr ids))
      (save-restriction
	(narrow-to-region (goto-char st) nd)
	(search-forward "\"content_elements\":" nil t)
	(while (re-search-forward "{\"_id\":\"\\([^\"]\\{26\\}\\)\"" nil t)
	  (setq st (goto-char (match-beginning 0))
		nd (match-end 0)
		id (match-string 1))
	  (if (ignore-errors (forward-sexp 1) (setq nd (point)) (goto-char st))
	      (if (search-forward "\"type\":\"image\"" nd t)
		  (progn
		    (goto-char st)
		    (setq caption (and (search-forward "\"caption\":" nd t)
				       (eq (following-char) ?\")
				       (setq tem (ignore-errors
						   (replace-regexp-in-string
						    "\\`[\t ]+\\|[\t ]+\\'" ""
						    (read (current-buffer)))))
				       (not (zerop (length tem)))
				       tem))
		    (unless (member id ids)
		      (goto-char st)
		      (setq img (and (search-forward
				      "\"type\":\"image\",\"url\":"
				      nd t)
				     (eq (following-char) ?\")
				     (ignore-errors (read (current-buffer)))))
		      (goto-char st)
		      (and (or (search-forward "\"articleLarge\":" nd t)
			       (search-forward "\"articleSmall\":" nd t)
			       ;; very large
			       (and (not img) (search-forward
					       "\"type\":\"image\",\"url\":"
					       nd t))
			       ;; portrait is trimmed?
			       (search-forward "\"articleSnsShareImage\":"
					       nd t))
			   (eq (following-char) ?\")
			   (setq tem (ignore-errors (read (current-buffer))))
			   (progn
			     (push id ids)
			     (push (concat (if img
					       (concat "<a href=\"" img "\">")
					     "")
					   "<img src=\"" tem
					   "\" alt=\"[写真]\">"
					   (if img "</a>" "")
					   (if caption
					       (concat "<br>\n" caption
						       "<br><br>")
					     ""))
				   contents)))))
		(if (and (search-forward "\"content\":" nd t)
			 (eq (following-char) ?\")
			 (setq tem (ignore-errors (read (current-buffer)))))
		    (progn
		      (setq tem (replace-regexp-in-string
				 "\\`[\t ]+\\|[\t ]+\\'" "" tem))
		      (unless (zerop (length tem))
			(push tem contents)))
		  (goto-char nd)))
	    (goto-char nd))))
      (goto-char nd)
      (setq eimgs (car (shimbun-sankei-extract-images nil ids)))
      (erase-buffer)
      (when simgs
	(insert "<p>" (mapconcat #'identity (nreverse simgs) "</p>\n<p>")
		"</p>\n"))
      (when contents
	(setq maxwidth (max (- (window-width) 10) 10))
	(if (member (shimbun-current-group-internal shimbun)
		    '("column.sankeisyo" "column.naniwa"))
	    (setq fn (lambda (str)
		       (when (eq (aref str 0) ?▼)
			 (setq str (substring str 1)))
		       (if (string-match "\\`<\\(?:a\\|img\\) " str)
			   str
			 (concat "<p>"
				 (if (and (string-match "[,.、。]" str)
					  (>= (string-width str) maxwidth))
				     "　" "")
				 str "</p>"))))
	  (setq fn (lambda (str)
		     (if (string-match "\\`<\\(?:a\\|img\\) " str)
			 str
		       (concat "<p>"
			       (if (and (string-match "[,.、。]" str)
					(>= (string-width str) maxwidth))
				   "　" "")
			       str "</p>")))))
	(insert (mapconcat fn (nreverse contents) "\n") "\n"))
      (when eimgs
	(insert "<p>" (mapconcat #'identity (nreverse eimgs) "</p>\n<p>")
		"</p>\n"))
      (unless (memq (shimbun-japanese-hankaku shimbun) '(header subject nil))
	(shimbun-japanese-hankaku-buffer t))
      t)))

(defun shimbun-sankei-extract-images (end ids)
  "Extract images existing in the area from the current position to END.
END defaults to (point-max).  Image of which ID is in IDS is ignored.
Return a list of images and IDS."
  (let (img nd id to images)
    (while (and (re-search-forward
		 "<figure[\t\n ]+\\(?:[^\t\n >]+[\t\n ]+\\)*\
class=\"\\(?:[^\t\n \"]+[\t\n ]+\\)*article-image[\t\n >]+" end t)
		(shimbun-end-of-tag "figure"))
      (setq img (match-string 0)
	    nd (match-end 0))
      (goto-char (match-beginning 0))
      (when (or (re-search-forward "<a[\t\n ]+\\(?:[^\t\n >]+[\t\n ]+\\)*\
href=\"[^\"]+/photo/\\([0-9A-Z]\\{26\\}\\)/" nd t)
		(re-search-forward "<img[\t\n ]+\\(?:[^\t\n >]+[\t\n ]+\\)*\
src=\"[^\"]+/\\([0-9A-Z]\\{26\\}\\)\\.[^\"]+\"" nd t))
	(unless (member (setq id (match-string 1)) ids)
	  (push id ids)
	  (with-temp-buffer
	    (insert img)
	    (goto-char (point-min))
	    (when (and (re-search-forward "<img[\t\n ]+" nil t)
		       (shimbun-end-of-tag))
	      (setq to (match-end 0))
	      (goto-char (match-beginning 0))
	      (if (re-search-forward "alt=\"\\([^\">]*\\)\"" to t)
		  (replace-match "[写真]" nil nil nil 1)
		(goto-char (1- to))
		(insert " alt=\"[写真]\""))
	      (push (buffer-string) images)))))
      (goto-char nd))
    (list images ids)))

(luna-define-method shimbun-footer :around ((shimbun shimbun-sankei)
					    header &optional html)
  (concat "<div align=\"left\">\n--&nbsp;<br>\n\
この記事の著作権は産経新聞社に帰属します。オリジナルはこちら：<br>\n\
<a href=\""
	  (shimbun-article-base-url shimbun header) "\">&lt;"
	  (shimbun-article-base-url shimbun header) "&gt;</a>\n</div>\n"))

(eval-when-compile
  (require 'w3m-cookie)
  (require 'w3m-form))

(declare-function w3m-cookie-save "w3m-cookie" (&optional domain))
(declare-function w3m-cookie-setup "w3m-cookie")

(autoload 'password-cache-add "password-cache")
(autoload 'password-read-from-cache "password-cache")

(defun shimbun-sankei-login (&optional name password interactive-p)
  "Login to special.sankei.com with NAME and PASSWORD.
NAME and PASSWORD default to `shimbun-sankei-login-name' and
`shimbun-sankei-login-password' respectively.  `password-data', if
cached, overrides `shimbun-sankei-login-password'.  If the prefix
argument is given, you will be prompted for new NAME and PASSWORD."
  (interactive (let ((pass (copy-sequence shimbun-sankei-login-password))
		     name default password)
		 (unless (and w3m-use-cookies w3m-use-form)
		   (error "\
You should set `w3m-use-cookies' and `w3m-use-form' to non-nil"))
		 (setq name (if current-prefix-arg
				(completing-read
				 "Login name: "
				 (cons shimbun-sankei-login-name nil)
				 nil nil shimbun-sankei-login-name)
			      shimbun-sankei-login-name))
		 (when (and name (string-match "\\`[\t ]*\\'" name))
		   (setq name nil))
		 (setq default (and name
				    (or (password-read-from-cache name)
					;; `password-cache' will expire
					;; the password by filling it with
					;; C-@'s, so we use a copy of
					;; the original.
					(copy-sequence
					 shimbun-sankei-login-password)))
		       password (and name
				     (if current-prefix-arg
					 (read-passwd
					  (concat "Password"
						  (when default
						    (concat " (default "
							    (make-string
							     (length default)
							     ?*)
							    ")"))
						  ": ")
					  nil default)
				       default)))
		 (when (and password (string-match "\\`[\t ]*\\'" password))
		   (setq name nil
			 password nil))
		 (list name password t)))
  (unless interactive-p
    (if (or name (setq name shimbun-sankei-login-name))
	(or password
	    (setq password
		  (or (password-read-from-cache name)
		      (copy-sequence shimbun-sankei-login-password)))
	    (setq name nil))
      (setq password nil)))
  (if (not (and w3m-use-cookies w3m-use-form name password))
      (when interactive-p (message "Quit"))
    (when interactive-p (message "Logging in to special.sankei.com..."))
    (require 'w3m-cookie)
    ;; Delete old login cookies.
    (w3m-cookie-setup)
    (dolist (cookie w3m-cookies)
      (when (string-match "\\.sankei\\..+login" (w3m-cookie-url cookie))
	(setq w3m-cookies (delq cookie w3m-cookies))))
    (require 'w3m-form)
    (w3m-arrived-setup)
    (let ((cache (buffer-live-p w3m-cache-buffer))
	  (w3m-message-silent t)
	  w3m-clear-display-while-reading next form action handler)
      (condition-case err
	  (with-temp-buffer
	    (w3m-process-with-wait-handler
	      (w3m-retrieve-and-render shimbun-sankei-login-url
				       t nil nil nil handler))
	    (goto-char (point-min))
	    (when (re-search-forward "^Location:[\t\n\r ]+\\(http[^\n]+\\)"
				     nil t)
	      (setq next (match-string-no-properties 1))
	      (w3m-process-with-wait-handler
		(w3m-retrieve-and-render next t nil nil nil handler))
	      (goto-char (point-min))
	      (when (re-search-forward
		     "^You were redirected to:[\t\n\r ]+\\(http[^\n]+\\)"
		     nil t)
		(setq next (match-string-no-properties 1))
		(w3m-process-with-wait-handler
		  (w3m-retrieve-and-render next t nil nil nil handler))))
	    (setq form (car w3m-current-forms))
	    (if (not (string-match "login\\.php\\'"
				   (setq action (w3m-form-action form))))
		(when interactive-p (message "Failed to login"))
	      (setq form (w3m-form-make-form-data form))
	      (while (string-match "\
&\\(?:LOGIN_ID\\|LOGIN_PASSWORD\\|STAY_LOGGED_IN\\)=[^&]*" form)
		(setq form (replace-match "" nil nil form)))
	      (setq form (concat form
				 "&LOGIN=&LOGIN_ID="
				 (shimbun-url-encode-string name)
				 "&LOGIN_PASSWORD="
				 (shimbun-url-encode-string password)
				 "&STAY_LOGGED_IN=1"))
	      (w3m-process-with-wait-handler
		(w3m-retrieve-and-render action t nil form nil handler))
	      (setq form (car w3m-current-forms))
	      (if (not (string-match "login\\'"
				     (setq action (w3m-form-action form))))
		  (when interactive-p (message "Failed to login"))
		(setq form (w3m-form-make-form-data form))
		(w3m-process-with-wait-handler
		  (w3m-retrieve-and-render action t nil form nil handler)))
	      (if (not (and w3m-current-url
			    (string-match
			     "\\`https://www.sankei.com/\\?[0-9]+\\'"
			     w3m-current-url)))
		  (when interactive-p (message "Failed to login"))
		(when interactive-p (message "Logged in"))
		(password-cache-add name password)
		(when w3m-cookie-save-cookies (w3m-cookie-save))))
	    (when (get-buffer " *w3m-cookie-parse-temp*")
	      (kill-buffer (get-buffer " *w3m-cookie-parse-temp*")))
	    (unless cache (w3m-cache-shutdown)))
	(error (if (or interactive-p debug-on-error)
		   (signal (car err) (cdr err))
		 (message "Error while logging in to special.sankei.com:\n %s"
			  (error-message-string err))))))))

(defun shimbun-sankei-logout (&optional interactive-p)
  "Logout from special.sankei.com."
  (interactive (list t))
  (require 'w3m-cookie)
  (require 'w3m-form)
  (w3m-arrived-setup)
  (let ((cache (buffer-live-p w3m-cache-buffer))
	(w3m-message-silent t)
	(next shimbun-sankei-logout-url)
	w3m-clear-display-while-reading done handler)
    (when interactive-p (message "Logging out from special.sankei.com..."))
    (condition-case err
	(with-temp-buffer
	  (while (not done)
	    (w3m-process-with-wait-handler
	      (w3m-retrieve-and-render next t nil nil nil handler))
	    (goto-char (point-min))
	    (if (re-search-forward "\
^\\(?:Location\\|You were redirected to\\):[\t\n\r ]+\\(http[^\n]+\\)" nil t)
		(setq next (match-string-no-properties 1))
	      (w3m-process-with-wait-handler
		(w3m-retrieve-and-render next t nil nil nil handler))
	      (when interactive-p (message "Logged out"))
	      (setq done t)))
	  (when (get-buffer " *w3m-cookie-parse-temp*")
	    (kill-buffer (get-buffer " *w3m-cookie-parse-temp*")))
	  (unless cache (w3m-cache-shutdown)))
      (error (if (or interactive-p debug-on-error)
		 (signal (car err) (cdr err))
	       (message "Error while logging out from special.sankei.com:\n %s"
			(error-message-string err)))))))

;;(shimbun-sankei-login)

(provide 'sb-sankei)

;;; sb-sankei.el ends here
