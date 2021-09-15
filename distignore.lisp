(cl:defpackage :distignore
  (:use :cl :alexandria)
  (:export #:pathname-ignored-p
           #:with-ignorable-directory))
(cl:in-package :distignore)


(defun ensure-unix-namestring (path)
  (let ((filename (file-namestring path))
        (dirs (rest (pathname-directory path))))
    (format nil "~@[~A~]~{~A/~}~@[~A~]"
            (when (uiop:absolute-pathname-p path)
              (uiop:pathname-root path))
            dirs
            filename)))


(defun read-distignore-predicate (path)
  (when-let ((distignore-file (uiop:probe-file*
                               (merge-pathnames ".distignore"
                                                (uiop:ensure-directory-pathname path)))))
    (labels ((trim-string (string)
               (let ((string (if-let (pos (position #\# string))
                               (subseq string 0 pos)
                               string)))
                 (string-trim '(#\Tab #\Space #\Newline) string))))
      (let* ((regexes (ppcre:split "[\\n\\r]+" (read-file-into-string distignore-file)))
             (scanners (mapcar #'ppcre:create-scanner (remove-if #'emptyp
                                                                 (mapcar #'trim-string regexes)))))
        (lambda (string)
          (let ((path (ensure-unix-namestring path))
                (string (ensure-unix-namestring string)))
            (when (starts-with-subseq path string)
              (let ((subpath (concatenate 'string "/" (enough-namestring string path))))
                (loop for scanner in scanners
                        thereis (ppcre:scan scanner subpath))))))))))


(defvar *exclusion-predicates* nil)


(defun pathname-ignored-p (path)
  (loop for pred in *exclusion-predicates*
          thereis (funcall pred path)))


(defmacro with-ignorable-directory ((dir) &body body)
  `(let ((*exclusion-predicates* (append (when-let ((pred (read-distignore-predicate ,dir)))
                                           (list pred))
                                         *exclusion-predicates*)))
     ,@body))
