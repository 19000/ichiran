;; one-time fixes that don't even need to be loaded

(in-package #:ichiran/dict)


(defun masen-fix ()
  "Fix erroneous conjugations for formal negative non-past forms of v1 and v1-s"
  (loop with max-seq = (query (:select (:max 'seq) :from 'entry) :single)
        with next-seq = (1+ max-seq)
     for prop in (select-dao 'conj-prop (:and (:in 'pos (:set "v1" "v1-s"))
                                                 (:= 'conj-type 1)
                                                 'neg 'fml))
       for conj = (get-dao 'conjugation (conj-id prop))
       for seq = (if (eql (seq-via conj) :null)
                     (seq-from conj)
                     (seq-via conj)) ;; via conj should always be null though
       for matrix = (conjugate-entry-inner seq :conj-types '(1) :as-posi (list (pos prop)))
       for mvals = (alexandria:hash-table-values matrix)
       for readings = (and mvals (aref (car mvals) 1 1))
       when readings
       do (print readings)
       (when (insert-conjugation readings :seq next-seq 
                                    :via (seq-via conj) :from (seq-from conj)
                                    :conj-id 1 :neg t :fml t :pos (pos prop))
            (incf next-seq))
          (delete-dao prop)
       ))
