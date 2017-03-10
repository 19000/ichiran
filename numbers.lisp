(in-package #:ichiran/numbers)

(defparameter *digit-kanji-default* "〇一二三四五六七八九")

(defparameter *digit-kanji-legal* "〇壱弐参四五六七八九拾")

(defparameter *power-kanji* "一十百千万   億   兆   京")

(defparameter *char-number-class*
  '("〇零" (:jd 0) "一壱" (:jd 1) "二弐" (:jd 2) "三参" (:jd 3)
    "四" (:jd 4) "五" (:jd 5) "六" (:jd 6) "七" (:jd 7)
    "八" (:jd 8) "九" (:jd 9) "十拾" (:p 1) "百" (:p 2)
    "千" (:p 3) "万" (:p 4) "億" (:p 8) "兆" (:p 12) "京" (:p 16)
    "0０" (:ad 0) "1１" (:ad 1) "2２" (:ad 2) "3３" (:ad 3) "4４" (:ad 4)
    "5５" (:ad 5) "6６" (:ad 6) "7７" (:ad 7) "8８" (:ad 8) "9９" (:ad 9)
    ))

(defparameter *char-number-class-hash*
  (let ((hash (make-hash-table)))
    (loop for (chars class) on *char-number-class* by #'cddr
       do (loop for char across chars
             do (setf (gethash char hash) class)))
    hash))


(defun number-to-kanji (n &rest keys &key (digits *digit-kanji-default*) (powers *power-kanji*) (1sen nil))
  (assert (and (integerp n) (>= n 0)))
  (if (= n 0) (string (char digits 0))
      (loop with mp = 1 and mc
         for i from 0 below (length powers)
         for p = 1 then (* p 10)
         for c = (char powers i)
         while (<= p n)
         when (char-not-equal c #\Space) do (setf mp p mc c)
         finally
           (return
             (if (= mp 1)
                 (string (char digits n))
                 (multiple-value-bind (qt rem) (floor n mp)
                   (format nil "~a~c~a"
                           (if (and (= qt 1) (<= mp (if 1sen 100 1000))) ""
                               (apply #'number-to-kanji qt :1sen t keys))
                           mc
                           (if (= rem 0) "" (apply #'number-to-kanji rem keys)))))))))


(defun parse-number* (na &key (start 0) (end (length na)))
  (loop with mp = 0 and mi
     for i from start below end
     for (class val) = (aref na i)
     if (and (eql class :p) (> val mp)) do (setf mp val mi i)
     finally
       (return
         (cond ((not mi)
                (reduce (lambda (a b) (+ (* 10 a) (cadr b))) na :start start :end end :initial-value 0))
               ((= mi start)
                (+ (expt 10 mp) (if (< (1+ start) end) (parse-number* na :start (1+ start) :end end) 0)))
               (t (+ (* (parse-number* na :start start :end mi) (expt 10 mp))
                     (if (< (1+ mi) end) (parse-number* na :start (1+ mi) :end end) 0)))))))
           

(defun parse-number (str)
  (parse-number* (map 'vector (lambda (c)
                                (or (gethash c *char-number-class-hash*)
                                    (error "Invalid character: ~c" c)))
                      str)))
