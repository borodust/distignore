(asdf:defsystem :distignore
  :description "Utility to handle .distignore files"
  :author "Pavel Korolev"
  :mailto "dev@borodust.org"
  :license "MIT"
  :depends-on (:uiop :alexandria :cl-ppcre)
  :components ((:file "distignore")))
