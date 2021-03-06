;;;; package.lisp

(defpackage :ichiran/characters
  (:use :cl)
  (:export :*sokuon-characters* :*iteration-characters* :*modifier-characters*
           :*kana-characters* :*all-characters* :*char-class-hash*
           :*katakana-regex* :*hiragana-regex* :*kanji-regex* :test-word
           :hash-from-list :voice-char :simplify-ngrams :normalize
           :split-by-regex :basic-split :mora-length :count-char-class
           :as-hiragana :sequential-kanji-positions
           :*undakuten-hash* :*dakuten-hash* :*handakuten-hash*
           :kanji-prefix :kanji-mask :kanji-regex :kanji-match :kanji-cross-match
           :unrendaku :rendaku :destem :geminate
           :collect-char-class :*kanji-char-regex* :consecutive-char-groups
           ))

(defpackage :ichiran/numbers
  (:use :cl :ichiran/characters)
  (:export
   #:*digit-kanji-default*
   #:*digit-kanji-legal*
   #:*power-kanji*
   #:number-to-kanji
   #:parse-number
   #:number-to-kana
   #:not-a-number))

(defpackage :ichiran/tokenize
  (:use :cl)
  (:export :segment))

(defpackage :ichiran/conn
  (:use :cl :postmodern)
  (:export :get-spec :with-db :let-db
           :*connection*
           :*connections*
           :def-conn-var
           :switch-conn-vars))

(defpackage :ichiran/dict
  (:use :cl :postmodern :split-sequence
        :ichiran/characters :ichiran/conn :ichiran/numbers)
  (:export :simple-segment :dict-segment :word-info-from-text
           :word-info :word-info-type :word-info-text
           :word-info-kana :word-info-score :map-word-info-kana
           :word-info-str :word-info-components :word-info-alternative
           :word-info-start :word-info-end :word-info-counter :word-info-skipped
           :word-info-json :word-info-gloss-json
           :init-suffixes :init-suffixes-running-p
           :node-text
           :get-kanji-words
           :find-word-info
           :find-word-info-json
           :simple-word-info
           :process-hints
           :init-counters))

(defpackage :ichiran
  (:use :cl :ichiran/characters :ichiran/conn :ichiran/dict)
  (:export :romanize :romanize-word :romanize* :romanize-word-info
           :generic-romanization :generic-hepburn :kana-table
           :simplified-hepburn :simplifications
           :*hepburn-basic* :*hepburn-simple* :*hepburn-passport*
           :*hepburn-traditional* :*hepburn-modified*
           :kunrei-siki :*kunrei-siki*
           :*default-romanization-method*))

(defpackage :ichiran/kanji
  (:use :cl :postmodern :ichiran/conn :ichiran :ichiran/characters :ichiran/dict)
  (:export
   :kanji-info-json
   :match-readings
   :kanji-word-stats
   :get-readings
   :get-normal-readings
   :match-readings-json
   :query-kanji-json))

(uiop:define-package :ichiran/all
    (:use-reexport :ichiran/characters :ichiran/numbers
                   :ichiran/conn :ichiran/dict :ichiran :ichiran/kanji))

(defpackage :ichiran/test
  (:use :cl :ichiran/all :lisp-unit)
  (:export :run-all-tests))
  
