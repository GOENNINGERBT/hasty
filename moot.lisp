(in-package #:hasty)

;; {TODO} Tick driven Systems perform a pass when the moot's tick function is
;;        called

(defun %make-systems-array (&optional systems)
  (make-array (length systems) :element-type '%system
	      :initial-contents systems))

;; (let ((all-entities (bag-of-entity!))
;;       (all-systems (%make-systems-array))
;;       (pending-systems nil)))

(defvar all-entities (bag-of-entity!))
(defvar all-systems (%make-systems-array))
(defvar pending-systems nil)

(defun %rummage-master (predicate)
  "used internally by systems"
  (rummage-entity-bag all-entities predicate))

(defun step-hasty ()
  (when pending-systems
    (%commit-pending-systems))
  (loop :for system :across all-systems :do (%run-pass system)))

(defun run-pass (system)
  (if (%system-event-based-p system)
      (%run-pass system)
      (error "Cannot manually trigger pass on non event-based system ~s"
	     system)))

(defun %run-pass (system)
  (let ((entities (get-items-from-entity-rummager
		   (%system-entities system)))
	(pass-function (%system-pass-function system)))
    (loop :for entity :across entities :do
       (unless-release
	 (when (entity-dirty entity)
	   (%check-component-friendships-of-entity entity)))
       (funcall pass-function entity))))

(defun %commit-pending-systems ()
  (if pending-systems
      (%add-systems pending-systems)
      (print "%commit-pending-systems: no pending systems found"))
  (setf pending-systems nil))

(defun %add-systems (systems)
  (let ((sorted (sort-systems
		 (append systems
			 (loop :for s :across all-systems :collect s)))))
    (setf all-systems (%make-systems-array sorted))
    all-systems))

(defun add-system (system)
  (if (find system all-systems :test #'eq)
      (error "System has already been added")
      (push system pending-systems))
  system)

(defun remove-system (system)
  (let ((sorted (sort-systems
		 (remove system (loop :for s :in all-systems :collect s)))))
    (setf all-systems (%make-systems-array sorted))
    all-systems))

(defun register-entity (entity)
  (add-item-to-entity-bag all-entities entity)
  entity)

(defun unregister-entity (entity)
  (remove-item-from-entity-bag all-entities entity))

(defun %get-all-entities ()
  all-entities)
