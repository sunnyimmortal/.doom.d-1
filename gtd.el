;;; package --- Summary
;;; Commentary:
;;; Code:
(defcustom org-gtd-folder "~/.org/gtd/"
  "Root folder where all GTD files will reside."
  :type 'directory)
(defcustom org-projects-folder "~/.org/gtd/proejcts"
  "Folder that holds all special projects managed by GTD."
  :type 'directory)
(defcustom org-gtd-task-files nil
  "List of NEXT ACTION files that reside in your GTD folder."
  :type '(choice
          (repeat :tag "List of files and directories" string)
          (file :tag "Store list in a file\n" :value "~/.gtd_nextaction_files")))
(defcustom org-gtd-someday-file "~/.org/gtd/someday.org"
  "The name of your INCUBATE file."
  :type 'file)
(defcustom org-gtd-inbox-file "~/.org/gtd/inbox.org"
  "The name of your INBOX file."
  :type 'file)
(defcustom org-gtd-references-file "~/.org/gtd/references.org"
  "The name of your REFERENCES file."
  :type 'file)
(defcustom org-gtd-tickler-file "~/.org/gtd/tickler.org"
  "The name of your TICKLER file."
  :type 'file)
(defcustom org-gtd-refile-properties nil
  "List of PROPERTY names when you Clarify or Refile."
  :type '(choice
          (repeat :tag "List of PROPERTY names" string)))

(defvar org-next-task-files nil)

;; Configure our next task file and map them to our folder directory
(setq org-next-task-files (mapcar (lambda (file) (expand-file-name file org-gtd-folder))
                                   org-gtd-task-files))

;; (mapcar (lambda (arg) (org-set-property arg (read-string (concat arg ": "))))
;;           org-gtd-properties)

;; Configure our key maps
(map! :after org
      :map org-mode-map
      :leader
      :prefix ("d" . "Getting Things Done")
      :desc "Capture" "!" #'org-gtd-quick-capture
      :desc "Check Inbox" "i" #'zyro/agenda-inbox
      :desc "Clarify" "c" #'zyro/refile-set-properties
      :desc "Search references" "r" #'zyro/agenda-references
      :desc "Refile to next tasks" "R" #'zyro/refile
      :desc "Next Tasks" "n" #'zyro/agenda-next-tasks
      :desc "Projects" "p" #'org-gtd-agenda-projects
      :desc "Find File" "f" #'org-gtd-find-file)

;;; Capture System for GTD
(defun zyro/capture-inbox ()
  "Function to locate file for capture template."
  (let ((name (file-name-nondirectory org-gtd-inbox-file))
        (dir (file-name-directory org-gtd-inbox-file)))
    (expand-file-name (format "%s%s" dir name))))

(defun org-gtd-quick-capture ()
  "Quick capture to inbox from KEY-BINDING."
  (interactive)
  (let* ((org-capture-templates
          '(("!" "Quick Capture" entry (file zyro/capture-inbox)
             "* TODO %^{task}\n:PROPERTIES:\n:CREATED: %U\n:END:" :immediate-finish t))))
    (org-capture nil "!")))

;;; Refile System

(defun zyro/refile-set-properties ()
  "Set properties when refiling."
  (interactive)
  (when major-mode (= '"org-mode")
    (mapcar (lambda (arg) (org-set-property arg (read-string (concat arg ": "))))
          org-gtd-refile-properties)
    (call-interactively #'org-schedule)
    (org-set-effort nil (ivy-completing-read "Estimate: " '("0:15" "0:30" "0:45" "1:00" "1:30" "2:00" "2:30" "3:00" "4:00")))
    (call-interactively #'org-set-tags-command)))

(defun zyro/refile ()
  "Refile current headline to NEXT tasks."
  (interactive)
  (let ((org-refile-targets '((org-next-task-files :maxlevel . 3))))
    (advice-add 'org-refile :before #'zyro/refile-set-properties)
    (org-refile)))

;;; Configure file finders
(defun org-gtd-find-file ()
  "Find default INBOX file."
  (interactive)
  (find-file (expand-file-name (ivy-completing-read "select: " (directory-files org-gtd-folder nil "[\\^.]org")) org-gtd-folder)))

;;; Configure Agenda Settings
(defun zyro/agenda-someday ()
  "Open next tasks in ORGMODE AGENDA."
  (interactive)
  (let ((org-agenda-files (list org-gtd-someday-file))
        (org-super-agenda-groups
                     '((:priority "A")
                       (:priority "B")
                       (:todo "PROJ")
                       (:effort> "0:16")
                       (:effort< "0:15"))))
    (org-agenda nil "t")))

(defun org-gtd-agenda-projects ()
  "Call agenda for GTD projects folder."
  (interactive)
  (let ((org-agenda-files (list org-projects-folder))
        (org-agenda-custom-commands
         '(("w" "Master List"
            ((agenda ""
                     ((org-agenda-start-day (org-today))
                      (org-agenda-span 3)))
             (todo ""
                   ((org-super-agenda-groups
                     '((:priority "A")
                       (:effort> "0:16")
                       (:priority "B"))))))))))
    (org-agenda nil "w")))

(defun zyro/agenda-references ()
  "Open next tasks in ORGMODE AGENDA."
  (interactive)
  (let ((org-agenda-files (list org-gtd-references-file))
        (org-super-agenda-groups
                     '((:auto-ts t))))
    (org-agenda nil "s")))

(defun zyro/agenda-inbox ()
  "Configure our Inbox agenda."
  (interactive)
  (let ((org-agenda-files (list org-gtd-inbox-file))
        (org-super-agenda-groups
         '((:auto-ts t))))
    (org-agenda nil "t")))

(defun zyro/agenda-next-tasks ()
  "Open next tasks in ORGMODE AGENDA."
  (interactive)
  (setq org-next-task-files (mapcar (lambda (file) (expand-file-name file org-gtd-folder))
                                    org-gtd-task-files))
  (let ((org-agenda-custom-commands
        '(("w" "Master Agenda"
           ((agenda ""
                    ((org-agenda-overriding-header "Master Agenda")
                     (org-agenda-files org-next-task-files)
                     (org-agenda-time-grid nil)
                     (org-agenda-start-day (org-today))
                     (org-agenda-span '5)))
            (tags-todo "@home"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@computer"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@place"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@brainstorm"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@read"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@order"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@labor"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "@bills"
                      ((org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))
            (tags-todo "-@place-@brainstorm-@bills-@labor-@order-@work-@computer-@home"
                       ((org-agenda-overriding-header "Everything else")
                        (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
                        (org-agenda-files org-next-task-files)))))
          ("h" . "Tasks")
          ("hh" tags-todo "@home"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("hp" tags-todo "@place"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("hb" tags-todo "@brainstorm"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("hr" tags-todo "@read"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("ho" tags-todo "@order"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("hl" tags-todo "@labor"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("hc" tags-todo "@computer"
           ((org-agenda-files org-next-task-files)
            (org-agenda-skip-function '(org-agenda-skip-entry-if 'scheduled))
            (org-super-agenda-groups '((:auto-parent t)))))
          ("x" . "Stuck Projects")
          ("xh" todo "WAIT|HOLD")
          ("xs" todo "SMDY"))))
  (org-agenda)))

;; Configure template picker
;;(find-file (expand-file-name (ivy-completing-read "select: " (directory-files "~/.doom.d/templates/" nil "[\\^.]org")) org-gtd-folder))

(defun org-gtd-templates ()
  "Template picker."
  (interactive)
  (let ((files (directory-files (expand-file-name "templates/" (doom-dir)) t "[\\^.]org")))
    (setq org-capture-templates nil)
    (mapcar (lambda (arg) (add-to-list 'org-capture-templates ((substring arg 20 21) arg plain (file zyro/capture-inbox)
                                                                (file arg)))) files)
    (call-interactively #'org-capture)))

(provide 'org-gtd)

;;; org-gtd.el ends here
