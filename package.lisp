;;;; package.lisp

(defpackage #:ichiran/tokenize
  (:use #:cl)
  (:export :segment))

(defpackage #:ichiran
  (:use #:cl)
  (:export :romanize :romanize-word
           :generic-romanization :generic-hepburn :kana-table
           :simplified-hepburn :simplifications
           :*hepburn-basic* :*hepburn-simple* :*hepburn-passport*
           :*hepburn-traditional* :*hepburn-modified*
           :*default-romanization-method*))

