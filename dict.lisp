;; ichiran dictionary module
;; based on JMDict

(in-package #:ichiran/dict)

(defparameter *jmdict-path* #p"foobar")

(defparameter *jmdict-data* #p"foobar")

(defparameter *connection* '("jmdict" "postgres" "" "localhost"))

(eval-when (:load-toplevel)
  (load (asdf:system-relative-pathname :ichiran "settings.lisp") :if-does-not-exist nil))

(defgeneric get-kana (obj)
  (:documentation "most popular kana representation"))

(defgeneric get-text (obj)
  (:documentation "most popular text representation (kanji or kana)")
  (:method (obj) (text obj)))

(defgeneric word-type (obj)
  (:documentation "returns :kanji or :kana or :gap")
  (:method (obj) :gap))

(defclass entry ()
  ((seq :reader seq :col-type integer :initarg :seq)
   (content :reader content :col-type string :initarg :content)
   (root-p :reader root-p :col-type boolean :initform nil :initarg :root-p)
   (n-kanji :accessor n-kanji :col-type integer :initform 0 :initarg :n-kanji)
   (n-kana :accessor n-kana :col-type integer :initform 0 :initarg :n-kana)
   (primary-nokanji :reader primary-nokanji :col-type boolean :initform nil)
   )
  (:metaclass dao-class)
  (:keys seq))

(deftable entry
  (!dao-def))

(defmethod print-object ((obj entry) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "~a ~a:~a" (seq obj) (n-kanji obj) (n-kana obj))))

(defmethod get-kana ((obj entry))
  (text (car (select-dao 'kana-text (:and (:= 'seq (seq obj)) (:= 'ord 0))))))

(defmethod get-text ((obj entry))
  (text (car (select-dao (if (> (n-kanji obj) 0) 'kanji-text 'kana-text)
                         (:and (:= 'seq (seq obj)) (:= 'ord 0))))))

(defun recalc-entry-stats ()
  (query (:update 'entry :set
                  'n-kanji (:select (:count 'id) :from 'kanji-text :where (:= 'kanji-text.seq 'entry.seq))
                  'n-kana (:select (:count 'id) :from 'kana-text :where (:= 'kana-text.seq 'entry.seq)))))

(defclass simple-text () ())

(defclass kanji-text (simple-text)
  ((id :reader id :col-type serial)
   (seq :reader seq :col-type integer :initarg :seq)
   (text :reader text :col-type string :initarg :text)
   (ord :reader ord :col-type integer :initarg :ord)
   (common :reader common :col-type (or db-null integer) :initarg :common)
   (conjugate-p :reader conjugate-p :col-type boolean :initform t :initarg :conjugate-p)
   (nokanji :reader nokanji :col-type boolean :initform nil :initarg :nokanji)
   )
  (:metaclass dao-class)
  (:keys id))

(deftable kanji-text
  (!dao-def)
  (!index 'seq)
  (!index 'ord)
  (!index 'text)
  (!index 'common)
  (!foreign 'entry 'seq :on-delete :cascade))

(defmethod print-object ((obj kanji-text) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "~a ~a" (seq obj) (text obj))))

(defmethod get-kana ((obj kanji-text))
  (text (car (select-dao 'kana-text (:and (:= 'seq (seq obj)) (:= 'ord 0))))))

(defmethod word-type ((obj kanji-text)) :kanji)

(defclass kana-text (simple-text)
  ((id :reader id :col-type serial)
   (seq :reader seq :col-type integer :initarg :seq)
   (text :reader text :col-type string :initarg :text)
   (ord :reader ord :col-type integer :initarg :ord)
   (common :reader common :col-type (or db-null integer) :initarg :common)
   (conjugate-p :reader conjugate-p :col-type boolean :initform t :initarg :conjugate-p)
   (nokanji :reader nokanji :col-type boolean :initform nil :initarg :nokanji)
   )
  (:metaclass dao-class)
  (:keys id))

(deftable kana-text
  (!dao-def)
  (!index 'seq)
  (!index 'ord)
  (!index 'text)
  (!index 'common)
  (!foreign 'entry 'seq :on-delete :cascade))

(defmethod print-object ((obj kana-text) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "~a ~a" (seq obj) (text obj))))

(defmethod get-kana ((obj kana-text))
  (text obj))

(defmethod word-type ((obj kana-text)) :kana)

(defclass sense ()
  ((id :reader id :col-type serial)
   (seq :reader seq :col-type integer :initarg :seq)
   (ord :reader ord :col-type integer :initarg :ord))
  (:metaclass dao-class)
  (:keys id))

(deftable sense
  (!dao-def)
  (!index 'seq)
  (!index 'ord)
  (!foreign 'entry 'seq))

(defclass gloss ()
  ((id :reader id :col-type serial)
   (sense-id :reader sense-id :col-type integer :initarg :sense-id)
   (text :reader text :col-type string :initarg :text)
   (ord :reader ord :col-type integer :initarg :ord)
   )
  (:documentation "English meaning")
  (:metaclass dao-class)
  (:keys id))

(defmethod print-object ((obj gloss) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "(~a) ~a" (ord obj) (text obj))))

(deftable gloss
  (!dao-def)
  (!index 'sense-id)
  (!index 'ord)
  (!foreign 'sense 'sense-id 'id))

(defclass sense-prop ()
  ((id :reader id :col-type serial)
   (tag :reader tag :col-type string :initarg :tag)
   (sense-id :reader sense-id :col-type integer :initarg :sense-id)
   (text :reader text :col-type string :initarg :text)
   (ord :reader ord :col-type integer :initarg :ord)
   (seq :reader seq :col-type integer :initarg :seq)
   )
  (:documentation "sense properties")
  (:metaclass dao-class)
  (:keys id))
  
(defmethod print-object ((obj sense-prop) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "~a:~a" (tag obj) (text obj))))

(deftable sense-prop
  (!dao-def)
  (!index 'sense-id)
  (!index 'tag)
  (!index 'text)
  (!index 'ord)
  (!index 'seq)
  (!foreign 'entry 'seq)
  (!foreign 'sense 'sense-id 'id))

(defclass conjugation ()
  ((id :reader id :col-type serial)
   (seq :reader seq :col-type integer :initarg :seq)
   (from :reader seq-from :col-type integer :initarg :from)
   (via :reader seq-via :col-type (or integer db-null) :initform :null :initarg :via)
   )
  (:documentation "conjugation link")
  (:metaclass dao-class)
  (:keys id))

(deftable conjugation
  (!dao-def)
  (!index 'seq)
  (!index 'from)
  (!foreign 'entry 'seq)
  (!foreign 'entry 'from 'seq))

(defmethod print-object ((obj conjugation) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (let ((via (seq-via obj)))
      (if (eql via :null)
          (format stream "~a -> ~a" (seq-from obj) (seq obj))
          (format stream "~a -> ~a -> ~a" (seq-from obj) (seq-via obj) (seq obj))))))

(defclass conj-prop ()
  ((id :reader id :col-type serial)
   (conj-id :reader conj-id :col-type integer :initarg :conj-id)
   (conj-type :reader conj-type :col-type integer :initarg :conj-type)
   (pos :reader pos :col-type string :initarg :pos)
   (neg :reader conj-neg :col-type (or db-null boolean) :initarg :neg)
   (fml :reader conj-fml :col-type (or db-null boolean) :initarg :fml))
  (:metaclass dao-class)
  (:keys id))

(deftable conj-prop
  (!dao-def)
  (!index 'conj-id)
  (!foreign 'conjugation 'conj-id 'id))

(defun conj-info-short (obj)
  (format nil "[~a] ~a~[ Affirmative~; Negative~]~[ Plain~; Formal~]"
          (pos obj) 
          (get-conj-description (conj-type obj))
          (case (conj-neg obj) ((nil) 0) ((t) 1))
          (case (conj-fml obj) ((nil) 0) ((t) 1))
          ))

(defmethod print-object ((obj conj-prop) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (princ (conj-info-short obj) stream)))

(defstruct conj-data seq from via prop)

(defun get-conj-data (seq)
  (loop for conj in (select-dao 'conjugation (:= 'seq seq))
       nconcing (loop for prop in (select-dao 'conj-prop (:= 'conj-id (id conj)))
                     collect (make-conj-data :seq (seq conj) :from (seq-from conj)
                                             :via (let ((via (seq-via conj)))
                                                    (if (eql via :null) nil via))
                                             :prop prop))))

(defun init-tables ()
  (with-connection *connection*
    (let ((tables '(entry kanji-text kana-text sense gloss sense-prop conjugation conj-prop)))
      (loop for table in (reverse tables)
         do (query (:drop-table :if-exists table)))
      (loop for table in tables
         do (create-table table)))))

;; Taken from webgunk so that ichiran doesn't depend on it
;; strip-whitespace option is removed as it doesn't look necessary in this case
(defun node-text (node &rest args &key test)
  (let (values result)
    (when (or (not test) (funcall test node))
      (dom:do-node-list (node (dom:child-nodes node))
        (let ((val (case (dom:node-type node)
                     (:element (apply #'node-text node args))
                     (:text (dom:node-value node)))))
          (push val values))))
    (setf result (apply #'concatenate 'string (nreverse values)))))

(defmacro do-node-list-ord ((ord-var node-var node-list) &body body)
  `(let ((,ord-var 0))
     (dom:do-node-list (,node-var ,node-list)
       ,@body
       (incf ,ord-var))))

(defun insert-readings (node-list tag table seq pri)
  (let (to-add primary-nokanji)
    (do-node-list-ord (ord node node-list)
      (let* ((reading-node (dom:item (dom:get-elements-by-tag-name node tag) 0))
             (reading-text (node-text reading-node))
             (common :null)
             skip (nokanji nil))
        (dom:do-node-list (node (dom:get-elements-by-tag-name node "re_inf"))
          (when (equal (node-text node) "ok")
            (setf skip t)))
        (when (< 0 (dom:length (dom:get-elements-by-tag-name node "re_nokanji")))
          (setf nokanji t))
        (unless skip
          (dom:do-node-list (node (dom:get-elements-by-tag-name node pri))
            (let ((pri-tag (node-text node)))
              (if (eql common :null) (setf common 0))
              (when (alexandria:starts-with-subseq "nf" pri-tag)
                (setf common (parse-integer pri-tag :start 2)))))
          (push (list reading-text common nokanji) to-add))))
    (loop for (reading-text common nokanji) in (nreverse to-add)
       for ord from 0
       when nokanji do (setf primary-nokanji t)
       do (make-dao table :seq seq :text reading-text :ord ord :common common
                    :nokanji nokanji))
    (when primary-nokanji
      (query (:update 'entry :set 'primary-nokanji t :where (:= 'seq seq))))))
         
  
(defun insert-sense-traits (sense-node tag sense-id seq)
  (do-node-list-ord (ord node (dom:get-elements-by-tag-name sense-node tag))
    (make-dao 'sense-prop :sense-id sense-id :tag tag :text (node-text node) :ord ord :seq seq)))

(defun insert-senses (node-list seq)
  (do-node-list-ord (ord node node-list)
    (let ((sense-id (id (make-dao 'sense :seq seq :ord ord))))
      (do-node-list-ord (ord node (dom:get-elements-by-tag-name node "gloss"))
        (make-dao 'gloss :sense-id sense-id :text (node-text node) :ord ord))
      (insert-sense-traits node "pos" sense-id seq)
      (insert-sense-traits node "misc" sense-id seq)
      (insert-sense-traits node "dial" sense-id seq))))

(defun load-entry (content)
  (let* ((parsed (cxml:parse content (cxml-dom:make-dom-builder)))
         (entseq-node (dom:item (dom:get-elements-by-tag-name parsed "ent_seq") 0))
         (seq (parse-integer (node-text entseq-node))))
    (make-dao 'entry :seq seq :content content :root-p t)
    (let* ((kanji-nodes (dom:get-elements-by-tag-name parsed "k_ele"))
           (kana-nodes (dom:get-elements-by-tag-name parsed "r_ele"))
           (sense-nodes (dom:get-elements-by-tag-name parsed "sense")))
      (insert-readings kanji-nodes "keb" 'kanji-text seq "ke_pri")
      (insert-readings kana-nodes "reb" 'kana-text seq "re_pri")
      (insert-senses sense-nodes seq))))

(defun fix-entities (source)
  "replaces entity definitions with abbreviations"
  (let ((entity-hash (cxml::dtd-gentities (cxml::dtd (slot-value source 'cxml::context)))))
    (maphash 
     (lambda (name entdef)
       (unless (member name '("lt" "gt" "amp" "apos" "quot") :test 'equal)
         (setf (cxml::entdef-value (cdr entdef)) name)))
     entity-hash)))
    
(defun load-jmdict (&key (path *jmdict-path*) (load-extras t))
  (init-tables)
  (with-connection *connection*
    (klacks:with-open-source (source (cxml:make-source path))
      (klacks:find-element source "JMdict")
      (fix-entities source)
      (loop for cnt from 1 ;; to 1000
         while (klacks:find-element source "entry")
         do
           (let ((content (klacks:serialize-element source (cxml:make-string-sink))))
             (load-entry content))
         if (zerop (mod cnt 1000)) do (format t "~a entries loaded~%" cnt)
         finally (recalc-entry-stats) (query "ANALYZE") (format t "~a entries total~%" cnt)))
    (when load-extras (load-extras))))

(defun load-extras ()
  (format t "Loading conjugations...~%")
  (load-conjugations)
  (format t "Loading secondary conjugations...~%")
  (load-secondary-conjugations)
  (add-errata)
  (recalc-entry-stats)
  (query "ANALYZE"))

(defun drop-extras ()
  (query (:delete-from 'conj-prop))
  (query (:delete-from 'conjugation))
  (query (:delete-from 'entry :where (:not 'root-p)))
  )

;;; conjugations generator (warning: terrible code ahead)

(defmacro csv-hash (hash-name (filename &key skip-first ((:errata errata-fn))) loader-opts &rest accessor-opts-list)
  (let ((base-name (string-trim "*" hash-name))
        (forms (list `(defparameter ,hash-name nil)))
        (loader-opts-length (length loader-opts)) ;;([loader-name] row-def row-key value-form)
        loader-name
        (row-count-var (gensym "ROW"))
        )
    (assert (member loader-opts-length '(3 4)))
    (setf loader-name
          (if (= loader-opts-length 4)
              (pop loader-opts)
              (intern (concatenate 'string (symbol-name :load-) base-name))))
    (destructuring-bind (row-def row-key-form value-form) loader-opts
      (push
       `(defun ,loader-name ()
          (setf ,hash-name (make-hash-table :test 'equal))
          (loop :for ,row-def :in (cl-csv:read-csv 
                                   (merge-pathnames *jmdict-data* ,filename)
                                   :separator #\Tab :skip-first-p ,skip-first)
             :for ,row-count-var :from 0
             :do (setf (gethash ,row-key-form ,hash-name) ,value-form))
          ,(when errata-fn `(funcall ,errata-fn ,hash-name)))
       forms))
    (loop with accessor-name
       for accessor-opts in accessor-opts-list
       for accessor-opts-length = (length accessor-opts) ;; ([accessor-name] val-var val-var-form)
       for param = (gensym "KEY")
       do (assert (member accessor-opts-length '(2 3)))
         (setf accessor-name
               (if (= accessor-opts-length 3)
                   (pop accessor-opts)
                   (intern (concatenate 'string (symbol-name :get-) base-name))))
         (destructuring-bind (val-var val-var-form) accessor-opts
           (push
            `(defun ,accessor-name (,param)
               (unless ,hash-name (,loader-name))
               (let ((,val-var (gethash ,param ,hash-name)))
                 ,val-var-form))
            forms)))
    `(progn ,@(nreverse forms))))
               
(csv-hash *pos-index* ("kwpos.csv")
          ((pos-id pos description) pos (cons (parse-integer pos-id) description))
          (val (car val)))

(csv-hash *pos-by-index* ("kwpos.csv")
          ((pos-id pos description) (parse-integer pos-id) pos)
          (get-pos val val))

(csv-hash *conj-description* ("conj.csv" :skip-first t
                                         :errata 'errata-conj-description-hook)
          ((conj-id description) (parse-integer conj-id) description)
          (val val))

(defstruct (conjugation-rule
             (:conc-name cr-)
             (:constructor make-conjugation-rule (pos conj neg fml onum stem okuri euphr euphk)))
  pos conj neg fml onum stem okuri euphr euphk)


(csv-hash *conj-rules* ("conjo.csv" :skip-first t
                                    :errata 'errata-conj-rules-hook)
          ((pos-id conj-id neg fml onum stem okuri euphr euphk pos2)
           (parse-integer pos-id)
           (let ((pos (parse-integer pos-id)))
             (cons (make-conjugation-rule pos
                                          (parse-integer conj-id)
                                          (case (char neg 0) (#\t t) (#\f nil))
                                          (case (char fml 0) (#\t t) (#\f nil))
                                          (parse-integer onum)
                                          (parse-integer stem)
                                          okuri euphr euphk)
                   (gethash pos *conj-rules* nil))))
          (val (reverse val)))


(defun construct-conjugation (word rule)
  (let* ((iskana (test-word (subseq word (max 0 (- (length word) 2))) :kana))
         (euphr (cr-euphr rule))
         (euphk (cr-euphk rule))
         (stem (+ (cr-stem rule)
                  (if (or (and iskana (> (length euphr) 0))
                          (and (not iskana) (> (length euphk) 0)))
                      1 0))))
    (concatenate 'string (subseq word 0 (- (length word) stem))
                 (if iskana euphr euphk)
                 (cr-okuri rule))))

(defun conjugate-word (word pos)
  (let* ((pos-id (get-pos-index pos))
         (rules (get-conj-rules pos-id)))
    (loop for rule in rules
         collect (cons rule (construct-conjugation word rule)))))

(defun get-all-readings (seq)
  (query (:union
          (:select 'text :from 'kanji-text :where (:= 'seq seq))
          (:select 'text :from 'kana-text :where (:= 'seq seq)))
         :column))

(defparameter *do-not-conjugate* '("n" "vs" "adj-na"))

(defparameter *pos-with-conj-rules*
 '("adj-i" "adj-ix" "cop-da" "v1" "v1-s" "v5aru" 
   "v5b" "v5g" "v5k" "v5k-s" "v5m" "v5n" "v5r" "v5r-i" "v5s"
   "v5t" "v5u" "v5u-s" "vk" "vs-s" "vs-i"))

(defparameter *secondary-conjugation-types-from* '(5 6 7 8))

(defparameter *secondary-conjugation-types* '(2 3 4 9 10 11 12 13))

(defun conjugate-entry-inner (seq &key conj-types as-posi)
  (let ((posi (or as-posi (query (:select 'text :distinct :from 'sense-prop
                                          :where (:and (:= 'tag "pos") (:= 'seq seq))) :column))))
    (loop with conj-matrix = (make-hash-table :test 'equal) ;; (cons pos-id conj-id) -> 2x2 array
       for pos in posi
       for pos-id = (get-pos-index pos)
       for rules = (get-conj-rules pos-id)
       if (and rules (not (member pos *do-not-conjugate* :test 'equal)))
         do (loop 
               for (reading ord kanji-flag) in (query (:union (:select 'text 'ord 1 :from 'kanji-text
                                                                       :where (:and (:= 'seq seq) 'conjugate-p))
                                                              (:select 'text 'ord 0 :from 'kana-text
                                                                       :where (:and (:= 'seq seq) 'conjugate-p))))
               do (loop for rule in rules
                        for conj-id = (cr-conj rule)
                     when (or (not conj-types)
                              (member conj-id conj-types))
                     do (let ((key (list pos-id conj-id))
                              (conj-text (construct-conjugation reading rule)))
                          (unless (gethash key conj-matrix)
                            (setf (gethash key conj-matrix)
                                  (make-array '(2 2) :initial-element nil)))
                          (push (list conj-text kanji-flag ord (cr-onum rule))
                                (aref (gethash key conj-matrix)
                                   (if (cr-neg rule) 1 0)
                                   (if (cr-fml rule) 1 0))))))
         finally (return conj-matrix))))

(defun conjugate-entry-outer (seq* &key via conj-types as-posi)
  (let* ((seq (or via seq*))
         (conj-matrix (conjugate-entry-inner seq :conj-types conj-types :as-posi as-posi))
         (original-readings (get-all-readings seq))
         (max-seq (query (:select (:max 'seq) :from 'entry) :single))
         (next-seq (1+ max-seq)))
    (loop for (pos-id conj-id) being the hash-key of conj-matrix using (hash-value matrix)
       for ignore-neg = (not (or (aref matrix 1 0) (aref matrix 1 1)))
       for ignore-fml = (not (or (aref matrix 0 1) (aref matrix 1 1)))
       for pos = (get-pos pos-id)
         do (loop for ii from 0 below 4
               for neg = (>= ii 2)
               for fml = (oddp ii)
               for readings = (remove-if (lambda (item) 
                                           (member (car item) original-readings :test 'equal))
                                         (row-major-aref matrix ii))
               when readings
               do (when (insert-conjugation readings :seq next-seq :via via
                                            :from seq* :pos pos
                                            :conj-id conj-id
                                            :neg (if ignore-neg :null neg)
                                            :fml (if ignore-fml :null fml))
                    (incf next-seq))))))

(defun lex-compare (predicate)
  "Only can sort sequences of equal length"
  (lambda (seq1 seq2)
    (block nil
      (map nil 
           (lambda (e1 e2) 
             (cond ((funcall predicate e1 e2) (return t))
                   ((funcall predicate e2 e1) (return nil))))
           seq1 seq2))))

(defun insert-conjugation (readings &key seq from pos conj-id neg fml via)
  "returns true if new entry is created, nil otherwise"
  (loop for (reading kanji-flag) in (sort readings (lex-compare #'<) :key #'cddr)
     if (= kanji-flag 1) collect reading into kanji-readings
     else collect reading into kana-readings
     finally
       (unless kana-readings (return nil))
       (let* ((kanji-readings (remove-duplicates kanji-readings :test 'equal))
              (kana-readings (remove-duplicates kana-readings :test 'equal))
              (seq-candidates
               (if kanji-readings
                   (query (:intersect 
                           (:select 'seq :from 'kanji-text
                                    :where (:in 'text (:set kanji-readings))
                                    :group-by 'seq
                                    :having (:= (:count 'id) (length kanji-readings)))
                           (:select 'seq :from 'kana-text
                                 :where (:in 'text (:set kana-readings))
                                 :group-by 'seq
                                 :having (:= (:count 'id) (length kana-readings))))
                          :column)
                   (query (:select 'r.seq
                                   :from (:as 'kana-text 'r)
                                   :left-join (:as 'kanji-text 'k) :on (:= 'r.seq 'k.seq)
                                   :where (:and (:is-null 'k.text)
                                                (:in 'r.text (:set kana-readings)))
                                   :group-by 'r.seq
                                   :having (:= (:count 'r.id) (length kana-readings)))
                          :column))))
         (when (or (member from seq-candidates) (member via seq-candidates))
           (return nil))
         (if seq-candidates
             (setf seq (car seq-candidates))
             (progn
               (make-dao 'entry :seq seq :content "")
               (let ((conjugate-p (when (member conj-id *secondary-conjugation-types-from*) t)))
                 (loop for kr in kanji-readings
                    for ord from 0
                    do (make-dao 'kanji-text :seq seq :text kr :ord ord :common :null :conjugate-p conjugate-p))
                 (loop for kr in kana-readings
                    for ord from 0
                    do (make-dao 'kana-text :seq seq :text kr :ord ord :common :null :conjugate-p conjugate-p)))))
         
         (let* ((old-conj (if via
                              (select-dao 'conjugation (:and (:= 'from from) (:= 'seq seq) (:= 'via via)))
                              (select-dao 'conjugation (:and (:= 'from from) (:= 'seq seq) (:is-null 'via)))))
                (conj (or (car old-conj) (make-dao 'conjugation :seq seq :from from :via (or via :null)))))
           (make-dao 'conj-prop :conj-id (id conj) :conj-type conj-id :pos pos :neg neg :fml fml))
         (return (not seq-candidates)))))

(defun load-conjugations ()
  (with-connection *connection*
    (let ((seqs (query (:select 'seq :distinct :from 'sense-prop
                                :where (:and (:= 'tag "pos")
                                             (:in 'text (:set *pos-with-conj-rules*))))
                       :column)))
      (loop for cnt from 1
           for seq in seqs
           do (conjugate-entry-outer seq)
           if (zerop (mod cnt 500)) do (format t "~a entries processed~%" cnt)))))


(defun load-secondary-conjugations ()
  (let ((to-conj (query-dao 'conjugation 
                            (:select 'conj.* :distinct :from (:as 'conjugation 'conj)
                                     :left-join 'conj-prop :on (:= 'conj.id 'conj-prop.conj-id)
                                     :where (:and (:in 'conj-prop.conj-type (:set *secondary-conjugation-types-from*))
                                                  (:not (:in 'conj-prop.pos (:set "vs-i" "vs-s")))
                                                  (:or (:not 'neg) (:is-null 'neg))
                                                  (:or (:not 'fml) (:is-null 'fml)))))))
    (loop for cnt from 1
       for conj in to-conj
       do (conjugate-entry-outer (seq-from conj) :via (seq conj) :as-posi '("v1")
                                 :conj-types *secondary-conjugation-types*)
       if (zerop (mod cnt 1000)) do (format t "~a entries processed~%" cnt))
    ))

;;; end conjugations


(defun find-word (word)
  (select-dao 
   (if (test-word word :kana) 'kana-text 'kanji-text)
   (:= 'text word)))

(defun word-readings (word)
  (let* ((kana-seq (query (:select 'seq :from 'kana-text :where (:= 'text word)) :column))
         (readings
          (if kana-seq (list word)
              (let* ((kanji-seq (query (:select 'seq :from 'kanji-text
                                                :where (:= 'text word)) :column)))
                (query (:order-by 
                        (:select 'text :from 'kana-text :where
                                 (:in 'seq (:set kanji-seq)))
                        'id) :column)))))
    (values readings (mapcar #'ichiran:romanize-word readings))))

;; Compound words (usually 2 words squished together, but not in concatenative way)

(defclass compound-text ()
  ((text :reader text :initarg :text)
   (kana :reader get-kana :initarg :kana)
   (primary :reader primary :initarg :primary)
   (words :reader words :initarg :words)
   (score-mod :reader score-mod :initarg :score-mod)
   ))

(defmethod seq ((obj compound-text))
  (mapcar #'seq (words obj)))

(defmethod print-object ((obj compound-text) stream)
  (print-unreadable-object (obj stream :type t :identity nil)
    (format stream "~a ~a" (seq obj) (text obj))))

(defmethod common ((obj compound-text))
  (common (primary obj)))

(defmethod ord ((obj compound-text))
  (ord (primary obj)))

(defmethod word-type ((obj compound-text)) (word-type (primary obj)))

(defgeneric adjoin-word (word1 word2 &key text kana score-mod)
  (:documentation "make compound word from 2 words"))

(defmethod adjoin-word :around (word1 word2 &key text kana score-mod)
  (call-next-method word1 word2
                    :text (or text (concatenate 'string (get-text word1) (get-text word2)))
                    :kana (or kana (concatenate 'string (get-kana word1) (get-kana word2)))
                    :score-mod (or score-mod 0)))

(defmethod adjoin-word ((word1 simple-text) (word2 simple-text) &key text kana score-mod)
  (make-instance 'compound-text
                 :text text :kana kana :primary word1 :words (list word1 word2) :score-mod score-mod))

(defmethod adjoin-word ((word1 compound-text) (word2 simple-text) &key text kana score-mod)
  (with-slots ((s-text text) (s-kana kana) (s-words words) (s-score-mod score-mod)) word1
    (setf s-text text s-kana kana
          s-words (append s-words (list word2))
          s-score-mod (+ s-score-mod score-mod)))
  word1)

(defgeneric word-conj-data (word)
  (:documentation "conjugation data for word"))

(defmethod word-conj-data ((word simple-text))
  (get-conj-data (seq word)))

(defmethod word-conj-data ((word compound-text))
  (word-conj-data (car (last (words word)))))


(defstruct segment
  start end word (score nil) (info nil) (top nil)) ;; (accum 0) (path nil)

(defun length-multiplier (length power len-lim)
  "len^power until len-lim, goes linear after"
  (cond ((<= length len-lim) (expt length power))
        (t (* length (expt len-lim (1- power))))))

(defparameter *length-coeff-sequences*
  '((:strong 1 8 24 48 100)
    (:weak 1 4 9 16 25)
    (:tail 1 4 9 16)))

(defun length-multiplier-coeff (length class)
  (let ((coeffs (assoc class *length-coeff-sequences*)))
    (if (< length (length coeffs))
        (elt coeffs length)
        (* length (/ (car (last coeffs)) (1- (length coeffs)))))))

(defparameter *final-prt* '(2029120 2086640 2029110))

(defun calc-score (reading &key final use-length (score-mod 0))
  (when (typep reading 'compound-text)
    (multiple-value-bind (score info) (calc-score (primary reading)
                                                  :use-length (mora-length (text reading))
                                                  :score-mod (score-mod reading))
      (setf (getf info :conj) (word-conj-data reading))
      (return-from calc-score
        (values score info))))

  (let* ((score 1)
         (kanji-p (typep reading 'kanji-text))
         (katakana-p (and (not kanji-p) (test-word (text reading) :katakana)))
         (len (mora-length (text reading))))
    (with-slots (seq ord) reading
      (let* ((entry (get-dao 'entry seq))
             (root-p (root-p entry))
             (conj-data (word-conj-data reading))
             (conj-of (mapcar #'conj-data-from conj-data))
             (secondary-conj-p (and conj-data (every #'conj-data-via conj-data)))
             (seq-set (cons seq conj-of)) ;;(if root-p (list seq) (cons seq conj-of)))
             (prefer-kana
              (select-dao 'sense-prop (:and (:in 'seq (:set seq-set)) (:= 'tag "misc") (:= 'text "uk"))))
             (posi (query (:select 'text :distinct :from 'sense-prop
                                   :where (:and (:in 'seq (:set seq-set)) (:= 'tag "pos"))) :column))
             (common (common reading))
             (common-p (not (eql common :null)))
             (particle-p (member "prt" posi :test 'equal))
             (pronoun-p (member "pn" posi :test 'equal))
             (cop-da-p (member "cop-da" posi :test 'equal))
             (long-p (> len (if (or (and kanji-p root-p (not prefer-kana)) (and common-p (< 0 common 10))) 2 3)))
             (primary-p (or (and prefer-kana
                                 (not kanji-p)
                                 (or (not (primary-nokanji entry))
                                     (nokanji reading)))
                            (and (= ord 0)
                                 (or (and kanji-p (not prefer-kana))
                                     (and common-p pronoun-p)
                                     (= (n-kanji entry) 0))))))
        (unless (or common-p secondary-conj-p)
          (let* ((table (if kanji-p 'kanji-text 'kana-text))
                 (conj-of-common (query (:select 'id :from table
                                                 :where (:and (:in 'seq (:set conj-of))
                                                              (:not-null 'common)))
                                       :column)))
            (when conj-of-common
              (setf common 0 common-p t))))
        (when primary-p
          (incf score (cond ((or kanji-p long-p) 10)
                            ((or common-p prefer-kana) 5)
                            (t 2)))
          (when (and particle-p (or final (not (member seq *final-prt*))))
            (when (and common-p)
              (incf score 5))
            (when final
              (incf score 5))))
        (when (and common-p (not particle-p)) 
          (cond ((or long-p cop-da-p (and primary-p root-p (or kanji-p (> len 1))))
                 (incf score (if (= common 0) 10 (max (- 20 common) 10))))
                ((or (> len 2) (< 0 common 10)) (incf score 3))
                (t (incf score 2))))
        (when (or long-p kanji-p)
          (setf score (max 5 score))
          (when (and long-p kanji-p)
            (incf score 2)))
        (setf score (* score (+ (length-multiplier-coeff len (if (or kanji-p katakana-p) :strong :weak))
                                (if use-length (length-multiplier-coeff use-length :tail) 0)
                                score-mod)))

        (values score (list :posi posi :seq-set (cons seq conj-of)
                            :conj conj-data
                            :kpcl (list kanji-p primary-p common-p long-p)))))))

(defun gen-score (segment &optional final)
  (setf (values (segment-score segment) (segment-info segment))
        (calc-score (segment-word segment) :final final))
  segment)

(defun find-sticky-positions (str)
  "words cannot start or end after sokuon and before yoon characters"
  (loop with modifiers = (append *modifier-characters* *iteration-characters*)
     for pos from 0 below (length str)
     for char = (char str pos)
     for char-class = (gethash char *char-class-hash* char)
     if (eql char-class :sokuon) collect (1+ pos)
     else if (member char-class modifiers) collect pos))

(defun find-substring-words (str)
  (loop with sticky = (find-sticky-positions str)
       for start from 0 below (length str)
       unless (member start sticky)
       nconcing 
       (loop for end from (1+ start) upto (length str)
            unless (member end sticky)
            nconcing (mapcar 
                      (lambda (word)
                        (gen-score (make-segment :start start :end end :word word)
                                   (= end (length str))))
                      (find-word (subseq str start end))))))

(defparameter *identical-word-score-cutoff* 1/2)

(defun cull-segments (segments)
  (when segments
    (let* ((segments (stable-sort segments #'> :key #'segment-score))
           (max-score (segment-score (car segments)))
           (cutoff (* max-score *identical-word-score-cutoff*)))
      (loop for seg in segments
           while (>= (segment-score seg) cutoff)
           collect seg))))

(defstruct segment-list segments start end (top nil))

(defgeneric get-segment-score (seg)
  (:documentation "Like segment-score but also works for segment-list and synergies")
  (:method ((seg segment))
    (segment-score seg))
  (:method ((seg-list segment-list))
    (let ((seg (car (segment-list-segments seg-list))))
      (if seg (segment-score seg) 0))))

;;; Those are only bound during join-substring-words calls
(defvar *suffix-map-temp* nil)
(defvar *suffix-next-end* nil)

(defun find-word-full (word)
  (nconc (find-word word)
         (find-word-suffix word)))

(defun join-substring-words (str)
  (loop with sticky = (find-sticky-positions str)
       with suffix-map = (get-suffix-map str)
       for start from 0 below (length str)
       unless (member start sticky)
       nconcing 
       (loop for end from (1+ start) upto (length str)
            unless (member end sticky)
            nconcing 
            (let ((segments (mapcar 
                             (lambda (word)
                               (gen-score (make-segment :start start :end end :word word)
                                          (= end (length str))))
                             (let ((*suffix-map-temp* suffix-map)
                                   (*suffix-next-end* end))
                               (find-word-full (subseq str start end))))))
              (when segments
                (list (make-segment-list :segments (cull-segments segments)
                                         :start start :end end)))))))


(defstruct (top-array-item (:conc-name tai-)) score payload)

(defclass top-array ()
  ((array :reader top-array)
   (count :reader item-count :initform 0)
   ))

(defmethod initialize-instance :after ((obj top-array) &key (limit 5))
  (setf (slot-value obj 'array) (make-array limit :initial-element nil)))

(defgeneric register-item (collection score payload)
  (:method ((obj top-array) score payload)
    (with-slots (array count) obj
      (let ((item (make-top-array-item :score score :payload payload))
            (len (length array)))
        (loop for idx from (min count len) downto 0
           for prev-item = (when (> idx 0) (aref array (1- idx)))
           for done = (or (not prev-item) (>= (tai-score prev-item) score))
           when (< idx len) do (setf (aref array idx) (if done item prev-item))
           until done)
        (incf count)))))

(defgeneric get-array (collection)
  (:method ((obj top-array))
    (with-slots (array count) obj
      (if (>= count (length array)) array (subseq array 0 count)))))


(defun find-best-path (segment-lists &key (limit 5))
  "generalized version of old find-best-path that operates on segment-lists and uses synergies"
  (let ((top (make-instance 'top-array :limit limit)))
    (register-item top 0 nil)

    (dolist (segment-list segment-lists)
      (setf (segment-list-top segment-list) (make-instance 'top-array :limit limit)))

    ;;assume segments are sorted by (start, end) (as is the result of find-substring-words)
    (loop for (seg1 . rest) on segment-lists
         for score1 = (get-segment-score seg1)
       when (> score1 0) do 
         (register-item (segment-list-top seg1) score1 (list seg1))
         (register-item top score1 (list seg1))
         (loop for seg2 in rest
            for score2 = (get-segment-score seg2)
            when (and (> score2 0)
                      (>= (segment-list-start seg2) (segment-list-end seg1))) do
              (loop for tai across (get-array (segment-list-top seg1))
                   for (seg-left . tail) = (tai-payload tai)
                   for score3 = (get-segment-score seg-left)
                   for score-tail = (- (tai-score tai) score3)
                   do (loop for split in (cons (get-penalties seg-left seg2) (get-synergies seg-left seg2))
                           for accum = (+ (max (reduce #'+ split :key #'get-segment-score)
                                               (1+ score3)
                                               (1+ score2))
                                          score-tail)
                           for path = (nconc split tail)
                           do (register-item (segment-list-top seg2) accum path)
                              (register-item top accum path)))))

    (dolist (segment segment-lists)
      (setf (segment-list-top segment) nil))

    (loop for tai across (get-array top)
         collect (cons (reverse (tai-payload tai)) (tai-score tai)))))

(defun find-best-path* (segment-lists &key (limit 5))
  "convert find-best-path results to single word format"
  (let ((result (find-best-path segment-lists :limit limit)))
    (dolist (item result result)
      (setf (car item)
            (mapcan (lambda (obj)
                      (typecase obj
                        (segment-list (list (car (segment-list-segments obj))))))
                    (car item))))))

(defstruct word-info type text kana (score 0) (seq nil) (components nil) (alternative nil))

(defun word-info-from-segment (segment &aux (word (segment-word segment)))
  (make-word-info :type (word-type word)
                  :text (get-text word)
                  :kana (get-kana word)
                  :seq (seq word)
                  :components (when (typep word 'compound-text)
                                (loop for wrd in (words word)
                                     collect (make-word-info :type (word-type wrd)
                                                             :text (get-text wrd)
                                                             :kana (get-kana wrd)
                                                             :seq (seq wrd))))
                  :score (segment-score segment)))

(defparameter *segment-score-cutoff* 4/5)

(defun word-info-from-segment-list (segment-list)
  (let* ((segments (segment-list-segments segment-list))
         (wi-list* (mapcar #'word-info-from-segment segments))
         (wi1 (car wi-list*))
         (max-score (word-info-score wi1))
         (wi-list (remove-if (lambda (wi)
                               (< (word-info-score wi)
                                  (* *segment-score-cutoff* max-score)))
                             wi-list*)))
    (if (= (length wi-list) 1)
        wi1
        (loop for wi in wi-list
           collect (word-info-kana wi) into kana-list
           collect (word-info-seq wi) into seq-list
           finally (return (make-word-info :type (word-info-type wi1)
                                           :text (word-info-text wi1)
                                           :kana (remove-duplicates kana-list :test 'equal)
                                           :seq seq-list
                                           :components wi-list
                                           :alternative t
                                           :score (word-info-score wi1)))))))
    

(defun fill-segment-path (str path)
  (flet ((make-substr-gap (start end)
           (let ((substr (subseq str start end)))
             (make-word-info :type :gap :text substr :kana substr))))
    (loop with idx = 0 and result
       for segment-list in path
       when (typep segment-list 'segment-list)
       if (> (segment-list-start segment-list) idx)
         do (push (make-substr-gap idx (segment-list-start segment-list)) result)
         end
       and do (push (word-info-from-segment-list segment-list) result)
              (setf idx (segment-list-end segment-list))
       finally
         (when (< idx (length str))
           (push (make-substr-gap idx (length str)) result))
         (return (nreverse result)))))
  
(defun dict-segment (str &key (limit 5))
  (with-connection *connection*
    (loop for (path . score) in (find-best-path (join-substring-words str) :limit limit)
         collect (cons (fill-segment-path str path) score))))

(defun simple-segment (str &key (limit 5))
  (caar (dict-segment str :limit limit)))

(defun get-senses (seq)
  (query (:order-by
          (:select (:select (:concat "[" (:raw "string_agg(pos.text, ',' ORDER BY pos.ord)") "]")
                            :from (:as 'sense-prop 'pos) :where (:and (:= 'pos.sense-id 'sense.id) (:= 'pos.tag "pos")))
                   (:select (:raw "string_agg(gloss.text, '; ' ORDER BY gloss.ord)")
                            :from 'gloss :where (:= 'gloss.sense-id 'sense.id))
                   :from 'sense
                   :where (:= 'sense.seq seq)
                   :group-by 'sense.id)
          'sense.ord)))

(defun get-senses-str (seq)
  (with-output-to-string (s)
    (loop for (pos gloss) in (get-senses seq)
          for i from 1
          for rpos = pos then (if (equal pos "[]") rpos pos)
          when (> i 1) do (terpri s)
          do (format s "~a. ~a ~a" i rpos gloss))))

(defun short-sense-str (seq &key with-pos)
  (query 
   (sql-compile
    `(:limit 
      (:order-by
       (:select (:select (:raw "string_agg(gloss.text, '; ' ORDER BY gloss.ord)")
                         :from gloss :where (:= gloss.sense-id sense.id))
                :from sense 
                ,@(if with-pos
                      `(:inner-join (:as sense-prop pos) :on (:and (:= pos.sense-id sense.id)
                                                                   (:= pos.tag "pos")
                                                                   (:= pos.text ,with-pos))))
                :where (:= 'sense.seq ,seq)
                :group-by 'sense.id)
       'sense.ord)
      1)) :single))

(defun reading-str (kanji kana)
  (if kanji
      (format nil "~a 【~a】" kanji kana)
      kana))

(defun entry-info-short (seq &key with-pos)
  (let ((kanji-text (car (query (:select 'text :from 'kanji-text :where (:and (:= 'seq seq) (:= 'ord 0))) :column)))
        (kana-text (car (query (:select 'text :from 'kana-text :where (:and (:= 'seq seq) (:= 'ord 0))) :column)))
        (sense-str (short-sense-str seq :with-pos with-pos)))
    (with-output-to-string (s)
      (format s "~a : " (reading-str kanji-text kana-text))
      (when sense-str (princ sense-str s)))))

(defun print-conj-info (seq &optional (out *standard-output*))
  (loop with straight-conj = (select-dao 'conjugation (:and (:= 'seq seq) (:is-null 'via)))
     for conj in (or straight-conj (select-dao 'conjugation (:= 'seq seq)))
     do (loop for conj-prop in (select-dao 'conj-prop (:= 'conj-id (id conj)))
           do (format out "~%[ Conjugation: ~a" (conj-info-short conj-prop)))
       (if (eql (seq-via conj) :null)
           (format out "~%  ~a" (entry-info-short (seq-from conj)))
           (progn
             (format out "~% --(via)--")
             (print-conj-info (seq-via conj) out)))
       (princ " ]" out)))

(defun map-word-info-kana (fn word-info &key (separator "/")
                           &aux (wkana (word-info-kana word-info)))
  (if (listp wkana)
      (with-output-to-string (s)
        (loop for wk in wkana
             for first = t then nil
             unless first do (princ separator s)
             do (princ (funcall fn wk) s)))
      (funcall fn wkana)))

(defun word-info-str (word-info)
  (with-connection *connection*
    (with-output-to-string (s)
      (labels ((inner (word-info)
                 (princ (reading-str (case (word-info-type word-info)
                                       (:kanji (word-info-text word-info))
                                       (t nil))
                                     (word-info-kana word-info)) s)
                 (if (word-info-components word-info)
                     (progn
                       (format s " Compound word: ~{~a~^ + ~}" (mapcar #'word-info-text (word-info-components word-info)))
                       (dolist (comp (word-info-components word-info))
                         (terpri s)
                         (inner comp)))
                     (let ((seq (word-info-seq word-info)))
                       (terpri s)
                       (princ (if seq (get-senses-str seq) "???") s)
                       (when seq
                         (print-conj-info seq s))))))
        (if (word-info-alternative word-info)
            (loop for wi in (word-info-components word-info)
                 for i from 1
                 when (> i 1) do (terpri s)
                 do (format s "<~a>. " i) (inner wi))
            (inner word-info))))))
          
